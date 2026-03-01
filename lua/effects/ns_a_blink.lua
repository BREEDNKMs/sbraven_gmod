function EFFECT:Init(data)
    local Pos, Ang, Scale, Time, Flags = data:GetOrigin(), data:GetAngles(), data:GetScale(), data:GetMagnitude(), data:GetFlags()
    self.CreationTime = CurTime()
    self.DieTime = Time
    
    -- Initialize tracking variables
    self.LastPos = Pos -- Start tracking position immediately
    self.LastCall = SysTime() -- Record precise system time

    if IsValid(data:GetEntity()) then
        self:SetOwner(data:GetEntity()) 
		self:SetPos(data:GetEntity():WorldSpaceCenter()) 
        -- self:SetParent(data:GetEntity(),data:GetHitBox()) 
		self:FollowBone(data:GetEntity(),data:GetHitBox()) 
		self:AddEffects(EF_PARENT_ANIMATES) 
    end

    self.Emitter = ParticleEmitter(Pos, tobool(Flags)) 
    local Emitter = self.Emitter 

    -- Initial Burst (Unchanged from your original code)
    for i = 1, 15 do
        local UniqueDieTime = math.Rand(0.10, 0.30)
        local Sprite = Emitter:Add("sprites/MI_B_LensCircle_01_15_AfterDof", Pos + VectorRand(-data:GetEntity():BoundingRadius(), data:GetEntity():BoundingRadius())) 
        
        Sprite:SetStartSize(0)
        Sprite:SetEndSize(0)
        Sprite:SetDieTime(UniqueDieTime)
        Sprite:SetGravity(Vector(0, 0, -100))
        Sprite:SetCollide(true)
        Sprite:SetBounce(0.5)
        Sprite:SetVelocity(VectorRand())
        Sprite:SetRoll(45)
        Sprite:SetThinkFunction(function(Sprite)
            local Cycle = (Sprite:GetLifeTime()) / UniqueDieTime
            local ParticleScale = 60 * Cycle * 1/0.5 
            if Cycle > 0.5 then
                Cycle = 1 - Cycle
                ParticleScale = 60 * Cycle * 1/0.5 
            end
            Sprite:SetStartSize(ParticleScale)
            Sprite:SetEndSize(ParticleScale)
            Sprite:SetNextThink(CurTime())
        end)
        
        if math.random() > 0.45 then
            local Sprite2 = Emitter:Add("sprites/blueflare1_noz_gmod", Sprite:GetPos())
            Sprite2:SetStartSize(0)
            Sprite2:SetEndSize(0)
            Sprite2:SetDieTime(UniqueDieTime)
            Sprite2:SetThinkFunction(function(Sprite2)
                Sprite2:SetStartSize(Sprite:GetStartSize())
                Sprite2:SetEndSize(Sprite:GetEndSize())
                Sprite2:SetPos(Sprite:GetPos())
                Sprite2:SetNextThink(CurTime())
            end)
        end
    end
    
    local UniqueDieTime = math.Rand(0.25, 0.30) 
    local Sprite = Emitter:Add("sprites/MI_A_ParNoiseBlur_01_1", Pos)
    Sprite:SetStartSize(60)
    Sprite:SetEndSize(0)
    Sprite:SetDieTime(UniqueDieTime)
    Sprite:SetGravity(VectorRand(-30, 30))
    Sprite:SetCollide(true)
    Sprite:SetBounce(0.5)
    Sprite:SetVelocity(VectorRand())
    Sprite:SetRoll(45)
    Sprite:SetThinkFunction(function(Sprite)
        local Cycle = (Sprite:GetLifeTime()) / UniqueDieTime
        local ParticleScale = 60 * Cycle * 1 / 0.2
        if Cycle > 0.2 then
            Cycle = 1 - Cycle
            ParticleScale = 60 * Cycle * 1 / 0.2
        end
        Sprite:SetStartSize(ParticleScale)
        Sprite:SetEndSize(ParticleScale)
        Sprite:SetNextThink(CurTime())
    end)
end 

function EFFECT:Think()
    self:SetNextClientThink(CurTime() + FrameTime())
    local Emitter = self.Emitter
    if !IsValid(Emitter) then return false end

    -- 1. Calculate time delta
    local CurrentTime = SysTime()
    local TimeDelta = CurrentTime - self.LastCall
    self.LastCall = CurrentTime

    -- 2. Calculate iterations (Variable)
    -- Target: 1 particle every 2ms (0.002 seconds)
    local Interval = 0.002 
    local Variable = math.floor(TimeDelta / Interval)
    
    -- Safety: Cap to avoid freezing if framerate drops massively
    if Variable > 50 then Variable = 50 end 

    -- Get positions for interpolation 
	local BoundingRadius = IsValid(self:GetOwner()) and self:GetOwner():BoundingRadius() or 16 
    local CurrentPos = IsValid(self:GetOwner()) and self:GetOwner():WorldSpaceCenter() or self:GetPos()
    local StartPos = self.LastPos

    -- 3. Iterate based on time elapsed
	-- print("variable is:",Variable) 
    for i = 1, Variable do
        
        -- 4. Interpolate Position
        -- If i=1 and Variable=2, Fraction is 0.5 (Halfway).
        -- If i=2 and Variable=2, Fraction is 1.0 (CurrentPos).
        local Fraction = i / Variable
        local InterpPos = LerpVector(Fraction, StartPos, CurrentPos)

        if math.random() > 0.8 then
            local UniqueDieTime = math.Rand(0.50, 2.00)
            -- Use InterpPos instead of self:GetPos()
            local Sprite = Emitter:Add("sprites/blueflare1_noz_gmod", InterpPos + VectorRand(-BoundingRadius, BoundingRadius)) 
            
            Sprite:SetStartSize(0)
            Sprite:SetEndSize(0)
            Sprite:SetDieTime(UniqueDieTime)
            Sprite:SetGravity(VectorRand(-3, 3))
            Sprite:SetCollide(true)
            Sprite:SetBounce(0.5)
            Sprite:SetVelocity(VectorRand(-3, 3))
            Sprite:SetRoll(45)
            Sprite:SetThinkFunction(function(Sprite)
                local Cycle = (Sprite:GetLifeTime()) / UniqueDieTime
                local ParticleScale = 0.3 * Cycle * 1 / 0.1
                if Cycle > 0.1 then
                    Cycle = 1 - Cycle
                    ParticleScale = 0.3 * Cycle * 1 / 0.1
                end
                Sprite:SetStartSize(ParticleScale)
                Sprite:SetEndSize(ParticleScale)
                Sprite:SetNextThink(CurTime())
            end)
        else
            local UniqueDieTime = math.Rand(0.50, 2.00)
            -- Use InterpPos instead of self:GetPos()
            local Sprite = Emitter:Add("sprites/MI_B_LensCircle_01_15_AfterDof", InterpPos + VectorRand(-BoundingRadius, BoundingRadius)) 
            
            Sprite:SetStartSize(0)
            Sprite:SetEndSize(0)
            Sprite:SetDieTime(UniqueDieTime)
            Sprite:SetGravity(VectorRand(-3, 3))
            Sprite:SetCollide(true)
            Sprite:SetBounce(0.5)
            Sprite:SetVelocity(VectorRand(-3, 3))
            Sprite:SetRoll(45)
            Sprite:SetThinkFunction(function(Sprite)
                local Cycle = (Sprite:GetLifeTime()) / UniqueDieTime
                local ParticleScale = 2 * Cycle * 1 / 0.1
                if Cycle > 0.1 then
                    Cycle = 1 - Cycle
                    ParticleScale = 2 * Cycle * 1 / 0.1
                end
                Sprite:SetStartSize(ParticleScale)
                Sprite:SetEndSize(ParticleScale)
                Sprite:SetNextThink(CurTime())
            end)
        end
    end
    
    -- Update LastPos for the next frame's interpolation
    self.LastPos = CurrentPos

    if CurTime() > self.CreationTime + self.DieTime then
        if IsValid(self.Emitter) then self.Emitter:Finish() end
        return false
    end

    return true
end

function EFFECT:Render() end