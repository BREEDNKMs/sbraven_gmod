-- flare for 0.1 sec, full scale, deflates in 0.1 sec 
-- sparks for 0.2 sec, on a circle, they all go to right direction of spawn axis 
-- optional: a little shockwave mesh for 0.2 sec 

-- shockwave material: MI_D_Raven_ShockWv_01 
local glowmat = Material("sprites/physg_glow1") 

function EFFECT:Init(data) 
    local Pos, Ang, Scale, Time, Flags = data:GetOrigin(), data:GetAngles(), data:GetScale(), data:GetMagnitude(), data:GetFlags() 
	Time = Time > 0 and Time or 0.35 
    self:SetModelScale(Scale) 
    self.LifeTime = Time 
	self.CreationTime = CurTime() 
    self.Emitter = ParticleEmitter(Pos) 
	if IsValid(data:GetEntity()) then 
		if data:GetEntity():IsWeapon() then 
			self:SetOwner(data:GetEntity():GetOwner()) 
		else 
			self:SetOwner(data:GetEntity()) 
		end 
	end 
	self:SetAngles(Ang+self:GetOwner():GetRenderAngles()) 
	-- print(self:GetAngles()) 

    local segments  = 100
    local radius    = Scale*5
    local fwd       = self:GetForward()
    local up        = self:GetUp()
    local right     = self:GetRight()

    for i = 1, segments do
        local angle = (i / segments) * math.pi * 2

        -- Distribute spawn positions evenly around a circle in the forward/up plane
        local circleOffset = fwd * (math.cos(angle) * radius)
                           + right  * (math.sin(angle) * radius)

        -- World-space positional noise: ±5 on X/Y, ±10 on Z
        local noise = Vector(
            math.Rand(-5,  5),
            math.Rand(-5,  5),
            math.Rand(-10, 10)
        )

        local spawnPos = Pos + circleOffset + noise

        -- Velocity along self:GetRight(), magnitude 300 ± 400
        local velocity = right * math.Rand(300, 400)

        local p = self.Emitter:Add("effects/spark", spawnPos)
        if p then
            p:SetDieTime(0.1)
            p:SetStartSize(math.Rand(3.7, 8.2))
            p:SetEndSize(0)
            p:SetVelocity(velocity)
			p:SetAirResistance(600) 
            p:SetColor(math.random(170, 200), 255, 255)
            p:SetStartAlpha(255)
            p:SetEndAlpha(255)
            p:SetRoll(math.rad((90)))
			p:SetVelocityScale(true) 
			p:SetStartLength(0.060) 
			p:SetEndLength(0) 
        end
    end

    self.Emitter:Finish()
	for i = 1, 2 do 
		local sphere = ClientsideModel("models/props_combine/sphere.mdl",RENDERGROUP_BOTH) 
		sphere:SetPos(self:GetPos()) 
		sphere:SetRenderMode(1) 
		sphere:SetSkin(1) 
		if i == 2 then 
			sphere:SetAngles(Angle(180,0,0)) 
		end 
		sphere:SetMaterial("sprites/MI_D_Raven_ShockWv_01") 
		self.BackJumpCombo_Spheres = self.BackJumpCombo_Spheres or { } 
		table.insert(self.BackJumpCombo_Spheres,sphere) 
	end 
end

function EFFECT:Think() 
	-- self:SetNextClientThink(CurTime()+FrameTime()) 
	local Cycle = math.Clamp((CurTime() - self.CreationTime) / self.LifeTime,0,1) 
    self.LifeTime = self.LifeTime - FrameTime() 
	for k,sphere in pairs(self.BackJumpCombo_Spheres) do 
		sphere:SetModelScale(sphere:GetModelScale()+(FrameTime()*166)) 
		sphere:SetColor(Color(0,255,255,1-(Cycle*200))) 
		-- print(sphere:GetModelScale()) 
	end 
	if Cycle < 1 then 
		return true 
	else 
		for k,v in pairs(self.BackJumpCombo_Spheres) do 
			SafeRemoveEntity(v)  
		end 
		return false 
	end 
    return Cycle < 1 
end 

function EFFECT:Render() 
	local Cycle = math.Clamp((CurTime() - self.CreationTime) / self.LifeTime,0,1) 
	render.SetMaterial(glowmat) 
	render.DrawSprite(self:GetPos(), (1-Cycle)*150, (1-Cycle)*10, Color(100,255,255)) 
	render.DrawSprite(self:GetPos(), (1-Cycle)*150, (1-Cycle)*10, Color(100,255,255)) 
	render.DrawSprite(self:GetPos(), (1-Cycle)*150, (1-Cycle)*10, Color(100,255,255)) 
	render.DrawSprite(self:GetPos(), (1-Cycle)*30, (1-Cycle)*30, Color(100,255,255)) 
end