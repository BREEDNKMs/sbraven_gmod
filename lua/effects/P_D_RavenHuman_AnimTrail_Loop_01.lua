-- P_D_RavenHuman_AnimTrail_Loop_01 
EFFECT.Mat = Material("trails/t_c_animtrail_02") 
EFFECT.SegmentLifetime = 0.4 
function EFFECT:Init(data)
    self.Entity = data:GetEntity()
	self.Scale = data:GetScale() -- LifeTime, update to GetMagnitude 
	-- print("scale:",self.Scale) 
	self.Attachment = data:GetAttachment() -- hand attachment 
	self.DieTime = CurTime() + self.Scale 
	if !self.Attachment or self.Attachment == 0 then self.Attachment = 1 end 
	-- Unreal SBShowTrailKey Duration
    -- self.DieTime = CurTime() + self.DieTime -- append dietime 
	if data:GetScale() <= 0 then self.DieTime = -1 end -- infinite 
	self.CumulativeLengths = {}      -- optional: cumulative length at each insertion
	-- print(CurTime(),self.DieTime) 

    self.TrailPoints = {}
    if !IsValid(self.Entity) then return end

    -- print("raven trail created", self, self.Entity)
	self:SetPos(self.Entity:GetPos()) 
    self:SetParent(self.Entity)
    -- self:SetModel(self.Entity:GetModel()) -- to enable rendering. don't touch 
	-- PrintTable(self:GetTable()) 

    -- self.Attachment1 = self.Entity:LookupAttachment("ValveBiped.Bip01_L_Hand")
    -- self.Attachment2 = self.Entity:LookupAttachment("ValveBiped.Bip01_R_Hand")
    -- if self.Attachment1 == 0 or self.Attachment2 == 0 then return end
	self.Attachment1 = 70 -- forward distance, grip of the sword 
	self.Attachment2 = 9 -- forward distance, tip of the sword 

    local pos1 = self:GetAttachmentPos(self.Attachment1)
    local pos2 = self:GetAttachmentPos(self.Attachment2)
    if not pos1 or not pos2 then return end

    self.LastPos1, self.LastPos2 = pos1, pos2
    self:AddSegment(pos1, pos2)
    self:SetRenderBounds(Vector(-256, -256, -256), Vector(256, 256, 256))
	-- print("render bounds set") 
	-- print(self:GetPos()) 
end 

function EFFECT:GetRenderEntity() 
	if !IsValid(GetViewEntity():GetActiveWeapon()) then return self.Entity end 
	if self.Entity == GetViewEntity():GetActiveWeapon() then 
		return GetViewEntity():GetViewModel() 
	end 
	return self.Entity 
end 

-- Prefer real attachments if the model has them. Fallback to bone + offset.
function EFFECT:GetAttachmentPos(id)
	local GetRenderEntity = self:GetRenderEntity() 
    if !IsValid(GetRenderEntity) then return end

    -- try GetAttachment (works when model has named attachments)
    -- if self.Entity.GetAttachment then
        -- local ok, att = pcall(self.Entity.GetAttachment, self.Entity, id)
        -- if ok and att and att.Pos then
            -- return att.Pos
        -- end
    -- end

    -- fallback: lookup a reasonable bone and offset by forward/up depending on id meaning
    local handBone = GetRenderEntity:LookupBone("ValveBiped.Bip01_R_Hand")
    if !handBone then
        -- try any bone idx 0
        handBone = 0
    end

    local matrix = GetRenderEntity:GetBoneMatrix(handBone)
    if not matrix then return end

    local pos = matrix:GetTranslation()
    local ang = matrix:GetAngles()
    pos = pos - ang:Up() * id

    return pos
end

function EFFECT:AddSegment(pos1, pos2)
    local now = CurTime()
    local segLen = pos1:Distance(pos2)
    -- maintain cumulative length for UV calculation
    self.TotalLength = (self.TotalLength or 0) + segLen

    table.insert(self.TrailPoints, 1, {
        pos1 = pos1,
        pos2 = pos2,
        timestamp = now,
        segLen = segLen,
        cumulative = self.TotalLength
    })
end

function EFFECT:PruneSegments()
    local t = CurTime()
    local removedLen = 0
    for i = #self.TrailPoints, 1, -1 do
        if (t - self.TrailPoints[i].timestamp) > self.SegmentLifetime then
            removedLen = removedLen + (self.TrailPoints[i].segLen or 0)
            table.remove(self.TrailPoints, i)
        end
    end
    -- subtract removed length from total so cumulative stays consistent
    self.TotalLength = math.max(0, (self.TotalLength or 0) - removedLen)
end 

function EFFECT:UpdateRenderBounds()
    -- Don't try to calculate bounds if there are no points
    if not self.TrailPoints or #self.TrailPoints == 0 then return end

    -- Initialize mins and maxs with the first point of the first segment
    -- We must :Copy() to avoid modifying the vector in the table
    local mins = Vector(self.TrailPoints[1].pos1)
    local maxs = Vector(self.TrailPoints[1].pos1)

    -- Iterate through all segments to expand the bounds
    for i = 1, #self.TrailPoints do
        local seg = self.TrailPoints[i]

		--- Expand the AABB to include this segment's pos1 ---
        -- Compare and set minimums
        mins.x = math.min(mins.x, seg.pos1.x)
        mins.y = math.min(mins.y, seg.pos1.y)
        mins.z = math.min(mins.z, seg.pos1.z)

        -- Compare and set maximums
        maxs.x = math.max(maxs.x, seg.pos1.x)
        maxs.y = math.max(maxs.y, seg.pos1.y)
        maxs.z = math.max(maxs.z, seg.pos1.z)

        -- --- Expand the AABB to include this segment's pos2 ---
        -- Compare and set minimums
        mins.x = math.min(mins.x, seg.pos2.x)
        mins.y = math.min(mins.y, seg.pos2.y)
        mins.z = math.min(mins.z, seg.pos2.z)

        -- Compare and set maximums
        maxs.x = math.max(maxs.x, seg.pos2.x)
        maxs.y = math.max(maxs.y, seg.pos2.y)
        maxs.z = math.max(maxs.z, seg.pos2.z)
    end

    -- Add a small amount of padding (e.g., 16 units)
    -- This helps prevent the trail from being culled if it's
    -- right at the edge of the screen or view.
    local padding = Vector(16, 16, 16)

    -- Set the world-space render bounds as requested
    -- self:SetRenderBoundsWS( mins, maxs, add )
    self:SetRenderBoundsWS(mins, maxs, padding)
end

function EFFECT:Think()
	local GetRenderEntity = self:GetRenderEntity() 
	if !IsValid(GetRenderEntity) then return false end 
	self:SetLocalPos(GetRenderEntity:GetLocalPos()) 
	if self.DieTime > 0 then 
		if CurTime() > self.DieTime then return false end 
	end 
	if GetRenderEntity:GetNoDraw() then -- may enable rendering afterwards, don't update stats but keep effect entity 
		return true 
	end 

    local pos1 = self:GetAttachmentPos(self.Attachment1)
    local pos2 = self:GetAttachmentPos(self.Attachment2)
	-- debugoverlay.Cross(pos1,32,1) 
	-- debugoverlay.Cross(pos2,32,1) 
    if !pos1 or !pos2 then return false end

    -- Only add a new segment when positions moved a small epsilon to avoid duplicates
    if !pos1:IsEqualTol(self.LastPos1 or vector_origin,0.1) or !pos2:IsEqualTol(self.LastPos2 or vector_origin,0.1) then
        self:AddSegment(pos1, pos2)
        self.LastPos1, self.LastPos2 = pos1, pos2
    end

    self:PruneSegments() 
	self:UpdateRenderBounds()
    return true
end

-- tuning
-- EFFECT.BaseWidth = 32.0         -- manual width in world units (raise to make thicker)
EFFECT.WidthMultiplier = 1.0    -- global scale
EFFECT.WidthMin = 10.0           -- never thinner than this
EFFECT.WidthMax = 50.0          -- never wider than this
-- EFFECT.ScaleByAttachmentDistance = false -- set true to use distance(pos1,pos2) as base width

-- optional width-over-life curve: lifeFrac in [0..1] => multiplier
-- example: start full, slightly grow, then shrink to zero
EFFECT.WidthCurve = {
    {0.0, 1.0},
    {0.2, 1.2},
    {0.7, 0.6},
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
            -- Prevent division by zero if time values are identical
            if range == 0 then return aV end
            local frac = (t - aT) / range
            return Lerp(frac, aV, bV)
        end
    end
    return tbl[#tbl][2]
end

-- modify Render's width calculation to use these params
function EFFECT:Render()
    if !self.TrailPoints or #self.TrailPoints < 2 then return end

    render.SetMaterial(self.Mat)
    mesh.Begin(MATERIAL_TRIANGLE_STRIP, #self.TrailPoints * 2)

    for i = #self.TrailPoints, 1, -1 do
        local seg = self.TrailPoints[i]
        local lifeFrac = math.Clamp((CurTime() - seg.timestamp) / self.SegmentLifetime, 0, 1)

        -- --- Appearance Calculation ---
        local alpha = math.sin(math.pi * (1 - lifeFrac)) * 255
        local intensity = Lerp(lifeFrac, 1.5, 0.0)
        local trailColor = Color(0, 1800 * intensity, 2550 * intensity, alpha)

        -- --- Vertex Position & Width Calculation ---
        local pos1 = seg.pos1
        local pos2 = seg.pos2
        local lifeMultiplier = SampleCurve(self.WidthCurve, lifeFrac)

        if self.WidthMultiplier ~= 1.0 or lifeMultiplier ~= 1.0 then
            local midPoint = (pos1 + pos2) * 0.5
            local direction = pos2 - pos1
            if direction:LengthSqr() > 0.01 then
                direction:Normalize()
                local width = pos1:Distance(pos2) * self.WidthMultiplier * lifeMultiplier
                pos1 = midPoint - direction * (width * 0.5)
                pos2 = midPoint + direction * (width * 0.5)
            end
        end

        -- --- UV Mapping ---
        local vCoord = 1 - (i / #self.TrailPoints)

        -- --- Build the Mesh ---
        -- Add the first vertex (Grip Side)
        mesh.Position(pos1)
        mesh.TexCoord(0, 0, vCoord)
        -- CORRECTED: Unpack the Color object into R, G, B, A
        mesh.Color(trailColor.r, trailColor.g, trailColor.b, trailColor.a)
        mesh.AdvanceVertex()

        -- Add the second vertex (Tip Side)
        mesh.Position(pos2)
        mesh.TexCoord(0, 1, vCoord)
        -- CORRECTED: Unpack the Color object into R, G, B, A
        mesh.Color(trailColor.r, trailColor.g, trailColor.b, trailColor.a)
        mesh.AdvanceVertex()
    end

    mesh.End()
    -- mesh.Draw()
end
