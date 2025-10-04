AddCSLuaFile() 

SWEP.Base = "weapon_ut99_base" 
SWEP.Category = "Other" 
SWEP.PrintName = "Raven Blade" 
SWEP.Author = "DevilHawk" 
SWEP.Purpose = "Samurai sword that teleports holder with right click." 
SWEP.Spawnable = true 

SWEP.Slot = 1 
SWEP.SlotPos = 2 

SWEP.DeploySound = "unreali/blade1s.wav" 

SWEP.HoldType			= "knife" 
SWEP.ViewModel = Model( "models/unreali/u4et/v_katana.mdl" ) 
SWEP.WorldModel = Model( "models/stellarblade/ch_m_na_53_weapon.mdl" ) 
SWEP.ViewModelFOV = 90 
SWEP.ViewModelFlip = false 

SWEP.Primary.Animation = ACT_VM_PRIMARYATTACK 
SWEP.Primary.Automatic = true 
SWEP.Primary.ClipSize = -1 
SWEP.Primary.Damage = 1000 
SWEP.Primary.DefaultClip = -1 
SWEP.Primary.Delay			= 0		-- additive after sequenceduration  
SWEP.Primary.Playback_Rate 	= 1 -- determine anim play speed 
SWEP.Primary.Projectile_Class	=	"proj_u4et_tomshell" 
SWEP.Primary.Sound			= Sound("unreali/swing1t.wav") 

SWEP.Secondary.Animation = ACT_VM_SECONDARYATTACK 
SWEP.Secondary.Automatic = true 
SWEP.Secondary.Delay			= 0		-- additive after sequenceduration  
SWEP.Secondary.Playback_Rate 	= 1 -- determine anim play speed 
SWEP.Secondary.Sound			= Sound("") 
SWEP.Melee_HitSound	=	Sound("unreali/clawhit1s.wav") 

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
	-- self:EmitSound(self.Primary.Sound, 100, 100) 
	self:UDSound() 
	self:DisableHolster() 
	-- self:TakeAmmo() 
	self:SetIdleDelay(CurTime() + self.Primary.Delay + (Delay / self.Primary.Playback_Rate)) 
end 

function SWEP:SecondaryAttack() 
	-- if not self:CanSecondaryAttack() then return end
end 

