AddCSLuaFile() 

local className = string.GetFileFromFilename(ENT.Folder)
local charData = SB_CharacterTable[1].Rows[className]

local NPC = { 
	Name = "Cricket Ground (Friend)", 
	Class = "m_clriketaground", 
	Category = "Other", 
	Model = "models/stellarblade/ch_m_na_03.mdl", 
	KeyValues = { citizentype = 4, Numgrenades = 5, npcclass = CLASS_PLAYER } 
} 

list.Set( "NPC", "CH_M_NA_03_ground", NPC ) 

NPC = { 
	Name = "Cricket Ground (Enemy)", 
	Class = "m_clriketaground", 
	Category = "Other", 
	Model = "models/stellarblade/ch_m_na_03.mdl", 
	KeyValues = { citizentype = 4, Numgrenades = 5, npcclass = CLASS_PORTAL_TURRET } 
} 

list.Set( "NPC", "CH_M_NA_03_ground_enemy", NPC ) 

ENT.Base = "m_raven" 
ENT.Type 			= "ai" 
ENT.Spawnable = false 
ENT.AdminOnly = false 
ENT.PrintName		= "Raven" 
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
ENT.SBAI_BlackBoard = { } 
ENT.SBAI_bInBackgroundTask = false 
ENT.SB_EffectAlias = { } 
ENT.SBAI_ActiveShow = { } 
ENT.SBAI_SkillTimers = { } 
-- State & Behavior Registries

-- 4. Dynamic Asset Imports (Soundset & BehaviorTree)
if charData.OverrideCharacterSoundSet and charData.OverrideCharacterSoundSet ~= "" then
	local css = string.match(charData.OverrideCharacterSoundSet, "'(.-)'") or charData.OverrideCharacterSoundSet
	ENT.CharacterSoundSetPath = "data_static/SB/Content" .. string.StripExtension(string.sub(css, 6)) .. ".uasset"
else
	ENT.CharacterSoundSetPath = "data_static/SB/Content/Sound/SoundAsset/CharacterSoundset/CSS_MON_03_ClriketA.uasset"
end
SB_CSS_MON_03_ClriketA = SB_ImportUAsset(ENT.CharacterSoundSetPath) 

local BehaviorTreeRes = "data_static/SB/Content" .. string.sub(charData.BehaviorTreeRes, 6) .. ".uasset"
local BehaviorTreePointer = string.GetFileFromFilename(charData.BehaviorTreeRes) -- M_Raven_AI
local BehaviorTreePointer = "SB_"..BehaviorTreePointer -- SB_M_Raven_AI
ENT.BehaviorTreeRes = BehaviorTreeRes
local BehaviorTree = SB_ImportUAsset(BehaviorTreeRes) 
_G[BehaviorTreePointer] = BehaviorTree 

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