-- ns_parryblock_01 
-- Cache the material outside of the functions for performance
local RefractMat = Material("sprites/physg_glow1")

-- Clientside only

local BONE_NAMES = {
    "ValveBiped.Bip01_R_Hand",
    "ValveBiped.Bip01_R_Forearm",
    "ValveBiped.Bip01_R_UpperArm",
    "ValveBiped.Bip01_L_Hand",
    "ValveBiped.Bip01_L_Forearm",
    "ValveBiped.Bip01_L_UpperArm",
}

local ARM_SEGMENTS = {
    { "ValveBiped.Bip01_R_UpperArm", "ValveBiped.Bip01_R_Forearm" },
    { "ValveBiped.Bip01_R_Forearm",   "ValveBiped.Bip01_R_Hand" },
    { "ValveBiped.Bip01_L_UpperArm", "ValveBiped.Bip01_L_Forearm" },
    { "ValveBiped.Bip01_L_Forearm",   "ValveBiped.Bip01_L_Hand" },
}

local function SafeBonePos(ent, boneName)
    if not IsValid(ent) then return nil end
    if ent.SetupBones then ent:SetupBones() end

    local boneId = ent:LookupBone(boneName)
    if boneId == nil then return nil end

    local pos = ent:GetBonePosition(boneId)
    if isvector(pos) then return pos end

    local mat = ent:GetBoneMatrix(boneId)
    if mat then
        return mat:GetTranslation()
    end

    return nil
end

local function ClosestPointsOnSegments(p1, q1, p2, q2)
    local d1 = q1 - p1
    local d2 = q2 - p2
    local r  = p1 - p2

    local a = d1:Dot(d1)
    local e = d2:Dot(d2)
    local f = d2:Dot(r)

    local s, t

    if a <= 1e-8 and e <= 1e-8 then
        return p1, p2
    end

    if a <= 1e-8 then
        s = 0
        t = math.Clamp(f / e, 0, 1)
    else
        local c = d1:Dot(r)

        if e <= 1e-8 then
            t = 0
            s = math.Clamp(-c / a, 0, 1)
        else
            local b = d1:Dot(d2)
            local denom = a * e - b * b

            if denom ~= 0 then
                s = math.Clamp((b * f - c * e) / denom, 0, 1)
            else
                s = 0
            end

            local tnom = b * s + f

            if tnom < 0 then
                t = 0
                s = math.Clamp(-c / a, 0, 1)
            elseif tnom > e then
                t = 1
                s = math.Clamp((b - c) / a, 0, 1)
            else
                t = tnom / e
            end
        end
    end

    return p1 + d1 * s, p2 + d2 * t
end

local function GetRelevantBones(ent)
    local bones = {}
    for _, name in ipairs(BONE_NAMES) do
        bones[name] = SafeBonePos(ent, name)
    end
    return bones
end

local function BuildArmSegments(ent)
    local bones = GetRelevantBones(ent)
    local segs = {}

    for _, pair in ipairs(ARM_SEGMENTS) do
        local a = bones[pair[1]]
        local b = bones[pair[2]]
        if a and b then
            segs[#segs + 1] = { a = a, b = b, nameA = pair[1], nameB = pair[2] }
        end
    end

    return bones, segs
end

local function FindBestEntityInRadius(originEntity, radius)
    if not IsValid(originEntity) then return nil end

    local originPos = originEntity:GetPos()
    local forward = originEntity.GetForward and originEntity:GetForward() or originEntity:GetAngles():Forward()

    local bestEnt = nil
    local bestScore = nil

    for _, ent in ipairs(ents.FindInSphere(originPos, radius)) do
        if IsValid(ent) and ent ~= originEntity and not ent:IsWorld() then
            local center = ent.WorldSpaceCenter and ent:WorldSpaceCenter() or ent:GetPos()
            local delta = center - originPos
            local dist = delta:Length()

            if dist > 0 then
                local dir = delta / dist
                local dot = forward:Dot(dir)

                -- Lower score wins. Close objects win, but objects in front are favored.
                local score = dist - (dot * radius * 0.75)

                if bestScore == nil or score < bestScore then
                    bestScore = score
                    bestEnt = ent
                end
            end
        end
    end

    return bestEnt
end

local function ClosestPointFromBonePairs(ent1, ent2)
    local bones1 = GetRelevantBones(ent1)
    local bones2 = GetRelevantBones(ent2)

    local bestA, bestB
    local bestDistSqr

    for name, pos1 in pairs(bones1) do
        local pos2 = bones2[name]
        if pos1 and pos2 then
            local ds = pos1:DistToSqr(pos2)
            if not bestDistSqr or ds < bestDistSqr then
                bestDistSqr = ds
                bestA = pos1
                bestB = pos2
            end
        end
    end

    if bestA and bestB then
        return (bestA + bestB) * 0.5
    end

    return nil
end

local function ClosestPointFromCrossBones(ent1, ent2)
    local bones1 = GetRelevantBones(ent1)
    local bones2 = GetRelevantBones(ent2)

    local bestA, bestB
    local bestDistSqr

    for _, p1 in pairs(bones1) do
        if p1 then
            for _, p2 in pairs(bones2) do
                if p2 then
                    local ds = p1:DistToSqr(p2)
                    if not bestDistSqr or ds < bestDistSqr then
                        bestDistSqr = ds
                        bestA = p1
                        bestB = p2
                    end
                end
            end
        end
    end

    if bestA and bestB then
        return (bestA + bestB) * 0.5
    end

    return nil
end

local function ClosestPointFromArmSegments(ent1, ent2)
    local _, segs1 = BuildArmSegments(ent1)
    local _, segs2 = BuildArmSegments(ent2)

    local bestP1, bestP2
    local bestDistSqr

    for _, s1 in ipairs(segs1) do
        for _, s2 in ipairs(segs2) do
            local p1, p2 = ClosestPointsOnSegments(s1.a, s1.b, s2.a, s2.b)
            local ds = p1:DistToSqr(p2)

            if not bestDistSqr or ds < bestDistSqr then
                bestDistSqr = ds
                bestP1 = p1
                bestP2 = p2
            end
        end
    end

    if bestP1 and bestP2 then
        return (bestP1 + bestP2) * 0.5
    end

    return nil
end

local function GetHitboxCenters(ent)
    local centers = {}

    if not IsValid(ent) then return centers end
    if not ent.GetHitBoxCount then return centers end

    local hitboxSet = 0
    if ent.GetHitBoxSet then
        local okSet, setVal = pcall(ent.GetHitBoxSet, ent)
        if okSet and isnumber(setVal) then
            hitboxSet = setVal
        end
    end

    local okCount, count = pcall(ent.GetHitBoxCount, ent, hitboxSet)
    if not okCount or not isnumber(count) or count <= 0 then
        return centers
    end

    for i = 0, count - 1 do
        local bone = -1
        if ent.GetHitBoxBone then
            local okBone, boneVal = pcall(ent.GetHitBoxBone, ent, hitboxSet, i)
            if okBone and isnumber(boneVal) then
                bone = boneVal
            end
        end

        if bone >= 0 then
            local pos = ent:GetBonePosition(bone)
            if isvector(pos) then
                centers[#centers + 1] = pos
            end
        end
    end

    return centers
end

local function ClosestPointFromHitboxes(ent1, ent2)
    local h1 = GetHitboxCenters(ent1)
    local h2 = GetHitboxCenters(ent2)

    local bestA, bestB
    local bestDistSqr

    for _, p1 in ipairs(h1) do
        for _, p2 in ipairs(h2) do
            local ds = p1:DistToSqr(p2)
            if not bestDistSqr or ds < bestDistSqr then
                bestDistSqr = ds
                bestA = p1
                bestB = p2
            end
        end
    end

    if bestA and bestB then
        return (bestA + bestB) * 0.5
    end

    return nil
end

-- Main function:
-- Returns: targetEntity, closestPoint
function FindClosestForwardBoneOrHitboxPoint(originEntity)
    if not IsValid(originEntity) then
        return nil, vector_origin
    end

    local originPos = originEntity:GetPos()
    local targetEnt = FindBestEntityInRadius(originEntity, originEntity:BoundingRadius()*5)

    if not IsValid(targetEnt) then
        return nil, originPos
    end

    local point =
        ClosestPointFromArmSegments(originEntity, targetEnt) or
        ClosestPointFromBonePairs(originEntity, targetEnt) or
        ClosestPointFromCrossBones(originEntity, targetEnt) or
        ClosestPointFromHitboxes(originEntity, targetEnt) or
        originPos

    return targetEnt, point
end

function EFFECT:Init(data)
    -- Collect data from the effect data object
	-- at the moment, self:GetPos() is already data:GetOrigin() 
	-- print(self,data:GetEntity()) 
	self:SetOwner(data:GetEntity()) 
	local ent, pos = FindClosestForwardBoneOrHitboxPoint(data:GetEntity()) 
	self:SetPos(pos) 
    self.Scale = data:GetScale()
	self.Scale = self.Scale * 10 
    self.Lifetime = math.max(data:GetMagnitude(),0.2) 
	self.CreationTime = CurTime() 
	self.Emitter = ParticleEmitter(data:GetOrigin()) 
    -- Calculate the exact timestamp when this effect should die
    self.DieTime = CurTime() + self.Lifetime
	for i = 1, 200 do 
		local p = self.Emitter:Add("effects/spark", self:GetPos()) 
		if p then 
			p:SetDieTime(0.5)
			p:SetStartAlpha(255)
			p:SetEndAlpha(0)
			p:SetStartSize(5)
			p:SetEndSize(0)
			p:SetColor(255, math.random(100,200), 0)
			p:SetGravity(-vector_up*cvars.Number("sv_gravity")) 
			p:SetVelocity(VectorRand(-500,500)) 
			p:SetStartLength(0.1) 
			p:SetEndLength(0) 
			p:SetVelocityScale(true) 
		end 
	end 
end

function EFFECT:Think()
    -- Returning true keeps the effect alive, returning false removes it
	local remaining = self.DieTime - CurTime()
    local ratio = math.Clamp(remaining / self.Lifetime, 0, 1)
	self:SetModelScale(ratio*self.Scale) 
	
	if CurTime() > self.DieTime then 
		if self.Emitter and self.Emitter:IsValid() then 
			self.Emitter:Finish() 
		end 
		return false 
	end 
    return true 
end

function EFFECT:Render()
    -- Calculate remaining lifetime ratio (starts at 1.0, counts down to 0.0)
    local remaining = self.DieTime - CurTime()
    local ratio = math.Clamp(remaining / self.Lifetime, 0, 1)

    -- Linearly decrease $refractamount from 0.1 to 0 based on the lifetime ratio
    -- RefractMat:SetFloat("$refractamount", ratio * 0.01)

    -- Render the material as a 2D sprite facing the player's EyePos()
    render.SetMaterial(RefractMat) 
	for i = 1,3 do 
		render.DrawSprite(self:GetPos(), self:GetModelScale()*10, self:GetModelScale()*0.5, Color(255,93,0))
	end 
end