local CONFIG = {
    RootCount                = 3,
    RotateRadius             = 110.0,
    RotateRateSpeedMult      = 1.5,
    RotationAxisRandomMult   = 0.5,
    VelFromCenterMult        = 1.0,
    LifeTime_Root_Min        = 0.3,
    LifeTime_Root_Max        = 0.55,
    AlphaMult                = 1.0,
    Brightness               = 3.0,
    RootPosOffset            = Vector(10, 10, 30),
    BaseWidth                = 15.0,
    RibbonWidthMult          = 0.5,
    RibbonLifeTimeMult       = 1.0,
    SegmentTilingLength      = 300.0,
    PaddingBounds            = 150,
    HistorySampleRate        = 0.016, 
    HistoryMaxPoints         = 64,
} 

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

local DEFAULT_WIDTH_CURVE = { {0.0, 0.1}, {0.3, 1.0}, {0.8, 0.8}, {1.0, 0.0} }
local DEFAULT_BASE_COLOR = Color(200, 230, 255)

EFFECT.Mat = Material("sprites/mi_b_windribbon_01")

function EFFECT:Init(data)
    self.CreationTime = CurTime() 
    self.Scale = data:GetScale() * 0.1 
    if self.Scale <= 0 then self.Scale = 1 end
    
    self.LifeTime = data:GetMagnitude() * 1 
    if self.LifeTime <= 0 then self.LifeTime = 1 end
    
    self.BaseRotationSpeed = (2 * math.pi) / 0.5 * CONFIG.RotateRateSpeedMult
    
    -- Grab spatial data provided by the user
    self:SetOwner(data:GetEntity()) 
    self.BoneID = data:GetHitBox() 
    
    -- Fallback to Z: 5.0 as specified in the Niagara RelativeLocation dump if GetStart is empty
    self.LocalPos = data:GetStart() or Vector(0, 0, 5) 
    self.LocalAng = data:GetAngles() or Angle(0, 0, 0)
    
    -- 1. Initial Alignment Calculation
    if IsValid(self:GetOwner()) then
        local bonePos, boneAng
        
        -- Try to fetch Bone Matrix
        if self.BoneID and self.BoneID >= 0 then
            local matrix = self:GetOwner():GetBoneMatrix(self.BoneID)
            if matrix then
                bonePos = matrix:GetTranslation()
                boneAng = matrix:GetAngles()
            else
                bonePos, boneAng = self:GetOwner():GetBonePosition(self.BoneID)
            end
        end
        
        -- Fallback to Entity Origin
        if not bonePos then
            bonePos = self:GetOwner():GetPos()
            boneAng = self:GetOwner():GetAngles()
        end

        -- Convert Local offsets to World coordinates relative to the socket/bone
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
	self:SetNextClientThink(CurTime()*FrameTime()) 
    local now = CurTime()
    local anyAlive = false
    local sampleRate = math.min(CONFIG.HistorySampleRate, FrameTime())

    -- 2. Handle "bAttach" and "bPosOnly" logic
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
        
        -- Niagara 'bPosOnly: true' means we follow the position, but NOT the rotation over time.
        self:SetPos(wPos) 
        self.Origin = wPos
        -- Notice: We purposely do NOT call self:SetAngles(wAng) here to preserve the initial slash trajectory.
    end

    -- 3. Update Ribbon History Trails
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
            
            posLocal = RotateVectorAroundAxis(posLocal, Vector(1,0,0), entry.axisJitter.x)
            posLocal = RotateVectorAroundAxis(posLocal, Vector(0,1,0), entry.axisJitter.y)
            posLocal.z = posLocal.z + entry.axisJitter.z * CONFIG.RotateRadius * age

            -- self:LocalToWorld automatically uses the newly updated self:GetPos() and the locked self:GetAngles()
            local worldPos = self:LocalToWorld(posLocal)

            if now - entry.lastSample >= sampleRate then
                entry.lastSample = now
                table.insert(entry.history, { pos = worldPos, t = now })
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

    local mins, maxs
    for _, entry in ipairs(self.Particles) do
        for _, h in ipairs(entry.history) do
            local pos = h.pos
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
        end
    end

    if mins then
        local pad = CONFIG.PaddingBounds
        self:SetRenderBoundsWS(mins, maxs, Vector(pad, pad, pad))
    end
end

function EFFECT:Render()
    if not self.Particles or #self.Particles == 0 then return end
    render.SetMaterial(self.Mat)

    local tilingLength = CONFIG.SegmentTilingLength
    local baseWidth = CONFIG.BaseWidth * CONFIG.RibbonWidthMult * self.Scale 
    local now = CurTime()

    for _, entry in ipairs(self.Particles) do
        local hist = entry.history
        if not hist or #hist < 2 then goto continue_particle end

        local cumul = 0
        local cumulTbl = { 0 }
        for i = 2, #hist do
            cumul = cumul + hist[i].pos:Distance(hist[i-1].pos)
            cumulTbl[i] = cumul
        end

        -- Correct primitive count for a Triangle Strip is (Vertices - 2)
        local vertexCount = #hist * 2
        mesh.Begin(MATERIAL_TRIANGLE_STRIP, vertexCount - 2)

        for i = 1, #hist do
            local h = hist[i]
            local pos = h.pos

            -- Age logic: Trail fades out behind the leader!
            local sampleAge = now - h.t
            local trailLife = entry.life * CONFIG.RibbonLifeTimeMult
            local trailFrac = math.Clamp(sampleAge / trailLife, 0, 1)
            local invSampleLife = 1 - trailFrac

            -- Intensity & Alpha Fade
            local alphaMul = math.ease.OutCubic(invSampleLife) * CONFIG.AlphaMult
            local alpha = math.Clamp(255 * alphaMul, 0, 255)
            local intensity = Lerp(invSampleLife, 1.5, 0.2) * CONFIG.Brightness

            local r = math.Clamp(DEFAULT_BASE_COLOR.r * intensity, 0, 2555)
            local g = math.Clamp(DEFAULT_BASE_COLOR.g * intensity, 0, 2555)
            local b = math.Clamp(DEFAULT_BASE_COLOR.b * intensity, 0, 2555)
            local acol = math.Round(alpha)

            -- Width driven by trail age
            local widthMul = SampleCurve(DEFAULT_WIDTH_CURVE, trailFrac)
            local halfWidth = (baseWidth * widthMul) * 0.5

            -- Directional Tangents
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

            -- Apply twisting turbulence 
            local twistAngle = math.sin(sampleAge * 10 + (entry.CreationTime % 3)) * 0.35
            if math.abs(twistAngle) > 1e-6 then
                right = RotateVectorAroundAxis(right, tangent, twistAngle)
                right:Normalize()
            end

            local off = right * halfWidth
            local rawU = (cumulTbl[i] or 0) / tilingLength
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
			-- if i == 1 then print(r,g,b,acol) end 
            mesh.AdvanceVertex()
        end
        mesh.End()
        ::continue_particle::
    end
end