-- ne_meshm effect
-- place in lua/effects/ne_meshm/init.lua
-- Usage (example): util.Effect("ne_meshm", effectdata) where effectdata has origin/angles/scale/magnitude set

local NE_MeshM = Model("models/stellarblade/Sword_Line_02_A.mdl") 
local NE_MeshM001_1 = Model("models/stellarblade/Sword_Line_02_B.mdl") 

local function lerpColor(a, b, t)
    return Color(
        Lerp(a.r / 255, b.r / 255, t) * 255,
        Lerp(a.g / 255, b.g / 255, t) * 255,
        Lerp(a.b / 255, b.b / 255, t) * 255,
        Lerp(a.a / 255, b.a / 255, t) * 255
    )
end

function EFFECT:Init(data)
    -- base transform
    self:SetPos(data:GetOrigin())
    self:SetAngles(data:GetAngles())

    -- provided by the user in the initial code lines
    self.Scale = data:GetScale() or 1            -- scale multiplier of effect, defaults to 1
	self.Scale = self.Scale * 0.1 
    self.LifeTime = data:GetMagnitude() or 1     -- lifetime multiplier of effect, defaults to 1

    -- clamp sensible minimums
    if self.Scale <= 0 then self.Scale = 1 end
    if self.LifeTime <= 0.01 then self.LifeTime = 1 end

    -- model + material
    self:SetModel(NE_MeshM)
    -- the material name (no extension) as the user created earlier
    self:SetMaterial("sprites/ma_d_meshtrail_rgbsplit_01")

    -- store model bounds to help with render bounds
    local min, max = self:GetModelBounds()
    self._bbMin = min or Vector(-32, -32, -32)
    self._bbMax = max or Vector(32, 32, 32)

    -- timing
    self._tStart = CurTime()
    self._tDie = self._tStart + self.LifeTime

    -- seed / randomness that can emulate material randomness if needed
    self._rand = math.random() 

    -- initial per-effect user defaults approximated from JSON:
    -- ColorCurve early sample: ~cyan/teal (R≈0, G≈0.27, B≈0.5, A≈1.0)
    -- We'll treat these as 0-255 ints for SetColor.
    self._startColor = Color(0, 69, 128, 255) -- approx (0,0.27,0.5) *255
    self._endColor   = Color(18, 18, 18, 0)   -- near-dark with 0 alpha at end

    -- alpha & timing envelope:
    self._fadeInTime = math.min(0.12 * self.LifeTime, 0.15)  -- short fade in (12% life max 0.15s)
    self._fadeOutTime = 0.9 * self.LifeTime                    -- start heavy fade near the end

    -- scale envelope (we'll make it grow slightly then shrink)
    self._baseModelScale = 1.0 -- model intrinsic scale
    self._endScaleMul = 0.1    -- final scale multiplier relative to start

    -- initial scale set immediately (SetModelScale changes drawing size)
    self:SetModelScale(self._baseModelScale * self.Scale, 0)

    -- ensure it has big enough bounds so it's visible while animating (local-space effect)
    local expand = math.max(self.Scale * 64, 128)
    self:SetRenderBounds(self._bbMin * expand, self._bbMax * expand)

    -- allow shadows off for sprite-like look (optional)
    self:DrawShadow(false)
	self:NE_MeshM001_1(data) 
end

function EFFECT:Think()
    local ct = CurTime()
    local life = (ct - self._tStart) / math.max(0.0001, self.LifeTime)
    if life >= 1 then
		if IsValid(self.EFFECT_NE_MeshM001_1) then 
			SafeRemoveEntity(self.EFFECT_NE_MeshM001_1) 
		end 
        return false
    end

    -- clamp life 0..1
    life = math.max(0, math.min(1, life))

    -- === ALPHA ENVELOPE ===
    -- short ease-in, long ease-out: combine two easing zones
    local alphaMul = 1.0
    if ct < self._tStart + self._fadeInTime then
        -- ease in from 0 -> 1
        local lt = (ct - self._tStart) / math.max(0.0001, self._fadeInTime)
        alphaMul = math.ease.InQuad(lt)
    else
        -- fade-out after fadeOutTime proportion
        local fadeStart = self._tStart + self._fadeOutTime
        if ct >= fadeStart then
            local lt = (ct - fadeStart) / math.max(0.0001, (self._tDie - fadeStart))
            -- use math.ease.OutQuad to make fade smooth
            alphaMul = 1 - math.ease.OutQuad(lt)
        else
            alphaMul = 1.0
        end
    end

    -- approximate the Scale Alpha FloatCurve (starts ~1 and decays)
    -- apply an additional gentle decay with easeOut behavior across life
    local alphaCurveMul = 1 - math.ease.OutQuad(life) * 0.98 -- ensures near 1 early, near 0 late
    local finalAlpha = math.max(0, math.min(1, alphaMul * alphaCurveMul))
	self:SetVelocity(self:GetForward()*finalAlpha) 

    -- === COLOR CURVE ===
    -- approximate ColorCurve: start cyan/teal -> shift to darker / slightly redder near end
    local colorT = math.ease.InOutCubic(life)
    local curColor = lerpColor(self._startColor, self._endColor, colorT)

    -- apply alpha to color
    curColor.a = math.floor(255 * finalAlpha)

    -- write color to entity (material uses vertex color / alpha in VMT)
    -- If you want additive/emissive feel, you can increase rgb scaling here.
    self:SetColor(curColor)

    -- === SCALE CURVE ===
    -- Small grow at start, then shrink toward end
    local growT = math.ease.OutQuad(math.min(1, life * 1.2)) -- quick initial growth
    local shrinkT = math.ease.InQuad(math.max(0, (life - 0.2) / 0.8)) -- start shrinking after 20%
    local scaleMul = Lerp(1.0 + 0.18 * growT, self._endScaleMul, shrinkT) -- from ~1.18 -> 0.1
    local modelScale = self._baseModelScale * self.Scale * scaleMul
    self:SetModelScale(modelScale, 0)

    -- update render bounds (scale aware)
    local expand = math.max(modelScale * 64, 128)
    self:SetRenderBounds(self._bbMin * expand, self._bbMax * expand)

    -- optional: rotate slowly for subtle motion (mimic mesh orientation binding)
    local ang = self:GetAngles()
    ang:RotateAroundAxis(ang:Up(), 90 * FrameTime() * (0.5 + self._rand))
    self:SetAngles(ang)
	
	if IsValid(self.EFFECT_NE_MeshM001_1) then 
		self.EFFECT_NE_MeshM001_1:SetPos(self:GetPos()) 
		self.EFFECT_NE_MeshM001_1:SetAngles(self:GetAngles()) 
		self.EFFECT_NE_MeshM001_1:SetModelScale(self:GetModelScale()) 
		self.EFFECT_NE_MeshM001_1:SetColor(self:GetColor()) 
	end 

    -- return true to keep the effect alive
    return true
end

function EFFECT:NE_MeshM001_1(data)
    local origin = data:GetOrigin()
    local ang = data:GetAngles()
    local scaleMul = data:GetScale() or 1
    local lifeMul = data:GetMagnitude() or 1

    -- sane defaults
    if scaleMul <= 0 then scaleMul = 1 end
    if lifeMul <= 0.01 then lifeMul = 1 end
	scaleMul = scaleMul * 0.1 

    local ent = ClientsideModel(NE_MeshM001_1, RENDERGROUP_BOTH)
    ent:SetPos(origin)
    ent:SetAngles(ang)
    ent:SetModel(NE_MeshM001_1) -- ensure model is set correctly
    ent:DrawShadow(false)

    -- mark start/die times
    ent._ne_start = CurTime()
    ent._ne_die = ent._ne_start + lifeMul

    -- store base scale and slots for dynamic data
    ent._ne_scaleMul = scaleMul
    ent._ne_baseModelScale = 1.0  -- we will multiply this by _ne_scaleMul and curve
    ent._ne_rand = math.Rand(0, 1)

    -- approximate color curve from JSON: cyan/teal -> darker / slightly desaturated
    ent._ne_col_start = Color(77, 223, 255, 255)  -- (~0.30,0.87,1.0) *255
    ent._ne_col_end   = Color(24, 24, 24, 0)      -- dark + fully transparent at end

    -- alpha/fade timing approximations
    -- JSON alpha LUT: near full early, decays to 0 late. We'll do small fade-in then ease-out fade.
    ent._ne_fadeInTime = math.min(0.12 * lifeMul, 0.15)
    ent._ne_fadeOutStart = 0.75 * lifeMul -- start main fade near 75% of life

    -- render bounds expansion so the model isn't culled during animation
    local minb, maxb = ent:GetModelBounds()
    local expand = math.max(ent._ne_scaleMul * 64, 128)
    ent:SetRenderBounds(minb * expand, maxb * expand)

    -- For safety: remove after lifetime if something else doesn't do it
    timer.Simple(lifeMul + 0.25, function()
        if IsValid(ent) then SafeRemoveEntity(ent) end
    end)

    -- RenderOverride does both think and draw
    ent.RenderOverride = function(self, flags)
        local ct = CurTime()
        local lifeT = (ct - self._ne_start) / math.max(0.00001, (self._ne_die - self._ne_start))
        lifeT = math.Clamp(lifeT, 0, 1)

        -- ALPHA: fade-in short, then smooth easeOut fade to 0
        local alphaMul = 1
        if ct < (self._ne_start + self._ne_fadeInTime) then
            local t = (ct - self._ne_start) / math.max(0.00001, self._ne_fadeInTime)
            alphaMul = math.ease.InQuad(math.Clamp(t, 0, 1))
        elseif ct >= (self._ne_start + self._ne_fadeOutStart) then
            local t = (ct - (self._ne_start + self._ne_fadeOutStart)) / math.max(0.00001, (self._ne_die - (self._ne_start + self._ne_fadeOutStart)))
            alphaMul = 1 - math.ease.OutQuad(math.Clamp(t, 0, 1))
        else
            alphaMul = 1
        end

        -- Apply an additional alpha curve to mimic Scale Alpha LUT: gentle overall decay
        local alphaCurve = 1 - math.ease.OutQuad(lifeT) * 0.98
        local finalAlpha = math.Clamp(alphaMul * alphaCurve, 0, 1)

        -- COLOR: approximate color curve with math.ease.InOutCubic
        local colT = math.ease.InOutCubic(lifeT)
        local curColor = lerpColor(self._ne_col_start, self._ne_col_end, colT)
        curColor.a = math.floor(255 * finalAlpha)

        -- Scale: small grow then shrink
        -- using two-stage easing: grow quickly (0..20%), then gradually shrink
        local growT = math.Clamp(lifeT / 0.2, 0, 1)
        local growMul = 1 + 0.18 * math.ease.OutQuad(growT) -- slightly larger at start
        local shrinkT = math.Clamp((lifeT - 0.2) / 0.8, 0, 1)
        local shrinkMul = Lerp(growMul, 0.12, math.ease.InQuad(shrinkT)) -- final ~0.12 of start
        local modelScale = self._ne_baseModelScale * self._ne_scaleMul * shrinkMul
        self:SetModelScale(modelScale, 0)

        -- subtle orientation animation to emulate mesh orientation binding
        local ang = self:GetAngles()
        ang:RotateAroundAxis(ang:Forward(), 40 * FrameTime() * (0.5 + self._ne_rand))
        ang:RotateAroundAxis(ang:Right(), 16 * FrameTime() * (0.3 + self._ne_rand))
        self:SetAngles(ang)

        -- Apply color/alpha via SetColor (VMT should respect $vertexcolor / $vertexalpha)
        -- Note: SetColor expects color values 0-255
        self:SetColor(curColor)

        -- Optionally, if you want to fake emissive brightness, you can amplify RGB here:
        -- local bright = 1.0 + (1 - lifeT) * 0.6
        -- self:SetColor(Color( clamp(curColor.r*bright,0,255), clamp(curColor.g*bright,0,255), clamp(curColor.b*bright,0,255), curColor.a ))

        -- update render bounds so it won't be culled if scale changed a lot
        local minb2, maxb2 = self:GetModelBounds()
        local expand2 = math.max(modelScale * 64, 128)
        self:SetRenderBounds(minb2 * expand2, maxb2 * expand2)

        -- draw the model normally (pass flags if present)
        self:DrawModel(flags)

        -- removal
        if lifeT >= 1 then
            SafeRemoveEntity(self)
            return
        end
    end
    -- done creating; the EFFECT creator may not want to keep a handle, but we return the entity anyway
    return ent
end

function EFFECT:Init(data)
    -- base transform
    self:SetPos(data:GetOrigin())
    self:SetAngles(data:GetAngles())

    -- provided by the user in the initial code lines
    self.Scale = data:GetScale() or 1            -- scale multiplier of effect, defaults to 1
	self.Scale = self.Scale * 0.1 
    self.LifeTime = data:GetMagnitude() or 1     -- lifetime multiplier of effect, defaults to 1

    -- clamp sensible minimums
    if self.Scale <= 0 then self.Scale = 1 end
    if self.LifeTime <= 0.01 then self.LifeTime = 1 end

    -- model + material
    self:SetModel(NE_MeshM)
    -- the material name (no extension) as the user created earlier
    self:SetMaterial("sprites/ma_d_meshtrail_rgbsplit_01")

    -- store model bounds to help with render bounds
    local min, max = self:GetModelBounds()
    self._bbMin = min or Vector(-32, -32, -32)
    self._bbMax = max or Vector(32, 32, 32)

    -- timing
    self._tStart = CurTime()
    self._tDie = self._tStart + self.LifeTime

    -- seed / randomness that can emulate material randomness if needed
    self._rand = math.random() 

    -- initial per-effect user defaults approximated from JSON:
    -- ColorCurve early sample: ~cyan/teal (R≈0, G≈0.27, B≈0.5, A≈1.0)
    -- We'll treat these as 0-255 ints for SetColor.
    self._startColor = Color(0, 69, 128, 255) -- approx (0,0.27,0.5) *255
    self._endColor   = Color(18, 18, 18, 0)   -- near-dark with 0 alpha at end

    -- alpha & timing envelope:
    self._fadeInTime = math.min(0.12 * self.LifeTime, 0.15)  -- short fade in (12% life max 0.15s)
    self._fadeOutTime = 0.9 * self.LifeTime                    -- start heavy fade near the end

    -- scale envelope (we'll make it grow slightly then shrink)
    self._baseModelScale = 1.0 -- model intrinsic scale
    self._endScaleMul = 0.1    -- final scale multiplier relative to start

    -- initial scale set immediately (SetModelScale changes drawing size)
    self:SetModelScale(self._baseModelScale * self.Scale, 0)

    -- ensure it has big enough bounds so it's visible while animating (local-space effect)
    local expand = math.max(self.Scale * 64, 128)
    self:SetRenderBounds(self._bbMin * expand, self._bbMax * expand)

    -- allow shadows off for sprite-like look (optional)
    self:DrawShadow(false)
	self.EFFECT_NE_MeshM001_1 = ClientsideModel(NE_MeshM001_1,RENDERGROUP_BOTH) 
	local EFFECT_NE_MeshM001_1 = self.EFFECT_NE_MeshM001_1 
	EFFECT_NE_MeshM001_1:SetPos(self:GetPos()) 
	EFFECT_NE_MeshM001_1:SetAngles(self:GetAngles()) 
	EFFECT_NE_MeshM001_1:SetModelScale(self:GetModelScale()) 
	EFFECT_NE_MeshM001_1:SetColor(self:GetColor()) 
	-- self:NE_MeshM001_1(data) 
	self:NE_MeshM002_1(data) 
end 

-- Main: create clientsidemodel and let RenderOverride drive lifetime, color, scale, alpha
function EFFECT:NE_MeshM002_1(data)
    local origin = data:GetOrigin()
    local ang = data:GetAngles()
    local scaleMul = data:GetScale() or 1
    local lifeMul = data:GetMagnitude() or 1

    -- sane defaults
    if scaleMul <= 0 then scaleMul = 1 end
    if lifeMul <= 0.01 then lifeMul = 1 end
	scaleMul = 0.1 

    local ent = ClientsideModel(NE_MeshM, RENDERGROUP_OPAQUE)

    ent:SetPos(origin)
    ent:SetAngles(ang)
    ent:DrawShadow(false)

    -- timing
    ent._ne_start = CurTime()
    ent._ne_die = ent._ne_start + lifeMul

    -- per-entity tuning derived from JSON analysis
    ent._ne_scaleMul = scaleMul
    ent._ne_baseModelScale = 1.0
    ent._ne_rand = math.Rand(0, 1)

    -- color curve approximation (NE_MeshM002 used cyan/teal -> dim)
    ent._ne_col_start = Color(77, 223, 255, 255) -- ~ (0.30,0.87,1.0)
    ent._ne_col_end   = Color(20, 20, 20, 0)     -- dark + transparent end

    -- alpha envelope timings (short fade-in, longer fade-out)
    ent._ne_fadeInTime = math.min(0.1 * lifeMul, 0.12)
    ent._ne_fadeOutStart = 0.8 * lifeMul

    -- render bounds to avoid culling
    local minb, maxb = ent:GetModelBounds()
    local expand = math.max(ent._ne_scaleMul * 64, 128)
    ent:SetRenderBounds(minb * expand, maxb * expand)

    -- safety cleanup timer in case RenderOverride isn't called (small buffer)
    timer.Simple(lifeMul + 0.3, function()
        if IsValid(ent) then SafeRemoveEntity(ent) end
    end)

    -- RenderOverride: both think & render
    ent.RenderOverride = function(ent, flags)
        local ct = CurTime()
        local lifeT = (ct - ent._ne_start) / math.max(0.00001, (ent._ne_die - ent._ne_start))
        lifeT = math.Clamp(lifeT, 0, 1)

        -- ALPHA envelope:
        local alphaMul = 1
        if ct < (ent._ne_start + ent._ne_fadeInTime) then
            local t = (ct - ent._ne_start) / math.max(0.00001, ent._ne_fadeInTime)
            alphaMul = math.ease.InQuad(math.Clamp(t, 0, 1))
        elseif ct >= (ent._ne_start + ent._ne_fadeOutStart) then
            local t = (ct - (ent._ne_start + ent._ne_fadeOutStart)) / math.max(0.00001, (ent._ne_die - (ent._ne_start + ent._ne_fadeOutStart)))
            alphaMul = 1 - math.ease.OutQuad(math.Clamp(t, 0, 1))
        else
            alphaMul = 1
        end

        -- additional alpha curve to mimic Scale Alpha LUT (gentle overall decay)
        local alphaCurve = 1 - math.ease.OutQuad(lifeT) * 0.98
        local finalAlpha = math.Clamp(alphaMul * alphaCurve, 0, 1)

        -- COLOR curve: map life -> color via a smooth s-curve
        local colT = math.ease.InOutCubic(lifeT)
        local curColor = lerpColor(ent._ne_col_start, ent._ne_col_end, colT)
        curColor.a = math.floor(255 * finalAlpha)
		local Velocity = math.Remap(curColor.a,0,255,0,1) 
		ent:SetVelocity(ent:GetForward()*Velocity) 

        -- SCALE curve: small grow early then shrink
        local growT = math.Clamp(lifeT / 0.18, 0, 1)
        local growMul = 1 + 0.14 * math.ease.OutQuad(growT) -- slight overshoot
        local shrinkT = math.Clamp((lifeT - 0.18) / 0.82, 0, 1)
        local scaleCurveMul = Lerp(growMul, 0.12, math.ease.InQuad(shrinkT)) -- final small scale
        local modelScale = ent._ne_baseModelScale * ent._ne_scaleMul * scaleCurveMul
        ent:SetModelScale(modelScale, 0)

        -- subtle rotation / orientation drift to emulate MeshOrientationBinding
        local ang = ent:GetAngles()
        ang:RotateAroundAxis(ang:Up(), 30 * FrameTime() * (0.6 + ent._ne_rand))
        ang:RotateAroundAxis(ang:Right(), 12 * FrameTime() * (0.4 + ent._ne_rand))
        ent:SetAngles(ang)

        -- write color & alpha (VMT must respect vertexcolor/vertexalpha)
        ent:SetColor(curColor)
		-- print(ent,curColor) 

        -- update render bounds to follow scale
        local minb2, maxb2 = ent:GetModelBounds()
        local expand2 = math.max(modelScale * 64, 128)
        ent:SetRenderBounds(minb2 * expand2, maxb2 * expand2)

        -- draw model (pass flags if provided)
		ent:DrawModel(flags)

        -- removal
        if lifeT >= 1 then
            SafeRemoveEntity(ent)
            return
        end
    end

    -- return the ent in case caller wants a handle
    return ent
end