-- ==============================================================================
-- NS_PC_SpinTrail_01 (Stellar Blade - Cyclone Wind Ribbon Effect)
-- Multi-Pass Additive Ribbon Renderer (Core + Atmospheric Turbulence)
-- ==============================================================================

local CONFIG = {
    RootCount                = 4,                  -- Niagara Trigger Override: [4, 0, 0, 0]
    RotateRadius             = 150.0,              -- Niagara Trigger Override: [0, 0, 22, 67] = 150.0 units
    RotateRateSpeedMult      = 2.0,                -- Orbital angular velocity multiplier
    RotationAxisRandomMult   = 0.5,                -- Niagara Trigger Override: [0, 0, 0, 63] = 0.5 wobble
    VelFromCenterMult        = 1.0,                -- Outward radial expansion velocity
    LifeTime_Root_Min        = 0.30,               -- Niagara Trigger Override: [154, 153, 153, 62] = 0.30s
    LifeTime_Root_Max        = 0.55,               -- Niagara Trigger Override: [205, 204, 12, 63] = 0.55s
    AlphaMult                = 1.0,                -- Global opacity scale
    Brightness               = 3.0,                -- Niagara Trigger Override: [0, 0, 64, 64] = 3.0 HDR boost
    RootPosOffset            = Vector(10, 10, 30), -- Niagara Trigger Override: (10, 10, 30) local offset
    BaseWidth                = 14.0,               -- Blade ribbon width in world units
    RibbonWidthMult          = 0.5,                -- Niagara Trigger Override: [0, 0, 0, 63] = 0.5
    RibbonLifeTimeMult       = 1.0,                -- Ribbon trail persistence multiplier
    CoreTilingLength         = 300.0,              -- UV0 Length tiling for Core Ribbon
    TurbTilingLength         = 900.0,              -- UV1 Length tiling from Niagara UV1Settings (900.0)
    PaddingBounds            = 200,                -- World bounds expansion padding
    HistorySampleRate        = 0.014,              -- Node capture interval (~70 Hz)
    HistoryMaxPoints         = 36,                 -- Maximum nodes tracked per particle strand
}

-- Materials located in the "sprites" directory
EFFECT.MatCore = Material("sprites/mi_b_windribbon_01_core")
EFFECT.MatTurb = Material("sprites/mi_b_windribbon_01_turbulence")

-- ==============================================================================
-- PRE-ALLOCATED GLOBAL POOLS (Eliminates GC overhead completely)
-- ==============================================================================
local POOL_SIZE = 512

local point_pool = {}
local strip_pool = {}
for i = 1, POOL_SIZE do
    point_pool[i] = {
        pos = Vector(0, 0, 0),
        t = 0,
        cumulDist = 0
    }
    strip_pool[i] = {
        posA = Vector(0, 0, 0),
        posB = Vector(0, 0, 0),
        uCore = 0,
        uTurb = 0,
        r = 255, g = 255, b = 255, a = 255,
        rT = 255, gT = 255, bT = 255, aT = 255
    }
end

-- Reusable math scratchpads
local tempMatrix       = Matrix()
local tempLocalPos     = Vector()
local tempWorldPos     = Vector()
local tempTangent      = Vector()
local tempViewDir      = Vector()
local tempRight        = Vector()
local tempRightTwisted = Vector()
local tempOffset       = Vector()
local tempMins         = Vector()
local tempMaxs         = Vector()

-- ==============================================================================
-- IN-PLACE MATHEMATICAL HELPERS (Zero allocation in hot loops)
-- ==============================================================================
local function VectorCrossInplace(out, a, b)
    out.x = a.y * b.z - a.z * b.y
    out.y = a.z * b.x - a.x * b.z
    out.z = a.x * b.y - a.y * b.x
end

local function RotateVectorAroundAxisInplace(out, v, k, theta)
    local cosT = math.cos(theta)
    local sinT = math.sin(theta)
    local oneMinusCos = 1.0 - cosT
    local kdotv = k.x * v.x + k.y * v.y + k.z * v.z

    local cx = k.y * v.z - k.z * v.y
    local cy = k.z * v.x - k.x * v.z
    local cz = k.x * v.y - k.y * v.x

    out.x = v.x * cosT + cx * sinT + k.x * kdotv * oneMinusCos
    out.y = v.y * cosT + cy * sinT + k.y * kdotv * oneMinusCos
    out.z = v.z * cosT + cz * sinT + k.z * kdotv * oneMinusCos
end

local function CatmullRomInplace(out, p0, p1, p2, p3, t)
    local t2 = t * t
    local t3 = t2 * t
    out.x = 0.5 * ((2 * p1.x) + (-p0.x + p2.x) * t + (2 * p0.x - 5 * p1.x + 4 * p2.x - p3.x) * t2 + (-p0.x + 3 * p1.x - 3 * p2.x + p3.x) * t3)
    out.y = 0.5 * ((2 * p1.y) + (-p0.y + p2.y) * t + (2 * p0.y - 5 * p1.y + 4 * p2.y - p3.y) * t2 + (-p0.y + 3 * p1.y - 3 * p2.y + p3.y) * t3)
    out.z = 0.5 * ((2 * p1.z) + (-p0.z + p2.z) * t + (2 * p0.z - 5 * p1.z + 4 * p2.z - p3.z) * t2 + (-p0.z + 3 * p1.z - 3 * p2.z + p3.z) * t3)
end

-- ==============================================================================
-- NIAGARA SCRIPT CURVE EMULATION (Extracted from NS_PC_SpinTrail_01 LUTs)
-- ==============================================================================
-- 1. Scale Alpha Over Age (Niagara UpdateScript_1 Curve 0: 98-sample LUT)
local function SampleScaleAlpha(normAge)
    if normAge < 0.18 then
        local t = normAge / 0.18
        return t * t * (3.0 - 2.0 * t) -- Smooth cubic attack
    elseif normAge <= 0.72 then
        return 1.0                     -- Sustained plateau
    else
        return math.max(0, (1.0 - normAge) / 0.28) -- Linear decay
    end
end

-- 2. Spawn Alpha Envelope (Niagara SpawnScript_0 Curve 0: 79-sample Trapezoid)
local function SampleSpawnAlpha(trailFrac)
    if trailFrac < 0.25 then
        return (trailFrac / 0.25) * 0.5
    elseif trailFrac <= 0.75 then
        return 0.5
    else
        return math.max(0, (1.0 - trailFrac) / 0.25 * 0.5)
    end
end

-- 3. Dynamic Material Param 2 / Emissive Curve (Niagara UpdateScript_1 Curve 2: 108-sample LUT)
-- 5.0x leading spike -> 1.0 valley -> 1.6 mid-rise -> 3.0x dissipation burst
local function SampleEmissiveMultiplier(normAge)
    if normAge < 0.20 then
        return Lerp(normAge / 0.20, 5.0, 1.0)
    elseif normAge < 0.80 then
        return Lerp((normAge - 0.20) / 0.60, 1.0, 1.6)
    else
        return Lerp((normAge - 0.80) / 0.20, 1.6, 3.0)
    end
end

-- 4. Ribbon Width Scale Over Trail (Tapered wind blade profile)
local function SampleWidthProfile(trailFrac)
    if trailFrac < 0.15 then
        return Lerp(trailFrac / 0.15, 0.2, 1.0) -- Razor-sharp tip
    elseif trailFrac < 0.70 then
        return Lerp((trailFrac - 0.15) / 0.55, 1.0, 0.75)
    else
        return math.max(0, (1.0 - trailFrac) / 0.30 * 0.75) -- Trailing tail dissipation
    end
end

-- ==============================================================================
-- EFFECT LIFECYCLE
-- ==============================================================================
function EFFECT:Init(data)
    local tab = self:GetTable()
    tab.CreationTime = CurTime()

    local ent = data:GetEntity()
    tab.Owner = IsValid(ent) and ent or nil

    if IsValid(tab.Owner) then
        self:SetParent(tab.Owner)
    end

    tab.Scale = data:GetScale()
    if tab.Scale <= 0 then tab.Scale = 1.0 end
    self:SetModelScale(tab.Scale)

    tab.LifeTime = data:GetMagnitude()
    if tab.LifeTime <= 0 then tab.LifeTime = 0.45 end

    tab.BoneID = data:GetHitBox()
    tab.LocalPos = Vector()
    tab.LocalPos:Set(data:GetStart() or Vector(0, 0, 0))

    tab.LocalAng = Angle()
    tab.LocalAng:Set(data:GetAngles() or Angle(0, 0, 0))

    tab.BasePos = Vector()
    tab.BaseAng = Angle()
    tab.Origin  = Vector()

    tab.BaseRotationSpeed = (2.0 * math.pi / 0.50) * CONFIG.RotateRateSpeedMult

    -- Initialize particles and pre-allocate history ring nodes
    tab.Particles = {}
    for i = 1, CONFIG.RootCount do
        local phase = (i - 1) * (2.0 * math.pi / CONFIG.RootCount)
        local life  = math.Rand(CONFIG.LifeTime_Root_Min, CONFIG.LifeTime_Root_Max) * tab.LifeTime

        -- Orbital tilt jitter axis
        local jitterTheta = math.random() * math.pi * 2.0
        local jitterZ = (math.random() * 2.0 - 1.0)
        local jitterR = math.sqrt(math.max(0, 1.0 - jitterZ * jitterZ))
        local axisJitter = Vector(jitterR * math.cos(jitterTheta), jitterR * math.sin(jitterTheta), jitterZ)
        axisJitter:Mul(CONFIG.RotationAxisRandomMult)

        local jitterAng = Angle(math.deg(axisJitter.y), 0, math.deg(axisJitter.x))

        -- Pre-allocated history pool for this particle strand
        local histNodes = {}
        for j = 1, CONFIG.HistoryMaxPoints do
            histNodes[j] = {
                pos = Vector(0, 0, 0),
                t = 0,
                cumulDist = 0
            }
        end

        tab.Particles[i] = {
            CreationTime = tab.CreationTime,
            life         = life,
            phase        = phase,
            jitterAng    = jitterAng,
            axisJitterZ  = axisJitter.z,
            history      = histNodes,
            histCount    = 0,
            lastSample   = 0
        }
    end

    self:UpdateOrigin()
    local pad = CONFIG.PaddingBounds
    tempMins:SetUnpacked(-pad, -pad, -pad)
    tempMaxs:SetUnpacked(pad, pad, pad)
    self:SetRenderBounds(tempMins, tempMaxs)
end

function EFFECT:UpdateOrigin()
    local tab = self:GetTable()
    if IsValid(tab.Owner) then
        if tab.BoneID and tab.BoneID >= 0 then
            tab.Owner:SetupBones()
            tab.Owner:CopyBoneMatrix(tab.BoneID, tempMatrix)
            tab.BasePos:Set(tempMatrix:GetTranslation())
            tab.BaseAng:Set(tempMatrix:GetAngles())
        else
            tab.BasePos:Set(tab.Owner:GetPos())
            tab.BaseAng:Set(tab.Owner:GetAngles())
        end

        local wPos = LocalToWorld(tab.LocalPos, tab.LocalAng, tab.BasePos, tab.BaseAng)
        tab.Origin:Set(wPos)
        self:SetPos(wPos)
    end
end

function EFFECT:Think()
    self:SetNextClientThink(CurTime() + FrameTime())

    local tab = self:GetTable()
    local now = CurTime()
    local anyAlive = false
    local sampleRate = math.min(CONFIG.HistorySampleRate, FrameTime())

    tab.UpdateOrigin(self)

    for i = #tab.Particles, 1, -1 do
        local entry = tab.Particles[i]
        local age = now - entry.CreationTime
        local trailLife = entry.life * CONFIG.RibbonLifeTimeMult

        if age >= entry.life and entry.histCount == 0 then
            table.remove(tab.Particles, i)
            goto continue_think
        end

        anyAlive = true

        if age < entry.life then
            -- Niagara RotateAroundPoint Solver
            local currentAngle  = entry.phase + (age * tab.BaseRotationSpeed)
            local currentRadius = CONFIG.RotateRadius + (age * CONFIG.VelFromCenterMult * 60.0)

            local cosA = math.cos(currentAngle)
            local sinA = math.sin(currentAngle)

            tempLocalPos:SetUnpacked(
                cosA * currentRadius + CONFIG.RootPosOffset.x,
                sinA * currentRadius + CONFIG.RootPosOffset.y,
                CONFIG.RootPosOffset.z + (entry.axisJitterZ * CONFIG.RotateRadius * age)
            )

            tempLocalPos:Rotate(entry.jitterAng)
            tempWorldPos:Set(self:LocalToWorld(tempLocalPos))

            -- Node sampling
            if (now - entry.lastSample) >= sampleRate then
                entry.lastSample = now

                local node
                if entry.histCount < CONFIG.HistoryMaxPoints then
                    entry.histCount = entry.histCount + 1
                    node = entry.history[entry.histCount]
                else
                    -- Recycle oldest node to head without table re-allocation
                    node = table.remove(entry.history, 1)
                    table.insert(entry.history, node)
                end

                local lastDist = 0
                if entry.histCount > 1 then
                    local prevNode = entry.history[entry.histCount - 1]
                    lastDist = prevNode.cumulDist + tempWorldPos:Distance(prevNode.pos)
                end

                node.pos:Set(tempWorldPos)
                node.t = now
                node.cumulDist = lastDist
            end
        end

        -- Prune expired nodes
        while entry.histCount > 0 and (now - entry.history[1].t) > trailLife do
            local expired = table.remove(entry.history, 1)
            table.insert(entry.history, expired)
            entry.histCount = entry.histCount - 1
        end

        ::continue_think::
    end

    if not anyAlive then return false end

    tab.UpdateBounds(self)
    return true
end

function EFFECT:UpdateBounds()
    local tab = self:GetTable()
    if not tab.Particles or #tab.Particles == 0 then return end

    local minX, minY, minZ
    local maxX, maxY, maxZ

    for i = 1, #tab.Particles do
        local entry = tab.Particles[i]
        local count = entry.histCount
        for j = 1, count do
            local p = entry.history[j].pos
            if not minX then
                minX, minY, minZ = p.x, p.y, p.z
                maxX, maxY, maxZ = p.x, p.y, p.z
            else
                if p.x < minX then minX = p.x elseif p.x > maxX then maxX = p.x end
                if p.y < minY then minY = p.y elseif p.y > maxY then maxY = p.y end
                if p.z < minZ then minZ = p.z elseif p.z > maxZ then maxZ = p.z end
            end
        end
    end

    if minX then
        local pad = CONFIG.PaddingBounds
        tempMins:SetUnpacked(minX, minY, minZ)
        tempMaxs:SetUnpacked(maxX, maxY, maxZ)
        self:SetRenderBoundsWS(tempMins, tempMaxs, Vector(pad, pad, pad))
    end
end

-- ==============================================================================
-- DUAL-PASS MULTI-VMT RENDERER
-- ==============================================================================
function EFFECT:Render()
    local tab = self:GetTable()
    if not tab.Particles or #tab.Particles == 0 then return end

    local now = CurTime()
    local eyePos = EyePos()
    local baseHalfWidth = (CONFIG.BaseWidth * CONFIG.RibbonWidthMult * tab.Scale) * 0.5
    local SUBDIVISIONS = 3

    for _, entry in ipairs(tab.Particles) do
        local hist = entry.history
        local histCount = entry.histCount
        if histCount < 2 then goto continue_particle end

        -- 1. Catmull-Rom Spline Interpolation Phase
        local smoothCount = 0
        for i = 1, histCount - 1 do
            local p1 = hist[i]
            local p2 = hist[i + 1]
            local p0 = (i > 1) and hist[i - 1] or p1
            local p3 = (i + 1 < histCount) and hist[i + 2] or p2

            local isLast = (i == histCount - 1)
            local steps = isLast and SUBDIVISIONS or (SUBDIVISIONS - 1)

            for k = 0, steps do
                smoothCount = smoothCount + 1
                if smoothCount > POOL_SIZE then break end

                local fr = k / SUBDIVISIONS
                local node = point_pool[smoothCount]
                CatmullRomInplace(node.pos, p0.pos, p1.pos, p2.pos, p3.pos, fr)
                node.t = Lerp(fr, p1.t, p2.t)
                node.cumulDist = Lerp(fr, p1.cumulDist, p2.cumulDist)
            end
        end

        if smoothCount < 2 then goto continue_particle end

        -- 2. Geometry & Lighting Strip Generation Phase
        local particleAge = now - entry.CreationTime
        local particleNormAge = math.Clamp(particleAge / entry.life, 0, 1)
        local trailLife = entry.life * CONFIG.RibbonLifeTimeMult

        local scaleAlpha = SampleScaleAlpha(particleNormAge) * CONFIG.AlphaMult
        local emissiveBoost = SampleEmissiveMultiplier(particleNormAge) * CONFIG.Brightness

        for i = 1, smoothCount do
            local h = point_pool[i]
            local pos = h.pos
            local sampleAge = now - h.t
            local trailFrac = math.Clamp(sampleAge / trailLife, 0, 1)

            -- Alpha calculation combining ScaleAlpha and SpawnEnvelope
            local spawnAlpha = SampleSpawnAlpha(trailFrac)
            local finalAlpha = math.Clamp(spawnAlpha * scaleAlpha * 255.0, 0, 255)

            -- Color calculation (white-hot emissive core)
            local rVal = math.Clamp(255.0 * emissiveBoost, 0, 255)
            local gVal = math.Clamp(255.0 * emissiveBoost, 0, 255)
            local bVal = math.Clamp(255.0 * emissiveBoost, 0, 255)

            -- Tangent vector calculation
            local prevPos = (i > 1) and point_pool[i - 1].pos or pos
            local nextPos = (i < smoothCount) and point_pool[i + 1].pos or pos

            tempTangent:Set(nextPos)
            tempTangent:Sub(prevPos)
            local tanLen = tempTangent:Length()
            if tanLen > 1e-4 then
                tempTangent:Div(tanLen)
            else
                tempTangent:SetUnpacked(0, 0, 1)
            end

            -- Camera-facing billboard vector
            tempViewDir:Set(eyePos)
            tempViewDir:Sub(pos)
            local viewLen = tempViewDir:Length()
            if viewLen > 1e-4 then
                tempViewDir:Div(viewLen)
            else
                tempViewDir:SetUnpacked(0, 0, 1)
            end

            VectorCrossInplace(tempRight, tempViewDir, tempTangent)
            local rightLen = tempRight:Length()
            if rightLen > 1e-4 then
                tempRight:Div(rightLen)
            else
                tempRight:SetUnpacked(0, 0, 1)
            end

            -- Aerodynamic Ribbon Twist
            local twist = math.sin(sampleAge * 12.0 + entry.phase) * 0.40
            if math.abs(twist) > 1e-4 then
                RotateVectorAroundAxisInplace(tempRightTwisted, tempRight, tempTangent, twist)
                tempRight:Set(tempRightTwisted)
            end

            -- Width extrusion
            local width = baseHalfWidth * SampleWidthProfile(trailFrac)
            tempOffset:Set(tempRight)
            tempOffset:Mul(width)

            local strip = strip_pool[i]
            strip.posA:Set(pos)
            strip.posA:Sub(tempOffset)

            strip.posB:Set(pos)
            strip.posB:Add(tempOffset)

            -- UV0: Core ribbon length tiling
            strip.uCore = math.max(0.0005, h.cumulDist / CONFIG.CoreTilingLength)

            -- UV1: High-frequency turbulence length tiling (900 units)
            strip.uTurb = math.max(0.0005, h.cumulDist / CONFIG.TurbTilingLength)

            strip.r = rVal
            strip.g = gVal
            strip.b = bVal
            strip.a = finalAlpha

            -- Turbulence Pass: Subtle shimmering air overlay
            strip.rT = math.Clamp(rVal * 0.40, 0, 255)
            strip.gT = math.Clamp(gVal * 0.40, 0, 255)
            strip.bT = math.Clamp(bVal * 0.40, 0, 255)
            strip.aT = math.Clamp(finalAlpha * 0.60, 0, 255)
        end

        local vertexCount = smoothCount * 2

        -- ======================================================================
        -- PASS 1: CORE WIND RIBBON (mi_b_windribbon_01_core)
        -- ======================================================================
        render.SetMaterial(tab.MatCore)
        mesh.Begin(MATERIAL_TRIANGLE_STRIP, vertexCount)
        for i = 1, smoothCount do
            local s = strip_pool[i]

            mesh.Position(s.posA)
            mesh.TexCoord(0, s.uCore, 0)
            mesh.Color(s.r, s.g, s.b, s.a)
            mesh.AdvanceVertex()

            mesh.Position(s.posB)
            mesh.TexCoord(0, s.uCore, 1)
            mesh.Color(s.r, s.g, s.b, s.a)
            mesh.AdvanceVertex()
        end
        mesh.End()

        -- ======================================================================
        -- PASS 2: ATMOSPHERIC TURBULENCE (mi_b_windribbon_01_turbulence)
        -- ======================================================================
        render.SetMaterial(tab.MatTurb)
        mesh.Begin(MATERIAL_TRIANGLE_STRIP, vertexCount)
        for i = 1, smoothCount do
            local s = strip_pool[i]

            mesh.Position(s.posA)
            mesh.TexCoord(0, s.uTurb, 0)
            mesh.Color(s.rT, s.gT, s.bT, s.aT)
            mesh.AdvanceVertex()

            mesh.Position(s.posB)
            mesh.TexCoord(0, s.uTurb, 1)
            mesh.Color(s.rT, s.gT, s.bT, s.aT)
            mesh.AdvanceVertex()
        end
        mesh.End()

        ::continue_particle::
    end
end