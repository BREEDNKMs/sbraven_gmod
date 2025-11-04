AddCSLuaFile() 

SWEP.Base = "weapon_ut99_base" 
SWEP.Category = "Other" 
SWEP.PrintName = "Raven Blade" 
SWEP.Author = "DevilHawk" 
SWEP.Purpose = "Samurai sword that teleports holder with right click." 
SWEP.Spawnable = true 

SWEP.Slot = 1 
SWEP.SlotPos = 2 
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

function SWEP:CanPrimaryAttack() return self:GetHolsterDelay() == 0 and self:GetActivity() != ACT_VM_HOLSTER end 
function SWEP:CanBePickedUpByNPCs() return false end 
function SWEP:SpecialThink() 
	if self:GetHolsterDelay() != 0 or self:GetActivity() == ACT_VM_HOLSTER then return false end 
	return weapons.Get("weapon_ugold_asmd").SpecialThink(self) 
end 
function SWEP:Deploy() return weapons.Get("weapon_ugold_automag").Deploy(self) end 
function SWEP:ShouldDropOnDie() return true end 
function SWEP:PrimaryAttack() 
	-- determine next attack time, relative with anim play rate 
	if !self:CanPrimaryAttack() then return false end 
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
	local ents = scripted_ents.Get("cycler_actor2").NPC_MeleeAttack(self,nil,nil,nil,nil,240) 
end 

function SWEP:Holster(Other) 
	-- local retVal = weapons.Get("weapon_ut99_base").Holster(self,Other) 
	return true 
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
    -- local boneID = vm:LookupBone("v_weapon.Knife_Handle")
    -- if not boneID then return end

    -- local matrix = vm:GetBoneMatrix(boneID)
    -- if not matrix then return end

    -- local pos = matrix:GetTranslation()
    -- local ang = matrix:GetAngles()
    -- local forward = ang:Up() * 7
    -- pos = pos + forward

    -- local view = EyePos()
    -- local distSqr = pos:DistToSqr(view)
    -- local dist = math.sqrt(distSqr)

    -- -- Niagara-style distance emissive scaling
    -- local maxRange = 4096
    -- local fade = math.Clamp(dist / maxRange, 0, 1)
    -- local intensity = Lerp(1 - math.sqrt(fade), 1.0, 2.5)

    -- -- ============================================================
    -- -- === Flares ===
    -- -- ============================================================
    -- if not self.NextFlareSpawn or CurTime() > self.NextFlareSpawn then
        -- self.NextFlareSpawn = CurTime() + 0.05
        -- table.insert(self.NiagaraFlares, {
            -- pos = pos,
            -- life = 0,
            -- maxlife = 0.4 + math.Rand(0.2, 0.4),
            -- scale = math.Rand(0.4, 0.5),
            -- seed = math.Rand(0, 100)
        -- })
    -- end

    -- for i = #self.NiagaraFlares, 1, -1 do
        -- local p = self.NiagaraFlares[i]
        -- p.life = p.life + FrameTime()
        -- local frac = p.life / p.maxlife

        -- if frac >= 1 then
            -- table.remove(self.NiagaraFlares, i)
        -- else
            -- local fadeIn = math.Clamp(frac / 0.2, 0, 1)
            -- local fadeOut = 1 - math.Clamp((frac - 0.8) / 0.2, 0, 1)
            -- local alphaMul = fadeIn * fadeOut

            -- local flicker = 1 + (math.sin(CurTime() * 17.3 + p.seed) + math.sin(CurTime() * 11.8 + p.seed)) * 0.02
            -- local pulse = 1 + math.sin(CurTime() * 6 + p.seed) * 0.05

            -- local lifeScale = p.scale * pulse * flicker
            -- local brightness = alphaMul * intensity

            -- for _, layer in ipairs(flareLayers) do
                -- render.SetMaterial(layer.mat)
                -- local col = layer.color
                -- local size = layer.size * lifeScale
                -- render.DrawSprite(
                    -- pos,
                    -- size,
                    -- size,
                    -- Color(
                        -- col.r * brightness * layer.hardness,
                        -- col.g * brightness * layer.hardness,
                        -- col.b * brightness * layer.hardness,
                        -- 255 * brightness
                    -- )
                -- )
            -- end
        -- end
    -- end

    -- -- ============================================================
    -- -- === Lens Objects ===
    -- -- ============================================================
    -- if not self.NextLensSpawn or CurTime() > self.NextLensSpawn then
        -- self.NextLensSpawn = CurTime() + 0.12
        -- table.insert(self.NiagaraLensObjs, {
            -- pos = pos,
            -- life = 0,
            -- maxlife = 0.8 + math.Rand(0.5, 1.2),
            -- scale = 1.0,
            -- seed = math.Rand(0, 100)
        -- })
    -- end

    -- for i = #self.NiagaraLensObjs, 1, -1 do
        -- local p = self.NiagaraLensObjs[i]
        -- p.life = p.life + FrameTime()
        -- local frac = p.life / p.maxlife

        -- if frac >= 1 then
            -- table.remove(self.NiagaraLensObjs, i)
        -- else
            -- -- Slower flicker and expansion over distance
            -- local flicker = 1.0 + math.sin(CurTime() * 1.5 + p.seed) * 0.08
            -- local distScale = math.Clamp(dist / 512, 0.4, 2.5)
            -- local scale = p.scale * distScale * flicker
            -- local brightness = Lerp(1 - frac, 1.4, 0.8) * intensity

            -- for _, layer in ipairs(lensObjLayers) do
                -- render.SetMaterial(layer.mat)
                -- local col = layer.color
                -- local size = layer.baseSize * scale
                -- local flicker2 = 1 + math.sin(CurTime() * layer.flickerSpeed + p.seed) * 0.05
                -- render.DrawSprite(
                    -- pos,
                    -- (size * flicker2) * 0.10,
                    -- (size * flicker2) * 0.15,
                    -- Color(
                        -- col.r * brightness * layer.hardness,
                        -- col.g * brightness * layer.hardness,
                        -- col.b * brightness * layer.hardness,
                        -- 255 * brightness
                    -- )
                -- )
            -- end
        -- end
    -- end
end

function SWEP:Initialize() 
	weapons.Get("weapon_ut99_base").Initialize(self) 
	local ef = EffectData() 
	ef:SetEntity(self) 
	ef:SetScale(0) -- sets time. 0 to make looping 
	ef:SetFlags(0) 
	util.Effect("P_D_RavenHuman_AnimTrail_Loop_01",ef) 
	util.Effect("mi_a_gpusparks_01",ef) 
	util.Effect("MI_A_Flares_01_23",ef) 
	util.Effect("ne_ribbonm",ef) 
end 

function SWEP:DrawWorldModelTranslucent(flags) 
	local base = weapons.Get("weapon_ut99_base")
	if base and base.DrawWorldModelTranslucent then
		base.DrawWorldModelTranslucent(self, flags)
	end
	self:Raven_Blade_Flare(1.3,1.5,"ValveBiped.Bip01_R_Hand") 
end 

function SWEP:Raven_Blade_Flare(mins,maxs,bonename) 
	local ViewModel = IsValid(self:GetOwner()) and IsValid(self:GetOwner():GetActiveWeapon()) and IsValid(GetViewEntity()) and IsValid(GetViewEntity():GetActiveWeapon()) and IsValid(GetViewEntity():GetViewModel()) and self == GetViewEntity():GetActiveWeapon() 
	local renderer = ViewModel and self:GetOwner():GetViewModel() or self 
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
