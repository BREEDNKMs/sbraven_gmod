-- overrides: 
-- LifeTime_Root = 0.25 
-- Brightness = 1.5 
-- RibbonLifeTimeMult = 1.3 
-- InheritVel = 0.05 

--[[
    EFFECT:         NE_WindRibbon
    DESCRIPTION:    Generates multiple continuous, flowing ribbon trails attached to a specific bone.
                    Replicates UE4's Niagara Ribbon logic with hardcoded VertexLitGeneric/EmissiveBlend support.
--]]

EFFECT.Mat = Material("sprites/MI_B_WindRibbon_01") 
EFFECT.SegmentLifetime = 0.4 
EFFECT.BaseWidth = 6.0
EFFECT.TilingLength = 400.0

-- Controls the ribbon's width over its individual segment life.
-- Notice the final keyframe {1.0, 0.0}: this handles our "fade out by scaling to 0" requirement.
EFFECT.WidthCurve = {
    {0.0, 0.2}, 
    {0.2, 1.0}, 
    {0.8, 0.8}, 
    {1.0, 0.0}  
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

local function TransformUV(u, v, centerX, centerY, scaleX, scaleY, rotateDeg, transX, transY)
    centerX = centerX or 0.5
    centerY = centerY or 0.5
    scaleX  = scaleX  or 1
    scaleY  = scaleY  or 1
    rotateDeg = rotateDeg or 0
    transX = transX or 0
    transY = transY or 0

    local x = (u - centerX) * scaleX
    local y = (v - centerY) * scaleY

    local rad = math.rad(rotateDeg)
    local cosT = math.cos(rad)
    local sinT = math.sin(rad)
    local xr = x * cosT - y * sinT
    local yr = x * sinT + y * cosT

    local uf = xr + centerX + transX
    local vf = yr + centerY + transY

    return uf, vf
end

function EFFECT:Init(data)
    self.Entity = data:GetEntity()
    self.BoneID = data:GetHitBox()
    self.DieTime = data:GetMagnitude()
    self.CreationTime = CurTime()

    -- Setup parenting natively
    self:SetOwner(self.Entity)
    self:FollowBone(self.Entity, self.BoneID)

    -- Define 3 separate ribbons around the local bone position
    self.Ribbons = {}
    for i = 1, 1 do
        table.insert(self.Ribbons, {
            LocalOffset = VectorRand() * 3,
            Points = {},
            TotalLength = 0,
            LastPos = nil
        })
    end

    self:SetRenderBounds(Vector(-1000, -1000, -1000), Vector(1000, 1000, 1000))
end

function EFFECT:Think()
    if not IsValid(self.Entity) then return false end

    local now = CurTime()
    local isEmitting = (now < self.CreationTime + self.DieTime)
    local hasActivePoints = false

    -- Fetch bone matrix for precise local-to-world offsets
    local boneMat = self.Entity:GetBoneMatrix(self.BoneID)
    local bonePos = self.Entity:GetPos()
    local boneAng = self.Entity:GetAngles()

    if boneMat then
        bonePos = boneMat:GetTranslation()
        boneAng = boneMat:GetAngles()
    end

    for _, ribbon in ipairs(self.Ribbons) do
        -- 1. Handle Emission
        if isEmitting and not self.Entity:IsEffectActive(EF_NODRAW) then
            local emitPos = LocalToWorld(ribbon.LocalOffset, angle_zero, bonePos, boneAng)
            
            if ribbon.LastPos then
                local segLen = ribbon.LastPos:Distance(emitPos)
                if segLen > 1 then -- Distance tolerance for spawning a new segment
                    ribbon.TotalLength = ribbon.TotalLength + segLen
                    table.insert(ribbon.Points, 1, {
                        pos1 = ribbon.LastPos,
                        pos2 = emitPos,
                        timestamp = now,
                        cumulative = ribbon.TotalLength,
                        twistStrength = math.Rand(-1, 1) * 0.6
                    })
                    ribbon.LastPos = emitPos
                end
            else
                ribbon.LastPos = emitPos
            end
        end

        -- 2. Prune old points
        for i = #ribbon.Points, 1, -1 do
            if (now - ribbon.Points[i].timestamp) > self.SegmentLifetime then
                table.remove(ribbon.Points, i)
            end
        end

        if #ribbon.Points > 0 then
            hasActivePoints = true
        end
    end

    -- Kill the effect entirely if we're done emitting and the tail has completely faded out
    if not isEmitting and not hasActivePoints then
        return false
    end

    return true
end

function EFFECT:Render()
    local now = CurTime()
    local tris = {}

    -- Assemble all ribbons into a single triangle batch
    for _, ribbon in ipairs(self.Ribbons) do
        local pts = ribbon.Points
        if #pts >= 2 then
            local segInfos = {}

            for i = #pts, 1, -1 do
                local seg = pts[i]
                local lifeFrac = math.Clamp((now - seg.timestamp) / self.SegmentLifetime, 0, 1)

                -- Scale width to 0 to simulate fading (avoids VLG alpha issues)
                local widthMul = SampleCurve(self.WidthCurve, lifeFrac)
                local halfWidth = (self.BaseWidth * widthMul) * 0.5

                local p1 = seg.pos1
                local p2 = seg.pos2

                if p1 and p2 and p1 ~= p2 then
                    local tangent = (p2 - p1)
                    if tangent:LengthSqr() < 1e-6 then
                        tangent = Vector(0,0,1)
                    else
                        tangent:Normalize()
                    end

                    local viewDir = (EyePos() - ((p1 + p2) * 0.5)):GetNormalized()
                    local right = viewDir:Cross(tangent)
                    if right:LengthSqr() < 1e-6 then right = Vector(0,0,1):Cross(tangent) end
                    right = right:GetNormalized()

                    -- Calculate Twist
                    local twistAngle = 0
                    if i < #pts then
                        local nextSeg = pts[i+1]
                        if nextSeg then
                            local nextT = (nextSeg.pos2 - nextSeg.pos1)
                            if nextT:LengthSqr() > 1e-6 then
                                nextT:Normalize()
                                local dot = math.Clamp(tangent:Dot(nextT), -1, 1)
                                local ang = math.acos(dot)
                                twistAngle = ang * 0.5 * (seg.twistStrength or 1.0)
                            end
                        end
                    end

                    if math.abs(twistAngle) > 1e-6 then
                        right = RotateVectorAroundAxis(right, tangent, twistAngle):GetNormalized()
                    end

                    local off = right * halfWidth

                    local t = Vector(tangent.x, tangent.y, tangent.z):GetNormalized()
                    local b = Vector(right.x, right.y, right.z):GetNormalized()
                    local n = t:Cross(b)
                    if n:LengthSqr() < 1e-6 then n = Vector(0,0,1) else n = n:GetNormalized() end

                    local uCoord = (seg.cumulative or 0) / self.TilingLength
                    local tuA, tvA = TransformUV(0, uCoord, 0.5, 0.5, 1, 1, -90, 0, 0)
                    local tuB, tvB = TransformUV(1, uCoord, 0.5, 0.5, 1, 1, -90, 0, 0)

                    -- Per-vertex color is hardcoded to pure white
                    table.insert(segInfos, {
                        left = { pos = p1 - off, u = tuA, v = tvA },
                        right = { pos = p2 + off, u = tuB, v = tvB },
                        color = Color(255, 255, 255, 255),
                        normal = n,
                        tangent = t,
                        binormal = b
                    })
                end
            end

            for i = 1, #segInfos - 1 do
                local a, b = segInfos[i], segInfos[i + 1]
                table.insert(tris, { pos = a.left.pos,  u = a.left.u,  v = a.left.v,  color = a.color, normal = a.normal, tangent = a.tangent, binormal = a.binormal })
                table.insert(tris, { pos = a.right.pos, u = a.right.u, v = a.right.v, color = a.color, normal = a.normal, tangent = a.tangent, binormal = a.binormal })
                table.insert(tris, { pos = b.left.pos,  u = b.left.u,  v = b.left.v,  color = b.color, normal = b.normal, tangent = b.tangent, binormal = b.binormal })

                table.insert(tris, { pos = b.left.pos,  u = b.left.u,  v = b.left.v,  color = b.color, normal = b.normal, tangent = b.tangent, binormal = b.binormal })
                table.insert(tris, { pos = a.right.pos, u = a.right.u, v = a.right.v, color = a.color, normal = a.normal, tangent = a.tangent, binormal = a.binormal })
                table.insert(tris, { pos = b.right.pos, u = b.right.u, v = b.right.v, color = b.color, normal = b.normal, tangent = b.tangent, binormal = b.binormal })
            end
        end
    end

    -- Draw the unified mesh if we have geometry
    if #tris > 0 then
        render.SetMaterial(self.Mat)
        local meshObj = Mesh(self.Mat) 
        meshObj:BuildFromTriangles(tris) 
        meshObj:Draw() 
        meshObj:Destroy() 
    end
end