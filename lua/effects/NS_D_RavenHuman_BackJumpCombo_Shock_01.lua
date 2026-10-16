-- NS_D_RavenHuman_BackJumpCombo_Shock_01.lua 
-- Garry's Mod clientside EFFECT replicating NS_D_RavenHuman_BackJumpCombo_Shock_01
-- Optimized for high performance and low GC overhead.

EFFECT.NextAuroraTime = CurTime() 

-- Configuration approximating the original FX_AddQuad calls
local QUADS = {
    {
        texture = "sprites/t_a_shockaura_01",
        startSize = 16,
        endSize   = 300 * 10,
        startAlpha = 4000.0,
        endAlpha   = 0.0,
        lifeTime = 1.25, 
        dynamicFarSize = true, 
        Color = color_white 
    },
    {
        texture = "sprites/ar2_muzzle1", 
        startSize = 16,
        endSize   = 300 * 10,
        startAlpha = 2000.0,
        endAlpha   = 0.0,
        lifeTime = 1.25,
        dynamicFarSize = true, 
        Color = Color(50, 255, 255) 
    },
    {
        texture = "sprites/T_A_FlareRing_02", 
        startSize = 16,
        endSize   = 300 * 12,
        startAlpha = 3000.0,
        endAlpha   = 0.0,
        lifeTime = 1.25,
        Color = color_white 
    },
}

-- Static vectors & cached constants to prevent GC churn
local up_16        = Vector(0, 0, 16) 
local down_150     = Vector(0, 0, -150) 
local vec_up_1      = Vector(0, 0, 1)
local vec_up_100    = Vector(0, 0, 100)
local vec_up_300    = Vector(0, 0, 300)
local vec_aurora_vel = Vector(0, 0, -0.8)
local vec_scratch   = Vector()
local ang_aurora    = Angle(0, 0, 90)

local DEG2RAD = math.pi / 180

-- Cached materials
local mat_bulge = Material("effects/strider_bulge_dudv")
local mat_pinch = Material("effects/strider_pinch_dudv")

-- Utility: build an angle facing the surface normal
local function AngleForNormal(normal)
    local ang = normal:Angle()
    ang:RotateAroundAxis(ang:Right(), 180)
    return ang
end

-- =========================================================================
-- OPTIMIZED PARTICLE THINK FUNCTIONS (Stored in EFFECT scope)
-- =========================================================================

EFFECT.FlareThink = function(prt)
    local ct = CurTime()
    local ft = FrameTime()

    -- 1. Direction jitter timer
    if ct >= prt.NextTurnTime then
        local cDir = prt.CurrentDir
        local tDir = prt.TargetDir
        tDir:SetUnpacked(
            cDir.x + 0.7 * (0.5 - math.random()),
            cDir.y + 0.7 * (0.5 - math.random()),
            cDir.z + 0.7 * (0.5 - math.random())
        )
        tDir:Normalize()
        prt.NextTurnTime = ct + 0.15
    end

    -- 2. In-place rotation lerp (avoids LerpVector allocations)
    local cDir = prt.CurrentDir
    local tDir = prt.TargetDir
    local turnFactor = ft * 10

    cDir.x = cDir.x + (tDir.x - cDir.x) * turnFactor
    cDir.y = cDir.y + (tDir.y - cDir.y) * turnFactor
    cDir.z = cDir.z + (tDir.z - cDir.z) * turnFactor
    cDir:Normalize()

    -- 3. In-place velocity assignment
    local vel = prt.VelCache
    vel:Set(cDir)
    vel:Mul(prt.Speed)
    prt:SetVelocity(vel)

    -- 4. Dynamic size oscillation
    local curStartSize = prt:GetStartSize()
    if curStartSize >= 10 then 
        prt.SizeIncrementType = -2 
    elseif curStartSize <= 0 then 
        prt.SizeIncrementType = 2 
    end 
    prt:SetStartSize(curStartSize + prt.SizeIncrementType) 
    prt:SetEndSize(prt:GetEndSize() + prt.SizeIncrementType) 

    prt:SetNextThink(ct + ft) 
end

EFFECT.SparkThink = function(prt)
    local ct = CurTime()
    local ft = FrameTime()

    -- 1. Direction jitter timer
    if ct >= prt.NextTurnTime then
        local cDir = prt.CurrentDir
        local tDir = prt.TargetDir
        tDir:SetUnpacked(
            cDir.x + 0.7 * (0.5 - math.random()),
            cDir.y + 0.7 * (0.5 - math.random()),
            cDir.z + 0.7 * (0.5 - math.random())
        )
        tDir:Normalize()
        prt.NextTurnTime = ct + 0.15
    end

    -- 2. In-place rotation lerp
    local cDir = prt.CurrentDir
    local tDir = prt.TargetDir
    local turnFactor = ft * 10

    cDir.x = cDir.x + (tDir.x - cDir.x) * turnFactor
    cDir.y = cDir.y + (tDir.y - cDir.y) * turnFactor
    cDir.z = cDir.z + (tDir.z - cDir.z) * turnFactor
    cDir:Normalize()

    local vel = prt.VelCache
    vel:Set(cDir)
    vel:Mul(prt.Speed)
    prt:SetVelocity(vel)

    -- 3. In-place angle and roll calculation (no Vector:Angle garbage)
    local pitch = -math.deg(math.asin(math.Clamp(cDir.z, -1, 1)))
    local yaw   = math.deg(math.atan2(cDir.y, cDir.x))
    
    local ang = prt.AngCache
    ang:SetUnpacked(pitch, yaw, 0)
    prt:SetAngles(ang)
    prt:SetRoll(yaw * DEG2RAD)

    local interval = prt:GetLifeTime() / prt:GetDieTime() 
    prt:SetColor(255 * (1 - interval), 255, 255) 

    prt:SetNextThink(ct) 
end

EFFECT.AuroraThink = function(p)
    local cycle = p:GetLifeTime() / p:GetDieTime() 
    p:SetColor(1 * cycle, 255 * (1 - cycle), 255 * (1 - cycle)) 
    p:SetNextThink(CurTime()) 
end

EFFECT.SpikeThink = function(p)
    p:SetNextThink(CurTime() + FrameTime()) 
    local cycle = p:GetLifeTime() / p:GetDieTime() 
    
    if p:GetLifeTime() >= 0.5 and not p.aftereffect then 
        p.aftereffect = true 
        local currentEndSize = p:GetEndSize() * cycle
        p:SetEndSize(currentEndSize) 
        p:SetStartSize(currentEndSize) 
        
        local currentEndLength = p:GetEndLength() * cycle
        p:SetStartLength(currentEndLength) 
        p:SetEndLength(currentEndLength) 
    end 
    
    if p.aftereffect then 
        local cycleAfter = math.Remap(cycle, 0.8, 1, 0, 1) 
        p:SetEndSize(p:GetStartSize() * (1 - cycleAfter)) 
    end 
end

EFFECT.BulgeThink = function(p)
    local cycle = 1 - (p:GetLifeTime() / p:GetDieTime()) 
    mat_bulge:SetFloat("$refractamount", cycle) 
    p:SetNextThink(CurTime()) 
end

EFFECT.PinchThink = function(p)
    local cycle = 1 - (p:GetLifeTime() / p:GetDieTime()) 
    mat_pinch:SetFloat("$refractamount", cycle) 
    p:SetNextThink(CurTime()) 
end

-- =========================================================================
-- EFFECT:Init
-- =========================================================================
function EFFECT:Init(data)
    self.Origin = data:GetOrigin() or vector_origin 
    self.Emitter = ParticleEmitter(self.Origin) 
    self.Emitter_3d = ParticleEmitter(self.Origin, true) 
    self.CreationTime = CurTime() 
    self.LifeTime = data:GetMagnitude() 

    local startPos = self.Origin + up_16
    local endPos   = self.Origin + down_150 

    local tr = util.TraceLine({
        start = startPos,
        endpos = endPos,
        mask = MASK_SOLID_BRUSHONLY,
        filter = function(ent) return false end
    })

    if not tr.Hit or tr.Fraction >= 1 then
        self.Projectors = {}
        self:SpawnSmallFallback()
        self.DieTime = CurTime() + 0.2
        return
    end

    local hitPos = tr.HitPos
    local hitNormal = tr.HitNormal

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

    self.Projectors = {}

    for i, q in ipairs(QUADS) do
        local p = ProjectedTexture()
        p:SetPos(hitPos + hitNormal * 8)
        
        local ang = AngleForNormal(hitNormal)
        ang:SetUnpacked(ang.p, ang.y + math.random(-180, 180), ang.r)  
        
        p:SetOrthographic(true, -q.startSize, -q.startSize, q.startSize, q.startSize)
        p:SetNearZ(0)
        p:SetFarZ(0)
        p:SetLightWorld(true)
        p:SetTexture(q.texture)
        p:SetBrightness(q.startAlpha)
        p:SetAngles(ang)
        p:SetColor(q.Color) 
        p:Update()

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
            dynamicFarSize = q.dynamicFarSize, 
            Color = q.Color 
        })
    end

    if IsValid(self.Emitter) then
        for i = 1, 10 do
            local vel = VectorRand() * math.Rand(10, 100)
            local p = self.Emitter:Add("effects/rollerglow", hitPos + VectorRand() * 4)
            if p then
                p:SetVelocity(vel)
                p:SetDieTime(0.3 + math.Rand(0, 0.4))
                p:SetStartAlpha(255)
                p:SetEndAlpha(0)
                p:SetStartSize(math.Rand(6, 12))
                p:SetEndSize(0)
                p:SetRoll(math.Rand(0, 360))
                p:SetColor(0, 255, 255)
                p:SetAirResistance(50)
            end
        end

        -- 2. DENSE RADIAL GROUND SPIKES / NEEDLES
        local spikeCount = 180
        for i = 1, spikeCount do
            if math.random() > 0.5 then continue end 
            
            local angle = math.rad((i / spikeCount) * 360 + math.Rand(-2, 2))
            local forwardDir = Vector(math.cos(angle), math.sin(angle), 0)
            forwardDir = (forwardDir - hitNormal * forwardDir:Dot(hitNormal)):GetNormalized()
            
            local p = self.Emitter:Add("effects/spark", hitPos + hitNormal * 3 + forwardDir * math.Rand(10, 40))
            if p then
                p:SetVelocity(forwardDir * 1)
                p:SetDieTime(1.2)
                p:SetStartAlpha(255)
                p:SetEndAlpha(0)
                p:SetStartSize(math.Rand(20, 35))
                p:SetEndSize(math.random(40, 70)) 
                p:SetStartLength(10)
                p:SetEndLength(math.random(140, 320) * 10)
                p:SetNextThink(CurTime() + FrameTime()) 
                
                if math.random() > 0.4 then
                    p:SetColor(220, 255, 255)
                else
                    p:SetColor(0, 220, 255)
                end
                p:SetThinkFunction(self.SpikeThink) 
            end
        end

        -- Refract bulges
        local pBulge = self.Emitter:Add("effects/strider_bulge_dudv", hitPos) 
        if pBulge then
            pBulge:SetStartSize(0) 
            pBulge:SetEndSize(1500) 
            pBulge:SetDieTime(0.1) 
            pBulge:SetThinkFunction(self.BulgeThink) 
        end

        local pPinch = self.Emitter:Add("effects/strider_pinch_dudv", hitPos) 
        if pPinch then
            pPinch:SetStartSize(0) 
            pPinch:SetEndSize(1500) 
            pPinch:SetDieTime(0.1) 
            pPinch:SetThinkFunction(self.PinchThink) 
        end

        -- 3. EXPANDING HORIZONTAL 3D SHOCKWAVE RING
        local ring = self.Emitter_3d:Add("effects/select_ring", hitPos + hitNormal * 2)
        if ring then
            ring:SetAngles(hitNormal:Angle())
            ring:SetDieTime(0.4)
            ring:SetStartAlpha(255)
            ring:SetEndAlpha(0)
            ring:SetStartSize(20)
            ring:SetEndSize(1200)
            ring:SetColor(100, 240, 255)
        end

        -- 4. GROUND MIST / ENERGY WISPS
        for i = 1, 75 do
            local theta = math.random() * math.pi * 2
            local z = math.random()
            local r = math.sqrt(1 - z * z)
            local dir = Vector(r * math.cos(theta), r * math.sin(theta), z)

            local p = self.Emitter:Add("particle/smokesprites_000" .. math.random(1, 9), hitPos + hitNormal * 4)
            if p then
                p:SetVelocity(dir * 600)
                p:SetDieTime(1.2)
                p:SetStartAlpha(255)
                p:SetEndAlpha(0)
                p:SetStartSize(math.random(5, 10))
                p:SetEndSize(math.random(30, 100))
                p:SetRoll(math.random(0, 3.14))
                p:SetRollDelta(math.Rand(-0.4, 0.4))
                p:SetAirResistance(60)
                p:SetColor(60, 255, 220)
            end
        end
    end 

    local maxLife = 0
    for _, v in ipairs(QUADS) do maxLife = math.max(maxLife, v.lifeTime) end
    self.DieTime = CurTime() + maxLife + 0.1
end

function EFFECT:SpawnSmallFallback()
    local emitter = ParticleEmitter(self.Origin, true)
    local p = emitter:Add("sprites/rollerglow_gray", self.Origin + VectorRand() * 4)
    if p then
        p:SetAngles(Angle(-90, 0, 0))
        p:SetDieTime(1)
        p:SetStartAlpha(255)
        p:SetEndAlpha(0)
        p:SetStartSize(0)
        p:SetEndSize(300)
        p:SetColor(255, 255, 255)
    end
    emitter:Finish()
end

-- =========================================================================
-- EFFECT:Think
-- =========================================================================
function EFFECT:Think()
    local ct = CurTime()
    local ft = FrameTime()

    if self.DLight then
        self.DLight.pos = self.Origin
    end

    if self.Projectors and #self.Projectors > 0 then
        for i = #self.Projectors, 1, -1 do
            local info = self.Projectors[i]
            local ptex = info.ptex
            if not IsValid(ptex) then
                table.remove(self.Projectors, i)
                continue 
            end

            local t = (ct - info.startTime) / info.lifeTime
            if t < 0 then t = 0 end

            local size = Lerp(t, info.startSize, info.endSize)
            local alpha = Lerp(t, info.startAlpha, info.endAlpha)
            local brightness = math.max(0.0, alpha)

            ptex:SetPos(info.pos)
            if info.dynamicFarSize then 
                ptex:SetOrthographic(true, -info.endSize, -info.endSize, info.endSize, info.endSize) 
                ptex:SetFarZ(size)
            else 
                ptex:SetOrthographic(true, -size, -size, size, size) 
                ptex:SetFarZ(info.endSize)
            end 
            ptex:SetBrightness(brightness)
            ptex:SetTexture(info.texture)
            ptex:SetColor(info.Color) 
            ptex:SetConstantAttenuation(size * 100) 
            ptex:Update()

            if t >= 1.0 then
                ptex:Remove()
                table.remove(self.Projectors, i)
            end
        end
    end

    -- Cached effect center position once per think
    local effectPos = self:GetPos()
    local cycle = (ct - self.CreationTime) / (self.DieTime - self.CreationTime)
    local spread = cycle * 2000

    -- Aurora emission
    if self.NextAuroraTime <= ct then 
        vec_scratch:Set(effectPos)
        vec_scratch.x = vec_scratch.x + math.Rand(-1, 1) * spread
        vec_scratch.y = vec_scratch.y + math.Rand(-1, 1) * spread
        vec_scratch.z = vec_scratch.z + 650

        local p = self.Emitter:Add("effects/energysplash", vec_scratch) 
        if p then 
            p:SetVelocity(vec_aurora_vel) 
            p:SetDieTime(0.3 + math.Rand(0, 0.4)) 
            p:SetStartAlpha(100)
            p:SetEndAlpha(0)
            p:SetStartSize(160)
            p:SetEndSize(160)
            p:SetColor(0, 255, 255)
            p:SetGravity(vec_up_1) 
            
            ang_aurora.y = math.random(-180, 180)
            p:SetAngles(ang_aurora) 
            p:SetStartLength(1500) 
            p:SetEndLength(1500) 
            p:SetVelocityScale(true) 
            p.CreationTime = ct 
            p:SetThinkFunction(self.AuroraThink) 
        end 
        self.NextAuroraTime = ct + 0.01 
    end 

    -- Emitting Flares and Sparks without garbage generation
    for i = 1, 50 do 
        vec_scratch:Set(effectPos)
        vec_scratch.x = vec_scratch.x + math.Rand(-1, 1) * spread
        vec_scratch.y = vec_scratch.y + math.Rand(-1, 1) * spread

        if math.random() >= 0.7 then 
            local p = self.Emitter:Add("sprites/mi_e_lensflare_03", vec_scratch) 
            if p then
                local initialSpeed = 100
                p:SetVelocity(vec_up_100) 
                p:SetDieTime(math.random(4, 5)) 
                p:SetStartAlpha(255)
                p:SetEndAlpha(0)
                p:SetStartSize(math.random() * 10)
                p:SetEndSize(0)
                p:SetColor(255, 255, 255)
                p:SetGravity(vec_up_1) 
                
                -- Particle state caching
                p.CreationTime = ct 
                p.NextTurnTime = ct
                p.Speed = initialSpeed
                p.SizeIncrementType = -1 
                p.CurrentDir = Vector(0, 0, 1)
                p.TargetDir  = Vector(0, 0, 1)
                p.VelCache   = Vector(0, 0, initialSpeed)

                p:SetThinkFunction(self.FlareThink) 
                p:SetNextThink(ct + ft) 
            end
        else 
            local p = self.Emitter:Add("effects/spark", vec_scratch) 
            if p then
                local initialSpeed = 300
                p:SetVelocity(vec_up_300) 
                p:SetDieTime(5) 
                p:SetStartAlpha(255)
                p:SetEndAlpha(0)
                p:SetStartSize(20)
                p:SetEndSize(0)
                p:SetColor(255, 255, 255)
                p:SetGravity(vec_up_1) 
                p:SetStartLength(0.1) 
                p:SetEndLength(0) 
                p:SetVelocityScale(true) 
                
                -- Particle state caching
                p.CreationTime = ct 
                p.NextTurnTime = ct
                p.Speed = initialSpeed
                p.CurrentDir = Vector(0, 0, 1)
                p.TargetDir  = Vector(0, 0, 1)
                p.VelCache   = Vector(0, 0, initialSpeed)
                p.AngCache   = Angle(0, 0, 0)

                p:SetThinkFunction(self.SparkThink) 
                p:SetNextThink(ct) 
            end
        end 
    end

    if ct >= self.DieTime then
        if self.Projectors then
            for _, info in ipairs(self.Projectors) do
                if info and IsValid(info.ptex) then
                    info.ptex:Remove()
                end
            end
            self.Projectors = {}
        end

        if self.DLight then
            self.DLight.dietime = ct
            self.DLight = nil
        end
        
        if IsValid(self.Emitter) then 
            self.Emitter:Finish() 
        end 
        if IsValid(self.Emitter_3d) then 
            self.Emitter_3d:Finish() 
        end 
        return false
    end

    self:SetNextClientThink(ct + ft) 
    return true
end

function EFFECT:Render()
    -- Handled by projected textures & emitters
end

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