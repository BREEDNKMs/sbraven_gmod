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
-- Zen package header  (UE4.26 / 4.27 "Initial" container layout)
--------------------------------------------------------------------------------
local function mappedNameText(names, idx, extra)
	local n = names[idx + 1]
	if n == nil then fail("name index %d out of range (name map has %d entries)", idx, #names) end
	if extra and extra > 0 then return n .. "_" .. (extra - 1) end
	return n
end

local function parseHeader(data, map, opts)
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
	if cur > #data then fail("export data runs past the end of the file (%d > %d)", cur, #data) end

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
	d.className = c and c.name or nil
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

local function descToJson(pkg, d, opts)
	if d == nil then return opts.nullValue end
	if d.kind == "unresolved" and d.import then
		if opts.importResolver then
			local r = opts.importResolver(d.import)
			if r then return r end
		end
		return { ObjectName = "Unresolved'0x" .. d.import.key .. "'", ObjectPath = "0x" .. d.import.key, Unresolved = true }
	end
	local top = d
	while top.outer do top = top.outer end
	local path = top.name
	if d.exportIndex then path = path .. "." .. d.exportIndex end
	return { ObjectName = fullName(d), ObjectPath = path }
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
		return descToJson(pkg, exportDesc(pkg, idx - 1), ctx.opts)
	end
	local imp = pkg.imports[-idx]
	if not imp then fail("import index %d out of range", idx) end
	return descToJson(pkg, resolveObjectIndex(pkg, imp.hi, imp.lo), ctx.opts)
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
	for i = 1, n do out[i] = readValue(ctx, inner, ARRAY) end
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
	for i = 1, r:i32() do
		local k = readValue(ctx, kt, MAP)
		local v = readValue(ctx, vt, MAP)
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

-- natively serialized in the engine => must not be read through the usmap schema
local UNSUPPORTED_NATIVE = {}
for n in ([[Matrix Matrix44f Plane Plane4f Plane4d Sphere Sphere3f Sphere3d CapsuleShape Box2D Box2f Box3f
 RichCurveKey SimpleCurveKey NameCurveKey StringCurveKey SmartName PerPlatformBool PerPlatformFloat PerPlatformInt
 PerPlatformFrameRate PerPlatformFString PerQualityLevelInt PerQualityLevelFloat FontData FontCharacter
 InstancedStruct InstancedStructContainer InstancedPropertyBag Transform3f TwoVectors Spline UniqueNetIdRepl
 MovieSceneFloatChannel MovieSceneDoubleChannel MovieSceneFloatValue MovieSceneDoubleValue MovieSceneFrameRange
 MovieSceneSegment MovieSceneEvaluationKey NiagaraVariable NiagaraVariableBase ExpressionInput ColorMaterialInput
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
				local v = readValue(ctx, p.type, NORMAL)
				out[p.arrayIndex > 0 and (p.name .. "[" .. p.arrayIndex .. "]") or p.name] = v
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

local function readExport(ctx, pkg, e, i, warnings, unread)
	local desc = exportDesc(pkg, i - 1)
	local out = {
		Type = desc.className or "UObject",
		Name = e.name,
		Flags = flagString(bor(e.flags, 0x80000, 0x200000)),
	}
	local cdesc = resolveObjectIndex(pkg, e.classHi, e.classLo)
	if cdesc then out.Class = "UScriptClass'" .. cdesc.name .. "'" end
	if desc.outer and desc.outer.kind ~= "package" then
		out.Outer = descToJson(pkg, desc.outer, ctx.opts)
	else
		out.Package = pkg.name
	end
	local sdesc = resolveObjectIndex(pkg, e.superHi, e.superLo)
	if sdesc and sdesc.kind == "export" then out.Super = descToJson(pkg, sdesc, ctx.opts) end
	local tdesc = resolveObjectIndex(pkg, e.templateHi, e.templateLo)
	if tdesc and tdesc.kind == "export" then out.Template = descToJson(pkg, tdesc, ctx.opts) end

	local skip = ctx.opts.skipTypes
	local cn = desc.className
	if cn and ((skip and skip[cn]) or false) then out.Skipped = true; return out end
	local pre = ctx.opts.skipPrefixes
	if cn and pre then
		for _, pf in ipairs(pre) do
			if sub(cn, 1, #pf) == pf then out.Skipped = true; return out end
		end
	end

	local r = ctx.r
	r.p = e.pos
	local map = ctx.map
	local isDT = false

	local function body()
		local st = desc.className and getStruct(map, desc.className)
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
				rows[key] = readStructFields(ctx, rowSt)
			end
		end
	end

	local ok, err = pcall(body)
	if out.Properties and next(out.Properties) == nil then out.Properties = nil end
	if not ok then
		if ctx.opts.strict then error(err, 0) end
		-- keep whatever was read before the failure; the rest of this export is lost
		out._Error = tostring(err)
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
	local ctx = { pkg = pkg, map = map, opts = o, names = pkg.names, r = newReader(data) }
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
	}
end

--------------------------------------------------------------------------------
-- file cache
--   Keyed by the FULL path you pass in ("SB/Path/To/Blah.uasset" and "SB/NewPath/To/Blah.uasset" are
--   different entries, even though both are called Blah), the search path ("GAME", "DATA", ...) and the
--   usmap table. Entries are dropped automatically when file.Time() reports a newer file (GMod).
--------------------------------------------------------------------------------
local cache = setmetatable({}, { __mode = "k" })        -- [mappingsTable] = { [key] = entry }

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
	if o.cache == false then return UAsset.Parse(readFileRaw(path, where), map, o) end
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

return UAsset
