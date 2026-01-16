-- effects/ns_pc_spintrail_target01_ribbon/init.lua
-- target01 emitter recreation with per-particle ribbons that follow particle history
-- Uses debug/debugwireframe for particles (hidden) and sprites/mi_b_windribbon_01 for ribbons.


local function SampleCurve(tbl, t)
    if not tbl or #tbl == 0 then return 1.0 end
    if t <= tbl[1][1] then return tbl[1][2] end
    for i = 2, #tbl do
        local aT, aV = tbl[i - 1][1], tbl[i - 1][2]
        local bT, bV = tbl[i][1], tbl[i][2]
        if t <= bT then
            local range = bT - aT
            if range == 0 then return aV end
            local frac = (t - aT) / range
            return Lerp(frac, aV, bV)
        end
    end
    return tbl[#tbl][2]
end

local function RotateVectorAroundAxis(v, k, theta)
    local cosT = math.cos(theta)
    local sinT = math.sin(theta)
    local kdotv = k.x * v.x + k.y * v.y + k.z * v.z
    local kxv = Vector(
        k.y * v.z - k.z * v.y,
        k.z * v.x - k.x * v.z,
        k.x * v.y - k.y * v.x
    )
    return Vector(
        v.x * cosT + kxv.x * sinT + k.x * kdotv * (1 - cosT),
        v.y * cosT + kxv.y * sinT + k.y * kdotv * (1 - cosT),
        v.z * cosT + kxv.z * sinT + k.z * kdotv * (1 - cosT)
    )
end

local function RandomUnitVector()
    local theta = math.random() * math.pi * 2
    local z = (math.random() * 2 - 1)
    local r = math.sqrt(math.max(0, 1 - z * z))
    return Vector(r * math.cos(theta), r * math.sin(theta), z)
end

-- === Config (mapped from Niagara JSON user parameters) ===
local CONFIG = {
    RootCount                = 6,
    RotateRadius             = 32,
    RotateRateSpeedMult      = 1.2,
    RotationAxisRandomMult   = 0.15,
    VelFromCenterMult        = 10,
    LifeTime_Root_Min        = 0.45,
    LifeTime_Root_Max        = 0.85,
    AlphaMult                = 1.0,
    Brightness               = 1.0,
    RootPosOffset            = Vector(0,0,0),
    BaseWidth                = 10.0,
    RibbonWidthMult          = 1.0,
    RibbonLifeTimeMult       = 1.0,
    SegmentTilingLength      = 900.0,
    StartSize                = 12,
    EndSize                  = 0,
    AirResistance            = 8,
    Gravity                  = Vector(0,0,-20),
    PaddingBounds            = 24,
    -- how often we sample particle positions into history (seconds)
    HistorySampleRate        = 0.016, -- ~60Hz (will clamp to FrameTime)
    -- how long to keep each history point (we use particle.life * RibbonLifeTimeMult)
    HistoryMaxPoints         = 48,    -- safety cap to avoid unbounded memory
}

local DEFAULT_WIDTH_CURVE = {
    {0.0, 0.2},
    {0.2, 1.0},
    {0.8, 0.8},
    {1.0, 0.0}
}

local DEFAULT_BASE_COLOR = Color(200, 230, 255)

-- Materials
EFFECT.Mat = Material("sprites/mi_b_windribbon_01")
local PARTICLE_MAT = "debug/debugwireframe" -- requested material

-- EFFECT defaults (engine provides EFFECT)
EFFECT.WidthCurve = DEFAULT_WIDTH_CURVE
EFFECT.BaseWidth = CONFIG.BaseWidth
EFFECT.SegmentLifetime = (CONFIG.LifeTime_Root_Min + CONFIG.LifeTime_Root_Max) * 0.5 * CONFIG.RibbonLifeTimeMult
EFFECT.TilingLength = CONFIG.SegmentTilingLength
EFFECT.WidthMultiplier = 1.0

-- === Init: emit CLuaParticles & create minimal per-particle entry with history table ===
function EFFECT:Init(data)
    self.Origin = data:GetOrigin() or vector_origin
	self:SetPos(data:GetOrigin()) 
	self:SetAngles(data:GetAngles()) 
	self.Scale = data:GetScale() * 1 
	print("scale is",self.Scale) 
	self.LifeTime = data:GetMagnitude() * 1 
	print("LifeTime is",self.LifeTime) 
    self.SpawnTime = CurTime()
    self.BaseRotationSpeed = (2 * math.pi) / 0.8 * CONFIG.RotateRateSpeedMult
    self.Emitter = ParticleEmitter(self.Origin, false)
	self.Emitter:SetNoDraw(true) 

    self.Particles = {} -- entries: { particle = p, spawnTime = now, life = life, history = { {pos, t} ... }, lastSample = now }

    local now = CurTime()
    for i = 1, CONFIG.RootCount do
        local phase = (i - 1) * (2 * math.pi / CONFIG.RootCount) + math.Rand(0, 0.1)
        local axisJitter = RandomUnitVector() * CONFIG.RotationAxisRandomMult
        local life = math.Rand(CONFIG.LifeTime_Root_Min,CONFIG.LifeTime_Root_Max) * self.LifeTime 
        local radius = CONFIG.RotateRadius * (1 + math.Rand(-0.06, 0.06))
        local angle = phase

        local posLocal = Vector(math.cos(angle), math.sin(angle), 0) * radius + CONFIG.RootPosOffset
        posLocal.z = posLocal.z + axisJitter.z * CONFIG.RotateRadius * 0.5
        local spawnPos = self.Origin + posLocal

        -- compute tangential + radial velocity (initial)
        local tangent2D = Vector(-posLocal.y, posLocal.x, 0)
        if tangent2D:Length() == 0 then tangent2D = Vector(1,0,0) end
        tangent2D:Normalize()
        local tangentialVel = tangent2D * (self.BaseRotationSpeed * radius)
        local radialDir = posLocal:GetNormalized()
        if radialDir:Length() == 0 then radialDir = Vector(1,0,0) end
        local radialVel = radialDir * CONFIG.VelFromCenterMult * math.Rand(0.2, 1.0)
        local finalVel = tangentialVel + radialVel

        local p = self.Emitter:Add(PARTICLE_MAT, spawnPos)
        if p then
            p:SetVelocity(finalVel)
            p:SetLifeTime(0)
            p:SetDieTime(life)
            p:SetStartAlpha(255)
            p:SetEndAlpha(0)
            p:SetStartSize(CONFIG.StartSize * self.Scale)
            p:SetEndSize(CONFIG.EndSize * self.Scale)
            p:SetColor(DEFAULT_BASE_COLOR.r, DEFAULT_BASE_COLOR.g, DEFAULT_BASE_COLOR.b)
            p:SetAirResistance(CONFIG.AirResistance)
            p:SetGravity(CONFIG.Gravity)
            p:SetCollide(false)

            table.insert(self.Particles, {
                particle = p,
                spawnTime = now,
                life = life,
                history = { { pos = p:GetPos(), t = now } }, -- start history with spawn pos
                lastSample = now
            })
        end
    end

    -- initial render bounds
    local pad = CONFIG.PaddingBounds
    self:SetRenderBoundsWS(self.Origin - Vector(pad,pad,pad), self.Origin + Vector(pad,pad,pad), Vector(pad,pad,pad))
end

-- === Think: prune dead particle refs, sample positions into each particle.history, update bounds ===
function EFFECT:Think()
    local now = CurTime()
    local anyAlive = false
    local dt = math.max(FrameTime(), 0.001)

    for i = #self.Particles, 1, -1 do
        local entry = self.Particles[i]
        local p = entry.particle

        -- particle pointer validity 
		-- print(p) 
        -- if !p or p and !p:IsValid() then
            -- table.remove(self.Particles, i)
            -- goto cont
        -- end

        -- age check
        local age = now - entry.spawnTime
        if age >= entry.life then
            -- let engine remove the CLuaParticle naturally; drop our ref
            table.remove(self.Particles, i)
            goto cont
        end

        anyAlive = true

        -- sample position at sample rate (clamp to FrameTime)
        local sampleRate = math.min(CONFIG.HistorySampleRate, dt)
        if now - entry.lastSample >= sampleRate then
            entry.lastSample = now
			local pos = p:GetPos()
			table.insert(entry.history, { pos = pos, t = now })
			-- prune history older than particle.life * RibbonLifeTimeMult or cap by points
			local cutoff = now - (entry.life * (CONFIG.RibbonLifeTimeMult or 1.0))
			-- prune from front while older than cutoff OR limit by HistoryMaxPoints
			while #entry.history > 0 and (entry.history[1].t < cutoff or #entry.history > CONFIG.HistoryMaxPoints) do
				table.remove(entry.history, 1)
			end
        end

        ::cont::
    end

    -- nothing alive -> finish emitter and remove effect
    if !anyAlive then
        if self.Emitter then
            self.Emitter:Finish()
            self.Emitter = nil
        end
        return false
    end

    -- update render bounds from all history points
    self:UpdateRenderBoundsFromParticles()

    return true
end

-- compute world-space AABB including all history points and call SetRenderBoundsWS
function EFFECT:UpdateRenderBoundsFromParticles()
    if not self.Particles or #self.Particles == 0 then return end

    local mins, maxs
    for _, entry in ipairs(self.Particles) do
        for _, h in ipairs(entry.history) do
            local pos = h.pos
            if not pos then goto next_h end
            if not mins then
                mins = Vector(pos)
                maxs = Vector(pos)
            else
                mins.x = math.min(mins.x, pos.x)
                mins.y = math.min(mins.y, pos.y)
                mins.z = math.min(mins.z, pos.z)
                maxs.x = math.max(maxs.x, pos.x)
                maxs.y = math.max(maxs.y, pos.y)
                maxs.z = math.max(maxs.z, pos.z)
            end
            ::next_h::
        end
    end

    if !mins then return end

    local pad = CONFIG.PaddingBounds
    self:SetRenderBoundsWS(mins, maxs, Vector(pad, pad, pad))
end

-- === Render: For each particle, draw a triangle strip along its history (oldest->newest) ===
function EFFECT:Render()
    if !self.Particles or #self.Particles == 0 then return end
    render.SetMaterial(self.Mat)

    local tilingLength = self.TilingLength or CONFIG.SegmentTilingLength
    local baseWidth = (self.BaseWidth or CONFIG.BaseWidth) * (self.RibbonWidthMult or CONFIG.RibbonWidthMult) * self.Scale 

    -- Render each particle's history as a separate triangle strip so they don't connect.
    for _, entry in ipairs(self.Particles) do
        local hist = entry.history
        if not hist or #hist < 2 then goto continue_particle end

        -- compute cumulative distances for U coordinate along this history
        local cumul = 0
        local cumulTbl = { 0 }
        for i = 2, #hist do
            local d = hist[i].pos:Distance(hist[i-1].pos)
            cumul = cumul + d
            cumulTbl[i] = cumul
        end

        -- Prepare a triangle strip for this particle's history
        -- Vertex count estimate: (#hist) * 2
        mesh.Begin(MATERIAL_TRIANGLE_STRIP, math.max(1, #hist * 2))

        for i = 1, #hist do
            local h = hist[i]
            local pos = h.pos
            if !pos then goto continue_sample end

            -- sample-based life fraction (older samples -> smaller)
            local sampleAgeFrac = math.Clamp((h.t - entry.spawnTime) / entry.life, 0, 1)
            local invSampleLife = 1 - sampleAgeFrac

            local alphaMul = math.ease.OutCubic(invSampleLife) * CONFIG.AlphaMult
            local alpha = math.Clamp(255 * alphaMul, 0, 255)
            local intensity = Lerp(invSampleLife, 1.5, 0.2) * CONFIG.Brightness

            local r = math.Clamp(DEFAULT_BASE_COLOR.r * intensity, 0, 255)
            local g = math.Clamp(DEFAULT_BASE_COLOR.g * intensity, 0, 255)
            local b = math.Clamp(DEFAULT_BASE_COLOR.b * intensity, 0, 255)
            local acol = math.Round(alpha)

            -- width from curve
            local widthMul = SampleCurve(self.WidthCurve, sampleAgeFrac)
            local halfWidth = (baseWidth * widthMul * (self.WidthMultiplier or 1.0)) * 0.5

            -- tangent using neighbor samples
            local prevPos = (i > 1) and hist[i-1].pos or pos
            local nextPos = (i < #hist) and hist[i+1].pos or pos
            local tangent = (nextPos - prevPos)
            if tangent:LengthSqr() < 1e-6 then tangent = Vector(0,0,1) else tangent:Normalize() end

            local viewDir = (EyePos() - pos)
            if viewDir:LengthSqr() < 1e-6 then viewDir = Vector(0,0,1) end
            viewDir:Normalize()

            local right = viewDir:Cross(tangent)
            if right:LengthSqr() < 1e-6 then right = Vector(0,0,1):Cross(tangent) end
            right:Normalize()

            -- small per-sample twist
            local twistAngle = math.sin((h.t - entry.spawnTime) * 10 + (entry.spawnTime % 3)) * 0.35
            if math.abs(twistAngle) > 1e-6 then
                right = RotateVectorAroundAxis(right, tangent, twistAngle)
                right:Normalize()
            end
			-- halfWidth = halfWidth * 5 
            local off = right * halfWidth

            -- U coordinate: cumulative distance along history / tiling length
            local rawU = (cumulTbl[i] or 0) / tilingLength
            local uEps = 0.0005
            local uCoord = math.max(uEps, rawU)

            -- Vertex A (left side, V = 0)
			-- render.OverrideBlend( true, BLEND_ONE, BLEND_ONE, BLENDFUNC_ADD )
			-- render.SetColorModulation(r,g,b) 
			-- render.SetBlend(acol) 
            mesh.Position(pos - off)
            mesh.TexCoord(0, uCoord, 0)
            mesh.Color(r, g, b, acol)
            mesh.AdvanceVertex()

            -- Vertex B (right side, V = 1)
            mesh.Position(pos + off)
            mesh.TexCoord(0, uCoord, 1)
            mesh.Color(r, g, b, acol)
            mesh.AdvanceVertex()
			-- render.SetBlend(1) 
			-- render.OverrideBlend( false )
			

            ::continue_sample::
        end

        mesh.End()

        ::continue_particle::
    end
end
