local CONFIG = {
    RootCount                = 3,
    RotateRadius             = 32.0,
    RotateRateSpeedMult      = 2,
    RotationAxisRandomMult   = 0.5,
    VelFromCenterMult        = 1.0,
    LifeTime_Root_Min        = 0.3,
    LifeTime_Root_Max        = 0.55,
    AlphaMult                = 1.0,
    Brightness               = 3.0,
    RootPosOffset            = Vector(10, 10, 30),
    BaseWidth                = 3.0,
    RibbonWidthMult          = 0.5,
    RibbonLifeTimeMult       = 1.0,
    SegmentTilingLength      = 300.0,
    PaddingBounds            = 150,
    HistorySampleRate        = 0.016, 
    HistoryMaxPoints         = 64,
} 

-- PRE-ALLOCATED POOL: Prevents garbage collector spikes from thousands of vector re-allocations per frame
local POOL_SIZE = 512
local point_pool = {}
for i = 1, POOL_SIZE do
    point_pool[i] = { pos = Vector(0, 0, 0), t = 0, cumulDist = 0 }
end

-- High-performance, allocation-free Catmull-Rom spline evaluator
local function CatmullRomInplace(out, p0, p1, p2, p3, t)
    local t2 = t * t
    local t3 = t2 * t
    
    out.x = 0.5 * ((2 * p1.x) + (-p0.x + p2.x) * t + (2 * p0.x - 5 * p1.x + 4 * p2.x - p3.x) * t2 + (-p0.x + 3 * p1.x - 3 * p2.x + p3.x) * t3)
    out.y = 0.5 * ((2 * p1.y) + (-p0.y + p2.y) * t + (2 * p0.y - 5 * p1.y + 4 * p2.y - p3.y) * t2 + (-p0.y + 3 * p1.y - 3 * p2.y + p3.y) * t3)
    out.z = 0.5 * ((2 * p1.z) + (-p0.z + p2.z) * t + (2 * p0.z - 5 * p1.z + 4 * p2.z - p3.z) * t2 + (-p0.z + 3 * p1.z - 3 * p2.z + p3.z) * t3)
end

local function SampleCurve(tbl, t)
    if not tbl or #tbl == 0 then return 1.0 end
    if t <= tbl[1][1] then return tbl[1][2] end
    for i = 2, #tbl do
        local aT, aV = tbl[i - 1][1], tbl[i - 1][2]
        local bT, bV = tbl[i][1], tbl[i][2]
        if t <= bT then
            local range = bT - aT
            if range == 0 then return aV end
            return Lerp((t - aT) / range, aV, bV)
        end
    end
    return tbl[#tbl][2]
end

-- Kept exclusively for the rendering twist step since it uses an arbitrary tangent axis
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

local DEFAULT_WIDTH_CURVE = { {0.0, 0.1}, {0.3, 1.0}, {0.8, 0.8}, {1.0, 0.0} }
local DEFAULT_BASE_COLOR = Color(255, 255, 255)

EFFECT.Mat = Material("sprites/mi_b_windribbon_01")

function EFFECT:Init(data)
    self.CreationTime = CurTime() 
    self:SetModelScale(data:GetScale()) 
    self:SetOwner(data:GetEntity()) 
    
    self.LifeTime = data:GetMagnitude() * 1 
    if self.LifeTime <= 0 then self.LifeTime = 0.2 end
    
    self.BaseRotationSpeed = (2 * math.pi) / 0.5 * CONFIG.RotateRateSpeedMult
    self.BoneID = data:GetHitBox() 
    
    self.LocalPos = data:GetStart() or Vector(0, 0, 5) 
    self.LocalAng = data:GetAngles() or Angle(0, 0, 0)
    
    if IsValid(self:GetOwner()) then
        local bonePos, boneAng
        if self.BoneID and self.BoneID >= 0 then
            local matrix = self:GetOwner():GetBoneMatrix(self.BoneID)
            if matrix then
                bonePos = matrix:GetTranslation()
                boneAng = matrix:GetAngles()
            else
                bonePos, boneAng = self:GetOwner():GetBonePosition(self.BoneID)
            end
        end
        
        if not bonePos then
            bonePos = self:GetOwner():GetPos()
            boneAng = self:GetOwner():GetAngles()
        end

        local wPos, wAng = LocalToWorld(self.LocalPos, self.LocalAng, bonePos, boneAng)
        self:SetPos(wPos)
        self:SetAngles(wAng)
        self.Origin = wPos
    else
        self.Origin = data:GetOrigin() or vector_origin
        self:SetPos(self.Origin)
        self:SetAngles(self.LocalAng)
    end

    self.Particles = {} 
    
    for i = 1, CONFIG.RootCount do
        local phase = (i - 1) * (2 * math.pi / CONFIG.RootCount) + math.Rand(0, 0.1)
        local life = math.Rand(CONFIG.LifeTime_Root_Min, CONFIG.LifeTime_Root_Max) * self.LifeTime 
        local axisJitter = RandomUnitVector() * CONFIG.RotationAxisRandomMult
        
        table.insert(self.Particles, {
            CreationTime = self.CreationTime,
            life = life,
            phase = phase,
            axisJitter = axisJitter,
            history = {},
            lastSample = 0
        })
    end

    local pad = CONFIG.PaddingBounds
    self:SetRenderBoundsWS(self.Origin - Vector(pad,pad,pad), self.Origin + Vector(pad,pad,pad), Vector(pad,pad,pad))
end

function EFFECT:Think()
	self:SetNextClientThink(CurTime()+FrameTime()) -- stops client thinking when the game is paused 
	local now = CurTime()
    local anyAlive = false
    local sampleRate = math.min(CONFIG.HistorySampleRate, FrameTime())

    if IsValid(self:GetOwner()) then
        local bonePos, boneAng
        if self.BoneID and self.BoneID >= 0 then
            local matrix = self:GetOwner():GetBoneMatrix(self.BoneID)
            if matrix then
                bonePos = matrix:GetTranslation()
                boneAng = matrix:GetAngles()
            else
                bonePos, boneAng = self:GetOwner():GetBonePosition(self.BoneID)
            end
        end
        
        if not bonePos then
            bonePos = self:GetOwner():GetPos()
            boneAng = self:GetOwner():GetAngles()
        end

        local wPos = LocalToWorld(self.LocalPos, self.LocalAng, bonePos, boneAng)
        self:SetPos(wPos) 
        self.Origin = wPos
    end

    for i = #self.Particles, 1, -1 do
        local entry = self.Particles[i]
        local age = now - entry.CreationTime
        local trailLife = entry.life * CONFIG.RibbonLifeTimeMult

        if age >= entry.life and #entry.history == 0 then
            table.remove(self.Particles, i)
            goto cont
        end

        anyAlive = true

        if age < entry.life then
            local currentAngle = entry.phase + (age * self.BaseRotationSpeed)
            local currentRadius = CONFIG.RotateRadius + (age * CONFIG.VelFromCenterMult * 60)
            
            local posLocal = Vector(math.cos(currentAngle), math.sin(currentAngle), 0) * currentRadius + CONFIG.RootPosOffset
            
            local jitterAng = Angle(math.deg(entry.axisJitter.y), 0, math.deg(entry.axisJitter.x))
            posLocal:Rotate(jitterAng)
            posLocal.z = posLocal.z + entry.axisJitter.z * CONFIG.RotateRadius * age

            local worldPos = self:LocalToWorld(posLocal)

            if now - entry.lastSample >= sampleRate then
                entry.lastSample = now
                
                local lastIdx = #entry.history
                local cumulDist = 0
                if lastIdx > 0 then
                    local lastNode = entry.history[lastIdx]
                    cumulDist = lastNode.cumulDist + worldPos:Distance(lastNode.pos)
                end
                
                table.insert(entry.history, { pos = worldPos, t = now, cumulDist = cumulDist })
            end
        end

        while #entry.history > 0 and (now - entry.history[1].t) > trailLife do
            table.remove(entry.history, 1)
        end
        while #entry.history > CONFIG.HistoryMaxPoints do
            table.remove(entry.history, 1)
        end

        ::cont::
    end

    if not anyAlive then return false end
    
    self:UpdateRenderBoundsFromParticles()
    return true
end

function EFFECT:UpdateRenderBoundsFromParticles()
    if not self.Particles or #self.Particles == 0 then return end

    -- OPTIMIZATION: Kept tracking metrics localized as pure numbers to stop garbage collection thrashing
    local minX, minY, minZ
    local maxX, maxY, maxZ

    for i = 1, #self.Particles do
        local entry = self.Particles[i]
        local hist = entry.history
        for j = 1, #hist do
            local pos = hist[j].pos
            local px, py, pz = pos.x, pos.y, pos.z
            if not minX then
                minX, minY, minZ = px, py, pz
                maxX, maxY, maxZ = px, py, pz
            else
                if px < minX then minX = px elseif px > maxX then maxX = px end
                if py < minY then minY = py elseif py > maxY then maxY = py end
                if pz < minZ then minZ = pz elseif pz > maxZ then maxZ = pz end
            end
        end
    end

    if minX then
        local pad = CONFIG.PaddingBounds
        self:SetRenderBoundsWS(Vector(minX, minY, minZ), Vector(maxX, maxY, maxZ), Vector(pad, pad, pad))
    end
end

function EFFECT:Render()
    if not self.Particles or #self.Particles == 0 then return end
    render.SetMaterial(self.Mat)

    local tilingLength = CONFIG.SegmentTilingLength
    local baseWidth = CONFIG.BaseWidth * CONFIG.RibbonWidthMult * self:GetModelScale() 
    local now = CurTime()
    local eyePos = EyePos()

    for _, entry in ipairs(self.Particles) do
        local hist = entry.history
        if not hist or #hist < 2 then goto continue_particle end

        -- SUBDIVISIONS: Number of linear sub-steps generated between each raw history node.
        -- 3 or 4 is ideal for perfectly round swooshes. Higher values increase vertex weight.
        local SUBDIVISIONS = 4
        local smoothCount = 0

        -- Dynamic Spline Interpolation Phase
        for i = 1, #hist - 1 do
            local p1 = hist[i]
            local p2 = hist[i+1]
            local p0 = (i > 1) and hist[i-1] or p1
            local p3 = (i + 1 < #hist) and hist[i+2] or p2

            local isLastSegment = (i == #hist - 1)
            local steps = isLastSegment and SUBDIVISIONS or (SUBDIVISIONS - 1)
            
            for k = 0, steps do
                local fr = k / SUBDIVISIONS
                smoothCount = smoothCount + 1
                if smoothCount > POOL_SIZE then break end
                
                local node = point_pool[smoothCount]
                CatmullRomInplace(node.pos, p0.pos, p1.pos, p2.pos, p3.pos, fr)
                node.t = Lerp(fr, p1.t, p2.t)
                node.cumulDist = Lerp(fr, p1.cumulDist, p2.cumulDist)
            end
        end

        if smoothCount < 2 then goto continue_particle end

        local vertexCount = smoothCount * 2
        mesh.Begin(MATERIAL_TRIANGLE_STRIP, vertexCount)

        -- Draw using the newly subdivided pool
        for i = 1, smoothCount do
            local h = point_pool[i]
            local pos = h.pos

            local sampleAge = now - h.t
            local trailLife = entry.life * CONFIG.RibbonLifeTimeMult
            local trailFrac = math.Clamp(sampleAge / trailLife, 0, 1)
            local invSampleLife = 1 - trailFrac

            local alphaMul = math.ease.OutCubic(invSampleLife) * CONFIG.AlphaMult
            local alpha = math.Clamp(255 * alphaMul, 0, 255)
            local intensity = Lerp(invSampleLife, 1.5, 0.2) * CONFIG.Brightness

            local r = math.Clamp(DEFAULT_BASE_COLOR.r * intensity, 0, 255)
            local g = math.Clamp(DEFAULT_BASE_COLOR.g * intensity, 0, 255)
            local b = math.Clamp(DEFAULT_BASE_COLOR.b * intensity, 0, 255)
            local acol = math.Round(alpha)

            local widthMul = SampleCurve(DEFAULT_WIDTH_CURVE, trailFrac)
            local halfWidth = (baseWidth * widthMul) * 0.5

            local prevPos = (i > 1) and point_pool[i-1].pos or pos
            local nextPos = (i < smoothCount) and point_pool[i+1].pos or pos
            local tangent = (nextPos - prevPos)
            if tangent:LengthSqr() < 1e-6 then tangent = Vector(0,0,1) else tangent:Normalize() end

            local viewDir = (eyePos - pos)
            if viewDir:LengthSqr() < 1e-6 then viewDir = Vector(0,0,1) end
            viewDir:Normalize()

            local right = viewDir:Cross(tangent)
            if right:LengthSqr() < 1e-6 then right = Vector(0,0,1):Cross(tangent) end
            right:Normalize()

            local twistAngle = math.sin(sampleAge * 10 + (entry.CreationTime % 3)) * 0.35
            if math.abs(twistAngle) > 1e-6 then
                right = RotateVectorAroundAxis(right, tangent, twistAngle)
                right:Normalize()
            end

            local off = right * halfWidth
            local rawU = h.cumulDist / tilingLength
            local uCoord = math.max(0.0005, rawU)

            -- Vertex A
            mesh.Position(pos - off)
            mesh.TexCoord(0, uCoord, 0)
            mesh.Color(r, g, b, acol)
            mesh.AdvanceVertex()

            -- Vertex B
            mesh.Position(pos + off)
            mesh.TexCoord(0, uCoord, 1)
            mesh.Color(r, g, b, acol)
            mesh.AdvanceVertex()
        end
        mesh.End()
        ::continue_particle::
    end
end