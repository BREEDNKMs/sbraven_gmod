AddCSLuaFile() 
list.Add( "NPCUsableWeapons", { class = "weapon_pk_rocketchaingun",	title = "Painkiller: Rocket Gatling Gun" }  ) 

SWEP.Base = "weapon_ut99_base"
SWEP.Category = "Painkiller"
SWEP.PrintName = "Rocket Gatling Gun"
SWEP.Author = "ZKiller (Refactored)"
SWEP.Purpose = "LMB to shoot a rocket, RMB to shoot bullets"

SWEP.Slot = 2
SWEP.SlotPos = 1
SWEP.Spawnable = true

SWEP.ViewModel = Model("models/weapons/CRL.mdl")
SWEP.WorldModel = Model("models/weapons/w_pkw_cg_rl.mdl")
SWEP.ViewModelFOV = 90
SWEP.DeploySound = "" 
SWEP.HoldType = "crossbow" 

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = 8
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "RPG_Round"
SWEP.Primary.Delay			= 1
SWEP.Primary.Sound			= Sound("weapon/painkiller/rocketgatling/rl_shoot.wav") 
SWEP.Primary.Projectile_Class = "ent_pk_rg_missile" 

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = 80
SWEP.Secondary.Automatic = true
SWEP.Secondary.Delay = 0.075 
SWEP.Secondary.Damage = 0 
SWEP.Secondary.Ammo = "SMG1"
SWEP.Secondary.Sound	=	Sound("weapon/painkiller/rocketgatling/mgun-mp-loop.wav") 
SWEP.Secondary.NumBullets = 2 
SWEP.Secondary.Special1 = {
	"weapon/painkiller/rocketgatling/mgun_shoot1.wav",
	"weapon/painkiller/rocketgatling/mgun_shoot2.wav",
	"weapon/painkiller/rocketgatling/mgun_shoot3.wav"
}

SWEP.DrawAmmo = true
SWEP.AdminOnly = false

SWEP.LightForward = 60 
SWEP.LightRight = 13 
SWEP.LightUp = -10 
SWEP.MuzzleName				= "ut99_mflash_minigun"
SWEP.NPC_BlockThink = true 
SWEP.SoundFireLoopStop = Sound("weapon/painkiller/rocketgatling/rotor-stop.wav") 
SWEP.CustomHolsterTime = 0.5

-- Use the UT99 base's SpecialDT to set up our Network variables
function SWEP:SpecialDT() 
	self:NetworkVar("Float", "NextAnimTime") 
	self:NetworkVar("Float", "HolsterStartTime")
end 

function SWEP:SetupWeaponHoldTypeForAI(t) 
	weapons.Get("weapon_ut99_base").SetupWeaponHoldTypeForAI(self,t) 
	self.ActivityTranslateAI[ ACT_RANGE_ATTACK1 ]	= ACT_RANGE_ATTACK_SMG1
	self.ActivityTranslateAI[ ACT_GESTURE_RANGE_ATTACK1 ]	= ACT_GESTURE_RANGE_ATTACK_SMG1
	self.ActivityTranslateAI[ ACT_RANGE_ATTACK1_LOW ]		= ACT_RANGE_ATTACK_SMG1_LOW
end 

function SWEP:Initialize() 
	self:SetDeploySpeed(5) 
	self:SetSaveValue("m_fMinRange1",200) 
	self:SetSaveValue("m_fMinRange2",0) 
	self:SetSaveValue("m_fMaxRange1",2500) 
	self:SetSaveValue("m_fMaxRange2",16384) 
	weapons.Get("weapon_ut99_base").Initialize(self) 
end 

local BobTime = 0 
local BobTimeLast = RealTime() 
local t = 1 

function SWEP:CalcViewModelView(vm, oldpos, oldang, pos, ang) 
	local targetPos = LocalToWorld(Vector(15, -12, -12), ang, pos, ang) 
    
    local targetAng = Angle(ang) -- Copy angle to avoid modifying original reference
    local offsetAng = Vector(0, 180, 0) 
    targetAng:RotateAroundAxis(targetAng:Right(), offsetAng.x) 
    targetAng:RotateAroundAxis(targetAng:Up(), offsetAng.y) 
    targetAng:RotateAroundAxis(targetAng:Forward(), offsetAng.z) 

    -- 2. Handle deploy interpolation if currently deploying
	-- print(self:GetIdleDelay()) 
    if self:GetIdleDelay() >= CurTime() and self:GetIdleDelay() ~= 0 then 
        local startPosOffset, startAngOffset = Vector(-20, -5, -20), Angle(40, 130, -20) 
        
        -- Start position and angle based on world transform
        local startPos, startAng = LocalToWorld(startPosOffset, startAngOffset, pos, ang) 
        
        local cycle = vm:GetCycle() 
		local cycle = math.TimeFraction(self:GetIdleDelay() -1, self:GetIdleDelay(), CurTime())
        cycle = math.Clamp(cycle, 0, 1)
		-- print(cycle) 
        cycle = math.ease.OutCubic(cycle) 
        
        -- Interpolate from start offset to the customized target position/angle
        pos = LerpVector(cycle, startPos, targetPos) 
        ang = LerpAngle(cycle, startAng, targetAng) 
    else
        pos = targetPos
        ang = targetAng
    end
	-- pos = LocalToWorld(Vector(10,0,0),ang,pos,ang) 
	if !IsValid(vm) then return pos,ang end 
	if !IsValid(self:GetOwner()) then return pos,ang end 
	local reg = debug.getregistry() 
	local GetVelocity = reg.Entity.GetVelocity 
	local Length = reg.Vector.Length2D 
	local vel = Length(GetVelocity(self:GetOwner())) 
	
	local bob 
	local RT = RealTime() 
	if game.SinglePlayer() then RT = CurTime() end 
	
	local cl_bobmodel_side = 0.15
	local cl_bobmodel_up = 0.055 
	local cl_bobmodel_speed = 8.7 
	local cl_viewmodel_scale = self.UTBobScale * math.Clamp(cvars.Number("ut_bobscale"), 0, 5) 

	local xyspeed = math.Clamp(vel, 0, 320) 
	
	BobTime = BobTime + (RT - BobTimeLast) * (xyspeed / 320) 
	BobTimeLast = RT 

	local s = BobTime * cl_bobmodel_speed 
	if self:GetOwner():IsOnGround() then 
		t = math.Approach(t, 1, FrameTime() * 6) 
	else 
		t = math.Approach(t, 0, FrameTime() * 3) 
	end 

	local bspeed = xyspeed * 0.01 
	bob = bspeed * cl_bobmodel_side * cl_viewmodel_scale * math.sin (10.55 + s) * t 
	local modelindex = vm:ViewModelIndex() 
	if modelindex == 0 then 
		pos = pos + bob * ang:Right() 
	else 
		pos = pos - bob * ang:Right() 
	end	
	bob = bspeed * cl_bobmodel_up * cl_viewmodel_scale * math.cos (0.45 + s *2) * t 
	pos[3] = pos[3] - bob 
	
	-- pos[3] = pos[3] + recoilpos 
	return pos, ang 
end 

-- Helper function to reliably play animations on the viewmodel
function SWEP:PlayVMSequence(name, speed)
	if !self:GetOwner().GetViewModel then return end 
	speed = speed or 1
	local vm = self:GetOwner():GetViewModel()
	if IsValid(vm) then
		local seq = vm:LookupSequence(name)
		if seq >= 0 then
			vm:SendViewModelMatchingSequence(seq)
			vm:SetPlaybackRate(speed)
		end
	end
end

function SWEP:Deploy() 
	self:SetNextSecondaryFire(CurTime()) 
	self:SetNextPrimaryFire(CurTime()) 
	if IsValid(self:GetOwner()) then 
		self:GetOwner():SetSaveValue("m_flNextAttack",0) 
	end 
	-- self:SetNextAnimTime(CurTime()) 
	self:SetSecAttack(false) 
	local deploy = weapons.Get("weapon_ut99_base").Deploy(self) 
	-- self:PlayVMSequence("crl_idle") 
	self:SetIdleDelay(CurTime()+1) 
	return deploy 
end 

function SWEP:PrimaryAttack(shootPos, shootDir) 
	if self:GetSecAttack() then return end 
	if self:GetOwner():IsPlayer() then 
		if self:GetOwner():GetAmmoCount(self.Primary.Ammo) < 1 then return end 
	end 
	shootDir = shootDir or self:GetOwner():GetAimVector() 
	shootPos = shootPos or self:GetOwner():GetShootPos() 
	local ang = shootDir:Angle() 

	self:TakeAmmo(1) 
	self:SetNextPrimaryFire(CurTime() + self.Primary.Delay) 
	self:SetNextSecondaryFire(CurTime() + self.Primary.Delay) 
	if istable(self.Primary.Sound) then 
		for k,v in ipairs(self.Primary.Sound) do 
			self:EmitSound(v,nil,nil,nil,CHAN_AUTO) 
			-- print(v) 
		end 
	else 
		self:EmitSound(self.Primary.Sound) 
	end 
	
	self:PlayVMSequence("crl_rl", 1) 
	self:SetNextAnimTime(CurTime() + self.Primary.Delay) 

	if SERVER then 
		local bolt = ents.Create(self.Primary.Projectile_Class) 
		if IsValid(bolt) then 
			bolt:SetPos(shootPos + ang:Right() * 4 + ang:Up() * -4) 
			bolt:SetAngles(ang) 
			bolt:SetOwner(self:GetOwner()) 
			bolt:Spawn() 
			bolt:Activate() 
			bolt:SetLocalVelocity(shootDir * 3200) 
		end 
	end 
	self:UTRecoil(1) 
	self:Muzzleflash() 
	self:MuzzleflashSprite(50) 
end 

function SWEP:SecondaryAttack() 
	if self:GetNextSecondaryFire() > CurTime() then return end 
	if self:GetOwner():GetAmmoCount(self:GetSecondaryAmmoType()) < 1 then return end 

	self:GetOwner():RemoveAmmo(1, self:GetSecondaryAmmoType()) 
	self:SetNextSecondaryFire(CurTime() + self.Secondary.Delay) 
	self:EmitSound(self.Secondary.Special1[math.random(1, 3)],nil,nil,nil,CHAN_AUTO)
	
	-- Minigun State activation handled in SpecialThink, but we fire bullets here 
	self:ShootBullet(self.Secondary.Damage,0,self.Secondary.NumBullets,Vector(0.03,0.02,0),self:GetShootPos(),self:GetOwner():GetAimVector()) 
	self:Muzzleflash() 
	self:MuzzleflashSprite() 
	self:UTRecoil(0.1) 
	-- self:SendWeaponAnim( ACT_VM_LOWERED_TO_IDLE )
	-- self:PlayVMSequence("crl_cshot", 2.5)
end 

function SWEP:ShootBullet(dmg, recoil, numbul, cone, shootPos, shootDir) 
	local owner = IsValid(self:GetOwner()) and self:GetOwner() or self 
	numbul 	= numbul 	or 1 
	cone 	= cone 		or 0.01 

	local bullet = {} 
	bullet.Callback = function(attacker,tr,dmginfo) 
		local ent = tr.Entity 
		local str = [[local f = Entity(]]..self:EntIndex()..[[).Chaingun_Tracer or weapons.Get("]]..self:GetClass()..[[").Chaingun_Tracer f(Entity(]]..self:EntIndex()..[[),"]]..tostring(tr.StartPos)..[[","]]..tostring(tr.HitPos)..[[",]]..tr.MatType..[[) ]] 
		BroadcastLua(str) 
		-- cast ents.FindAlongRay on this tr.StartPos and tr.HitPos 
		-- if ray table contains rpg_missile or apc_missile, deal dmginfo to them 
		local bMissileDefense = true 
		if bMissileDefense then 
			local vec1 = Vector(5,5,5) 
			local ray = ents.FindAlongRay(tr.StartPos, tr.HitPos,-vec1,vec1) 
			for k,v in pairs(ray) do 
				-- print(v,v:GetInternalVariable("m_flAugerTime"),isnumber(v:GetInternalVariable("m_flAugerTime"))) 
				-- local class = v:GetClass() 
				if v:GetInternalVariable("m_flAugerTime") then 
					local olddamage = dmginfo:GetDamage() 
					dmginfo:SetDamage(150) 
					v:DispatchTraceAttack(dmginfo,tr) 
					dmginfo:SetDamage(olddamage) 
				end 
			end 
		end 
		if IsValid(ent) then 
			local class = ent:GetClass() 
			if class == "npc_strider" then 
				local dmginfo2 = DamageInfo() 
				if (ent:Health() - dmginfo:GetDamage()) >= 0 then 
					ent:SetHealth(ent:Health() - dmginfo:GetDamage()) 
					if math.random() > 0.95 then 
						ent:RestartGesture(ACT_GESTURE_SMALL_FLINCH) 
					end 
				else 
					dmginfo:SetDamage(18) 
				end 
				-- ent:DispatchTraceAttack(dmginfo,tr) 
			elseif class == "npc_combinegunship" then 
				ent:SetSaveValue("m_flDamageAccumulator",ent:GetInternalVariable("m_flDamageAccumulator")+dmginfo:GetDamage()) 
				if ent:GetInternalVariable("m_flDamageAccumulator") > 400 then 
					dmginfo:SetDamageType(DMG_BLAST) 
					dmginfo:SetDamage(80) 
					ent:SetSaveValue("m_flDamageAccumulator",ent:GetInternalVariable("m_flDamageAccumulator") - 400) 
				end 
			end 
		end 
	end 
	bullet.Attacker = owner 
	bullet.Inflictor = self 
	bullet.Num 		= numbul 
	bullet.Src 		= shootPos or owner:GetShootPos()  
	bullet.Dir 		= shootDir or owner:GetAimVector() 
	if isvector(cone) then 
		bullet.Spread 	= cone 
	else 
		bullet.Spread 	= Vector(cone, cone, 0) 
	end 
	bullet.Tracer	= 0 
	bullet.Force	= 5 
	bullet.Damage	= dmg 
	bullet.AmmoType = "AirboatGun" 
	owner:FireBullets(bullet) 
	owner:SetAnimation(PLAYER_ATTACK1) 
end 

function SWEP:Chaingun_Tracer(startPos,hitPos,matType) 
	startPos = Vector(startPos) 
	hitPos = Vector(hitPos) 
	if IsValid(self) and IsValid(self:GetOwner()) and self:GetOwner().GetViewModel then 
		local vm = self:GetOwner():GetViewModel() 
		if IsValid(vm) then 
			-- local joint1 = vm:GetBonePosition(9) 
			-- print(joint1) 
			-- local pos, ang = self:CalcViewModelView(vm,vm:GetPos(),vm:GetAngles(),vm:GetPos(),vm:GetAngles()) 
			local ang = self:GetOwner():EyeAngles() 
			startPos = startPos + (ang:Forward()*1)
			startPos = startPos + (ang:Right()*7)
			startPos = startPos + (ang:Up()*-10)
			-- print(pos) 
			-- startPos = startPos + pos 
		end 
	end 
	local speed = 8000 
	local ent = ClientsideModel("models/props_c17/FurnitureDrawer001a_Shard01.mdl",RENDERGROUP_BOTH) 
	ent:SetPos(startPos) 
	ent:SetAngles((hitPos-startPos):Angle()) 
	ent:SetAngles(ent:GetAngles()+Angle(90,0,0)) 
	-- ent:SetModelScale(0.2) 
	ent:SetMaterial("white_outline") 
	ent:SetMoveType(MOVETYPE_FLY) 
	-- ent:PhysicsInit(SOLID_VPHYSICS) 
	-- ent:SetSolid(0) 
	ent:PhysWake() 
	ent:SetLocalVelocity(ent:GetUp()*speed) 
	local phys = ent:GetPhysicsObject() 
	if IsValid(phys) then 
		phys:SetVelocity(ent:GetUp()*speed) 
		phys:EnableCollisions(false) 
		phys:EnableGravity(false) 
		phys:EnableDrag(false) 
	end 
	
	ent.Tracer_Think = { Outer = ent } 
	ent.Tracer_Think.IsValid = function() return IsValid(ent) and ent.Tracer_Think end 
	hook.Add("Think",ent.Tracer_Think,function() 
		ent:SetPos(ent:GetPos() + ent:GetVelocity()*FrameTime()) 
		-- print(ent,ent:GetVelocity()) 
	end) 
	
	
	-- Remove the tracer when it should reach the destination.
    -- Add a small buffer to account for frame timing.
    local distance   = startPos:Distance(hitPos)
    local travelTime = (distance / speed) + FrameTime() * 2

    SafeRemoveEntityDelayed(ent, travelTime) 
	-- print(matType,matType == MAT_METAL or matType == MAT_COMPUTER or matType == MAT_VENT) 
	if matType == MAT_METAL or matType == MAT_COMPUTER or matType == MAT_VENT then 
		local muzzleflash1_hl1 = Material("sprites/muzzleflash1_hl1") 
		muzzleflash1_hl1:SetInt("$spriterendermode",5) 
		local muzzleflash2_hl1 = Material("sprites/muzzleflash2_hl1") 
		muzzleflash2_hl1:SetInt("$spriterendermode",5) 
		local muzzleflash3_hl1 = Material("sprites/muzzleflash3_hl1") 
		muzzleflash3_hl1:SetInt("$spriterendermode",5) 
		local particles = { "sprites/muzzleflash1_hl1", "sprites/muzzleflash2_hl1", "sprites/muzzleflash3_hl1" } 
		local particle = particles[math.random(1,#particles)] 
		local emitter = ParticleEmitter(hitPos) 
		local particle = emitter:Add(particle,hitPos) 
		particle:SetStartSize(math.random(16,32)) 
		particle:SetDieTime(0.1) 
		particle:SetStartAlpha(255) 
		emitter:Finish() 
	end 
end 

function SWEP:Reload()
    local ply = self:GetOwner()
    if !IsValid(ply) then return end

    local primaryID   = self:GetPrimaryAmmoType()
    local secondaryID = self:GetSecondaryAmmoType()

    local primaryName   = game.GetAmmoName(primaryID)
    local secondaryName = game.GetAmmoName(secondaryID)

    local primaryMax   = game.GetAmmoMax(primaryID)
    local secondaryMax = game.GetAmmoMax(secondaryID)

    local primaryCur   = ply:GetAmmoCount(primaryID)
    local secondaryCur = ply:GetAmmoCount(secondaryID)

    for ammoID, ammoCount in RandomPairs(ply:GetAmmo()) do

        if ammoID ~= primaryID and ammoID ~= secondaryID then

            local donorMax = game.GetAmmoMax(ammoID)

            if donorMax > 0 and ammoCount > 0 then

                ----------------------------------------------------
                -- PRIMARY
                ----------------------------------------------------
                if primaryCur < primaryMax then

                    local need = primaryMax - primaryCur

                    -- Amount of receiver ammo obtainable from donor.
                    local produced = math.floor(ammoCount / donorMax * primaryMax)

                    if produced > need then
                        produced = need
                    end

                    if produced > 0 then

                        -- donor ammo actually consumed
                        local consume = math.ceil(produced / primaryMax * donorMax)

                        consume = math.min(consume, ammoCount)

                        ply:RemoveAmmo(consume, ammoID)
                        ply:GiveAmmo(produced, primaryName, true)

                        primaryCur = primaryCur + produced
                        ammoCount = ammoCount - consume
                    end
                end

                ----------------------------------------------------
                -- SECONDARY
                ----------------------------------------------------
                if ammoCount > 0 and secondaryCur < secondaryMax then

                    local need = secondaryMax - secondaryCur

                    local produced = math.floor(ammoCount / donorMax * secondaryMax)

                    if produced > need then
                        produced = need
                    end

                    if produced > 0 then

                        local consume = math.ceil(produced / secondaryMax * donorMax)

                        consume = math.min(consume, ammoCount)

                        ply:RemoveAmmo(consume, ammoID)
                        ply:GiveAmmo(produced, secondaryName, true)

                        secondaryCur = secondaryCur + produced
                        ammoCount = ammoCount - consume
                    end
                end

                if primaryCur >= primaryMax and secondaryCur >= secondaryMax then
                    break
                end
            end
        end
    end
end

function SWEP:Think()
    if game.SinglePlayer() and CLIENT then return end

    local holsterDelay = self:GetHolsterDelay()
    if holsterDelay > 0 and holsterDelay <= CurTime() then
        if IsValid(self.Owner) and self.Owner:Alive() and self.Owner:GetActiveWeapon() == self and self:CanHolster() then
            local wep = self:GetNewWeapon()
            if IsValid(wep) then
                self:SetBeingHolster(true)
                if game.SinglePlayer() then
                    self.Owner:SelectWeapon(wep:GetClass())
                elseif CLIENT and IsFirstTimePredicted() then
                    input.SelectWeapon(wep)
                end
            end
        else
            self:SetHolsterDelay(0)
            self:SetHolsterStartTime(0) -- Reset start time if canceled
        end
    end
    
    local attHolsterDelay = self:GetAttackHolsterDelay()
    if attHolsterDelay > 0 and attHolsterDelay <= CurTime() then
        self:SetAttackHolsterDelay(0)
        local wep = self:GetNewWeapon()
        if IsValid(wep) then
            self:Holster(wep)
        end
    end
    
    self:SpecialThink()
    
    -- local idle = self:GetIdleDelay()
	-- print(idle) 
    -- if idle > 0 and CurTime() > idle then
        -- self:SetIdleDelay(0)
        -- self:SendWeaponAnim(ACT_VM_IDLE)
    -- end
end

-- Replaces all hooks and timers
function SWEP:SpecialThink()
	if !IsValid(self:GetOwner()) then return end
	local vm = self:GetOwner():GetViewModel()
	-- print(vm:GetSequence()) 

	local isMoving = self:GetOwner():GetVelocity():Length2D() > 24
	local holdingAlt = self:GetOwner():KeyDown(IN_ATTACK2)
	local canAltFire = self:GetOwner():GetAmmoCount(self.Secondary.Ammo) > 0
	-- print("CurTime:",CurTime()) 
	-- print("isMoving:",isMoving) 
	-- print("holdingAlt:",holdingAlt) 
	-- print("canAltFire:",canAltFire) 

	-- 1. Handle Minigun Winding and Sound Loops
	if holdingAlt and canAltFire and self:GetNextPrimaryFire() <= CurTime() then
		if not self:GetSecAttack() then
			self:SetSecAttack(true)
			self:PlayVMSequence("crl_cshot", 4.5)
			
			if SERVER or (CLIENT and IsFirstTimePredicted()) then
				if not self.WeaponLoop then
					self.WeaponLoop = CreateSound(self, self.Secondary.Sound)
				end
				self.WeaponLoop:Play()
			end
		end
	else
		-- Stop Minigun if we were firing but are no longer holding M2 or ran out of ammo
		if self:GetSecAttack() then
			self:SetSecAttack(false)
			self:PlayVMSequence("crl_endshot", 3)
			self:SetNextAnimTime(CurTime() + 1.8) -- Accounts for wind down animation
			
			if self.WeaponLoop then self.WeaponLoop:Stop() end
			self:EmitSound(self.SoundFireLoopStop)
		
		else 
			-- print(vm:GetSequence(),CurTime(),self:GetNextPrimaryFire()) 
			if vm:GetSequence() == 0 then 
				local flNextAttack = self:GetNextPrimaryFire() 
				if CurTime() >= flNextAttack and vm:GetPlaybackRate() > 1 then 
					-- print("set",CurTime(),self:GetNextPrimaryFire()) 
					vm:SetPlaybackRate(1) 
				end 
				-- self:PlayVMSequence("crl_idle") 
			end 
		end 
	end

	-- 2. Handle Idle and Walking Transitions
	if not self:GetSecAttack() and self:GetNextAnimTime() <= CurTime() then
		
		if IsValid(vm) then
			local currentSeq = vm:GetSequenceName(vm:GetSequence())
			
			if isMoving then
				if currentSeq ~= "crl_walk" and currentSeq ~= "CRL_walk" then
					self:PlayVMSequence("crl_walk")
				end
			else
				if currentSeq ~= "crl_idle" and currentSeq ~= "CRL_idle" then
					self:PlayVMSequence("crl_idle")
				end
			end
		end
	end
end 

function SWEP:NPCShoot_Primary(shootPos, shootDir) 
	if !self:GetSecAttack() then 
		local enemy = self:GetOwner():GetEnemy() 
		if !IsValid(enemy) then return self:PrimaryAttack(shootPos, shootDir) end 
		local playermoving = enemy:IsPlayer() and (enemy:KeyDown(IN_FORWARD) or enemy:KeyDown(IN_BACK) or enemy:KeyDown(IN_MOVELEFT) or enemy:KeyDown(IN_MOVERIGHT) or enemy:GetVelocity() != vector_origin) 
		if enemy.IsMoving and enemy:IsMoving() or enemy:IsFlagSet(FL_FLY) or enemy.Classify and enemy:Classify() == CLASS_MISSILE or enemy:GetClass() == "apc_missile" or enemy:GetClass() == "rpg_missile" or playermoving then return self:NPCShoot_Secondary(shootPos,shootDir) end 
		-- primary fire 
		if CurTime() >= self:GetAttackDelay() then 
			self:SetAttackDelay(CurTime()+1) 
			return self:PrimaryAttack(shootPos, shootDir) 
		else -- npc tries to primary fire again during attack delay 
		
		end 
	else -- already in secondary attack 
		return self:NPCShoot_Secondary(shootPos, shootDir) 
	end 
end 

function SWEP:NPCShoot_Secondary(shootPos, shootDir)
	-- already firing: just refresh aim, don't rebuild sounds/hook
	if self:GetSecAttack() and self.Secondary.Outer == self then
		self.ChaingunNPC_LerpFromDir = self.CurrentShootDirection or shootDir
		self.ChaingunNPC_TargetDir = shootDir
		self.ChaingunNPC_LerpStartTime = CurTime()
		return
	end
	
	self:SetSecAttack(true) 
	self:SetSecAttackDelay(CurTime()+0.5) 
	self.CurrentShootDirection = shootDir 
	self.ChaingunNPC_LerpFromDir = shootDir 
	self.ChaingunNPC_TargetDir = shootDir 
	self.ChaingunNPC_LerpStartTime = CurTime() 
	self.ChaingunNPC_FireStartTime = CurTime() 
	self.ChaingunNPC_NextFireTime = CurTime() 

	if SERVER or (CLIENT and IsFirstTimePredicted()) then
		if not self.WeaponLoop then
			self.WeaponLoop = CreateSound(self, self.Secondary.Sound)
		end
		self.WeaponLoop:Play()
	end

	-- construct hook to maintain chaingun firing loop
	self.Secondary.Outer = self
	self.Secondary.NPCThink = function()
		if not self.Secondary:IsValid() then
			hook.Remove("Think", self.Secondary)
			return
		end

		if not self:ChaingunNPC_ShouldMaintainFire() then
			self:ChaingunNPC_StopFire()
			return
		end

		self:ChaingunNPC_MaintainFire()
	end
	hook.Add("Think", self.Secondary, self.Secondary.NPCThink)
end

function SWEP.Secondary:IsValid()
	local weapon = self.Outer

	if not IsValid(weapon) then return false end

	local owner = weapon:GetOwner()
	if not IsValid(owner) or not owner:IsNPC() then
		weapon:ChaingunNPC_StopFire()
		return false
	end

	if not owner:Alive() then
		weapon:ChaingunNPC_StopFire()
		return false
	end

	if weapon.Secondary.ClipSize > 0 and weapon:Clip2() <= 0 then
		weapon:ChaingunNPC_StopFire()
		return false
	end

	return true
end

-- Maintain the chaingun behavior
function SWEP:ChaingunNPC_MaintainFire()
	if not self.ChaingunNPC_FireStartTime then self.ChaingunNPC_FireStartTime = CurTime() end

	local npc = self:GetOwner()
	-- lerp fraction based on elapsed time since the last NPCShoot_Secondary call
	local lerpStart = self.ChaingunNPC_LerpStartTime or CurTime()
	local frac = math.Clamp((CurTime() - lerpStart) / 0.1, 0, 1)

	local fromDir = self.ChaingunNPC_LerpFromDir or self.CurrentShootDirection or npc:GetAimVector()
	local toDir = self.ChaingunNPC_TargetDir or self.CurrentShootDirection or npc:GetAimVector()

	self.CurrentShootDirection = LerpVector(frac, fromDir, toDir)

	-- Fire bullets respecting the secondary attack delay
	if CurTime() >= (self.ChaingunNPC_NextFireTime or 0) then

		self:EmitSound(npc:GetActiveWeapon().Secondary.Special1[math.random(1, 3)])
		
		-- Use the original secondary attack bullet functionality
		self:ShootBullet(self.Secondary.Damage, 0, self.Secondary.NumBullets, Vector(0.03, 0.02, 0), self:GetShootPos(), self.CurrentShootDirection)
		self:Muzzleflash()
		self:MuzzleflashSprite()
		
		self.ChaingunNPC_NextFireTime = CurTime() + 0.075
	end
end 

-- Check if NPC has required conditions to maintain the fire
function SWEP:ChaingunNPC_ShouldMaintainFire()
	local npc = self:GetOwner()
	if not IsValid(npc) or not npc:IsNPC() then
		return false
	end
	
	if self:GetSecAttackDelay() > CurTime() then return true end 

	local conditions = {
		13, -- COND.ENEMY_OCCLUDED
		12, -- COND.ENEMY_WENT_NULL
		50, -- COND.HEAR_DANGER
		39, -- COND.TOO_FAR_TO_ATTACK
		42, -- COND.WEAPON_BLOCKED_BY_FRIEND
		43, -- COND.WEAPON_PLAYER_IN_SPREAD
		44, -- COND.WEAPON_PLAYER_NEAR_TARGET
		45  -- COND.WEAPON_SIGHT_OCCLUDED
	}

	for _, cond in ipairs(conditions) do
		if npc:HasCondition(cond) then
			-- print(cond) 
			return false
		end 
	end 
	if npc:GetNPCState() == NPC_STATE_IDLE or npc:GetNPCState() == NPC_STATE_ALERT then return false end

	return true
end

function SWEP:ChaingunNPC_StopFire() 
	self:SetSecAttack(false) 
	self.CurrentShootDirection = nil
	self.ChaingunNPC_FireStartTime = nil
	self.ChaingunNPC_NextFireTime = nil
	self.ChaingunNPC_LerpFromDir = nil
	self.ChaingunNPC_TargetDir = nil
	self.ChaingunNPC_LerpStartTime = nil
	
	if self.WeaponLoop then self.WeaponLoop:Stop() end
	self:EmitSound(self.SoundFireLoopStop)

	if self.Secondary and self.Secondary.Outer == self then
		hook.Remove("Think", self.Secondary)
		self.Secondary.Outer = nil
	end
end

-- Strictly allow holster only during idle or walk animations
function SWEP:CanHolster() 
	if !IsValid(self:GetOwner()) then return true end 
	if !self:GetOwner().GetViewModel then return true end 
	if !IsValid(self:GetOwner():GetViewModel()) then return true end
	
	local vm = self:GetOwner():GetViewModel()
	if IsValid(vm) then
		local seq = string.lower(vm:GetSequenceName(vm:GetSequence()))
		if seq == "crl_idle" or seq == "crl_walk" or seq == "crl_rl" or seq == "crl_endshot" then
			return true
		end
	end
	
	return false
end

function SWEP:Holster(wep)
    if self == wep then
        return
    end
    
    if self:GetBeingHolster() or !IsValid(wep) then
        if !self.NoOnRemoveCallOnHolster then
            self:OnRemove()
        end
        self:SetHolsterDelay(0)
        self:SetHolsterStartTime(0) -- Reset start time
        self:SetBeingHolster(false)
        self:SetNewWeapon(NULL)
        return true
    end
    
    if self.IsGuidingNuke then return false end

    if !self:CanHolster() then
        if IsValid(wep) then
            self:SetHolsterDelay(0)
            self:SetHolsterStartTime(0) -- Reset start time
            self:SetNewWeapon(wep)
            local t = self.cantholster or CurTime()
            self:SetAttackHolsterDelay(t)
        end
        return false
    end
    
    if self:GetClass() == "weapon_ut99_enforcer" and wep:GetClass() == "weapon_ut99_dualenforcers" then return true end
    
    self:DelayedHolster(wep)
    
    return false
end

-- NEW FUNCTION: Returns a float between 0 and 1 representing holster progress
function SWEP:GetHolsterCycle()
    local startTime = self:GetHolsterStartTime()
    local endTime = self:GetHolsterDelay()
    
    -- If we aren't holstering, return 0
    if startTime == 0 or endTime == 0 or startTime >= endTime then
        return 0
    end
    
    -- Calculate how far along we are and clamp it to 0-1
    local cycle = (CurTime() - startTime) / (endTime - startTime)
    return math.Clamp(cycle, 0, 1)
end

function SWEP:DelayedHolster(wep)
    if IsValid(wep) and !self:GetBeingHolster() then
        self:SetNewWeapon(wep)
        if self:GetHolsterDelay() <= CurTime() then
            self:SetIdleDelay(0)
            self:SetNextPrimaryFire(CurTime() + self.CustomHolsterTime)
            self:SetNextSecondaryFire(CurTime() + self.CustomHolsterTime)
            
            -- Removed the ACT_VM_HOLSTER animation call
            self:SpecialHolster()
            
            -- Use the custom time float instead of sequence duration
            local delay = self.CustomHolsterTime or 0.5 
            
            self:SetHolsterStartTime(CurTime()) -- Mark when we started
            self:SetHolsterDelay(CurTime() + delay)
        end
    end
end

-- Safely clean up looping sounds to prevent ghost audio
function SWEP:SpecialHolster()
	if self.WeaponLoop then self.WeaponLoop:Stop() end
end

function SWEP:OnRemove()
	if self.WeaponLoop then self.WeaponLoop:Stop() end
end

function SWEP:CanBePickedUpByNPCs()
	return true
end

function SWEP:ShouldDropOnDie()
	return false
end

function SWEP:GetNPCRestTimes()
	if self:GetSecAttack() then return 0.01, 0.01 end 
	return 0.3, 0.6
end

function SWEP:GetNPCBurstSettings()
	if self:GetSecAttack() then return 1,1,0.01 end 
	return 1, 6, 0.1
end

function SWEP:GetNPCBulletSpread(proficiency)
	return 1
end

function SWEP:GetCapabilities() return CAP_WEAPON_RANGE_ATTACK1 + CAP_WEAPON_RANGE_ATTACK2 end 

-- scripted_ents.Alias("weapon_rpg","weapon_pk_rocketchaingun") 