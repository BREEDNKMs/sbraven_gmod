--[[
    EFFECT:         NE_RibbonM (Niagara Emitter Recreation)
    DESCRIPTION:    Generates a continuous, flowing ribbon trail attached to an entity.
                    The behavior and parameters are derived directly from the Unreal Engine
                    JSON properties for 'NE_RibbonM' and 'NiagaraRibbonRendererProperties_2'.
--]]

-- === PARAMETERS DERIVED FROM JSON ===

-- From NiagaraRibbonRendererProperties_2 -> Material -> MI_D_RibbonDefault_01 
EFFECT.Mat = Material("sprites/T_A_StreakSwirl_01") 

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

--==============================================================
-- REUSABLE SCRATCH OBJECTS & POOLS (Zero GC Allocations)
--==============================================================
local boneMat       = Matrix()
local scratchVec1   = Vector()
local scratchVec2   = Vector()
local scratchVec3   = Vector()
local scratchVec4   = Vector()
local scratchVec5   = Vector()
local scratchVec6   = Vector()

local vecUp         = Vector(0, 0, 1)
local vecBoundsMin  = Vector(-1000, -1000, -1000)
local vecBoundsMax  = Vector(1000, 1000, 1000)

-- Point pool recycled between expiration and creation
local pointPool = {}

-- Vertex segment pool to avoid table creation inside EFFECT:Render
local segInfos = {}
local function GetSegInfo(idx)
    local s = segInfos[idx]
    if not s then
        s = {
            leftPos  = Vector(),
            rightPos = Vector(),
            normal   = Vector(),
            tangent  = Vector(),
            binormal = Vector(),
            tuA = 0, tvA = 0,
            tuB = 0, tvB = 0,
            r = 255, g = 255, b = 255, a = 255,
        }
        segInfos[idx] = s
    end
    return s
end

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

    if !IsValid(self.Entity) then return end

    self.TrailPoints = {}
    self.TotalLength = 0

    local startPos = self:GetTrailPos()
    if not startPos then return end

    self.LastPos = Vector()
    self.LastPos:Set(startPos)

    -- Add the very first point to start the trail
    self:AddPoint(self.LastPos)

    self:SetRenderBounds(vecBoundsMin, vecBoundsMax)
end

function EFFECT:GetRenderEntity()
    if !IsValid(self.Entity) then return nil end

    -- If it's a weapon whose owner is the local player in first-person, prefer the viewmodel
    if self.Entity:IsWeapon() then
        local owner = self.Entity:GetOwner()
        if IsValid(owner) and owner:IsPlayer() and owner == LocalPlayer() and !owner:ShouldDrawLocalPlayer() then
            local vm = owner:GetViewModel()
            if IsValid(vm) then return vm end
        end
    end

    return self.Entity
end 

-- REWRITE START:
function EFFECT:GetTrailPos()
    local ent = self:GetRenderEntity() 
    if !IsValid(ent) then
        return vector_origin
    end

    -- Look up the bone directly each call without caching so that multi-pass rendering
    -- (mirrors, renderscreens, observer cams, and first/third-person switches)
    -- always queries the correct active entity's hierarchy for that pass.
    local boneID = ent:LookupBone("ValveBiped.Bip01_R_Hand")
    if boneID then
        -- Still write into the pre-allocated Matrix to avoid VMatrix heap churn
        if ent.CopyBoneMatrix then
            ent:CopyBoneMatrix(boneID, boneMat)
            return boneMat:GetTranslation()
        else
            local m = ent:GetBoneMatrix(boneID)
            if m then return m:GetTranslation() end
        end
    end

    if self.AttachmentID and self.AttachmentID > 0 then
        local att = ent:GetAttachment(self.AttachmentID)
        if att and att.Pos then return att.Pos end
    end

    return ent:EyePos() 
end
-- REWRITE END

-- TRAILING CODE:
function EFFECT:AddPoint(pos)
    local segLen = 0
    if self.LastPos then
        segLen = self.LastPos:Distance(pos)
    end
    local prev = self.LastPos or pos

    self.TotalLength = self.TotalLength + segLen

    -- Pop from the recycled pool or create once
    local pt = pointPool[#pointPool]
    if pt then
        pointPool[#pointPool] = nil
        pt.pos1:Set(prev)
        pt.pos2:Set(pos)
    else
        pt = {
            pos1 = Vector(prev),
            pos2 = Vector(pos),
        }
    end

    pt.timestamp     = CurTime()
    pt.segLen        = segLen
    pt.cumulative    = self.TotalLength
    pt.rand          = math.Rand(0.8, 1.2)
    pt.twistStrength = math.Rand(-1, 1) * 0.6

    table.insert(self.TrailPoints, 1, pt)
    self.LastPos:Set(pos)
end

function EFFECT:Think()
    if !IsValid(self.Entity) or !self.Entity:Alive() then return false end

    local currentPos = self:GetTrailPos()
    if !currentPos then return true end 
    if self.Entity:IsEffectActive(EF_NODRAW) then return true end 

    -- Interpolated spawning: add a point only when moved
    if !currentPos:IsEqualTol(self.LastPos, 1) then
        self:AddPoint(currentPos)
    end
    self:SetPos(self.Entity:GetPos()) 

    -- Prune old points back into the reusable pool (Zero GC drop)
    local t = CurTime()
    local pts = self.TrailPoints
    for i = #pts, 1, -1 do
        local pt = pts[i]
        if (t - pt.timestamp) > self.SegmentLifetime then
            pointPool[#pointPool + 1] = table.remove(pts, i)
        end
    end

    return true
end

-- Rodrigues' rotation formula written directly to an output vector
local function RotateVectorAroundAxis(out, v, k, theta)
    local cosT = math.cos(theta)
    local sinT = math.sin(theta)
    local oneMinusCos = 1 - cosT
    local kdotv = k.x * v.x + k.y * v.y + k.z * v.z

    local kxv_x = k.y * v.z - k.z * v.y
    local kxv_y = k.z * v.x - k.x * v.z
    local kxv_z = k.x * v.y - k.y * v.x

    out:SetUnpacked(
        v.x * cosT + kxv_x * sinT + k.x * kdotv * oneMinusCos,
        v.y * cosT + kxv_y * sinT + k.y * kdotv * oneMinusCos,
        v.z * cosT + kxv_z * sinT + k.z * kdotv * oneMinusCos
    )
end

-- Transform UVs with constant-fold optimization for -90 degree ribbon tiling
local function TransformUV(u, v, centerX, centerY, scaleX, scaleY, rotateDeg, transX, transY)
    -- Fast path for the standard ribbon call (-90 deg centered)
    if rotateDeg == -90 and centerX == 0.5 and centerY == 0.5 and scaleX == 1 and scaleY == 1 and transX == 0 and transY == 0 then
        return v, 1 - u
    end

    local x = (u - centerX) * scaleX
    local y = (v - centerY) * scaleY

    local rad = math.rad(rotateDeg)
    local cosT = math.cos(rad)
    local sinT = math.sin(rad)
    local xr = x * cosT - y * sinT
    local yr = x * sinT + y * cosT

    return xr + centerX + transX, yr + centerY + transY
end

function EFFECT:Render()
    local pts = self.TrailPoints
    if !pts or #pts < 2 then return end

    local mat = self.Mat
    local now = CurTime()
    local segLife = self.SegmentLifetime
    local baseWidth = self.BaseWidth or 10
    local tilingLength = self.TilingLength or 250
    local hdrBoost = self.HDRMultiplier or 10.0

    render.SetMaterial(mat)

    local segCount = 0

    for i = #pts, 1, -1 do
        local seg = pts[i]
        local lifeFrac = math.Clamp((now - seg.timestamp) / segLife, 0, 1)
        local invLife = 1 - lifeFrac

        local alpha = math.sin(math.pi * invLife)
        local intensity = Lerp(invLife, 1.5, 0.2)
        local rcol = 0
        local gcol = math.Clamp(180 * intensity * hdrBoost, 0, 255)
        local bcol = math.Clamp(255 * intensity * hdrBoost, 0, 255)
        local acol = math.Clamp(255 * alpha, 0, 255)

        local widthMul = SampleCurve(self.WidthCurve, lifeFrac)
        local halfWidth = (baseWidth * widthMul * (self.WidthMultiplier or 1)) * 0.5

        local p1 = seg.pos1
        local p2 = seg.pos2

        if p1 and p2 and p1 ~= p2 then
            -- tangent in scratchVec1
            scratchVec1:Set(p2)
            scratchVec1:Sub(p1)
            if scratchVec1:LengthSqr() < 1e-6 then
                scratchVec1:Set(vecUp)
            else
                scratchVec1:Normalize()
            end

            -- midPoint in scratchVec2 = (p1 + p2) * 0.5
            scratchVec2:Set(p1)
            scratchVec2:Add(p2)
            scratchVec2:Mul(0.5)

            -- viewDir in scratchVec3 = EyePos() - midPoint
            scratchVec3:Set(EyePos())
            scratchVec3:Sub(scratchVec2)
            scratchVec3:Normalize()

            -- right in scratchVec4 = viewDir:Cross(tangent)
            scratchVec4:Set(scratchVec3:Cross(scratchVec1))
            if scratchVec4:LengthSqr() < 1e-6 then 
                scratchVec4:Set(vecUp:Cross(scratchVec1)) 
            end
            scratchVec4:Normalize()

            local twistAngle = 0
            if self.TwistCurve then
                local twistNormalized = SampleCurve(self.TwistCurve, lifeFrac)
                twistAngle = twistNormalized * (seg.twistStrength or 1.0)
            else
                if i < #pts then
                    local nextSeg = pts[i + 1]
                    if nextSeg then
                        scratchVec2:Set(nextSeg.pos2)
                        scratchVec2:Sub(nextSeg.pos1)
                        if scratchVec2:LengthSqr() > 1e-6 then
                            scratchVec2:Normalize()
                            local dot = math.Clamp(scratchVec1:Dot(scratchVec2), -1, 1)
                            twistAngle = math.acos(dot) * 0.5 * (seg.rand or 1.0)
                        end
                    end
                end
            end

            if math.abs(twistAngle) > 1e-6 then
                RotateVectorAroundAxis(scratchVec5, scratchVec4, scratchVec1, twistAngle)
                scratchVec5:Normalize()
                scratchVec4:Set(scratchVec5)
            end

            -- off in scratchVec5 = right * halfWidth
            scratchVec5:Set(scratchVec4)
            scratchVec5:Mul(halfWidth)

            -- normal in scratchVec6 = tangent:Cross(right)
            scratchVec6:Set(scratchVec1:Cross(scratchVec4))
            if scratchVec6:LengthSqr() < 1e-6 then
                scratchVec6:Set(vecUp)
            else
                scratchVec6:Normalize()
            end

            local uCoord = (seg.cumulative or 0) / tilingLength
            local tuA, tvA = TransformUV(0, uCoord, 0.5, 0.5, 1, 1, -90, 0, 0)
            local tuB, tvB = TransformUV(1, uCoord, 0.5, 0.5, 1, 1, -90, 0, 0)

            segCount = segCount + 1
            local info = GetSegInfo(segCount)

            info.leftPos:Set(p1)
            info.leftPos:Sub(scratchVec5)

            info.rightPos:Set(p2)
            info.rightPos:Add(scratchVec5)

            info.normal:Set(scratchVec6)
            info.tangent:Set(scratchVec1)
            info.binormal:Set(scratchVec4)

            info.tuA = tuA
            info.tvA = tvA
            info.tuB = tuB
            info.tvB = tvB

            info.r = rcol
            info.g = gcol
            info.b = bcol
            info.a = acol
        end
    end

    if segCount < 2 then return end

    -- Direct dynamic mesh stream: zero table allocations and zero IMesh heap churn
    local numQuads = segCount - 1
    mesh.Begin(MATERIAL_TRIANGLES, numQuads * 2)

    for i = 1, numQuads do
        local a = segInfos[i]
        local b = segInfos[i + 1]

        -- Triangle 1: a.left, a.right, b.left
        mesh.Position(a.leftPos)
        mesh.TexCoord(0, a.tuA, a.tvA)
        mesh.Color(a.r, a.g, a.b, a.a)
        mesh.Normal(a.normal)
        mesh.TangentS(a.binormal)
        mesh.AdvanceVertex()

        mesh.Position(a.rightPos)
        mesh.TexCoord(0, a.tuB, a.tvB)
        mesh.Color(a.r, a.g, a.b, a.a)
        mesh.Normal(a.normal)
        mesh.TangentS(a.binormal)
        mesh.AdvanceVertex()

        mesh.Position(b.leftPos)
        mesh.TexCoord(0, b.tuA, b.tvA)
        mesh.Color(b.r, b.g, b.b, b.a)
        mesh.Normal(b.normal)
        mesh.TangentS(b.binormal)
        mesh.AdvanceVertex()

        -- Triangle 2: b.left, a.right, b.right
        mesh.Position(b.leftPos)
        mesh.TexCoord(0, b.tuA, b.tvA)
        mesh.Color(b.r, b.g, b.b, b.a)
        mesh.Normal(b.normal)
        mesh.TangentS(b.binormal)
        mesh.AdvanceVertex()

        mesh.Position(a.rightPos)
        mesh.TexCoord(0, a.tuB, a.tvB)
        mesh.Color(a.r, a.g, a.b, a.a)
        mesh.Normal(a.normal)
        mesh.TangentS(a.binormal)
        mesh.AdvanceVertex()

        mesh.Position(b.rightPos)
        mesh.TexCoord(0, b.tuB, b.tvB)
        mesh.Color(b.r, b.g, b.b, b.a)
        mesh.Normal(b.normal)
        mesh.TangentS(b.binormal)
        mesh.AdvanceVertex()
    end

    mesh.End()
end