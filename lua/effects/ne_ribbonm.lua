--[[
    EFFECT:         NE_RibbonM (Niagara Emitter Recreation)
    DESCRIPTION:    Generates a continuous, flowing ribbon trail attached to an entity.
                    The behavior and parameters are derived directly from the Unreal Engine
                    JSON properties for 'NE_RibbonM' and 'NiagaraRibbonRendererProperties_2'.
--]]

-- === PARAMETERS DERIVED FROM JSON ===

-- From NiagaraRibbonRendererProperties_2 -> Material -> MI_D_RibbonDefault_01 
EFFECT.Mat = Material("sprites/T_A_StreakSwirl_01") 

-- Derived from the average of the Lifetime module in NS_D_RavenHuman_WPBuffTrail_01 (Min: 0.3, Max: 0.5) 
EFFECT.SegmentLifetime = 0.4 

-- Derived from the RibbonWidth module (Value: 10.0)
EFFECT.BaseWidth = 10.0

-- From UV0Settings -> TilingLength
EFFECT.TilingLength = 250.0

-- A width curve to simulate dynamic width changes over the ribbon's life,
-- mimicking the 'RibbonWidthBinding' functionality.
EFFECT.WidthCurve = {
    {0.0, 0.2}, -- Starts thin
    {0.2, 1.0}, -- Quickly widens
    {0.8, 0.8}, -- Stays wide
    {1.0, 0.0}  -- Fades to nothing
}

-- Simple function to sample a point from a curve table.
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

function EFFECT:Init(data)
    self.Entity = data:GetEntity()
    self.AttachmentID = data:GetAttachment()
    self.DieTime = -1 -- Loop indefinitely by default

    if !IsValid(self.Entity) then return end

    self.TrailPoints = {}
    self.TotalLength = 0
    self.LastPos = self:GetTrailPos()

    if !self.LastPos then return end

    -- Add the very first point to start the trail
    self:AddPoint(self.LastPos)

    self:SetRenderBounds(Vector(-1000, -1000, -1000), Vector(1000, 1000, 1000))
end

function EFFECT:GetTrailPos()
    local ent = self.Entity
    if !IsValid(ent) then
        return vector_origin
    end
	
	local ent = self:GetRenderEntity() 
	-- temp: use hand bone Position instead of attachment variable 
	-- until attachments are added to the weapon qc 
	local pos = ent:LookupBone("ValveBiped.Bip01_R_Hand") 
	if !pos then return ent:EyePos() end 
	pos = ent:GetBoneMatrix(pos) 
	if pos then pos = pos:GetTranslation() end 
	-- print(ent,ent:LookupBone("ValveBiped.Bip01_R_Hand"),ent:GetBoneMatrix(1):GetTranslation()) 
	-- local pos = ent:GetBoneMatrix(ent:LookupBone("ValveBiped.Bip01_R_Hand")):GetTranslation() 
	if pos then return pos end 
	local att = ent:GetAttachment(self.AttachmentID)
	if att and att.Pos then return att.Pos end

    return ent:EyePos() 
end

function EFFECT:AddPoint(pos)
    local segLen = 0
    if self.LastPos then
        segLen = self.LastPos:Distance(pos)
    end
	local prev = self.LastPos or pos

    self.TotalLength = self.TotalLength + segLen

    table.insert(self.TrailPoints, 1, {
    pos1 = prev,         -- previous point
	pos2 = pos,          -- new point
    timestamp = CurTime(),
    segLen = segLen,
    cumulative = self.TotalLength,
    rand = math.Rand(0.8, 1.2),    -- per-seg random
    twistStrength = math.Rand(-1,1) * 0.6 -- tune
})
	self.LastPos = pos
end

function EFFECT:Think()
    if !IsValid(self.Entity) or !self.Entity:Alive() then return false end

    local currentPos = self:GetTrailPos()
    if !currentPos then return true end -- Continue trying if attachment is temporarily invalid
	if self.Entity:IsEffectActive(EF_NODRAW) then return true end 

    -- To replicate 'bInterpolatedSpawning', we add a point only when it has moved.
    if !currentPos:IsEqualTol(self.LastPos, 1) then
        self:AddPoint(currentPos)
        self.LastPos = currentPos
    end
	self:SetPos(self.Entity:GetPos()) 

    -- Prune old points from the trail
    local t = CurTime()
    for i = #self.TrailPoints, 1, -1 do
        if (t - self.TrailPoints[i].timestamp) > self.SegmentLifetime then
            table.remove(self.TrailPoints, i)
        end
    end

    return true
end

local function RotateVectorAroundAxis(v, k, theta)
    -- Rodrigues' rotation formula:
    -- v_rot = v*cos(theta) + (k x v)*sin(theta) + k*(k·v)*(1-cos(theta))
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

function EFFECT:GetRenderEntity()
    if !IsValid(self.Entity) then return nil end

    -- If it's a weapon whose owner is the local player in first-person, prefer the viewmodel
    if self.Entity:IsWeapon() then
        local owner = self.Entity:GetOwner()
        if IsValid(owner) and owner:IsPlayer() and owner == LocalPlayer() and !owner:ShouldDrawLocalPlayer() then
            local vm = owner:GetViewModel()
            if IsValid(vm) then return vm end
        end
    end

    return self.Entity
end 

-- Transform UVs using Material "$basetexturetransform" style:
-- centerX, centerY :: pivot point (0..1)
-- scaleX, scaleY   :: scale multipliers (1 = no scale)
-- rotateDeg         :: degrees (positive = CCW), negative = CW (matches VMT rotate)
-- transX, transY    :: translation in UV space
local function TransformUV(u, v, centerX, centerY, scaleX, scaleY, rotateDeg, transX, transY)
    -- defaults
    centerX = centerX or 0.5
    centerY = centerY or 0.5
    scaleX  = scaleX  or 1
    scaleY  = scaleY  or 1
    rotateDeg = rotateDeg or 0
    transX = transX or 0
    transY = transY or 0

    -- move to center and apply scale
    local x = (u - centerX) * scaleX
    local y = (v - centerY) * scaleY

    -- rotate
    local rad = math.rad(rotateDeg)
    local cosT = math.cos(rad)
    local sinT = math.sin(rad)
    local xr = x * cosT - y * sinT
    local yr = x * sinT + y * cosT

    -- move back and apply translation
    local uf = xr + centerX + transX
    local vf = yr + centerY + transY

    return uf, vf
end


function EFFECT:Render()
    local pts = self.TrailPoints
    if !pts or #pts < 2 then return end

    -- Cache some locals for speed
    local mat = self.Mat
    local now = CurTime()
    local segLife = self.SegmentLifetime
    local baseWidth = self.BaseWidth or 10
    local tilingLength = self.TilingLength or 250
    local hdrBoost = self.HDRMultiplier or 10.0

    -- Precompute cumulative length table (if you don't store it per-seg)
    -- Your AddSegment already records cumulative length as seg.cumulative - use that.
    -- We will compute U using seg.cumulative / tilingLength	
    render.SetMaterial(mat)

    local segInfos = {}
    for i = #pts, 1, -1 do
        local seg = pts[i]
        local lifeFrac = math.Clamp((now - seg.timestamp) / segLife, 0, 1)
        local invLife = 1 - lifeFrac

        local alpha = math.sin(math.pi * invLife)
        local intensity = Lerp(invLife, 1.5, 0.2)
        local rcol = 0
        local gcol = math.Clamp(180 * intensity * hdrBoost, 0, 255)
        local bcol = math.Clamp(255 * intensity * hdrBoost, 0, 255)
        local acol = math.Clamp(255 * alpha, 0, 255)

        local widthMul = SampleCurve(self.WidthCurve, lifeFrac)
        local halfWidth = (baseWidth * widthMul * (self.WidthMultiplier or 1)) * 0.5

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

            local twistAngle = 0
            if self.TwistCurve then
                local twistNormalized = SampleCurve(self.TwistCurve, lifeFrac)
                twistAngle = twistNormalized * (seg.twistStrength or 1.0)
            else
                if i < #pts then
                    local nextSeg = pts[i+1]
                    if nextSeg then
                        local nextT = (nextSeg.pos2 - nextSeg.pos1)
                        if nextT:LengthSqr() > 1e-6 then
                            nextT:Normalize()
                            local dot = math.Clamp(tangent:Dot(nextT), -1, 1)
                            local ang = math.acos(dot)
                            twistAngle = ang * 0.5 * (seg.rand or 1.0)
                        end
                    end
                end
            end

            if math.abs(twistAngle) > 1e-6 then
                right = RotateVectorAroundAxis(right, tangent, twistAngle)
                right = right:GetNormalized()
            end

            local off = right * halfWidth

            -- Per-vertex basis:
            local t = Vector(tangent.x, tangent.y, tangent.z)
            t = t:GetNormalized()

            local b = Vector(right.x, right.y, right.z)
            b = b:GetNormalized()

            local n = t:Cross(b)
            if n:LengthSqr() < 1e-6 then
                n = Vector(0,0,1)
            else
                n = n:GetNormalized()
            end

            local uCoord = (seg.cumulative or 0) / tilingLength
            local uA, vA = 0, uCoord
            local uB, vB = 1, uCoord
            local tuA, tvA = TransformUV(uA, vA, 0.5, 0.5, 1, 1, -90, 0, 0)
            local tuB, tvB = TransformUV(uB, vB, 0.5, 0.5, 1, 1, -90, 0, 0)
			-- self.Mat:SetVector("$color2",Vector(rcol/255,gcol/255,bcol/255)) 
			-- self.Mat:SetVector("$emissiveblendtint",Vector(rcol/255,gcol/255,bcol/255)) 
			-- self.Mat:SetInt("$emissiveblendstrength",acol) 

            table.insert(segInfos, {
                left = { pos = p1 - off, u = tuA, v = tvA },
                right = { pos = p2 + off, u = tuB, v = tvB },
                -- color = Color(rcol, gcol, bcol, acol),
				-- color = Color(math.random(0,255), math.random(0,255), math.random(0,255), math.random(0,255)), 
                normal = n,
                tangent = t,
                binormal = b
            })
        end
    end

    if #segInfos < 2 then return end

    local tris = {}
    for i = 1, #segInfos - 1 do
        local a = segInfos[i]
        local b = segInfos[i + 1]

        -- Triangle 1
		-- print(a.color) 
        table.insert(tris, { pos = a.left.pos,  u = a.left.u,  v = a.left.v,  color = a.color, normal = a.normal, tangent = a.tangent, binormal = a.binormal })
        table.insert(tris, { pos = a.right.pos, u = a.right.u, v = a.right.v, color = a.color, normal = a.normal, tangent = a.tangent, binormal = a.binormal })
        table.insert(tris, { pos = b.left.pos,  u = b.left.u,  v = b.left.v,  color = b.color, normal = b.normal, tangent = b.tangent, binormal = b.binormal })

        -- Triangle 2
        table.insert(tris, { pos = b.left.pos,  u = b.left.u,  v = b.left.v,  color = b.color, normal = b.normal, tangent = b.tangent, binormal = b.binormal })
        table.insert(tris, { pos = a.right.pos, u = a.right.u, v = a.right.v, color = a.color, normal = a.normal, tangent = a.tangent, binormal = a.binormal })
        table.insert(tris, { pos = b.right.pos, u = b.right.u, v = b.right.v, color = b.color, normal = b.normal, tangent = b.tangent, binormal = b.binormal })
    end

    local meshObj = Mesh(mat) 
    meshObj:BuildFromTriangles(tris) 
    meshObj:Draw() 
    meshObj:Destroy() 
	-- self.Mat:SetUndefined("$color") 
	-- self.Mat:SetUndefined("$color2") 
	-- self.Mat:SetUndefined("$emissiveblendtint") 
	-- self.Mat:SetUndefined("$emissiveblendstrength") 
end
