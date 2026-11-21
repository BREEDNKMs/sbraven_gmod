AddCSLuaFile() 
local meta = FindMetaTable("Entity")
if !meta then timer.Simple(5,function() Entity(1):ChatPrint("FindMetaTable('Entity)' appears to be nil") end) end 
local fGetTable = meta.GetTable 

-- local M_Raven_Default = "data_static/SB/Content/Local/Data/CharacterStanceTable.json" 
-- SB_ImportJSON(M_Raven_Default) 
M_Raven_Default = SB_CharacterStanceTable[1].Rows.M_Raven_Default 
if !table.HasValue(M_Raven_Default.CommandArray,"M_Raven_ChaseChargeSlash") then 
	table.insert(M_Raven_Default.CommandArray,"M_Raven_ChaseChargeSlash") 
end 

SWEP.Base = "weapon_ut99_base" 
SWEP.Category = "Other" 
SWEP.PrintName = "Raven Blade" 
SWEP.Author = "DevilHawk" 
SWEP.Purpose = "Primary or Secondary: Normal Swing. ALT + Primary or Secondary: Select skill. Reload: Cast selected skill. " 
SWEP.Spawnable = true 

SWEP.WepSelectIcon		= surface and surface.GetTextureID("vgui/stellarblade/raven_blade") 

SWEP.Slot = 0 
-- SWEP.SlotPos = 2 
SWEP.RenderGroup = RENDERGROUP_BOTH 
SWEP.DeploySound = "character/se/pc_foldsword_open.wav" 

SWEP.HoldType			= "knife" 
SWEP.UseHands = true 
SWEP.ViewModel = Model( "models/stellarblade/c_raven_blade.mdl" ) 
SWEP.WorldModel = Model( "models/stellarblade/ch_m_na_53_weapon.mdl" ) 
SWEP.ViewModelFOV = 60 
SWEP.ViewModelFlip = false 

SWEP.Primary.Animation = ACT_VM_PRIMARYATTACK 
SWEP.Primary.Automatic = true 
SWEP.Primary.ClipSize = -1 
SWEP.Primary.Damage = 1000 
SWEP.Primary.DefaultClip = -1 
SWEP.Primary.Delay			= 0		-- additive after sequenceduration  
SWEP.Primary.Playback_Rate 	= 1 -- determine anim play speed 
SWEP.Primary.Projectile_Class	=	"proj_u4et_tomshell" 
SWEP.Primary.Sound			= Sound("M_Raven_SwordSwish_S_Cue") 

SWEP.Secondary.Animation = ACT_VM_SECONDARYATTACK 
SWEP.Secondary.Automatic = true 
SWEP.Secondary.Delay			= 0		-- additive after sequenceduration  
SWEP.Secondary.Playback_Rate 	= 1 -- determine anim play speed 
SWEP.Secondary.Sound			= Sound("M_Raven_SwordSwish_L_Cue") 
SWEP.Melee_HitSound	=	Sound("M_Raven_Skill_Stab_Cue") 
local tempMatrix = Matrix() 

function SWEP:SpecialDT() 
    self:NetworkVar("Int", "SelectedSkillIndex") 
    -- self:NetworkVar("Bool", 0, "InSkillMode") -- SetAttack will be used instead 
end 

function SWEP:CanPrimaryAttack() return self:GetHolsterDelay() == 0 and self:GetActivity() != ACT_VM_HOLSTER end 
function SWEP:CanBePickedUpByNPCs() return false end 
function SWEP:Deploy() 
	local owner = self:GetOwner() 
	if IsValid(owner) then 
		if owner:IsPlayer() then 
			owner:AddVCDSequenceToGestureSlot(0,owner:LookupSequence("layer_Eve_Weapon_Start_Anim"),0,true) 
			BroadcastLua("if IsValid(Entity("..owner:EntIndex()..")) then Entity("..owner:EntIndex().."):AddVCDSequenceToGestureSlot(0,Entity("..owner:EntIndex().."):LookupSequence('layer_Eve_Weapon_Start_Anim'),0,true) end ") 
		end 
	end 
	return weapons.GetStored("weapon_ugold_automag").Deploy(self) 
end 
function SWEP:ShouldDropOnDie() return true end 
function SWEP:SpecialThink() 
	if self:GetHolsterDelay() != 0 or self:GetActivity() == ACT_VM_HOLSTER then return false end 
	local owner = weapons.GetStored("weapon_ugold_dispersionpistol").Unreali_GetOwner(self) 
	local vm = weapons.GetStored("weapon_ugold_dispersionpistol").Unreali_GetViewModel(self) 
	if SERVER then 
		local StellarBlade_SelectedSkill = self.StellarBlade_SelectedSkill  
		local CheckCooldown = owner.SBAI_SkillTimers and owner.SBAI_SkillTimers[StellarBlade_SelectedSkill] -- returns Time, ["M_Raven_SlashChain"] = 216 
		-- print(CheckCooldown) 
		if CheckCooldown then 
			self:SetAttackDelay(CheckCooldown) 
		end 
	end 
	
	if owner:KeyDown(IN_WALK) then
        -- self:SetAttack(true)
        
        -- Allow scrolling through skills
        if owner:KeyPressed(IN_ATTACK) then
            -- Optional: Click to Instant Cast current selection while holding Reload
            -- self:PrimaryAttack() 
            -- return 
        end 
        
        if owner:KeyPressed(IN_ATTACK) then
            self:CycleSkill(1) -- Next Skill
        elseif owner:KeyPressed(IN_ATTACK2) then
            self:CycleSkill(-1) -- Prev Skill
        end
        
    else
        -- self:SetAttack(false)
    end 
	if IsValid(vm) then 
		if vm:GetCycle() > 0.15 and vm:GetCycle() < 0.35 and self:GetActivity() == ACT_VM_SECONDARYATTACK then 
			if self:GetNextSecondaryFire() > CurTime() then 
				local ents = scripted_ents.GetStored("cycler_actor2").t.NPC_MeleeAttack(self,nil,nil,nil,nil,5) 
			end 
		end 
	end 
	return weapons.GetStored("weapon_ugold_asmd").SpecialThink(self) 
end 

function SWEP:CycleSkill(direction)
    if !self.CachedSkillList or #self.CachedSkillList == 0 then self:BuildSkillList() return end
    
    local cur = self:GetSelectedSkillIndex()
    local nextIndex = cur + direction
    
    if nextIndex > #self.CachedSkillList then nextIndex = 1 end
    if nextIndex < 1 then nextIndex = #self.CachedSkillList end
    
    self:SetSelectedSkillIndex(nextIndex)
    
    if IsFirstTimePredicted() then
        self:EmitSound("buttons/lightswitch2.wav", 50, 150) -- Small click sound
    end
    
    -- Update the actual string variable for the logic
    local skillName = self.CachedSkillList[nextIndex]
    self.StellarBlade_SelectedSkill = skillName
end

function SWEP:SpecialInit() 
	self:SetSaveValue("m_fMaxRange1",64) 
	self:SetSaveValue("m_fMaxRange2",64) 
	self:SetSaveValue("m_fMinRange1",0) 
	self:SetSaveValue("m_fMinRange2",0) 
	if CLIENT then 
		local ef = EffectData() 
		ef:SetEntity(self) 
		ef:SetScale(0) -- sets time. 0 to make looping 
		ef:SetFlags(0) -- 1 to kill given effects 
		ef:SetMagnitude(0) 
		util.Effect("P_D_RavenHuman_AnimTrail_Loop_01",ef) 
		-- util.Effect("mi_a_gpusparks_01",ef) 
		-- util.Effect("MI_A_Flares_01_23",ef) 
		ef:SetAttachment(2) 
		util.Effect("ne_ribbonm",ef) 
	end 
	self.CachedSkillList = {} 
	self:BuildSkillList() 
	self:SetSelectedSkillIndex(1) 
	self.StellarBlade_SelectedSkill = "M_Raven_Slash" 
end 

function SWEP:BuildSkillList() 
	-- hack in custom skill ChaseChargeSlash 
	local SB_M_Raven_ChaseChargeSlash = SB_ImportUAsset("data_static/SB/Content/Art/Show/CH_M_NA_53_Raven/Skill/M_Raven_ChaseChargeSlash.uasset") 
	local M_Raven_ChaseChargeSlash = table.Copy(SB_SkillTable[1].Rows["M_Raven_Slash"]) 
	local M_Raven_ChaseChargeSlash_Cast1 = SB_M_Raven_ChaseChargeSlash[4].Properties.ShowStepArray[1].StepProperty 
	local M_Raven_ChaseChargeSlash_Hit1 = SB_M_Raven_ChaseChargeSlash[4].Properties.ShowStepArray[2].StepProperty 
	local M_Raven_ChaseChargeSlash_Finish1 = SB_M_Raven_ChaseChargeSlash[4].Properties.ShowStepArray[3].StepProperty 
	local M_Raven_ChaseChargeSlash_Move1 = table.Copy(SB_CharacterMoveTable[1].Rows["Move_Forward_20"]) 
	local M_Raven_ChaseChargeSlash_Move2 = table.Copy(SB_CharacterMoveTable[1].Rows["Move_Forward_20"]) 
	local M_Raven_ChaseChargeSlash_Move3 = table.Copy(SB_CharacterMoveTable[1].Rows["Move_Forward_20"]) 
	local M_Raven_ChaseChargeSlash_Move4 = table.Copy(SB_CharacterMoveTable[1].Rows["Move_Forward_20"]) 
	local SR_M_Raven_ChaseChargeSlash_Hit1 = table.Copy(SB_SkillResultTable[1].Rows["M_Raven_Slash_Hit1"]) 
	M_Raven_ChaseChargeSlash.SkillType = "ESBSkillType::SkillType_MeleeAttack" 
	M_Raven_ChaseChargeSlash.FirstSkillActiveAlias = "M_Raven_ChaseChargeSlash_Cast1" 
	M_Raven_ChaseChargeSlash.CoolTime = 30
	
	M_Raven_ChaseChargeSlash_Hit1.OverrideTargetFilterAlias = "M_Raven_Slash_Target" 
	M_Raven_ChaseChargeSlash_Hit1.bEveryFrameHitCheck = true 
	
	
	M_Raven_ChaseChargeSlash_Move1 = table.Merge(M_Raven_ChaseChargeSlash_Move1, SB_M_Raven_ChaseChargeSlash[36].Properties.MoveTableProperty) 
	M_Raven_ChaseChargeSlash_Move2 = table.Merge(M_Raven_ChaseChargeSlash_Move2, SB_M_Raven_ChaseChargeSlash[37].Properties.MoveTableProperty) 
	M_Raven_ChaseChargeSlash_Move3 = table.Merge(M_Raven_ChaseChargeSlash_Move3, SB_M_Raven_ChaseChargeSlash[38].Properties.MoveTableProperty) 
	M_Raven_ChaseChargeSlash_Move4 = table.Merge(M_Raven_ChaseChargeSlash_Move4, SB_M_Raven_ChaseChargeSlash[39].Properties.MoveTableProperty) 
	SR_M_Raven_ChaseChargeSlash_Hit1 = table.Merge(SR_M_Raven_ChaseChargeSlash_Hit1, SB_M_Raven_ChaseChargeSlash[40].Properties.SkillResultTableProperty) 
	
	M_Raven_ChaseChargeSlash_Move1.bIgnoreCollision = false 
	M_Raven_ChaseChargeSlash_Move2.bIgnoreCollision = false 
	M_Raven_ChaseChargeSlash_Move3.bIgnoreCollision = true 
	M_Raven_ChaseChargeSlash_Move4.bIgnoreCollision = false 
	
	M_Raven_ChaseChargeSlash_Move1.ForwardValue = 0 
	M_Raven_ChaseChargeSlash_Move2.ForwardValue = 0 
	M_Raven_ChaseChargeSlash_Move3.ForwardValue = 0 
	M_Raven_ChaseChargeSlash_Move4.ForwardValue = 0 
	
	M_Raven_ChaseChargeSlash_Move2.bExecuteSeparately = false 
	M_Raven_ChaseChargeSlash_Move3.bExecuteSeparately = true 
	M_Raven_ChaseChargeSlash_Move4.bExecuteSeparately = true 
	
	SB_SkillTable[1].Rows["M_Raven_ChaseChargeSlash"] = M_Raven_ChaseChargeSlash 
	SB_SkillActiveStepTable[1].Rows["M_Raven_ChaseChargeSlash_Cast1"] = M_Raven_ChaseChargeSlash_Cast1 
	SB_SkillActiveStepTable[1].Rows["M_Raven_ChaseChargeSlash_Hit1"] = M_Raven_ChaseChargeSlash_Hit1 
	SB_SkillActiveStepTable[1].Rows["M_Raven_ChaseChargeSlash_Finish1"] = M_Raven_ChaseChargeSlash_Finish1 
	SB_SkillResultTable[1].Rows["M_Raven_ChaseChargeSlash_Hit1"] = SR_M_Raven_ChaseChargeSlash_Hit1
	SB_CharacterMoveTable[1].Rows["M_Raven_ChaseChargeSlash_Move1"] = M_Raven_ChaseChargeSlash_Move1
	SB_CharacterMoveTable[1].Rows["M_Raven_ChaseChargeSlash_Move2"] = M_Raven_ChaseChargeSlash_Move2
	SB_CharacterMoveTable[1].Rows["M_Raven_ChaseChargeSlash_Move3"] = M_Raven_ChaseChargeSlash_Move3
	SB_CharacterMoveTable[1].Rows["M_Raven_ChaseChargeSlash_Move4"] = M_Raven_ChaseChargeSlash_Move4 
	
	SCT_M_Raven_ChaseChargeSlash = table.Copy(SB_SkillCommandTable[1].Rows["M_Raven_Slash"]) 
	SCT_M_Raven_ChaseChargeSlash.SkillAlias = "M_Raven_ChaseChargeSlash" 
	SB_SkillCommandTable[1].Rows["M_Raven_ChaseChargeSlash"] = SCT_M_Raven_ChaseChargeSlash 
	
    -- Access the global table loaded by your JSON importer 
    if SB_CharacterStanceTable and SB_CharacterStanceTable[1] and SB_CharacterStanceTable[1].Rows then 
        local stanceData = SB_CharacterStanceTable[1].Rows.M_Raven_Default 
        if stanceData and stanceData.CommandArray then 
            self.CachedSkillList = stanceData.CommandArray 
            -- print("Raven Blade: Loaded " .. #self.CachedSkillList .. " skills.") 
        end 
    end 
end 

function SWEP:PrimaryAttack() 
	-- determine next attack time, relative with anim play rate 
	if !self:CanPrimaryAttack() then return false end 
    local owner = self:GetOwner() 
	if owner:KeyDown(IN_WALK) then return end 
	local vm = weapons.GetStored("weapon_ugold_dispersionpistol").Unreali_GetViewModel(self) 
	local seq = vm:SelectWeightedSequence( self.Primary.Animation ) 
	local Delay = vm:SequenceDuration(seq) 
	self:SetNextPrimaryFire(CurTime() + self.Primary.Delay + (Delay / self.Primary.Playback_Rate)) 
	self:SetNextSecondaryFire(math.max(CurTime() + self.Primary.Delay + (Delay / self.Primary.Playback_Rate)),self:GetNextSecondaryFire()) 
	-- do the attack 
	if self:GetActivity() != self.Primary.Animation then self:SendWeaponAnim(self.Primary.Animation) end 
	vm:SetPlaybackRate(self.Primary.Playback_Rate) 
	self:UTRecoil() 
	self:EmitSound(self.Primary.Sound, 100, 100) 
	self:UDSound() 
	self:DisableHolster() 
	self:GetOwner():SetAnimation( PLAYER_ATTACK1 ) 
	-- self:GetOwner():AnimRestartGesture(GESTURE_SLOT_ATTACK_AND_RELOAD, ACT_HL2MP_GESTURE_RANGE_ATTACK_MELEE, true) 
	-- self:TakeAmmo() 
	self:SetIdleDelay(CurTime() + self.Primary.Delay + (Delay / self.Primary.Playback_Rate)) 
	local ents = scripted_ents.Get("cycler_actor2").NPC_MeleeAttack(self,nil,nil,nil,nil,120) 
end 

function SWEP:SecondaryAttack() 
	-- if not self:CanSecondaryAttack() then return end 
	-- determine next attack time, relative with anim play rate 
	if !self:CanPrimaryAttack() then return false end 
	local owner = self:GetOwner() 
	if owner:KeyDown(IN_WALK) then return end 
	local vm = weapons.GetStored("weapon_ugold_dispersionpistol").Unreali_GetViewModel(self) 
	-- PrintTable(scripted_ents.Get("cycler_actor2").NPC_MeleeAttack(self,nil,nil,nil,nil,120)) 
	local Animation = table.IsEmpty(scripted_ents.Get("cycler_actor2").NPC_MeleeAttack(self,nil,nil,nil,nil,120)) and ACT_VM_MISSCENTER or self.Secondary.Animation
	local seq = vm:SelectWeightedSequence( Animation ) 
	-- local seq = vm:SelectWeightedSequence( self.Secondary.Animation ) -- play ACT_VM_MISSCENTER if secondary attack missed 
	local Delay = vm:SequenceDuration(seq) 
	self:SetNextPrimaryFire(CurTime() + self.Secondary.Delay + (Delay / self.Secondary.Playback_Rate)) 
	self:SetNextSecondaryFire(math.max(CurTime() + self.Secondary.Delay + (Delay / self.Secondary.Playback_Rate)),self:GetNextSecondaryFire()) 
	-- do the attack 
	self:SendWeaponAnim(Animation) 
	vm:SetPlaybackRate(self.Secondary.Playback_Rate) 
	self:UTRecoil() 
	self:UDSound() 
	self:DisableHolster() 
	self:GetOwner():SetAnimation( PLAYER_ATTACK1 ) 
	-- self:TakeAmmo() 
	self:SetIdleDelay(CurTime() + self.Secondary.Delay + (Delay / self.Secondary.Playback_Rate)) 
	self:EmitSound(self.Secondary.Sound, 100, 100) 
	-- local ents = scripted_ents.Get("cycler_actor2").NPC_MeleeAttack(self,nil,nil,nil,nil,150) 
end 

function SWEP:NPCShoot_Primary(shootPos, shootDir) 
	
end 

function SWEP:NPCShoot_Secondary(shootPos, shootDir) 
	
end 

function SWEP:Reload() 
	if !self:CanPrimaryAttack() then return false end 
    local owner = self:GetOwner() 
    
    -- 1. If holding RELOAD, standard M1 just cycles (handled in Think), or does nothing to prevent accidental fires. 
    if owner:KeyDown(IN_WALK) then return end 

    -- 2. Check if we have a skill Queued
    if self.StellarBlade_SelectedSkill then 
		-- if !owner.SBAI_SkillStep or owner.SBAI_SkillStep and !owner.SBAI_SkillStep:IsActive() then 
		
		if owner.SBAI_SkillTable and !owner.SBAI_SkillTable.IsValid then 
			owner.SBAI_SkillTable = nil 
			owner.SBAI_SkillStep = nil 
			owner.SBAI_SkillTimers = nil 
			owner.SBAI_SkillUseCount = nil 
			StellarBlade.ForceClearActorState(owner) 
		end 
		
		if !owner.SBAI_SkillStep or owner.SBAI_SkillStep and !StellarBlade.SBAI_SkillStep.IsActive(owner.SBAI_SkillStep) then 
            local success = StellarBlade.StartSkillCommand(owner, self.StellarBlade_SelectedSkill) 
			-- print("success",success) 
            if success then return end 
        end 
    end 
end 

function SWEP:Holster(Other) 
	-- local retVal = weapons.Get("weapon_ut99_base").Holster(self,Other) 
	if IsValid(self.GlowProjectedTexture) then
        self.GlowProjectedTexture:Remove()
    end
    return true
end 

function SWEP:OnRemove() 
	weapons.GetStored("weapon_ut99_base").OnRemove(self) 
	if IsValid(self.GlowProjectedTexture) then
        self.GlowProjectedTexture:Remove()
    end 
	if IsValid(self.Emitter) then self.Emitter:Finish() end 
end 

function SWEP:GetCapabilities() return CAP_WEAPON_MELEE_ATTACK1 + CAP_WEAPON_MELEE_ATTACK2 end 

function SWEP:OnRestore() 
	if IsValid(self:GetOwner()) then 
		self:GetOwner().SBAI_SkillTimers = nil 
	end 
	if IsValid(self.GlowProjectedTexture) then
        self.GlowProjectedTexture:Remove()
    end
end 

function SWEP:GetNPCBurstSettings() return 1, 1, 1 end 
local color_modeselecting = Color(255, 200, 50, 255) 
local color_modenotselecting = Color(255, 255, 255, 150) 
local color_text = Color(200,200,200) 
local colBg = Color(0, 0, 0, 150)

function SWEP:DrawHUD()
    weapons.GetStored("weapon_ut99_base").DrawHUD(self) 
	local sTable = fGetTable(self) 
    
    if #sTable.CachedSkillList == 0 then 
        self:BuildSkillList() -- Try building again if empty
        return 
    end
    
    local idx = sTable:GetSelectedSkillIndex()
    local skillName = sTable.CachedSkillList[idx] or "None"
    local inMode = self:GetOwner():KeyDown(IN_WALK)
    
    -- Configuration
    local x, y = ScrW() * 0.85, ScrH() * 0.85
    local colText = inMode and color_modeselecting or color_modenotselecting
    
    -- Draw Background Box
    draw.RoundedBox(4, x - 10, y - 10, 250, 70, colBg)
    
    -- Draw "Skill Ready" Label
    draw.SimpleText("ACTIVE SKILL [Hold ALT + Mouse Buttons]", "DermaDefault", x, y, color_text, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
    
    -- Clean up the name (Remove M_Raven_ prefix for cleaner UI)
    local cleanName = string.Replace(skillName, "M_Raven_", "") 
    cleanName = string.Replace(cleanName, "_", " ") 
	cleanName = string.NiceName(cleanName) 
    
    -- Draw Skill Name
    surface.SetFont("DermaLarge")
    local tw, th = surface.GetTextSize(cleanName)
    draw.SimpleText(cleanName, "DermaLarge", x, y + 5, colText, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    draw.SimpleText("Press RELOAD to activate", "DermaDefault", x, y + 40, color_text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
end 

-- ============================================================
-- Niagara-style looping flare + lens object renderer
-- ============================================================
local flareLayers = {
    {
        mat = Material("sprites/t_a_shineflare_02"),
        size = 30,
        color = Color(140, 255, 255),
        hardness = 1.2
    },
    {
        mat = Material("sprites/t_a_spheremask_02"),
        size = 14,
        color = Color(80, 255, 255),
        hardness = 0.9
    },
    {
        mat = Material("sprites/t_a_shineflare_02"),
        size = 20,
        color = Color(255, 255, 255),
        hardness = 0.7
    }
}

-- Lens object layers (Horizon 03 and 05)
local lensObjLayers = {
    {
        mat = Material("sprites/MI_A_LensObj_Horizon_01_5"),   -- Horizon 05, wider
        baseSize = 180,
        color = Color(200, 255, 255),
        desat = 0.7,
        flickerSpeed = 1.6,
        hardness = 0.8
    },
    {
        mat = Material("sprites/MI_A_LensObj_Horizon_01_3_AfterDof"), -- Horizon 03, strong
        baseSize = 120,
        color = Color(255, 255, 255),
        desat = 1.0,
        flickerSpeed = 2.3,
        hardness = 1.0
    }
}

function SWEP:ViewModelDrawn(vm)
    weapons.GetStored("weapon_ut99_base").ViewModelDrawn(self, vm) 
	self:Raven_Blade_Flare(vm,0.4,0.5,"v_weapon.Knife_Handle") 
	self:Raven_Blade_Sparks(vm) 
	self:Raven_Blade_Beam(vm) 
end 

function SWEP:DrawWorldModelTranslucent(flags) 
	local base = weapons.GetStored("weapon_ut99_base") 
	local sTable = self:GetTable() 
	if base and base.DrawWorldModelTranslucent then 
		base.DrawWorldModelTranslucent(self, flags) 
	end 
	self:Raven_Blade_Flare(self,1.3,1.5,"ValveBiped.Bip01_R_Hand") 
	self:Raven_Blade_Sparks(IsValid(self:GetOwner()) and self:GetOwner() or self) 
	self:Raven_Blade_Beam(self) 
end 

function SWEP:CustomAmmoDisplay() 
	self.AmmoDisplay = self.AmmoDisplay or {} 
	self.AmmoDisplay.Draw = true -- draw the display? 
	self.AmmoDisplay.PrimaryClip = -1 -- amount in clip 
	-- self.AmmoDisplay.PrimaryAmmo = self:GetAttackDelay() - CurTime() -- amount in clip 
	self.AmmoDisplay.SecondaryAmmo = self:GetAttackDelay() - CurTime() -- amount in clip 
	return self.AmmoDisplay 
end 

-- Cache materials and colors to prevent garbage collection stuttering
local GLOW_MAT = Material("sprites/glow04_noz")
local BEAM_MAT = Material("effects/laser1")
local glowColor = Color(0, 210, 255, 255)
local beamColor = Color(220, 250, 255, 255)

-- Pre-allocated vectors to eliminate garbage collection allocations every frame
local startPos = Vector()
local endPos = Vector()
local startPos_beam = Vector()
local endPos_beam = Vector()
local tempVec = Vector()

function SWEP:Raven_Blade_Beam(ent) 
    local handBone = ent:LookupBone("v_weapon.Knife_Handle") -- following bone doesn't exist on worldmodel 
    if !handBone then handBone = ent:LookupBone("ValveBiped.Bip01_R_Hand") end -- exists on worldmodel 
    if !handBone then return end 

    ent:CopyBoneMatrix(handBone, tempMatrix) 
    local pos = tempMatrix:GetTranslation() 

    -- Directly fetch directional vectors from the matrix to avoid Angle conversions
    local fwd = tempMatrix:GetForward()
    local rgt = tempMatrix:GetRight()
    local up = tempMatrix:GetUp()

    if ent:GetClass() == "viewmodel" then -- drawing viewmodel 
        startPos:Set(pos)
        tempVec:Set(fwd); tempVec:Mul(1); startPos:Add(tempVec)
        tempVec:Set(rgt); tempVec:Mul(1); startPos:Add(tempVec)
        tempVec:Set(up); tempVec:Mul(-14); startPos:Add(tempVec)

        endPos:Set(pos)
        tempVec:Set(fwd); tempVec:Mul(1); endPos:Add(tempVec)
        tempVec:Set(rgt); tempVec:Mul(1); endPos:Add(tempVec)
        tempVec:Set(up); tempVec:Mul(50); endPos:Add(tempVec)

        tempVec:Set(startPos)
        tempVec:Sub(endPos)
        tempVec:Normalize()
        tempVec:Mul(10)
        startPos:Add(tempVec)
    else -- drawing worldmodel 
        startPos:Set(pos)
        tempVec:Set(fwd); tempVec:Mul(1.1); startPos:Add(tempVec)
        tempVec:Set(rgt); tempVec:Mul(6); startPos:Add(tempVec)
        tempVec:Set(up); tempVec:Mul(15.4); startPos:Add(tempVec)

        endPos:Set(pos)
        tempVec:Set(fwd); tempVec:Mul(10.6); endPos:Add(tempVec)
        tempVec:Set(rgt); tempVec:Mul(-19.5); endPos:Add(tempVec)
        tempVec:Set(up); tempVec:Mul(-88.3); endPos:Add(tempVec)

        tempVec:Set(startPos)
        tempVec:Sub(endPos)
        tempVec:Normalize()
        tempVec:Mul(21)
        startPos:Add(tempVec)
    end 
    
    if ent:GetClass() == "viewmodel" then -- drawing viewmodel 
        startPos_beam:Set(pos)
        tempVec:Set(up); tempVec:Mul(7); startPos_beam:Add(tempVec)

        endPos_beam:Set(pos)
		tempVec:Set(fwd); tempVec:Mul(1.6); endPos_beam:Add(tempVec)
		tempVec:Set(rgt); tempVec:Mul(-0.4); endPos_beam:Add(tempVec)
        tempVec:Set(up); tempVec:Mul(65); endPos_beam:Add(tempVec)
		-- print(tempVec) 
    else -- drawing worldmodel 
        startPos_beam:Set(pos)
        tempVec:Set(fwd); tempVec:Mul(3.4); startPos_beam:Add(tempVec)
        tempVec:Set(rgt); tempVec:Mul(0.6); startPos_beam:Add(tempVec)
        tempVec:Set(up); tempVec:Mul(-8.9); startPos_beam:Add(tempVec)

        endPos_beam:Set(pos)
        tempVec:Set(fwd); tempVec:Mul(8.5); endPos_beam:Add(tempVec)
        tempVec:Set(rgt); tempVec:Mul(-12.8); endPos_beam:Add(tempVec)
        tempVec:Set(up); tempVec:Mul(-63.1); endPos_beam:Add(tempVec)
    end 
    
    local distSqr = EyePos():DistToSqr(startPos) -- max: 26700 
    glowColor:SetUnpacked(0, 210, 255, 255)
    beamColor:SetUnpacked(220, 250, 255, 255)
    if ent:GetClass() == "viewmodel" then -- drawing viewmodel 
        glowColor:SetBrightness(math.Clamp(distSqr/5000,0,1)) 
        beamColor:SetBrightness(math.Clamp(distSqr/5000,0,1)) 
    else 
        glowColor:SetBrightness(math.Clamp(distSqr/26700,0,1)) 
        beamColor:SetBrightness(math.Clamp(distSqr/26700,0,1)) 
    end 
    
    -- 1. Draw outer wide beam (Blade Aura)
    render.SetMaterial(GLOW_MAT)
    render.DrawBeam(startPos, endPos, 32, 0, 1, glowColor)
    -- 2. Draw inner bright core beam
    render.DrawBeam(startPos, endPos, 6, 0, 1, beamColor)
    
    render.SetMaterial(BEAM_MAT)
    render.DrawBeam(startPos_beam, endPos_beam, 6, 0, 1, glowColor)
    -- 2. Draw inner bright core beam
    render.DrawBeam(startPos_beam, endPos_beam, 3, 0, 1, beamColor)
end

local flarePos = Vector()
local projectedTexAngle = Angle(90, 0, 0)
local projectedTexColor = Color(140, 255, 255)
local renderColor = Color(255, 255, 255, 255)
local baseScaleVec = Vector()

function SWEP:Raven_Blade_Flare(ent, mins, maxs, bonename) 
    local handBone = ent:LookupBone(bonename)
    if !handBone then return end

    ent:CopyBoneMatrix(handBone, tempMatrix)

    flarePos:Set(tempMatrix:GetTranslation())
    local fwd = tempMatrix:GetForward()
    local rgt = tempMatrix:GetRight()
    local up = tempMatrix:GetUp()

    if ent:GetClass() == "viewmodel" then 
        tempVec:Set(up)
        tempVec:Mul(7)
        flarePos:Add(tempVec)
    else 
        tempVec:Set(fwd); tempVec:Mul(3.4); flarePos:Add(tempVec)
        tempVec:Set(rgt); tempVec:Mul(0.6); flarePos:Add(tempVec)
        tempVec:Set(up); tempVec:Mul(-8.9); flarePos:Add(tempVec)
    end 

    local view = EyePos()
    local distSqr = flarePos:DistToSqr(view)
    local dist = math.sqrt(distSqr)
    local distAlpha = math.Clamp(dist / 150, 0, 1)

    -- Niagara-style distance emissive scaling
    local maxRange = 4096
    local fade = math.Clamp(dist / maxRange, 0, 1)
    local intensity = Lerp(1 - math.sqrt(fade), 1.0, 2.5)

    -- ============================================================
    -- === Projected Texture Glow ===
    -- ============================================================
    -- Initialize the texture if it doesn't exist
    if !IsValid(self.GlowProjectedTexture) then
        self.GlowProjectedTexture = ProjectedTexture() 
        self.GlowProjectedTexture:SetAngles(projectedTexAngle) -- Point straight down
        self.GlowProjectedTexture:SetColor(projectedTexColor) -- Cyan to match flares
        self.GlowProjectedTexture:SetFarZ(256) -- Vertical depth limit
        self.GlowProjectedTexture:SetFOV(180)
        -- Use orthographic bounds to enforce the 128 radius
        self.GlowProjectedTexture:SetOrthographic(true, -128, -128, 128, 128) 
        self.GlowProjectedTexture:SetTexture("sprites/t_b_glow_01") 
    end

    -- Update position and dynamically adjust brightness to match the flare intensity
    if IsValid(self.GlowProjectedTexture) then
        self.GlowProjectedTexture:SetPos(flarePos)
        -- Add a subtle flicker multiplier to blend with the Niagara effects
        local ptexFlicker = 1 + (math.sin(CurTime() * 15) * 0.05)
        self.GlowProjectedTexture:SetBrightness(0.5 * ptexFlicker * intensity)
        self.GlowProjectedTexture:Update()
    end

    -- ============================================================
    -- === Direct Flare Rendering ===
    -- ============================================================
    local baseScale = 1.0
    if mins and maxs then
        if isvector(mins) and isvector(maxs) then
            baseScaleVec:Set(mins)
            baseScaleVec:Add(maxs)
            baseScaleVec:Mul(0.5)
            baseScale = baseScaleVec
        else
            baseScale = (mins + maxs) * 0.5
        end
    end

    local flicker = 1 + (math.sin(CurTime() * 17.3) + math.sin(CurTime() * 11.8)) * 0.02
    local pulse = 1 + math.sin(CurTime() * 6) * 0.05
    local flareScale = baseScale * pulse * flicker

    for _, layer in ipairs(flareLayers) do
        render.SetMaterial(layer.mat)
        local col = layer.color
        local size = layer.size * flareScale

        renderColor:SetUnpacked(col.r, col.g, col.b, 255 * distAlpha)
        render.DrawSprite(
            flarePos,
            size,
            size,
            renderColor
        )
    end

    -- ============================================================
    -- === Direct Lens Object Rendering ===
    -- ============================================================
    for _, layer in ipairs(lensObjLayers) do
        render.SetMaterial(layer.mat)
        local col = layer.color
        local flicker2 = 1 + math.sin(CurTime() * (layer.flickerSpeed or 1.0)) * 0.05
        local size = layer.baseSize * flicker2

        renderColor:SetUnpacked(col.r, col.g, col.b, 255 * distAlpha)
        render.DrawSprite(
            flarePos,
            size * 0.10,
            size * 0.15,
            renderColor
        )
    end
end

function SWEP:Raven_Blade_Sparks(ent) 
	if self.Raven_Blade_Sparks_NextTime and self.Raven_Blade_Sparks_NextTime >= CurTime() then return end 
	self.Raven_Blade_Sparks_NextTime = CurTime() + 0.1 
	local handBone = ent:LookupBone("ValveBiped.Bip01_R_Hand")
	if !handBone then return end
	ent:CopyBoneMatrix(handBone,tempMatrix)

	local pos = tempMatrix:GetTranslation()
	local up = tempMatrix:GetUp() 
	-- local ang = tempMatrix:GetAngles() 
	if ent:GetClass() == "viewmodel" then 
		local forward = up * -7
		-- pos = pos + forward
		pos:Add(forward) 
	else 
		up:Mul(9) 
		-- pos = pos - up * 9 
		pos:Sub(up)
	end 
	if !IsValid(self.Emitter) then self.Emitter = ParticleEmitter(pos) end 
	local p = self.Emitter:Add("effects/spark", pos) 

	if p then
		local initialSpeed = 50
		local initialDir = VectorRand()

		p:SetVelocity(initialDir * initialSpeed) 
		p:SetDieTime(math.Rand(1,2)) 
		p:SetStartAlpha(255)
		p:SetEndAlpha(0)
		p:SetStartSize(2)
		p:SetEndSize(0)
		p:SetColor(0, 200, 255)
		p:SetGravity(initialDir) 
		p:SetStartLength(0.1) 
		p:SetEndLength(0) 
		p:SetVelocityScale(true) 
		
		-- Initialize custom variables for the Think function
		p.CreationTime = CurTime() 
		p.NextTurnTime = CurTime() -- Force the first turn calculation immediately
		p.Speed = initialSpeed
		p.TargetDir = initialDir

		p:SetThinkFunction(function(prt) 
			local ct = CurTime()
			local ft = FrameTime()

			-- 1. Choose a new direction every 0.15 seconds
			if ct >= prt.NextTurnTime then
				local dir = prt:GetVelocity():GetNormalized()

				-- Apply random rotation logic based on your example.
				-- Note: math.random() without args cleanly returns a float between 0 and 1.
				dir.x = dir.x + 0.7 * (0.5 - math.random()) 
				dir.y = dir.y + 0.7 * (0.5 - math.random()) 
				dir.z = dir.z + 0.7 * (0.5 - math.random()) 

				prt.TargetDir = dir:GetNormalized()
				prt.NextTurnTime = ct + 0.15
			end

			-- 2. Smoothly apply rotation and velocity every frame
			local currentDir = prt:GetVelocity():GetNormalized()
			
			-- LerpVector provides the smooth transition. The '10' is the turn speed.
			local newDir = LerpVector(ft * 10, currentDir, prt.TargetDir):GetNormalized()
			prt:SetVelocity(newDir * prt.Speed)

			-- 3. Set particle angles and roll according to motion dir
			local motionAng = newDir:Angle()
			
			-- Applies 3D orientation (Useful if the material supports 3D rendering)
			prt:SetAngles(motionAng)
			
			-- Applies 2D Sprite Roll. SetRoll expects radians, so we convert the Angle's yaw/roll.
			prt:SetRoll(motionAng.y * (math.pi / 180))
			local interval = prt:GetLifeTime()/prt:GetDieTime() 
			-- prt:SetColor(255*(1-interval),255,255) -- fade to cyan 

			prt:SetNextThink(CurTime()) 
		end) 

		p:SetNextThink(CurTime()) 
	end
end 