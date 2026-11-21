AddCSLuaFile() 

local className = string.GetFileFromFilename(ENT.Folder)
local charData = SB_CharacterTable[1].Rows[className]

local NPC = { 
	Name = "Unidentified Naytiba (Friend)", 
	Class = "m_ravenbeast", 
	Category = "Other", 
	Model = "models/stellarblade/ch_m_na_42.mdl", 
	KeyValues = { citizentype = 4, Numgrenades = 5, npcclass = CLASS_PLAYER } 
} 

list.Set( "NPC", "CH_M_NA_42", NPC ) 

NPC = { 
	Name = "Unidentified Naytiba (Enemy)", 
	Class = "m_ravenbeast", 
	Category = "Other", 
	Model = "models/stellarblade/ch_m_na_42.mdl", 
	KeyValues = { citizentype = 4, Numgrenades = 5, npcclass = CLASS_PORTAL_TURRET } 
} 

list.Set( "NPC", "CH_M_NA_42_enemy", NPC ) 

ENT.Base = "m_raven" 
ENT.Type 			= "ai" 
ENT.Spawnable = false 
ENT.AdminOnly = false 
ENT.PrintName		= "Unidentified Naytiba" 
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

ENT.bHasInnateMelee1 = false 
ENT.m_fMaxYawSpeed = 360 -- "RotateAnglePerSecond": 360.0, 
-- State & Behavior Registries

-- 4. Dynamic Asset Imports (Soundset & BehaviorTree)
if charData.OverrideCharacterSoundSet and charData.OverrideCharacterSoundSet ~= "" then
	local css = string.match(charData.OverrideCharacterSoundSet, "'(.-)'") or charData.OverrideCharacterSoundSet
	ENT.CharacterSoundSetPath = "data_static/SB/Content" .. string.StripExtension(string.sub(css, 6)) .. ".uasset"
else
	ENT.CharacterSoundSetPath = "data_static/SB/Content/Sound/SoundAsset/CharacterSoundset/CSS_MON_42_RavenBeast.uasset"
end

SB_CSS_MON_42_RavenBeast = SB_ImportUAsset(ENT.CharacterSoundSetPath) 

local BehaviorTreeRes = "data_static/SB/Content" .. string.sub(charData.BehaviorTreeRes, 6) .. ".uasset"
local BehaviorTreePointer = string.GetFileFromFilename(charData.BehaviorTreeRes) -- M_Raven_AI
local BehaviorTreePointer = "SB_"..BehaviorTreePointer -- SB_M_Raven_AI
ENT.BehaviorTreeRes = BehaviorTreeRes
local BehaviorTree = SB_ImportUAsset(BehaviorTreeRes) 
_G[BehaviorTreePointer] = BehaviorTree 
print(BehaviorTreePointer,ENT.BehaviorTreeRes,BehaviorTree)

function ENT:Draw(flags) 
	scripted_ents.GetStored("base_ai").t.Draw(self,flags) 
end 

function ENT:NPC_ShouldConductBehaviorTree() 
	-- stun 
	if self["ESBActorState::ActorState_BlockingBehavior"] then return false end 
	-- cricket always runs on behaviortree 
	if self:GetNPCState() == 0 then self:SetNPCState(1) end 
	-- self:NPC_MaintainActivity() 
	return true 
end 

function ENT:SBAI_GetAnimSet(act) 
	if act == ACT_IDLE then 
		return "Animation/Type_A/M_Clriket_TA1_P_Spawn01" 
	elseif act == ACT_IDLE_ANGRY then 
	
	end 
end 

-- Inside m_ravenbeast.lua
ENT.CollisionGroupBones = {
	["Collision_WeaponR"] = {
		"Bip001-R-UpperArm",
		"Bip001-R-Forearm",
		"Bip001-R-Hand",
		"Bip001-R-Finger13"
	},
	["Collision_WeaponL"] = {
		"Bip001-L-UpperArm",
		"Bip001-L-Forearm",
		"Bip001-L-Hand",
		"Bip001-L-Finger13"
	},
	["Collision_Weapon"] = {
		"Bip001-L-Forearm",
		"Bip001-L-Hand",
		"Bip001-L-Finger13",
		"Bip001-R-Forearm",
		"Bip001-R-Hand",
		"Bip001-R-Finger13"
	},
	["Collision_WeaponNoArm"] = {
		"Bip001-L-Hand",
		"Bip001-L-Finger13",
		"Bip001-R-Hand",
		"Bip001-R-Finger13"
	},
	["Collision_Head"] = {
		"Bip001-Head",
		"Bip001-Neck"
	}
}

-- ENT.CollisionGroupBones = {
	-- ["Collision_WeaponAndHandR"] = {
		-- "Bip001-R-UpperArm",
		-- "Bip001-R-Forearm",
		-- "Bip001-R-Hand",
		-- bWeapon = true -- Also expands the AABB to include self:GetActiveWeapon()
	-- }
-- }

-- ENT.CollisionGroupBones = {
	-- ["Collision_Tail"] = { 12, 13, 14 }, -- Direct hitbox IDs in hitboxSet 0
	-- ["Collision_Body"] = { 0, "Bip001-Spine2" } -- Mixed hitbox ID and bone name
-- }

-- sTable.CheckHitboxCollision(self, tableofhittargets, group): Checked first. Can return varargs (return "Bone1", "Bone2") or a table (return {"Bone1", "Bone2"}). If it returns nil, it moves to step 2.