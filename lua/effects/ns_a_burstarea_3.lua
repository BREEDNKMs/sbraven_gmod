-- lua/effects/ns_a_lightningpillarm9/init.lua
-- Garry's Mod EFFECT that approximates NE_LightningPillarM_9 behaviour
-- Emits sprites/t_a_shineflare_02.vmt at random 2D positions around origin
-- with an interpolated sweep and simple curve-based scale/alpha.

local function Lerp(a, b, t) return a + (b - a) * t end
local function Clamp(x, lo, hi) return math.max(lo, math.min(hi, x)) end

-- simple linear curve sampler
local function SampleCurve(samples, t)
	-- samples = { {time0, val0}, {time1, val1}, ... } times in [0,1]
	if #samples == 0 then return 0 end
	if t <= samples[1][1] then return samples[1][2] end
	for i = 1, #samples - 1 do
		local t0, v0 = samples[i][1], samples[i][2]
		local t1, v1 = samples[i+1][1], samples[i+1][2]
		if t >= t0 and t <= t1 then
			local nt = (t - t0) / (t1 - t0)
			return Lerp(v0, v1, nt)
		end
	end
	return samples[#samples][2]
end

-- simple ease in-out quad (used optionally)
local function EaseInOutQuad(t)
	if t < 0.5 then return 2 * t * t end
	return -1 + (4 - 2 * t) * t
end

-- Create a material reference once
local MAT_FLARE = Material("sprites/t_a_shineflare_02.vmt")

-- Configuration defaults (tweak these to taste)
local DEFAULT_NUM_SAMPLES = 48        -- how many points around the ring
local BASE_RADIUS = 180              -- base radius in world units (multiplied by scale)
local RADIUS_JITTER = 24             -- random jitter per point
local Z_OFFSET = 6                    -- slight z offset so sprite sits above ground
local SWEEP_FRACTION = 0.6           -- fraction of lifetime used to sweep all points
local BASE_PIXEL_SIZE = 24           -- base sprite size in world units

-- An approximate vector2 scale curve (width, height)
-- These are sampled by normalized age and produce multipliers.
-- Replace with exact JSON-extracted samples for full fidelity.
local WIDTH_CURVE = {
	{0.00, 0.18},
	{0.08, 1.00},
	{0.40, 0.78},
	{1.00, 0.00}
}
local HEIGHT_CURVE = {
	{0.00, 0.40},
	{0.08, 2.20},
	{0.40, 1.80},
	{1.00, 0.18}
}

-- Color/alpha curve: alpha pulses in quickly then decays
local ALPHA_CURVE = {
	{0.00, 0.05},
	{0.06, 1.00},
	{0.70, 0.95},
	{1.00, 0.00}
}

local COLOR_BASE = Color(140, 220, 255) -- electric cyan tint

-- EFFECT table
function EFFECT:Init(data)
	-- world-level inputs
	self.Origin = data:GetOrigin() or Vector(0,0,0)
	self.Angles = data:GetAngles() or Angle(0,0,0)
	self.Scale = tonumber(data:GetScale()) or 1
	if self.Scale <= 0 then self.Scale = 1 end

	-- Per-emitter lifetime override (in seconds)
	self.Lifetime = tonumber(data:GetMagnitude()) or 1.0
	if self.Lifetime <= 0 then self.Lifetime = 1.0 end

	self.StartTime = CurTime()

	-- configuration derived from scale
	self.NumPoints = math.Clamp(math.floor(DEFAULT_NUM_SAMPLES * self.Scale), 6, 256)
	self.Radius = BASE_RADIUS * self.Scale
	self.SweepDuration = math.min(self.Lifetime * SWEEP_FRACTION, 0.8) -- sweep completes in this time

	-- build sample positions (random 2D vectors around origin)
	-- keep angle information so sweep order sorts by angle (makes sweep look circular)
	-- replace this with target light locations 
	self.Points = {}
	math.randomseed(math.Round(CurTime() * 1000) % 2^31)
	for i = 1, self.NumPoints do
		-- random angle but we'll sort to produce a sweep
		local ang = math.random() * math.pi * 2
		local r = self.Radius + (math.random() * 2 - 1) * RADIUS_JITTER
		local x = math.cos(ang) * r
		local y = math.sin(ang) * r
		local z = Z_OFFSET + (math.random() * 8 - 4) -- small Z variation
		table.insert(self.Points, { pos = self.Origin + Vector(x, y, z), angle = ang, baseR = r })
	end

	-- sort points by angle to create a nice sweeping order (clockwise)
	table.sort(self.Points, function(a,b) return a.angle < b.angle end)

	-- spawn schedule: each point gets a spawnTime offset so they appear swept around the ring
	self.Particles = {}
	for i, p in ipairs(self.Points) do
		local frac = (i - 1) / #self.Points
		local spawnDelay = frac * self.SweepDuration -- spread across sweep period
		local spawnAt = self.StartTime + spawnDelay
		local life = self.Lifetime -- each particle lives for the emitter lifetime (overrideable later)
		-- we keep per-particle seed/rotation for slight variation
		local rotation = math.deg(p.angle) + math.Rand(-20, 20)
		table.insert(self.Particles, {
			pos = p.pos,
			angle = rotation,
			spawnAt = spawnAt,
			life = life,
			alive = false,
			-- optional random flick phase:
			phase = math.random()
		})
	end

	-- bounding box: set effect to persist until last particle dies
	local maxEnd = self.StartTime + self.SweepDuration + self.Lifetime
	self.EndTime = maxEnd

	-- pre-cache material
	self.Mat = MAT_FLARE
end

function EFFECT:Think()
	local now = CurTime()

	-- If all particles have finished, kill effect
	if now > self.EndTime then
		return false
	end

	-- optionally update particles' pos if you'd want them to move or track an entity.
	-- For now, they are static world positions generated at Init.

	return true
end

function EFFECT:Render()
	local now = CurTime()
	if not self.Mat then
		self.Mat = Material("sprites/t_a_shineflare_02.vmt")
	end

	render.SetMaterial(self.Mat)
	-- draw each particle if its spawn time has passed and it hasn't expired
	for i, p in ipairs(self.Particles) do
		if now < p.spawnAt then
			-- not spawned yet
		elseif now > p.spawnAt + p.life then
			-- dead
		else
			local age = (now - p.spawnAt) / p.life
			age = Clamp(age, 0, 1)

			-- sample width/height multipliers (approx Vector2 curve)
			local wMul = SampleCurve(WIDTH_CURVE, age)
			local hMul = SampleCurve(HEIGHT_CURVE, age)

			-- overall base size (world units)
			local base = BASE_PIXEL_SIZE * self.Scale

			-- compute final size: use height as sprite size; width can be used to offset and fake anisotropy
			local size = base * hMul
			local width = base * wMul

			-- alpha from alpha curve, apply ease for smoother fade
			local rawAlpha = SampleCurve(ALPHA_CURVE, age)
			local alpha = Clamp(rawAlpha, 0, 1)
			-- apply a slight ease to alpha
			alpha = Lerp(0, alpha, EaseInOutQuad(age))

			local color = Color(
				math.floor(COLOR_BASE.r),
				math.floor(COLOR_BASE.g),
				math.floor(COLOR_BASE.b),
				math.floor(255 * alpha)
			)

			-- Anchor the sprite slightly above the ground so it looks like a pillar
			-- We offset by a fraction of the height so the base sits at the point.
			local offsetUp = Vector(0, 0, size * 0.45 * self.Scale)
			local drawPos = p.pos + offsetUp

			-- If you want the sprite to face along a direction (velocity aligned),
			-- you'd calculate an orientation and draw a rotated quad. For simplicity
			-- we draw sprites (square) and use an offset to simulate a vertical pillar.
			render.DrawSprite(drawPos, size, size, color)

			-- Optionally draw a small base glow with smaller sprite and additive alpha
			local baseCol = Color(color.r, color.g, color.b, math.max(16, color.a * 0.5))
			render.DrawSprite(p.pos, size * 0.38, size * 0.38, baseCol)
		end
	end
end
