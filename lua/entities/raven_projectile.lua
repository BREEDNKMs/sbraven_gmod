-- M_Raven_BackJumpCombo_Projectile1 

AddCSLuaFile() 

ENT.Author			= "DevilHawk" 
ENT.Base			= "proj_unreali_skaarjprojectile" 
ENT.PrintName		= "Raven's Sword Aura" 
ENT.Spawnable		= false 
ENT.Type 			= "anim" 

-- SERVER VARIABLES BELOW 

ENT.angRotation				=	Angle(0,0,0) 
ENT.bBounce					=	false 
ENT.bRemoveOnHit			=	true 
ENT.bSwitchSprites			=	false 
ENT.bHasBlastExplosion		=	false 
ENT.bHasInflictDamage		=	true 
ENT.bHasExplosionSprite		=	true 
ENT.bPlaySpriteOnAliveHit	=	true 

ENT.flVelocity				=	2000 
ENT.strExplosionSprite		=	"materials/sprites/dseb_a00.vmt" 
ENT.strModel				=	Model("models/stellarblade/SM_C_SwordPrjTrail_01.mdl") 
ENT.strSpawnSound			=	Sound("") -- "skill/monster/raven/M_Raven_Skill_Shot.wav" 
ENT.strHitSound				=	Sound("unreali/dispex1.wav") 
ENT.LoopSound				=	Sound("skill/monster/raven/M_Raven_Skill_Projectile_Loop_1.wav") 
ENT.LoopSoundLevel			=	75 
ENT.vecCollisionMins		=	Vector(-16,-16,-1) 
ENT.vecCollisionMaxs		=	Vector(16,16,16) 

ENT.InflictDamage_flDamageTypes = DMG_ENERGYBEAM 
ENT.InflictDamage_flDamage = 1300 

ENT.RavenProjectile_TargetScale = Vector(2,2,10) 

ENT.light_size					=	256 -- local dynamic lighting 
ENT.light_decay					=	0 
ENT.light_R						=	0 
ENT.light_G						=	255 
ENT.light_B						=	255 
ENT.light_brightness			=	255 

-- CLIENT VARIABLES BELOW 

-- Curve Data (Approximating Niagara Curves) 
-- Color: Hot White -> Orange -> Red -> Invisible 
local COLOR_LIFE = { 
    [0.0] = Color(255, 255, 255, 255), -- Start: White Hot 
    [0.2] = Color(255, 200, 100, 255), -- 20%: Bright Orange 
    [0.5] = Color(200, 50, 10, 255),   -- 50%: Deep Red 
    [1.0] = Color(0, 0, 0, 0)          -- End: Invisible 
} 

local COLOR2_LIFE = {
    [0.0] = Color(255, 230, 200, 255), -- Start: Slightly warmer white
    [0.1] = Color(255, 150, 50, 255),  -- 10%: Rapidly turns Orange
    [0.4] = Color(150, 30, 5, 200),    -- 40%: Dark Red & starting to fade
    [1.0] = Color(0, 0, 0, 0)          -- End: Invisible
}

ENT.RenderSprite = false 
ENT.LastPos = vector_origin 	
ENT.LastPos2 = vector_origin 	
ENT.SpawnAccumulator = 0
ENT.SpawnAccumulator2 = 0
ENT.SpawnRate = 100 -- Particles per second (Adjust for density) 
ENT.SpawnRate2 = 100 -- Particles per second (Adjust for density) 

ENT.NE_RibbonM = { } 
ENT.NE_RibbonM001 = { } 
ENT.NE_SparkM003 = { } 
local NE_RibbonM = ENT.NE_RibbonM 
local NE_RibbonM001 = ENT.NE_RibbonM001 
local NE_SparkM003 = ENT.NE_SparkM003 
NE_RibbonM.Mat = Material("sprites/mi_d_ravenhuman_ribbon_03")

-- Lifetime of a segment (how long a trail point persists)
NE_RibbonM.SegmentLifetime = 0.4

-- Base width in world units (maps to RibbonWidth module)
NE_RibbonM.BaseWidth = 10.0

-- UV tiling length (maps to Niagara UV TilingLength)
NE_RibbonM.TilingLength = 150.0

-- HDR multiplier to mimic brightness scaling
NE_RibbonM.HDRMultiplier = 10.0

-- Small global width multiplier if you want to tune quickly
NE_RibbonM.WidthMultiplier = 1 

NE_RibbonM001.Mat = Material("sprites/mi_d_ravenhuman_ribbon_03")

-- Config (tweak as needed)
NE_RibbonM001.SegmentLifetime = 0.4        -- how long each trail segment lives (seconds)
NE_RibbonM001.BaseWidth      = 10.0       -- base width in world units
NE_RibbonM001.TilingLength   = 300.0      -- UV tiling length (matches NE_RibbonM001)
NE_RibbonM001.HDRMultiplier  = 1.0
NE_RibbonM001.WidthMultiplier = 1.0       -- global tuning

-- Interpolated spawning config
NE_RibbonM001.MinStepDist = 4.0           -- when moving more than this, insert intermediate points
NE_RibbonM001.MaxInterpolationSteps = 8   -- cap to avoid huge spikes

NE_SparkM003.BASE_MATERIAL = "sprites/mi_d_raven_goldparts_1" -- Path to your .vmt (no extension)

-- === Config derived from JSON / approximations ===
NE_SparkM003.SPAWN_RATE = 30                -- particles per second (approximate)
NE_SparkM003.SPAWN_RADIUS = 4.5             -- lathe/cylinder radius (derived)
NE_SparkM003.SPAWN_RADIUS_JITTER = 0.35     -- percent jitter to avoid perfectly uniform ring
NE_SparkM003.SPAWN_ANGLE_RINGS = 1         -- number of rings per spawn (1 => single ring)
NE_SparkM003.LIFETIME_MIN, NE_SparkM003.LIFETIME_MAX = 0.18, 0.45  -- seconds (short-lived sparks)
NE_SparkM003.START_SIZE_MIN, NE_SparkM003.START_SIZE_MAX = 1.5, 4 -- world units (start)
NE_SparkM003.END_SIZE_FACTOR = 0.12         -- end size relative to start (shrinks)
NE_SparkM003.INHERIT_VELOCITY = 0.6         -- fraction of projectile velocity inherited
NE_SparkM003.OUTWARD_SPEED_MIN, NE_SparkM003.OUTWARD_SPEED_MAX = 80, 220 -- radial ejection speeds
NE_SparkM003.GRAVITY = Vector(0, 0, -600)   -- NE_SparkM003.gravity applied to sparks
NE_SparkM003.AIR_RESIST = 40                -- air resistance
NE_SparkM003.SPAWN_MIN_STEP = 3.5           -- interpolated spawn threshold (units)
NE_SparkM003.MAX_INTERP_STEPS = 8

-- Twinkle parameters (mapped from instance)
NE_SparkM003.TWINKLE_PROBABILITY = 0.06  -- small chance at spawn to be a bright twinkle
NE_SparkM003.TWINKLE_BRIGHT_MULT = 2.4

local function GetQualityScale()
    -- In the JSON there is a scalability override that reduces spawn to 0.1 on low quality.
    -- We'll check a typical GMod cvar and map it simply (you can expand).
    if GetConVarNumber and GetConVarNumber("mat_picmip") >= 2 then
        return 0.25
    end
    return 1.0
end

NE_SparkM003.ScaleFactor = function(t)
    -- t in [0,1] where 0 = new, 1 = dead
    local k = math.ease.InOutSine(math.Clamp(t,0,1))
    local startS, endS = 0.85, 0.67
    return Lerp(k,startS, endS), Lerp(k,startS, endS)
end 

-- Alpha pop+fade (Scale Alpha)
NE_SparkM003.AlphaCurve = function(t)
    -- quick pop first ~12% then fade
    local popEnd = 0.12
    if t < popEnd then
        local p = t / popEnd
        return math.ease.OutCubic(p)
    else
        local p = (t - popEnd) / (1 - popEnd)
        return math.Clamp(1 - math.ease.OutQuad(p), 0, 1)
    end
end

NE_SparkM003.BrightnessCurve = function(t)
    -- strong early brightness, decays
    return Lerp(math.ease.InOutSine(math.Clamp(t,0,1)),1.6, 0.25)
end

-- ColorCurve (approx): gold -> orange over life (values 0..255)
NE_SparkM003.ColorCurve = function(t)
    local r1,g1,b1 = 1.00, 0.86, 0.25  -- bright gold (0..1)
    local r2,g2,b2 = 1.00, 0.55, 0.08  -- orange
    local k = math.ease.InOutSine(math.Clamp(t,0,1))
    local r = Lerp(k,r1, r2)
    local g = Lerp(k,g1, g2)
    local b = Lerp(k,b1, b2)
    return math.floor(math.Clamp(r * 255, 0, 255)),
           math.floor(math.Clamp(g * 255, 0, 255)),
           math.floor(math.Clamp(b * 255, 0, 255))
end

-- Lathe/radial offset (approx of the Lathe Profile DI)
NE_SparkM003.LatheOffset = function(angleRad)
    -- small sinusoidal ripple to mimic the lathe sampled profile
    local base = NE_SparkM003.SPAWN_RADIUS
    local ripple = 1 + 0.12 * math.sin(angleRad * 3 + CurTime() * 12)
    return base * ripple
end

-- A tiny curl-noise approximation for GMod (per-particle, deterministic via seed)
NE_SparkM003.CurlNoiseVel = function(seed, pos)
    -- produce a small lateral oscillation based on seed & position
    local t = CurTime()
    local sx = math.sin(t * 6 + seed * 12 + pos.x * 0.04) * 20
    local sy = math.cos(t * 5 + seed * 9 + pos.y * 0.03) * 20
    local sz = math.sin(t * 7 + seed * 5 + pos.z * 0.02) * 8
    return Vector(sx, sy, sz)
end

-- Helper: Linear Interpolation for Color
local function LerpColor(t, c1, c2)
    return Color(
        Lerp(t, c1.r, c2.r),
        Lerp(t, c1.g, c2.g),
        Lerp(t, c1.b, c2.b),
        Lerp(t, c1.a, c2.a)
    )
end 

-- Sample Width curve: returns multiplier [0..1.2] roughly
local function SampleWidthCurve(t)
    -- t in [0,1]
    if t <= 0.2 then
        -- start thin -> quickly go to near 1 using an ease-out
        local localT = t / 0.2
        return Lerp(math.ease.OutQuad(localT), 0.2, 1.0)
    elseif t <= 0.8 then
        -- stable wide area: slight ramp using ease in/out
        local localT = (t - 0.2) / 0.6
        return Lerp(math.ease.InOutSine(localT), 1.0, 0.85)
    else
        -- fade to zero at the very end
        local localT = (t - 0.8) / 0.2
        return Lerp(math.ease.InQuad(localT), 0.85, 0.0)
    end
end

-- Sample Alpha (Scale Alpha) curve: keep opaque early then fade out
local function SampleAlphaCurve(t)
    -- t in [0,1]
    if t <= 0.2 then
        return 1.0
    end
    -- fade with ease-out so it feels smooth
    local localT = (t - 0.2) / 0.8
    return Lerp(math.ease.OutQuad(localT), 1.0, 0.0)
end

local function SampleAlphaCurve_RibbonM001(t)
    if t <= 0.15 then
        return 1.0
    end
    local localT = (t - 0.15) / 0.85
    return Lerp(math.ease.OutQuad(math.Clamp(localT, 0, 1)), 1.0, 0.0)
end

-- Sample Brightness curve (Scale Brightness): decays over life
local function SampleBrightnessCurve(t)
    -- subtle brighter at start -> then decay
    return Lerp(math.ease.InOutSine(t), 1.6, 0.2)
end 

-- Sample Color curve (approx): from teal-ish to bright cyan -> then dim
local function SampleColorCurve(t)
    -- returns r,g,b in 0..255
    -- start: deep teal (40,160,220) -> mid: cyan (80,200,255) -> end: darker (30,100,140)
    if t <= 0.5 then
        local localT = t / 0.5
        local r = Lerp(math.ease.InOutSine(localT), 40, 80)
        local g = Lerp(math.ease.InOutSine(localT), 160, 200)
        local b = Lerp(math.ease.InOutSine(localT), 220, 255)
        return r, g, b
    else
        local localT = (t - 0.5) / 0.5
        local r = Lerp(math.ease.OutQuad(localT), 80, 30)
        local g = Lerp(math.ease.OutQuad(localT), 200, 100)
        local b = Lerp(math.ease.OutQuad(localT), 255, 140)
        return r, g, b
    end
end

-- Color curve: teal -> cyan -> cool dim
local function SampleColorCurve_RibbonM001(t)
    if t <= 0.5 then
        local u = t / 0.5
        local r = Lerp(math.ease.InOutSine(u), 40, 80)
        local g = Lerp(math.ease.InOutSine(u), 160, 200)
        local b = Lerp(math.ease.InOutSine(u), 220, 255)
        return r, g, b
    else
        local u = (t - 0.5) / 0.5
        local r = Lerp(math.ease.OutQuad(u), 80, 30)
        local g = Lerp(math.ease.OutQuad(u), 200, 100)
        local b = Lerp(math.ease.OutQuad(u), 255, 140)
        return r, g, b
    end
end

-- Secondary param (Index 0 Param 2) for subtle shape/brightness tweaks
local function SampleParam2(t)
    -- starts bigger then decays to ~1.0
    return 1.0 + 1.5 * (1 - math.ease.OutCubic(math.Clamp(t, 0, 1)))
end

-- Helper to compute (u,v) transform like basetexturetransform rotate -90deg used previously
local function TransformUV(u, v, centerX, centerY, scaleX, scaleY, rotateDeg, transX, transY)
    centerX = centerX or 0.5
    centerY = centerY or 0.5
    scaleX  = scaleX  or 1
    scaleY  = scaleY  or 1
    rotateDeg = rotateDeg or 0
    transX = transX or 0
    transY = transY or 0

    local x = (u - centerX) * scaleX
    local y = (v - centerY) * scaleY

    local rad = math.rad(rotateDeg)
    local cosT = math.cos(rad)
    local sinT = math.sin(rad)
    local xr = x * cosT - y * sinT
    local yr = x * sinT + y * cosT

    local uf = xr + centerX + transX
    local vf = yr + centerY + transY

    return uf, vf
end

-- Utility: rotate vector v around axis k by theta (Rodrigues)
local function RotateVectorAroundAxis(v, k, theta)
    local cosT = math.cos(theta)
    local sinT = math.sin(theta)
    local kdotv = k.x * v.x + k.y * v.y + k.z * v.z
    local kxv = Vector(k.y * v.z - k.z * v.y,
                       k.z * v.x - k.x * v.z,
                       k.x * v.y - k.y * v.x)
    return Vector(
        v.x * cosT + kxv.x * sinT + k.x * kdotv * (1 - cosT),
        v.y * cosT + kxv.y * sinT + k.y * kdotv * (1 - cosT),
        v.z * cosT + kxv.z * sinT + k.z * kdotv * (1 - cosT)
    )
end 

function ENT:AddPoint_NE_RibbonM001(pos)
    if !pos then return end
    local prev = self.NE_RibbonM001.LastPos or pos
    local segLen = prev:Distance(pos)
    self.NE_RibbonM001.TotalLength = self.NE_RibbonM001.TotalLength + segLen

    table.insert(self.NE_RibbonM001.TrailPoints, 1, {
        pos1 = prev,
        pos2 = pos,
        timestamp = CurTime(),
        segLen = segLen,
        cumulative = self.NE_RibbonM001.TotalLength,
        rand = math.Rand(0.8, 1.2),
        twistStrength = math.Rand(-1, 1) * 0.6
    })

    self.NE_RibbonM001.LastPos = pos
end

function ENT:AddPoint_NE_RibbonM(pos)
    if !pos then return end
    local prev = self.NE_RibbonM.LastPos or pos
    local segLen = prev:Distance(pos)
    self.NE_RibbonM.TotalLength = self.NE_RibbonM.TotalLength + segLen

    table.insert(self.NE_RibbonM.TrailPoints, 1, {
        pos1 = prev,
        pos2 = pos,
        timestamp = CurTime(),
        segLen = segLen,
        cumulative = self.NE_RibbonM.TotalLength,
        rand = math.Rand(0.8, 1.2),
        twistStrength = math.Rand(-1, 1) * 0.6
    })

    self.NE_RibbonM.LastPos = pos
end

function ENT:Initialize() 
	scripted_ents.Get("proj_unreali_skaarjprojectile").Initialize(self) 
	self.NE_RibbonM.Origin = self:GetPos() 
	self.NE_RibbonM.Outer = self 

    -- Trail storage: each entry { pos1, pos2, timestamp, segLen, cumulative, rand, twistStrength }
    self.NE_RibbonM.TrailPoints = {}
    self.NE_RibbonM.TotalLength = 0
    self.NE_RibbonM.LastPos = self.NE_RibbonM.Origin
    self.NE_RibbonM.DieTime = 0 -- not used (ribbon is driven by SegmentLifetime)
	
	self.NE_RibbonM001.Origin = self:GetPos() 
	self.NE_RibbonM001.Outer = self 

    -- Trail storage: each entry { pos1, pos2, timestamp, segLen, cumulative, rand, twistStrength }
    self.NE_RibbonM001.TrailPoints = {}
    self.NE_RibbonM001.TotalLength = 0
    self.NE_RibbonM001.LastPos = self.NE_RibbonM001.Origin
    self.NE_RibbonM001.DieTime = 0 -- not used (ribbon is driven by SegmentLifetime)

    -- Add initial short zero-length segment to bootstrap 
    self:AddPoint_NE_RibbonM(self.NE_RibbonM.LastPos) 
	self:AddPoint_NE_RibbonM001(self.NE_RibbonM001.LastPos) 
	
	


	self.NE_SparkM003.Outer = self
	self.NE_SparkM003.LastPos = self:GetPos()

	self.NE_SparkM003.Origin = self.NE_SparkM003.LastPos
	self.NE_SparkM003.SpawnAccumulator = 0
	-- self.Emitter = ParticleEmitter(self.Origin)
	self.NE_SparkM003.DieTime = CurTime() + 5 -- safety: stop after 5s if entity disappears
	self.NE_SparkM003.QualityScale = GetQualityScale()

	-- Keep a per-effect random seed for variety
	self.NE_SparkM003.Seed = math.random() * 1000

	
	
	

	if CLIENT then 
		self.LastPos = self:GetPos()  	
		self.LastPos2 = self:GetPos()  
		local subMeshes = { } 
		self.RavenProjectile_MeshesToManage = { } 
		table.insert(subMeshes,{["Model"] = self:GetModel(), ["Material"] = "sprites/MI_D_RavenHuman_SwordProjectileSprite_05.vmt", ["RavenProjectile_TargetScale"] = Vector(2,2,10)}) 
		table.insert(subMeshes,{["Model"] = self:GetModel(), ["Material"] = "sprites/MI_D_RavenHuman_SwordProjectileSprite_06.vmt", ["RavenProjectile_TargetScale"] = Vector(2.2,2.4,12)}) 
		table.insert(subMeshes,{["Model"] = self:GetModel(), ["Material"] = "sprites/MI_D_RavenHuman_SwordProjectileSprite_02.vmt", ["RavenProjectile_TargetScale"] = Vector(2,2,1)}) 
		table.insert(subMeshes,{["Model"] = "models/stellarblade/SM_C_SwordPrjTrail_01_2.mdl", ["Material"] = "sprites/MA_D_Opener_SwordProjectileSprite_03.vmt", ["RavenProjectile_TargetScale"] = Vector(1,2,1)}) 
		
		for k,enttable in ipairs(subMeshes) do 
			local model = ClientsideModel(enttable.Model,RENDERGROUP_BOTH) 
			model:SetMaterial(enttable.Material) 
			model:SetRenderMode(1) 
			model:SetPos(self:GetPos()) 
			model:SetAngles(self:GetAngles()) 
			model:SetParent(self) 
			self:CallOnRemove(model,function() model:Remove() end) 
			model.RavenProjectile_TargetScale = enttable.RavenProjectile_TargetScale 
			table.insert(self.RavenProjectile_MeshesToManage,model) 
		end 
		
		table.insert(self.RavenProjectile_MeshesToManage,self) 
		
		for k,v in ipairs(self.RavenProjectile_MeshesToManage) do 
	
			local scale = Vector(0.01,0.01,1) 
			v.RavenProjectile_CurrentScale = scale 
			self.RavenProjectile_ScaleTime = self:GetCreationTime() + 0.2 
			local mat = Matrix() 
			mat:Scale(scale) 
			v:EnableMatrix("RenderMultiply", mat) 
		
		end 
	end 
	self:SetColor(Color(255,255,255,1)) 
end 

function ENT:NE_RibbonM001_AddInterpolatedPoints(currPos)
    local last = self.NE_RibbonM001.LastPos or currPos
    local dist = last:Distance(currPos)
    if dist <= self.NE_RibbonM001.MinStepDist then
        self:AddPoint_NE_RibbonM001(currPos)
        return
    end

    local steps = math.min(math.ceil(dist / self.NE_RibbonM001.MinStepDist), self.NE_RibbonM001.MaxInterpolationSteps)
    for i = 1, steps do
        local t = i / steps
        local interp = Lerp(t, last.x, currPos.x)
        local y = Lerp(t, last.y, currPos.y)
        local z = Lerp(t, last.z, currPos.z)
        self:AddPoint_NE_RibbonM001(Vector(interp, y, z))
    end
end

function ENT:ProjectileThink(flInterval) 
	-- print("projectile think",flInterval) 
	local curColor = self:GetColor() 
	local newAlpha = curColor.a * 2 
	self:SetColor(Color(255,255,255,math.min(newAlpha,255))) 
	return 0.01 
end 

if CLIENT then 
	function ENT:Think() 
		scripted_ents.Get("proj_unreali_skaarjprojectile").Think(self) 
		-- print(self:GetCreationTime(),self:GetAnimTimeInterval()) 
		for k,v in ipairs(self.RavenProjectile_MeshesToManage) do 
			local scaleInterval = math.Remap(math.Clamp(self.RavenProjectile_ScaleTime - CurTime(),0,0.2),0,0.2,1,0) 
			v.RavenProjectile_CurrentScale = LerpVector(scaleInterval,Vector(0.01,0.01,10), v.RavenProjectile_TargetScale) 
			
			local mat = Matrix() 
			mat:Scale(v.RavenProjectile_CurrentScale) 
			v:EnableMatrix("RenderMultiply", mat) 
		end 
		
		self:NE_SparkM001_1_Think() 
		self:NE_SparkM002_1_Think() 
		self:NE_RibbonM_Think() 
		self:NE_RibbonM001_Think() 
		self:NE_SparkM003_Think() 
		
	end 
end 

function ENT:NE_RibbonM_Think() 
	-- Update origin (projectile may have moved)
	local src = self:GetPos() + self:GetRight() * -30 

    -- Add a new point only when moved a bit (this emulates interpolated spawning)
    local last = self.NE_RibbonM.LastPos 
    if !src:IsEqualTol(last, 0.5) then
        self:AddPoint_NE_RibbonM(src)
        self.NE_RibbonM.LastPos = src
    end

    -- Prune old points based on SegmentLifetime
    local now = CurTime()
    for i = #self.NE_RibbonM.TrailPoints, 1, -1 do
        if (now - self.NE_RibbonM.TrailPoints[i].timestamp) > self.NE_RibbonM.SegmentLifetime then
            table.remove(self.NE_RibbonM.TrailPoints, i)
        end
    end
	-- print(self.NE_RibbonM_Think,self.NE_RibbonM.LastPos,self.NE_RibbonM.TrailPoints) 
    -- Keep alive while we have points
    return #self.NE_RibbonM.TrailPoints > 0
end 

function ENT:NE_RibbonM001_Think()
    local src = self:GetPos() + self:GetRight() * 30 

    -- Interpolated spawning: add points along the movement path
    local last = self.NE_RibbonM001.LastPos or src
    if !src:IsEqualTol(last, 0.25) then
        self:NE_RibbonM001_AddInterpolatedPoints(src)
    end

    -- Remove old segments
    local now = CurTime()
    for i = #self.NE_RibbonM001.TrailPoints, 1, -1 do
        if (now - self.NE_RibbonM001.TrailPoints[i].timestamp) > self.NE_RibbonM001.SegmentLifetime then
            table.remove(self.NE_RibbonM001.TrailPoints, i)
        end
    end

    -- keep alive while points remain or entity exists recently
    return #self.NE_RibbonM001.TrailPoints > 0
end

function ENT:NE_SparkM001_1_Think() 
    local currentPos = self:GetPos() 
    local lastPos = self.LastPos or currentPos 
    local dt = FrameTime() 
    
    -- --- INTERPOLATED SPAWNING LOGIC ---
    -- Calculate distance traveled this frame
    local diff = currentPos - lastPos
    local dist = diff:Length()
    
    -- Determine how many particles to spawn based on time/distance
    -- (Combining Time-based rate with Distance-based fill)
    local particlesToSpawn = self.SpawnRate * dt
    self.SpawnAccumulator = self.SpawnAccumulator + particlesToSpawn

    if self.SpawnAccumulator >= 1 then
        local count = math.floor(self.SpawnAccumulator)
        self.SpawnAccumulator = self.SpawnAccumulator - count
        
        for i = 1, count do
            -- Calculate interpolation factor (0.0 to 1.0)
            -- This spreads particles evenly along the line traveled this frame
            local lerpFactor = i / count
            local spawnPos = LerpVector(lerpFactor, lastPos, currentPos)
			spawnPos = spawnPos + VectorRand(-30,30) 
            
            self:EmitSpark(spawnPos)
        end
    end

    self.LastPos = currentPos
    return true
end 

function ENT:NE_SparkM002_1_Think() 
    local currentPos = self:GetPos()
    local lastPos = self.LastPos2 or currentPos
    local dt = FrameTime()
    
    -- --- INTERPOLATED SPAWNING ---
    -- Fills gaps between frames
    local diff = currentPos - lastPos
    local dist = diff:Length()
    local particlesToSpawn = self.SpawnRate * dt 
    
    -- Add extra particles based on speed to prevent gaps (rate over distance)
    if dist > 10 then
        particlesToSpawn = particlesToSpawn + (dist * 0.5)
    end

    self.SpawnAccumulator2 = self.SpawnAccumulator2 + particlesToSpawn

    if self.SpawnAccumulator2 >= 1 then
        local count = math.floor(self.SpawnAccumulator2)
        self.SpawnAccumulator2 = self.SpawnAccumulator2 - count
        
        for i = 1, count do
            local lerpFactor = i / count
            local spawnPos = LerpVector(lerpFactor, lastPos, currentPos)
            
            -- Spread the spawn origin slightly to simulate volume
            local volOffset = VectorRand() * 5
            self:EmitSecondarySpark(spawnPos + volOffset)
        end
    end

    self.LastPos2 = currentPos
    return true
end

function ENT:EmitSpark(pos) 
	local SPARK_MAT = {"sprites/MI_A_GPUSparks_01_Tr_000","sprites/MI_A_GPUSparks_01_Tr_001","sprites/MI_A_GPUSparks_01_Tr_002","sprites/MI_A_GPUSparks_01_Tr_003"} 
	SPARK_MAT = SPARK_MAT[math.random(1,4)] 
    local particle = self.SpriteEmitter_2d:Add(SPARK_MAT, pos)
    
    if particle then
        -- --- INITIAL PROPERTIES ---
        local lifeTime = math.Rand(0.3, 0.6) -- Short life
        particle:SetDieTime(lifeTime) 
        particle:SetLifeTime(0) 
        
        -- Velocity: Eject outward + turbulence
        local ejection = VectorRand() * 50 -- Random direction
        local forwardInertia = self:GetVelocity() * 0.2 -- Drag behind projectile
        particle:SetVelocity(ejection - forwardInertia)
        
        -- Size: Velocity Aligned stretch handled by Start/End length
        particle:SetStartSize(2) 
        particle:SetEndSize(0) -- Shrink to nothing
        particle:SetStartLength(15) -- Stretch factor
        particle:SetEndLength(0)
        
        -- Physics
        particle:SetGravity(Vector(0, 0, -200)) -- Mild gravity
        particle:SetAirResistance(50) -- High drag (stops quickly)
        
        -- --- PARTICLE THINK FUNCTION (Driving Curves) ---
        -- This runs every frame for *this specific particle*
        particle:SetNextThink(CurTime())
        particle:SetThinkFunction(function(p)
            local lifePerc = p:GetLifeTime() / p:GetDieTime()
            
            -- 1. COLOR CURVE LERP
            -- Simple linear interpolation between keyframes based on life %
            local col
            if lifePerc < 0.2 then
                col = LerpColor(lifePerc / 0.2, COLOR_LIFE[0.0], COLOR_LIFE[0.2])
            elseif lifePerc < 0.5 then
                col = LerpColor((lifePerc - 0.2) / 0.3, COLOR_LIFE[0.2], COLOR_LIFE[0.5])
            else
                col = LerpColor((lifePerc - 0.5) / 0.5, COLOR_LIFE[0.5], COLOR_LIFE[1.0])
            end
            
            p:SetColor(col.r, col.g, col.b)
            p:SetStartAlpha(col.a)
            
            -- 2. CURL NOISE SIMULATION
            -- Add random sine-wave turbulence to velocity
            local turbulence = Vector(
                math.sin(CurTime() * 10 + p:GetPos().x * 0.1),
                math.cos(CurTime() * 12 + p:GetPos().y * 0.1),
                math.sin(CurTime() * 8 + p:GetPos().z * 0.1)
            ) * 5
            
            p:SetVelocity(p:GetVelocity() + turbulence)
            
            p:SetNextThink(CurTime()) -- Run again next frame
        end)
    end
end 

function ENT:EmitSecondarySpark(pos)
    local SPARK_MAT = {"sprites/MI_A_GPUSparks_01_Tr_000","sprites/MI_A_GPUSparks_01_Tr_001","sprites/MI_A_GPUSparks_01_Tr_002","sprites/MI_A_GPUSparks_01_Tr_003"} 
	SPARK_MAT = SPARK_MAT[math.random(1,4)] 
    local particle = self.SpriteEmitter_2d:Add(SPARK_MAT, pos) 
	
    if particle then
        -- --- PROPERTIES (Based on NE_SparkM002 Analysis) ---
        
        -- Lifetime: Slightly longer/more varied than primary to linger in wake
        local lifeTime = math.Rand(0.5, 0.9) 
        particle:SetDieTime(lifeTime)
        particle:SetLifeTime(0)
        
        -- Velocity: "Wake" behavior
        -- Less forward inertia, more random diffusion
        local ejection = VectorRand() * 40
        local dragWake = self:GetVelocity() * 0.05 -- Very little inherited velocity
        particle:SetVelocity(ejection + dragWake)
        
        -- Physics: High Drag
        -- M002 is the "dust", so it should stop in mid-air quickly
        particle:SetAirResistance(150) 
        particle:SetGravity(Vector(0, 0, -50)) -- Floatier than primary
        
        -- Size & Alignment
        -- Velocity Aligned: Stretch based on speed
        -- Sort Order 10 (Background) -> Slightly smaller/thinner than M001
        particle:SetStartSize(1.5) 
        particle:SetEndSize(0)
        particle:SetStartLength(8) -- Less stretched than M001 (slower)
        particle:SetEndLength(0)
        
        -- --- PARTICLE LOGIC (Curves & Turbulence) ---
        particle:SetNextThink(CurTime())
        particle:SetThinkFunction(function(p)
            local lifePerc = p:GetLifeTime() / p:GetDieTime()
            
            -- 1. COLOR CURVE (Cooler/Darker)
            local col
            if lifePerc < 0.1 then
                col = LerpColor(lifePerc / 0.1, COLOR2_LIFE[0.0], COLOR2_LIFE[0.1])
            elseif lifePerc < 0.4 then
                col = LerpColor((lifePerc - 0.1) / 0.3, COLOR2_LIFE[0.1], COLOR2_LIFE[0.4])
            else
                col = LerpColor((lifePerc - 0.4) / 0.6, COLOR2_LIFE[0.4], COLOR2_LIFE[1.0])
            end
            
            p:SetColor(col.r, col.g, col.b)
            p:SetStartAlpha(col.a)
            
            -- 2. CURL NOISE (Turbulence)
            -- Different frequency/offset than M001 to prevent stacking
            -- Slower, more "drifting" noise
            local turbulence = Vector(
                math.sin(CurTime() * 5 + p:GetPos().z * 0.05),
                math.cos(CurTime() * 4 + p:GetPos().x * 0.05),
                math.sin(CurTime() * 6 + p:GetPos().y * 0.05)
            ) * 2 -- Lower magnitude
            
            p:SetVelocity(p:GetVelocity() + turbulence)
            
            p:SetNextThink(CurTime())
        end)
    end
end 

function ENT:DrawTranslucent(flags) 
	scripted_ents.Get("proj_unreali_skaarjprojectile").Draw(self,flags) 
	self:NE_RibbonM_Draw(flags) 
	self:NE_RibbonM001_Draw(flags) 
end 

function ENT:NE_RibbonM_Draw(flags)  
	-- if true then return end 
	-- print("drawing:",CurTime(),self.NE_RibbonM.TrailPoints) 
    local pts = self.NE_RibbonM.TrailPoints
    if !pts or #pts < 2 then return end -- Changed from < 1 to < 2

    local mat = self.NE_RibbonM.Mat
    render.SetMaterial(mat)
    local now = CurTime()
    local segLife = self.NE_RibbonM.SegmentLifetime
    local baseWidth = self.NE_RibbonM.BaseWidth or 10
    local tilingLength = self.NE_RibbonM.TilingLength or 150
    local hdrBoost = self.NE_RibbonM.HDRMultiplier or 1.0

    -- Use triangle strip; build from oldest to newest so winding is consistent
	local oldr,oldg,oldb = render.GetColorModulation() 
	local vertexCount = #pts * 2
	local triCount = math.max(vertexCount - 2, 0) -- Safely clamp to 0 minimum
    if triCount <= 0 then return end -- Bail out before drawing if we have no triangles
    
    mesh.Begin(MATERIAL_TRIANGLE_STRIP, triCount)

    local eyePos = EyePos()
    -- iterate oldest -> newest (so i = # to 1 yields newest -> oldest; we want oldest first)
    for i = #pts, 1, -1 do
        local seg = pts[i]
        local lifeFrac = math.Clamp((now - seg.timestamp) / segLife, 0, 1) -- 0 = new, 1 = dead
        local invLife = 1 - lifeFrac

        -- Compute per-seg properties via easing-based curves:
        local alphaMul = SampleAlphaCurve(invLife) -- invLife: 1 => brand new, 0 => old
        local brightnessMul = SampleBrightnessCurve(invLife)
        local widthMul = SampleWidthCurve(invLife) * (seg.rand or 1.0) * (self.NE_RibbonM.WidthMultiplier or 1.0)

        -- Color (r,g,b)
        local rcol, gcol, bcol = SampleColorCurve(invLife)
		-- alphaMul = alphaMul * 255 
        rcol = math.Clamp(rcol * hdrBoost * brightnessMul, 0, 255)
        gcol = math.Clamp(gcol * hdrBoost * brightnessMul, 0, 255)
        bcol = math.Clamp(bcol * hdrBoost * brightnessMul, 0, 255)
        local acol = math.Clamp(255 * alphaMul, 0, 255)

        -- half width in world units
        local halfWidth = (baseWidth * 0.5) * widthMul

        local p1 = seg.pos1
        local p2 = seg.pos2

        if !p1 or !p2 then
            -- skip malformed
        else
            -- tangent along segment
            local tangent = (p2 - p1)
            if tangent:LengthSqr() < 1e-6 then
                tangent = Vector(0, 0, 1)
            else
                tangent:Normalize()
            end

            -- view-facing right vector: cross(viewDir, tangent)
            local mid = (p1 + p2) * 0.5
            local viewDir = (eyePos - mid)
            if viewDir:LengthSqr() < 1e-6 then viewDir = Vector(0, 0, 1) end
            viewDir:Normalize()

            local right = viewDir:Cross(tangent)
            if right:LengthSqr() < 1e-6 then
                right = Vector(0, 0, 1):Cross(tangent)
            end
            right:Normalize()

            -- Add twist derived from per-seg random & small curvature between neighbors
            local twistAngle = seg.twistStrength or 0
            if i < #pts then
                local nextSeg = pts[i + 1]
                if nextSeg then
                    local nextT = (nextSeg.pos2 - nextSeg.pos1)
                    if nextT:LengthSqr() > 1e-6 then
                        nextT:Normalize()
                        local dot = math.Clamp(tangent:Dot(nextT), -1, 1)
                        local ang = math.acos(dot)
                        twistAngle = twistAngle + ang * 0.3 * (seg.rand or 1.0)
                    end
                end
            end

            if math.abs(twistAngle) > 1e-6 then
                right = RotateVectorAroundAxis(right, tangent, twistAngle)
                right:Normalize()
            end

            local off = right * halfWidth

            -- UV: u = cumulative distance / tilingLength
            local uCoord = (seg.cumulative or 0) / tilingLength
            -- we set v to 0/1 for the two verts; transform to match VMT rotate -90deg like in example
            local uA, vA = 0, uCoord
            local uB, vB = 1, uCoord
            local tuA, tvA = TransformUV(uA, vA, 0.5, 0.5, 1, 1, -90, 0, 0) 
            local tuB, tvB = TransformUV(uB, vB, 0.5, 0.5, 1, 1, -90, 0, 0) 
			
			render.SetColorModulation(rcol,gcol,bcol) 
            -- Vertex A (one side)
            mesh.Position(p1 - off)
            mesh.TexCoord(0, tuA, tvA)
            mesh.Color(0, gcol, bcol, acol)
            mesh.Specular(0, gcol, bcol, acol)
            mesh.AdvanceVertex()

            -- Vertex B (other side)
            mesh.Position(p2 + off)
            mesh.TexCoord(0, tuB, tvB)
            mesh.Color(0, gcol, bcol, acol)
            mesh.Specular(0, gcol, bcol, acol)
            mesh.AdvanceVertex() 
			
			-- self:SetColor(oldColor) 
        end
    end

    mesh.End() 
	render.SetColorModulation(oldr,oldg,oldb) 
end 

function ENT:NE_RibbonM001_Draw(flags)
    local pts = self.NE_RibbonM001.TrailPoints
    if !pts or #pts < 2 then return end
    local mat = self.NE_RibbonM001.Mat

    render.SetMaterial(mat)
    local now = CurTime()
    local segLife = self.NE_RibbonM001.SegmentLifetime
    local baseWidth = self.NE_RibbonM001.BaseWidth or 10
    local tilingLength = self.NE_RibbonM001.TilingLength or 300
    local hdrBoost = self.NE_RibbonM001.HDRMultiplier or 1.0

    -- Compute valid triangle count for strip
    local vertexCount = #pts * 2
    local triCount = math.max(vertexCount - 2, 0)
    if triCount <= 0 then return end

    mesh.Begin(MATERIAL_TRIANGLE_STRIP, triCount)

    local eyePos = EyePos()

    -- Iterate oldest -> newest so strip vertices are emitted in correct order
    for i = #pts, 1, -1 do
        local seg = pts[i]
        local lifeFrac = math.Clamp((now - seg.timestamp) / segLife, 0, 1)  -- 0 = new, 1 = old
        local invLife = 1 - lifeFrac                                -- good for "youngness"

        -- sample curves using invLife (1=brand new)
        local alphaMul = SampleAlphaCurve(invLife)
        local brightnessMul = SampleBrightnessCurve(invLife)
        local widthMul = SampleWidthCurve(invLife) * (seg.rand or 1.0) * (self.NE_RibbonM001.WidthMultiplier or 1.0)
        local idx2 = SampleParam2(invLife)

        local rcol, gcol, bcol = SampleColorCurve(invLife)
        rcol = math.Clamp(rcol * hdrBoost * brightnessMul * idx2, 0, 255)
        gcol = math.Clamp(gcol * hdrBoost * brightnessMul * idx2, 0, 255)
        bcol = math.Clamp(bcol * hdrBoost * brightnessMul * idx2, 0, 255)
        local acol = math.Clamp(255 * alphaMul, 0, 255)

        local halfWidth = (baseWidth * 0.5) * widthMul

        local p1 = seg.pos1
        local p2 = seg.pos2
        if !p1 or !p2 then
            -- skip malformed
        else
            -- tangent & fallback
            local tangent = (p2 - p1)
            if tangent:LengthSqr() < 1e-6 then
                tangent = Vector(0, 0, 1)
            else
                tangent:Normalize()
            end

            -- view-facing right vector
            local mid = (p1 + p2) * 0.5
            local viewDir = (eyePos - mid)
            if viewDir:LengthSqr() < 1e-6 then viewDir = Vector(0, 0, 1) end
            viewDir:Normalize()

            local right = viewDir:Cross(tangent)
            if right:LengthSqr() < 1e-6 then
                right = Vector(0, 0, 1):Cross(tangent)
            end
            right:Normalize()

            -- twist: small seed + curvature between neighbors
            local twistAngle = seg.twistStrength or 0
            if i < #pts then
                local nextSeg = pts[i + 1]
                if nextSeg then
                    local nextT = (nextSeg.pos2 - nextSeg.pos1)
                    if nextT:LengthSqr() > 1e-6 then
                        nextT:Normalize()
                        local dot = math.Clamp(tangent:Dot(nextT), -1, 1)
                        local ang = math.acos(dot)
                        twistAngle = twistAngle + ang * 0.3 * (seg.rand or 1.0)
                    end
                end
            end

            if math.abs(twistAngle) > 1e-6 then
                right = RotateVectorAroundAxis(right, tangent, twistAngle)
                right:Normalize()
            end

            local off = right * halfWidth

            -- UV coordinates: u = cumulative / tilingLength, v = 0/1
            local uCoord = (seg.cumulative or 0) / tilingLength
            local uA, vA = 0, uCoord
            local uB, vB = 1, uCoord
            local tuA, tvA = TransformUV(uA, vA, 0.5, 0.5, 1, 1, -90, 0, 0)
            local tuB, tvB = TransformUV(uB, vB, 0.5, 0.5, 1, 1, -90, 0, 0)

            -- Vertex A
            mesh.Position(p1 - off)
            mesh.TexCoord(0, tuA, tvA)
            mesh.Color(rcol, gcol, bcol, acol)
            mesh.AdvanceVertex()

            -- Vertex B
            mesh.Position(p2 + off)
            mesh.TexCoord(0, tuB, tvB)
            mesh.Color(rcol, gcol, bcol, acol)
            mesh.AdvanceVertex()
        end
    end

    mesh.End()
end 

function ENT:NE_SparkM003_AddInterpolatedSpawns(fromPos, toPos, count, spawnFunc)
    -- count = number of spawn subdivisions to perform (e.g., steps)
    count = math.min(count, NE_SparkM003.MAX_INTERP_STEPS or 8)
    for i = 1, count do
        local t = i / count
        local p = Lerp(t, fromPos.x, toPos.x)
        local y = Lerp(t, fromPos.y, toPos.y)
        local z = Lerp(t, fromPos.z, toPos.z)
        spawnFunc(Vector(p,y,z))
    end
end

function ENT:NE_SparkM003_SpawnOneAt(pos)
    -- if !NE_SparkM003.SpriteEmitter_2d then return end
    local qualityScale = self.NE_SparkM003.QualityScale

    local emitter = self.SpriteEmitter_2d
    -- Lathe spawn: choose random angle and radius per particle
    local angle = math.Rand(0, math.pi * 2)
    local radius = NE_SparkM003.LatheOffset(angle) * (1 + math.Rand(-NE_SparkM003.SPAWN_RADIUS_JITTER, NE_SparkM003.SPAWN_RADIUS_JITTER))

    -- Build orientation basis: use attached entity forward/up/right if available
	local forward = self:GetForward()
	local up = self:GetUp()
	local right = self:GetRight()

    local localOffset = (right * math.cos(angle) + up * math.sin(angle)) * radius
    local spawnPos = pos + localOffset

    -- Create particle using the material (our VMT path)
    local p = emitter:Add(NE_SparkM003.BASE_MATERIAL, spawnPos)

    -- Lifespan
    local life = NE_SparkM003.LIFETIME_MIN + math.Rand(0,1) * (NE_SparkM003.LIFETIME_MAX - NE_SparkM003.LIFETIME_MIN)
    p:SetDieTime(life)

    -- Sizes (scaleFactor ~0.85 -> 0.67)
    -- Start size based on ScaleFactor(0)
    local startScaleX, startScaleY = NE_SparkM003.ScaleFactor(0)
    local startSize = Lerp(math.random(),NE_SparkM003.START_SIZE_MIN, NE_SparkM003.START_SIZE_MAX) * startScaleX
    local endSize = math.max(startSize * NE_SparkM003.END_SIZE_FACTOR, 0.5)
    p:SetStartSize(startSize * qualityScale)
    p:SetEndSize(endSize * qualityScale)
	-- print(startSize,endSize) 

    -- Alpha: full bright at start, fade to 0 - we'll set start/end alpha now and rely on engine interpolation
    p:SetStartAlpha(255)
    p:SetEndAlpha(0)

    -- Colors: use color curve at t=0 modulated by brightness
    local r,g,b = NE_SparkM003.ColorCurve(0)
    -- apply brightness curve at spawn (early bright), and add small per-particle brightness jitter
    local brightness = NE_SparkM003.BrightnessCurve(0) * Lerp(math.random(),0.85, 1.25)
    -- occasional twinkle (rare strong spike at spawn)
    if math.random() < NE_SparkM003.TWINKLE_PROBABILITY then
        brightness = brightness * NE_SparkM003.TWINKLE_BRIGHT_MULT
    end
    -- map brightness into 0..255 safely (scale factor tuned for VMT)
    local colorScale = math.Clamp(brightness * 0.8, 0, 2.8)
    p:SetColor(math.Clamp(math.floor(r * colorScale), 0, 255),
               math.Clamp(math.floor(g * colorScale), 0, 255),
               math.Clamp(math.floor(b * colorScale), 0, 255))

    -- Velocity: inherit projectile velocity + radial outward + curl noise
    local inheritVel = self:GetVelocity() * NE_SparkM003.INHERIT_VELOCITY

    -- radial outward direction (from center out)
    local radialDir = (spawnPos - pos)
    if radialDir:LengthSqr() < 1e-6 then
        radialDir = (right * math.cos(angle) + up * math.sin(angle))
    else radialDir:Normalize() end

    local ejectSpeed = math.Rand(NE_SparkM003.OUTWARD_SPEED_MIN, NE_SparkM003.OUTWARD_SPEED_MAX)
    local vel = inheritVel + radialDir * ejectSpeed

    -- small curl-noise component
    local seed = math.random() * 100
    vel = vel + NE_SparkM003.CurlNoiseVel(seed, spawnPos) * 0.45

    p:SetVelocity(vel)
    p:SetAirResistance(NE_SparkM003.AIR_RESIST)
    p:SetGravity(NE_SparkM003.GRAVITY)

    -- Rotation and roll
    p:SetRoll(math.Rand(0, 360))
    p:SetRollDelta(math.Rand(-360, 360))

    -- Lighting & collision
    p:SetCollide(false) -- sparks in this effect usually do not collide
    p:SetBounce(0)
    p:SetLighting(false) -- keep emissive look unaffected by world lighting
	
	p.__seed          = math.Rand(0, 1000)
	p.__baseColor     = { r = r, g = g, b = b } -- r,g,b were set above

	-- per-particle think: update size, color, alpha, velocity (curl noise), schedule next think
	p:SetThinkFunction(function(selfP)
		local life     = selfP:GetLifeTime()      -- time since spawn
		local dieTime  = selfP:GetDieTime()       -- total lifetime

		local t = math.Clamp(life / dieTime, 0, 1)     -- 0 = new, 1 = dead

		-- size: compute vector2 factor but we only have scalar size so use X.
		local sx, _ = NE_SparkM003.ScaleFactor(t)              -- returns ~0.85..0.67
		local targetSize = Lerp(t, startSize * qualityScale, endSize * qualityScale)
		local curSize = targetSize * sx
		-- override both start and end so engine draws current size this frame
		selfP:SetStartSize(curSize)
		selfP:SetEndSize(curSize)

		-- alpha: sample alpha curve (0..1) then map to 0..255
		local alphaMul = NE_SparkM003.AlphaCurve(t)
		local alpha = math.floor(math.Clamp(alphaMul * 255, 0, 255))
		selfP:SetStartAlpha(alpha)
		selfP:SetEndAlpha(0) -- keep fading to 0

		-- brightness & color: compute base color and multiply by brightness curve
		local br = NE_SparkM003.BrightnessCurve(t)
		local rr, gg, bb = NE_SparkM003.ColorCurve(t) -- returns 0..255 ints
		-- Mix with base color for more continuity: average them weighted by br
		local finalR = math.Clamp(math.floor(rr * br), 0, 255)
		local finalG = math.Clamp(math.floor(gg * br), 0, 255)
		local finalB = math.Clamp(math.floor(bb * br), 0, 255)
		selfP:SetColor(finalR, finalG, finalB)

		-- velocity curl/noise addition (small, time-dependent)
		local curl = NE_SparkM003.CurlNoiseVel(selfP.__seed, selfP:GetPos()) * 0.35
		local vel = selfP:GetVelocity() + curl
		selfP:SetVelocity(vel)

		-- schedule next think shortly (use small timestep)
		selfP:SetNextThink(CurTime() + 0.025)
	end)

	-- make sure the first think runs soon
	p:SetNextThink(CurTime())

    -- Misc: set velocity-dependent size or custom properties if needed
    -- (We can't set per-particle custom shader params easily without custom materials)
end

function ENT:NE_SparkM003_Think()
    -- Get source position: prefer attached entity pos
    local src = self:GetPos() 
    local now = CurTime()

    -- If entity disappeared, keep finishing until DieTime
    -- if not IsValid(self.AttachedEntity) and now > self.DieTime then
        -- if self.Emitter then
            -- self.Emitter:Finish()
            -- self.Emitter = nil
        -- end
        -- return false
    -- end

    -- Update bounds so engine doesn't clip particles
    -- self:SetRenderBoundsWS(src + Vector(-600,-600,-600), src + Vector(600,600,600))

    -- Spawn logic with accumulator & interpolated spawning
    local dt = FrameTime()
    local spawnRateAdjusted = NE_SparkM003.SPAWN_RATE * self.NE_SparkM003.QualityScale
    self.NE_SparkM003.SpawnAccumulator = self.NE_SparkM003.SpawnAccumulator + spawnRateAdjusted * dt

    local spawnCount = math.floor(self.NE_SparkM003.SpawnAccumulator)
    self.NE_SparkM003.SpawnAccumulator = self.NE_SparkM003.SpawnAccumulator - spawnCount

    if spawnCount > 0 then
        local fromPos = self.NE_SparkM003.LastPos 
        local toPos = src
        local dist = fromPos:Distance(toPos)

        -- if moved a lot, subdivide and interpolate spawns along path
        if dist > NE_SparkM003.SPAWN_MIN_STEP then
            local steps = math.min(math.ceil(dist / NE_SparkM003.SPAWN_MIN_STEP), NE_SparkM003.MAX_INTERP_STEPS)
            -- spawnCount distributed across steps
            local perStep = math.max(1, math.floor(spawnCount / steps))
            for s = 1, steps do
                local t = s / steps
                local interp = Lerp(t, fromPos.x, toPos.x)
                local y = Lerp(t, fromPos.y, toPos.y)
                local z = Lerp(t, fromPos.z, toPos.z)
                local stepPos = Vector(interp, y, z)
                for i = 1, perStep do
                    self:NE_SparkM003_SpawnOneAt(stepPos)
                end
            end
        else
            -- spawn all at current position
            for i = 1, spawnCount do
                self:NE_SparkM003_SpawnOneAt(src)
            end
        end
    end

    self.NE_SparkM003.LastPos = src
    return true
end