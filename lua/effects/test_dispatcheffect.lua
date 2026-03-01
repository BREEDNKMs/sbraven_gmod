function EFFECT:Init(data) 
	local Pos, Ang, Scale, Time, Flags = data:GetOrigin(), data:GetAngles(), data:GetScale(), data:GetMagnitude(), data:GetFlags() 
	self.CreationTime = CurTime() 
	self.DieTime = Time 
	local Emitter = ParticleEmitter(Pos,tobool(Flags)) 
	-- self.Emitter = Emitter 
	local Sprite = Emitter:Add("sprites/MI_A_ParNoiseBlur_01_1",Pos) 
	Sprite:SetStartSize(Scale) 
	Sprite:SetEndSize(0) 
	Sprite:SetDieTime(Time) 
	Sprite:SetGravity(Vector(0,0,-100)) 
	Sprite:SetCollide(true) 
	Sprite:SetBounce(0.5) 
	Sprite:SetColor(1,1,1) 
	Sprite:SetStartAlpha(1) 
	Sprite:SetEndAlpha(1) 
	-- Sprite:SetVelocityScale(true) 
	-- Sprite:SetStartLength(1)
	-- Sprite:SetEndLength(1)
	Emitter:Finish() 
	
	self.Pos = data:GetOrigin() or LocalPlayer():EyePos()
    self.StartTime = CurTime()
    self.Fraction = 0

    -- Create a clientside model. Change the model path here if you want.
	self:SetModel("models/stellarblade/Sword_Line_02_A.mdl") 
	self:SetRenderMode(1) 
    -- self.Model = ClientsideModel("models/props_c17/oildrum001.mdl", RENDERGROUP_OPAQUE)
	self.LifeTime = 2 -- seconds
    -- if not IsValid(self.Model) then return end

    -- self.Model:SetPos(self:GetPos())
    -- self.Model:SetAngles(self:GetAngles())
    -- self.Model:SetNoDraw(true) -- we'll draw it manually with clipping
    -- self.Model:DrawShadow(false)

    -- Compute a conservative radius from the render bounds (used to place the plane)
    local mins, maxs = self:GetModelRenderBounds()
    self.BoundsRadius = (maxs - mins):Length() * 0.5

    -- Optional: small offset so the plane doesn't exactly graze the hull at start
    self.BoundsRadius = math.max(self.BoundsRadius, 16)
end 

function EFFECT:Think() 
	self:SetNextClientThink(CurTime()+FrameTime()) 
	-- if not IsValid(self.Model) then return false end

    local elapsed = CurTime() - self.StartTime
    if elapsed >= self.LifeTime then
        -- finished: remove model and stop the effect
        -- self.Model:Remove()
        return false
    end

    -- fraction 0..1 of lifetime
    self.Fraction = math.Clamp(elapsed / self.LifeTime, 0, 1)

    -- keep the model positioned at the effect origin in case world moves
    -- self.Model:SetPos(self.Pos)

    -- rotate the model a little so the visual is nicer (optional)
    -- self.Model:SetAngles(Angle(0, -self.Fraction * 360, 0))

    return true
end 

function EFFECT:Render()
    -- if not IsValid(self.Model) then return end

    -- Rotation: we want the clipping plane normal to rotate clockwise in the XY plane.
    -- In math, positive angles are counter-clockwise, so use negative angle for clockwise.
    local angDeg = -self.Fraction * 360
    local ang = math.rad(angDeg)

    -- Plane normal in world-space (rotate around Z)
    local normal = Vector(math.cos(ang), math.sin(ang), 0)
    normal:Normalize()

    -- Place plane so at fraction 0 the plane sits just in front of the model (clipping everything),
    -- and at fraction 1 the plane is behind the model (clipping nothing). We interpolate the plane
    -- distance linearly from +radius to -radius relative to the model center.

    local modelPos = self:GetPos()
    local planeDot = normal:Dot(modelPos)

    -- distance = dot + radius*(1 - 2*frac)
    local distance = planeDot + self.BoundsRadius * (1 - 2 * self.Fraction)

    -- Enable clipping and draw the model once with the custom clip plane
    render.EnableClipping(true)
    render.PushCustomClipPlane(normal, distance)

    -- Draw the model; the clip plane will hide the part we don't want to render yet
    self:DrawModel()

    render.PopCustomClipPlane()
    render.EnableClipping(false)

    -- DEBUG: draw the plane line (uncomment if needed)
    -- local start = modelPos - normal * 2048
    -- local finish = modelPos + normal * 2048
    -- debugoverlay.Line(start, finish, 0.05, Color(255,0,0), true)
end
