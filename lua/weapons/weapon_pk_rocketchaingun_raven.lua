AddCSLuaFile() 
list.Add( "NPCUsableWeapons", { class = "weapon_pk_rocketchaingun",	title = "Painkiller: Rocket Gatling Gun" }  ) 

SWEP.Base = "weapon_pk_rocketchaingun"
SWEP.Category = "Painkiller"
SWEP.PrintName = "Rocket Gatling Gun (Raven)"
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
-- SWEP.Primary.Sound			= Sound("skill/monster/raven/M_Raven_Skill_BurstAreaSlash_Impact2.wav") 
SWEP.Primary.Sound			= {Sound("skill/monster/raven/M_Raven_Skill_Projectile_BigWhoosh.wav"), Sound("skill/monster/raven/M_Raven_Skill_BurstAreaSlash_Impact2.wav"), Sound("skill/monster/raven/M_Raven_Skill_BackJumpCombo_FireImpact.wav") } 
SWEP.Primary.Projectile_Class = "ent_pk_rg_missile_raven" 

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = 80
SWEP.Secondary.Automatic = true
SWEP.Secondary.Delay = 0.075 
SWEP.Secondary.Ammo = "SMG1"
SWEP.Secondary.Damage = 5 
SWEP.Secondary.Sound	=	Sound("skill/monster/raven/M_Raven_Skill_BackJumpCombo_Loop.wav") 
SWEP.Secondary.Special1 = {
	"skill/monster/raven/M_Raven_Skill_Projectile_Hit_1.wav",
	"skill/monster/raven/M_Raven_Skill_Projectile_Hit_2.wav",
	"skill/monster/raven/M_Raven_Skill_Projectile_Hit_3.wav"
}

SWEP.DrawAmmo = true
SWEP.AdminOnly = false

SWEP.LightForward = 60 
SWEP.LightRight = 13 
SWEP.LightUp = -10 
SWEP.MuzzleName				= "ut99_mflash_minigun"
SWEP.NPC_BlockThink = true 
SWEP.SoundFireLoopStop = Sound("weapon/painkiller/rocketgatling/rotor-stop.wav") 

SWEP.humSnd_pitch_min = 60 
SWEP.humSnd_pitch_max = 100 

function SWEP:Think() 
	weapons.Get("weapon_pk_rocketchaingun").Think(self) 
	local charge = self:Chaingun_GetChargeAmount() 
	if !self.IdleSound or self.IdleSound and !self.IdleSound:IsPlaying() then 
		self.IdleSound = CreateSound(self,"skill/monster/raven/M_Raven_Skill_Projectile_Loop2.wav") 
		self.IdleSound:ChangeVolume(0) 
		if charge > 0 then 
			self.IdleSound:Play() 
		end 
	end 
	
	if self.IdleSound then 
		-- print(self:Chaingun_GetChargeAmount()) 
		if charge > 0 then 
			self.IdleSound:ChangeVolume(self:Chaingun_GetChargeAmount()) 
			local pitch = math.Remap(self:Chaingun_GetChargeAmount(),0,1,self.humSnd_pitch_min,self.humSnd_pitch_max) 
			self.IdleSound:ChangePitch(pitch) 
		else 
			self.IdleSound:Stop() 
		end 
	end 
end 

function SWEP:Holster(Other) 
	-- if self.IdleSound and self.IdleSound:IsPlaying() then 
		-- self.IdleSound:Stop() 
	-- end 
	-- if IsValid(self.Emitter) then self.Emitter:Finish() end 
	return weapons.Get("weapon_pk_rocketchaingun").Holster(self,Other) 
end 

function SWEP:OnRemove() 
	if self.IdleSound and self.IdleSound:IsPlaying() then 
		self.IdleSound:Stop() 
	end 
	if IsValid(self.Emitter) then self.Emitter:Finish() end 
	return weapons.Get("weapon_pk_rocketchaingun").OnRemove(self) 
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
	local direction = (hitPos - startPos):GetNormalized()
	local distance = startPos:Distance(hitPos)
	local travelTime = distance / speed
	-- print(travelTime,RealFrameTime(),CurTime()) 
	travelTime = math.max(travelTime,RealFrameTime()*1) 
	local travelStartTime, travelEndTime = CurTime(), CurTime() + travelTime 
	
	local emitter = ParticleEmitter(hitPos,false) 
	
	--==============================================================
	-- SPRITE CULLING: manual clipped rendering
	--
	-- The spark sprites below ("effects/spark") are drawn with
	-- SetVelocityScale + a stretched length, so at high travel speed
	-- their tails can poke out past startPos (behind the muzzle) for
	-- a frame or two. That reads fine locally but looks wrong for
	-- other players watching the tracer. Instead of letting the
	-- emitter auto-draw every frame, we disable its automatic draw,
	-- and manually draw it ourselves inside PostDrawEffects
	-- with a clip plane at startPos so nothing behind the muzzle
	-- (opposite the travel direction) ever gets rendered.
	--==============================================================
	emitter:SetNoDraw(true)

	local clipDist = direction:Dot(startPos)
 
	-- Table used as the hook's "name". As long as its IsValid function
	-- returns true, the hook keeps firing; once the emitter itself goes
	-- invalid (dies out / garbage collected), IsValid() returns false
	-- and the engine removes the hook for us automatically.
	local emitterProxy = { IsValid = function(tbl)  
		if CurTime() > travelEndTime then -- dead 
			emitter:Finish() 
			return false 
		else -- alive 
			return true 
		end 
	end }
 
	hook.Add("PostDrawEffects", emitterProxy, function(self, isDrawingDepth, isDrawSkybox, isDraw3DSkybox)
		local oldClip = render.EnableClipping(true)
		render.PushCustomClipPlane(direction, clipDist)
 
		emitter:Draw()
 
		render.PopCustomClipPlane()
		render.EnableClipping(oldClip)
	end)
	
	--==============================================================
	-- 1. HOT WHITE PROJECTILE CORE
	--==============================================================
	local particle = emitter:Add("effects/spark",startPos) 
	if particle then
		particle:SetDieTime(travelTime)
		particle:SetStartSize(math.random(8,10))
		particle:SetEndSize(particle:GetStartSize())
		particle:SetStartAlpha(255)
		particle:SetEndAlpha(255)
		particle:SetVelocity(direction * speed)
		particle:SetVelocityScale(true)
		-- particle:SetStartLength(1 / speed)
		-- particle:SetEndLength(1.8)
		
		particle:SetStartLength(-0.1)
		particle:SetEndLength(-0.1)
		
		particle:SetLighting(false)
		particle:SetColor(255,255,255)
	end
	
	--==============================================================
	-- 2. SURROUNDING CYAN PROJECTILE GLOW
	--==============================================================
	local particle = emitter:Add("sprites/glow04_noz_gmod",startPos) 
	if particle then
		particle:SetDieTime(travelTime)
		particle:SetStartSize(math.random(10,12))
		particle:SetEndSize(particle:GetStartSize())
		particle:SetStartAlpha(255)
		particle:SetEndAlpha(0)
		particle:SetVelocity(direction * speed)
		particle:SetVelocityScale(true)
		-- particle:SetStartLength(1 / speed)
		-- particle:SetEndLength(2.1)
		
		particle:SetStartLength(-0.1)
		particle:SetEndLength(-2)
		
		particle:SetLighting(false)
		particle:SetColor(math.random(0,50),math.random(225,255),math.random(225,255))
	end
	
	--==============================================================
	-- 2.5. TRAILING HEATWAVE BLUR 
	--==============================================================
	local particle = emitter:Add("effects/hunterphysblast",startPos) 
	if particle then
		particle:SetDieTime(travelTime)
		particle:SetStartSize(0.5)
		particle:SetEndSize(0)
		particle:SetStartAlpha(255)
		particle:SetEndAlpha(0)
		particle:SetVelocity(direction * speed)
		particle:SetVelocityScale(true)
		-- particle:SetStartLength(1 / speed)
		-- particle:SetEndLength(2.1)
		
		particle:SetStartLength(-0.1)
		particle:SetEndLength(-2.2)
		
		particle:SetLighting(false)
		particle:SetColor(math.random(0,50),math.random(225,255),math.random(225,255))
	end
	
	--==============================================================
	-- 3. CHROMACROSS AT EVERY SHOT'S IMPACT
	--==============================================================
	local particle = emitter:Add("sprites/MI_B_LensCircle_01_15_AfterDof",hitPos)
	if particle then
		particle:SetDieTime(0.12)
		particle:SetStartSize(math.random(28,44))
		particle:SetEndSize(0)
		particle:SetStartAlpha(255)
		particle:SetEndAlpha(0)
		particle:SetLighting(false)
		particle:SetRoll(math.Rand(0,math.pi * 2))
	end
	
	-- Small secondary chroma crosses give the impact more of the
	-- dense Stellar Blade-style flare/spark appearance.
	for i = 1,2 do
		local pos = hitPos + VectorRand() * math.Rand(2,5)
		local particle = emitter:Add("sprites/MI_B_LensCircle_01_15_AfterDof",pos)
		if particle then
			particle:SetDieTime(math.Rand(0.06,0.1))
			particle:SetStartSize(math.random(8,18))
			particle:SetEndSize(0)
			particle:SetStartAlpha(math.random(150,230))
			particle:SetEndAlpha(0)
			particle:SetLighting(false)
			particle:SetRoll(math.Rand(0,math.pi * 2))
		end
	end
	
	--==============================================================
	-- 4. CYAN-WHITE IMPACT SPARK STORM
	--==============================================================
	local sparkCount = (matType == MAT_METAL or matType == MAT_COMPUTER or matType == MAT_VENT) and 50 or 20
	
	for i = 1,sparkCount do
		local particle = emitter:Add("effects/spark",hitPos)
		if particle then
			particle:SetDieTime(math.Rand(0.12,0.3))
			particle:SetStartSize(math.Rand(3,8))
			particle:SetEndSize(0)
			particle:SetStartAlpha(math.Rand(180,255))
			particle:SetEndAlpha(0)
			particle:SetLighting(false)
			
			local velocity = VectorRand():GetNormalized()
			particle:SetVelocity(velocity * math.Rand(180,500))
			particle:SetVelocityScale(true)
			particle:SetStartLength(0.02)
			particle:SetEndLength(0.02)
			
			particle:SetColor(
				math.random(80,180),
				math.random(230,255),
				255
			)
		end
	end
	
	--==============================================================
	-- 5. EXTRA HOT WHITE CENTER ON HARD SURFACES
	--==============================================================
	if matType == MAT_METAL or matType == MAT_COMPUTER or matType == MAT_VENT then
		local particle = emitter:Add("sprites/glow04_noz_gmod",hitPos)
		if particle then
			particle:SetDieTime(0.2)
			particle:SetStartSize(math.random(18,28))
			particle:SetEndSize(0)
			particle:SetStartAlpha(255)
			particle:SetEndAlpha(0)
			particle:SetLighting(false)
			particle:SetColor(255,255,255)
			local color_r = 255 
			particle:SetThinkFunction(function(p) 
				local Cycle = p:GetLifeTime() / p:GetDieTime() 
				color_r = 1-Cycle 
				color_r = color_r * 255 
				particle:SetColor(color_r,255,255) 
				particle:SetNextThink(CurTime()+FrameTime())
			end) 
		end
	end
	
	-- emitter:Finish() 
end 

function SWEP:Chaingun_GetReserveAmmoFillnessRate()
    local owner = self:GetOwner()
    
    -- If there is no valid owner, there is no reserve ammo to check
    if not IsValid(owner) then return 0 end
    
    local primaryType = self:GetPrimaryAmmoType()
    local secondaryType = self:GetSecondaryAmmoType()
    
    -- In GMod, an ammo type of -1 means "None"
    local hasPrimary = primaryType ~= -1
    local hasSecondary = secondaryType ~= -1
    
    if not hasPrimary and not hasSecondary then return 0 end
    
    local primaryFill = 0
    local secondaryFill = 0
    
    -- Calculate Primary Ammo Fillness (0 to 1)
    if hasPrimary then
        local count = owner:GetAmmoCount(primaryType)
        local max = game.GetAmmoMax(primaryType)
        
        if max and max > 0 then
            primaryFill = math.Clamp(count / max, 0, 1)
        end
    end
    
    -- Calculate Secondary Ammo Fillness (0 to 1)
    if hasSecondary then
        local count = owner:GetAmmoCount(secondaryType)
        local max = game.GetAmmoMax(secondaryType)
        
        if max and max > 0 then
            secondaryFill = math.Clamp(count / max, 0, 1)
        end
    end
    
    -- Local float defining primary ammo's weight (0.5 = 50% primary / 50% secondary)
    -- Adjust this float to change how much primary ammo influences the final value
    local primaryWeight = 0.5 
    
    -- Return the weighted average if both exist
    if hasPrimary and hasSecondary then
        return (primaryFill * primaryWeight) + (secondaryFill * (1.0 - primaryWeight))
    
    -- If only one ammo type exists, ignore the weight and just return its fillness
    elseif hasPrimary then
        return primaryFill
    elseif hasSecondary then
        return secondaryFill
    end
    
    return 0
end

function SWEP:Chaingun_GetChargeAmount() 
    local Chaingun_GetReserveAmmoFillnessRate = self:Chaingun_GetReserveAmmoFillnessRate() 
	if !IsValid(self:GetOwner()) then return 0 end 
	if self:GetOwner():GetActiveWeapon() != self then return 0 end 

    if self:GetHolsterDelay() > 0 then 
        local GetHolsterCycle = self:GetHolsterCycle() 
        local HolsterDelay = self:GetHolsterDelay() -- CurTime + delay 

        -- Calculate current cycle progress (0 = start of holster, 1 = fully holstered)
        local progress = GetHolsterCycle
        
        -- Fallback calculation if GetHolsterCycle isn't already normalized between 0 and 1:
        if not progress or progress == 0 then
            local remainingTime = HolsterDelay - CurTime()
            -- Assuming standard holster delay behavior if cycle isn't directly exposed
            progress = math.Clamp(1 - remainingTime, 0, 1)
        end

        -- Drop down the rate smoothly down to 0 as holstering completes
        Chaingun_GetReserveAmmoFillnessRate = Chaingun_GetReserveAmmoFillnessRate * math.Clamp(1 - progress, 0, 1)
		-- print(Chaingun_GetReserveAmmoFillnessRate) 
    end 
	-- print(self:GetBeingHolster(),self:GetHolsterDelay(),self:GetAttackHolsterDelay(),self:GetNewWeapon(),self:GetOwner():GetActiveWeapon()) 
	

    return Chaingun_GetReserveAmmoFillnessRate 
end

local RavenCrossMat = Material("sprites/MI_B_LensCircle_01_15_AfterDof")
local RavenCoreMat = Material("sprites/glow04_noz_gmod")
local RavenBeamMat = Material("effects/bluelaser1")

function SWEP:Muzzleflash() 

end 

function SWEP:MuzzleflashSprite(iParticles) 
	if !game.SinglePlayer() and SERVER then return end 
	iParticles = iParticles or math.random(8,14) 
	if game.SinglePlayer() and SERVER then 
		return BroadcastLua("local f = weapons.Get('"..self:GetClass().."').MuzzleflashSprite if IsValid(Entity("..self:EntIndex()..")) and f then f(Entity("..self:EntIndex().."),"..tostring(iParticles)..") end" ) 
	end 

	local matrix = self:GetOwner():GetViewModel():GetBoneMatrix(1)
	local pos,ang = matrix:GetTranslation(),matrix:GetAngles() 
	local forward, right, up = ang:Forward(), ang:Right(), ang:Up() 
	pos = pos + (forward * 30)

	local shardMat = Material("models/debug/debugwhite")
	local shardGlow = Material("sprites/glow04_noz_gmod")

	for i = 1,iParticles do
		local randModel = Model("models/gibs/glass_shard0"..math.random(1,6)..".mdl")
		local ent = ClientsideModel(randModel,RENDERGROUP_BOTH)

		if IsValid(ent) then
			local lifespan = math.Rand(0.12,0.45)

			ent:SetPos(
				pos +
				ang:Right() * math.Rand(-8,8) +
				ang:Up() * math.Rand(-8,8) +
				ang:Forward() * math.Rand(-4,4)
			)

			ent:SetAngles(AngleRand())
			ent:SetModelScale(math.Rand(0.55,1.15),0)
			ent:SetMaterial("models/debug/debugwhite")
			ent:SetRenderMode(RENDERMODE_TRANSALPHA)
			ent:SetColor(Color(180,245,255,255))
			ent:SetSolid(SOLID_NONE)
			ent:SetMoveType(MOVETYPE_FLY)
			ent:SetModelScale(0.1) 

			local initialDir = (
				ang:Forward() * math.Rand(0.15,0.8) +
				ang:Right() * math.Rand(-1,1) +
				ang:Up() * math.Rand(-1,1)
			):GetNormalized()

			local initialSpeed = math.Rand(140,420)

			ent:SetLocalVelocity(initialDir * initialSpeed)
			ent:SetLocalAngularVelocity(AngleRand(-900,900))

			ent.Tracer_Think = {Outer = ent}
			ent.Tracer_Think.CreationTime = CurTime()
			ent.Tracer_Think.NextTurnTime = CurTime()
			ent.Tracer_Think.Speed = initialSpeed
			ent.Tracer_Think.TargetDir = initialDir
			ent.Tracer_Think.IsValid = function() return IsValid(ent) and ent.Tracer_Think end 

			hook.Add("Think",ent.Tracer_Think,function()
				local ct = CurTime()
				local ft = FrameTime()
				local vel = ent:GetVelocity()

				if ct >= ent.Tracer_Think.NextTurnTime then
					local dir = vel:LengthSqr() > 0
						and vel:GetNormalized()
						or ent.Tracer_Think.TargetDir

					dir.x = dir.x + math.Rand(-0.55,0.55)
					dir.y = dir.y + math.Rand(-0.55,0.55)
					dir.z = dir.z + math.Rand(-0.55,0.55)

					ent.Tracer_Think.TargetDir = dir:GetNormalized()
					ent.Tracer_Think.NextTurnTime = ct + math.Rand(0.035,0.09)
				end

				local currentDir = vel:LengthSqr() > 0
					and vel:GetNormalized()
					or ent.Tracer_Think.TargetDir

				local newDir = LerpVector(
					math.Clamp(ft * 12,0,1),
					currentDir,
					ent.Tracer_Think.TargetDir
				):GetNormalized()

				local lifeFrac = math.Clamp(
					(ct - ent.Tracer_Think.CreationTime) / lifespan,
					0,
					1
				)

				local speed = ent.Tracer_Think.Speed * Lerp(lifeFrac,1,0.35)
				ent:SetVelocity(newDir * speed)
				ent:SetPos(ent:GetPos() + ent:GetVelocity()*FrameTime())

				local av = ent:GetLocalAngularVelocity()

				ent:SetAngles(
					ent:GetAngles() +
					Angle(
						av.p * ft,
						av.y * ft,
						av.r * ft
					)
				)

				local alpha = lifeFrac > 0.65
					and 255 * (1 - (lifeFrac - 0.65) / 0.35)
					or 255

				local cyanFrac = math.Clamp(lifeFrac * 1.5,0,1)

				ent:SetColor(Color(
					Lerp(cyanFrac,255,100),
					255,
					255,
					alpha
				))

				ent:SetNextClientThink(ct+FrameTime())
			end)

			SafeRemoveEntityDelayed(ent,lifespan)

			ent.RenderOverride = function(ent,flags)
				local lifeFrac = math.Clamp(
					(CurTime() - ent.Tracer_Think.CreationTime) / lifespan,
					0,
					1
				)

				-- Bright physical shard.
				local oldFlags = shardMat:GetInt("$flags")

				shardMat:SetInt(
					"$flags",
					bit.bor(oldFlags,64) -- turn on $selfillum 
				)

				shardMat:SetTexture(
					"$selfillummask",
					"models/debug/debugwhite"
				)

				-- render.MaterialOverride(shardMat)
				ent:DrawModel(flags)
				-- render.MaterialOverride(nil)

				shardMat:SetInt("$flags",oldFlags) -- turn off $selfillum 

				-- Cyan halo surrounding the shard.
				render.SetMaterial(shardGlow)

				local glowSize = Lerp(lifeFrac,18,4)
				local glowAlpha = 170 * (1 - lifeFrac)

				render.DrawSprite(
					ent:GetPos(),
					glowSize,
					glowSize,
					Color(80,235,255,glowAlpha)
				)

				-- White-hot center.
				render.DrawSprite(
					ent:GetPos(),
					glowSize * 0.42,
					glowSize * 0.42,
					Color(255,255,255,glowAlpha)
				)
			end
		end
	end
	
	-- print("in CLIENT") 
end 

function SWEP:PreDrawViewModel(vm,weapon,ply,flags) 
	if !self.Chaingun_material then 
		self.Chaingun_material = Material(vm:GetMaterials()[1]) 
	end 

	local charge = math.Clamp(self:Chaingun_GetChargeAmount(),0,1) 

	-- VMT handles the dark internal weapon parts / emissive response.
	self.Chaingun_material:SetFloat("$emissiveblendstrength",charge) 
	self.Chaingun_material:SetInt("$emissiveblendenabled",1) 
	self.Chaingun_material:SetInt("$rimlight",1) 
	self.Chaingun_material:SetFloat("$rimlightboost",charge*2) 
	self.Chaingun_material:SetVector("$phongtint",Vector(0,1,1)) 
	self.Chaingun_material:SetTexture("$emissiveblendtexture","vgui/white") -- required placeholder 
	self.Chaingun_material:SetTexture("$emissiveblendbasetexture","models/weapons/crl_e") -- emissive pattern 
	self.Chaingun_material:SetTexture("$emissiveblendflowtexture","vgui/white") -- static, no flow 
	self.Chaingun_material:SetVector("$emissiveblendtint",Vector(0,1,1)) 
	self.Chaingun_material:SetVector("$emissiveblendscrollvector",Vector(0,0,0)) 
end 

function SWEP:PostDrawViewModel(vm,weapon,ply,flags)
	if !IsValid(vm) then return end

	local charge = math.Clamp(self:Chaingun_GetChargeAmount(),0,1)

	-- Turn the VMT emissive back off when this VM is finished drawing.
	if self.Chaingun_material then 
		self.Chaingun_material:SetFloat("$emissiveblendstrength",0)
		self.Chaingun_material:SetInt("$rimlight",0) 
		self.Chaingun_material:SetFloat("$rimlightboost",0) 
		self.Chaingun_material:SetVector("$phongtint",Vector(1,1,1)) 
	end 

	local matrix = vm:GetBoneMatrix(0) 
	local pos = matrix:GetTranslation() 
	local ang = matrix:GetAngles() 
	local forward = ang:Forward()
	local right = ang:Right()
	local up = ang:Up()

	--==============================================================
	-- ENERGY HEART
	--==============================================================

	-- Reposition this later to the actual barrel/core center.
	local corePos =
		pos +
		forward * 18 +
		right * -0.8 +
		up * 1

	-- Charge controls pulse amplitude.
	local pulseSpeed = Lerp(charge,3,18)
	local pulse = 0.5 + math.sin(CurTime() * pulseSpeed) * 0.5
	local pulse2 = 0.5 + math.sin(CurTime() * pulseSpeed * 1.7 + 1.2) * 0.5

	-- White hot center -> cyan outer glow.
	local coreSize = Lerp(charge,10,30) + pulse * Lerp(charge,2,8)
	local coreAlpha = Lerp(charge,70,255)
	coreSize = coreSize * 0.7 

	render.SetMaterial(RavenCoreMat)

	render.DrawSprite(
		corePos,
		coreSize,
		coreSize,
		Color(255,255,255,coreAlpha)
	)

	render.DrawSprite(
		corePos,
		coreSize * 1.8,
		coreSize * 1.8,
		Color(0,220,255,coreAlpha * 0.35)
	)


	--==============================================================
	-- ROTATING CYAN ENERGY RING
	--==============================================================

	-- Ring remains subtle at low charge and becomes almost white
	-- at maximum charge.
	local ringRadius = Lerp(charge,3.5,9)
	local ringWidth = Lerp(charge,0.5,2.5)

	local ringSegments = 20
	local ringRot = CurTime() * Lerp(charge,1,12)

	render.SetMaterial(RavenBeamMat)

	for i = 0,ringSegments - 1 do
		local a1 = ringRot + (i / ringSegments) * math.pi * 2
		local a2 = ringRot + ((i + 1) / ringSegments) * math.pi * 2

		local p1 =
			corePos +
			right * math.cos(a1) * ringRadius +
			up * math.sin(a1) * ringRadius

		local p2 =
			corePos +
			right * math.cos(a2) * ringRadius +
			up * math.sin(a2) * ringRadius

		-- Slightly vary brightness around the ring.
		local segmentPulse =
			0.65 +
			math.sin(CurTime() * pulseSpeed + i * 0.8) * 0.35

		local brightness =
			Lerp(charge,50,255) * segmentPulse

		render.DrawBeam(
			p1,
			p2,
			ringWidth,
			0,
			1,
			Color(
				Lerp(charge,0,180),
				brightness,
				255,
				Lerp(charge,70,255)
			)
		)
	end

	
	--==============================================================
	-- RADIAL ENERGY SUPPORT BEAMS
	--==============================================================

	render.SetMaterial(Material("effects/blueblacklargebeam"))
	local beamCount = math.floor(Lerp(charge,1,10))
	local beamLength = Lerp(charge,4,14)
	local beamWidth = Lerp(charge,0.4,2)

	for i = 1,beamCount do
		local angle =
			CurTime() * Lerp(charge,0.5,8) +
			i * (math.pi * 2 / beamCount)
			
		local angle =
			CurTime() * Lerp(charge,0.5,8) +
			i * (math.pi * 2 / beamCount)
			-- print(i,angle) 
			
		local angle_cos = math.cos(angle)
		local angle_sin = math.sin(-angle)

		local dir = right * angle_cos + up * angle_sin
			-- print(i,dir,type(dir)) 

		local beamStart = corePos + dir * ringRadius
		local beamEnd = corePos + dir * (ringRadius + beamLength)
		local beamStart = corePos + (forward * -11) + (dir*6)  
		local beamEnd = corePos + (forward * 0.5) + (dir*6)
		-- if i == 1 then 
			-- debugoverlay.Cross(beamEnd,5,FrameTime()*2) 
			-- print(i,angle_cos,angle_sin) 
		-- end 
		if angle_cos > 0.8 then 

		render.DrawBeam(
			beamStart,
			beamEnd,
			beamWidth,
			0,
			1,
			Color(
				255,
				255,
				255,
				Lerp(charge,40,255)
			)
		)
		end 
	end


	--==============================================================
	-- CHROMACROSS / ENERGY SPARKS
	--==============================================================

	if charge > 0.01 then
		local emitterPos = corePos

		if !IsValid(self.Emitter) then
			self.Emitter = ParticleEmitter(emitterPos,false)
		end

		local charge = math.Clamp(self:Chaingun_GetChargeAmount(),0,1)

		-- Higher charge = more frequent particle creation.
		local sparks = charge < 0.95 or math.random() > charge -- or chromaCross 
		local spawnInterval = sparks and Lerp(charge,0.20,0.025) or Lerp(charge,0.80,0.2)

		if !self.RavenNextCrossTime or CurTime() >= self.RavenNextCrossTime then
			self.RavenNextCrossTime = CurTime() + spawnInterval

			--==========================================================
			-- LOW/MID CHARGE : WANDERING ENERGY SPARK
			--==========================================================

			if sparks then
				local offset =
					right * math.Rand(-5,5) +
					up * math.Rand(-5,5) +
					forward * math.Rand(-3,3)

				local pos = corePos + offset
				local p = self.Emitter:Add("effects/spark",pos)

				if p then
					local initialSpeed = Lerp(charge,35,110)
					local initialDir = VectorRand():GetNormalized()

					p:SetVelocity(initialDir * initialSpeed)
					p:SetDieTime(math.Rand(
						Lerp(charge,0.35,0.15),
						Lerp(charge,0.75,0.3)
					))
					p:SetStartAlpha(255)
					p:SetEndAlpha(0)
					p:SetStartSize(Lerp(charge,2,4))
					p:SetEndSize(0)
					p:SetColor(
						Lerp(charge,0,120),
						255,
						255
					)
					p:SetGravity(initialDir * Lerp(charge,20,80))
					p:SetStartLength(0.1)
					p:SetEndLength(0)
					p:SetVelocityScale(true)

					p.CreationTime = CurTime()
					p.NextTurnTime = CurTime()
					p.Speed = initialSpeed
					p.TargetDir = initialDir

					p:SetThinkFunction(function(prt)
						if !prt then return end

						local ct = CurTime()
						local ft = FrameTime()

						if ct >= prt.NextTurnTime then
							local dir = prt:GetVelocity():GetNormalized()

							dir.x = dir.x + 0.7 * (0.5 - math.random())
							dir.y = dir.y + 0.7 * (0.5 - math.random())
							dir.z = dir.z + 0.7 * (0.5 - math.random())

							prt.TargetDir = dir:GetNormalized()
							prt.NextTurnTime = ct + math.Rand(0.08,0.18)
						end

						local currentVel = prt:GetVelocity()
						local currentDir = currentVel:Length() > 0 and currentVel:GetNormalized() or prt.TargetDir

						local turnSpeed = Lerp(charge,7,15)
						local newDir = LerpVector(
							math.Clamp(ft * turnSpeed,0,1),
							currentDir,
							prt.TargetDir
						):GetNormalized()

						prt:SetVelocity(newDir * prt.Speed)

						local motionAng = newDir:Angle()
						prt:SetAngles(motionAng)
						prt:SetRoll(motionAng.y * (math.pi / 180))

						local interval = prt:GetLifeTime() / prt:GetDieTime()

						-- Become increasingly white as it approaches death.
						local cyan = 1 - interval
						prt:SetColor(
							255 * (1 - cyan) * 0.45,
							220 + 35 * cyan,
							255
						)

						prt:SetNextThink(ct)
					end)

					p:SetNextThink(CurTime())
				end

			--==========================================================
			-- HIGH CHARGE : RAPIDLY PULSING CHROMACROSS
			--==========================================================

			else
				local offset =
					right * math.Rand(-10,10) +
					up * math.Rand(-10,10) +
					forward * math.Rand(-0,40)

				local pos = corePos + offset

				local p = self.Emitter:Add(
					"sprites/MI_B_LensCircle_01_15_AfterDof",
					pos
				)

				if p then
					local dieTime = math.Rand(0.05,0.75)

					p:SetDieTime(dieTime)
					p:SetStartAlpha(0)
					p:SetEndAlpha(0)
					p:SetStartSize(0)
					p:SetEndSize(0)
					p:SetLighting(false)
					p:SetRoll(math.Rand(0,math.pi * 2))
					p:SetColor(150,255,255)
					p:SetVelocity(VectorRand()*100) 

					p.CreationTime = CurTime()

					p:SetThinkFunction(function(prt)
						if !prt then return end

						local life = prt:GetLifeTime()
						local die = prt:GetDieTime()

						if die <= 0 then return end

						local fraction = life / die

						-- Full pulse cycles during the particle's short lifetime.
						local cycles = Lerp(charge,2,5)

						local pulse = math.sin(
							fraction * math.pi * 2 * cycles
						)

						-- Convert -1..1 into 0..1.
						pulse = pulse * 0.5 + 0.5

						-- Stronger charge = larger/brighter cross.
						local size =
							pulse *
							Lerp(charge,0,8)

						local alpha =
							pulse *
							Lerp(charge,100,255)

						prt:SetStartSize(size)
						prt:SetEndSize(size)
						prt:SetStartAlpha(alpha)
						prt:SetEndAlpha(alpha)

						-- White core at pulse maximum, cyan otherwise.
						local white = pulse * charge

						prt:SetColor(
							Lerp(white,80,255),
							255,
							255
						)

						prt:SetRoll(
							prt:GetRoll() +
							FrameTime() * Lerp(charge,2,12)
						)

						prt:SetNextThink(CurTime())
					end)

					p:SetNextThink(CurTime())
				end
			end
		end
	end
end

function SWEP:DrawWorldModel(flags) 
	if !self.Chaingun_wmaterial then 
		self.Chaingun_wmaterial = Material(self:GetMaterials()[1]) 
	end 

	local charge = math.Clamp(self:Chaingun_GetChargeAmount(),0,1) 

	-- VMT handles the dark internal weapon parts / emissive response.
	self.Chaingun_wmaterial:SetFloat("$emissiveblendstrength",charge) 
	self.Chaingun_wmaterial:SetInt("$emissiveblendenabled",1) 
	self.Chaingun_wmaterial:SetInt("$rimlight",1) 
	self.Chaingun_wmaterial:SetFloat("$rimlightboost",charge*2) 
	self.Chaingun_wmaterial:SetVector("$phongtint",Vector(0,1,1)) 
	self.Chaingun_wmaterial:SetTexture("$emissiveblendtexture","vgui/white") -- required placeholder 
	self.Chaingun_wmaterial:SetTexture("$emissiveblendbasetexture","models/weapons/crl_item_texture_e2") -- emissive pattern 
	self.Chaingun_wmaterial:SetTexture("$emissiveblendflowtexture","vgui/white") -- static, no flow 
	self.Chaingun_wmaterial:SetVector("$emissiveblendtint",Vector(0,1,1)) 
	self.Chaingun_wmaterial:SetVector("$emissiveblendscrollvector",Vector(0,0,0)) 
	
	self:DrawModel(flags) 
	
	-- Turn the VMT emissive back off when this VM is finished drawing.
	if self.Chaingun_wmaterial then 
		self.Chaingun_wmaterial:SetFloat("$emissiveblendstrength",0)
		self.Chaingun_wmaterial:SetInt("$rimlight",0) 
		self.Chaingun_wmaterial:SetFloat("$rimlightboost",0) 
		self.Chaingun_wmaterial:SetVector("$phongtint",Vector(1,1,1)) 
	end 
	self:DrawVisuals(self) 
end 

function SWEP:DrawVisuals(vm) 
	local charge = math.Clamp(self:Chaingun_GetChargeAmount(),0,1) 
	local matrix = vm:GetBoneMatrix(0) 
	local pos = matrix:GetTranslation() 
	local ang = matrix:GetAngles() 
	local forward = ang:Forward()
	local right = ang:Right()
	local up = ang:Up()

	--==============================================================
	-- ENERGY HEART
	--==============================================================

	-- Reposition this later to the actual barrel/core center.
	local corePos =
		pos +
		forward * 18 +
		right * -0.8 +
		up * 1

	-- Charge controls pulse amplitude.
	local pulseSpeed = Lerp(charge,3,18)
	local pulse = 0.5 + math.sin(CurTime() * pulseSpeed) * 0.5
	local pulse2 = 0.5 + math.sin(CurTime() * pulseSpeed * 1.7 + 1.2) * 0.5

	-- White hot center -> cyan outer glow.
	local coreSize = Lerp(charge,10,30) + pulse * Lerp(charge,2,8)
	local coreAlpha = Lerp(charge,70,255)
	coreSize = coreSize * 0.7 

	render.SetMaterial(RavenCoreMat)

	render.DrawSprite(
		corePos,
		coreSize,
		coreSize,
		Color(255,255,255,coreAlpha)
	)

	render.DrawSprite(
		corePos,
		coreSize * 1.8,
		coreSize * 1.8,
		Color(0,220,255,coreAlpha * 0.35)
	)


	--==============================================================
	-- ROTATING CYAN ENERGY RING
	--==============================================================

	-- Ring remains subtle at low charge and becomes almost white
	-- at maximum charge.
	local ringRadius = Lerp(charge,3.5,9)
	local ringWidth = Lerp(charge,0.5,2.5)

	local ringSegments = 20
	local ringRot = CurTime() * Lerp(charge,1,12)

	render.SetMaterial(RavenBeamMat)

	for i = 0,ringSegments - 1 do
		local a1 = ringRot + (i / ringSegments) * math.pi * 2
		local a2 = ringRot + ((i + 1) / ringSegments) * math.pi * 2

		local p1 =
			corePos +
			right * math.cos(a1) * ringRadius +
			up * math.sin(a1) * ringRadius

		local p2 =
			corePos +
			right * math.cos(a2) * ringRadius +
			up * math.sin(a2) * ringRadius

		-- Slightly vary brightness around the ring.
		local segmentPulse =
			0.65 +
			math.sin(CurTime() * pulseSpeed + i * 0.8) * 0.35

		local brightness =
			Lerp(charge,50,255) * segmentPulse

		render.DrawBeam(
			p1,
			p2,
			ringWidth,
			0,
			1,
			Color(
				Lerp(charge,0,180),
				brightness,
				255,
				Lerp(charge,70,255)
			)
		)
	end

	
	--==============================================================
	-- RADIAL ENERGY SUPPORT BEAMS
	--==============================================================

	render.SetMaterial(Material("effects/blueblacklargebeam"))
	local beamCount = math.floor(Lerp(charge,1,10))
	local beamLength = Lerp(charge,4,14)
	local beamWidth = Lerp(charge,0.4,2)

	for i = 1,beamCount do
		local angle =
			CurTime() * Lerp(charge,0.5,8) +
			i * (math.pi * 2 / beamCount)
			
		local angle =
			CurTime() * Lerp(charge,0.5,8) +
			i * (math.pi * 2 / beamCount)
			-- print(i,angle) 
			
		local angle_cos = math.cos(angle)
		local angle_sin = math.sin(-angle)

		local dir = right * angle_cos + up * angle_sin
			-- print(i,dir,type(dir)) 

		local beamStart = corePos + dir * ringRadius
		local beamEnd = corePos + dir * (ringRadius + beamLength)
		local beamStart = corePos + (forward * -11) + (dir*6)  
		local beamEnd = corePos + (forward * 0.5) + (dir*6)
		-- if i == 1 then 
			-- debugoverlay.Cross(beamEnd,5,FrameTime()*2) 
			-- print(i,angle_cos,angle_sin) 
		-- end 
		if angle_cos > 0.8 then 

		render.DrawBeam(
			beamStart,
			beamEnd,
			beamWidth,
			0,
			1,
			Color(
				255,
				255,
				255,
				Lerp(charge,40,255)
			)
		)
		end 
	end


	--==============================================================
	-- CHROMACROSS / ENERGY SPARKS
	--==============================================================

	if charge > 0.01 then
		local emitterPos = corePos

		if !IsValid(self.Emitter) then
			self.Emitter = ParticleEmitter(emitterPos,false)
		end

		local charge = math.Clamp(self:Chaingun_GetChargeAmount(),0,1)

		-- Higher charge = more frequent particle creation.
		local sparks = charge < 0.95 or math.random() > charge -- or chromaCross 
		local spawnInterval = sparks and Lerp(charge,0.20,0.025) or Lerp(charge,0.80,0.2)

		if !self.RavenNextCrossTime or CurTime() >= self.RavenNextCrossTime then
			self.RavenNextCrossTime = CurTime() + spawnInterval

			--==========================================================
			-- LOW/MID CHARGE : WANDERING ENERGY SPARK
			--==========================================================

			if sparks then
				local offset =
					right * math.Rand(-5,5) +
					up * math.Rand(-5,5) +
					forward * math.Rand(-3,3)

				local pos = corePos + offset
				local p = self.Emitter:Add("effects/spark",pos)

				if p then
					local initialSpeed = Lerp(charge,35,110)
					local initialDir = VectorRand():GetNormalized()

					p:SetVelocity(initialDir * initialSpeed)
					p:SetDieTime(math.Rand(
						Lerp(charge,0.35,0.15),
						Lerp(charge,0.75,0.3)
					))
					p:SetStartAlpha(255)
					p:SetEndAlpha(0)
					p:SetStartSize(Lerp(charge,2,4))
					p:SetEndSize(0)
					p:SetColor(
						Lerp(charge,0,120),
						255,
						255
					)
					p:SetGravity(initialDir * Lerp(charge,20,80))
					p:SetStartLength(0.1)
					p:SetEndLength(0)
					p:SetVelocityScale(true)

					p.CreationTime = CurTime()
					p.NextTurnTime = CurTime()
					p.Speed = initialSpeed
					p.TargetDir = initialDir

					p:SetThinkFunction(function(prt)
						if !prt then return end

						local ct = CurTime()
						local ft = FrameTime()

						if ct >= prt.NextTurnTime then
							local dir = prt:GetVelocity():GetNormalized()

							dir.x = dir.x + 0.7 * (0.5 - math.random())
							dir.y = dir.y + 0.7 * (0.5 - math.random())
							dir.z = dir.z + 0.7 * (0.5 - math.random())

							prt.TargetDir = dir:GetNormalized()
							prt.NextTurnTime = ct + math.Rand(0.08,0.18)
						end

						local currentVel = prt:GetVelocity()
						local currentDir = currentVel:Length() > 0 and currentVel:GetNormalized() or prt.TargetDir

						local turnSpeed = Lerp(charge,7,15)
						local newDir = LerpVector(
							math.Clamp(ft * turnSpeed,0,1),
							currentDir,
							prt.TargetDir
						):GetNormalized()

						prt:SetVelocity(newDir * prt.Speed)

						local motionAng = newDir:Angle()
						prt:SetAngles(motionAng)
						prt:SetRoll(motionAng.y * (math.pi / 180))

						local interval = prt:GetLifeTime() / prt:GetDieTime()

						-- Become increasingly white as it approaches death.
						local cyan = 1 - interval
						prt:SetColor(
							255 * (1 - cyan) * 0.45,
							220 + 35 * cyan,
							255
						)

						prt:SetNextThink(ct)
					end)

					p:SetNextThink(CurTime())
				end

			--==========================================================
			-- HIGH CHARGE : RAPIDLY PULSING CHROMACROSS
			--==========================================================

			else
				local offset =
					right * math.Rand(-10,10) +
					up * math.Rand(-10,10) +
					forward * math.Rand(-0,40)

				local pos = corePos + offset

				local p = self.Emitter:Add(
					"sprites/MI_B_LensCircle_01_15_AfterDof",
					pos
				)

				if p then
					local dieTime = math.Rand(0.05,0.75)

					p:SetDieTime(dieTime)
					p:SetStartAlpha(0)
					p:SetEndAlpha(0)
					p:SetStartSize(0)
					p:SetEndSize(0)
					p:SetLighting(false)
					p:SetRoll(math.Rand(0,math.pi * 2))
					p:SetColor(150,255,255)
					p:SetVelocity(VectorRand()*100) 

					p.CreationTime = CurTime()

					p:SetThinkFunction(function(prt)
						if !prt then return end

						local life = prt:GetLifeTime()
						local die = prt:GetDieTime()

						if die <= 0 then return end

						local fraction = life / die

						-- Full pulse cycles during the particle's short lifetime.
						local cycles = Lerp(charge,2,5)

						local pulse = math.sin(
							fraction * math.pi * 2 * cycles
						)

						-- Convert -1..1 into 0..1.
						pulse = pulse * 0.5 + 0.5

						-- Stronger charge = larger/brighter cross.
						local size =
							pulse *
							Lerp(charge,0,8)

						local alpha =
							pulse *
							Lerp(charge,100,255)

						prt:SetStartSize(size)
						prt:SetEndSize(size)
						prt:SetStartAlpha(alpha)
						prt:SetEndAlpha(alpha)

						-- White core at pulse maximum, cyan otherwise.
						local white = pulse * charge

						prt:SetColor(
							Lerp(white,80,255),
							255,
							255
						)

						prt:SetRoll(
							prt:GetRoll() +
							FrameTime() * Lerp(charge,2,12)
						)

						prt:SetNextThink(CurTime())
					end)

					p:SetNextThink(CurTime())
				end
			end
		end
	end
end 