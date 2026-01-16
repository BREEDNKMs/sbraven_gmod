-- NE_RibbonM.lua (updated)
-- Ribbon EFFECT derived from NS_D_RavenHuman_Trail_01 JSON properties
-- Material: sprites/mi_d_raven_ribbon_01.vmt (use "sprites/mi_d_raven_ribbon_01" in Material())
-- ------------------------------------------------------------------
-- Config / Defaults (from your derived JSON values)
-- ------------------------------------------------------------------
local NE_RibbonM = { } 
local NE_RibbonM001 = { } 
local NE_SpriteM = { } 
local NE_RibbonM003 = { } 
local NE_SpriteM001 = { } 
NE_RibbonM.DEFAULT_MATERIAL = "sprites/mi_d_raven_ribbon_01"  -- user asked to load sprites/mi_d_raven_ribbon_01.vmt
-- local DEFAULT_MATERIAL = "effects/laser1"  -- user asked to load sprites/mi_d_raven_ribbon_01.vmt
NE_RibbonM.DEFAULT_SEGMENT_LIFETIME = 0.4   -- from Lifetime average (0.3-0.5)
NE_RibbonM.DEFAULT_BASE_WIDTH = 10.0        -- from RibbonWidth module
NE_RibbonM.DEFAULT_TILING_LENGTH = 250.0    -- from UV0Settings -> TilingLength

-- Width curve (as provided)
NE_RibbonM.DEFAULT_WIDTH_CURVE = {
    {0.0, 0.2},
    {0.2, 1.0},
    {0.8, 0.8},
    {1.0, 0.0}
} 

NE_RibbonM001.Mat = Material("sprites/mi_d_ravenhuman_ribbon_02")

-- Segment lifetime derived from system lifetime ranges in JSON (approx).
NE_RibbonM001.SegmentLifetime = 0.4

-- Base width (will be modulated by WidthCurve & per-seg random)
NE_RibbonM001.BaseWidth = 10.0

-- From UV0Settings -> TilingLength in JSON for NE_RibbonM001
NE_RibbonM001.TilingLength = 250.0

-- HDR/emissive multiplier approximation (material dependent)
NE_RibbonM001.HDRMultiplier = 8.0

-- Width modulation curve (approximates Index curves / RibbonWidth behavior)
NE_RibbonM001.WidthCurve = {
    {0.00, 0.12}, -- start thin
    {0.15, 1.0},  -- quickly reach full width
    {0.80, 0.9},  -- slightly taper
    {1.00, 0.0}   -- collapse at end
}

-- Alpha curve (approximation of Scale Alpha.FloatCurve)
NE_RibbonM001.AlphaCurve = {
    {0.00, 0.0},  -- invisible start (or very low)
    {0.08, 1.0},  -- quick fade-in
    {0.85, 1.0},  -- hold
    {1.00, 0.0}   -- fade out
}

-- Brightness / emissive scale (approximation of Scale Brightness.FloatCurve)
NE_RibbonM001.BrightnessCurve = {
    {0.00, 0.5},
    {0.12, 1.6},
    {0.6, 1.2},
    {1.00, 0.4}
}

-- Color curve: we approximate the ColorCurve LUT as a subtle blue-white tint.
-- This returns a linear RGB multiplier (0..1). We keep it simple here.
NE_RibbonM001.ColorCurve = {
    {0.00, Color(230, 245, 255)}, -- slightly bluish white at spawn
    {0.2,  Color(240, 250, 255)},
    {0.7,  Color(220, 235, 250)},
    {1.00, Color(200, 220, 245)}
}
-- === PLACEHOLDER: Replace these tables with the exact LUT arrays extracted from JSON ===
-- ColorLUT: list of {r_float,g_float,b_float,a_float} where floats are 0..1
-- Example: { {1.0, 0.9, 1.0, 0.0}, {0.95,0.95,1.0,1.0}, ... }
NE_RibbonM003.ColorLUT = {
    -- Replace these example rows with the extracted ColorCurve LUT (RGBA floats 0..1)
    {1.0, 0.92, 1.0, 0.0},
    {0.98, 0.95, 1.0, 1.0},
    {0.94, 0.90, 1.0, 1.0}
}
NE_RibbonM003.ColorLUT_MinTime = 0.0
NE_RibbonM003.ColorLUT_MaxTime = 1.0

-- Float LUTs: single float samples (0..1 or arbitrary scale)
-- FloatLUT_Alpha -> used to produce alpha (0..1)
-- FloatLUT_Brightness -> used to scale brightness/emissive
-- FloatLUT_Width -> used to modulate width
NE_RibbonM003.FloatLUT_Alpha = { 0.0, 1.0, 1.0, 0.0 } -- replace with exact Scale Alpha LUT float array
NE_RibbonM003.FloatLUT_Alpha_MinTime = 0.0
NE_RibbonM003.FloatLUT_Alpha_MaxTime = 1.0

NE_RibbonM003.FloatLUT_Brightness = { 0.5, 1.6, 1.2, 0.4 } -- replace with exact Scale Brightness LUT float array
NE_RibbonM003.FloatLUT_Brightness_MinTime = 0.0
NE_RibbonM003.FloatLUT_Brightness_MaxTime = 1.0

NE_RibbonM003.FloatLUT_Width = { 0.12, 1.0, 0.9, 0.0 } -- replace with Index/Width LUT
NE_RibbonM003.FloatLUT_Width_MinTime = 0.0
NE_RibbonM003.FloatLUT_Width_MaxTime = 1.0
-- === END placeholders ===

-- Helper: sample a float LUT (linear interpolation)
NE_RibbonM003.SampleLUTFloat = function(lut, minT, maxT, t)
    if not lut or #lut == 0 then return 1.0 end
    local tt = math.Clamp(t, minT, maxT)
    local range = maxT - minT
    local norm = (range == 0) and 0 or ((tt - minT) / range)
    local n = #lut
    local idx = norm * (n - 1)
    local i0 = math.floor(idx) + 1
    local i1 = math.min(i0 + 1, n)
    local frac = idx - math.floor(idx)
    local v0 = lut[i0] or lut[1]
    local v1 = lut[i1] or lut[#lut]
    return Lerp(frac, v0, v1)
end

-- Helper: sample color LUT (LUT entries are {r,g,b,a} as floats 0..1)
NE_RibbonM003.SampleLUTColor = function(lut, minT, maxT, t)
    if not lut or #lut == 0 then return Color(255,255,255,255) end
    local tt = math.Clamp(t, minT, maxT)
    local range = maxT - minT
    local norm = (range == 0) and 0 or ((tt - minT) / range)
    local n = #lut
    local idx = norm * (n - 1)
    local i0 = math.floor(idx) + 1
    local i1 = math.min(i0 + 1, n)
    local frac = idx - math.floor(idx)
    local a = lut[i0] or lut[1]
    local b = lut[i1] or lut[#lut]
    local r = math.floor(Lerp(frac, a[1], b[1]) * 255)
    local g = math.floor(Lerp(frac, a[2], b[2]) * 255)
    local bl = math.floor(Lerp(frac, a[3], b[3]) * 255)
    local al = math.floor(Lerp(frac, a[4], b[4]) * 255)
    return Color(r, g, bl, al)
end

NE_RibbonM003.Mat = Material("sprites/mi_d_raven_ribbon_01") -- placeholder: MI_D_Raven_Ribbon_01
NE_RibbonM003.SegmentLifetime = 0.45 -- approximate segment lifetime; adjust if you get exact spawn times
NE_RibbonM003.BaseWidth = 10.0 -- base width; final width multiplied by FloatLUT_Width sample
NE_RibbonM003.TilingLength = 125.0 -- from JSON
NE_RibbonM003.HDRMultiplier = 6.0 -- brightness scale; tune to match material

-- ------------------------------------------------------------------
-- Helpers
-- ------------------------------------------------------------------
local function SampleCurve(tbl, t)
    if !tbl or #tbl == 0 then return 1.0 end
    if t <= tbl[1][1] then return tbl[1][2] end
    for i = 2, #tbl do
        local aT, aV = tbl[i - 1][1], tbl[i - 1][2]
        local bT, bV = tbl[i][1], tbl[i][2]
        if t <= bT then
            local range = bT - aT
            if range == 0 then return aV end
            local frac = (t - aT) / range
            return Lerp(frac, aV, bV)
        end
    end
    return tbl[#tbl][2]
end

-- Simple curve sampler (linear segments)
NE_RibbonM001.SampleCurve = function(tbl, t)
    if not tbl or #tbl == 0 then return 1.0 end
    if t <= tbl[1][1] then
        local v = tbl[1][2]
        if type(v) == "table" then return v end
        return v
    end
    for i = 2, #tbl do
        local aT, aV = tbl[i - 1][1], tbl[i - 1][2]
        local bT, bV = tbl[i][1], tbl[i][2]
        if t <= bT then
            local range = bT - aT
            if range == 0 then return aV end
            local frac = (t - aT) / range
            if type(aV) == "table" and type(bV) == "table" then
                -- color lerp
                return Color(
                    math.floor(Lerp(frac, aV.r, bV.r)),
                    math.floor(Lerp(frac, aV.g, bV.g)),
                    math.floor(Lerp(frac, aV.b, bV.b))
                )
            else
                return Lerp(frac, aV, bV)
            end
        end
    end
    return tbl[#tbl][2]
end

-- Rodrigues rotation to rotate vector v around axis k by theta radians
local function RotateVectorAroundAxis(v, k, theta)
    local cosT = math.cos(theta)
    local sinT = math.sin(theta)
    local kdotv = k.x * v.x + k.y * v.y + k.z * v.z
    local kxv = Vector(
        k.y * v.z - k.z * v.y,
        k.z * v.x - k.x * v.z,
        k.x * v.y - k.y * v.x
    )
    return Vector(
        v.x * cosT + kxv.x * sinT + k.x * kdotv * (1 - cosT),
        v.y * cosT + kxv.y * sinT + k.y * kdotv * (1 - cosT),
        v.z * cosT + kxv.z * sinT + k.z * kdotv * (1 - cosT)
    )
end

-- Transform UVs like "$basetexturetransform" string: [ center cx cy scale sx sy rotate deg translate tx ty ]
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

-- ------------------------------------------------------------------
-- EFFECT
-- ------------------------------------------------------------------
function EFFECT:Init(data)
    -- Input convenience
    local ent = data:GetEntity()
    local origin = data:GetOrigin() or vector_origin
    local ang = data:GetAngles() or Angle(0, 0, 0)
    local life = math.max(0.01, data:GetMagnitude() or NE_RibbonM.DEFAULT_SEGMENT_LIFETIME)
    local scale = math.max(0.01, data:GetScale() or 1.0)
	self:SetPos(ent:GetPos()) 
	
	self.Entity = data:GetEntity() 
	self:NE_RibbonM_Init(data) 
	self:NE_RibbonM001_Init(data) 
	self:NE_RibbonM003_Init(data) 

    -- reasonable bounds for rendering the trail
    self:SetRenderBounds(Vector(-2048, -2048, -2048), Vector(2048, 2048, 2048))
end

function EFFECT:NE_RibbonM_Init(data) 
	self.NE_RibbonM = { Outer = self } 
	self.NE_RibbonM.Entity = self 
    self.NE_RibbonM.Attachment = data:GetAttachment() or 0
	self.NE_RibbonM.CreationTime = CurTime() 

    -- Derived runtime parameters
    self.NE_RibbonM.SegmentLifetime = math.max(0.01, data:GetMagnitude() or NE_RibbonM.DEFAULT_SEGMENT_LIFETIME)                           -- life per segment
    self.NE_RibbonM.BaseWidth = (NE_RibbonM.DEFAULT_BASE_WIDTH or 10.0) * data:GetScale()  -- base width multiplied by spawn scale
	self.NE_RibbonM.BaseWidth = self.NE_RibbonM.BaseWidth * 0.5 
    self.NE_RibbonM.TilingLength = NE_RibbonM.DEFAULT_TILING_LENGTH or 250.0
    self.NE_RibbonM.WidthCurve = NE_RibbonM.DEFAULT_WIDTH_CURVE
    self.NE_RibbonM.WidthMultiplier = 1.0
    self.NE_RibbonM.HDRMultiplier = 1.0

    -- material: prefer the exact path; Material() usually expects path without .vmt
    self.NE_RibbonM.Mat = Material(NE_RibbonM.DEFAULT_MATERIAL)

    -- initial trail state
    self.NE_RibbonM.TrailPoints = {}
    self.NE_RibbonM.TotalLength = 0
    self.NE_RibbonM.LastPos = self:GetTrailPos()
    if !self.NE_RibbonM.LastPos then
        self.NE_RibbonM.LastPos = data:GetPos() 
    end

    -- add first anchor point (degenerate segment where pos1 == pos2)
    self:NE_RibbonM_AddPoint(self.NE_RibbonM.LastPos)

    -- spawning/stop logic: we keep the emitter alive after spawning stops until every segment expires
    self.NE_RibbonM.Spawning = true
    self.NE_RibbonM.SpawnStopTime = self.NE_RibbonM.CreationTime + self.NE_RibbonM.SegmentLifetime

    -- infinite by default; you can set DieTime later if needed
    self.DieTime = -1
end 

function EFFECT:NE_RibbonM001_Init(data)
	self.NE_RibbonM001 = { Outer = self } 
    self.NE_RibbonM001.Entity = self 
	self.NE_RibbonM001.BaseWidth = (NE_RibbonM001.BaseWidth or 10.0) * data:GetScale()  -- base width multiplied by spawn scale
	self.NE_RibbonM001.BaseWidth = self.NE_RibbonM001.BaseWidth * 0.5 
    self.AttachmentID = data:GetAttachment()
    self.DieTime = -1

    if !IsValid(self.Entity) then return end

    self.NE_RibbonM001.TrailPoints = {}
    self.NE_RibbonM001.TotalLength = 0
    self.NE_RibbonM001.LastPos = self:GetTrailPos()

    -- start with one point
    self:NE_RibbonM001_AddPoint(self.NE_RibbonM001.LastPos)
end

function EFFECT:NE_RibbonM003_Init(data)
	self.NE_RibbonM003 = { Outer = self } 
    self.NE_RibbonM003.Entity = self 
	self.NE_RibbonM003.BaseWidth = (NE_RibbonM003.BaseWidth or 10.0) * data:GetScale()  -- base width multiplied by spawn scale
	self.NE_RibbonM003.BaseWidth = self.NE_RibbonM003.BaseWidth * 0.5 
    self.AttachmentID = data:GetAttachment()
    self.DieTime = -1

    if !IsValid(self.Entity) then return end

    self.NE_RibbonM003.TrailPoints = {}
    self.NE_RibbonM003.TotalLength = 0
    self.NE_RibbonM003.LastPos = self:GetTrailPos()

    -- start with one point
    self:NE_RibbonM001_AddPoint(self.NE_RibbonM003.LastPos)
end

function EFFECT:GetRenderEntity()
    if !IsValid(self.Entity) then return nil end

    if self.Entity:IsWeapon() then
        local owner = self.Entity:GetOwner()
        if IsValid(owner) and owner:IsPlayer() and owner == LocalPlayer() and !owner:ShouldDrawLocalPlayer() then
            local vm = owner:GetViewModel()
            if IsValid(vm) then return vm end
        end
    end

    return self.Entity
end

function EFFECT:GetTrailPos()
    local ent = self:GetRenderEntity()
    if !IsValid(ent) then return nil end

    -- Try bone "ValveBiped.Bip01_R_Hand" like your example
    local boneIdx = ent:LookupBone("ValveBiped.Bip01_R_Hand")
    if boneIdx then
        local m = ent:GetBoneMatrix(boneIdx)
        if m then
            local pos, up = m:GetTranslation(), m:GetUp() 
            if pos then 
				return pos + up * -100
			end
        end
    end

    -- fallback to attachment, if present
    local att = ent:GetAttachment(self.NE_RibbonM.Attachment)
    if att and att.Pos then return att.Pos end

    return ent:EyePos()
end

function EFFECT:NE_RibbonM_AddPoint(pos)
    local segLen = 0
    if self.NE_RibbonM.LastPos then
        segLen = self.NE_RibbonM.LastPos:Distance(pos)
    end
    local prev = self.NE_RibbonM.LastPos or pos

    self.NE_RibbonM.TotalLength = (self.NE_RibbonM.TotalLength or 0) + segLen

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

function EFFECT:NE_RibbonM001_AddPoint(pos)
    local segLen = 0
    if self.LastPos then
        segLen = self.NE_RibbonM001.LastPos:Distance(pos)
    end
    local prev = self.NE_RibbonM001.LastPos or pos

    self.NE_RibbonM001.TotalLength = (self.NE_RibbonM001.TotalLength or 0) + segLen

    table.insert(self.NE_RibbonM001.TrailPoints, 1, {
        pos1 = prev,
        pos2 = pos,
        timestamp = CurTime(),
        segLen = segLen,
        cumulative = self.TotalLength,
        rand = math.Rand(0.85, 1.15),
        twistStrength = math.Rand(-1, 1) * 0.6
    })

    self.NE_RibbonM001.LastPos = pos
end 

function EFFECT:NE_RibbonM003_AddPoint(pos)
    local segLen = 0
    if self.NE_RibbonM003.LastPos then segLen = self.NE_RibbonM003.LastPos:Distance(pos) end
    local prev = self.NE_RibbonM003.LastPos or pos
    self.NE_RibbonM003.TotalLength = (self.NE_RibbonM003.TotalLength or 0) + segLen
    table.insert(self.NE_RibbonM003.TrailPoints, 1, {
        pos1 = prev,
        pos2 = pos,
        timestamp = CurTime(),
        segLen = segLen,
        cumulative = self.NE_RibbonM003.TotalLength,
        rand = math.Rand(0.9, 1.1),
        twistStrength = math.Rand(-1, 1) * 0.5
    })
    self.NE_RibbonM003.LastPos = pos
end

function EFFECT:Think() 
	local NE_RibbonM_Think = self:NE_RibbonM_Think() 
	local NE_RibbonM001_Think = self:NE_RibbonM001_Think() 
	local NE_RibbonM003_Think = self:NE_RibbonM003_Think() 
	if !NE_RibbonM_Think then return false end 
	return true 
end 

function EFFECT:NE_RibbonM_Think()
    -- validity checks
    if !IsValid(self.Entity) then return false end
	-- print("thinking",CurTime()) 
    if self.Entity:IsPlayer() and not self.Entity:Alive() then return false end
	self:SetPos(self.Entity:GetPos()) 

    -- fetch current pos (may be nil briefly)
    local currentPos = self:GetTrailPos()
    if !currentPos then return true end

    local now = CurTime()

    -- stop spawning new points once the spawn lifetime has elapsed, but keep existing segments alive
    if self.NE_RibbonM.Spawning and now >= (self.NE_RibbonM.SpawnStopTime or 0) then
        self.NE_RibbonM.Spawning = false
    end

    -- add only on meaningful movement (bInterpolatedSpawning-like)
    -- if !currentPos:IsEqualTol(self.NE_RibbonM.LastPos, 1.0) then
        if self.NE_RibbonM.Spawning then
            self:NE_RibbonM_AddPoint(currentPos)
            self.NE_RibbonM.LastPos = currentPos
        else
            -- update lastpos to avoid a single huge segment if the entity moves after spawning stopped
            self.NE_RibbonM.LastPos = currentPos
        end
    -- end

    -- prune based on segment lifetime
    for i = #self.NE_RibbonM.TrailPoints, 1, -1 do
        local seg = self.NE_RibbonM.TrailPoints[i]
        if (now - seg.timestamp) > self.NE_RibbonM.SegmentLifetime then
            table.remove(self.NE_RibbonM.TrailPoints, i)
        end
    end

    -- if no points left and spawning has finished, kill effect
    if #self.NE_RibbonM.TrailPoints == 0 and !self.NE_RibbonM.Spawning then
        return false
    end

    return true
end

function EFFECT:NE_RibbonM001_Think()
    if !IsValid(self.Entity) then return false end

    local currentPos = self:GetTrailPos()
    if !currentPos then return true end

    -- movement threshold to add new interpolated sample (like bInterpolatedSpawning)
    if !currentPos:IsEqualTol(self.NE_RibbonM001.LastPos, 1) then
        self:NE_RibbonM001_AddPoint(currentPos)
    end

    -- prune old segments
    local t = CurTime()
    for i = #self.NE_RibbonM001.TrailPoints, 1, -1 do
        if (t - self.NE_RibbonM001.TrailPoints[i].timestamp) > NE_RibbonM001.SegmentLifetime then
            table.remove(self.NE_RibbonM001.TrailPoints, i)
        end
    end

    -- keep the EFFECT alive if we still have segments or entity is valid
    return #self.NE_RibbonM001.TrailPoints > 0 or IsValid(self.Entity)
end

function EFFECT:NE_RibbonM003_Think()
    if !IsValid(self.Entity) then return false end
    local curPos = self:GetTrailPos()
    if !curPos then return true end
    if !curPos:IsEqualTol(self.NE_RibbonM003.LastPos, 1) then self:NE_RibbonM003_AddPoint(curPos) end

    -- prune by SegmentLifetime
    local t = CurTime()
    for i = #self.NE_RibbonM003.TrailPoints, 1, -1 do
        if (t - self.NE_RibbonM003.TrailPoints[i].timestamp) > NE_RibbonM003.SegmentLifetime then
            table.remove(self.NE_RibbonM003.TrailPoints, i)
        end
    end
    return #self.NE_RibbonM003.TrailPoints > 0 or IsValid(self.Entity)
end

function EFFECT:Render() 
	self:NE_RibbonM_Render() 
	self:NE_RibbonM001_Render() 
	self:NE_RibbonM003_Render() 
end 

function EFFECT:NE_RibbonM_Render() 
    local pts = self.NE_RibbonM.TrailPoints
    if !pts or #pts < 1 then return end
    if !self.NE_RibbonM.Mat then return end

    local now = CurTime()
    local segLife = self.NE_RibbonM.SegmentLifetime
    local baseWidth = self.NE_RibbonM.BaseWidth or NE_RibbonM.DEFAULT_BASE_WIDTH
    local tilingLength = self.NE_RibbonM.TilingLength or NE_RibbonM.DEFAULT_TILING_LENGTH
    local hdrBoost = self.NE_RibbonM.HDRMultiplier or 10.0
    
    render.SetMaterial(self.NE_RibbonM.Mat)
	-- print("rendering",CurTime(),#pts) 
	-- self.Mat:SetFloat("$emissiveblendstrength", 10)

    -- prepare mesh, expect 2 verts per segment
    local vertCount = math.max(1, #pts * 2)
    mesh.Begin(MATERIAL_TRIANGLE_STRIP, vertCount)

    local eyePos = EyePos()

    -- iterate oldest -> newest so strip is correctly ordered
    for i = #pts, 1, -1 do
        local seg = pts[i]
        if !seg or !seg.pos1 or !seg.pos2 then continue end

        local lifeFrac = math.Clamp((now - seg.timestamp) / segLife, 0, 1)
        local invLife = 1 - lifeFrac

        -- alpha easing - smoother fade in/out
        local alpha = math.sin(math.pi * invLife)
        alpha = math.Clamp(alpha, 0, 1)

        -- color/intensity approximation 
        local intensity = Lerp(lifeFrac, 1.5, 0.2) -- younger brighter
        local rcol = 0
        local gcol = math.Clamp(180 * intensity * hdrBoost, 0, 255)
        local bcol = math.Clamp(255 * intensity * hdrBoost, 0, 255)
        local acol = math.floor(math.Clamp(255 * alpha, 0, 255))

        -- width from width curve
        local widthMul = SampleCurve(self.NE_RibbonM.WidthCurve or NE_RibbonM.DEFAULT_WIDTH_CURVE, invLife)
        local halfWidth = (baseWidth * widthMul * (self.NE_RibbonM.WidthMultiplier or 1)) * 0.5

        local p1 = seg.pos1 
        local p2 = seg.pos2 

        -- tangent vector
        local tangent = (p2 - p1)
        local tlen2 = tangent:LengthSqr()
        if tlen2 < 1e-6 then tangent = Vector(0, 0, 1) else tangent:Normalize() end

        -- compute camera-facing right vector (perpendicular to tangent)
        local mid = (p1 + p2) * 0.5
        local viewDir = (eyePos - mid)
        if viewDir:LengthSqr() < 1e-6 then viewDir = Vector(0, 0, 1) end
        viewDir:Normalize()
        local right = viewDir:Cross(tangent)
        if right:LengthSqr() < 1e-6 then
            right = Vector(0, 0, 1):Cross(tangent)
        end
        right:Normalize()

        -- twist handling (uses per-seg random and twistStrength)
        local twistAngle = 0
        if seg.twistStrength and math.abs(seg.twistStrength) > 0 then
            -- simple decay by life: more twist when recently spawned
            local twistNorm = seg.twistStrength * (invLife)
            twistAngle = twistNorm
        else
            -- try derivative between neighbors to produce small twist
            if i < #pts then
                local nextSeg = pts[i + 1]
                if nextSeg and nextSeg.pos1 and nextSeg.pos2 then
                    local nextT = (nextSeg.pos2 - nextSeg.pos1)
                    if nextT:LengthSqr() > 1e-6 then
                        nextT:Normalize()
                        local dot = math.Clamp(tangent:Dot(nextT), -1, 1)
                        local ang = math.acos(dot)
                        twistAngle = ang * 0.5 * (seg.rand or 1.0) * invLife
                    end
                end
            end
        end

        if math.abs(twistAngle) > 1e-6 then
            right = RotateVectorAroundAxis(right, tangent, twistAngle)
            right:Normalize()
        end

        local off = right * halfWidth

        -- UV computation: u = cumulative / tilingLength
        local uCoord = (seg.cumulative or 0) / tilingLength

        -- Build 2 vertices per segment for triangle strip
        -- A common layout: (p1 - off) with u=0, (p2 + off) with u=1 for each segment.
        -- We'll transform the UVs using TransformUV for basetexturetransform mimicry.
        local uA, vA = 0, uCoord
        local uB, vB = 1, uCoord

        -- Example basetexture transform values; adjust if you bake different ones in VMT
        local tuA, tvA = TransformUV(uA, vA, 0.5, 0.5, 1, 1, -90, 0, 0)
        local tuB, tvB = TransformUV(uB, vB, 0.5, 0.5, 1, 1, -90, 0, 0)

        -- vertex 1 (side A)
        mesh.Position(p1 - off)
        mesh.TexCoord(0, tuA, tvA)
        mesh.Color(rcol, gcol, bcol, acol)
        mesh.AdvanceVertex()

        -- vertex 2 (side B)
        mesh.Position(p2 + off)
        mesh.TexCoord(0, tuB, tvB)
        mesh.Color(rcol, gcol, bcol, acol)
        mesh.AdvanceVertex()
    end

    mesh.End()
end

function EFFECT:NE_RibbonM001_Render()
    local pts = self.NE_RibbonM001.TrailPoints
    if !pts or #pts < 2 then return end

    local mat = NE_RibbonM001.Mat
    local now = CurTime()
    local segLife = NE_RibbonM001.SegmentLifetime
    local baseWidth = self.NE_RibbonM001.BaseWidth or 10
    local tilingLength = NE_RibbonM001.TilingLength or 250
    local hdrBoost = NE_RibbonM001.HDRMultiplier or 8.0

    render.SetMaterial(mat)

    local segInfos = {}
    for i = #pts, 1, -1 do
        local seg = pts[i]
        local lifeFrac = math.Clamp((now - seg.timestamp) / segLife, 0, 1)
        local invLife = 1 - lifeFrac

        -- sample our approx curves
        local widthMul = NE_RibbonM001.SampleCurve(self.NE_RibbonM001.WidthCurve, lifeFrac) or 1.0
        local halfWidth = (baseWidth * widthMul * (seg.rand or 1.0)) * 0.5

        local alphaMul = NE_RibbonM001.SampleCurve(NE_RibbonM001.AlphaCurve, lifeFrac) or 1.0
        local brightMul = NE_RibbonM001.SampleCurve(NE_RibbonM001.BrightnessCurve, lifeFrac) or 1.0
        local col = NE_RibbonM001.SampleCurve(NE_RibbonM001.ColorCurve, lifeFrac) or Color(255,255,255)

        -- combine alpha/brightness for final alpha & emissive tint
        local alpha = math.Clamp(alphaMul * 255, 0, 255)
        local intensity = brightMul * hdrBoost

        -- final color scaled by intensity; clamp to 0..255
        local rcol = math.Clamp(math.floor(col.r * intensity / 255 * 255), 0, 255)
        local gcol = math.Clamp(math.floor(col.g * intensity / 255 * 255), 0, 255)
        local bcol = math.Clamp(math.floor(col.b * intensity / 255 * 255), 0, 255)
		-- rcol = rcol * 255 
		-- gcol = gcol * 255 
		-- bcol = bcol * 255 

        local p1 = seg.pos1
        local p2 = seg.pos2

        if p1 and p2 and p1 != p2 then
            local tangent = (p2 - p1)
            if tangent:LengthSqr() < 1e-6 then tangent = Vector(0,0,1)
            else tangent:Normalize() end

            local viewDir = (EyePos() - ((p1 + p2) * 0.5)):GetNormalized()
            local right = viewDir:Cross(tangent)
            if right:LengthSqr() < 1e-6 then right = Vector(0,0,1):Cross(tangent) end
            right = right:GetNormalized()

            -- twist: small per-seg twist using stored value and life
            local twistAngle = 0
            if seg.twistStrength then
                twistAngle = seg.twistStrength * (0.6 * (1 - lifeFrac))
            end
            if math.abs(twistAngle) > 1e-6 then
                right = RotateVectorAroundAxis(right, tangent, twistAngle)
                right = right:GetNormalized()
            end

            local off = right * halfWidth

            -- basis (tangent, binormal, normal) for shader-like data
            local tvec = tangent:GetNormalized()
            local bvec = right:GetNormalized()
            local nvec = tvec:Cross(bvec)
            if nvec:LengthSqr() < 1e-6 then nvec = Vector(0,0,1) else nvec = nvec:GetNormalized() end

            local uCoord = (seg.cumulative or 0) / tilingLength
            local uA, vA = 0, uCoord
            local uB, vB = 1, uCoord
            local tuA, tvA = TransformUV(uA, vA, 0.5, 0.5, 1, 1, -90, 0, 0) 
            local tuB, tvB = TransformUV(uB, vB, 0.5, 0.5, 1, 1, -90, 0, 0) 

            -- store per-vertex entries; include color & alpha
            table.insert(segInfos, {
                left = { pos = p1 - off, u = tuA, v = tvA, color = Color(rcol, gcol, bcol, math.floor(alpha)) },
                right = { pos = p2 + off, u = tuB, v = tvB, color = Color(rcol, gcol, bcol, math.floor(alpha)) },
                normal = nvec,
                tangent = tvec,
                binormal = bvec
            })
        end
    end

    if #segInfos < 2 then return end

    -- Build triangle list
    local tris = {}
    for i = 1, #segInfos - 1 do
        local a = segInfos[i]
        local b = segInfos[i + 1]

        -- Triangle 1
        table.insert(tris, { pos = a.left.pos,  u = a.left.u,  v = a.left.v,  color = a.left.color,  normal = a.normal, tangent = a.tangent, binormal = a.binormal })
        table.insert(tris, { pos = a.right.pos, u = a.right.u, v = a.right.v, color = a.right.color, normal = a.normal, tangent = a.tangent, binormal = a.binormal })
        table.insert(tris, { pos = b.left.pos,  u = b.left.u,  v = b.left.v,  color = b.left.color,  normal = b.normal, tangent = b.tangent, binormal = b.binormal })

        -- Triangle 2
        table.insert(tris, { pos = b.left.pos,  u = b.left.u,  v = b.left.v,  color = b.left.color,  normal = b.normal, tangent = b.tangent, binormal = b.binormal })
        table.insert(tris, { pos = a.right.pos, u = a.right.u, v = a.right.v, color = a.right.color, normal = a.normal, tangent = a.tangent, binormal = a.binormal })
        table.insert(tris, { pos = b.right.pos, u = b.right.u, v = b.right.v, color = b.right.color, normal = b.normal, tangent = b.tangent, binormal = b.binormal })
    end

    -- Create mesh and draw
    local meshObj = Mesh(mat)
    meshObj:BuildFromTriangles(tris)
    meshObj:Draw()
    meshObj:Destroy()
end 

function EFFECT:NE_RibbonM003_Render()
    local pts = self.NE_RibbonM003.TrailPoints
    if !pts or #pts < 2 then return end

    local mat = Material(NE_RibbonM.DEFAULT_MATERIAL) 
    local now = CurTime()
    local segLife = NE_RibbonM003.SegmentLifetime
    local baseWidth = NE_RibbonM003.BaseWidth or 10
    local tilingLength = NE_RibbonM003.TilingLength or 125
    local hdrBoost = NE_RibbonM003.HDRMultiplier or 6.0

    render.SetMaterial(mat)

    local segInfos = {}
    for i = #pts, 1, -1 do
        local seg = pts[i]
        local lifeFrac = math.Clamp((now - seg.timestamp) / segLife, 0, 1)

        -- sample exact (or placeholder) LUTs
        local col = NE_RibbonM003.SampleLUTColor(NE_RibbonM003.ColorLUT, NE_RibbonM003.ColorLUT_MinTime, NE_RibbonM003.ColorLUT_MaxTime, lifeFrac)
        local alphaSample = NE_RibbonM003.SampleLUTFloat(NE_RibbonM003.FloatLUT_Alpha, NE_RibbonM003.FloatLUT_Alpha_MinTime, NE_RibbonM003.FloatLUT_Alpha_MaxTime, lifeFrac)
        local brightSample = NE_RibbonM003.SampleLUTFloat(NE_RibbonM003.FloatLUT_Brightness, NE_RibbonM003.FloatLUT_Brightness_MinTime, NE_RibbonM003.FloatLUT_Brightness_MaxTime, lifeFrac)
        local widthSample = NE_RibbonM003.SampleLUTFloat(NE_RibbonM003.FloatLUT_Width, NE_RibbonM003.FloatLUT_Width_MinTime, NE_RibbonM003.FloatLUT_Width_MaxTime, lifeFrac)

        local alpha = math.Clamp(math.floor(alphaSample * 255), 0, 255)
        local intensity = brightSample * hdrBoost

        local rcol = math.Clamp(math.floor(col.r * intensity / 255 * 255), 0, 255)
        local gcol = math.Clamp(math.floor(col.g * intensity / 255 * 255), 0, 255)
        local bcol = math.Clamp(math.floor(col.b * intensity / 255 * 255), 0, 255)
        local acol = math.Clamp(alpha, 0, 255)

        local halfWidth = (baseWidth * (widthSample or 1.0) * (seg.rand or 1.0)) * 0.5

        local p1 = seg.pos1 
		local p2 = seg.pos2
        if p1 and p2 and p1 != p2 then
            local tangent = (p2 - p1)
            if tangent:LengthSqr() < 1e-6 then tangent = Vector(0,0,1) else tangent:Normalize() end
            local viewDir = (EyePos() - ((p1 + p2) * 0.5)):GetNormalized()
            local right = viewDir:Cross(tangent)
            if right:LengthSqr() < 1e-6 then right = Vector(0,0,1):Cross(tangent) end
            right = right:GetNormalized()

            local twistAngle = seg.twistStrength * (0.6 * (1 - lifeFrac))
            if math.abs(twistAngle) > 1e-6 then right = RotateVectorAroundAxis(right, tangent, twistAngle); right = right:GetNormalized() end

            local off = right * halfWidth
            local tvec = tangent:GetNormalized()
            local bvec = right:GetNormalized()
            local nvec = tvec:Cross(bvec)
            if nvec:LengthSqr() < 1e-6 then nvec = Vector(0,0,1) else nvec = nvec:GetNormalized() end

            local uCoord = (seg.cumulative or 0) / tilingLength
            local uA, vA = 0, uCoord
            local uB, vB = 1, uCoord
            local tuA, tvA = TransformUV(uA, vA, 0.5, 0.5, 1, 1, -90, 0, 0)
            local tuB, tvB = TransformUV(uB, vB, 0.5, 0.5, 1, 1, -90, 0, 0)

            table.insert(segInfos, {
                left = { pos = p1 - off, u = tuA, v = tvA, color = Color(rcol, gcol, bcol, acol) },
                right = { pos = p2 + off, u = tuB, v = tvB, color = Color(rcol, gcol, bcol, acol) },
                normal = nvec,
                tangent = tvec,
                binormal = bvec
            })
        end
    end

    if #segInfos < 2 then return end

    local tris = {}
    for i = 1, #segInfos - 1 do
        local a = segInfos[i]
        local b = segInfos[i + 1]

        table.insert(tris, { pos = a.left.pos,  u = a.left.u,  v = a.left.v,  color = a.left.color,  normal = a.normal, tangent = a.tangent, binormal = a.binormal })
        table.insert(tris, { pos = a.right.pos, u = a.right.u, v = a.right.v, color = a.right.color, normal = a.normal, tangent = a.tangent, binormal = a.binormal })
        table.insert(tris, { pos = b.left.pos,  u = b.left.u,  v = b.left.v,  color = b.left.color,  normal = b.normal, tangent = b.tangent, binormal = b.binormal })

        table.insert(tris, { pos = b.left.pos,  u = b.left.u,  v = b.left.v,  color = b.left.color,  normal = b.normal, tangent = b.tangent, binormal = b.binormal })
        table.insert(tris, { pos = a.right.pos, u = a.right.u, v = a.right.v, color = a.right.color, normal = a.normal, tangent = a.tangent, binormal = a.binormal })
        table.insert(tris, { pos = b.right.pos, u = b.right.u, v = b.right.v, color = b.right.color, normal = b.normal, tangent = b.tangent, binormal = b.binormal })
    end

    local meshObj = Mesh(mat)
    meshObj:BuildFromTriangles(tris)
    meshObj:Draw()
    meshObj:Destroy()
end