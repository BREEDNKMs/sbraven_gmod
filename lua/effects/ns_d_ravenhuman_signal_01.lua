-- effects/ns_d_ravenhuman_signal_01/init.lua
-- Simulates ns_d_ravenhuman_signal_01 (approximation of the Niagara emitter from JSON)
-- Uses CLuaEmitter if available, falls back to ParticleEmitter.

local MI_A_LensObj_Horizon_01_2 = "sprites/MI_A_LensObj_Horizon_01_2" 
local MI_A_LensObj_Horizon_01_3 = "sprites/MI_A_LensObj_Horizon_01_3" 
local MI_A_LensObj_Horizon_01_5 = "sprites/MI_A_LensObj_Horizon_01_5" 
local MI_A_LensObj_Horizon_01_4 = "sprites/MI_A_LensObj_Horizon_01_4" 
local MI_A_Flares_01_8 = "sprites/MI_A_Flares_01_8" 
local MI_B_LensCircle_01_18 = "sprites/MI_B_LensCircle_01_18" 

local function LerpColor(t, c1, c2)
		return Color(
			Lerp(t, c1.r, c2.r),
			Lerp(t, c1.g, c2.g),
			Lerp(t, c1.b, c2.b),
			Lerp(t, c1.a or 255, c2.a or 255)
		)
	end

function EFFECT:Init(data) 
	self:NE_FlareHorizonM(data) 
	self:NE_FlareHorizonM002_8(data) 
	self:NE_FlareHorizonM003_10(data) 
	self:NE_FlareHorizonM004_12(data) 
	self:NE_FlareM(data) 
	self:NE_FlareM002_1(data) 
	self:NE_LightM(data) 
end 

function EFFECT:NE_FlareHorizonM(data) 
	-- Get position and angles from the effect data
    local pos = data:GetOrigin()
    local ang = data:GetAngles()
    local ent = data:GetEntity()
    self:SetPos(pos)
    self:SetAngles(ang)

    -- Get scale and lifetime multipliers, with default values of 1
    self.Scale = data:GetScale() ~= 0 and data:GetScale() or 0.1
    self.Scale = self.Scale * 0.1

    local lifetimeMultiplier = data:GetMagnitude() ~= 0 and data:GetMagnitude() or 1

    -- ----------------------------------------------------------------------------
    -- Parameters & approximated curve samplers (these mimic the Niagara curves)
    -- ----------------------------------------------------------------------------

    -- Base lifetime (seconds) — Niagara stores lifetime on the particle; we choose a plausible default.
    -- This value is multiplied by lifetimeMultiplier to allow tuning from Lua callsite.
    local BASE_LIFETIME = 1.0
    local lifetime = BASE_LIFETIME * lifetimeMultiplier

    -- Base sprite "size" (in units). Niagara used a SpriteSize Vector2 driven by a Vector2Curve.
    -- We use a base size and then scale it by self.Scale and by a sampled scale factor.
    local BASE_SIZE = 100 -- chosen to look like a horizon lens flare; you can tune this.
    -- Apply self.Scale as global multiplier (user provided), matching your startup snippet intent.
    BASE_SIZE = BASE_SIZE * math.max(0.0001, self.Scale)

    -- Helper: ease function (smoothstep-like)
    local function easeSmooth01(t)
        -- Smoothstep cubic (3t^2 - 2t^3)
        return t * t * (3 - 2 * t)
    end

    -- Sampled alpha curve approximation (normalizedAge in [0,1])
    -- Mimics: quick fade-in, hold near full opacity, then fade-out at end.
    local function sampleAlphaCurve(n)
        if n <= 0 then return 0 end
        if n < 0.12 then
            -- fade in (0 -> 1)
            return easeSmooth01(n / 0.12)
        elseif n < 0.80 then
            -- hold near full
            return 1
        elseif n < 1.0 then
            -- fade out (1 -> 0)
            return easeSmooth01(1 - (n - 0.80) / 0.20)
        else
            return 0
        end
    end

    -- Sampled color curve approximation (normalizedAge in [0,1])
    -- Mimics a warm tint early -> cooler/white near middle/end.
    local function sampleColorCurve(n)
        -- Colors are returned as R,G,B in 0-255
        local warm = Vector(255, 200, 150)   -- warm orange-ish tint
        local neutral = Vector(255, 255, 255) -- white
        -- interpolate with a subtle tint shift using smoothstep
        local t = easeSmooth01(math.min(math.max((n - 0.05) / 0.9, 0), 1))
        local v = warm * (1 - t) + neutral * t
        return math.Clamp(v.x, 0, 255), math.Clamp(v.y, 0, 255), math.Clamp(v.z, 0, 255)
    end

    -- Sampled 2D-scale curve approximation (normalizedAge in [0,1])
    -- Returns Vector2-like scale (we use a single uniform scalar).
    -- Mimics: small growth, slight peak, then slow shrink.
    local function sampleScaleCurve(n)
        -- start smaller, peak near 0.35, then slowly reduce towards 1.0
        if n <= 0 then return 0.35 end
        local peakT = 0.35
        if n < peakT then
            -- grow 0.35 -> 1.1
            return 0.35 + (1.1 - 0.35) * easeSmooth01(n / peakT)
        else
            -- shrink 1.1 -> 0.9 (soft fade out)
            local tt = (n - peakT) / (1 - peakT)
            return 1.1 + (0.9 - 1.1) * easeSmooth01(tt)
        end
    end

    -- ----------------------------------------------------------------------------
    -- Create particle(s)
    -- The original Niagara emitter likely spawns a small burst of particles.
    -- We'll spawn a few overlapping sprites to better approximate the lens-flare feel.
    -- ----------------------------------------------------------------------------

    -- how many sub-sprites to spawn for the flare (keeps the look richer)
    local NUM_SUBPARTICLES = 3
	local emitter  = ParticleEmitter(pos)

    -- Emit several layered sprites with slightly different parameters to mimic the effect.
    for i = 1, NUM_SUBPARTICLES do
        -- jitter the spawn pos slightly along the emitter's forward to create variation
        local jitterForward = (i - (NUM_SUBPARTICLES + 1) / 2) * 4 * (i / NUM_SUBPARTICLES)
        local spawnPos = pos + ang:Forward() * jitterForward

        -- Create particle
        -- CLuaEmitter:Add / ParticleEmitter:Add both generally accept material or texture string.
		particle = emitter:Add(MI_A_LensObj_Horizon_01_3, spawnPos)

        if not particle then continue end

        -- Decide per-subparticle life offset to create a natural spread
        local lifeJitter = Lerp((i - 1) / math.max(1, NUM_SUBPARTICLES - 1), 0.9, 1.15)
        local pDie = lifetime * lifeJitter

        -- Sample curve endpoints to map into Particle:SetStart/End values (Niagara does per-frame sampling on GPU).
        local startAlpha = sampleAlphaCurve(0)   -- [0..1]
        local endAlpha   = sampleAlphaCurve(1)   -- [0..1]
        local startScale = sampleScaleCurve(0)   -- scalar
        local endScale   = sampleScaleCurve(1)   -- scalar
        local sr, sg, sb = sampleColorCurve(0)
        local er, eg, eb = sampleColorCurve(1)

        -- Particle start/end size (Particle:SetStartSize/SetEndSize uses absolute units)
        local startSize = BASE_SIZE * startScale * Lerp(0.7, 0.9, i / NUM_SUBPARTICLES) -- small variation
        local endSize   = BASE_SIZE * endScale   * Lerp(0.9, 1.1, i / NUM_SUBPARTICLES)

        -- Map alpha [0..1] -> 0..255 for particle API
        local startAlpha255 = math.Clamp(math.floor(startAlpha * 255 + 0.5), 0, 255)
        local endAlpha255   = math.Clamp(math.floor(endAlpha * 255 + 0.5), 0, 255)

        -- Set particle properties (covers position, life, size, alpha, color, roll)
        particle:SetDieTime(pDie)
        particle:SetStartAlpha(startAlpha255)
        particle:SetEndAlpha(endAlpha255)
        particle:SetStartSize(startSize)
        particle:SetEndSize(endSize)

        -- Set a mild velocity outward so horizon-like flares can drift slightly
        local vel = ang:Forward() * math.Rand(2, 12) + VectorRand() * math.Rand(0, 6)
        particle:SetVelocity(vel)

        -- Rotation behavior
        particle:SetRoll(math.Rand(0, 360))
        particle:SetRollDelta(math.Rand(-8, 8))

        -- Color: we can't animate color per-particle easily with basic Particle API,
        -- so pick a mid-life color that approximates the color curve (blend start+end).
        local midR = math.Clamp(math.floor((sr + er) * 0.5 + 0.5), 0, 255)
        local midG = math.Clamp(math.floor((sg + eg) * 0.5 + 0.5), 0, 255)
        local midB = math.Clamp(math.floor((sb + eb) * 0.5 + 0.5), 0, 255)
        particle:SetColor(midR, midG, midB)

        -- Material random/dynamic parameter: set a small random to vary the material if it uses that param
        -- Many Niagara lens materials accept a parameter for distortion/randomness; we emulate that with a float.
        particle:SetLighting(false) 

        -- Slightly enlarge alpha for center particle to make the effect pop
        if i == math.ceil(NUM_SUBPARTICLES / 2) then
            particle:SetStartAlpha(math.min(255, startAlpha255 + 24))
            particle:SetEndAlpha(math.min(255, endAlpha255 + 8))
        end

    end
	emitter:Finish() 
end 

function EFFECT:NE_FlareHorizonM002_8(data)
    -- Get position and angles from the effect data
    local pos = data:GetOrigin()
    local ang = data:GetAngles()
    local ent = data:GetEntity()
    self:SetPos(pos)
    self:SetAngles(ang)

    -- Get scale and lifetime multipliers, with default values of 1
    self.Scale = data:GetScale() ~= 0 and data:GetScale() or 1
    self.Scale = self.Scale * 0.1

    local lifetimeMultiplier = data:GetMagnitude() ~= 0 and data:GetMagnitude() or 1

    -- -------------------------------------------------------------------------
    -- Base parameters (tuned to match the feel of the Niagara emitter)
    -- -------------------------------------------------------------------------
    local BASE_LIFETIME = 1.0         -- seconds (will be multiplied by lifetimeMultiplier)
    local lifetime = math.max(0.05, BASE_LIFETIME * lifetimeMultiplier)

    -- Base sprite size (units); Niagara used Vector2 scale per axis; we use uniform base scaled by self.Scale
    local BASE_SIZE = 26 * math.max(0.0001, self.Scale)

    -- How many layered sub-sprites to create for richer lens flare
    local NUM_SUB = 4

    -- Simple smoothing function (smoothstep)
    local function smooth(t)
        return t * t * (3 - 2 * t)
    end

    -- Approximated alpha curve: slight fade-in quick, hold, then fade-out
    local function sampleAlpha(n)
        if n <= 0 then return 0 end
        if n < 0.10 then
            return smooth(n / 0.10)                -- quick fade in
        elseif n < 0.75 then
            return 1                                -- hold
        elseif n < 1.0 then
            return 1 - smooth((n - 0.75) / 0.25)    -- fade out
        else
            return 0
        end
    end

    -- Approximated color curve: warm (orange) early -> white later
    local function sampleColor(n)
        -- warm color (R,G,B) and white
        local warmR, warmG, warmB = 255, 200, 140
        local whiteR, whiteG, whiteB = 255, 255, 255
        local t = smooth(math.Clamp((n - 0.05) / 0.9, 0, 1))
        local r = Lerp(t, warmR / 255, whiteR / 255)
        local g = Lerp(t, warmG / 255, whiteG / 255)
        local b = Lerp(t, warmB / 255, whiteB / 255)
        return r * 255, g * 255, b * 255
    end

    -- Approximated vector2 scale curve -> uniform scalar returned:
    -- small start, grow to a peak, then slightly shrink toward end
    local function sampleScale(n)
        if n <= 0 then return 0.35 end
        local peak = 0.35
        if n < 0.35 then
            return Lerp(smooth(n / 0.35), 0.35, 1.12) -- grow to peak
        else
            local t = (n - 0.35) / (1 - 0.35)
            return Lerp(smooth(t), 1.12, 0.92) -- shrink to slightly smaller
        end
    end

    -- -------------------------------------------------------------------------
    -- Create emitter and spawn particles
    -- Use ParticleEmitter(pos, false) per your requested signature.
    -- -------------------------------------------------------------------------
    local emitter = ParticleEmitter(pos, false)
    if not emitter then return end

    for i = 1, NUM_SUB do
        -- Staggered spawn positions slightly on the forward axis for layering
        local offsetAmt = (i - (NUM_SUB + 1) / 2) * 6
        local spawnPos = pos + ang:Forward() * offsetAmt + ang:Right() * math.Rand(-2, 2) + ang:Up() * math.Rand(-2, 2)

        local p = emitter:Add(MI_A_LensObj_Horizon_01_2, spawnPos)
        if !p then continue end

        -- Per-subparticle life jitter for a natural look
        local jitter = Lerp((i-1)/(NUM_SUB-1 or 1), 0.9, 1.15)
        local pLife = lifetime * jitter
        p:SetDieTime(pLife)

        -- We'll approximate Niagara's per-frame curves by setting Start/End values
        -- and letting the particle system interpolate them.
        local startAlpha = sampleAlpha(0)
        local endAlpha   = sampleAlpha(1)
        p:SetStartAlpha(math.Clamp(math.floor(startAlpha * 255 + 0.5), 0, 255))
        p:SetEndAlpha(math.Clamp(math.floor(endAlpha * 255 + 0.5), 0, 255))

        -- Size driven by sampleScale but modulated per-subparticle
        local s0 = sampleScale(0) * BASE_SIZE * Lerp(0.8, 0.95, i/NUM_SUB)
        local s1 = sampleScale(1) * BASE_SIZE * Lerp(0.95, 1.15, i/NUM_SUB)
        p:SetStartSize(s0)
        p:SetEndSize(s1)

        -- Color: pick a mid-life color that approximates the whole color curve
		local function sampleColor(n)
		-- warm -> white transition, using existing smooth() helper in your file
		local warmR, warmG, warmB = 255, 223, 188
		local whiteR, whiteG, whiteB = 255, 255, 255
		local t = smooth(math.Clamp((n - 0.05) / 0.9, 0, 1))
		local r = Lerp(t, warmR / 255, whiteR / 255)
		local g = Lerp(t, warmG / 255, whiteG / 255)
		local b = Lerp(t, warmB / 255, whiteB / 255)
		return math.Clamp(math.floor(r * 255 + 0.5), 0, 255),
			   math.Clamp(math.floor(g * 255 + 0.5), 0, 255),
			   math.Clamp(math.floor(b * 255 + 0.5), 0, 255)
	end
        local sr, sg, sb = sampleColor(0.45)
        p:SetColor(math.Clamp(math.floor(sr + 0.5), 0, 255),
                   math.Clamp(math.floor(sg + 0.5), 0, 255),
                   math.Clamp(math.floor(sb + 0.5), 0, 255))
				   

        -- Slight outward velocity to mimic horizon flare drift & make layering move a bit
        local vel = ang:Forward() * math.Rand(5, 20) + VectorRand() * math.Rand(0, 6)
        p:SetVelocity(vel)

        -- Rotation and spin
        p:SetRoll(math.Rand(0, 360))
        p:SetRollDelta(math.Rand(-6, 6))

        -- Not affected by world lighting (like many lens flares)
        if p.SetLighting then
            p:SetLighting(false)
        end

        -- No collision and no bounce; purely visual
        if p.SetCollide then p:SetCollide(false) end
		
		local spawnTime = CurTime()
		p:SetThinkFunction(function(particle, delta)
			-- compute normalized age in [0,1]
			local age = CurTime() - spawnTime
			local n = 0
			if pLife > 0 then n = math.Clamp(age / pLife, 0, 1) end

			-- sample our alpha curve and apply
			local alpha = sampleAlpha(n)
			local alpha255 = math.Clamp(math.floor(alpha * 255 + 0.5), 0, 255)

			-- update particle alpha dynamically
			particle:SetStartAlpha(alpha255) 
			particle:SetEndAlpha(alpha255) 

			-- sample color over life and apply
			local cr, cg, cb = sampleColor(n)
			particle:SetColor(cr, cg, cb) 

			-- schedule next think on the next frame
			if particle.SetNextThink then
				particle:SetNextThink(CurTime() + FrameTime())
			end

			return true
		end)
		-- Kick off the first think immediately (some CLuaParticle variants require an initial NextThink)
		if p.SetNextThink then p:SetNextThink(CurTime()) end

        -- If particle allows material params, we could set them here (omitted for portability)
    end

    -- Finish emitter (commits particles)
    emitter:Finish()
end 

function EFFECT:NE_FlareHorizonM003_10(data) 
	local pos = data:GetOrigin()
    local ang = data:GetAngles()
    local ent = data:GetEntity()
    self:SetPos(pos)
    self:SetAngles(ang)

    -- Get scale and lifetime multipliers, with default values of 1
    self.Scale = data:GetScale() ~= 0 and data:GetScale() or 1
    self.Scale = self.Scale * 0.1
    local lifetimeMultiplier = data:GetMagnitude() ~= 0 and data:GetMagnitude() or 1

    -- Base params
    local BASE_LIFETIME = 1.0
    local lifetime = math.max(0.05, BASE_LIFETIME * lifetimeMultiplier)
    local BASE_SIZE = 22 * math.max(0.0001, self.Scale)
    local NUM_SUB = 4

    -- helpers
    local function smooth(t) return t * t * (3 - 2 * t) end

    -- alpha: quick fade-in, hold, fade-out
    local function sampleAlpha(n)
        if n <= 0 then return 0 end
        if n < 0.08 then
            return smooth(n / 0.08)
        elseif n < 0.72 then
            return 1
        elseif n < 1.0 then
            return 1 - smooth((n - 0.72) / 0.28)
        else
            return 0
        end
    end

    -- color: warm -> white over life
    local function sampleColor(n)
        local warmR, warmG, warmB = 255, 210, 170
        local whiteR, whiteG, whiteB = 255, 255, 255
        local t = smooth(math.Clamp((n - 0.05) / 0.9, 0, 1))
        local r = Lerp(t, warmR / 255, whiteR / 255)
        local g = Lerp(t, warmG / 255, whiteG / 255)
        local b = Lerp(t, warmB / 255, whiteB / 255)
        return math.Clamp(math.floor(r * 255 + 0.5), 0, 255),
               math.Clamp(math.floor(g * 255 + 0.5), 0, 255),
               math.Clamp(math.floor(b * 255 + 0.5), 0, 255)
    end

    -- size: grow to peak then slightly shrink (uniform scalar returned)
    local function sampleScale(n)
        if n <= 0 then return 0.35 end
        local peakT = 0.34
        if n < peakT then
            return Lerp(smooth(n / peakT), 0.35, 1.18)
        else
            local tt = (n - peakT) / (1 - peakT)
            return Lerp(smooth(tt), 1.18, 0.9)
        end
    end

    -- Create emitter (CLuaEmitter / ParticleEmitter)
    local emitter = ParticleEmitter(pos, false)
    if not emitter then return end

    for i = 1, NUM_SUB do
        local offsetAmt = (i - (NUM_SUB + 1) / 2) * 6
        local spawnPos = pos + ang:Forward() * offsetAmt + ang:Right() * math.Rand(-3, 3) + ang:Up() * math.Rand(-3, 3)

        local p = emitter:Add(MI_A_LensObj_Horizon_01_5, spawnPos)
        if not p then continue end

        local jitter = Lerp((i-1)/(NUM_SUB-1 or 1), 0.92, 1.12)
        local pLife = lifetime * jitter
        p:SetDieTime(pLife)

        -- Initialize with zero alpha so Think drives it
        p:SetStartAlpha(0)
        p:SetEndAlpha(0)

        -- initial sizes (will be updated per-frame in Think)
        local s0 = sampleScale(0) * BASE_SIZE * Lerp(0.78, 0.95, i/NUM_SUB)
        local s1 = sampleScale(1) * BASE_SIZE * Lerp(0.95, 1.18, i/NUM_SUB)
        p:SetStartSize(s0)
        p:SetEndSize(s1)

        -- initial color mid-life placeholder
        local mr, mg, mb = sampleColor(0.45)
        p:SetColor(mr, mg, mb)

        -- initial velocity & rotation
        local vel = ang:Forward() * math.Rand(4, 18) + VectorRand() * math.Rand(0, 6)
        p:SetVelocity(vel)
        p:SetRoll(math.Rand(0, 360))
        p:SetRollDelta(math.Rand(-6, 6))

        p:SetLighting(false) 
		p:SetCollide(false) 

        -- Per-particle Think: drive alpha, color, and size over normalized life
        local spawnTime = CurTime()
        local subScaleMul = Lerp(0.9, 1.12, i/NUM_SUB)

		p:SetThinkFunction(function(particle, delta)
			local age = CurTime() - spawnTime
			local n = 0
			if pLife > 0 then n = math.Clamp(age / pLife, 0, 1) end

			-- alpha
			local a = sampleAlpha(n)
			local a255 = math.Clamp(math.floor(a * 255 + 0.5), 0, 255)
			particle:SetStartAlpha(a255) 
			particle:SetEndAlpha(a255) 

			-- color
			local cr, cg, cb = sampleColor(n)
			if particle.SetColor then particle:SetColor(cr, cg, cb) end

			-- size (dynamic)
			local sf = sampleScale(n) * subScaleMul
			local sizeNow = BASE_SIZE * sf
			-- update both start and end to ensure immediate visual change
			particle:SetStartSize(sizeNow) 
			particle:SetEndSize(sizeNow) 

			-- optional small drift along forward to mimic curve-driven path
			-- gently reduce outward velocity as life progresses
			local baseVel = ang:Forward() * Lerp(6, 14, 1 - n)
			local rnd = VectorRand() * math.Rand(0, 4) * (1 - n)
			particle:SetVelocity(baseVel + rnd)

			particle:SetNextThink(CurTime() + FrameTime()) 
			return true
		end)

		p:SetNextThink(CurTime()) 
    end

    emitter:Finish()
end 

function EFFECT:NE_FlareHorizonM004_12(data) 
	-- Get position/angles/entity
    local pos = data:GetOrigin()
    local ang = data:GetAngles()
    local ent = data:GetEntity()
    self:SetPos(pos)
    self:SetAngles(ang)

    -- Get scale and lifetime multipliers, with default values of 1
    self.Scale = data:GetScale() ~= 0 and data:GetScale() or 1
    self.Scale = self.Scale * 0.1
    local lifetimeMultiplier = data:GetMagnitude() ~= 0 and data:GetMagnitude() or 1

    -- Base parameters (tweakable)
    local BASE_LIFETIME = 1.0
    local lifetime = math.max(0.05, BASE_LIFETIME * lifetimeMultiplier)
    local BASE_SIZE = 24 * math.max(0.0001, self.Scale)
    local NUM_SUB = 4

    -- Helpers
    local function smooth(t) return t * t * (3 - 2 * t) end

    -- Approximate alpha curve: short fade-in, hold, fade-out
    local function sampleAlpha(n)
        if n <= 0 then return 0 end
        if n < 0.09 then
            return smooth(n / 0.09)
        elseif n < 0.74 then
            return 1
        elseif n < 1.0 then
            return 1 - smooth((n - 0.74) / 0.26)
        else
            return 0
        end
    end

    -- Approximate color curve: warm -> white
    local function sampleColor(n)
        local warmR, warmG, warmB = 255, 205, 170
        local whiteR, whiteG, whiteB = 255, 255, 255
        local t = smooth(math.Clamp((n - 0.05) / 0.9, 0, 1))
        local r = Lerp(t, warmR / 255, whiteR / 255)
        local g = Lerp(t, warmG / 255, whiteG / 255)
        local b = Lerp(t, warmB / 255, whiteB / 255)
        return math.Clamp(math.floor(r * 255 + 0.5), 0, 255),
               math.Clamp(math.floor(g * 255 + 0.5), 0, 255),
               math.Clamp(math.floor(b * 255 + 0.5), 0, 255)
    end

    -- Approximate vector2 scale curve -> return uniform scalar (keeps file small)
    local function sampleScale(n)
        if n <= 0 then return 0.36 end
        local peakT = 0.33
        if n < peakT then
            return Lerp(smooth(n / peakT), 0.36, 1.20)
        else
            local tt = (n - peakT) / (1 - peakT)
            return Lerp(smooth(tt), 1.20, 0.88)
        end
    end

    -- Create emitter (CLuaEmitter / ParticleEmitter)
    local emitter = ParticleEmitter(pos, false)
    if not emitter then return end

    for i = 1, NUM_SUB do
        -- small offset along forward for layering
        local offsetAmt = (i - (NUM_SUB + 1) / 2) * 6
        local spawnPos = pos + ang:Forward() * offsetAmt + ang:Right() * math.Rand(-3, 3) + ang:Up() * math.Rand(-3, 3)

        local p = emitter:Add(MI_A_LensObj_Horizon_01_4, spawnPos)
        if not p then continue end

        -- per-particle life jitter
        local jitter = Lerp((i-1)/(NUM_SUB-1 or 1), 0.9, 1.15)
        local pLife = lifetime * jitter
        p:SetDieTime(pLife)

        -- initialize alpha to zero; Think will drive non-linear alpha
        p:SetStartAlpha(0)
        p:SetEndAlpha(0)

        -- initial size (Start/End). We'll update dynamically in Think for smooth non-linear sizing.
        local s0 = sampleScale(0) * BASE_SIZE * Lerp(0.8, 0.95, i/NUM_SUB)
        local s1 = sampleScale(1) * BASE_SIZE * Lerp(0.95, 1.15, i/NUM_SUB)
        p:SetStartSize(s0)
        p:SetEndSize(s1)

        -- initial color placeholder (Think will lerp per-frame)
        local mr, mg, mb = sampleColor(0.45)
        p:SetColor(mr, mg, mb)

        -- small outward velocity and randomized jitter
        local vel = ang:Forward() * math.Rand(5, 18) + VectorRand() * math.Rand(0, 6)
        p:SetVelocity(vel)

        p:SetRoll(math.Rand(0, 360))
        p:SetRollDelta(math.Rand(-6, 6))

        p:SetLighting(false)
        p:SetCollide(false)

        -- capture spawnTime & per-sub multiplier
        local spawnTime = CurTime()
        local subScaleMul = Lerp(0.9, 1.12, i/NUM_SUB)

        -- SetThinkFunction drives alpha, color and size per-frame (approximating curves)
        p:SetThinkFunction(function(particle, delta)
            local age = CurTime() - spawnTime
            local n = 0
            if pLife > 0 then n = math.Clamp(age / pLife, 0, 1) end

            -- alpha (non-linear)
            local a = sampleAlpha(n)
            local a255 = math.Clamp(math.floor(a * 255 + 0.5), 0, 255)
            particle:SetStartAlpha(a255)
            particle:SetEndAlpha(a255)

            -- color (lerp over life)
            local cr, cg, cb = sampleColor(n)
            particle:SetColor(cr, cg, cb)

            -- size (uniform scalar approximation of Vector2Curve)
            local sf = sampleScale(n) * subScaleMul
            local sizeNow = BASE_SIZE * sf
            particle:SetStartSize(sizeNow)
            particle:SetEndSize(sizeNow)

            -- slight velocity decay/drift to mimic path-driven motion
            local forwardVel = ang:Forward() * Lerp(6, 14, 1 - n)
            local rnd = VectorRand() * math.Rand(0, 4) * (1 - n)
            particle:SetVelocity(forwardVel + rnd)

            -- schedule next think
            particle:SetNextThink(CurTime() + FrameTime())
            return true
        end)

        -- prime the Think system immediately
        p:SetNextThink(CurTime())
    end

    emitter:Finish()
end 

function EFFECT:NE_FlareM(data) 
	local pos = data:GetOrigin()
	local ang = data:GetAngles()
	local ent = data:GetEntity()
	self:SetPos(pos)
	self:SetAngles(ang)
	self.Entity = ent -- Store entity for local space simulation

	-- Get scale and lifetime multipliers, with default values of 1
	self.Scale = data:GetScale() != 0 and data:GetScale() or 1
	self.Scale = self.Scale * 1
	local lifetimeMultiplier = data:GetMagnitude() ~= 0 and data:GetMagnitude() or 1

	-- Create the emitter at the effect's position
	local emitter = ParticleEmitter(pos, false)
	if !emitter then return end

	-- Spawn one particle for the flare
	local particle = emitter:Add(MI_A_Flares_01_8, pos)

	if particle then
		-- --- Set Initial Properties (from JSON) ---
		particle:SetDieTime(1.0 * lifetimeMultiplier)

		-- Set initial state (will be overridden by Think in <1 frame)
		-- JSON default color is white, alpha will be 0 from curve
		particle:SetColor(255, 255, 255, 0)
		-- JSON default size is (1,1), but we start from 0 for the curve
		particle:SetStartSize(0)
		particle:SetEndSize(0)

		-- No physics (Mass is 0.0 in JSON)
		particle:SetVelocity(Vector(0, 0, 0))
		particle:SetGravity(Vector(0, 0, 0))
		particle:SetAirResistance(0)
		particle:SetCollide(false)
		particle.SpawnTime = CurTime() 
		particle.DieTime = particle:GetDieTime() + particle.SpawnTime
		particle.EF_Scale = self.Scale 
		particle.Entity = data:GetEntity() 

		-- --- Set Think Function ---
		-- This is the key. We tell the particle to call our
		-- ParticleThink function every frame.
		-- We wrap it in a function() to pass 'self' correctly.
		particle:SetThinkFunction(function(p)
		-- Get the particle's total lifetime, which we stored on it in Init
			local totalLife = particle:GetDieTime() 
			-- if not totalLife or totalLife <= 0 then return false end

			-- Get the elapsed time
			local elapsed = CurTime() - particle.SpawnTime

			-- Calculate normalized age (0.0 to 1.0)
			local normAge = elapsed / totalLife 

			-- --- 1. Alpha Curve (ScaleAlpha) ---
			-- This curve simulates a fade-in and fade-out.
			-- We use math.sin() from 0 to Pi to get a smooth 0 -> 1 -> 0 pulse.
			local alphaMultiplier = math.sin(normAge * math.pi)
			local finalAlpha = 255 * alphaMultiplier

			-- --- 2. Size Curve (ScaleFactor) ---
			-- This curve also pulses the size from 0 up to a peak and back to 0.
			local peakSize = 20
			local sizeMultiplier = math.sin(normAge * math.pi)
			-- Get the scale we stored on the particle
			local finalSize = (peakSize * sizeMultiplier) * particle.EF_Scale
			
			-- Use SetStartSize/SetEndSize as you had
			particle:SetStartSize(finalSize)
			particle:SetEndSize(finalSize)

			-- --- 3. Color Curve (ScaleColor) ---
			-- This curve simulates the flare's color changing over its life.
			-- We'll approximate this by interpolating from White (initial)
			-- to a fiery Orange (end of life), simulating cooling.
			local r, g, b
			r = 255 -- Stays hot
			g = Lerp(normAge, 255, 180) -- Lerps from White (255) to Orange (180)
			b = Lerp(normAge, 255, 50)  -- Lerps from White (255) to Orange (50)
			
			-- Use SetStartAlpha/SetEndAlpha and SetColor
			particle:SetColor(r, g, b, finalAlpha)
			particle:SetStartAlpha(finalAlpha)
			particle:SetEndAlpha(finalAlpha)

			-- --- 4. Position (bLocalSpace) ---
			-- Get the entity to follow, which we stored on the particle
			local followEnt = particle.Entity
			-- if IsValid(followEnt) then
				-- particle:SetPos(followEnt:GetPos())
			-- end

			-- Return true to keep thinking
			particle:SetNextThink(CurTime()) 
			return true
		end)
		particle:SetNextThink(CurTime()) 
	end

	-- We're done spawning particles
	emitter:Finish()
end 

function EFFECT:NE_FlareM002_1(data) 
	-- Interpolate between two colors (Color objects) by t in [0,1]
    local pos = data:GetOrigin()
    local ang = data:GetAngles()
    local ent = data:GetEntity()
    self:SetPos(pos)
    self:SetAngles(ang)

    -- user-supplied scale & lifetime multipliers (defaults)
    self.Scale = (data:GetScale() ~= 0 and data:GetScale() or 1) * 0.1
    local lifetimeMultiplier = (data:GetMagnitude() ~= 0 and data:GetMagnitude() or 1)

    -- base lifetime chosen to match typical small lens-flare particle feel
    local baseLifetime = 0.9 -- seconds, tuned approximation
    local life = math.max(0.05, baseLifetime * lifetimeMultiplier)

    -- base size in source pixels (GMod particle units) - tuned
    local baseSize = math.max(1, 24 * self.Scale) -- peak size scale reference

    -- spawn a particle emitter (2D false => not 3D by default; doesn't change much for simple sprite)
    local emitter = ParticleEmitter(pos, false)
    if not emitter then return end

    -- We'll spawn one particle for this effect (Niagara emitter typically spawns many; adjust if you want multiples)
    local p = emitter:Add(MI_B_LensCircle_01_18, pos)
    if not p then
        emitter:Finish()
        return
    end

    -- Initial velocity: slight outward / random jitter
    local randomDir = VectorRand():GetNormalized()
    local velocityMagnitude = 0.0 -- flare is mostly screen-space; very small outward drift
    p:SetVelocity(randomDir * velocityMagnitude)

    -- No gravity, no collisions for a lens flare
    p:SetGravity(Vector(0, 0, 0))
    p:SetCollide(false)
    p:SetBounce(0)

    -- Rotation & spin; Niagara bound sprite rotation so we emulate rotating sprite
    local startRoll = math.Rand(0, 360)
    local rollSpeed = math.Rand(-20, 20) -- degrees/sec
    p:SetRoll(startRoll)
    p:SetRollDelta(rollSpeed)

    -- Lifetime
    p:SetDieTime(life) -- seconds

    -- START / END size: We'll set them but we will also update color/alpha each frame to emulate curves.
    -- Choose StartSize small -> quickly ramp to peak (at ~20-30% life), then slowly fall back to end.
    local peakFactor = 1.0 -- peak relative to baseSize
    local startSize = baseSize * 0.05     -- tiny at spawn
    local peakSize = baseSize * peakFactor
    local endSize = baseSize * 0.9       -- slightly smaller than peak at the end

    p:SetStartSize(startSize)
    p:SetEndSize(endSize)

    -- Alpha: we'll control with SetStartAlpha / SetEndAlpha for gross behaviour, but refine with Think() for curve
    p:SetStartAlpha(0)
    p:SetEndAlpha(0) -- we will manually set visible alpha through Think (so SetStart/EndAlpha as placeholders)

    -- Base color (Initial.Color in JSON is white). We'll modulate via Think to approximate ColorCurve
    local baseColor = Color(255, 255, 255)
    p:SetColor(baseColor.r, baseColor.g, baseColor.b)

    -- Air resistance small so sprite doesn't drift (mostly static)
    p:SetAirResistance(5)

    -- Material random / dynamic material param is not directly accessible; we skip
    -- Lighting off for unlit/additive look (the material itself should be additive)
    p:SetLighting(false)

    -- store some local variables in closure for Think
    local birthTime = CurTime()
    local dieTime = birthTime + life

    -- We'll approximate the Niagara color curve with three color stops:
    -- 0.0 -> white (center highlight)
    -- 0.25 -> cool bluish (mid-life color)
    -- 0.75 -> warm/brownish rim
    local colStart = Color(255, 255, 255)
    local colMid   = Color(170, 200, 255)
    local colEnd   = Color(120, 60, 35)

    -- Alpha envelope approximating nuisance: rapid fade-in, hold, then fade-out at tail.
    -- We'll make alpha(t) = easeOutCubic(t*1.2) up to a peak, then easeOutQuad decaying near the end.
    local peakAlpha = 200 -- 0..255

    -- Size envelope: ramp to peak quickly (10-30% life) then slowly reduce
    -- We'll also perform a subtle per-frame size modulation to mimic radial steps
    local function SampleAlpha(normalizedAge)
        -- normalizedAge in [0,1]
        if normalizedAge < 0.18 then
            -- quick fade in
            return Lerp(math.ease.OutCubic(normalizedAge / 0.18), 0, peakAlpha)
        elseif normalizedAge < 0.75 then
            -- stay near peak with slight easing
            return Lerp(math.ease.InOutQuad((normalizedAge - 0.18) / (0.75 - 0.18)), peakAlpha, peakAlpha * 0.9)
        else
            -- fade out towards end
            return Lerp(math.ease.OutQuad((normalizedAge - 0.75) / (1 - 0.75)), peakAlpha * 0.9, 0)
        end
    end

    local function SampleColor(normalizedAge)
        if normalizedAge < 0.25 then
            local t = normalizedAge / 0.25
            return LerpColor(math.ease.OutCubic(t), colStart, colMid)
        elseif normalizedAge < 0.75 then
            local t = (normalizedAge - 0.25) / (0.75 - 0.25)
            return LerpColor(math.ease.InOutQuad(t), colMid, colEnd)
        else
            local t = (normalizedAge - 0.75) / (1 - 0.75)
            -- gradually shift towards darker warm color
            return LerpColor(math.ease.OutQuad(t), colEnd, Color(80, 30, 20))
        end
    end

    local function SampleScale(normalizedAge)
        -- returns scale multiplier where 1 is "baseSize"
        if normalizedAge < 0.2 then
            -- ramp quickly to peak
            return Lerp(math.ease.OutCubic(normalizedAge / 0.2), 0.05, 1.0)
        else
            -- slowly decay after peak
            return Lerp(math.ease.InOutQuad((normalizedAge - 0.2) / 0.8), 1.0, 0.9)
        end
    end

    -- Think function to update color / alpha / subtle size & roll over the particle lifetime
    p:SetThinkFunction(function(particle)
        -- safety check (particle might be dead)
        if not particle or not particle.SetColor then return end

        local now = CurTime()
        local age = now - birthTime
        local normalized = math.Clamp(age / life, 0, 1)

        -- color and alpha from easing samplers
        local col = SampleColor(normalized)
        local alpha = SampleAlpha(normalized)

        -- set color and alpha
        -- Note: SetColor in GF uses RGB only; to ensure alpha we use SetStartAlpha/SetEndAlpha
        -- We set both to current alpha so it appears with our custom envelope (works in many GMod builds)
        particle:SetColor(math.floor(col.r), math.floor(col.g), math.floor(col.b))
        if particle.SetStartAlpha then
            particle:SetStartAlpha(alpha)
            particle:SetEndAlpha(alpha)
        end

        -- subtle per-frame size modulation (pulsing) by updating start/end sizes so sprite visually follows curve
        local scaleMul = SampleScale(normalized)
        local currentSize = Lerp(scaleMul, startSize, peakSize) -- if sample returns <1, lean toward start/peak
        local endSizeNow = Lerp(normalized, currentSize, endSize)
        particle:SetStartSize(currentSize) 
        particle:SetEndSize(endSizeNow) 

        -- Keep roll advancing naturally (SetRollDelta was set); ensure roll is applied.
        -- (No code required here unless you want to change roll over time.)

        -- Reschedule think until death
         particle:SetNextThink(CurTime())
    end)

    -- Ensure emitter is finished
    emitter:Finish() 
end 

function EFFECT:NE_LightM(data) 
	local pos = data:GetOrigin()
    local ang = data:GetAngles()
    local ent = data:GetEntity()

    self:SetPos(pos)
    self:SetAngles(ang)

    -- Get scale and lifetime multipliers, with default values of 1
    self.Scale = data:GetScale() ~= 0 and data:GetScale() or 0.1
    self.Scale = self.Scale * 0.1

    local lifetimeMultiplier = data:GetMagnitude() ~= 0 and data:GetMagnitude() or 1
	    -- Base lifetime similar to flare/light lifetime in Niagara (tuned)
    local baseLifetime = 1.0 -- seconds
    self.LifeTime = math.max(0.05, baseLifetime * lifetimeMultiplier)
    self.BirthTime = CurTime()
    self.DieTime = self.BirthTime + self.LifeTime

    -- We'll use this ent index as the DynamicLight index so it doesn't stomp other lights.
    -- Fallback to LocalPlayer if ent is nil/invalid.
    if IsValid(ent) and ent.GetCreationID then
        self.LightIndex = ent:EntIndex()
    else
        local lp = LocalPlayer()
        self.LightIndex = IsValid(lp) and lp:EntIndex() or math.random(1, 32767)
    end

    -- Peak brightness tuning (how bright the light gets). This is similar to
    -- Niagara's Scale Brightness curve * external NPC.FXParam.ParticleLightBright.
    self.PeakBrightness = 2.5 * (1 + self.Scale * 6) -- tuned heuristic (0.5..6 range typical)
    self.MinBrightness = 0.05

    -- Peak radius (size) mapping: brightness -> radius mapping
    self.MaxRadius = math.Clamp(150 * self.Scale, 32, 2048) -- tuned mapping
	-- print(self.MaxRadius) 

    -- Fade-out window (how long fade-out lasts). We'll fade out over last 25% of life
    self.FadeOutWindow = math.max(0.06, self.LifeTime * 0.25)
    -- Compute decay as per supplied formula: 1000 / fadeOutTimeInSeconds
    self.Decay = 1000 / self.FadeOutWindow
    -- dietime is the absolute CurTime when the light should be removed
    self.DieTimeLight = self.DieTime

    -- Color stops (approximate Scale Color curve)
    -- Start = white-ish bright center; Mid = bluish tint; End = warm/dim (for late life)
    self.ColorStart = Color(255, 250, 240)
    self.ColorMid   = Color(170, 200, 255)
    self.ColorEnd   = Color(120, 80, 60)

    -- Additional small per-frame motion (optional). Niagara LightM might be anchored
    -- so we keep position mostly fixed but allow a small jitter to simulate breathe.
    self.JitterAmount = math.Clamp(6 * self.Scale, 0, 24)

    -- We'll update the dynamic light every Think until die
    self.Active = true
end 

-- Sample color using the three stops
function EFFECT:SampleColor(n)
    if n < 0.25 then
        local t = n / 0.25
        return LerpColor(math.ease.OutQuad(t), self.ColorStart, self.ColorMid)
    elseif n < 0.8 then
        local t = (n - 0.25) / (0.8 - 0.25)
        return LerpColor(math.ease.InOutCubic(t), self.ColorMid, self.ColorEnd)
    else
        local t = (n - 0.8) / (1 - 0.8)
        return LerpColor(math.ease.OutQuad(t), self.ColorEnd, Color(80, 40, 30))
    end
end

local function SampleAlpha(n)
    -- quick fade-in, solid mid life, linear-ish fade-out at end (combined with brightness)
    if n < 0.12 then
        return Lerp(0.0, 1.0, math.ease.OutQuad(n / 0.12))
    elseif n < 0.8 then
        return 1.0
    else
        local t = (n - 0.8) / (1 - 0.8)
        return Lerp(1.0, 0.0, math.ease.OutQuad(t))
    end
end

-- Sample brightness over normalized age (0..1) using easing to mimic the Niagara curve
function EFFECT:SampleBrightness(n)
    -- n in [0,1]
    -- bright quickly to peak, hold/mild decay, then fade at end
    if n < 0.18 then
        return Lerp(0.0, self.PeakBrightness, math.ease.OutQuad(n / 0.18))
    elseif n < 0.75 then
        -- slight falloff from peak to 0.85*peak
        local t = (n - 0.18) / (0.75 - 0.18)
        return Lerp(self.PeakBrightness, self.PeakBrightness * 0.85, math.ease.InOutCubic(t))
    else
        local t = (n - 0.75) / (1 - 0.75)
        return Lerp(self.PeakBrightness * 0.85, self.MinBrightness, math.ease.OutQuad(t))
    end
end

-- Think: handles only light 
function EFFECT:Think()
    if not self.Active then return false end

    local now = CurTime()
    if now >= self.DieTime then
        -- last update for final frame to allow light removal
        self.Active = false
        -- return false
    end

    -- normalized age 0..1
    local age = now - self.BirthTime
    local n = math.Clamp(age / self.LifeTime, 0, 1)

    -- sample curves
    local brightness = self:SampleBrightness(n)
    local alpha = SampleAlpha(n) -- 0..1
    local color = self:SampleColor(n)

    -- map brightness & alpha -> dynamic light brightness; multiply by scale factor
    -- DynamicLight brightness is not linear to screen intensity; tune down to stable range
    local finalBrightness = math.max(0.01, brightness * alpha)

    -- radius mapping: larger when brighter
    local size = math.Clamp(self.MaxRadius * (0.6 + (finalBrightness / math.max(0.0001, self.PeakBrightness)) * 0.8), 8, 400)

    -- jittered position to emulate breathing / volumetric subtle motion
    local jitter = VectorRand() * (self.JitterAmount * (1 - n) * 0.4) -- more jitter early, settle later
    local basePos = self:GetPos()
    local pos = basePos + jitter

    -- dynamic light index
    local idx = self.LightIndex

    -- create/update dynamic light each frame (dynamic lights expire automatically if not refreshed)
    local dlight = DynamicLight(idx)
    if dlight then
        dlight.Pos = pos
        dlight.pos = pos -- compatibility
        dlight.r = color.r
        dlight.g = color.g
        dlight.b = color.b

        -- brightness (engine scale). clamp to sane values
        dlight.brightness = math.Clamp(finalBrightness, 0.01, 8)

        -- decay: use formula 1000 / fadeOutTimeInSeconds, but DynamicLight.decay expects units per second
        dlight.decay = self.Decay

        -- size
        dlight.size = size

        -- lifetime: set to final die time
        dlight.dietime = self.DieTimeLight

        -- options (tweak as needed)
        dlight.style = 0
        dlight.noworld = false
        dlight.nomodel = false
        dlight.minlight = 0

        -- direction & angle fields can be left zero for point lights (or set if you want cone)
        -- dlight.dir = Vector(0,0,0)
        -- dlight.innerangle = 0
        -- dlight.outerangle = 0
    end

    -- continue thinking while alive
    return true
end

-- Render: nothing to draw manually; particles render via engine
function EFFECT:Render()
    -- nothing: sprite rendering handled by particle system
end
