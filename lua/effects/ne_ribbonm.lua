--[[
    EFFECT:         NE_RibbonM (Niagara Emitter Recreation)
    DESCRIPTION:    Generates a continuous, flowing ribbon trail attached to an entity.
                    The behavior and parameters are derived directly from the Unreal Engine
                    JSON properties for 'NE_RibbonM' and 'NiagaraRibbonRendererProperties_2'.
--]]

-- === PARAMETERS DERIVED FROM JSON ===

-- From NiagaraRibbonRendererProperties_2 -> Material -> MI_D_RibbonDefault_01
EFFECT.Mat = Material("trails/T_A_StreakSwirl_01")

-- Derived from the average of the Lifetime module in NS_D_RavenHuman_WPBuffTrail_01 (Min: 0.3, Max: 0.5)
EFFECT.SegmentLifetime = 0.4

-- Derived from the RibbonWidth module (Value: 10.0)
EFFECT.BaseWidth = 10.0

-- From UV0Settings -> TilingLength
EFFECT.TilingLength = 250.0

-- A width curve to simulate dynamic width changes over the ribbon's life,
-- mimicking the 'RibbonWidthBinding' functionality.
EFFECT.WidthCurve = {
    {0.0, 0.2}, -- Starts thin
    {0.2, 1.0}, -- Quickly widens
    {0.8, 0.8}, -- Stays wide
    {1.0, 0.0}  -- Fades to nothing
}

-- Simple function to sample a point from a curve table.
local function SampleCurve(tbl, t)
    if not tbl or #tbl == 0 then return 1.0 end
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

function EFFECT:Init(data)
    self.Entity = data:GetEntity()
    self.AttachmentID = data:GetAttachment()
    self.DieTime = -1 -- Loop indefinitely by default

    if not IsValid(self.Entity) then return end

    self.TrailPoints = {}
    self.TotalLength = 0
    self.LastPos = self:GetTrailPos()

    if not self.LastPos then return end

    -- Add the very first point to start the trail
    self:AddPoint(self.LastPos)

    self:SetRenderBounds(Vector(-1000, -1000, -1000), Vector(1000, 1000, 1000))
end

function EFFECT:GetTrailPos()
    if !IsValid(self.Entity) then return vector_origin end
    local att = self.Entity:GetAttachment(self.AttachmentID)
    return att and att.Pos
end

function EFFECT:AddPoint(pos)
    local segLen = 0
    if self.LastPos then
        segLen = self.LastPos:Distance(pos)
    end
	local prev = self.LastPos or pos

    self.TotalLength = self.TotalLength + segLen

    table.insert(self.TrailPoints, 1, {
    pos1 = prev,         -- previous point
	pos2 = pos,          -- new point
    timestamp = CurTime(),
    segLen = segLen,
    cumulative = self.TotalLength,
    rand = math.Rand(0.8, 1.2),    -- per-seg random
    twistStrength = math.Rand(-1,1) * 0.6 -- tune
})
	self.LastPos = pos
end

function EFFECT:Think()
    if not IsValid(self.Entity) or not self.Entity:Alive() then return false end

    local currentPos = self:GetTrailPos()
    if not currentPos then return true end -- Continue trying if attachment is temporarily invalid

    -- To replicate 'bInterpolatedSpawning', we add a point only when it has moved.
    if not currentPos:IsEqualTol(self.LastPos, 1) then
        self:AddPoint(currentPos)
        self.LastPos = currentPos
    end
	self:SetPos(self.Entity:GetPos()) 

    -- Prune old points from the trail
    local t = CurTime()
    for i = #self.TrailPoints, 1, -1 do
        if (t - self.TrailPoints[i].timestamp) > self.SegmentLifetime then
            table.remove(self.TrailPoints, i)
        end
    end

    return true
end

local function RotateVectorAroundAxis(v, k, theta)
    -- Rodrigues' rotation formula:
    -- v_rot = v*cos(theta) + (k x v)*sin(theta) + k*(k·v)*(1-cos(theta))
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

function EFFECT:Render()
    local pts = self.TrailPoints
    if not pts or #pts < 2 then return end

    -- Cache some locals for speed
    local mat = self.Mat
    local now = CurTime()
    local segLife = self.SegmentLifetime
    local baseWidth = self.BaseWidth or 10
    local tilingLength = self.TilingLength or 250
    local hdrBoost = self.HDRMultiplier or 1.0

    -- Precompute cumulative length table (if you don't store it per-seg)
    -- Your AddSegment already records cumulative length as seg.cumulative - use that.
    -- We will compute U using seg.cumulative / tilingLength
    render.SetMaterial(mat)

    -- We'll build triangle strip: 2 verts per segment
    mesh.Begin(MATERIAL_TRIANGLE_STRIP, #pts * 2)

    -- For camera-facing perpendicular calculation
    local eyePos = EyePos()

    -- iterate oldest->newest (so strip winding is consistent)
    for i = #pts, 1, -1 do
		-- print("in iteration",i) 
        local seg = pts[i]
        local lifeFrac = math.Clamp((now - seg.timestamp) / segLife, 0, 1)
        local invLife = 1 - lifeFrac

        -- Alpha: ease-in/out using sine
        local alpha = math.sin(math.pi * invLife)
		-- print("alpha:",alpha) 
        -- Intensity / color: similar to your original
        local intensity = Lerp(invLife, 1.5, 0.2) -- brighter when younger
        local rcol = 0
        local gcol = math.Clamp(180 * intensity * hdrBoost, 0, 255)
        local bcol = math.Clamp(255 * intensity * hdrBoost, 0, 255)
        local acol = math.Clamp(255 * alpha, 0, 255)

        -- width from your width curve (multiplier)
        local widthMul = SampleCurve(self.WidthCurve, lifeFrac)
        local halfWidth = (baseWidth * widthMul * (self.WidthMultiplier or 1)) * 0.5

        -- positions (two endpoints of segment)
        local p1 = seg.pos1
        local p2 = seg.pos2

        -- safety: if degenerate, skip
        if not p1 or not p2 or p1 == p2 then
			-- print("skipping degenerate segment") 
			-- print("p1 == p1",p1 == p1) 
			-- print("p2 == p2",p2 == p2) 
			-- print("p1",p1) 
			-- print("p2",p2) 
        else
			-- print("computing tangent along the segment. i:",i)
            -- compute tangent along the segment
            local tangent = (p2 - p1)
            local tlen2 = tangent:LengthSqr()
            if tlen2 < 1e-6 then
                tangent = Vector(0,0,1)
            else
                tangent:Normalize()
            end

            -- compute a camera-facing right vector (perpendicular)
            -- prefer EyePos to get a stable view-facing normal
            local viewDir = (eyePos - ((p1 + p2) * 0.5)):GetNormalized()
            local right = viewDir:Cross(tangent) -- cross(view,tangent) gives perpendicular in plane
            if right:LengthSqr() < 1e-6 then
                -- fallback axis if camera aligns with tangent
                right = Vector(0,0,1):Cross(tangent)
            end
            right:Normalize()

            -- compute local twist angle (radians)
            -- Use a twist curve if present, otherwise derive small twist from seg.rand or velocity
            local twistAngle = 0
            if self.TwistCurve then
                -- prefer using seg.rand for variation, fallback 0
                local randSeed = seg.rand or 0
                local twistNormalized = SampleCurve(self.TwistCurve, lifeFrac) -- [-1..1] ideally
                -- scale twist; you can tune 0.5 -> 0.5 radians
                twistAngle = twistNormalized * (seg.twistStrength or 1.0)
            else
                -- fallback: derive twist from local tangent yaw change between neighbors
                if i < #pts then
                    local nextSeg = pts[i+1]
                    if nextSeg then
                        local nextT = (nextSeg.pos2 - nextSeg.pos1)
                        if nextT:LengthSqr() > 1e-6 then
                            nextT:Normalize()
                            -- angle between tangents
                            local dot = math.Clamp(tangent:Dot(nextT), -1, 1)
                            local ang = math.acos(dot)
                            -- small twist proportional to angle
                            twistAngle = ang * 0.5 * (seg.rand or 1.0)
                        end
                    end
                end
            end

            -- rotate right vector around tangent by twistAngle
            if math.abs(twistAngle) > 1e-6 then
                right = RotateVectorAroundAxis(right, tangent, twistAngle)
                right:Normalize()
            end

            -- final offset vectors for the two vertices
            local off = right * halfWidth

            -- UV: compute u using cumulative distance / tiling length
            local uCoord = (seg.cumulative or 0) / tilingLength
			
			-- print("colors:",rcol,gcol,bcol,acol) 
            -- vertex 1 (side A)
            mesh.Position(p1 - off)
            mesh.TexCoord(0, 0, uCoord)
            mesh.Color(rcol, gcol, bcol, acol)
            mesh.AdvanceVertex()

            -- vertex 2 (side B)
            mesh.Position(p2 + off)
            mesh.TexCoord(0, 1, uCoord)
            mesh.Color(rcol, gcol, bcol, acol)
            mesh.AdvanceVertex()
        end
    end

    mesh.End()
end
