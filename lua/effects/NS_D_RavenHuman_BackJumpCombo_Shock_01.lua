-- NS_D_RavenHuman_BackJumpCombo_Shock_01.lua 
-- Garry's Mod clientside EFFECT replicating NS_D_RavenHuman_BackJumpCombo_Shock_01 (approximation)
-- Projects several textures onto the hit surface using ProjectedTexture,
-- animates their size and brightness over their lifetimes, and adds particles.
EFFECT.NextAuroraTime = CurTime() 

-- Configuration approximating the original FX_AddQuad calls
local QUADS = {
    -- {
        -- texture = "effects/ar2_altfire1b", -- first ripple texture
        -- startSize = 64,
        -- endSize   = 600*50,
        -- startAlpha = 500.0,
        -- endAlpha   = 0.0,
        -- lifeTime = 0.75
    -- },
    {
        texture = "sprites/rollerglow_gray", -- second inner glow
        startSize = 16,
        endSize   = 300*10,
        startAlpha = 10000.0,
        endAlpha   = 0.0,
        lifeTime = 1.25, 
		Color = color_white 
    },
	{
        texture = "sprites/ar2_muzzle1", 
        startSize = 16,
        endSize   = 300*10,
        startAlpha = 10000.0,
        endAlpha   = 0.0,
        lifeTime = 1.25,
		Color = Color(50,255,255) 
    },
	{
        texture = "sprites/T_A_FlareRing_02", 
        startSize = 16,
        endSize   = 300*10,
        startAlpha = 3000.0,
        endAlpha   = 0.0,
        lifeTime = 1.25,
		Color = Color(255,255,255) 
    },
	-- { -- refract test
        -- texture = "effects/hunterphysblast", 
        -- startSize = 16,
        -- endSize   = 300*15,
        -- startAlpha = 1500.0,
        -- endAlpha   = 0.0,
        -- lifeTime = 1.25,
		-- Color = Color(50,255,255) 
    -- },
}

-- Utility: build an angle facing the surface normal. We want the projector to look *towards* the surface.
local function AngleForNormal(normal)
    -- Use normal:Angle, but rotate so the projector "faces" the surface
    local ang = normal:Angle()
    -- The projector's "forward" should be -normal, so rotate 180 around pitch
    ang:RotateAroundAxis(ang:Right(), 180)
    return ang
end

-- EFFECT Init
function EFFECT:Init(data)
    self.Origin = data:GetOrigin() or Vector(0,0,0) 
	self.Emitter = ParticleEmitter(data:GetOrigin()) 
	self.CreationTime = CurTime() 
	self.Emitter_3d = ParticleEmitter(data:GetOrigin(),true) 

    -- Trace down from Origin+16Z to Origin-64Z like the HL2 code
    local startPos = self.Origin + Vector(0,0,16)
    local endPos   = self.Origin + Vector(0,0,-150)

    local tr = util.TraceLine({
        start = startPos,
        endpos = endPos,
        mask = MASK_SOLID_BRUSHONLY,
        filter = function(ent) return false end -- don't hit entities
    })

    if not tr.Hit or tr.Fraction >= 1 then
        -- Nothing hit: short-lifetime fallback (spawn small particles + finish)
        self.Projectors = {}
        self:SpawnSmallFallback()
        self.DieTime = CurTime() + 0.2
        return
    end

    local hitPos = tr.HitPos
    local hitNormal = tr.HitNormal

    -- Create a dynamic light at the effect position, greenish like Vortigaunt
    local dlight = DynamicLight(LocalPlayer():EntIndex())
    if dlight and block then
        dlight.pos = self.Origin
        dlight.r = 64
        dlight.g = 255
        dlight.b = 64
        dlight.brightness = 1.5
        dlight.Decay = 1024
        dlight.size = 256
        dlight.dietime = CurTime() + 0.25
    end
    self.DLight = dlight

    -- Create projectors table that we'll update each Think
    self.Projectors = {}

    -- For each configured quad, create a ProjectedTexture entity and store animation params
    for i, q in ipairs(QUADS) do
        local p = ProjectedTexture()

        p:SetPos(hitPos + hitNormal * 8) -- the original used normal * 8
        -- p:SetTargetEntity(NULL)
        -- use orthographic projection so we can control the quad size directly
		local ang = AngleForNormal(hitNormal)
		ang = ang + Angle(0,math.random(-180,180),0) 
        p:SetOrthographic(true, -q.startSize, -q.startSize, q.startSize, q.startSize)
        p:SetNearZ(0)              -- start projection right at the surface
        p:SetFarZ(0)            -- plenty of projection distance
        p:SetLightWorld(true)
        p:SetTexture(q.texture)
        p:SetBrightness(q.startAlpha) -- initial brightness mapped from alpha (0..1)
		p:SetAngles(ang)
		p:SetColor(q.Color) 
        p:Update()

        -- store animator
        table.insert(self.Projectors, {
            ptex = p,
            startTime = CurTime(),
            lifeTime  = q.lifeTime,
            startSize = q.startSize,
            endSize   = q.endSize,
            startAlpha = q.startAlpha,
            endAlpha   = q.endAlpha,
            pos = hitPos + hitNormal * 8,
            normal = hitNormal,
            texture = q.texture, 
			Color = q.Color 
        })
    end

    -- Small particle burst to mimic hand glow / sparks
    if IsValid(self.Emitter) then
        for i=1, 10 do
            local vel = VectorRand() * math.Rand(10, 100)
            local p = self.Emitter:Add("effects/rollerglow", hitPos + VectorRand()*4)
            if p then
                p:SetVelocity(vel)
                p:SetDieTime(0.3 + math.Rand(0,0.4))
                p:SetStartAlpha(255)
                p:SetEndAlpha(0)
                p:SetStartSize(math.Rand(6,12))
                p:SetEndSize(0)
                p:SetRoll(math.Rand(0,360))
                p:SetColor(0,255,255)
                p:SetAirResistance(50)
            end
        end
		
		-- local p = self.Emitter:Add("effects/strider_pinch_dudv",hitPos) 
		local p = self.Emitter:Add("effects/strider_bulge_dudv",hitPos) 
		p:SetStartSize(0) 
		p:SetEndSize(1500) 
		p:SetDieTime(0.1) 
		p:SetThinkFunction(function() 
			local Cycle = 1-(p:GetLifeTime() / p:GetDieTime()) 
			-- print(Cycle) 
			Material("effects/strider_bulge_dudv"):SetFloat("$refractamount",Cycle) 
			p:SetNextThink(CurTime()) 
		end) 
		
		local p = self.Emitter:Add("effects/strider_pinch_dudv",hitPos) 
		p:SetStartSize(0) 
		p:SetEndSize(1500) 
		p:SetDieTime(0.1) 
		p:SetThinkFunction(function() 
			local Cycle = 1-(p:GetLifeTime() / p:GetDieTime()) 
			Material("effects/strider_pinch_dudv"):SetFloat("$refractamount",Cycle) 
			p:SetNextThink(CurTime()) 
		end) 
		
    end

    -- We will live until the longest quad lifetime is finished
    local maxLife = 0
    for _, v in ipairs(QUADS) do maxLife = math.max(maxLife, v.lifeTime) end
    self.DieTime = CurTime() + maxLife + 0.1
end

function EFFECT:SpawnSmallFallback()
    -- fallback particle effect when no surface found
    local emitter = ParticleEmitter(self.Origin,true)
        local p = emitter:Add("sprites/rollerglow_gray", self.Origin + VectorRand()*4)
        if p then
            -- p:SetVelocity(VectorRand()*40)
			p:SetAngles(Angle(-90,0,0))
            p:SetDieTime(1)
            p:SetStartAlpha(255)
            p:SetEndAlpha(0)
            p:SetStartSize(0)
            p:SetEndSize(300)
            p:SetColor(255,255,255)
        end
    emitter:Finish()
end

-- EFFECT Think: update projector animations and clean up expired ones
function EFFECT:Think()
    local ct = CurTime()

    -- Update dynamic light position if present
    if self.DLight then
        self.DLight.pos = self.Origin
        -- let engine handle die time
    end

    if self.Projectors and #self.Projectors > 0 then
        for i = #self.Projectors, 1, -1 do
            local info = self.Projectors[i]
            local ptex = info.ptex
            if not IsValid(ptex) then
                table.remove(self.Projectors, i)
                continue 
            end

            local t = (ct - info.startTime) / (info.lifeTime)
            if t < 0 then t = 0 end
            -- if t > 1 then t = 1 end

            -- Interpolate size and brightness (used to simulate alpha fade)
            local size = Lerp( t, info.startSize, info.endSize )
            local alpha = Lerp( t, info.startAlpha, info.endAlpha ) -- 0..1
            local brightness = math.max(0.0, alpha) -- projected texture brightness uses small numbers
            -- local brightness = 2000 -- projected texture brightness uses small numbers

            -- Update projector transform and orthographic bounds
            ptex:SetPos(info.pos)
            -- Compute an angle so projector faces the surface normal
            -- local ang = AngleForNormal(info.normal)
            -- ptex:SetAngles(ang)
            -- Use orthographic bounds to roughly match a square of 'size' units
            ptex:SetOrthographic(true, -size, -size, size, size)
            ptex:SetBrightness(brightness)
            ptex:SetTexture(info.texture)
			ptex:SetColor(info.Color) 
			ptex:SetFarZ(size)
			ptex:SetLinearAttenuation(size*0.008) 
			ptex:SetConstantAttenuation(size*0.008) 
			ptex:SetQuadraticAttenuation(size*0.008) 
			-- print(size) 
            ptex:Update()
			-- debugoverlay.Sphere(info.pos,size*0.42,FrameTime()*2) 

            if t >= 1.0 then
                -- expire and remove projector
                ptex:Remove()
                table.remove(self.Projectors, i)
            end
        end
    end
	
	local Cycle = (CurTime() - self.CreationTime) / (self.DieTime - self.CreationTime)
	-- print(Cycle) 
	local Rand = Vector(math.Rand(-1,1),math.Rand(-1,1),0)*(Cycle*2000) 
	print(Rand,Cycle) 
	if self.NextAuroraTime <= CurTime() then 
		-- local p = self.Emitter_3d:Add("effects/energysplash", self:GetPos() + Rand) 
		local p = self.Emitter:Add("effects/energysplash", self:GetPos() + Rand + Vector(0,0,650)) 
		if p then 
			p:SetVelocity(Vector(0,0,-0.8)) 
			p:SetDieTime(0.3 + math.Rand(0,0.4)) 
			p:SetStartAlpha(100)
			p:SetEndAlpha(0)
			p:SetStartSize(80*2)
			p:SetEndSize(80*2)
			p:SetColor(0,255,255)
			-- p:SetAirResistance(100) 
			p:SetGravity(Vector(0,0,1)) 
			p:SetAngles(Angle(0,math.random(-180,180),90)) 
			p:SetStartLength(1500) 
			p:SetEndLength(1500) 
			p:SetVelocityScale(true) 
			p.CreationTime = CurTime() 
			
			p:SetThinkFunction(function()  
			local eyePos = EyePos()
			local particlePos = p:GetPos()
			local dir = (eyePos - particlePos):GetNormalized()
			local angles = dir:Angle()
			angles.p = 0 
			angles:RotateAroundAxis(angles:Forward(), 90) 
			-- p:SetAngles(angles) 
			local Cycle = p:GetLifeTime() / p:GetDieTime() 
			-- print(p,Cycle) 
			p:SetColor(0*Cycle,255*(1-Cycle),255*(1-Cycle)) 
			p:SetNextThink(CurTime()) 
			end) -- billboard always rotating towards player 
			
		end 
		self.NextAuroraTime = CurTime() + 0.01 
	end 

    -- Effect lives until DieTime, then we cleanup
    if ct >= (self.DieTime) then
        -- ensure all projectors removed
        if self.Projectors then
            for _, info in ipairs(self.Projectors) do
                if info and IsValid(info.ptex) then
                    info.ptex:Remove()
                end
            end
            self.Projectors = {}
        end

        -- mark dynamic light to die immediately if exists
        if self.DLight then
            self.DLight.dietime = ct
            self.DLight = nil
        end
		
		if self.Emitter and self.Emitter:IsValid() then 
			self.Emitter:Finish() 
		end 
		if self.Emitter_3d and self.Emitter_3d:IsValid() then 
			self.Emitter_3d:Finish() 
		end 
        return false
    end
	self:SetNextClientThink(CurTime()+FrameTime()) 
    return true
end

-- EFFECT Render: nothing to draw manually (projected textures handle visuals)
function EFFECT:Render()
    -- Intentionally empty
end

-- Clean up on remove (in case engine calls directly)
function EFFECT:OnRemove()
    if self.Projectors then
        for _, info in ipairs(self.Projectors) do
            if info and IsValid(info.ptex) then
                info.ptex:Remove()
            end
        end
        self.Projectors = nil
    end

    if self.DLight then
        self.DLight.dietime = CurTime()
        self.DLight = nil
    end
end
