--[[
================================================================================
 uasset_parser.lua  -  read an FModel-exported .uasset straight into a Lua table
================================================================================
 Port of the relevant parts of CUE4Parse (FabianFG/CUE4Parse @ 85495b5):
   * MappingsProvider/Usmap          -> UAsset.LoadUsmap
   * IoPackage (UE4.26 "Zen" header)  -> UAsset.Parse
   * unversioned property serialization (FUnversionedHeader / FIterator)
   * FPropertyTagType readers, UDataTable, JSON converters (output shape)

 The result has the SAME SHAPE as FModel's .json export, so code that already
 consumes the JSON (tbl[1].Rows[alias], tbl[2].Properties.X ...) keeps working:

     [ { Type=, Name=, Flags=, Class=, Outer={ObjectName=,ObjectPath=} | Package=,
         Properties={...}, Rows={...}(DataTable only) }, ... ]

 Runs in GMod (LuaJIT, uses the `bit` library) and in any standalone LuaJIT.
 No file/IO calls happen unless you use the *File helpers.

 USAGE
     local UAsset = include("uasset_parser.lua")          -- GMod
     local map    = UAsset.LoadUsmapFile("data/sb/StellarBlade_1_1_0.raw.usmap")
     local tbl    = UAsset.ParseFile("data/sb/M_ClriketA_SingleShot_1.uasset", map)
     PrintTable(tbl[1].Properties)

 Parse the usmap ONCE and reuse it (it is large); parsing many assets with the
 same usmap is then cheap.

 LIMITS (deliberately loud instead of silently wrong)
   * Needs an UNCOMPRESSED usmap (compression 0). Zstd/Brotli/Oodle decoders are
     not implemented here - run usmap_decompress.py once.
   * Only the UE4.26/4.27 IoStore ("zen") package layout, unversioned properties.
   * Hard references to OTHER packages cannot be named without the container
     header (FModel resolves them by loading the other package). They come out
     as { ObjectName="Unresolved'0x..'", ObjectPath="0x..", Unresolved=true };
     plug your own lookup into opts.importResolver.
   * Native-serialized structs that are not implemented raise an error naming
     the struct; add yours to UAsset.NativeStructs[name] = function(ctx, mode).
   * int64/uint64 become Lua numbers (exact up to 2^53), like a JSON parser.
================================================================================
]]

local bit = bit or require("bit")
local band, bor, bxor, lshift, rshift = bit.band, bit.bor, bit.bxor, bit.lshift, bit.rshift

local byte, sub, fmt, lower, char = string.byte, string.sub, string.format, string.lower, string.char
local floor, ldexp, huge = math.floor, math.ldexp, math.huge
local concat = table.concat

local UAsset = {}
UAsset.VERSION = "1.0"

-- Defaults (override per call through opts)
UAsset.Defaults = {
	shortFloats     = true,   -- float32 -> shortest decimal that round-trips (3.6666667, as in FModel's JSON)
	lwc             = false,  -- true for UE5 "large world coordinates" (FVector etc. are doubles)
	verify          = true,   -- check every export consumed exactly its serial size
	strict          = false,  -- true: error() on the first export that fails instead of recording _Error
	nullValue       = nil,    -- what a null object reference becomes (nil => key omitted)
	scriptModules   = nil,    -- extra "/Script/<Module>" names used to resolve script classes
	importResolver  = nil,    -- function(info) -> { ObjectName=, ObjectPath= } | nil for other-package refs
	resolveImports  = true,   -- resolve references to other packages by hashing the files under UAsset.Content.root
	warnUnresolved  = false,   -- ErrorNoHalt() once per reference that matches no file (so you can extract it); false = silent
	niagaraValues   = true,   -- add Value.Decoded (float/bool/vector...) next to the raw Bytes of Niagara parameter overrides
	cache           = true,   -- ParseFile only: reuse results per file path (false = always re-parse, "copy" = cached but deep-copied)
	-- exports of these classes are NOT decoded (header only, Skipped=true): render/engine payloads that
	-- are useless outside the engine. Set to {} / false to decode everything.
	skipTypes       = { SkeletalMesh = true, StaticMesh = true, Texture2D = true, TextureCube = true,
	                    Texture2DArray = true, VolumeTexture = true, Font = true, FontFace = true },
	skipPrefixes    = { "Niagara" },
}

--------------------------------------------------------------------------------
-- small helpers
--------------------------------------------------------------------------------
local TWO32 = 4294967296
local function U(x) if x < 0 then return x + TWO32 end return x end

local function fail(msg, ...)
	if select("#", ...) > 0 then msg = fmt(msg, ...) end
	error("UAsset: " .. msg, 0)
end

local function hex32(x) return bit.tohex(x) end            -- 8 lower-case hex digits
local function hex64(hi, lo) return hex32(hi) .. hex32(lo) end

local function readFileRaw(path, where)
	if file and file.Read then                              -- Garry's Mod
		local d = file.Read(path, where or "GAME")
		if d == nil then fail("cannot read file '%s' (search path '%s')", path, where or "GAME") end
		return d
	end
	local f, err = io.open(path, "rb")
	if not f then fail("cannot open '%s': %s", path, tostring(err)) end
	local d = f:read("*a"); f:close()
	return d
end

local function utf16le_to_utf8(s)
	local out, n, i, len = {}, 0, 1, #s
	while i + 1 <= len do
		local c = byte(s, i) + byte(s, i + 1) * 256
		i = i + 2
		if c >= 0xD800 and c < 0xDC00 and i + 1 <= len then
			local c2 = byte(s, i) + byte(s, i + 1) * 256
			if c2 >= 0xDC00 and c2 < 0xE000 then
				c = 0x10000 + (c - 0xD800) * 1024 + (c2 - 0xDC00)
				i = i + 2
			end
		end
		n = n + 1
		if c < 0x80 then out[n] = char(c)
		elseif c < 0x800 then out[n] = char(0xC0 + floor(c / 64), 0x80 + c % 64)
		elseif c < 0x10000 then out[n] = char(0xE0 + floor(c / 4096), 0x80 + floor(c / 64) % 64, 0x80 + c % 64)
		else out[n] = char(0xF0 + floor(c / 262144), 0x80 + floor(c / 4096) % 64, 0x80 + floor(c / 64) % 64, 0x80 + c % 64) end
	end
	return concat(out)
end

--------------------------------------------------------------------------------
-- float32 <-> shortest decimal (Newtonsoft prints floats this way)
--------------------------------------------------------------------------------
local function round_f32(x)
	if x ~= x or x == 0 or x == huge or x == -huge then return x end
	local _, e = math.frexp(x)
	local q = ldexp(1, e - 24)
	if q < 1.401298464324817e-45 then q = 1.401298464324817e-45 end  -- 2^-149 (denormals)
	local r = x / q
	local f = floor(r)
	local d = r - f
	if d > 0.5 or (d == 0.5 and f % 2 == 1) then f = f + 1 end
	return f * q
end

local function shortest_f32(v)
	if v ~= v or v == 0 or v == huge or v == -huge then return v end
	for d = 1, 9 do
		local c = tonumber(fmt("%." .. d .. "g", v))
		if round_f32(c) == v then return c end
	end
	return v
end

local function decode_f32(a, b, c, d)           -- little-endian bytes -> exact double
	local sign = d >= 128 and -1 or 1
	local exp = (d % 128) * 2 + floor(c / 128)
	local mant = (c % 128) * 65536 + b * 256 + a
	if exp == 255 then
		if mant == 0 then return sign * huge end
		return 0 / 0
	elseif exp == 0 then
		return sign * mant * 1.401298464324817e-45
	end
	return sign * ldexp(1 + mant / 8388608, exp - 127)
end

--------------------------------------------------------------------------------
-- Reader  (0-based offsets, like the C# archives)
--------------------------------------------------------------------------------
local Reader = {}
Reader.__index = Reader

local f32cache_short, f32cache_exact = {}, {}

local function newReader(s, p) return setmetatable({ s = s, p = p or 0, shortFloats = true }, Reader) end

function Reader:eof() return self.p >= #self.s end
function Reader:u8()
	local v = byte(self.s, self.p + 1)
	if not v then fail("unexpected end of data at offset %d", self.p) end
	self.p = self.p + 1
	return v
end
function Reader:i8() local v = self:u8(); if v >= 128 then v = v - 256 end return v end
function Reader:u16()
	local a, b = byte(self.s, self.p + 1, self.p + 2)
	if not b then fail("unexpected end of data at offset %d", self.p) end
	self.p = self.p + 2
	return a + b * 256
end
function Reader:i16() local v = self:u16(); if v >= 32768 then v = v - 65536 end return v end
function Reader:u32()
	local a, b, c, d = byte(self.s, self.p + 1, self.p + 4)
	if not d then fail("unexpected end of data at offset %d", self.p) end
	self.p = self.p + 4
	return a + b * 256 + c * 65536 + d * 16777216
end
function Reader:i32() local v = self:u32(); if v >= 2147483648 then v = v - TWO32 end return v end
function Reader:u64pair() local lo = self:u32(); local hi = self:u32(); return hi, lo end
function Reader:u64() local hi, lo = self:u64pair(); return hi * TWO32 + lo end
function Reader:i64()
	local hi, lo = self:u64pair()
	if hi >= 2147483648 then hi = hi - TWO32 end
	return hi * TWO32 + lo
end
function Reader:f32()
	local s4 = sub(self.s, self.p + 1, self.p + 4)
	if #s4 < 4 then fail("unexpected end of data at offset %d", self.p) end
	self.p = self.p + 4
	local cache = self.shortFloats and f32cache_short or f32cache_exact
	local v = cache[s4]
	if v == nil then
		v = decode_f32(byte(s4, 1, 4))
		if self.shortFloats then v = shortest_f32(v) end
		cache[s4] = v
	end
	return v
end
function Reader:f64()
	local lo = self:u32(); local hi = self:u32()
	local sign = hi >= 2147483648 and -1 or 1
	local exp = floor(hi / 1048576) % 2048
	local mant = (hi % 1048576) * TWO32 + lo
	if exp == 2047 then
		if mant == 0 then return sign * huge end
		return 0 / 0
	elseif exp == 0 then
		return sign * ldexp(mant, -1074)
	end
	return sign * ldexp(1 + mant / 4503599627370496, exp - 1023)
end
function Reader:bytes(n)
	if n < 0 or self.p + n > #self.s then fail("read of %d bytes at offset %d runs past end of data", n, self.p) end
	local v = sub(self.s, self.p + 1, self.p + n)
	self.p = self.p + n
	return v
end
function Reader:skip(n) self.p = self.p + n end
function Reader:fstring()
	local len = self:i32()
	if len == 0 then return "" end
	if len > 0 then
		local s = self:bytes(len)
		return sub(s, 1, len - 1)
	end
	len = -len
	local s = self:bytes(len * 2)
	return utf16le_to_utf8(sub(s, 1, len * 2 - 2))
end
function Reader:guid()
	local a, b, c, d = self:u32(), self:u32(), self:u32(), self:u32()
	return (hex32(a) .. "-" .. hex32(b) .. "-" .. hex32(c) .. "-" .. hex32(d)):upper()
end

--------------------------------------------------------------------------------
-- CityHash64 on (hi,lo) 32-bit halves  (needed to turn "/Script/Mod/Class" into
-- the FPackageObjectIndex that exports use for their class)
--------------------------------------------------------------------------------
local city64
local function makeCityHash()
	local bswap = bit.bswap
	local function add(ah, al, bh, bl)
		local l = al + bl
		local c = 0
		if l >= TWO32 then l = l - TWO32; c = 1 end
		local h = ah + bh + c
		if h >= TWO32 then h = h - TWO32 end
		return h, l
	end
	local function xor(ah, al, bh, bl) return U(bxor(ah, bh)), U(bxor(al, bl)) end
	local function mul32lo(a, b)
		local a1 = floor(a / 65536)
		local a0 = a - a1 * 65536
		return (a0 * b + ((a1 * b) % 65536) * 65536) % TWO32
	end
	local function mul(ah, al, bh, bl)
		local a1 = floor(al / 65536); local a0 = al - a1 * 65536
		local b1 = floor(bl / 65536); local b0 = bl - b1 * 65536
		local mid = a0 * b1 + a1 * b0
		local lt = a0 * b0 + (mid % 65536) * 65536
		local carry = floor(lt / TWO32)
		local lo = lt - carry * TWO32
		local hi = (a1 * b1 + floor(mid / 65536) + carry + mul32lo(ah, bl) + mul32lo(al, bh)) % TWO32
		return hi, lo
	end
	local function shr(h, l, n)
		if n >= 32 then return 0, U(rshift(h, n - 32)) end
		return U(rshift(h, n)), U(bor(rshift(l, n), lshift(h, 32 - n)))
	end
	local function rot(h, l, n)
		if n == 0 then return h, l end
		if n >= 32 then h, l = l, h; n = n - 32; if n == 0 then return h, l end end
		return U(bor(rshift(h, n), lshift(l, 32 - n))), U(bor(rshift(l, n), lshift(h, 32 - n)))
	end
	local function bswap64(h, l) return U(bswap(l)), U(bswap(h)) end
	local function smix(h, l) local sh, sl = shr(h, l, 47); return xor(h, l, sh, sl) end
	local function f64(s, i)
		local a, b, c, d, e, f, g, h = byte(s, i + 1, i + 8)
		return e + f * 256 + g * 65536 + h * 16777216, a + b * 256 + c * 65536 + d * 16777216
	end
	local function f32(s, i)
		local a, b, c, d = byte(s, i + 1, i + 4)
		return a + b * 256 + c * 65536 + d * 16777216
	end
	local K0h, K0l = 0xc3a5c85c, 0x97cb3127
	local K1h, K1l = 0xb492b66f, 0xbe98f273
	local K2h, K2l = 0x9ae16a3b, 0x2f90404f
	local KMh, KMl = 0x9ddfea08, 0xeb382d69

	local function hlm(uh, ul, vh, vl, mh, ml)
		local ah, al = xor(uh, ul, vh, vl)
		ah, al = mul(ah, al, mh, ml)
		local sh, sl = shr(ah, al, 47)
		ah, al = xor(ah, al, sh, sl)
		local bh, bl = xor(vh, vl, ah, al)
		bh, bl = mul(bh, bl, mh, ml)
		sh, sl = shr(bh, bl, 47)
		bh, bl = xor(bh, bl, sh, sl)
		return mul(bh, bl, mh, ml)
	end
	local function hl16(uh, ul, vh, vl) return hlm(uh, ul, vh, vl, KMh, KMl) end

	local function weak(wh, wl, xh, xl, yh, yl, zh, zl, ah, al, bh, bl)
		ah, al = add(ah, al, wh, wl)
		local th, tl = add(bh, bl, ah, al)
		th, tl = add(th, tl, zh, zl)
		bh, bl = rot(th, tl, 21)
		local ch, cl = ah, al
		ah, al = add(ah, al, xh, xl)
		ah, al = add(ah, al, yh, yl)
		local rh, rl = rot(ah, al, 44)
		bh, bl = add(bh, bl, rh, rl)
		local oh, ol = add(ah, al, zh, zl)
		local ph, pl = add(bh, bl, ch, cl)
		return oh, ol, ph, pl
	end
	local function weaks(s, i, ah, al, bh, bl)
		local wh, wl = f64(s, i)
		local xh, xl = f64(s, i + 8)
		local yh, yl = f64(s, i + 16)
		local zh, zl = f64(s, i + 24)
		return weak(wh, wl, xh, xl, yh, yl, zh, zl, ah, al, bh, bl)
	end

	local function len0to16(s, n)
		if n >= 8 then
			local mh, ml = add(K2h, K2l, 0, n * 2)
			local ah, al = f64(s, 0); ah, al = add(ah, al, K2h, K2l)
			local bh, bl = f64(s, n - 8)
			local rh, rl = rot(bh, bl, 37)
			rh, rl = mul(rh, rl, mh, ml); local ch, cl = add(rh, rl, ah, al)
			rh, rl = rot(ah, al, 25); rh, rl = add(rh, rl, bh, bl)
			local dh, dl = mul(rh, rl, mh, ml)
			return hlm(ch, cl, dh, dl, mh, ml)
		elseif n >= 4 then
			local mh, ml = add(K2h, K2l, 0, n * 2)
			local a = f32(s, 0)
			local ah, al = floor(a * 8 / TWO32), (a * 8) % TWO32
			ah, al = add(ah, al, 0, n)
			return hlm(ah, al, 0, f32(s, n - 4), mh, ml)
		elseif n > 0 then
			local a, b, c = byte(s, 1), byte(s, floor(n / 2) + 1), byte(s, n)
			local y = a + b * 256
			local z = n + c * 4
			local ah, al = mul(0, y, K2h, K2l)
			local bh, bl = mul(0, z, K0h, K0l)
			ah, al = xor(ah, al, bh, bl)
			ah, al = smix(ah, al)
			return mul(ah, al, K2h, K2l)
		end
		return K2h, K2l
	end
	local function len17to32(s, n)
		local mh, ml = add(K2h, K2l, 0, n * 2)
		local ah, al = f64(s, 0); ah, al = mul(ah, al, K1h, K1l)
		local bh, bl = f64(s, 8)
		local ch, cl = f64(s, n - 8); ch, cl = mul(ch, cl, mh, ml)
		local dh, dl = f64(s, n - 16); dh, dl = mul(dh, dl, K2h, K2l)
		local th, tl = add(ah, al, bh, bl); th, tl = rot(th, tl, 43)
		local uh, ul = rot(ch, cl, 30)
		th, tl = add(th, tl, uh, ul); th, tl = add(th, tl, dh, dl)
		uh, ul = add(bh, bl, K2h, K2l); uh, ul = rot(uh, ul, 18)
		uh, ul = add(ah, al, uh, ul); uh, ul = add(uh, ul, ch, cl)
		return hlm(th, tl, uh, ul, mh, ml)
	end
	local function len33to64(s, n)
		local mh, ml = add(K2h, K2l, 0, n * 2)
		local ah, al = f64(s, 0); ah, al = mul(ah, al, K2h, K2l)
		local bh, bl = f64(s, 8)
		local ch, cl = f64(s, n - 24)
		local dh, dl = f64(s, n - 32)
		local eh, el = f64(s, 16); eh, el = mul(eh, el, K2h, K2l)
		local fh, fl = f64(s, 24); fh, fl = mul(fh, fl, 0, 9)
		local gh, gl = f64(s, n - 8)
		local hh, hl = f64(s, n - 16); hh, hl = mul(hh, hl, mh, ml)
		-- u = Rotate(a + g, 43) + (Rotate(b, 30) + c) * 9
		local agh, agl = add(ah, al, gh, gl)
		local uh, ul = rot(agh, agl, 43)
		local th, tl = rot(bh, bl, 30); th, tl = add(th, tl, ch, cl); th, tl = mul(th, tl, 0, 9)
		uh, ul = add(uh, ul, th, tl)
		-- v = ((a + g) ^ d) + f + 1
		local vh, vl = xor(agh, agl, dh, dl); vh, vl = add(vh, vl, fh, fl); vh, vl = add(vh, vl, 0, 1)
		-- w = Bswap((u + v) * mul) + h
		local wh, wl = add(uh, ul, vh, vl); wh, wl = mul(wh, wl, mh, ml); wh, wl = bswap64(wh, wl); wh, wl = add(wh, wl, hh, hl)
		-- x = Rotate(e + f, 42) + c
		local xh, xl = add(eh, el, fh, fl); xh, xl = rot(xh, xl, 42); xh, xl = add(xh, xl, ch, cl)
		-- y = (Bswap((v + w) * mul) + g) * mul
		local yh, yl = add(vh, vl, wh, wl); yh, yl = mul(yh, yl, mh, ml); yh, yl = bswap64(yh, yl)
		yh, yl = add(yh, yl, gh, gl); yh, yl = mul(yh, yl, mh, ml)
		-- z = e + f + c
		local zh, zl = add(eh, el, fh, fl); zh, zl = add(zh, zl, ch, cl)
		-- a = Bswap((x + z) * mul + y) + b
		ah, al = add(xh, xl, zh, zl); ah, al = mul(ah, al, mh, ml); ah, al = add(ah, al, yh, yl)
		ah, al = bswap64(ah, al); ah, al = add(ah, al, bh, bl)
		-- b = ShiftMix((z + a) * mul + d + h) * mul
		bh, bl = add(zh, zl, ah, al); bh, bl = mul(bh, bl, mh, ml); bh, bl = add(bh, bl, dh, dl); bh, bl = add(bh, bl, hh, hl)
		bh, bl = smix(bh, bl); bh, bl = mul(bh, bl, mh, ml)
		return add(bh, bl, xh, xl)
	end

	function city64(s)
		local n = #s
		if n <= 16 then return len0to16(s, n) end
		if n <= 32 then return len17to32(s, n) end
		if n <= 64 then return len33to64(s, n) end
		local xh, xl = f64(s, n - 40)
		local yh, yl = f64(s, n - 16)
		local t1h, t1l = f64(s, n - 56); yh, yl = add(yh, yl, t1h, t1l)
		local zh, zl = f64(s, n - 48); zh, zl = add(zh, zl, 0, n)
		local z2h, z2l = f64(s, n - 24)
		zh, zl = hl16(zh, zl, z2h, z2l)
		local v1h, v1l, v2h, v2l = weaks(s, n - 64, 0, n, zh, zl)
		local w1h, w1l, w2h, w2l
		do local ah, al = add(yh, yl, K1h, K1l); w1h, w1l, w2h, w2l = weaks(s, n - 32, ah, al, xh, xl) end
		do local fh, fl = f64(s, 0); xh, xl = mul(xh, xl, K1h, K1l); xh, xl = add(xh, xl, fh, fl) end
		local len = floor((n - 1) / 64) * 64
		local p = 0
		repeat
			local fh, fl = f64(s, p + 8)
			local th, tl = add(xh, xl, yh, yl); th, tl = add(th, tl, v1h, v1l); th, tl = add(th, tl, fh, fl)
			th, tl = rot(th, tl, 37); xh, xl = mul(th, tl, K1h, K1l)
			fh, fl = f64(s, p + 48)
			th, tl = add(yh, yl, v2h, v2l); th, tl = add(th, tl, fh, fl)
			th, tl = rot(th, tl, 42); yh, yl = mul(th, tl, K1h, K1l)
			xh, xl = xor(xh, xl, w2h, w2l)
			fh, fl = f64(s, p + 40)
			th, tl = add(v1h, v1l, fh, fl); yh, yl = add(yh, yl, th, tl)
			th, tl = add(zh, zl, w1h, w1l); th, tl = rot(th, tl, 33); zh, zl = mul(th, tl, K1h, K1l)
			local mh, ml = mul(v2h, v2l, K1h, K1l)
			local ph, pl = add(xh, xl, w1h, w1l)
			v1h, v1l, v2h, v2l = weaks(s, p, mh, ml, ph, pl)
			local qh, ql = add(zh, zl, w2h, w2l)
			fh, fl = f64(s, p + 16)
			local rh, rl = add(yh, yl, fh, fl)
			w1h, w1l, w2h, w2l = weaks(s, p + 32, qh, ql, rh, rl)
			zh, zl, xh, xl = xh, xl, zh, zl
			p = p + 64
			len = len - 64
		until len == 0
		local ah, al = hl16(v1h, v1l, w1h, w1l)
		local sh, sl = smix(yh, yl); sh, sl = mul(sh, sl, K1h, K1l)
		ah, al = add(ah, al, sh, sl); ah, al = add(ah, al, zh, zl)
		local bh, bl = hl16(v2h, v2l, w2h, w2l); bh, bl = add(bh, bl, xh, xl)
		return hl16(ah, al, bh, bl)
	end
	return city64
end
-- The hash code is branchy 64-bit emulation: with the JIT on, LuaJIT wastes ~20x more time
-- compiling/aborting traces than running it. Keep this code in the interpreter.
if jit and jit.off then jit.off(makeCityHash, true) end
city64 = makeCityHash()
UAsset.CityHash64 = city64

-- "/Script/SB/SBShowData" -> FPackageObjectIndex(ScriptImport) as (hi, lo)
local function scriptObjectIndex(path)
	local s = lower(path):gsub(".", "%0\0")
	local hi, lo = city64(s)
	hi = bor(band(hi, 0x3FFFFFFF), 0x40000000)
	return U(hi), lo
end
UAsset.ScriptObjectIndex = scriptObjectIndex

-- "/Game/Sound/Foo/Bar/Bar" -> FPackageObjectIndex(PackageImport) as 16 hex digits.
-- This is how the 4.26 package store names "object Bar inside package /Game/Sound/Foo/Bar".
local function packageImportKey(path)
	local s = lower(path):gsub(".", "%0\0")
	local hi, lo = city64(s)
	hi = U(bor(band(hi, 0x3FFFFFFF), 0x80000000))
	return hex64(hi, lo)
end
UAsset.PackageImportKey = packageImportKey

--------------------------------------------------------------------------------
-- .usmap
--------------------------------------------------------------------------------
local PROP_TYPES = {
	[0] = "ByteProperty", "BoolProperty", "IntProperty", "FloatProperty", "ObjectProperty", "NameProperty",
	"DelegateProperty", "DoubleProperty", "ArrayProperty", "StructProperty", "StrProperty", "TextProperty",
	"InterfaceProperty", "MulticastDelegateProperty", "WeakObjectProperty", "LazyObjectProperty",
	"AssetObjectProperty", "SoftObjectProperty", "UInt64Property", "UInt32Property", "UInt16Property",
	"Int64Property", "Int16Property", "Int8Property", "MapProperty", "SetProperty", "EnumProperty",
	"FieldPathProperty", "OptionalProperty", "Utf8StrProperty", "AnsiStrProperty", "ClassProperty",
	"MulticastInlineDelegateProperty", "SoftClassProperty", "VerseStringProperty", "VerseDynamicProperty",
	"VerseFunctionProperty",
}

local function readUsmapType(r, names)
	local code = r:u8()
	local t = PROP_TYPES[code] or "Unknown"
	local pt = { t = t }
	local function rname() local i = r:i32(); if i == -1 then return nil end return names[i + 1] end
	if t == "EnumProperty" then
		pt.inner = readUsmapType(r, names)
		pt.enum = rname()
	elseif t == "StructProperty" then
		pt.struct = rname()
	elseif t == "SetProperty" or t == "ArrayProperty" or t == "OptionalProperty" then
		pt.inner = readUsmapType(r, names)
	elseif t == "MapProperty" then
		pt.inner = readUsmapType(r, names)
		pt.value = readUsmapType(r, names)
	end
	return pt
end

--- Parse an UNCOMPRESSED .usmap (string of bytes). Returns a mappings table.
function UAsset.LoadUsmap(data)
	local r = newReader(data)
	if #data < 2 or r:u16() ~= 0x30C4 then fail("not a .usmap file (bad magic)") end
	local ver = r:u8()
	if ver > 5 then fail("unsupported usmap version %d", ver) end
	local hasVersioning = false
	if ver >= 1 then hasVersioning = r:i32() ~= 0 end
	local info = {}
	if hasVersioning then
		if ver >= 5 then
			r:skip(2 + 2 + 2 + 4)                 -- engine major/minor/patch/changelist
			local n = r:i32()
			r:skip(n > 0 and n or -2 * n)          -- branch FString
		end
		info.ue4, info.ue5 = r:i32(), r:i32()
		local n = r:i32()
		r:skip(n * 20)                            -- custom versions (guid + int)
		r:skip(4)                                 -- NetCL
	end
	local comp = r:u8()
	local compSize, decompSize = r:u32(), r:u32()
	if comp ~= 0 then
		fail("this .usmap is compressed (method %d = %s). Decompress it once with usmap_decompress.py "
			.. "(it writes an uncompressed .usmap that this loader and FModel both accept).",
			comp, ({ [1] = "Oodle", [2] = "Brotli", [3] = "Zstd" })[comp] or "?")
	end
	if compSize ~= decompSize then fail("usmap: size fields disagree for uncompressed data") end
	r = newReader(sub(data, r.p + 1, r.p + decompSize))

	local nameCount = r:u32()
	local names = {}
	for i = 1, nameCount do
		local len = ver >= 2 and r:u16() or r:u8()
		names[i] = r:bytes(len)
	end
	local function rname() local i = r:i32(); if i == -1 then return nil end return names[i + 1] end

	local enums = {}
	for _ = 1, r:u32() do
		local ename = rname()
		local n = ver >= 3 and r:u16() or r:u8()
		local members = {}
		if ver >= 4 then
			for _ = 1, n do
				local v = r:u64()
				members[v] = rname()
			end
		else
			for j = 0, n - 1 do members[j] = rname() end
		end
		if enums[ename] == nil then enums[ename] = members end    -- duplicates ignored, like CUE4Parse
	end

	local structs, structsCI = {}, {}
	for _ = 1, r:u32() do
		local st = { name = rname(), super = rname(), props = {} }
		st.propCount = r:u16()
		local serializable = r:u16()
		for _ = 1, serializable do
			local index = r:u16()
			local dim = r:u8()
			local pname = rname()
			local ptype = readUsmapType(r, names)
			for j = 0, dim - 1 do
				st.props[index + j] = { name = pname, type = ptype, arrayIndex = j, arraySize = dim }
			end
		end
		structs[st.name] = st
		structsCI[lower(st.name)] = st
	end

	return { version = ver, enums = enums, structs = structs, structsCI = structsCI, info = info,
	         _scriptIdx = {}, _scriptMods = {} }
end

function UAsset.LoadUsmapFile(path, where) return UAsset.LoadUsmap(readFileRaw(path, where)) end

local function getStruct(map, name)
	return map.structs[name] or map.structsCI[lower(name)]
end

local function getProp(map, st, i)
	while st do
		local p = st.props[i]
		if p then return p end
		if i < st.propCount or not st.super then return nil end
		i = i - st.propCount
		st = getStruct(map, st.super)
	end
	return nil
end

-- script classes: hash "/Script/<Module>/<Name>" for every struct/class in the usmap
local function ensureScriptModules(map, modules)
	for _, m in ipairs(modules) do
		if not map._scriptMods[m] then
			map._scriptMods[m] = true
			local prefix = "/Script/" .. m .. "/"
			for name in pairs(map.structs) do
				local hi, lo = scriptObjectIndex(prefix .. name)
				map._scriptIdx[hex64(hi, lo)] = { module = "/Script/" .. m, name = name }
			end
		end
	end
end

--------------------------------------------------------------------------------
-- issue tracking: remembers WHERE parsing could not decode something (feeds the undecoded-field report)
--------------------------------------------------------------------------------
local function pathString(ctx)
	local t, n = {}, 0
	for i = 1, ctx.depth or 0 do
		local part = ctx.parts[i]
		n = n + 1
		if sub(part, 1, 1) == "[" or n == 1 then t[n] = part else t[n] = "." .. part end
	end
	return concat(t)
end

local function addIssue(ctx, rec)
	local list = ctx.issues
	if not list then return end
	if #list < 500 then list[#list + 1] = rec end         -- cap per asset so one bad table cannot flood memory
end

-- turn an error message into (cause, what) for grouping
local function classifyError(msg)
	local what = msg:match("native struct '([^']+)'")
	if what then return "native struct not implemented", what end
	what = msg:match("property type '([^']+)'")
	if what then return "property type not supported", what end
	what = msg:match("Missing prop mappings for type (%S+)")
	if what then return "struct missing from usmap", what end
	what = msg:match("class '([^']+)' has no entry")
	if what then return "class missing from usmap", what end
	what = msg:match("([%w_]+): unknown property with schema index")
	if what then return "struct layout mismatch (natively serialized struct, or usmap from another build)", what end
	what = msg:match("FText history type (%-?%d+)")
	if what then return "FText history not implemented", what end
	return "other error", (msg:gsub("^UAsset: ", ""):sub(1, 100))
end

--------------------------------------------------------------------------------
-- Zen package header  (UE4.26 / 4.27 "Initial" container layout)
--------------------------------------------------------------------------------
local function mappedNameText(names, idx, extra)
	local n = names[idx + 1]
	if n == nil then fail("name index %d out of range (name map has %d entries)", idx, #names) end
	if extra and extra > 0 then return n .. "_" .. (extra - 1) end
	return n
end

local parseHeader
function parseHeader(data, map, opts, headerOnly)
	if #data < 64 then fail("file too small to be a package") end
	local r = newReader(data)
	if r:u32() == 0x9E2A83C1 then
		fail("this is a legacy (pak) .uasset, not an IoStore/Zen package. Only Zen packages are supported.")
	end
	r.p = 0
	local pkg = { data = data }
	local nameIdx, nameExtra = r:u32(), r:u32()
	r:skip(8)                                                -- SourceName
	pkg.packageFlags = r:u32()
	pkg.cookedHeaderSize = r:u32()
	local namesOff, namesSize = r:i32(), r:i32()
	local hashesOff, hashesSize = r:i32(), r:i32()
	local importOff, exportOff, bundlesOff = r:i32(), r:i32(), r:i32()
	local graphOff, graphSize = r:i32(), r:i32()
	if namesOff ~= 64 or hashesOff < namesOff or importOff < hashesOff or exportOff < importOff
	   or bundlesOff < exportOff or graphOff < bundlesOff or graphOff + graphSize > #data
	   or (exportOff - importOff) % 8 ~= 0 or (bundlesOff - exportOff) % 72 ~= 0 then
		fail("header does not look like a UE4.26/4.27 Zen package (offsets are inconsistent). "
			.. "UE5 packages use a different header and are not supported.")
	end
	if band(pkg.packageFlags, 0x2000) == 0 then
		fail("package does not use unversioned properties (flag 0x2000 missing); only unversioned packages are supported")
	end
	pkg.allExportDataOffset = graphOff + graphSize

	-- name map
	local nameCount = hashesSize / 8 - 1
	local names = {}
	r.p = namesOff
	local hdrs = {}
	for i = 1, nameCount do
		local b0, b1 = r:u8(), r:u8()
		local len = (b0 % 128) * 256 + b1
		local wide = b0 >= 128
		if wide then
			if r.p % 2 == 1 then r.p = r.p + 1 end
			names[i] = utf16le_to_utf8(r:bytes(len * 2))
		else
			names[i] = r:bytes(len)
		end
	end
	pkg.names = names
	pkg.name = mappedNameText(names, nameIdx % 1073741824, nameExtra)

	-- imports (FPackageObjectIndex)
	pkg.imports = {}
	r.p = importOff
	for i = 1, (exportOff - importOff) / 8 do
		local hi, lo = r:u64pair()
		pkg.imports[i] = { hi = hi, lo = lo }
	end

	-- exports
	pkg.exports = {}
	r.p = exportOff
	for i = 1, (bundlesOff - exportOff) / 72 do
		local start = r.p
		local e = {}
		e.serialOffset = r:u64()
		e.serialSize = r:u64()
		local ni, ne = r:u32(), r:u32()
		e.name = mappedNameText(names, ni % 1073741824, ne)
		e.outerHi, e.outerLo = r:u64pair()
		e.classHi, e.classLo = r:u64pair()
		e.superHi, e.superLo = r:u64pair()
		e.templateHi, e.templateLo = r:u64pair()
		e.globalHi, e.globalLo = r:u64pair()
		e.flags = r:u32()
		e.filter = r:u8()
		r.p = start + 72
		pkg.exports[i] = e
	end

	-- export bundles -> physical order of export data
	r.p = bundlesOff
	local remaining = (graphOff - bundlesOff) / 8
	local found, headers = 0, {}
	while found < remaining do
		remaining = remaining - 1
		local first, count = r:u32(), r:u32()
		headers[#headers + 1] = { first = first, count = count }
		found = found + count
	end
	if found ~= remaining then fail("export bundle table is inconsistent (%d vs %d)", found, remaining) end
	local entries = {}
	for i = 0, found - 1 do entries[i] = { index = r:u32(), cmd = r:u32() } end
	local cur = pkg.allExportDataOffset
	for _, h in ipairs(headers) do
		for i = 0, h.count - 1 do
			local en = entries[h.first + i]
			if en.cmd == 1 then                       -- ExportCommandType_Serialize
				local e = pkg.exports[en.index + 1]
				e.pos = cur
				cur = cur + e.serialSize
			end
		end
	end
	if not headerOnly and cur > #data then fail("export data runs past the end of the file (%d > %d)", cur, #data) end

	-- imported package ids (graph data)
	pkg.importedPackages = {}
	r.p = graphOff
	if graphSize >= 4 then
		for i = 1, r:u32() do
			local hi, lo = r:u64pair()
			pkg.importedPackages[i] = "0x" .. hex64(hi, lo)
			r:skip(r:i32() * 8)
		end
	end

	-- modules used for class hashing
	local modules, seen = {}, {}
	local function addModule(m) if not seen[m] then seen[m] = true; modules[#modules + 1] = m end end
	for _, n in ipairs(names) do
		if sub(n, 1, 8) == "/Script/" and not n:find("/", 9, true) then addModule(sub(n, 9)) end
	end
	for _, m in ipairs(opts.scriptModules or {}) do addModule((m:gsub("^/Script/", ""))) end
	addModule("CoreUObject"); addModule("Engine")
	-- game modules first: engine classes are found last, and each module costs ~2s to hash the first time
	table.sort(modules, function(a, b)
		local ea = (a == "CoreUObject" or a == "Engine") and 1 or 0
		local eb = (b == "CoreUObject" or b == "Engine") and 1 or 0
		return ea < eb
	end)
	pkg.modules = modules
	return pkg
end

--------------------------------------------------------------------------------
-- object descriptors (what an FPackageIndex / FPackageObjectIndex points at)
--------------------------------------------------------------------------------
local FLAG_NAMES = {
	{ 0x1, "RF_Public" }, { 0x2, "RF_Standalone" }, { 0x4, "RF_MarkAsNative" }, { 0x8, "RF_Transactional" },
	{ 0x10, "RF_ClassDefaultObject" }, { 0x20, "RF_ArchetypeObject" }, { 0x40, "RF_Transient" },
	{ 0x80, "RF_MarkAsRootSet" }, { 0x100, "RF_TagGarbageTemp" }, { 0x200, "RF_NeedInitialization" },
	{ 0x400, "RF_NeedLoad" }, { 0x800, "RF_KeepForCooker" }, { 0x1000, "RF_NeedPostLoad" },
	{ 0x2000, "RF_NeedPostLoadSubobjects" }, { 0x4000, "RF_NewerVersionExists" }, { 0x8000, "RF_BeginDestroyed" },
	{ 0x10000, "RF_FinishDestroyed" }, { 0x20000, "RF_BeingRegenerated" }, { 0x40000, "RF_DefaultSubObject" },
	{ 0x80000, "RF_WasLoaded" }, { 0x100000, "RF_TextExportTransient" }, { 0x200000, "RF_LoadCompleted" },
	{ 0x400000, "RF_InheritableComponentTemplate" }, { 0x800000, "RF_DuplicateTransient" },
	{ 0x1000000, "RF_StrongRefOnFrame" }, { 0x2000000, "RF_NonPIEDuplicateTransient" },
	{ 0x4000000, "RF_Dynamic" }, { 0x8000000, "RF_WillBeLoaded" },
}
local function flagString(f)
	local out = {}
	for _, e in ipairs(FLAG_NAMES) do
		if band(f, e[1]) ~= 0 then out[#out + 1] = e[2] end
	end
	return #out > 0 and concat(out, " | ") or "0"
end

local function objIndexType(hi) return floor(hi / 1073741824) end   -- 0 export, 1 script, 2 package import, 3 null

-- descriptor: { name=, outer=<desc|nil>, className=, exportIndex=, kind= }
local resolveImportFile, warnUnresolved      -- defined with the import-resolution code below
local resolveObjectIndex

local function packageDesc(pkg)
	if not pkg._pkgDesc then pkg._pkgDesc = { kind = "package", name = pkg.name } end
	return pkg._pkgDesc
end

local function exportDesc(pkg, i)                                     -- i is 0-based
	pkg._descCache = pkg._descCache or {}
	local d = pkg._descCache[i]
	if d then return d end
	local e = pkg.exports[i + 1]
	if not e then return nil end
	d = { kind = "export", name = e.name, exportIndex = i }
	pkg._descCache[i] = d
	d.outer = resolveObjectIndex(pkg, e.outerHi, e.outerLo) or packageDesc(pkg)
	local c = resolveObjectIndex(pkg, e.classHi, e.classLo)
	d.classDesc = c
	d.className = c and c.name or nil
	if c and c.kind == "unresolved" and c.import and pkg._opts and pkg._opts.resolveImports ~= false
	   and c.import.hi >= 2147483648 and c.import.hi < 3221225472 then
		local r = resolveImportFile(pkg._map, pkg._opts, c.import.hi, c.import.lo)   -- class is a Blueprint in another file
		if r then d.className = r.name; d.classImport = r end
	end
	return d
end

function resolveObjectIndex(pkg, hi, lo)
	local t = objIndexType(hi)
	if t == 3 then return nil end
	if t == 0 then return exportDesc(pkg, lo) end
	if t == 1 then
		local key = hex64(hi, lo)
		pkg._scriptDescs = pkg._scriptDescs or {}
		local d = pkg._scriptDescs[key]
		if d then return d end
		local hit = pkg._map._scriptIdx[key]
		if not hit then                                  -- hash modules lazily, game module first
			for _, m in ipairs(pkg.modules) do
				if not pkg._map._scriptMods[m] then
					ensureScriptModules(pkg._map, { m })
					hit = pkg._map._scriptIdx[key]
					if hit then break end
				end
			end
		end
		if hit then
			d = { kind = "script", name = hit.name, className = "Class", outer = { kind = "package", name = hit.module } }
		else
			d = { kind = "unresolved", name = "0x" .. key, className = "Class", outer = nil }
		end
		pkg._scriptDescs[key] = d
		return d
	end
	local key = hex64(hi, lo)
	return { kind = "unresolved", name = "0x" .. key, className = "Class", import = { hi = hi, lo = lo, key = key,
	         packageIndex = floor((hi % 1073741824)), } }
end

local function pathName(d, includeOuterMost)
	local prefix = ""
	local o = d.outer
	if o then
		local oo = o.outer
		if oo ~= nil or includeOuterMost then
			prefix = pathName(o, includeOuterMost) .. ((oo ~= nil and oo.outer == nil) and ":" or ".")
		end
	end
	return prefix .. d.name
end

local function fullName(d)
	return (d.className or "") .. "'" .. pathName(d, false) .. "'"
end

local function descToJson(pkg, d, opts, ctx)
	if d == nil then return opts.nullValue end
	if d.kind == "unresolved" and d.import then
		local imp = d.import
		if opts.importResolver then
			local r = opts.importResolver(imp)
			if r then return r end
		end
		if opts.resolveImports ~= false and imp.hi >= 2147483648 and imp.hi < 3221225472 then   -- PackageImport
			local r = resolveImportFile(pkg._map, opts, imp.hi, imp.lo)
			if r then
				local oname = r.className and (r.className .. "'" .. r.name .. "'") or r.name
				return { ObjectName = oname, ObjectPath = r.path .. "." .. r.exportIndex, File = r.file }
			end
		end
		if ctx then addIssue(ctx, { kind = "unresolved", hash = imp.key, export = ctx.exportName, path = pathString(ctx) }) end
		if opts.warnUnresolved then warnUnresolved(ctx or { pkg = pkg }, imp.key) end
		return { ObjectName = "Unresolved'0x" .. imp.key .. "'", ObjectPath = "0x" .. imp.key, Unresolved = true }
	end
	local top = d
	while top.outer do top = top.outer end
	local path = top.name
	if d.exportIndex then path = path .. "." .. d.exportIndex end
	return { ObjectName = fullName(d), ObjectPath = path }
end

--------------------------------------------------------------------------------
-- resolving references to OTHER packages
--
-- A reference to another package is stored as a 62-bit hash of "/Game/<folders>/<Name>/<Name>" - the
-- name itself is not in the file and a hash cannot be reversed. So we do the opposite: hash every
-- package we know about (the .uasset files below UAsset.Content.root) and look the reference up.
-- A hit gives the exact ObjectPath; the class (SoundCue, Texture2D...) and export index come from the
-- target file's header, which is cheap to read.
--------------------------------------------------------------------------------
UAsset.Content = {
	root     = "data_static/SB/Content",   -- where "/Game/..." lives on disk
	where    = "GAME",                      -- GMod search path
}

local pkgIndex                 -- key -> { pkg = "/Game/..", name = "Bar", file = "Foo/Bar/Bar.uasset" }
local importCache = {}         -- key -> resolved entry | false
local warnedKeys = {}
local forceScan = false        -- true: next ensureIndex() must rescan the disk instead of reading the cache file
local scanning                 -- state of a running async scan

-- Persistent hash cache. Path is relative to garrysmod/data (the "DATA" search path):
--   garrysmod/data/stellarblade/folderhashmap.json
UAsset.HashCacheFile = "stellarblade/folderhashmap.json"
UAsset.HashCacheVersion = 2
UAsset.Verbose = true          -- one console line per index load/scan

local function log(msg)
	if not UAsset.Verbose then return end
	if MsgN then MsgN(msg) else print(msg) end
end
local function countKeys(t) local n = 0 for _ in pairs(t) do n = n + 1 end return n end

local INDEX_SUFFIXES = { "", "_C" }

--- engine packages that are referenced a lot but are not in Content (extend as you like)
UAsset.BuiltinPackages = {
	"/Engine/Animation/DefaultAnimBoneCompressionSettings",
	"/Engine/Animation/DefaultAnimCurveCompressionSettings",
}

local function indexAdd(idx, rel, name, base)       -- rel = "Sound/Foo" ("" for root), name = "Bar"
	base = base or "/Game/"
	local dir = rel ~= "" and (rel .. "/") or ""
	local fpath = base == "/Game/" and (dir .. name .. ".uasset") or nil     -- engine content is not on disk
	local pkgPath = base .. dir .. name
	-- A package normally holds one asset named like the package ("X/X"); a Blueprint holds its class as "X_C".
	local plain = dir:match("^L10N/[^/]+/(.*)$")
	for _, suffix in ipairs(base == "/Game/" and INDEX_SUFFIXES or { "" }) do      -- no "_C" guessing for engine content
		local oname = name .. suffix
		local key = packageImportKey(pkgPath .. "/" .. oname)
		if not idx[key] then idx[key] = { pkg = pkgPath, name = oname, file = fpath } end
		-- Localized assets: other packages reference the plain path ("/Game/Sound/Voice/X"); the engine (and
		-- FModel) swap in "/Game/L10N/<culture>/..." afterwards. So a file stored under L10N/<culture>/ must
		-- also answer to the plain path.
		if plain then
			local k = packageImportKey(base .. plain .. name .. "/" .. oname)
			if not idx[k] then idx[k] = { pkg = pkgPath, name = oname, file = fpath } end
		end
	end
end

-- directory scanner: a queue of folders, processed in slices so it can run without freezing the game
local function newScan() return { queue = { "" }, qn = 1, index = {}, dirs = 0 } end

local function scanSlice(st, budget)                 -- returns true when finished
	local C = UAsset.Content
	local clock = SysTime or os.clock
	local t0 = clock()
	while st.qn > 0 do
		local rel = st.queue[st.qn]
		st.queue[st.qn] = nil
		st.qn = st.qn - 1
		local files, dirs = file.Find(C.root .. (rel ~= "" and ("/" .. rel) or "") .. "/*", C.where or "GAME")
		st.dirs = st.dirs + 1
		for _, f in ipairs(files or {}) do
			if lower(sub(f, -7)) == ".uasset" then indexAdd(st.index, rel, sub(f, 1, -8)) end
		end
		for _, d in ipairs(dirs or {}) do
			st.qn = st.qn + 1
			st.queue[st.qn] = rel ~= "" and (rel .. "/" .. d) or d
		end
		if budget and clock() - t0 >= budget then break end
	end
	return st.qn == 0
end

local function addBuiltins(idx)
	for _, p in ipairs(UAsset.BuiltinPackages or {}) do
		local base = p:match("^/Engine/") and "/Engine/" or "/Game/"
		local q = p:gsub("^/Engine/", ""):gsub("^/Game/", "")
		local rel, name = q:match("^(.*)/([^/]+)$")
		if not name then rel, name = "", q end
		local key = packageImportKey(base .. (rel ~= "" and rel .. "/" or "") .. name .. "/" .. name)
		if not idx[key] then indexAdd(idx, rel, name, base) end
	end
end

local function installIndex(idx, keepParseCache)
	addBuiltins(idx)
	pkgIndex = idx
	importCache = {}
	warnedKeys = {}
	if not keepParseCache and UAsset.ClearCache then UAsset.ClearCache() end
end

--- Load the index from UAsset.HashCacheFile. Returns true, count  |  false, reason.
function UAsset.LoadHashCache(silent, keepParseCache)
	if not (file and file.Exists and file.Read and util and util.JSONToTable) then return false, "no file/util library" end
	local path = UAsset.HashCacheFile
	if not file.Exists(path, "DATA") then return false, "no cache file data/" .. path end
	local raw = file.Read(path, "DATA")
	local t = raw and util.JSONToTable(raw, true, true)
	if type(t) ~= "table" or (t.version ~= 1 and t.version ~= 2) or type(t.entries) ~= "table" then
		return false, "cache file is unreadable or from another version"
	end
	if t.root ~= UAsset.Content.root then
		return false, "cache was built for '" .. tostring(t.root) .. "', not '" .. tostring(UAsset.Content.root) .. "'"
	end
	local idx, n = {}, 0
	if t.version == 1 then
		-- old format (no Blueprint "_C" hashes): rebuild every hash from the stored file names. No disk scan needed.
		local seen = {}
		for key, v in pairs(t.entries) do
			if type(key) ~= "string" or type(v) ~= "string" then return false, "cache file has damaged keys" end
			if not seen[v] then
				seen[v] = true
				if sub(v, 1, 1) == "/" then
					local q = v:gsub("^/Engine/", "")
					local rel, name = q:match("^(.*)/([^/]+)$")
					indexAdd(idx, rel or "", name or q, "/Engine/")
				else
					local q = v:gsub("%.uasset$", "")
					local rel, name = q:match("^(.*)/([^/]+)$")
					indexAdd(idx, rel or "", name or q)
				end
			end
		end
		n = countKeys(idx)
		if not silent then log("[UAsset] hash cache is the old format - upgraded in memory; run uasset_savehashcache to store the new one") end
	else
		local files = t.files
		if type(files) ~= "table" then return false, "cache file has no file list" end
		for key, v in pairs(t.entries) do
			if type(key) ~= "string" then return false, "cache file has damaged keys" end
			local e
			if type(v) == "number" then
				local bp = v < 0
				local f = files[bp and -v or v]
				if type(f) ~= "string" then return false, "cache file has a bad file index" end
				local pkgPath = "/Game/" .. sub(f, 1, -8)
				local stem = pkgPath:match("[^/]+$")
				e = { file = f, pkg = pkgPath, name = bp and (stem .. "_C") or stem }
			elseif type(v) == "string" then                          -- engine entry: value is the package path
				e = { pkg = v, name = v:match("[^/]+$") }
			else
				return false, "cache file has damaged entries"
			end
			idx[key] = e
			n = n + 1
		end
	end
	installIndex(idx, keepParseCache)
	if not silent then log(fmt("[UAsset] loaded %d package hashes from data/%s", n, path)) end
	return true, n
end

--- Write the current index to UAsset.HashCacheFile. Returns true, count, bytes  |  false, reason.
function UAsset.SaveHashCache(silent)
	if not (file and file.Write and util and util.TableToJSON) then return false, "no file/util library" end
	if not pkgIndex then return false, "no index in memory yet" end
	-- compact form: one list of file names + hash -> file number (negative = the Blueprint "_C" object of that file)
	local files, fileNo, entries, n = {}, {}, {}, 0
	for key, e in pairs(pkgIndex) do
		if e.file then
			local i = fileNo[e.file]
			if not i then i = #files + 1; files[i] = e.file; fileNo[e.file] = i end
			local stem = e.file:match("([^/]+)%.uasset$")
			entries[key] = (e.name ~= stem) and -i or i
		else
			entries[key] = e.pkg                      -- engine entry
		end
		n = n + 1
	end
	local json = util.TableToJSON({ version = UAsset.HashCacheVersion, root = UAsset.Content.root, count = n, files = files, entries = entries })
	if not json then return false, "util.TableToJSON failed" end
	local path = UAsset.HashCacheFile
	local dir = path:match("^(.*)/[^/]+$")
	if dir and file.CreateDir then file.CreateDir(dir) end
	file.Write(path, json)
	if file.Size and file.Size(path, "DATA") ~= #json then return false, "file.Write did not store the whole file" end
	if not silent then log(fmt("[UAsset] saved %d package hashes (%d KB) to data/%s", n, floor(#json / 1024), path)) end
	return true, n, #json
end

local function ensureIndex()
	if pkgIndex then return pkgIndex end
	if scanning then return {} end                    -- async rescan running: answer "unknown" until it is installed
	if not forceScan and UAsset.LoadHashCache(true, true) then
		log(fmt("[UAsset] package hash cache loaded (%d entries)", countKeys(pkgIndex)))
		return pkgIndex
	end
	forceScan = false
	local st = newScan()
	if file and file.Find then
		log("[UAsset] no usable hash cache - scanning " .. tostring(UAsset.Content.root) .. " (slow; run uasset_savehashcache to store the result)")
		scanSlice(st, nil)
		log(fmt("[UAsset] scanned %d folders, %d package hashes", st.dirs, countKeys(st.index)))
	end
	addBuiltins(st.index)
	pkgIndex = st.index
	return pkgIndex
end

--- Rescan the disk WITHOUT blocking the game (a slice of folders per Think tick).
--- onDone(ok, count) is called when the new index has replaced the old one.
function UAsset.RefreshPackageIndexAsync(onDone)
	if scanning then return false, "a scan is already running" end
	if not (file and file.Find) then return false, "file.Find is not available" end
	local st = newScan()
	st.count = 0
	scanning = st
	local clock = SysTime or os.clock
	local t0, lastLog = clock(), clock()
	local function finish()
		scanning = nil
		installIndex(st.index)
		local n = countKeys(st.index)
		log(fmt("[UAsset] rescan finished: %d folders, %d package hashes, %.1fs", st.dirs, n, clock() - t0))
		if onDone then onDone(true, n) end
	end
	local function failed(err)
		scanning = nil
		log("[UAsset] rescan failed: " .. tostring(err))
		if onDone then onDone(false, err) end
	end
	if hook and hook.Add then
		hook.Add("Think", "UAsset_PackageIndexScan", function()
			local ok, done = pcall(scanSlice, st, 0.01)
			if not ok then hook.Remove("Think", "UAsset_PackageIndexScan"); return failed(done) end
			if done then hook.Remove("Think", "UAsset_PackageIndexScan"); return finish() end
			if clock() - lastLog > 10 then
				lastLog = clock()
				log(fmt("[UAsset] rescanning... %d folders done, %d queued", st.dirs, st.qn))
			end
		end)
	else
		local ok, err = pcall(scanSlice, st, nil)
		if ok then finish() else failed(err) end
	end
	return true
end

function UAsset.IsScanning() return scanning ~= nil end

--- The index (key -> { file=, pkg=, name= }). Loads the cache file, or scans, on first use.
function UAsset.PackageIndex() return ensureIndex() end

-- raw state, for debugging in the console (these never trigger a load/scan; pkgIndex() is nil until first use)
function UAsset.pkgIndex() return pkgIndex end
function UAsset.importCache() return importCache end
function UAsset.warnedKeys() return warnedKeys end

--- Register packages you know exist but have not extracted (or when file.Find is unavailable).
--- Accepts a table or a newline separated string of paths such as "Sound/Voice/X/Y.uasset",
--- "Content/Sound/Voice/X/Y" or "/Game/Sound/Voice/X/Y".
function UAsset.AddPackages(list)
	local idx = ensureIndex()
	if type(list) == "string" then
		local t = {}
		for line in list:gmatch("[^\r\n]+") do t[#t + 1] = line end
		list = t
	end
	for _, p in ipairs(list) do
		p = p:gsub("\\", "/"):gsub("^%s+", ""):gsub("%s+$", ""):gsub("%.uasset$", ""):gsub("%.uexp$", ""):gsub("%.[%w_]+$", "")
		local base = "/Game/"
		if p:find("^/?Engine/") then base = "/Engine/"; p = p:gsub("^/?Engine/", "") end
		p = p:gsub("^/?Game/", ""):gsub("^/?Content/", ""):gsub("^/", "")
		local rel, name = p:match("^(.*)/([^/]+)$")
		if not name then rel, name = "", p end
		if name ~= "" then indexAdd(idx, rel, name, base) end
	end
	for k in pairs(importCache) do importCache[k] = nil end
end

--- Forget the index and rescan the DISK on next use (blocking). Prefer RefreshPackageIndexAsync().
function UAsset.RefreshPackageIndex()
	pkgIndex = nil
	forceScan = true
	importCache = {}
	warnedKeys = {}
	if UAsset.ClearCache then UAsset.ClearCache() end
end

function UAsset.PackageIndexCount()
	return countKeys(ensureIndex())
end

local function readHeaderBytes(path, where)
	if file and file.Open then
		local f = file.Open(path, "rb", where or "GAME")
		if f then
			local head = f:Read(64)
			if head and #head == 64 then
				local r = newReader(head, 0x34)
				local total = r:u32() + r:u32()
				f:Seek(0)
				local data = f:Read(total)
				f:Close()
				if data and #data == total then return data end
			else
				f:Close()
			end
		end
	end
	local ok, d = pcall(readFileRaw, path, where)
	return ok and d or nil
end

function resolveImportFile(map, opts, hi, lo)
	local key = hex64(hi, lo)
	local cached = importCache[key]
	if cached ~= nil then return cached or nil end
	local ent = ensureIndex()[key]
	if not ent then importCache[key] = false; return nil end
	local C = UAsset.Content
	local res = { name = ent.name, className = nil, path = ent.pkg, exportIndex = 0,
	              file = ent.file and (C.root .. "/" .. ent.file) or nil }
	local data = res.file and readHeaderBytes(res.file, C.where)
	if data then
		local ok, p2 = pcall(parseHeader, data, map, opts, true)
		if ok then
			p2._map = map
			p2._opts = opts
			local pick
			for i, e in ipairs(p2.exports) do
				if e.globalHi == hi and e.globalLo == lo then pick = i; break end
			end
			if not pick then
				for i, e in ipairs(p2.exports) do
					if e.name == ent.name and objIndexType(e.outerHi) == 3 then pick = i; break end
				end
			end
			if pick then
				res.exportIndex = pick - 1
				local e = p2.exports[pick]
				local c = resolveObjectIndex(p2, e.classHi, e.classLo)
				if c and c.kind == "script" then res.className = c.name end
				if res.className and res.className:find("GeneratedClass$") then res.hdr = p2 end   -- needed to follow Blueprint parent classes
			end
		end
	end
	importCache[key] = res
	return res
end

function warnUnresolved(ctx, key)
	if warnedKeys[key] then return end
	warnedKeys[key] = true
	local C = UAsset.Content
	local msg = fmt("[UAsset] unresolved reference 0x%s  (package %s, export %s, property %s): no .uasset under '%s' hashes to it. "
		.. "Extract the missing file, then call UAsset.RefreshPackageIndex().\n",
		key, tostring(ctx and ctx.pkg and ctx.pkg.name), tostring(ctx and ctx.exportName), tostring(ctx and ctx.propName), tostring(C.root))
	if ErrorNoHalt then ErrorNoHalt(msg) else io.stderr:write(msg) end
end

--------------------------------------------------------------------------------
-- property readers
--------------------------------------------------------------------------------
local ZERO, NORMAL, MAP, ARRAY = "ZERO", "NORMAL", "MAP", "ARRAY"
local H = {}                       -- type name -> function(ctx, pt, mode)
local NATIVE = {}                  -- struct name -> function(ctx, mode)
UAsset.NativeStructs = NATIVE
UAsset.PropertyReaders = H

local readValue, readStructFields

local function readFName(ctx)
	local r = ctx.r
	local idx, num = r:i32(), r:i32()
	local n = ctx.names[idx + 1]
	if n == nil then fail("FName index %d out of range at offset %d", idx, r.p - 8) end
	if num > 0 then return n .. "_" .. (num - 1) end
	return n
end

local function packageIndexJson(ctx, idx)
	if idx == 0 then return ctx.opts.nullValue end
	local pkg = ctx.pkg
	if idx > 0 then
		return descToJson(pkg, exportDesc(pkg, idx - 1), ctx.opts, ctx)
	end
	local imp = pkg.imports[-idx]
	if not imp then fail("import index %d out of range", idx) end
	return descToJson(pkg, resolveObjectIndex(pkg, imp.hi, imp.lo), ctx.opts, ctx)
end

local function enumName(ctx, ename, index)
	if not ename then return tostring(index) end
	local members = ctx.map.enums[ename]
	local m = members and members[index]
	if m then return ename .. "::" .. m end
	return ename .. "::" .. index
end

H.IntProperty    = function(ctx, pt, mode) if mode == ZERO then return 0 end return ctx.r:i32() end
H.UInt32Property = function(ctx, pt, mode) if mode == ZERO then return 0 end return ctx.r:u32() end
H.Int16Property  = function(ctx, pt, mode) if mode == ZERO then return 0 end return ctx.r:i16() end
H.UInt16Property = function(ctx, pt, mode) if mode == ZERO then return 0 end return ctx.r:u16() end
H.Int8Property   = function(ctx, pt, mode) if mode == ZERO then return 0 end return ctx.r:i8() end
H.Int64Property  = function(ctx, pt, mode) if mode == ZERO then return 0 end return ctx.r:i64() end
H.UInt64Property = function(ctx, pt, mode) if mode == ZERO then return 0 end return ctx.r:u64() end
H.FloatProperty  = function(ctx, pt, mode) if mode == ZERO then return 0 end return ctx.r:f32() end
H.DoubleProperty = function(ctx, pt, mode) if mode == ZERO then return 0 end return ctx.r:f64() end
H.ByteProperty   = function(ctx, pt, mode) if mode == ZERO then return 0 end return ctx.r:u8() end
H.BoolProperty   = function(ctx, pt, mode) if mode == ZERO then return false end return ctx.r:u8() ~= 0 end
H.StrProperty    = function(ctx, pt, mode) if mode == ZERO then return "" end return ctx.r:fstring() end
H.Utf8StrProperty = H.StrProperty
H.AnsiStrProperty = H.StrProperty
H.NameProperty   = function(ctx, pt, mode) if mode == ZERO then return "None" end return readFName(ctx) end

H.EnumProperty = function(ctx, pt, mode)
	if mode == ZERO then return enumName(ctx, pt.enum, 0) end
	if mode == NORMAL then                    -- unversioned: stored as the underlying integer
		local idx
		if pt.inner then idx = readValue(ctx, pt.inner, NORMAL) else idx = ctx.r:u8() end
		return enumName(ctx, pt.enum, idx)
	end
	return readFName(ctx)                     -- array / map elements are stored as FName (as CUE4Parse does)
end

local function objectRef(ctx, pt, mode)
	if mode == ZERO then return ctx.opts.nullValue end
	return packageIndexJson(ctx, ctx.r:i32())
end
H.ObjectProperty, H.ClassProperty, H.WeakObjectProperty = objectRef, objectRef, objectRef
H.InterfaceProperty = objectRef

local function softPath(ctx, mode)
	if mode == ZERO then return { AssetPathName = "None", SubPathString = "" } end
	local a = readFName(ctx)
	return { AssetPathName = a, SubPathString = ctx.r:fstring() }
end
H.SoftObjectProperty = function(ctx, pt, mode) return softPath(ctx, mode) end
H.SoftClassProperty = H.SoftObjectProperty
H.AssetObjectProperty = function(ctx, pt, mode)
	if mode == ZERO then return { AssetPathName = "", SubPathString = "" } end
	local s = ctx.r:fstring()
	local i = s:match("^.*()%.")
	if not i then return { AssetPathName = s, SubPathString = "" } end
	return { AssetPathName = sub(s, 1, i - 1), SubPathString = sub(s, i + 1) }
end

H.LazyObjectProperty = function(ctx, pt, mode)
	if mode == ZERO then return "00000000-00000000-00000000-00000000" end
	return ctx.r:guid()
end

H.DelegateProperty = function(ctx, pt, mode)
	if mode == ZERO then return { Object = ctx.opts.nullValue, FunctionName = "None" } end
	local o = packageIndexJson(ctx, ctx.r:i32())
	return { Object = o, FunctionName = readFName(ctx) }
end
H.MulticastDelegateProperty = function(ctx, pt, mode)
	local out = {}
	if mode == ZERO then return { InvocationList = out } end
	for i = 1, ctx.r:i32() do out[i] = H.DelegateProperty(ctx, pt, NORMAL) end
	return { InvocationList = out }
end
H.MulticastInlineDelegateProperty = H.MulticastDelegateProperty

H.TextProperty = function(ctx, pt, mode)
	if mode == ZERO then return { CultureInvariantString = nil } end
	local r = ctx.r
	local flags = r:u32()
	local ht = r:i8()
	if ht == 0 then
		local ns, key, src = r:fstring(), r:fstring(), r:fstring()
		return { Namespace = ns, Key = key, SourceString = src, LocalizedString = src }
	elseif ht == -1 then
		if r:i32() ~= 0 then return { CultureInvariantString = r:fstring() } end
		return {}
	end
	fail("FText history type %d is not implemented", ht)
end

H.ArrayProperty = function(ctx, pt, mode)
	local out = {}
	if mode == ZERO then return out end
	local r = ctx.r
	local n = r:i32()
	if n < 0 or n > #r.s - r.p then fail("array element count %d is implausible at offset %d", n, r.p - 4) end
	local inner = pt.inner
	if not inner then fail("array without inner type") end
	local it = inner.t
	if it == "StructProperty" or it == "MapProperty" or it == "ArrayProperty" or it == "SetProperty" then
		local d = ctx.depth + 1
		ctx.depth = d
		for i = 1, n do ctx.parts[d] = "[" .. i .. "]"; out[i] = readValue(ctx, inner, ARRAY) end
		ctx.depth = d - 1
	else
		for i = 1, n do out[i] = readValue(ctx, inner, ARRAY) end
	end
	return out
end

H.SetProperty = function(ctx, pt, mode)
	local out = {}
	if mode == ZERO then return out end
	local r = ctx.r
	local inner = pt.inner
	for _ = 1, r:i32() do readValue(ctx, inner, ARRAY) end      -- elements to remove
	for i = 1, r:i32() do out[i] = readValue(ctx, inner, ARRAY) end
	return out
end

local function mapKeyString(pt, v)
	local t = pt.t
	local s
	if type(v) == "boolean" then s = v and "True" or "False"
	elseif type(v) == "number" then s = tostring(v):gsub("^(%-?%d+)%.0$", "%1")
	elseif type(v) == "string" then s = v
	else return v end
	local tn = t
	local cut = (s .. " (" .. tn .. ")"):match("^([^%(]*)")
	return (cut:gsub("^%s+", ""):gsub("%s+$", ""))
end

H.MapProperty = function(ctx, pt, mode)
	local out = {}
	if mode == ZERO then return out end
	local r = ctx.r
	local kt, vt = pt.inner, pt.value
	if not kt or not vt then fail("map without key/value type") end
	for _ = 1, r:i32() do readValue(ctx, kt, MAP) end           -- keys to remove
	local niagara = ctx.opts.niagaraValues ~= false and kt.struct and kt.struct:find("^NiagaraVariable") and vt.struct == "NiagaraVariant"
	for i = 1, r:i32() do
		local d = ctx.depth + 1
		ctx.parts[d] = "[" .. i .. "]"
		ctx.parts[d + 1] = "Key"
		ctx.depth = d + 1
		local k = readValue(ctx, kt, MAP)
		ctx.parts[d + 1] = "Value"
		local v = readValue(ctx, vt, MAP)
		ctx.depth = d - 1
		if niagara then UAsset.AttachNiagaraValue(ctx, k, v) end
		if kt.t ~= "StructProperty" then k = mapKeyString(kt, k) end
		out[i] = { Key = k, Value = v }
	end
	return out
end

-- native structs (names as in usmap: no F prefix). UE4 floats unless opts.lwc.
local function real(ctx) if ctx.opts.lwc then return ctx.r:f64() end return ctx.r:f32() end
NATIVE.Vector = function(ctx, mode)
	if mode == ZERO then return { X = 0, Y = 0, Z = 0 } end
	return { X = real(ctx), Y = real(ctx), Z = real(ctx) }
end
NATIVE.Vector2D = function(ctx, mode)
	if mode == ZERO then return { X = 0, Y = 0 } end
	return { X = real(ctx), Y = real(ctx) }
end
NATIVE.Vector4 = function(ctx, mode)
	if mode == ZERO then return { X = 0, Y = 0, Z = 0, W = 0 } end
	return { X = real(ctx), Y = real(ctx), Z = real(ctx), W = real(ctx) }
end
NATIVE.Quat = function(ctx, mode)
	if mode == ZERO then return { X = 0, Y = 0, Z = 0, W = 1 } end
	return { X = real(ctx), Y = real(ctx), Z = real(ctx), W = real(ctx) }
end
NATIVE.Rotator = function(ctx, mode)
	if mode == ZERO then return { Pitch = 0, Yaw = 0, Roll = 0 } end
	return { Pitch = real(ctx), Yaw = real(ctx), Roll = real(ctx) }
end
NATIVE.Vector3f = function(ctx, mode)
	if mode == ZERO then return { X = 0, Y = 0, Z = 0 } end
	return { X = ctx.r:f32(), Y = ctx.r:f32(), Z = ctx.r:f32() }
end
NATIVE.Vector3d = function(ctx, mode)
	if mode == ZERO then return { X = 0, Y = 0, Z = 0 } end
	return { X = ctx.r:f64(), Y = ctx.r:f64(), Z = ctx.r:f64() }
end
NATIVE.Vector2f = function(ctx, mode)
	if mode == ZERO then return { X = 0, Y = 0 } end
	return { X = ctx.r:f32(), Y = ctx.r:f32() }
end
NATIVE.IntPoint = function(ctx, mode)
	if mode == ZERO then return { X = 0, Y = 0 } end
	return { X = ctx.r:i32(), Y = ctx.r:i32() }
end
NATIVE.Int32Point = NATIVE.IntPoint
NATIVE.IntVector = function(ctx, mode)
	if mode == ZERO then return { X = 0, Y = 0, Z = 0 } end
	return { X = ctx.r:i32(), Y = ctx.r:i32(), Z = ctx.r:i32() }
end
NATIVE.Box = function(ctx, mode)
	if mode == ZERO then return { Min = { X = 0, Y = 0, Z = 0 }, Max = { X = 0, Y = 0, Z = 0 }, IsValid = 0 } end
	local mn = NATIVE.Vector(ctx, NORMAL)
	local mx = NATIVE.Vector(ctx, NORMAL)
	return { Min = mn, Max = mx, IsValid = ctx.r:u8() }
end
NATIVE.Guid = function(ctx, mode)
	if mode == ZERO then return "00000000-00000000-00000000-00000000" end
	return ctx.r:guid()
end
NATIVE.GUID = NATIVE.Guid
NATIVE.DateTime = function(ctx, mode)
	if mode == ZERO then return { Ticks = 0 } end
	return { Ticks = ctx.r:i64() }
end
NATIVE.Timespan = NATIVE.DateTime
NATIVE.SoftObjectPath = function(ctx, mode) return softPath(ctx, mode) end
NATIVE.SoftClassPath = NATIVE.SoftObjectPath
NATIVE.StringAssetReference = NATIVE.SoftObjectPath
NATIVE.StringClassReference = NATIVE.SoftObjectPath
NATIVE.GameplayTagContainer = function(ctx, mode)
	local out = {}
	if mode == ZERO then return out end
	for i = 1, ctx.r:i32() do out[i] = readFName(ctx) end
	return out
end
NATIVE.FrameNumber = function(ctx, mode)
	if mode == ZERO then return { Value = 0 } end
	return { Value = ctx.r:i32() }
end
NATIVE.Color = function(ctx, mode)
	local b, g, rr, a = 0, 0, 0, 255
	if mode ~= ZERO then local r = ctx.r; b, g, rr, a = r:u8(), r:u8(), r:u8(), r:u8() end
	local hex
	if a == 255 or a == 0 then hex = fmt("%02X%02X%02X", rr, g, b) else hex = fmt("%02X%02X%02X%02X", a, rr, g, b) end
	return { B = b, G = g, R = rr, A = a, Hex = hex }
end
NATIVE.LinearColor = function(ctx, mode)
	local R, G, B, A = 0, 0, 0, 0
	if mode ~= ZERO then local r = ctx.r; R, G, B, A = r:f32(), r:f32(), r:f32(), r:f32() end
	local function clamp(x) if x < 0 then return 0 elseif x > 1 then return 1 end return x end
	local function srgb(x)
		x = clamp(x)
		if x <= 0.0031308 then return x * 12.92 end
		return (x ^ (1 / 2.4)) * 1.055 - 0.055
	end
	local cr, cg, cb, ca = floor(srgb(R) * 255.999), floor(srgb(G) * 255.999), floor(srgb(B) * 255.999), floor(clamp(A) * 255.999)
	local hex
	if ca == 255 or ca == 0 then hex = fmt("%02X%02X%02X", cr, cg, cb) else hex = fmt("%02X%02X%02X%02X", ca, cr, cg, cb) end
	return { R = R, G = G, B = B, A = A, Hex = hex }
end

-- Niagara parameter variables: FName + the ordinary usmap struct "NiagaraTypeDefinition"
-- (+ VarData bytes / Offset for the NiagaraVariable / NiagaraVariableWithOffset flavours)
local function niagaraVariable(ctx, mode, withVarData, withOffset)
	local out = {}
	if mode == ZERO then
		out.Name = "None"; out.TypeDef = {}
		if withVarData then out.VarData = {} end
		if withOffset then out.Offset = 0 end
		return out
	end
	local r = ctx.r
	out.Name = readFName(ctx)
	local st = getStruct(ctx.map, "NiagaraTypeDefinition")
	if not st then fail("Missing prop mappings for type NiagaraTypeDefinition") end
	out.TypeDef = readStructFields(ctx, st)
	if withVarData then
		local n = r:i32()
		if n < 0 or n > #r.s - r.p then fail("NiagaraVariable.VarData length %d is implausible", n) end
		local a = {}
		for i = 1, n do a[i] = r:u8() end
		out.VarData = a
	end
	if withOffset then out.Offset = r:i32() end
	return out
end
NATIVE.NiagaraVariableBase = function(ctx, mode) return niagaraVariable(ctx, mode) end
NATIVE.NiagaraDataChannelVariable = NATIVE.NiagaraVariableBase
NATIVE.NiagaraVariable = function(ctx, mode) return niagaraVariable(ctx, mode, true) end
NATIVE.NiagaraVariableWithOffset = function(ctx, mode) return niagaraVariable(ctx, mode, false, true) end

-- Niagara stores a parameter override's value as raw bytes; the TypeDef says how to read them.
local NIAGARA_LAYOUT = {            -- type name -> field list (f = float32, i = int32, b = bool)
	NiagaraFloat = { "f" }, NiagaraInt32 = { "i" }, NiagaraBool = { "b" },
	Vector2D = { "f", "X", "Y" }, Vector = { "f", "X", "Y", "Z" }, Vector4 = { "f", "X", "Y", "Z", "W" },
	Quat = { "f", "X", "Y", "Z", "W" }, LinearColor = { "f", "R", "G", "B", "A" },
}
NIAGARA_LAYOUT.NiagaraPosition = NIAGARA_LAYOUT.Vector
NIAGARA_LAYOUT.Vector3f = NIAGARA_LAYOUT.Vector

--- Decode Value.Bytes of a NiagaraVariant using its key's TypeDef. Returns value | nil, typeName.
function UAsset.NiagaraValue(key, variant, shortFloats)
	local cs = key and key.TypeDef and key.TypeDef.ClassStructOrEnum
	local tname = cs and cs.ObjectName and cs.ObjectName:match("'(.-)'") or "?"
	local bytes = variant and variant.Bytes
	if type(bytes) ~= "table" or #bytes == 0 then return nil, tname end
	local lay = NIAGARA_LAYOUT[tname]
	if not lay then return nil, tname end
	local chars = {}
	for i = 1, #bytes do chars[i] = char(bytes[i]) end
	local r = newReader(concat(chars), 0)
	r.shortFloats = shortFloats ~= false
	local kind = lay[1]
	if kind == "b" then return r:i32() ~= 0, tname end
	if kind == "i" then return r:i32(), tname end
	if #lay == 1 then return r:f32(), tname end                    -- single float
	if #bytes < (#lay - 1) * 4 then return nil, tname end
	local out = {}
	for i = 2, #lay do out[lay[i]] = r:f32() end
	return out, tname
end

function UAsset.AttachNiagaraValue(ctx, key, variant)
	if type(variant) ~= "table" or type(key) ~= "table" then return end
	if variant.CurrentMode ~= "ENiagaraVariantMode::Bytes" then return end
	local val, tname = UAsset.NiagaraValue(key, variant, ctx.opts.shortFloats)
	if val ~= nil then
		variant.Decoded = val
	else
		addIssue(ctx, { kind = "niagara_value", what = tname, export = ctx.exportName, path = pathString(ctx) })
	end
end

local INTERP = { [0] = "RCIM_Linear", "RCIM_Constant", "RCIM_Cubic", "RCIM_None" }
local TANGENT = { [0] = "RCTM_Auto", "RCTM_User", "RCTM_Break", "RCTM_None" }
local TWEIGHT = { [0] = "RCTWM_WeightedNone", "RCTWM_WeightedArrive", "RCTWM_WeightedLeave", "RCTWM_WeightedBoth" }
NATIVE.RichCurveKey = function(ctx, mode)
	if mode == ZERO then
		return { InterpMode = INTERP[0], TangentMode = TANGENT[0], TangentWeightMode = TWEIGHT[0], Time = 0, Value = 0,
		         ArriveTangent = 0, ArriveTangentWeight = 0, LeaveTangent = 0, LeaveTangentWeight = 0 }
	end
	local r = ctx.r
	local im, tm, tw = r:u8(), r:u8(), r:u8()
	return { InterpMode = INTERP[im] or tostring(im), TangentMode = TANGENT[tm] or tostring(tm),
	         TangentWeightMode = TWEIGHT[tw] or tostring(tw), Time = r:f32(), Value = r:f32(),
	         ArriveTangent = r:f32(), ArriveTangentWeight = r:f32(), LeaveTangent = r:f32(), LeaveTangentWeight = r:f32() }
end
NATIVE.SimpleCurveKey = function(ctx, mode)
	if mode == ZERO then return { Time = 0, Value = 0 } end
	return { Time = ctx.r:f32(), Value = ctx.r:f32() }
end

-- natively serialized in the engine => must not be read through the usmap schema
local UNSUPPORTED_NATIVE = {}
for n in ([[Matrix Matrix44f Plane Plane4f Plane4d Sphere Sphere3f Sphere3d CapsuleShape Box2D Box2f Box3f
 NameCurveKey StringCurveKey SmartName PerPlatformBool PerPlatformFloat PerPlatformInt
 PerPlatformFrameRate PerPlatformFString PerQualityLevelInt PerQualityLevelFloat FontData FontCharacter
 InstancedStruct InstancedStructContainer InstancedPropertyBag Transform3f TwoVectors Spline UniqueNetIdRepl
 MovieSceneFloatChannel MovieSceneDoubleChannel MovieSceneFloatValue MovieSceneDoubleValue MovieSceneFrameRange
 MovieSceneSegment MovieSceneEvaluationKey ExpressionInput ColorMaterialInput
 ScalarMaterialInput VectorMaterialInput Vector2MaterialInput MaterialAttributesInput]]):gmatch("%S+") do
	UNSUPPORTED_NATIVE[n] = true
end

function readStructFields(ctx, st, out)
	local r = ctx.r
	-- FUnversionedHeader
	local fskip, fzero, fnum = {}, {}, {}
	local nfrag, zeroNum, unmasked = 0, 0, 0
	repeat
		local v = r:u16()
		nfrag = nfrag + 1
		fskip[nfrag] = band(v, 0x7F)
		fzero[nfrag] = band(v, 0x80) ~= 0
		fnum[nfrag] = rshift(v, 9)
		if fzero[nfrag] then zeroNum = zeroNum + fnum[nfrag] else unmasked = unmasked + fnum[nfrag] end
	until band(v, 0x100) ~= 0
	local mask
	local hasNonZero = unmasked > 0
	if zeroNum > 0 then
		local nbytes
		if zeroNum <= 8 then nbytes = 1 elseif zeroNum <= 16 then nbytes = 2 else nbytes = math.ceil(zeroNum / 32) * 4 end
		mask = r:bytes(nbytes)
		if not hasNonZero then
			for i = 0, zeroNum - 1 do
				if band(rshift(byte(mask, floor(i / 8) + 1), i % 8), 1) == 0 then hasNonZero = true; break end
			end
		end
	end
	out = out or {}
	if not (hasNonZero or zeroNum > 0) then return out end

	local map = ctx.map
	local schemaIdx, maskIdx = 0, 0
	for f = 1, nfrag do
		schemaIdx = schemaIdx + fskip[f]
		local hasZero = fzero[f]
		for _ = 1, fnum[f] do
			local nonZero = true
			if hasZero then nonZero = band(rshift(byte(mask, floor(maskIdx / 8) + 1), maskIdx % 8), 1) == 0 end
			local p = getProp(map, st, schemaIdx)
			if nonZero then
				if not p then fail("%s: unknown property with schema index %d (usmap does not match this game version?)", st.name, schemaIdx) end
				local key = p.arrayIndex > 0 and (p.name .. "[" .. p.arrayIndex .. "]") or p.name
				local d = ctx.depth + 1
				ctx.depth = d
				ctx.parts[d] = key
				ctx.propName = p.name
				out[key] = readValue(ctx, p.type, NORMAL)
				ctx.depth = d - 1
			elseif p then
				local v = readValue(ctx, p.type, ZERO)
				out[p.arrayIndex > 0 and (p.name .. "[" .. p.arrayIndex .. "]") or p.name] = v
			end
			schemaIdx = schemaIdx + 1
			if hasZero then maskIdx = maskIdx + 1 end
		end
	end
	return out
end

H.StructProperty = function(ctx, pt, mode)
	local sname = pt.struct
	if not sname then fail("struct property without struct type") end
	local nat = NATIVE[sname]
	if nat then return nat(ctx, mode) end
	if UNSUPPORTED_NATIVE[sname] then
		fail("native struct '%s' is not implemented (add UAsset.NativeStructs.%s = function(ctx, mode) ... end)", sname, sname)
	end
	if mode == ZERO then return {} end
	local st = getStruct(ctx.map, sname)
	if not st then fail("Missing prop mappings for type %s", sname) end
	return readStructFields(ctx, st)
end

function readValue(ctx, pt, mode)
	local h = H[pt.t]
	if not h then fail("property type '%s' is not supported", tostring(pt.t)) end
	return h(ctx, pt, mode)
end

--------------------------------------------------------------------------------
-- exports
--------------------------------------------------------------------------------
local function classChain(map, className)
	local chain, n = {}, 0
	local st = className and getStruct(map, className)
	while st and n < 64 do
		n = n + 1; chain[n] = st.name
		st = st.super and getStruct(map, st.super) or nil
	end
	return chain
end

local function isDataTable(chain)
	for _, n in ipairs(chain) do if n == "DataTable" then return true end end
	return false
end

-- usmap schema for an export: its class, or (Blueprint classes) the nearest native parent class
local function schemaFor(pkg, map, desc)
	local st = desc.className and getStruct(map, desc.className)
	if st then return st end
	local curPkg, cd = pkg, desc.classDesc
	for _ = 1, 24 do
		if not cd then return nil end
		if cd.kind == "script" then return getStruct(map, cd.name) end
		if cd.kind == "export" then
			local s2 = getStruct(map, cd.name)
			if s2 then return s2 end
			local ce = curPkg.exports[cd.exportIndex + 1]
			cd = resolveObjectIndex(curPkg, ce.superHi, ce.superLo)
		elseif cd.kind == "unresolved" and cd.import then          -- parent Blueprint lives in another file
			local r = resolveImportFile(curPkg._map, curPkg._opts, cd.import.hi, cd.import.lo)
			if not (r and r.hdr) then return nil end
			curPkg = r.hdr
			cd = exportDesc(curPkg, r.exportIndex)
		else
			return nil
		end
	end
	return nil
end

local function readExport(ctx, pkg, e, i, warnings, unread)
	local desc = exportDesc(pkg, i - 1)
	local out = {
		Type = desc.className or "UObject",
		Name = e.name,
		Flags = flagString(bor(e.flags, 0x80000, 0x200000)),
	}
	local cdesc = desc.classDesc
	if cdesc then
		if cdesc.kind == "export" then            -- instance of a Blueprint class defined in this package
			out.Class = (cdesc.className or "Class") .. "'" .. pathName(cdesc, true) .. "'"
		elseif desc.classImport then              -- instance of a Blueprint class defined in another package
			local ci = desc.classImport
			out.Class = (ci.className or "Class") .. "'" .. ci.path .. "." .. ci.name .. "'"
		else
			out.Class = "UScriptClass'" .. cdesc.name .. "'"
		end
	end
	if desc.outer and desc.outer.kind ~= "package" then
		out.Outer = descToJson(pkg, desc.outer, ctx.opts)
	else
		out.Package = pkg.name
	end
	local sdesc = resolveObjectIndex(pkg, e.superHi, e.superLo)
	if sdesc and sdesc.kind == "export" then out.Super = descToJson(pkg, sdesc, ctx.opts) end
	local tdesc = resolveObjectIndex(pkg, e.templateHi, e.templateLo)
	if tdesc and tdesc.kind == "export" then out.Template = descToJson(pkg, tdesc, ctx.opts) end

	-- a Blueprint class itself: UClass payload (functions, bytecode) is not decoded, only the useful links
	if desc.className and desc.className:find("GeneratedClass$") and not desc.classImport and desc.classDesc and desc.classDesc.kind == "script" then
		out.SuperStruct = descToJson(pkg, resolveObjectIndex(pkg, e.superHi, e.superLo), ctx.opts, ctx)
		for j, e2 in ipairs(pkg.exports) do
			if band(e2.flags, 0x10) ~= 0 and objIndexType(e2.classHi) == 0 and e2.classLo == i - 1 then
				out.ClassDefaultObject = descToJson(pkg, exportDesc(pkg, j - 1), ctx.opts, ctx)
				break
			end
		end
		return out
	end

	local skip = ctx.opts.skipTypes
	local cn = desc.className
	if cn and ((skip and skip[cn]) or false) then
		out.Skipped = true
		addIssue(ctx, { kind = "skipped", export = e.name, class = cn, bytes = e.serialSize })
		return out
	end
	local pre = ctx.opts.skipPrefixes
	if cn and pre then
		for _, pf in ipairs(pre) do
			if sub(cn, 1, #pf) == pf then
				out.Skipped = true
				addIssue(ctx, { kind = "skipped", export = e.name, class = cn, bytes = e.serialSize })
				return out
			end
		end
	end

	local r = ctx.r
	r.p = e.pos
	ctx.exportName = e.name
	local map = ctx.map
	local isDT = false

	ctx.depth = 0

	local function body()
		local st = schemaFor(pkg, map, desc)
		if not st then
			fail("class '%s' has no entry in the usmap (Blueprint class, or usmap from another game version?)",
				tostring(desc.className))
		end
		local props = {}
		out.Properties = props
		readStructFields(ctx, st, props)
		-- UObject::Deserialize: trailing "has object guid" flag comes right after the properties
		if band(e.flags, 0x10) == 0 then
			if r:i32() ~= 0 then r:skip(16) end
		end
		isDT = isDataTable(classChain(map, desc.className))
		if isDT then
			local rs = props.RowStruct
			if not rs then fail("DataTable export has no RowStruct") end
			local rowName = rs.ObjectName and rs.ObjectName:match("^[^']*'(.*)'$")
			local rowSt = rowName and getStruct(map, rowName)
			if not rowSt then fail("DataTable RowStruct '%s' not found in the usmap", tostring(rowName)) end
			local rows = {}
			out.Rows = rows
			for _ = 1, r:i32() do
				local key = readFName(ctx)
				ctx.parts[1] = "Rows"
				ctx.parts[2] = "[" .. key .. "]"
				ctx.depth = 2
				rows[key] = readStructFields(ctx, rowSt)
				ctx.depth = 0
			end
		end
	end

	local ok, err = pcall(body)
	if out.Properties and next(out.Properties) == nil then out.Properties = nil end
	if not ok then
		if ctx.opts.strict then error(err, 0) end
		-- keep whatever was read before the failure; the rest of this export is lost
		out._Error = tostring(err)
		local cause, what = classifyError(tostring(err))
		local decoded = 0
		if out.Properties then for _ in pairs(out.Properties) do decoded = decoded + 1 end end
		addIssue(ctx, { kind = "error", export = e.name, class = desc.className, path = pathString(ctx), cause = cause, what = what,
		                message = tostring(err), decoded = decoded })
		warnings[#warnings + 1] = fmt("export %d (%s): %s", i - 1, e.name, tostring(err))
		return out
	end
	if ctx.opts.verify then
		local used = r.p - e.pos
		if used > e.serialSize or (isDT and used ~= e.serialSize) then
			warnings[#warnings + 1] = fmt("export %d (%s): consumed %d of %d bytes", i - 1, e.name, used, e.serialSize)
		elseif used < e.serialSize then
			-- normal for meshes, textures, sounds, animations...: engine-native payload we do not decode
			unread[e.name] = e.serialSize - used
			addIssue(ctx, { kind = "unread", export = e.name, class = desc.className, bytes = e.serialSize - used })
		end
	end
	return out
end

--------------------------------------------------------------------------------
-- public API
--------------------------------------------------------------------------------
--- Parse an .uasset (string of bytes). Returns exports (array, FModel-JSON shaped), info.
function UAsset.Parse(data, map, opts)
	if type(data) ~= "string" then fail("Parse expects the file contents as a string") end
	if type(map) ~= "table" or not map.structs then fail("Parse needs a mappings table from UAsset.LoadUsmap") end
	local o = setmetatable(opts or {}, { __index = UAsset.Defaults })
	local pkg = parseHeader(data, map, o)
	pkg._map = map
	pkg._opts = o
	local ctx = { pkg = pkg, map = map, opts = o, names = pkg.names, r = newReader(data), depth = 0, parts = {}, issues = {} }
	ctx.r.shortFloats = o.shortFloats and true or false

	local exports, warnings, unread = {}, {}, {}
	for i, e in ipairs(pkg.exports) do
		local ok, res = pcall(readExport, ctx, pkg, e, i, warnings, unread)
		if ok then
			exports[i] = res
		else
			if o.strict then error(res, 0) end
			exports[i] = { Name = e.name, _Error = tostring(res) }
			warnings[#warnings + 1] = fmt("export %d (%s): %s", i - 1, e.name, tostring(res))
		end
	end
	return exports, {
		PackageName = pkg.name, PackageFlags = pkg.packageFlags, Names = pkg.names,
		ImportedPackageIds = pkg.importedPackages, Warnings = warnings,
		UnreadBytes = unread,       -- export name -> bytes of native payload (mesh/audio/anim data) that was skipped
		Issues = ctx.issues,        -- everything that could not be decoded (see UAsset.BuildReport)
	}
end

--------------------------------------------------------------------------------
-- file cache
--   Keyed by the FULL path you pass in ("SB/Path/To/Blah.uasset" and "SB/NewPath/To/Blah.uasset" are
--   different entries, even though both are called Blah), the search path ("GAME", "DATA", ...) and the
--   usmap table. Entries are dropped automatically when file.Time() reports a newer file (GMod).
--------------------------------------------------------------------------------
local cache = setmetatable({}, { __mode = "k" })        -- [mappingsTable] = { [key] = entry }
local reportAssets = {}                                  -- normalised path -> issues of the last parse of that file

local function normPath(path)
	path = tostring(path):gsub("\\", "/"):gsub("/+", "/"):gsub("^%./", ""):gsub("^/", "")
	return path
end
local function cacheKey(path, where, o)
	return (where or "GAME") .. "|" .. normPath(path) .. "|" .. (o.shortFloats and "s" or "e")
		.. (o.lwc and "L" or "f") .. "|" .. tostring(o.nullValue)
end
local function fileTime(path, where)
	if file and file.Time then return file.Time(path, where or "GAME") end
	return nil
end
local function deepCopy(v, seen)
	if type(v) ~= "table" then return v end
	seen = seen or {}
	if seen[v] then return seen[v] end
	local c = {}
	seen[v] = c
	for k, x in pairs(v) do c[deepCopy(k, seen)] = deepCopy(x, seen) end
	return c
end
UAsset.DeepCopy = deepCopy

--- Parse a file; results are cached per path (opts.cache = false to bypass).
--- The returned table is SHARED with the cache - treat it as read-only, or pass opts.cache = "copy".
function UAsset.ParseFile(path, map, opts, where)
	local o = setmetatable(opts or {}, { __index = UAsset.Defaults })
	if o.cache == false then
		local ex, inf = UAsset.Parse(readFileRaw(path, where), map, o)
		reportAssets[normPath(path)] = inf.Issues
		return ex, inf
	end
	local key = cacheKey(path, where, o)
	local bucket = cache[map]
	if not bucket then bucket = {}; cache[map] = bucket end
	local entry = bucket[key]
	local mtime = fileTime(path, where)
	if entry and entry.mtime == mtime then
		if o.cache == "copy" then return deepCopy(entry.exports), deepCopy(entry.info) end
		return entry.exports, entry.info
	end
	local exports, info = UAsset.Parse(readFileRaw(path, where), map, o)
	reportAssets[normPath(path)] = info.Issues
	bucket[key] = { exports = exports, info = info, mtime = mtime }
	if o.cache == "copy" then return deepCopy(exports), deepCopy(info) end
	return exports, info
end

--- UAsset.ClearCache()                     forget everything
--- UAsset.ClearCache(map)                  forget everything parsed with that usmap
--- UAsset.ClearCache(map, "SB/Path/X.uasset" [, where])   forget one file (all option variants)
function UAsset.ClearCache(map, path, where)
	if map == nil then
		for k in pairs(cache) do cache[k] = nil end
		return
	end
	local bucket = cache[map]
	if not bucket then return end
	if path == nil then cache[map] = nil; return end
	local prefix = (where or "GAME") .. "|" .. normPath(path) .. "|"
	for k in pairs(bucket) do
		if sub(k, 1, #prefix) == prefix then bucket[k] = nil end
	end
end

--- number of cached files for a usmap
function UAsset.CacheCount(map)
	local n = 0
	for _ in pairs(cache[map] or {}) do n = n + 1 end
	return n
end

--------------------------------------------------------------------------------
-- undecoded-field report
--   Every ParseFile() remembers what it could not decode: failed exports (with the property path where
--   reading stopped), Niagara values of unknown type, references to missing files, and - optionally -
--   skipped exports and native payload that was left unread.
--   UAsset.BuildReport([includeInfo]) -> text      UAsset.DumpReport([includeInfo]) -> writes UAsset.ReportFile
--------------------------------------------------------------------------------
UAsset.ReportFile = "stellarblade/uasset_undecoded.txt"        -- inside garrysmod/data

function UAsset.UndecodedReport() return reportAssets end
function UAsset.ClearReport() reportAssets = {} end

local function causeOf(rec)
	if rec.kind == "error" then return rec.cause .. ": " .. tostring(rec.what) end
	if rec.kind == "niagara_value" then return "niagara value type not decoded: " .. tostring(rec.what) end
end

function UAsset.BuildReport(includeInfo)
	local paths = {}
	for path in pairs(reportAssets) do paths[#paths + 1] = path end
	table.sort(paths)

	local causes, unresolved, nAssets, nBad = {}, {}, #paths, 0
	local skipped, unreadTotal, unreadAssets = {}, 0, 0
	local detail = {}
	for _, path in ipairs(paths) do
		local lines, bad = {}, false
		local seen = {}                                   -- identical findings in one asset are printed once with a count
		for _, rec in ipairs(reportAssets[path]) do
			local ck = causeOf(rec)
			if ck then
				bad = true
				local c = causes[ck]
				if not c then c = { count = 0, assets = {}, nAssets = 0, example = { path, rec.export, rec.path } }; causes[ck] = c end
				c.count = c.count + 1
				if not c.assets[path] then c.assets[path] = true; c.nAssets = c.nAssets + 1 end
				local sig = rec.kind .. "|" .. tostring(rec.export) .. "|" .. tostring(rec.path) .. "|" .. ck
				if seen[sig] then
					seen[sig].n = seen[sig].n + 1
				elseif rec.kind == "error" then
					local entry = { n = 1, text = fmt("  ERROR  export '%s' (%s)  stopped at: %s\n         %s\n         -> %d top-level properties were decoded before it; everything after this field in that export is missing",
						tostring(rec.export), tostring(rec.class), rec.path ~= "" and rec.path or "(start)", ck, rec.decoded or 0) }
					seen[sig] = entry
					lines[#lines + 1] = entry
				else
					local entry = { n = 1, text = fmt("  VALUE  export '%s'  %s  (%s) - raw Bytes kept, no Decoded field", tostring(rec.export), tostring(rec.path), ck) }
					seen[sig] = entry
					lines[#lines + 1] = entry
				end
			elseif rec.kind == "unresolved" then
				bad = true
				local u = unresolved[rec.hash]
				if not u then u = { count = 0, assets = {}, nAssets = 0, example = { path, rec.export, rec.path } }; unresolved[rec.hash] = u end
				u.count = u.count + 1
				if not u.assets[path] then u.assets[path] = true; u.nAssets = u.nAssets + 1 end
				lines[#lines + 1] = fmt("  REF    export '%s'  %s  -> 0x%s (no file under the content root hashes to it)", tostring(rec.export), tostring(rec.path), rec.hash)
			elseif rec.kind == "skipped" then
				skipped[rec.class or "?"] = (skipped[rec.class or "?"] or 0) + 1
				if includeInfo then
					local sig = "skip|" .. tostring(rec.class)
					if seen[sig] then
						seen[sig].n = seen[sig].n + 1
						seen[sig].bytes = seen[sig].bytes + (rec.bytes or 0)
					else
						local entry = { n = 1, bytes = rec.bytes or 0, cls = tostring(rec.class) }
						seen[sig] = entry
						lines[#lines + 1] = entry
					end
				end
			elseif rec.kind == "unread" then
				unreadTotal = unreadTotal + (rec.bytes or 0)
				if includeInfo then lines[#lines + 1] = fmt("  UNREAD export '%s' (%s): %d bytes of native payload after the properties were not decoded", tostring(rec.export), tostring(rec.class), rec.bytes or 0) end
			end
		end
		if bad then nBad = nBad + 1 end
		if #lines > 0 then
			local texts = {}
			for k, l in ipairs(lines) do
				if type(l) == "table" and l.cls then
					texts[k] = fmt("  SKIP   %d x %s not decoded by choice (opts.skipTypes / skipPrefixes), %d bytes", l.n, l.cls, l.bytes)
				elseif type(l) == "table" then
					texts[k] = l.text .. (l.n > 1 and ("   (x" .. l.n .. ")") or "")
				else
					texts[k] = l
				end
			end
			detail[#detail + 1] = path .. "\n" .. concat(texts, "\n")
		end
	end

	local out = {}
	local function add(line) out[#out + 1] = line end
	add("UAsset undecoded-field report" .. (os and os.date and os.date("  (%Y-%m-%d %H:%M:%S)") or ""))
	add(fmt("assets parsed this session: %d   with undecoded data or missing references: %d", nAssets, nBad))
	add("")
	add("== UNDECODED, GROUPED BY CAUSE (most common first) ==")
	local ordered = {}
	for ck, c in pairs(causes) do ordered[#ordered + 1] = ck end
	table.sort(ordered, function(a, b) if causes[a].count ~= causes[b].count then return causes[a].count > causes[b].count end return a < b end)
	if #ordered == 0 then add("  (nothing)") end
	for _, ck in ipairs(ordered) do
		local c = causes[ck]
		add(fmt("  %5d x  %s   [%d asset%s]", c.count, ck, c.nAssets, c.nAssets == 1 and "" or "s"))
		add(fmt("           e.g. %s  export '%s'  %s", c.example[1], tostring(c.example[2]), tostring(c.example[3] or "")))
	end
	add("")
	add("== REFERENCES TO FILES THAT ARE NOT UNDER THE CONTENT ROOT ==")
	local uh = {}
	for h in pairs(unresolved) do uh[#uh + 1] = h end
	table.sort(uh, function(a, b) if unresolved[a].count ~= unresolved[b].count then return unresolved[a].count > unresolved[b].count end return a < b end)
	if #uh == 0 then add("  (none)") end
	for _, h in ipairs(uh) do
		local u = unresolved[h]
		add(fmt("  0x%s  %d reference%s in %d asset%s   first: %s  export '%s'  %s", h, u.count, u.count == 1 and "" or "s", u.nAssets, u.nAssets == 1 and "" or "s",
			u.example[1], tostring(u.example[2]), tostring(u.example[3] or "")))
	end
	add("")
	add("== INFO (not errors) ==")
	local sk = {}
	for cls, n in pairs(skipped) do sk[#sk + 1] = fmt("%s x%d", cls, n) end
	table.sort(sk)
	add("  exports skipped by choice: " .. (#sk > 0 and concat(sk, ", ") or "none"))
	add(fmt("  native payload left unread: %d KB in total (meshes, audio, animation...)   run 'uasset_dumpundecoded all' to list it per export", floor(unreadTotal / 1024)))
	add("")
	add("== DETAILS PER ASSET ==")
	if #detail == 0 then add("  (nothing)") end
	for _, d in ipairs(detail) do add(d) end
	return concat(out, "\n") .. "\n", { causes = causes, ordered = ordered, unresolved = unresolved, assets = nAssets, bad = nBad }
end

--- Write the report to data/<UAsset.ReportFile>. Returns true, path | false, reason.
function UAsset.DumpReport(includeInfo)
	if not (file and file.Write) then return false, "no file library" end
	local text, summary = UAsset.BuildReport(includeInfo)
	local dir = UAsset.ReportFile:match("^(.*)/[^/]+$")
	if dir and file.CreateDir then file.CreateDir(dir) end
	file.Write(UAsset.ReportFile, text)
	return true, UAsset.ReportFile, summary
end

--------------------------------------------------------------------------------
-- console commands (server console / listen-server host / superadmins)
--   uasset_savehashcache         write the package index to garrysmod/data/stellarblade/folderhashmap.json
--   uasset_loadhashcache         reload the index from that file; recreate (rescan + save) if it is missing/unusable
--   uasset_refreshpackageindex   rescan data_static/SB/Content from disk without freezing the game
--   uasset_dumpundecoded [all]   write every field/export that could not be decoded to data/stellarblade/uasset_undecoded.txt
--   uasset_clearundecoded        forget the collected report
--------------------------------------------------------------------------------
if concommand and concommand.Add then
	local function say(ply, msg)
		if IsValid and IsValid(ply) then ply:PrintMessage(HUD_PRINTCONSOLE, msg .. "\n") else MsgN(msg) end
	end
	local function allowed(ply)
		if IsValid and IsValid(ply) and not ply:IsSuperAdmin() then say(ply, "[UAsset] superadmin only"); return false end
		return true
	end
	local function saveAndReport(ply)
		local ok, a, b = UAsset.SaveHashCache(true)
		if ok then say(ply, fmt("[UAsset] saved %d package hashes (%d KB) to data/%s", a, floor(b / 1024), UAsset.HashCacheFile))
		else say(ply, "[UAsset] could not save hash cache: " .. tostring(a)) end
	end

	concommand.Add("uasset_savehashcache", function(ply)
		if not allowed(ply) then return end
		if UAsset.IsScanning() then return say(ply, "[UAsset] a rescan is running; try again when it has finished") end
		if not pkgIndex then
			say(ply, "[UAsset] no index in memory yet - scanning first, then saving")
			local ok, err = UAsset.RefreshPackageIndexAsync(function(done) if done then saveAndReport(ply) end end)
			if not ok then say(ply, "[UAsset] " .. tostring(err)) end
			return
		end
		saveAndReport(ply)
	end)

	concommand.Add("uasset_dumpundecoded", function(ply, cmd, args)
		if not allowed(ply) then return end
		local all = args and args[1] == "all"
		local ok, path, summary = UAsset.DumpReport(all)
		if not ok then return say(ply, "[UAsset] could not write the report: " .. tostring(path)) end
		say(ply, fmt("[UAsset] %d assets parsed, %d with undecoded data or missing references. Written to data/%s%s",
			summary.assets, summary.bad, path, all and " (with info lines)" or ""))
		for i = 1, math.min(#summary.ordered, 12) do
			local ck = summary.ordered[i]
			say(ply, fmt("  %5d x %s  [%d assets]", summary.causes[ck].count, ck, summary.causes[ck].nAssets))
		end
		local nu = 0
		for _ in pairs(summary.unresolved) do nu = nu + 1 end
		if nu > 0 then say(ply, fmt("  %d distinct unresolved file references (listed in the report)", nu)) end
	end)

	concommand.Add("uasset_clearundecoded", function(ply)
		if not allowed(ply) then return end
		UAsset.ClearReport()
		say(ply, "[UAsset] undecoded-field report cleared (it fills again as assets are parsed; cached assets are not re-parsed, run UAsset.ClearCache() to re-collect)")
	end)

	concommand.Add("uasset_refreshpackageindex", function(ply)
		if not allowed(ply) then return end
		local ok, err = UAsset.RefreshPackageIndexAsync(function(done, n)
			if done then say(ply, fmt("[UAsset] package index rebuilt: %d hashes. Run uasset_savehashcache to store it.", n))
			else say(ply, "[UAsset] rescan failed: " .. tostring(n)) end
		end)
		say(ply, ok and "[UAsset] rescanning in the background..." or ("[UAsset] " .. tostring(err)))
	end)

	concommand.Add("uasset_loadhashcache", function(ply)
		if not allowed(ply) then return end
		if UAsset.IsScanning() then return say(ply, "[UAsset] a rescan is running; try again when it has finished") end
		local ok, a = UAsset.LoadHashCache(true)
		if ok then return say(ply, fmt("[UAsset] loaded %d package hashes from data/%s", a, UAsset.HashCacheFile)) end
		say(ply, "[UAsset] " .. tostring(a) .. " - recreating it from disk...")
		local started, err = UAsset.RefreshPackageIndexAsync(function(done) if done then saveAndReport(ply) end end)
		if not started then say(ply, "[UAsset] " .. tostring(err)) end
	end)
end

return UAsset