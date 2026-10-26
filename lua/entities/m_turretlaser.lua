AddCSLuaFile() 

local className = string.GetFileFromFilename(ENT.Folder)
local charData = SB_CharacterTable[1].Rows[className]

local NPC = { 
	Name = "Turret Laser (Friend)", 
	Class = "m_turretlaser", 
	Category = "Other", 
	Model = "models/stellarblade/ch_m_na_27.mdl", 
	KeyValues = { citizentype = 4, Numgrenades = 5, npcclass = CLASS_PLAYER } 
} 

list.Set( "NPC", "CH_M_NA_27", NPC ) 

NPC = { 
	Name = "Turret Laser (Enemy)", 
	Class = "m_turretlaser", 
	Category = "Other", 
	Model = "models/stellarblade/ch_m_na_27.mdl", 
	KeyValues = { citizentype = 4, Numgrenades = 5, npcclass = CLASS_PORTAL_TURRET } 
} 

list.Set( "NPC", "CH_M_NA_27_enemy", NPC ) 

ENT.Base = "m_raven" 
ENT.Type 			= "ai" 
ENT.Spawnable = false 
ENT.AdminOnly = false 
ENT.PrintName		= "Turret Laser" 
ENT.Author			= "DevilHawk" 

-- Merge CharacterTable properties while protecting GMod engine fields
for k, v in pairs(charData) do
	if k ~= "Type" and k ~= "Base" then
		ENT[k] = v
	end
end
ENT.CharacterType = charData.Type
ENT.NPC_AlertSound	= "" 
ENT.NPC_IdleSound 	= "" 
ENT.NPC_GroupIdleSound 	= "" 
ENT.NPC_MeleeHitSound = "Unreali_Nali.MeleeHit" 
ENT.NPC_PainSound 	= "" 
ENT.vecBBoxMins = Vector(-32,-32,0) 
ENT.vecBBoxMaxs = Vector(32,32,100) 
ENT.bHasInnateMelee1 = true 
ENT.m_fMaxYawSpeed = 360 -- "RotateAnglePerSecond": 360.0, 
ENT.SBAI_BlackBoard = { } 
ENT.SBAI_bInBackgroundTask = false 
ENT.SB_EffectAlias = { } 
ENT.SBAI_ActiveShow = { } 
ENT.SBAI_SkillTimers = { } 
-- State & Behavior Registries
ENT.NPC_RangedProjectile = "ent_pk_rg_missile"

-- 4. Dynamic Asset Imports (Soundset & BehaviorTree)
if charData.OverrideCharacterSoundSet and charData.OverrideCharacterSoundSet ~= "" then
	local css = string.match(charData.OverrideCharacterSoundSet, "'(.-)'") or charData.OverrideCharacterSoundSet
	ENT.CharacterSoundSetPath = "data_static/SB/Content" .. string.StripExtension(string.sub(css, 6)) .. ".json"
else
	ENT.CharacterSoundSetPath = "data_static/SB/Content/Sound/SoundAsset/CharacterSoundset/CSS_MON_27_TurretLaser.json"
end
SB_ImportJSON(ENT.CharacterSoundSetPath) 

local BehaviorTreeRes = "data_static/SB/Content" .. string.sub(charData.BehaviorTreeRes, 6) .. ".json"
ENT.BehaviorTreeRes = BehaviorTreeRes
SB_ImportJSON(BehaviorTreeRes) 
ENT.SBAI_Debug = false 
function ENT:NPC_GetShootPos() return self:EyePos() end 

function ENT:Draw(flags) 
	scripted_ents.GetStored("base_ai").t.Draw(self,flags) 
end 

function ENT:NPC_ShouldConductBehaviorTree() 
	-- stun 
	if self["ESBActorState::ActorState_BlockingBehavior"] then return false end 
	if self:GetNPCState() == 0 then self:SetNPCState(1) end 
	-- self:NPC_MaintainActivity() 
	return true 
end 

function ENT:Think() 
	if CLIENT then return scripted_ents.GetStored("cycler_actor2").t.Think(self) 
	else 
		-- self:CapabilitiesRemove(CAP_TURN_HEAD) 
		if !bEnabled then return scripted_ents.GetStored("cycler_actor2").t.Think(self) end 
		-- ENT:Think() — smooth poseparameter interpolation to enemy
		local ft = FrameTime()
		local lerpSpeedYaw   = 60.0   -- larger = faster yaw response
		local lerpSpeedPitch = 80.0   -- larger = faster pitch response

		-- Poseparameter ranges (match your QC)
		local yawMin,  yawMax  = -179, 179
		local pitchMin, pitchMax = -90, 90

		-- Helper: clamp
		local function clamp(v, a, b) if v < a then return a end if v > b then return b end return v end

		-- Get current poseparameter values (fallback to 0)
		local curYaw   = self:GetPoseParameter("head_yaw")   or 0
		local curPitch = self:GetPoseParameter("head_pitch") or 0

		local desiredYaw, desiredPitch

		local enemy = self:GetEnemy()
		if IsValid(enemy) then
			-- target direction from our eye position to enemy eye position
			local eyePos = self:EyePos()
			local targetPos = enemy:EyePos() 
			local dir = (targetPos - eyePos)
			if dir:LengthSqr() <= 0 then
				desiredYaw, desiredPitch = curYaw, curPitch
			else
				local angWorld = dir:Angle() -- world-space angle to target
				-- convert to local relative angles by subtracting entity orientation
				local myAng = self:GetAngles()
				local relPitch = angWorld.p - myAng.p
				local relYaw   = angWorld.y - myAng.y

				-- normalize to -180..180
				relPitch = math.NormalizeAngle(relPitch)
				relYaw   = math.NormalizeAngle(relYaw)

				desiredYaw   = math.Clamp(-relYaw,  yawMin,  yawMax)
				desiredPitch = math.Clamp(relPitch, pitchMin, pitchMax) 
			end
		else
			-- No enemy: keep yaw as-is, slowly return pitch to 0
			desiredYaw   = curYaw
			desiredPitch = 0
		end

		-- Shortest-angle difference for yaw (use math.AngleDifference)
		local yawDiff = math.AngleDifference(desiredYaw, curYaw)
		local pitchDiff = desiredPitch - curPitch

		-- Interpolation factor (frame-rate independent)
		local tYaw   = math.Clamp(ft * lerpSpeedYaw,   0, 1)
		local tPitch = math.Clamp(ft * lerpSpeedPitch, 0, 1)

		local newYaw   = curYaw   + yawDiff   * tYaw
		local newPitch = curPitch + pitchDiff * tPitch

		-- Clamp final values to poseparameter ranges
		newYaw   = math.Clamp(newYaw,   yawMin,   yawMax)
		newPitch = math.Clamp(newPitch, pitchMin, pitchMax)

		-- Apply poseparameters
		self:SetPoseParameter("head_yaw",   newYaw)
		self:SetPoseParameter("head_pitch", newPitch)

    -- Next think
    -- self:NextThink(CurTime() + 0.01)
	return scripted_ents.GetStored("cycler_actor2").t.Think(self) 
	end 
end 