-- effects/ns_a_burstarea_1.lua
-- Recreates the lightning-pillar ring sweep using render.AddBeam and an animated electric texture.
-- Replace SCALE_LUT and LATHE_LUT with the exact ShaderLUT arrays from your JSON for bit-perfect results.

EFFECT.Material = Material("sprites/mi_b_electric_01_4.vmt") -- animated texture proxy vmt you requested

-- ========== USER-SUPPLIED LOOKUP TABLES ==========
-- SCALE_LUT is a flat list of pairs: { x0, y0, x1, y1, x2, y2, ... }
-- Each pair represents the Vector2 sample at equal intervals across normalized particle life.
-- Replace this rough approx with the exact floats from the JSON (the ShaderLUT block of the Vector2 curve).
local SCALE_LUT = {
	-- best-effort / approximate; replace with exact JSON values for perfect reproduction
	0.500000, 1.000000,
	0.677777, 1.000000,
	0.855555, 1.000000,
	1.033333, 1.000000,
	1.291111, 1.000000,
	1.490000, 1.000000,
	1.258333, 1.000000,
	1.068000, 1.000000,
	0.807777, 1.000000,
	0.000000, 1.000000
}

-- LATHE_LUT is the radial multiplier profile used to place beams around the ring.
-- Replace with the exact ShaderLUT from the "Lathe Profile" NiagaraDataInterfaceCurve.
local LATHE_LUT = {
	-- approx. values; replace with JSON's lathe ShaderLUT for exact geometry
	1.00,0.94,0.90,0.88,0.87,0.85,0.83,0.82,0.80,0.78,0.75,0.72,
	0.70,0.68,0.66,0.64,0.62,0.60,0.58,0.56,0.54,0.52,0.50,0.48,
	0.45,0.43,0.41,0.39,0.37,0.35,0.33,0.31,0.30,0.28,0.26,0.24,
	0.22,0.20,0.18,0.16,0.15,0.14,0.13,0.12,0.11,0.10,0.09,0.08,
	0.07,0.06,0.05,0.04,0.03,0.02,0.01,0.00
}

-- ==================================================
-- small helper: evaluate a 1D curve stored as flat pairs
local function EvalVector2Curve(flatPairs, t)
	-- t in [0,1], returns two floats x,y
	local nPairs = #flatPairs / 2
	if nPairs <= 0 then return 1, 1 end
	if t <= 0 then return flatPairs[1], flatPairs[2] end
	if t >= 1 then
		local ix = (nPairs - 1) * 2 + 1
		return flatPairs[ix], flatPairs[ix+1]
	end
	local fIndex = t * (nPairs - 1)
	local i0 = math.floor(fIndex)
	local frac = fIndex - i0
	local aIdx = i0 * 2 + 1 -- Lua 1-based
	local bIdx = (i0+1) * 2 + 1
	local ax, ay = flatPairs[aIdx], flatPairs[aIdx+1]
	local bx, by = flatPairs[bIdx], flatPairs[bIdx+1]
	local x = Lerp(frac, ax, bx)
	local y = Lerp(frac, ay, by)
	return x, y
end

-- sample lathe: LATHE_LUT is a 1D sample list (not paired)
local function EvalLatheSample(i)
	-- i in [1 .. #LATHE_LUT]
	return LATHE_LUT[i] or 1.0
end

-- Init: create internal beam list and compute spawn timing
function EFFECT:Init(data)
	self.Origin = data:GetOrigin() or vector_origin
	self.Angles = data:GetAngles() or Angle(0,0,0)
	self.Scale = math.max(1, (data:GetScale() or 1))  -- user-supplied scale, default 1
	self.Duration = (data:GetMagnitude() ~= 0) and data:GetMagnitude() or 2.65 -- emitter total duration fallback

	-- Beam lifetime (per beam). We pick a conservative short lifetime so beams scale and vanish.
	self.BeamLife = math.min(1.25, self.Duration * 0.7)

	-- Lathe: number of points is the number of samples in LATHE_LUT
	self.NumBeams = #LATHE_LUT
	if self.NumBeams < 3 then self.NumBeams = 16 end

	-- Sweep timing: spawn beams in sequence across emitter duration
	self.SpawnInterval = math.max(0.0001, self.Duration / self.NumBeams)

	self.NextSpawnTime = CurTime()
	self.SpawnIndex = 1
	self.Beams = {} -- each entry: {pos, spawnTime, life, dir, baseRadiusIndex}

	-- precompute ring orientation vectors from angle
	self.Right = self.Angles:Right()
	self.Forward = self.Angles:Forward()
	self.Up = self.Angles:Up()

	-- default color (electric cyan); you can change to match JSON exact color curve
	self.Color = Color(140, 220, 255, 255)

	-- seed-based jitter: optionally use data:GetRadius or data:GetScale as base radius
	-- In your Niagara data the radius was passed as a user param; here we map data:GetScale() => base physical radius
	self.BaseRadius = 1200 * (self.Scale or 1) -- default to the radius value observed in your SBShow bytes (1200). Override by setting data:SetScale when spawning the effect.

	-- mark creation time
	self.StartTime = CurTime()
	self.EndTime = self.StartTime + self.Duration

	-- a small performance clamp: keep a maximum number of active beams simultaneously
	self.MaxActive = math.max(64, self.NumBeams)

	-- material ready
	render.SetMaterial(self.Material)
end

-- Think: spawn beams sequentially, cull old beams, return false when done
function EFFECT:Think()
	local cur = CurTime()

	-- spawn sweep: spawn one beam per interval, using LATHE_LUT radial multiplier
	while self.SpawnIndex <= self.NumBeams and cur >= self.NextSpawnTime do
		local i = self.SpawnIndex
		local angle = (i-1) / self.NumBeams * math.pi * 2
		local radial = EvalLatheSample(i) or 1.0
		local r = (self.BaseRadius * radial)

		-- compute position in the plane transformed by data:GetAngles()
		local posOffset = (self.Right * math.cos(angle) + self.Forward * math.sin(angle)) * r
		local pos = self.Origin + posOffset

		-- beam direction from center to pos (points outward)
		local dir = (pos - self.Origin)
		local dirlen = dir:Length()
		if dirlen == 0 then dirlen = 1 end
		dir = dir / dirlen

		-- sample scale curve at spawn-time (we also evaluate in render per-frame)
		local startFactorX, startFactorY = EvalVector2Curve(SCALE_LUT, 0) -- at normalized age 0
		local endFactorX, endFactorY = EvalVector2Curve(SCALE_LUT, 1)   -- at normalized age 1

		local beam = {
			pos = pos,
			dir = dir,
			spawnTime = cur,
			life = self.BeamLife,
			startFactor = startFactorX, -- width factor over life; evaluated in render too
			endFactor = endFactorX,
			peakFactor = nil, -- we can optionally store peak values for diagnostics
			angle = angle
		}
		table.insert(self.Beams, beam)

		-- advance spawn index/time
		self.SpawnIndex = self.SpawnIndex + 1
		self.NextSpawnTime = self.NextSpawnTime + self.SpawnInterval

		-- safety cap
		if #self.Beams > self.MaxActive then
			table.remove(self.Beams, 1)
		end
	end

	-- remove dead beams
	for i = #self.Beams, 1, -1 do
		local b = self.Beams[i]
		if CurTime() > b.spawnTime + b.life then
			table.remove(self.Beams, i)
		end
	end

	-- keep effect alive until the emitter duration has passed or there are active beams
	local alive = (cur < self.EndTime) or (#self.Beams > 0)
	return alive
end

-- Render: draws all active beams using the animated material
function EFFECT:Render()
	if not self.Material then return end
	render.SetMaterial(self.Material)

	local cur = CurTime()
	for _, b in ipairs(self.Beams) do
		local age = (cur - b.spawnTime) / b.life
		if age < 0 then age = 0 end
		if age > 1 then age = 1 end

		-- Evaluate width multiplier from the SCALE curve at this normalized age:
		local widthFactor = EvalVector2Curve(SCALE_LUT, age)
		-- widthFactor is (x,y) but we use x as beam width multiplier
		local w = widthFactor
		if type(w) == "table" then w = w[1] end -- safety

		-- derive real beam width in world units:
		local beamWidth = (w or 1.0) * (self.Scale or 1.0) * 8 -- 8 is a base pixel/world width: tweak to taste

		-- alpha fade: we fade out using age and the curve (so it disappears smoothly)
		local alpha = math.floor(255 * (1 - age))
		local col = Color(self.Color.r, self.Color.g, self.Color.b, alpha)

		-- beam start & end positions: center -> ring point
		local startPos = self.Origin
		local endPos = b.pos

		-- texture U coordinate: stretch by beam length (optionally)
		local beamLen = (endPos - startPos):Length()
		local texCoord = math.max(1, beamLen / 64)

		-- final render
		render.DrawBeam(startPos, endPos, beamWidth, 0, texCoord, col)
	end
end
