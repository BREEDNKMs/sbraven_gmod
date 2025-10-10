local tblWeapons = { "raven_blade" } 

player_manager.AddValidModel( "Raven", "models/alvaroports/SBRavenPM.mdl" ) 
player_manager.AddValidHands( "Raven", "models/alvaroports/SBRavenVM.mdl", 0, "0000000" ) 

local flRescale = 0.42 

local NPC = {
	Name = "Raven (Friend)",
	Class = "npc_sb_raven",
	Category = "Other",
	Weapons = tblWeapons,
	Model = "models/alvaroports/sbravenpm.mdl",
	KeyValues = { citizentype = 4, Numgrenades = 5, npcclass = 2 }
} 

list.Set( "NPC", "CH_M_NA_53", NPC ) 

NPC = {
	Name = "Raven (Enemy)",
	Class = "npc_sb_raven",
	Category = "Other",
	Weapons = tblWeapons,
	Model = "models/alvaroports/sbravenpm.mdl",
	KeyValues = { citizentype = 4, Numgrenades = 5, npcclass = 5 }
} 

list.Set( "NPC", "CH_M_NA_53_ent", NPC ) 

game.AddParticles( "particles/raven.pcf" ) 
PrecacheParticleSystem("ravencoreglow_2") 
PrecacheParticleSystem("ravencoreglow_4") 
PrecacheParticleSystem("ravencoreglow_8") 

--==============================================================================
-- HELPER: Quaternion to Angle Conversion
--==============================================================================
--[[
    Converts a quaternion from the JSON data into a Garry's Mod Angle.
    This function also handles the conversion from Unreal Engine's left-handed
    coordinate system to Source Engine's right-handed system. This is typically
    done by negating the Yaw and Roll.

    @param q A table representing the quaternion, e.g., {X=0, Y=0, Z=0, W=1}.
    @returns A GMod Angle object.
]]
local function QuaternionToAngle(q)
    if not q then return Angle(0, 0, 0) end

    local w, x, y, z = q.W, q.X, q.Y, q.Z

    -- Roll (x-axis rotation)
    local t0 = 2.0 * (w * x + y * z)
    local t1 = 1.0 - 2.0 * (x * x + y * y)
    local roll = math.atan2(t0, t1)

    -- Pitch (y-axis rotation)
    local t2 = 2.0 * (w * y - z * x)
    -- Clamp the value to the valid range for asin [-1, 1]
    t2 = math.max(-1.0, math.min(1.0, t2))
    local pitch = math.asin(t2)

    -- Yaw (z-axis rotation)
    local t3 = 2.0 * (w * z + x * y)
    local t4 = 1.0 - 2.0 * (y * y + z * z)
    local yaw = math.atan2(t3, t4)

    -- Convert radians to degrees and create the angle.
    -- Negate Yaw and Roll for Left-Handed (UE) to Right-Handed (Source) conversion.
    return Angle(math.deg(pitch), -math.deg(yaw), -math.deg(roll))
end

--==============================================================================
-- HELPER: Quaternion SLERP
--==============================================================================
-- Performs spherical linear interpolation between two quaternions.
-- q1, q2 are tables {X, Y, Z, W}
-- t is interpolation factor [0,1]
local function QuaternionSlerp(q1, q2, t)
    -- Compute dot product
    local dot = q1.X*q2.X + q1.Y*q2.Y + q1.Z*q2.Z + q1.W*q2.W

    -- If dot < 0, negate one quaternion to take the shortest path
    if dot < 0 then
        q2 = {X=-q2.X, Y=-q2.Y, Z=-q2.Z, W=-q2.W}
        dot = -dot
    end

    local theta0 = math.acos(math.min(dot,1)) -- angle between
    local sinTheta0 = math.sin(theta0)

    -- If very close, fall back to linear interpolation
    if sinTheta0 < 1e-6 then
        return {
            X = (1-t)*q1.X + t*q2.X,
            Y = (1-t)*q1.Y + t*q2.Y,
            Z = (1-t)*q1.Z + t*q2.Z,
            W = (1-t)*q1.W + t*q2.W
        }
    end

    local s1 = math.sin((1-t)*theta0) / sinTheta0
    local s2 = math.sin(t*theta0) / sinTheta0

    return {
        X = s1*q1.X + s2*q2.X,
        Y = s1*q1.Y + s2*q2.Y,
        Z = s1*q1.Z + s2*q2.Z,
        W = s1*q1.W + s2*q2.W
    }
end 

-- Map of SB InterpTypes to GMod math.ease functions
local EasingFunctions = {
    ["InterpType_Step"] = function(f) return f >= 1 and 1 or 0 end,
    ["InterpType_Liner"] = function(f) return f end,
    ["InterpType_SinOut"] = math.ease.OutSine,
    ["InterpType_SinIn"] = math.ease.InSine,
    ["InterpType_ExpoIn"] = math.ease.InExpo,
    ["InterpType_SinInOut"] = math.ease.InOutSine,
    ["InterpType_ExpoInOut"] = math.ease.InOutExpo,
    ["InterpType_ExpoOut"] = math.ease.OutExpo,
    ["InterpType_CircularOut"] = math.ease.OutCirc,
    ["InterpType_CircularIn"] = math.ease.InCirc,
    ["InterpType_EaseIn"] = math.ease.InQuad, -- Using Quad as a generic EaseIn
    ["InterpType_CircularInOut"] = math.ease.InOutCirc,
    ["InterpType_EaseInOut"] = math.ease.InOutQuad, -- Using Quad as a generic EaseInOut
    ["InterpType_EaseOut"] = math.ease.OutQuad -- Using Quad as a generic EaseOut
}


StellarBlade = { } 
StellarBlade = StellarBlade or {}

StellarBlade.TargetFilter = function(ent, filter)
    local TargetFilterTable = _G["SB_TargetFilterTable"][1].Rows[filter] 
	if !IsValid(ent) then error("Expected Entity, got NULL Entity!") return end 
	if !filter then print("input a filter") end 
    if !TargetFilterTable then return {ent:GetEnemy()} end

    -- Base vectors
    local origin = ent:GetPos() 
    local forward = ent:GetAimVector() 
	
	local ShapeForwardDistance = TargetFilterTable.ShapeForwardDistance * flRescale 
	local ShapeRightDistance = TargetFilterTable.ShapeRightDistance * flRescale 
	local ShapeUpDistance = TargetFilterTable.ShapeUpDistance * flRescale 
	
	local TargetCheckValue1 = TargetFilterTable.TargetCheckValue1 * flRescale 
	local TargetCheckValue2 = TargetFilterTable.TargetCheckValue2 * flRescale 
	local TargetCheckValue3 = TargetFilterTable.TargetCheckValue3 * flRescale 
	
	local FarDistance = TargetFilterTable.FarDistance * flRescale 
	local NearDistance = TargetFilterTable.NearDistance * flRescale 

    -- Shape offsets
    local offsetOrigin = origin
        + forward * (ShapeForwardDistance or 0)
        + ent:GetRight() * (ShapeRightDistance or 0)
        + ent:GetUp() * (ShapeUpDistance or 0)

    local candidates = {}

    -- Step 1: Candidate pool
    local shape = TargetFilterTable.TargetCheckShape or ""
    if shape == "ESBCheckShape::CheckShape_3DArc" then
        local range = FarDistance or 0
        local angle = math.max(0, math.min(TargetFilterTable.TargetCheckValue1 or 0, 180))
        local angle_cos = math.cos(math.rad(angle))
        candidates = ents.FindInCone(offsetOrigin, forward, range, angle_cos)
    elseif shape == "ESBCheckShape::CheckShape_3DCircle" then
        local radius = TargetCheckValue1 or (FarDistance or 0)
        candidates = ents.FindInSphere(offsetOrigin, radius)
	elseif shape == "ESBCheckShape::CheckShape_3DBox" then
		local val1 = TargetCheckValue1 or 0 -- half-size X (right)
		local val2 = TargetCheckValue2 or 0 -- half-size Y (forward)
		local val3 = TargetCheckValue3 or 0 -- half-size Z (up)

		-- Define the oriented box in world space
		local start = origin
		local endpos = origin + forward * (ShapeForwardDistance or 0)

		-- Define local AABB extents in actor’s local basis
		local localMins = Vector(-val1, -val2, -val3)
		local localMaxs = Vector(val1, val2, val3)

		-- Find entities within that oriented box
		candidates = ents.FindAlongRay(start, endpos, localMins, localMaxs) 
	else -- default action 
        candidates = ents.FindInPVS(ent)
    end

    -- Step 2: Filter out self
	-- expang this depending on Target type 
	--[[ 
	Target_None                              = 0,
	Target_Self                              = 1,
	Target_SpecifiedTargetes                 = 2,
	Target_Ally                              = 3, -- kamikaze NPCs 
	Target_AllyWithSelf                      = 4, -- only used by heal grenade 
	Target_Enemy                             = 5,
	Target_All                               = 6,
	Target_AllWithoutSelf                    = 7,
	Target_Owner                             = 8,
	Target_LockOn                            = 9,
	Target_AIDetectTarget                    = 10,
	Target_AIDetectSubTarget                 = 11,
	Target_MAX                               = 12,
	--]] 
	local TargetType = TargetFilterTable.TargetType 
    local filtered = {}
	
	if TargetType == "ESBTargetActor::Target_Self" then 
		filtered[1] = self 
	elseif TargetType == "ESBTargetActor::Target_Owner" then 
		filtered[1] = IsValid(self:GetOwner()) and self:GetOwner() 
	elseif TargetType == "ESBTargetActor::Target_All" then 
		for _, target in ipairs(candidates) do
			if IsValid(target) 
				and target:IsSolid()
				and target:GetCollisionGroup() != COLLISION_GROUP_NONE
				and !target:IsFlagSet(FL_DONTTOUCH)
				and target:Alive() 
			then
				table.insert(filtered, target)
			end
		end 
	else -- default action 
		for _, target in ipairs(candidates) do
			if IsValid(target)
				and target != ent
				and target:IsSolid()
				and target:GetCollisionGroup() != COLLISION_GROUP_NONE
				and !target:IsFlagSet(FL_DONTTOUCH)
				and target:Alive() 
			then
				-- print("candidates at step 2:",target) 
				table.insert(filtered, target)
			end
		end 
	end 

    -- Step 3: Distance check
    local nearDist = NearDistance or 0
    local farDist  = FarDistance or math.huge 
    local distFiltered = {}
    for _, target in ipairs(filtered) do
        local distSqr = offsetOrigin:DistToSqr(target:GetPos())
        if distSqr >= nearDist * nearDist and distSqr <= farDist * farDist then
            table.insert(distFiltered, target)
        end
    end
	-- print("past dist check") 

    -- Step 4: Shape checks (2D circle / 3D cylinder)
    local val1  = TargetCheckValue1 or 0
    local val2  = TargetCheckValue2 or 0
    local tmp = {}
	
	print("shape check is:",shape) 
	if shape == "ESBCheckShape::CheckShape_2DCircle" then
		local radius = TargetCheckValue1
		if radius == 0 or not radius then
			radius = FarDistance or 0
		end
		print("circle radius:",radius) 
		local radiusSqr = radius * radius
		local tmp = {}

		for _, target in ipairs(distFiltered) do
			local tpos = target:GetPos()
			local d2d = Vector(tpos.x, tpos.y, offsetOrigin.z):DistToSqr(offsetOrigin)
			if d2d <= radiusSqr then
				table.insert(tmp, target)
			end
		end
		distFiltered = tmp

    elseif shape == "ESBCheckShape::CheckShape_3DCylinder" then
		local radius = TargetCheckValue1
		if radius == 0 or not radius then
			radius = FarDistance or 0
		end
        local radiusSqr = radius * radius -- val1 * val1 
        for _, target in ipairs(distFiltered) do
            local tpos = target:GetPos()
            local horizDist = Vector(tpos.x, tpos.y, offsetOrigin.z):DistToSqr(offsetOrigin)
            local height = math.abs(tpos.z - offsetOrigin.z)
            if horizDist <= radiusSqr and (val2 == 0 or height <= val2) then
                table.insert(tmp, target)
            end
        end
        distFiltered = tmp
    end
	-- print("past custom filters:") 

    -- Step 4b: Line of sight check
    if not TargetFilterTable.bDisableBlockingCheck then
        local losFiltered = {}
        for _, candidate in ipairs(distFiltered) do
            local targetPos = TargetFilterTable.bBlockingCheckWithTopLocation
                and candidate:EyePos()
                or candidate:WorldSpaceCenter()

            local tr = util.TraceLine({
                start = ent:GetShootPos(),
                endpos = targetPos,
                filter = ent,
                collisiongroup = COLLISION_GROUP_PROJECTILE,
                mask = MASK_SHOT
            })
            if tr.Entity == candidate or tr.Fraction >= 1 then
                table.insert(losFiltered, candidate)
            end
        end
        distFiltered = losFiltered
    end

    -- Step 5: Sorting
    local sortType = TargetFilterTable.SortType
    if sortType == "ESBActorSortType::ActorSortType_Near" then
        table.sort(distFiltered, function(a, b)
            return offsetOrigin:DistToSqr(a:GetPos()) < offsetOrigin:DistToSqr(b:GetPos())
        end) 
	elseif sortType == "ESBActorSortType::ActorSortType_Far" then
        table.sort(distFiltered, function(a, b)
            return offsetOrigin:DistToSqr(a:GetPos()) > offsetOrigin:DistToSqr(b:GetPos())
        end)
	elseif sortType == "ESBActorSortType::ActorSortType_LowHp" then
        table.sort(distFiltered, function(a, b)
            return offsetOrigin:DistToSqr(a:Health()) < offsetOrigin:DistToSqr(b:Health())
        end)
	elseif sortType == "ESBActorSortType::ActorSortType_HighHp" then
        table.sort(distFiltered, function(a, b)
            return offsetOrigin:DistToSqr(a:Health()) > offsetOrigin:DistToSqr(b:Health())
        end)
    elseif sortType == "ESBActorSortType::ActorSortType_Parry" then
        table.sort(distFiltered, function(a, b)
            local aflag = a:IsFlagSet(FL_GODMODE)
            local bflag = b:IsFlagSet(FL_GODMODE)
            if aflag != bflag then return aflag end
            return offsetOrigin:DistToSqr(a:GetPos()) < offsetOrigin:DistToSqr(b:GetPos()) -- default to distance check 
        end)
    end
	
	-- print("multiple targets:",TargetFilterTable.bMultipleTargets) 
    -- Step 6: Multiple vs single target
    if TargetFilterTable.bMultipleTargets then
        return distFiltered
    elseif #distFiltered > 0 then
        return { distFiltered[1] }
    end

    return {}
end 

--[[
    Checks weapon collision for a given entity.
    Uses the active weapon’s collision bounds and the owner's right-hand bone
    to cast a rotated FindAlongRay.
    Only entities within the provided entityList are kept.
]]
StellarBlade.CheckWeaponCollision = function(owner, entityList)
    if not IsValid(owner) then return {} end

    local wep = owner:GetActiveWeapon()
    if not IsValid(wep) then return {} end

    local mins, maxs = wep:GetCollisionBounds()
    if not mins or not maxs then return {} end

    -- Get the right-hand bone transform
    local boneIndex = owner:LookupBone("ValveBiped.Bip01_R_Hand")
    if not boneIndex then return {} end

    local bonePos, boneAng = owner:GetBonePosition(boneIndex)
    if not bonePos or not boneAng then return {} end

    -- Base direction vectors
    local forward = boneAng:Forward()
    local right   = boneAng:Right()
    local up      = boneAng:Up()

    -- Extend ray roughly along the weapon’s forward axis
    local reach = maxs:Length() * 1.5
    local startPos = bonePos
    local endPos = bonePos + forward * reach

    -- Convert mins/maxs into world-space oriented bounding box corners
    -- by applying the bone’s rotation
    local worldMins, worldMaxs = LocalToWorld(mins, Angle(), vector_origin, boneAng)
    local worldMins2, worldMaxs2 = LocalToWorld(maxs, Angle(), vector_origin, boneAng)

    -- Because LocalToWorld rotates each vector around origin, we must find the
    -- actual numeric min/max bounds after rotation.
    local orientedMins = Vector(
        math.min(worldMins.x, worldMaxs.x, worldMins2.x, worldMaxs2.x),
        math.min(worldMins.y, worldMaxs.y, worldMins2.y, worldMaxs2.y),
        math.min(worldMins.z, worldMaxs.z, worldMins2.z, worldMaxs2.z)
    )
    local orientedMaxs = Vector(
        math.max(worldMins.x, worldMaxs.x, worldMins2.x, worldMaxs2.x),
        math.max(worldMins.y, worldMaxs.y, worldMins2.y, worldMaxs2.y),
        math.max(worldMins.z, worldMaxs.z, worldMins2.z, worldMaxs2.z)
    )

    -- Perform the oriented trace
    local hitEnts = ents.FindAlongRay(startPos, endPos, orientedMins, orientedMaxs)

    -- Filter to include only given entity list members
    local filtered = {}
    for _, ent in ipairs(hitEnts) do
        if IsValid(ent) and table.HasValue(entityList, ent) then
            table.insert(filtered, ent)
        end
    end

    -- Optional debug visualization
    -- debugoverlay.Line(startPos, endPos, 0.1, Color(255, 255, 0), false)
    -- debugoverlay.Box(startPos, orientedMins, orientedMaxs, 0.1, Color(255, 0, 0, 5))

    return filtered
end


--[[
    Checks whether a given entity’s specified hitbox collides with any entities in entityList.
    @param owner      (Entity) The entity whose hitbox will be checked.
    @param entityList (table)  List of entities to test against.
    @param hitboxID   (number|string) Hitbox index or bone name.
    @param hitboxSet  (number) Optional: hitbox set index (default = 0).
    @return table     List of entities intersecting this hitbox.
]]-- 
StellarBlade.CheckHitboxCollision = function(owner, entityList, hitboxID, hitboxSet)
    if not IsValid(owner) or not istable(entityList) then return {} end
    hitboxSet = hitboxSet or 0

    -- Convert bone name → hitbox ID if string was given
    if isstring(hitboxID) then
        local numHitBoxes = owner:GetHitBoxCount(hitboxSet)
        for i = 0, numHitBoxes - 1 do
            local boneIndex = owner:GetHitBoxBone(i, hitboxSet)
            local boneName = owner:GetBoneName(boneIndex)
            if boneName == hitboxID then
                hitboxID = i
                break
            end
        end
    end

    if not isnumber(hitboxID) then return {} end

    -- Fetch hitbox bounds in world space
    local mins, maxs = owner:GetHitBoxBounds(hitboxID, hitboxSet)
    if not mins or not maxs then return {} end

    -- Fetch hitbox orientation
    local boneIndex = owner:GetHitBoxBone(hitboxID, hitboxSet)
    if not boneIndex then return {} end

    local bonePos, boneAng = owner:GetBonePosition(boneIndex)
    if not bonePos or not boneAng then return {} end

    -- Optionally visualize the hitbox for debugging
    -- debugoverlay.BoxAngles(bonePos, mins, maxs, boneAng, 0.1, Color(0, 255, 0, 8))

    -- Build a list of entities intersecting this hitbox
    local collided = {}
    for _, target in ipairs(entityList) do
        if IsValid(target) and target ~= owner then
            -- Check a few sample points around the target’s bounding box
            local tmins, tmaxs = target:OBBMins(), target:OBBMaxs()
            local corners = {
                target:LocalToWorld(tmins),
                target:LocalToWorld(tmaxs),
                target:LocalToWorld(Vector(tmins.x, tmaxs.y, tmins.z)),
                target:LocalToWorld(Vector(tmaxs.x, tmins.y, tmaxs.z)),
                target:LocalToWorld(Vector(tmaxs.x, tmaxs.y, tmins.z)),
                target:LocalToWorld(Vector(tmins.x, tmins.y, tmaxs.z)),
                target:LocalToWorld(Vector(tmins.x, tmaxs.y, tmaxs.z)),
                target:LocalToWorld(Vector(tmaxs.x, tmins.y, tmins.z)),
            }

            -- If any corner is inside this hitbox’s OBB, we count it as a hit
            for _, point in ipairs(corners) do
                -- Fast built-in Garry's Mod OBB test
                if owner:IsPointInBounds(point) then
                    table.insert(collided, target)
                    break
                end
            end
        end
    end

    return collided
end


StellarBlade.IsInJustParry = function(ent) 
	--- START: Added Damage Check Logic ---

	local bDamageBlocked = false -- Initialize the variable to false.

	-- Check various conditions to see if damage was blocked or prevented.
	-- We set bDamageBlocked to true if ANY of these conditions are met.

	-- Condition 1: The ent is a player and the GM:PlayerShouldTakeDamage hook returns false.
	local playerHookBlocked = ent:IsPlayer() and hook.Run("GM:PlayerShouldTakeDamage", ent, self) == false
	local ai_block_damage = ent:IsNPC() and cvars.Bool("ai_block_damage") == false 

	-- Condition 2: The ent has God Mode enabled.
	local isGodMode = ent:IsFlagSet(FL_GODMODE)

	-- Condition 3: The ent's internal takedamage variable is set to 0 (DAMAGE_NO) or less.
	-- (or 1) is a safeguard in case the variable is missing, defaulting to DAMAGE_EVENTS_ONLY.
	local takeDamageDisabled = (ent:GetInternalVariable("m_takedamage") or 1) < 1

	if playerHookBlocked or isGodMode or takeDamageDisabled or ai_block_damage then
		bDamageBlocked = true
	end
	return bDamageBlocked 
end 

StellarBlade.SetSkillStep = function(self,strSkill) 
	local SkillStepTable = SB_SkillActiveStepTable[1].Rows[strSkill]
    if not SkillStepTable then
        self.SBAI_ActiveSkill = {} -- Clear active skill if the next step is invalid
        return
    end

    -- Store the current skill step's data
    self.SBAI_ActiveSkill = { Name = strSkill, Time = CurTime(), Data = SkillStepTable }

    -- [NEW] Handle `bRetargeting`: Lock onto the current target if false
    if SkillStepTable.bRetargeting == false and self.GetEnemy then
        self.SBAI_ActiveSkill.LockedTarget = self:GetEnemy()
    else
        -- If retargeting is allowed, ensure no previous target is locked
        self.SBAI_ActiveSkill.LockedTarget = nil
    end

    -- [NEW] Handle `StopSelfMove`: Stop the NPC from moving if true
    if SkillStepTable.StopSelfMove and self.StopMoving then
        self:StopMoving(true)
        self:ClearGoal()
    end

    -- [NEW] Handle initial `bLookAtTarget`: Turn to face the target at the start of the step
    if SkillStepTable.bLookAtTarget and self.SetIdealYawAndUpdate then
        local target = self.SBAI_ActiveSkill.LockedTarget or self:GetEnemy()
        if IsValid(target) then
            local angleToTarget = (target:GetPos() - self:GetPos()):Angle().y
            self:SetIdealYawAndUpdate(angleToTarget, -1) -- -1 for automatic turn speed
        end
    end

    -- Apply the animation/movement for this step
    local SelfMoveAliasArray = SkillStepTable.SelfMoveAliasArray
    for _, SelfMoveAlias in pairs(SelfMoveAliasArray) do
        StellarBlade.SetMoveTable(self,SelfMoveAlias)
    end
	-- activate TargetMoveAliasArray on target 
	
	-- activate ShowPath "ShowPath": "CH_M_NA_53_Raven/Skill/M_Raven_Slash", 
	if SkillStepTable.ShowPath != "None" then 
		local showpath = "addons/sbraven/data_static/SB/Content/Art/Show/" 
		showpath = showpath..SkillStepTable.ShowPath..".json" 
		self:SBAI_SetShow(showpath) 
	end 
	if #SkillStepTable.UsableTargetProjectileAliasArray > 0 then 
		for i = 1,#SkillStepTable.UsableTargetProjectileAliasArray do 
			local event,etime,cycle,types,options 
			if self.NPC_RangedAttack then 
				self:NPC_RangedAttack(event,etime,cycle,types,options) 
			else 
				scripted_ents.Get("npc_unreali_female").NPC_RangedAttack(self,event,etime,cycle,types,options) 
			end 
		end 
	end 
end 

--==============================================================================
-- HELPER: Curve Loading and Evaluation
--==============================================================================
--[[
    Loads a CurveFloat JSON file by parsing the specific path format from the move tables.
    @param curveDataPath The raw path string from the CharacterMoveTable.
]]
StellarBlade.LoadCurveData = function(curveDataPath)
    if not curveDataPath or curveDataPath == "None" then return end

    -- Extract the path between the single quotes, e.g., /Game/GameDesign/...
    local extractedPath = string.match(curveDataPath, "'(.-)'")
    if not extractedPath then return end

    -- Strip the duplicate object name at the end, which acts like an extension.
	extractedPath = string.sub(extractedPath,6) 
    extractedPath = string.StripExtension(extractedPath)

    -- Construct the final file path.
    local finalPath = "addons/sbraven/data_static/SB/Content" .. extractedPath .. ".json"

    -- This external function is expected to load the JSON into a global table.
    SB_ImportJSON(finalPath)
end

StellarBlade.SetMoveTable = function(self,strEffect)
    if not SB_CharacterMoveTable or not SB_CharacterMoveTable[1] or not SB_CharacterMoveTable[1].Rows then
        print("ERROR: SB_CharacterMoveTable is not available.")
        return false
    end

    local CharacterMoveTable = SB_CharacterMoveTable[1].Rows[strEffect]
    if not CharacterMoveTable then
        print("no move table", strEffect)
        return false
    end

    if not self.SBAI_MoveStep then
        self.SBAI_MoveStep = {}
    end

    local newMoveStep = {
        ["MoveArrayName"] = strEffect,
        ["StartTime"] = CurTime() + (CharacterMoveTable.StartDelayTime or 0), 
        ["RunTime"] = CurTime() 
    }
    table.insert(self.SBAI_MoveStep, newMoveStep)

    if CharacterMoveTable.RootMotionDataPath and CharacterMoveTable.RootMotionDataPath ~= "None" then
        local RootMotionDataPath = string.sub(CharacterMoveTable.RootMotionDataPath, 6)
        RootMotionDataPath = "addons/sbraven/data_static/SB/Content" .. RootMotionDataPath .. ".json"
        SB_ImportJSON(RootMotionDataPath)
    end
    if CharacterMoveTable.PositionInterpCurveDataPath and CharacterMoveTable.PositionInterpCurveDataPath != "None" then
        StellarBlade.LoadCurveData(CharacterMoveTable.PositionInterpCurveDataPath)
    end
    if CharacterMoveTable.StaticMoveZVAlueCurveDataPath and CharacterMoveTable.StaticMoveZVAlueCurveDataPath != "None" then
        StellarBlade.LoadCurveData(CharacterMoveTable.StaticMoveZVAlueCurveDataPath)
    end
    if CharacterMoveTable.MoveOffsetCurveDataPath and CharacterMoveTable.MoveOffsetCurveDataPath != "None" then
        StellarBlade.LoadCurveData(CharacterMoveTable.MoveOffsetCurveDataPath)
    end
    if CharacterMoveTable.RotationInterpCurveDataPath and CharacterMoveTable.RotationInterpCurveDataPath != "None" then
        StellarBlade.LoadCurveData(CharacterMoveTable.RotationInterpCurveDataPath)
    end

    return true
end 

StellarBlade.ShouldCancelMoveTable = function(self,moveStep) 
    if not moveStep then return false end
    local name = moveStep.MoveArrayName 
    local CharacterMoveTable = SB_CharacterMoveTable[1].Rows[name] 
	if self.GetEnemy then 
		if CharacterMoveTable.bStopWhenInvalidTarget and not IsValid(self:GetEnemy()) then 
			return true 
		end
	end 
	if self.IsGoalActive then 
		if CharacterMoveTable.bStopWhenInvalidNavigation and not self:IsGoalActive() then 
			return true 
		end 
	end 
    return false 
end 

StellarBlade.MaintainMoveTable = function(self) -- adapt this to work between all entities, including players and npcs 
    if self.SBAI_MoveStep and #self.SBAI_MoveStep > 0 then
        local currentAng = self:GetLocalAngles()
        local totalAngDelta = Angle(0, 0, 0)

        -- Iterate backwards for safe removal
        for i = #self.SBAI_MoveStep, 1, -1 do
            local moveStep = self.SBAI_MoveStep[i]
			
			local flInterval = CurTime() - moveStep.RunTime 
			moveStep.RunTime = CurTime() 
			
            if CurTime() < moveStep.StartTime then continue end

            local name = moveStep.MoveArrayName
            local CharacterMoveTable = SB_CharacterMoveTable[1].Rows[name] -- get precached movetable 
            local Time = CharacterMoveTable.Time
            local CurEndTime = moveStep.StartTime + Time
            
            local moveStartTime = CharacterMoveTable.MoveStartTime or 0
            local moveEndTime = CharacterMoveTable.MoveEndTime or Time
            local moveDuration = moveEndTime - moveStartTime
            
            local normalizedTime, prevNormalizedTime = 0, 0
            if moveDuration > 0 then
                local elapsedTime = CurTime() - moveStep.StartTime
                normalizedTime = math.Clamp((elapsedTime - moveStartTime) / moveDuration, 0, 1)
                prevNormalizedTime = math.Clamp(((elapsedTime - flInterval) - moveStartTime) / moveDuration, 0, 1)
            end
            
            local interpType = CharacterMoveTable.PositionInterpType
            local easedNow = StellarBlade.GetEasedFraction(interpType, normalizedTime)
            local easedPrev = StellarBlade.GetEasedFraction(interpType, prevNormalizedTime)

            local movePosDelta = Vector(0, 0, 0)
            local moveAngDelta = Angle(0, 0, 0)
            local MoveType = CharacterMoveTable.MoveType
			local directionAxis = CharacterMoveTable.PositionDirectionAxis 
			local vecMoveDirection = self:GetAimVector() 
			local enemy = self.GetEnemy and self:GetEnemy() 
			if !self.GetEnemy then 
				enemy = scripted_ents.Get("proj_unreali_skaarjprojectile").PickTarget(self,0, 9999, self:GetAimVector(), self:GetShootPos()) 
			end 
			if !IsValid(enemy) then 
				enemy = Entity(0) 
			end 
			if directionAxis == "ESBMoveDirectionAxis::MoveDirectionAxis_Self" then 
			elseif directionAxis == "ESBMoveDirectionAxis::MoveDirectionAxis_Target" then 
				vecMoveDirection = enemy:GetAimVector() 
			elseif directionAxis == "ESBMoveDirectionAxis::MoveDirectionAxis_SelfToTarget" then 
				vecMoveDirection = (enemy:GetPos() - self:GetPos()):GetNormalized() 
			elseif directionAxis == "ESBMoveDirectionAxis::MoveDirectionAxis_InputDirectionWorld" then -- relative to DefaultInputDirection, for player takedamage 
				vecMoveDirection = self:GetForward()  
			elseif directionAxis == "ESBMoveDirectionAxis::MoveDirectionAxis_InputDirectionLocal" then -- unused 
			elseif directionAxis == "ESBMoveDirectionAxis::MoveDirectionAxis_HitDirection" then -- unused 
			elseif directionAxis == "ESBMoveDirectionAxis::MoveDirectionAxis_Velocity" then -- used by Eve swimming 
			elseif directionAxis == "ESBMoveDirectionAxis::MoveDirectionAxis_Velocity2D" then -- unused 
			elseif directionAxis == "ESBMoveDirectionAxis::MoveDirectionAxis_SelfToTarget2D" then 
				local enemyPos = enemy:GetPos() enemyPos.z = 0 
				local selfPos = self:GetPos() selfPos.z = 0 
				vecMoveDirection = (enemyPos - selfPos):GetNormalized() 
			elseif directionAxis == "ESBMoveDirectionAxis::MoveDirectionAxis_InputDirectionWorldWithoutZ" then -- relative to DefaultInputDirection, for player takedamage 
			
			end 

            if MoveType == "ESBMoveTransformType::MoveTransformType_RootMotion" then
				-- print("root motion") 
                local RootMotionDataPath = string.StripExtension(string.GetFileFromFilename(CharacterMoveTable.RootMotionDataPath))
                local RootMotion = _G["SB_" .. RootMotionDataPath]
                if RootMotion then
                    local posOffset, angOffset = StellarBlade.GetRootMotionTransform(RootMotion, moveStep.StartTime)
                    if posOffset and angOffset then
                        if not moveStep.PrevPosOffset then
                            moveStep.PrevPosOffset = Vector(0, 0, 0)
                            moveStep.PrevAngOffset = Angle(0, 0, 0)
                        end
                        local posDelta = posOffset - moveStep.PrevPosOffset
                        moveAngDelta = angOffset - moveStep.PrevAngOffset
                        -- movePosDelta = directionAngle:Forward() * posDelta.x + directionAngle:Right() * posDelta.y + directionAngle:Up() * posDelta.z
						-- print(vecMoveDirection) 
						-- posDelta = posDelta * flRescale -- rescale to approximate hammer units 
						movePosDelta = vecMoveDirection * posDelta.x + vecMoveDirection:Cross(Vector(0,0,-1)) * posDelta.y + vecMoveDirection:Cross(Vector(0,1,0)) * posDelta.z 
						-- movePosDelta = vecMoveDirection * posDelta 
                        moveStep.PrevPosOffset = posOffset
                        moveStep.PrevAngOffset = angOffset
                    end
                end
				-- movePosDelta = movePosDelta * (easedNow - easedPrev) -- is the RootMotion influenced from interptype? 
            elseif MoveType == "ESBMoveTransformType::MoveTransformType_Static" then
				if CharacterMoveTable.PositionType == "ESBMovePositionType::MovePositionType_TargetSocket" then -- TargetSocket used only by eve, static 
                    local target = IsValid(self:GetEnemy()) and self:GetEnemy() or Entity(1) 
                    movePosDelta = target:WorldSpaceCenter() - self:GetPos()
                else
                    -- if not moveStep.MoveDir then
                        -- local directionAxis = CharacterMoveTable.PositionDirectionAxis
                        -- if directionAxis == "ESBMoveDirectionAxis::MoveDirectionAxis_SelfToTarget" and IsValid(enemy) then
                            -- moveStep.MoveDir = (enemy:GetPos() - self:GetPos()):GetNormalized()
                        -- else
                            -- moveStep.MoveDir = currentAng:Forward()
                        -- end
                    -- end
					
                    local rightDir = vecMoveDirection:Cross(Vector(0, 0, 1)):GetNormalized()
                    local forwardMove = CharacterMoveTable.ForwardValue or 0
                    local rightMove = CharacterMoveTable.RightValue or 0
                    local upMove = CharacterMoveTable.UpValue or 0
                    local posCurvePath = CharacterMoveTable.PositionInterpCurveDataPath
                    local zCurvePath = CharacterMoveTable.StaticMoveZVAlueCurveDataPath
                    if (posCurvePath and posCurvePath != "None") or (zCurvePath and zCurvePath != "None") then
                        local posMultiplier, prevPosMultiplier, zMultiplier, prevZMultiplier = 1, 1, 1, 1
                        if posCurvePath and posCurvePath != "None" then
                            local curveName = string.StripExtension(string.GetFileFromFilename(string.match(posCurvePath, "'(.-)'")))
                            posMultiplier = StellarBlade.ApplyCurveFloat(curveName, normalizedTime)
                            prevPosMultiplier = StellarBlade.ApplyCurveFloat(curveName, prevNormalizedTime)
                        end
                        if zCurvePath and zCurvePath != "None" then
                           local curveName = string.StripExtension(string.GetFileFromFilename(string.match(zCurvePath, "'(.-)'")))
                            zMultiplier = StellarBlade.ApplyCurveFloat(curveName, normalizedTime)
                            prevZMultiplier = StellarBlade.ApplyCurveFloat(curveName, prevNormalizedTime)
                        end
                        local totalOffset = (vecMoveDirection * forwardMove + rightDir * rightMove)
                        local curvePosDelta = totalOffset * (posMultiplier - prevPosMultiplier)
                        local zDelta = Vector(0, 0, upMove * (zMultiplier - prevZMultiplier))
                        movePosDelta = curvePosDelta + zDelta
						-- movePosDelta = movePosDelta * (easedNow - easedPrev) 
                    else
                        local totalDisplacement = (vecMoveDirection * forwardMove) + (rightDir * rightMove) + (Vector(0,0,1) * upMove)
                        movePosDelta = totalDisplacement * (easedNow - easedPrev)
                    end
					-- movePosDelta = movePosDelta * flRescale 
                end
            elseif MoveType == "ESBMoveTransformType::MoveTransformType_LocalAxis" then
                local forwardMove = CharacterMoveTable.ForwardValue or 0
                local rightMove = CharacterMoveTable.RightValue or 0
                local upMove = CharacterMoveTable.UpValue or 0
                local totalLocalDisplacement = Vector(forwardMove, rightMove, upMove)
                local localDisplacementDelta = totalLocalDisplacement * (easedNow - easedPrev) 
                movePosDelta = vecMoveDirection * localDisplacementDelta.x + vecMoveDirection:Cross(Vector(0,0,-1)) * localDisplacementDelta.y + vecMoveDirection:Cross(Vector(0,1,0)) * localDisplacementDelta.z
            elseif MoveType == "ESBMoveTransformType::MoveTransformType_WorldLocation" then 
				local targetPos = Vector(CharacterMoveTable.ForwardValue,CharacterMoveTable.RightValue,CharacterMoveTable.UpValue) 
				movePosDelta = movePosDelta * (easedNow - easedPrev) 
				movePosDelta = targetPos -- lerp to targetPos using PositionInterpType 
			elseif MoveType == "ESBMoveTransformType::MoveTransformType_None" then 
			elseif MoveType == "ESBMoveTransformType::MoveTransformType_LinkTo" then -- link to attachment, used 
			elseif MoveType == "ESBMoveTransformType::MoveTransformType_LinkTo_Velocity" then -- unused 
			elseif MoveType == "ESBMoveTransformType::MoveTransformType_LinkFrom" then -- used 
			elseif MoveType == "ESBMoveTransformType::MoveTransformType_ZeroVelocity" then -- stop velocity, used only once 
			elseif MoveType == "ESBMoveTransformType::MoveTransformType_Airborne" then 
			elseif MoveType == "ESBMoveTransformType::MoveTransformType_Fly" then 
			elseif MoveType == "ESBMoveTransformType::MoveTransformType_Fall" then 
			elseif MoveType == "ESBMoveTransformType::MoveTransformType_TargetAround" then 
			elseif MoveType == "ESBMoveTransformType::MoveTransformType_PathWay" then 
			elseif MoveType == "ESBMoveTransformType::MoveTransformType_SwimmingDash" then 
			end 
			-- movePosDelta = movePosDelta * (easedNow - easedPrev)
			-- print(easedNow,easedPrev) 
			movePosDelta = movePosDelta * flRescale 
			-- print(movePosDelta) 

            -- Apply this move's delta and check for collision failure
            local collisionFailed = false
            if movePosDelta:LengthSqr() > 0.001 then
                local moveSuccess = true
                local targetPosForThisMove = self:GetPos() + movePosDelta

                if CharacterMoveTable.bOnGround and self.MoveGroundStep then 
                    if self:MoveGroundStep(targetPosForThisMove) == 0 then moveSuccess = false end 
                else 
                    local moveResult = IterativeHybridMoveLimit(self, self:GetPos(), targetPosForThisMove)
                    self:SetLocalPos(moveResult.vEndPosition)
                    if moveResult.fStatus != "OK" then moveSuccess = false end
                end

                if not moveSuccess and CharacterMoveTable.bStopWhenCollision then
                    print("removing motion due to collision for", name)
                    table.remove(self.SBAI_MoveStep, i)
                    collisionFailed = true
                end
            end

            -- Only process expiration and add angle delta if the move wasn't removed for collision
            if not collisionFailed then
                totalAngDelta = totalAngDelta + moveAngDelta
                
                if CurTime() > CurEndTime or StellarBlade.ShouldCancelMoveTable(self,moveStep) then
                    if CharacterMoveTable.bZeroVelocityWhenEnd then
                        self:SetLocalVelocity(Vector(0,0,0))
                    end
                    table.remove(self.SBAI_MoveStep, i)
                end
            end
        end

        -- Apply total accumulated angle delta at the end
        local targetAng = currentAng + totalAngDelta
        if targetAng != currentAng then
            self:SetLocalAngles(targetAng)
        end
    end
end 

--[[
    Calculates a value from a loaded CurveFloat table based on a normalized time.
    Handles both Linear and Cubic interpolation between keys.
    @param curveName The name of the curve, e.g., "M_Sawshark_DoubleSwingSaw_Curve".
    @param normalizedTime A value between 0.0 and 1.0 representing the progress.
    @returns The calculated float value from the curve.
]]-- 

StellarBlade.ApplyCurveFloat = function(curveName, normalizedTime)
    local curveTable = _G["SB_" .. curveName]
    if not curveTable or not curveTable[1] or not curveTable[1].Properties or not curveTable[1].Properties.FloatCurve then
		print("curveTable not found") 
        return 0
    end

    local keys = curveTable[1].Properties.FloatCurve.Keys
    if not keys or #keys == 0 then return 0 end

    -- If there's only one key, return its value.
    if #keys == 1 then return keys[1].Value end

    -- Clamp the time to be within the curve's bounds.
    normalizedTime = math.Clamp(normalizedTime, keys[1].Time, keys[#keys].Time)

    -- Find the two keys to interpolate between.
    local key1, key2
    for i = 1, #keys - 1 do
        if normalizedTime >= keys[i].Time and normalizedTime <= keys[i + 1].Time then
            key1 = keys[i]
            key2 = keys[i + 1]
            break
        end
    end

    if not key1 or not key2 then return keys[#keys].Value end
    if key1.Time == key2.Time then return key1.Value end

    -- Calculate the alpha for interpolation between the two keys.
    local alpha = (normalizedTime - key1.Time) / (key2.Time - key1.Time)

    if key1.InterpMode == "RCIM_Constant" or key1.InterpMode == "RCIM_None" then
        -- Constant/None interpolation holds the value of the first key.
        return key1.Value
    elseif key1.InterpMode == "RCIM_Linear" then
        return Lerp(alpha, key1.Value, key2.Value)
    elseif key1.InterpMode == "RCIM_Cubic" then
        local t, t2, t3 = alpha, alpha * alpha, alpha * alpha * alpha
        local p0, p1 = key1.Value, key2.Value

        -- Tangents must be scaled by the time difference between the keys.
        local timeDiff = key2.Time - key1.Time
        local m0 = key1.LeaveTangent * timeDiff
        local m1 = key2.ArriveTangent * timeDiff

        -- Cubic Hermite spline interpolation formula.
        local h00 = 2 * t3 - 3 * t2 + 1
        local h10 = t3 - 2 * t2 + t
        local h01 = -2 * t3 + 3 * t2
        local h11 = t3 - t2

        return h00 * p0 + h10 * m0 + h01 * p1 + h11 * m1
    else
        -- Default to linear interpolation if the mode is unknown.
        return Lerp(alpha, key1.Value, key2.Value)
    end
end
--[[
    Converts a linear fraction (0-1) into an eased fraction based on the interp type.
    @param interpType The string identifier from the move table.
    @param fraction The linear progress, typically normalizedTime.
    @returns The eased progress.
]]
StellarBlade.GetEasedFraction = function(interpType, fraction)
    if !interpType then return fraction end
    local key = interpType:gsub("ESBInterpType::", "")
    local easeFunc = EasingFunctions[key] or EasingFunctions["InterpType_Liner"]
    return easeFunc(fraction)
end 

--==============================================================================
-- CORE: Get Interpolated Root Motion Transform
--==============================================================================
--[[
    Parses the root motion data to get the interpolated transform at a specific time.
    It calculates the current frame based on elapsed time and interpolates between
    the two nearest keyframes to ensure smooth movement.

    @param rootMotionTable The imported JSON table for the animation.
    @param startTime The CurTime() when the animation started.
    @returns Vector positionOffset, Angle angleOffset, or nil if data is invalid.
]]-- 
StellarBlade.GetRootMotionTransform = function(rootMotionTable, startTime)
    -- Ensure the root motion table is valid.
    if not rootMotionTable or not rootMotionTable[1] or not rootMotionTable[1].Properties then
        return nil, nil
    end

    local frameRate = rootMotionTable[1].Properties.FrameRate or 30

    local dataArray = rootMotionTable[1].Properties.RootMotionDataArray
    if not dataArray or not dataArray[1] then return nil, nil end

    local transformArray = dataArray[1].TransformArray
    if not transformArray or #transformArray == 0 then return nil, nil end

    local elapsedTime = CurTime() - startTime

    -- Calculate which frame we are on (can be a float).
    local currentFrame = elapsedTime * frameRate
    local frameCount = #transformArray

    -- Determine the two keyframes to interpolate between.
    local frame1_idx = math.floor(currentFrame) + 1
    local frame2_idx = frame1_idx + 1

    -- Prevent indexing out of bounds.
    if frame1_idx > frameCount then frame1_idx = frameCount end
    if frame2_idx > frameCount then frame2_idx = frameCount end

    -- Get the transform data for both frames.
    local transform1 = transformArray[frame1_idx]
    local transform2 = transformArray[frame2_idx]

    if not transform1 or not transform2 then return nil, nil end

    -- Calculate the interpolation alpha (0.0 to 1.0).
    local alpha = currentFrame - (frame1_idx - 1)
    alpha = math.Clamp(alpha, 0, 1)

    -- Extract and interpolate position (Translation).
    -- We negate the Y value to convert from UE's Left-Handed to Source's Right-Handed coordinates.
    local pos1 = Vector(transform1.Translation.X, -transform1.Translation.Y, transform1.Translation.Z)
    local pos2 = Vector(transform2.Translation.X, -transform2.Translation.Y, transform2.Translation.Z)
    local interpolatedPos = LerpVector(alpha, pos1, pos2)

       -- Rotation interpolation (now with quaternion slerp)
    local q1 = transform1.Rotation
    local q2 = transform2.Rotation
    local qInterp = QuaternionSlerp(q1, q2, alpha)

    -- Convert final quaternion to Angle once
    local interpolatedAngle = QuaternionToAngle(qInterp)

    return interpolatedPos, interpolatedAngle
end 

StellarBlade.ClearMoveTable = function(self) self.SBAI_MoveStep = { } end 

hook.Add("Think","SB_MaintainMoveTable", function() 
	for _,ent in ents.Iterator() do 
		StellarBlade.MaintainMoveTable(ent) 
	end 
end) 
