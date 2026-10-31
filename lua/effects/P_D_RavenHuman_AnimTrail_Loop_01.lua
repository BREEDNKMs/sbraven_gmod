-- P_D_RavenHuman_AnimTrail_Loop_01 (Stellar Blade - Raven Human AnimTrail)
EFFECT.Mat = Material("sprites/mi_d_ravenhuman_animtraildefault_02")
EFFECT.SegmentLifetime = 0.4
EFFECT.Padding = Vector(32, 32, 32)

-- File-level reusable structures to eliminate GC garbage
local tempMatrix = Matrix()
local tempMins   = Vector()
local tempMaxs   = Vector()
local tempPos1   = Vector()
local tempPos2   = Vector()
local tempMid    = Vector()
local tempDir    = Vector()

function EFFECT:Init(data)
    self.Entity = data:GetEntity()
    self.Scale = data:GetScale() -- Lifetime duration from SBShowTrailKey
    self.DieTime = (self.Scale > 0) and (CurTime() + self.Scale) or -1

    self.TrailPoints = {}
    if not IsValid(self.Entity) then return end

    self:SetPos(self.Entity:GetPos())
    self:SetParent(self.Entity)

    -- Sword attachment offsets (grip vs tip)
    self.Attachment1 = 70 -- Grip offset along bone -Up
    self.Attachment2 = 9  -- Tip offset along bone -Up

    self.LastPos1 = Vector()
    self.LastPos2 = Vector()

    local pos1 = self:GetAttachmentPos(self.Attachment1)
    local pos2 = self:GetAttachmentPos(self.Attachment2)
    if pos1 and pos2 then
        self.LastPos1:Set(pos1)
        self.LastPos2:Set(pos2)
        self:AddSegment(pos1, pos2)
    end

    self:SetRenderBounds(Vector(-256, -256, -256), Vector(256, 256, 256))
end

function EFFECT:GetRenderEntity()
    local viewEnt = GetViewEntity()
    if not IsValid(viewEnt) or not viewEnt:IsPlayer() then 
        return self.Entity 
    end

    local activeWep = viewEnt:GetActiveWeapon()
    if not IsValid(activeWep) then 
        return self.Entity 
    end

    -- If locally held weapon in first-person, target viewmodel
    if self.Entity == activeWep and not viewEnt:ShouldDrawLocalPlayer() then 
        local vm = viewEnt:GetViewModel()
        if IsValid(vm) then
            return vm
        end
    end

    return self.Entity
end

function EFFECT:GetAttachmentPos(id)
    local renderEnt = self:GetRenderEntity()
    if not IsValid(renderEnt) then return end

    local handBone = renderEnt:LookupBone("ValveBiped.Bip01_R_Hand") or 0
    if not handBone or handBone < 0 then
        handBone = 0
    end

    -- Copy bone transform into temp matrix without heap allocations
    renderEnt:CopyBoneMatrix(handBone, tempMatrix)

    local pos = tempMatrix:GetTranslation()
    local up = tempMatrix:GetUp()
    up:Mul(id)
    pos:Sub(up)

    return pos
end

function EFFECT:AddSegment(pos1, pos2)
    table.insert(self.TrailPoints, 1, {
        pos1 = pos1,
        pos2 = pos2,
        timestamp = CurTime()
    })
end

function EFFECT:PruneSegments()
    local t = CurTime()
    local lifetime = self.SegmentLifetime
    for i = #self.TrailPoints, 1, -1 do
        if (t - self.TrailPoints[i].timestamp) > lifetime then
            table.remove(self.TrailPoints, i)
        end
    end
end

function EFFECT:UpdateRenderBounds()
    local count = #self.TrailPoints
    if count == 0 then return end

    local p1 = self.TrailPoints[1].pos1
    local minX, minY, minZ = p1.x, p1.y, p1.z
    local maxX, maxY, maxZ = p1.x, p1.y, p1.z

    for i = 1, count do
        local seg = self.TrailPoints[i]
        local s1 = seg.pos1
        local s2 = seg.pos2

        if s1.x < minX then minX = s1.x end
        if s1.y < minY then minY = s1.y end
        if s1.z < minZ then minZ = s1.z end
        if s1.x > maxX then maxX = s1.x end
        if s1.y > maxY then maxY = s1.y end
        if s1.z > maxZ then maxZ = s1.z end

        if s2.x < minX then minX = s2.x end
        if s2.y < minY then minY = s2.y end
        if s2.z < minZ then minZ = s2.z end
        if s2.x > maxX then maxX = s2.x end
        if s2.y > maxY then maxY = s2.y end
        if s2.z > maxZ then maxZ = s2.z end
    end

    tempMins:SetUnpacked(minX, minY, minZ)
    tempMaxs:SetUnpacked(maxX, maxY, maxZ)

    self:SetRenderBoundsWS(tempMins, tempMaxs, self.Padding)
end

function EFFECT:Think()
    local renderEnt = self:GetRenderEntity()
    if not IsValid(renderEnt) then return false end
    -- self:SetLocalPos(renderEnt:GetLocalPos())

    if self.DieTime > 0 and CurTime() > self.DieTime then
        return false
    end

    local pos1 = self:GetAttachmentPos(self.Attachment1)
    local pos2 = self:GetAttachmentPos(self.Attachment2)
    if not pos1 or not pos2 then return false end

    if renderEnt:GetNoDraw() then
        self.LastPos1:Set(pos1)
        self.LastPos2:Set(pos2)
        return true
    end

    -- Add segment when blade moves
    if not pos1:IsEqualTol(self.LastPos1, 0.1) or not pos2:IsEqualTol(self.LastPos2, 0.1) then
        self:AddSegment(pos1, pos2)
        self.LastPos1:Set(pos1)
        self.LastPos2:Set(pos2)
    end

    self:PruneSegments()
    self:UpdateRenderBounds()
    return true
end

-- Ribbon width tuning
EFFECT.WidthMultiplier = 1.0
EFFECT.WidthCurve = {
    {0.0, 1.0},
    {0.2, 1.1},
    {0.7, 0.7},
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
            return Lerp((t - aT) / range, aV, bV)
        end
    end
    return tbl[#tbl][2]
end

function EFFECT:Render()
	local sTable = self:GetTable() 
    local count = #sTable.TrailPoints
    if count < 2 then return end

    render.SetMaterial(sTable.Mat)
    mesh.Begin(MATERIAL_TRIANGLE_STRIP, count * 2)

    local now = CurTime()
    local lifetime = sTable.SegmentLifetime
    local widthMult = sTable.WidthMultiplier

    -- Render from oldest segment (tail) to newest (blade edge)
    for i = count, 1, -1 do
        local seg = sTable.TrailPoints[i]
        local lifeFrac = math.Clamp((now - seg.timestamp) / lifetime, 0, 1)

        -- 1. ColorScaleOverLife & AlphaScaleOverLife matching Stellar Blade JSON:
        -- Birth (0.0): White-hot 5x bloom core (R: 220, G: 255, B: 255)
        -- Mid-life: Radiant Cyan (R: 0, G: 178, B: 255)
        -- Dissolving: Deep Electric Blue (R: 0, G: 68, B: 255)
        local coreBoost = math.max(0, 1.0 - lifeFrac * 5.0) -- First 20% of life
        local r = math.min(255, coreBoost * 220)
        local g = math.min(255, Lerp(lifeFrac, 178, 68) + coreBoost * 77)
        local b = 255

        -- AlphaScaleOverLife: Solid opacity at blade, decaying smoothly to tail
        local alphaFrac = math.Clamp(1.0 - math.max(0, lifeFrac - 0.2) * 1.25, 0, 1)
        local a = alphaFrac * 255

        -- 2. Vertex calculations without heap allocations:
        tempPos1:Set(seg.pos1)
        tempPos2:Set(seg.pos2)

        local lifeMultiplier = SampleCurve(sTable.WidthCurve, lifeFrac)
        if widthMult ~= 1.0 or lifeMultiplier ~= 1.0 then
            -- tempDir = pos2 - pos1
            tempDir:Set(tempPos2)
            tempDir:Sub(tempPos1)

            local lenSqr = tempDir:LengthSqr()
            if lenSqr > 0.01 then
                local currentDist = math.sqrt(lenSqr)
                tempDir:Div(currentDist) -- Normalized direction

                -- tempMid = (pos1 + pos2) * 0.5
                tempMid:Set(tempPos1)
                tempMid:Add(tempPos2)
                tempMid:Mul(0.5)

                local halfWidth = currentDist * widthMult * lifeMultiplier * 0.5
                tempDir:Mul(halfWidth)

                tempPos1:Set(tempMid)
                tempPos1:Sub(tempDir)

                tempPos2:Set(tempMid)
                tempPos2:Add(tempDir)
            end
        end

        -- 3. UV Mapping for T_C_AnimTrail_02:
        -- U: 0 at fresh blade edge -> 1 at faded tail
        -- V: 0 at sword grip (Pos1) -> 1 at sword tip (Pos2)
        local uCoord = lifeFrac

        mesh.Position(tempPos1)
        mesh.TexCoord(0, uCoord, 0)
        mesh.Color(r, g, b, a)
        mesh.AdvanceVertex()

        mesh.Position(tempPos2)
        mesh.TexCoord(0, uCoord, 1)
        mesh.Color(r, g, b, a)
        mesh.AdvanceVertex()
    end

    mesh.End()
end