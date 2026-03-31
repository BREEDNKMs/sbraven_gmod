AddCSLuaFile() 

function SB_ImportJSON(path)
    -- Helper function to process a single JSON file (unchanged).
    local function ProcessJSONFile(relativePath)
        local fileName = string.match(relativePath, "([^/]+)%.json$")
        if not fileName then
            MsgC(Color(255, 100, 100), "[SB Importer] Invalid file name or not a .json file: ", relativePath, "\n")
            return
        end
        local globalTableName = "SB_" .. fileName

        if _G[globalTableName] then
            MsgC(Color(100, 255, 100), "[SB Importer] Table '", globalTableName, "' already exists. Skipping file read.\n")
            return _G[globalTableName] 
        end

        local jsonString = file.Read(relativePath, "GAME")
        if not jsonString then
            ErrorNoHalt(string.format("[SB Importer] Failed to read file for '%s'! Check path: %s\n", globalTableName, relativePath))
            return
        end

        local tempTable = util.JSONToTable(jsonString,false)
        if not tempTable then
            ErrorNoHalt(string.format("[SB Importer] Failed to parse JSON for '%s'! File may be malformed: %s\n", globalTableName, relativePath))
            return
        end

        _G[globalTableName] = tempTable
        MsgC(Color(100, 255, 100), "[SB Importer] Successfully loaded '", relativePath, "' into global table '", globalTableName, "'.\n")
		return tempTable 
    end

    -- Main function logic starts here.
    -- First, normalize the path separators from Windows-style '\' to '/'
    local normalizedPath = string.gsub(path, "\\", "/")
    local relativePath

    -- NEW, SMARTER PATH HANDLING:
    -- Try to strip the path as if it's absolute.
    local strippedPath = string.match(normalizedPath, "/garrysmod/(.+)")
    if strippedPath then
        -- If it succeeded, it was an absolute path. Use the stripped version.
        relativePath = strippedPath
    else
        -- If it failed, it's already a relative path. Use it as-is.
        relativePath = normalizedPath
    end

    -- The rest of the function proceeds with the correctly determined relativePath.
    if file.IsDir(relativePath, "GAME") then
        local filesInDir = file.Find(relativePath .. "/*.json", "GAME")
        MsgC(Color(255, 255, 100), "[SB Importer] Starting batch import for directory: ", relativePath, "\n")

        if #filesInDir == 0 then
            MsgC(Color(255, 150, 0), "[SB Importer] No .json files found in ", relativePath, "\n")
            return
        end

        for _, fileName in ipairs(filesInDir) do
            -- Make sure the path has a trailing slash before appending the filename
            local dirPath = string.sub(relativePath, -1) == "/" and relativePath or (relativePath .. "/")
            ProcessJSONFile(dirPath .. fileName)
        end
    else
        return ProcessJSONFile(relativePath)
    end
end

-- include("entities/npc_sb_raven.lua") 

local M_Raven_Default = "data_static/SB/Content/Local/Data/CharacterStanceTable.json" 
SB_ImportJSON(M_Raven_Default) 
M_Raven_Default = SB_CharacterStanceTable[1].Rows.M_Raven_Default 

SWEP.Base = "weapon_ut99_base" 
SWEP.Category = "Other" 
SWEP.PrintName = "Raven Blade" 
SWEP.Author = "DevilHawk" 
SWEP.Purpose = "Primary or Secondary: Normal Swing. ALT + Primary or Secondary: Select skill. Reload: Cast selected skill. " 
SWEP.Spawnable = true 

SWEP.Slot = 0 
-- SWEP.SlotPos = 2 
SWEP.RenderGroup = RENDERGROUP_BOTH 
SWEP.DeploySound = "unreali/blade1s.wav" 

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

function SWEP:SpecialDT() 
    self:NetworkVar("Int", 0, "SelectedSkillIndex") 
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
	return weapons.Get("weapon_ugold_automag").Deploy(self) 
end 
function SWEP:ShouldDropOnDie() return true end 
function SWEP:SpecialThink() 
	if self:GetHolsterDelay() != 0 or self:GetActivity() == ACT_VM_HOLSTER then return false end 
	local owner = weapons.Get("weapon_ugold_dispersionpistol").Unreali_GetOwner(self) 
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
	return weapons.Get("weapon_ugold_asmd").SpecialThink(self) 
end 

function SWEP:CycleSkill(direction)
    if #self.CachedSkillList == 0 then self:BuildSkillList() return end
    
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
	local ef = EffectData() 
	ef:SetEntity(self) 
	ef:SetScale(0) -- sets time. 0 to make looping 
	ef:SetFlags(0) -- 1 to kill given effects 
	ef:SetMagnitude(0) 
	util.Effect("P_D_RavenHuman_AnimTrail_Loop_01",ef) 
	util.Effect("mi_a_gpusparks_01",ef) 
	util.Effect("MI_A_Flares_01_23",ef) 
	ef:SetAttachment(2) 
	util.Effect("ne_ribbonm",ef) 
	self.CachedSkillList = {} 
	self:BuildSkillList() 
	self:SetSelectedSkillIndex(1) 
	self.StellarBlade_SelectedSkill = "M_Raven_Slash" 
end 

function SWEP:BuildSkillList()
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
	local vm = weapons.Get("weapon_ugold_dispersionpistol").Unreali_GetViewModel(self) 
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
	local vm = weapons.Get("weapon_ugold_dispersionpistol").Unreali_GetViewModel(self) 
	local seq = vm:SelectWeightedSequence( self.Secondary.Animation ) -- play ACT_VM_MISSCENTER if secondary attack missed 
	local Delay = vm:SequenceDuration(seq) 
	self:SetNextPrimaryFire(CurTime() + self.Secondary.Delay + (Delay / self.Secondary.Playback_Rate)) 
	self:SetNextSecondaryFire(math.max(CurTime() + self.Secondary.Delay + (Delay / self.Secondary.Playback_Rate)),self:GetNextSecondaryFire()) 
	-- do the attack 
	if self:GetActivity() != self.Secondary.Animation then self:SendWeaponAnim(self.Secondary.Animation) end 
	vm:SetPlaybackRate(self.Secondary.Playback_Rate) 
	self:UTRecoil() 
	self:UDSound() 
	self:DisableHolster() 
	self:GetOwner():SetAnimation( PLAYER_ATTACK1 ) 
	-- self:TakeAmmo() 
	self:SetIdleDelay(CurTime() + self.Secondary.Delay + (Delay / self.Secondary.Playback_Rate)) 
	self:EmitSound(self.Secondary.Sound, 100, 100) 
	local ents = scripted_ents.Get("cycler_actor2").NPC_MeleeAttack(self,nil,nil,nil,nil,150) 
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
		if !owner.SBAI_SkillStep or owner.SBAI_SkillStep and !owner.SBAI_SkillStep:IsActive() then 
				-- if strSkill then 
					-- if strSkill == "M_Raven_ShieldBreakerCounter_Cast1" then strSkill = "P_Eve_ShieldBreakerCounterRaven1_Cast1" end 
					-- if strSkill == "M_Raven_BetaSkillCounter_Cast1" then strSkill = "P_Eve_BetaCounterRaven1_Cast1" end 
				-- end 
			-- if self.StellarBlade_SelectedSkill == "M_Raven_BetaSkillCounter" then 
				-- local target = owner:GetEyeTrace().Entity 
				-- local _PickTarget = StellarBlade.PickTarget 
				-- StellarBlade.PickTarget = function() return owner end 
				-- local success = StellarBlade.SetSkillStep(target,"P_Eve_BetaCounterRaven1_Cast1") 
				-- StellarBlade.PickTarget = _PickTarget 
				-- -- StellarBlade.AddEffect(owner,"Test_BlockActionEnemy_Effect",{Constructor = owner, Target = target, TraceResult = owner:GetEyeTrace()}, StartDelayTime,0, LifeTime,7) 
				-- -- StellarBlade.AddEffect(owner,"BlockSkill",{Constructor = owner, Target = target, TraceResult = owner:GetEyeTrace()}, StartDelayTime,0, LifeTime,7) 
				-- StellarBlade.AddEffect(owner,"BlockAction",{Constructor = owner, Target = target, TraceResult = owner:GetEyeTrace()}, "StartDelayTime",0, "LifeTime",7) 
				-- return success 
			-- end 
			
			-- if self.StellarBlade_SelectedSkill == "M_Raven_ShieldBreakerCounter" then 
				-- local target = owner:GetEyeTrace().Entity 
				-- local _PickTarget = StellarBlade.PickTarget 
				-- StellarBlade.PickTarget = function() return owner end 
				-- local success = StellarBlade.SetSkillStep(target,"P_Eve_ShieldBreakerCounterRaven1_Cast1") 
				-- StellarBlade.PickTarget = _PickTarget 
				-- return success 
			-- end 
            local success = StellarBlade.StartSkillCommand(owner, self.StellarBlade_SelectedSkill) 
            if success then return end 
        end 
    end 
end 

function SWEP:Holster(Other) 
	-- local retVal = weapons.Get("weapon_ut99_base").Holster(self,Other) 
	return true 
end 

function SWEP:GetCapabilities() return CAP_WEAPON_MELEE_ATTACK1 + CAP_WEAPON_MELEE_ATTACK2 end 

function SWEP:OnRestore() 
	if IsValid(self:GetOwner()) then 
		self:GetOwner().SBAI_SkillTimers = nil 
	end 
end 

function SWEP:GetNPCBurstSettings() return 1, 1, 1 end 

function SWEP:DrawHUD()
    weapons.Get("weapon_ut99_base").DrawHUD(self)
    
    if #self.CachedSkillList == 0 then 
        self:BuildSkillList() -- Try building again if empty
        return 
    end
    
    local idx = self:GetSelectedSkillIndex()
    local skillName = self.CachedSkillList[idx] or "None"
    local inMode = self:GetOwner():KeyDown(IN_WALK)
    
    -- Configuration
    local x, y = ScrW() * 0.85, ScrH() * 0.85
    local colText = inMode and Color(255, 200, 50, 255) or Color(255, 255, 255, 150)
    local colBg = Color(0, 0, 0, 150)
    
    -- Draw Background Box
    draw.RoundedBox(4, x - 10, y - 10, 250, 70, colBg)
    
    -- Draw "Skill Ready" Label
    draw.SimpleText("ACTIVE SKILL [Hold ALT + Mouse Buttons]", "DermaDefault", x, y, Color(200,200,200), TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
    
    -- Clean up the name (Remove M_Raven_ prefix for cleaner UI)
    local cleanName = string.Replace(skillName, "M_Raven_", "") 
    cleanName = string.Replace(cleanName, "_", " ") 
	cleanName = string.NiceName(cleanName) 
    
    -- Draw Skill Name
    surface.SetFont("DermaLarge")
    local tw, th = surface.GetTextSize(cleanName)
    draw.SimpleText(cleanName, "DermaLarge", x, y + 5, colText, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    draw.SimpleText("Press RELOAD to activate", "DermaDefault", x, y + 40, Color(200,200,200), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
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

-- Cache of active flare particles
SWEP.NiagaraFlares = SWEP.NiagaraFlares or {}
SWEP.NiagaraLensObjs = SWEP.NiagaraLensObjs or {}

function SWEP:ViewModelDrawn(vm)
    weapons.Get("weapon_ut99_base").ViewModelDrawn(self, vm) 
	self:Raven_Blade_Flare(0.4,0.5,"v_weapon.Knife_Handle") 
end 

function SWEP:CustomAmmoDisplay() 
	self.AmmoDisplay = self.AmmoDisplay or {} 
	self.AmmoDisplay.Draw = true -- draw the display? 
	self.AmmoDisplay.PrimaryClip = -1 -- amount in clip 
	-- self.AmmoDisplay.PrimaryAmmo = self:GetAttackDelay() - CurTime() -- amount in clip 
	self.AmmoDisplay.SecondaryAmmo = self:GetAttackDelay() - CurTime() -- amount in clip 
	return self.AmmoDisplay 
end 

function SWEP:DrawWorldModelTranslucent(flags) 
	local base = weapons.Get("weapon_ut99_base") 
	if base and base.DrawWorldModelTranslucent then 
		base.DrawWorldModelTranslucent(self, flags) 
	end 
	self:Raven_Blade_Flare(1.3,1.5,"ValveBiped.Bip01_R_Hand") 
end 

function SWEP:Raven_Blade_Flare(mins,maxs,bonename) 
	local ViewModel = IsValid(self:GetOwner()) and self:GetOwner().GetActiveWeapon and IsValid(self:GetOwner():GetActiveWeapon()) and IsValid(GetViewEntity()) and GetViewEntity().GetActiveWeapon and IsValid(GetViewEntity():GetActiveWeapon()) and IsValid(GetViewEntity():GetViewModel()) and self == GetViewEntity():GetActiveWeapon() 
	local renderer = ViewModel and self:GetOwner():IsPlayer() and !self:GetOwner():ShouldDrawLocalPlayer() and self:GetOwner():GetViewModel() or self 
	local handBone = renderer:LookupBone(bonename)
	if !handBone then return end

	local matrix = renderer:GetBoneMatrix(handBone)
	if !matrix then return end

	local pos = matrix:GetTranslation()
	local ang = matrix:GetAngles() 
	if ViewModel then 
		local forward = ang:Up() * 7
		pos = pos + forward
	else 
		pos = pos - ang:Up() * 9 
	end 

    local view = EyePos()
    local distSqr = pos:DistToSqr(view)
    local dist = math.sqrt(distSqr)

    -- Niagara-style distance emissive scaling
    local maxRange = 4096
    local fade = math.Clamp(dist / maxRange, 0, 1)
    local intensity = Lerp(1 - math.sqrt(fade), 1.0, 2.5)

    -- ============================================================
    -- === Flares ===
    -- ============================================================
    if not self.NextFlareSpawn or CurTime() > self.NextFlareSpawn then
        self.NextFlareSpawn = CurTime() + 0.05
        table.insert(self.NiagaraFlares, {
            pos = pos,
            life = 0,
            maxlife = 0.4 + math.Rand(0.2, 0.4),
            scale = math.Rand(mins,maxs),
            seed = math.Rand(0, 100)
        })
    end

    for i = #self.NiagaraFlares, 1, -1 do
        local p = self.NiagaraFlares[i]
        p.life = p.life + FrameTime()
        local frac = p.life / p.maxlife

        if frac >= 1 then
            table.remove(self.NiagaraFlares, i)
        else
            local fadeIn = math.Clamp(frac / 0.2, 0, 1)
            local fadeOut = 1 - math.Clamp((frac - 0.8) / 0.2, 0, 1)
            local alphaMul = fadeIn * fadeOut

            local flicker = 1 + (math.sin(CurTime() * 17.3 + p.seed) + math.sin(CurTime() * 11.8 + p.seed)) * 0.02
            local pulse = 1 + math.sin(CurTime() * 6 + p.seed) * 0.05

            local lifeScale = p.scale * pulse * flicker
            local brightness = alphaMul * intensity

            for _, layer in ipairs(flareLayers) do
                render.SetMaterial(layer.mat)
                local col = layer.color
                local size = layer.size * lifeScale
                render.DrawSprite(
                    pos,
                    size,
                    size,
                    Color(
                        col.r * brightness * layer.hardness,
                        col.g * brightness * layer.hardness,
                        col.b * brightness * layer.hardness,
                        255 * brightness
                    )
                )
            end
        end
    end

    -- ============================================================
    -- === Lens Objects ===
    -- ============================================================
    if not self.NextLensSpawn or CurTime() > self.NextLensSpawn then
        self.NextLensSpawn = CurTime() + 0.12
        table.insert(self.NiagaraLensObjs, {
            pos = pos,
            life = 0,
            maxlife = 0.8 + math.Rand(0.5, 1.2),
            scale = 1.0,
            seed = math.random(0, 100)
        })
    end

    for i = #self.NiagaraLensObjs, 1, -1 do
        local p = self.NiagaraLensObjs[i]
        p.life = p.life + FrameTime()
        local frac = p.life / p.maxlife

        if frac >= 1 then
            table.remove(self.NiagaraLensObjs, i)
        else
            -- Slower flicker and expansion over distance
            local flicker = 1.0 + math.sin(CurTime() * 1.5 + p.seed) * 0.08
            local distScale = math.Clamp(dist / 512, 0.4, 2.5)
            local scale = p.scale * distScale * flicker
            local brightness = Lerp(1 - frac, 1.4, 0.8) * intensity

            for _, layer in ipairs(lensObjLayers) do
                render.SetMaterial(layer.mat)
                local col = layer.color
                local size = layer.baseSize * scale
                local flicker2 = 1 + math.sin(CurTime() * layer.flickerSpeed + p.seed) * 0.05
                render.DrawSprite(
                    pos,
                    (size * flicker2) * 0.10,
                    (size * flicker2) * 0.15,
                    Color(
                        col.r * brightness * layer.hardness,
                        col.g * brightness * layer.hardness,
                        col.b * brightness * layer.hardness,
                        255 * brightness
                    )
                )
            end
        end
    end
end 