-- Cache the material outside of the functions for performance
local RefractMat = Material("sprites/sphere_refract")

function EFFECT:Init(data)
    -- Collect data from the effect data object
    self.Origin = data:GetOrigin()
    self.Scale = data:GetScale()
	self.Scale = self.Scale * 5 
    self.Lifetime = math.max(data:GetMagnitude(),0.05)
    
    -- Calculate the exact timestamp when this effect should die
    self.DieTime = CurTime() + self.Lifetime
	-- debugoverlay.Cross(self:GetPos(),10) 
	-- print(self.Scale,self.Lifetime) 
end

function EFFECT:Think()
    -- Returning true keeps the effect alive, returning false removes it
    return CurTime() < self.DieTime
end

function EFFECT:Render()
    -- Calculate remaining lifetime ratio (starts at 1.0, counts down to 0.0)
    local remaining = self.DieTime - CurTime()
    local ratio = math.Clamp(remaining / self.Lifetime, 0, 1)

    -- Linearly decrease $refractamount from 0.1 to 0 based on the lifetime ratio
    RefractMat:SetFloat("$refractamount", ratio * 0.01)

    -- Render the material as a 2D sprite facing the player's EyePos()
    render.SetMaterial(RefractMat)
    render.DrawSprite(self.Origin, self.Scale, self.Scale, color_white)
end