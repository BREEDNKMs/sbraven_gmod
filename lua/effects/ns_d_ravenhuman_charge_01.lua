local MaterialFrames = {
    "sprites/t_b_glow_01",
    "sprites/t_b_glow_01",
    "sprites/t_b_glow_01",
    "sprites/t_b_glow_01"
}

-- Unclamped Lerp is required to allow bouncy easings (OutBack/InBack) to overshoot
local function UnclampedLerp(t, a, b)
    return a + (b - a) * t
end

-- UV Transform Helper
local function TransformUV(u, v, centerX, centerY, scaleX, scaleY, rotateDeg, transX, transY)
    centerX, centerY = centerX or 0.5, centerY or 0.5
    scaleX, scaleY = scaleX or 1, scaleY or 1
    rotateDeg, transX, transY = rotateDeg or 0, transX or 0, transY or 0

    local x = (u - centerX) * scaleX
    local y = (v - centerY) * scaleY

    local rad = math.rad(rotateDeg)
    local cosT, sinT = math.cos(rad), math.sin(rad)
    local xr = x * cosT - y * sinT
    local yr = x * sinT + y * cosT

    return xr + centerX + transX, yr + centerY + transY
end

EFFECT.Mat = Material("sprites/MI_C_WindRibbon_01") 
EFFECT.SegmentLifetime = 0.15 -- Mesh segments fade quickly
EFFECT.BaseWidth = 2.0
EFFECT.TilingLength = 300.0

function EFFECT:Init(data)
    local origin = data:GetOrigin()
    local duration = data:GetMagnitude()
	duration = 0.5 
	self.Duration = duration 
	local CreationTime = CurTime() 
	self.CreationTime = CreationTime 
	self.Deadline = self.CreationTime + duration 
	self.DieTime = self.Deadline + self.SegmentLifetime

    local emitter = ParticleEmitter(origin)
    local numParticles = 120 

    for i = 1, numParticles do
        local mat = MaterialFrames[math.random(1, #MaterialFrames)]
        local p = emitter:Add(mat, origin)

        if p then
            p:SetDieTime(duration)
            
            p:SetStartAlpha(255)
            p:SetEndAlpha(255)
            p:SetStartSize(math.Rand(1.5, 3))
            p:SetEndSize(math.Rand(0.5, 1))
            
            p:SetColor(120, 255, 255) 
            
            p:SetVelocityScale(true)
            p:SetStartLength(0.1) 
            p:SetEndLength(0.008)
            
            -- Unique particle parameters 
            local baseAng = math.Rand(0, math.pi * 2)
            local maxRad = math.Rand(60, 120)
            
            -- Total amount of rotation over the entire lifespan
            -- local rotAmt = math.rad(math.random(40, 54)) * (math.random(0, 1) == 1 and 1 or -1) 
            local rotAmt = math.rad(math.random(40, 54)) * -1 
            
            -- Random height limit for the 3D expansion (adjust these numbers for more/less vertical spread)
            local maxHeight = math.Rand(-17, 17) 
            
            p:SetThinkFunction(function(prt)
                local curTime = CurTime()
                local elapsed = curTime - (self.CreationTime or CreationTime)
                local f = elapsed / duration 
                local ft = FrameTime()

                if ft > 0 then
                    local R = 0
                    local Z = 0
                    
                    -- Continuous rotation over the entire lifetime (0.0 to 3.0)
                    -- InOutCubic creates a smooth acceleration and deceleration for the spin
                    local Ang = baseAng + UnclampedLerp(math.ease.InOutCubic(f), 0, rotAmt)

                    -- Phase 1: Expanding (0.0 - 0.3)
                    if f <= 0.3 then
                        local phaseF = f / 0.3
                        local eased = math.ease.OutBack(phaseF)
                        R = UnclampedLerp(eased, 0, maxRad)
                        Z = UnclampedLerp(eased, 0, maxHeight) -- Expands vertically alongside radius
                    
                    -- Phase 2: Holding fully expanded shape (0.3 - 0.6)
                    elseif f > 0.3 and f <= 0.6 then
                        R = maxRad
                        Z = maxHeight

                    -- Phase 3: Shrinking back to origin (0.6 - 1.0)
                    else
                        local phaseF = (f - 0.6) / 0.4
                        local eased = math.ease.InBack(phaseF)
                        R = UnclampedLerp(eased, maxRad, 0)
                        Z = UnclampedLerp(eased, maxHeight, 0) -- Collapses vertically back to 0
                    end

                    -- Calculate desired position (now including the Z offset for 3D volume)
                    local targetPos = origin + Vector( math.cos(Ang) * R, math.sin(Ang) * R, Z )
                    local currentPos = prt:GetPos()
                    local desiredVelocity = (targetPos - currentPos) / ft
                    
                    prt:SetVelocity(desiredVelocity)
                end

                prt:SetNextThink(curTime)
            end)

            p:SetNextThink(CurTime())
        end
    end

    emitter:Finish()
	
	-- ribbon 
	self.Heads = {} 
	-- Initialize 5 unique trail heads
    for i = 1, 5 do
        -- Random spawn offset up to 70 units
        local startPos = self:GetPos() + (VectorRand() * 70)
        
        table.insert(self.Heads, {
            pos = startPos,
            vel = VectorRand() * math.Rand(100, 200),
            points = {},
            totalLength = 0,
            reachedCenter = false
        })
        
        -- Add the very first point
        self:AddPoint(self.Heads[i], startPos)
    end

    self:SetRenderBounds(Vector(-1000, -1000, -1000), Vector(1000, 1000, 1000))
end

function EFFECT:AddPoint(head, pos)
    local segLen = 0
    if #head.points > 0 then
        segLen = head.points[1].pos2:Distance(pos)
    end
    
    local prev = (#head.points > 0) and head.points[1].pos2 or pos
    head.totalLength = head.totalLength + segLen

    table.insert(head.points, 1, {
        pos1 = prev,         
        pos2 = pos,          
        timestamp = CurTime(),
        segLen = segLen,
        cumulative = head.totalLength
    })
end

function EFFECT:Think()
    local now = CurTime()
    
    -- Return false ONLY when time has exceeded deadline AND the last segments have faded
    if now > self.DieTime then return false end

    local timeRemaining = self.Deadline - now
    local timeFrac = math.Clamp((now - self.CreationTime) / self.Duration, 0, 1)
    
    -- Warp strength scales exponentially from 0 to 1.
    -- It starts weak (allowing wandering) and becomes overwhelmingly strong at the end.
    local warpStrength = timeFrac ^ 3 
    
    for _, head in ipairs(self.Heads) do
        if not head.reachedCenter then
            local distToCenter = self:GetPos() - head.pos
            
            -- If time is fully up, or it's physically close enough, lock it to center
            if timeFrac >= 1 or distToCenter:LengthSqr() < 16 then
                head.pos = self:GetPos()
                head.reachedCenter = true
                self:AddPoint(head, head.pos)
            else
                -- 1. Wandering force: highly chaotic at first, dies out as warp engages
                local wander = VectorRand() * math.Rand(400, 800) * (1 - warpStrength)
                
                -- 2. Pull force: the exact velocity needed to arrive exactly at the deadline
                local idealVel = distToCenter / math.max(timeRemaining, 0.01)
                
                -- Apply wander to the current velocity
                head.vel = head.vel + (wander * FrameTime())
                
                -- Blend the chaotic velocity into the ideal homing velocity using warpStrength
                -- This creates the smooth, sweeping pull instead of a hard snap.
                head.vel = LerpVector(warpStrength, head.vel, idealVel)
                
                -- Move head
                head.pos = head.pos + (head.vel * FrameTime())
                
                -- Interpolated Spawning: only record if moved enough (DistToSqr for performance)
                if head.points[1] and head.pos:DistToSqr(head.points[1].pos2) > 4 then
                    self:AddPoint(head, head.pos)
                end
            end
        end

        -- Prune old points for this specific trail
        for i = #head.points, 1, -1 do
            if (now - head.points[i].timestamp) > self.SegmentLifetime then
                table.remove(head.points, i)
            end
        end
    end

    return true
end

function EFFECT:Render()
    local now = CurTime()
    local segLife = self.SegmentLifetime
    local baseWidth = self.BaseWidth
    local tilingLength = self.TilingLength
    
    -- Force per-vertex color to solid white (no alpha fading)
    local solidColor = Color(255, 255, 255, 255)

    render.SetMaterial(self.Mat)
    
    -- We will pool all triangles from all 5 trails into one mesh draw call
    local masterTris = {}

    for _, head in ipairs(self.Heads) do
        local pts = head.points
        if #pts >= 2 then
            local segInfos = {}
            
            for i = #pts, 1, -1 do
                local seg = pts[i]
                local lifeFrac = math.Clamp((now - seg.timestamp) / segLife, 0, 1)
                
                -- FADE BY SCALING: Taper width to 0 as it approaches end of its life
                local widthMul = 1.0 - lifeFrac
                local halfWidth = (baseWidth * widthMul) * 0.5

                local p1, p2 = seg.pos1, seg.pos2
                if p1 and p2 and p1 ~= p2 then
                    local tangent = (p2 - p1)
                    if tangent:LengthSqr() < 1e-6 then
                        tangent = Vector(0,0,1)
                    else
                        tangent:Normalize()
                    end

                    local viewDir = (EyePos() - ((p1 + p2) * 0.5)):GetNormalized()
                    local right = viewDir:Cross(tangent)
                    if right:LengthSqr() < 1e-6 then right = Vector(0,0,1):Cross(tangent) end
                    right = right:GetNormalized()

                    local off = right * halfWidth

                    local t = tangent:GetNormalized()
                    local b = right:GetNormalized()
                    local n = t:Cross(b):GetNormalized()
                    if n:LengthSqr() < 1e-6 then n = Vector(0,0,1) end

                    local uCoord = (seg.cumulative or 0) / tilingLength
                    local uA, vA = 0, uCoord
                    local uB, vB = 1, uCoord
                    
                    -- Transformed UVs with 90 degree rotation requested
                    local tuA, tvA = TransformUV(uA, vA, 0.5, 0.5, 1, 1, 90, 0, 0)
                    local tuB, tvB = TransformUV(uB, vB, 0.5, 0.5, 1, 1, 90, 0, 0)

                    table.insert(segInfos, {
                        left = { pos = p1 - off, u = tuA, v = tvA },
                        right = { pos = p2 + off, u = tuB, v = tvB },
                        color = solidColor,
                        normal = n, tangent = t, binormal = b
                    })
                end
            end

            -- Build triangles for this specific trail
            for i = 1, #segInfos - 1 do
                local a = segInfos[i]
                local b = segInfos[i + 1]

                -- Triangle 1
                table.insert(masterTris, { pos = a.left.pos,  u = a.left.u,  v = a.left.v,  color = a.color, normal = a.normal, tangent = a.tangent, binormal = a.binormal })
                table.insert(masterTris, { pos = a.right.pos, u = a.right.u, v = a.right.v, color = a.color, normal = a.normal, tangent = a.tangent, binormal = a.binormal })
                table.insert(masterTris, { pos = b.left.pos,  u = b.left.u,  v = b.left.v,  color = b.color, normal = b.normal, tangent = b.tangent, binormal = b.binormal })

                -- Triangle 2
                table.insert(masterTris, { pos = b.left.pos,  u = b.left.u,  v = b.left.v,  color = b.color, normal = b.normal, tangent = b.tangent, binormal = b.binormal })
                table.insert(masterTris, { pos = a.right.pos, u = a.right.u, v = a.right.v, color = a.color, normal = a.normal, tangent = a.tangent, binormal = a.binormal })
                table.insert(masterTris, { pos = b.right.pos, u = b.right.u, v = b.right.v, color = b.color, normal = b.normal, tangent = b.tangent, binormal = b.binormal })
            end
        end
    end

    -- Draw all trails in a single mesh batch for performance
    if #masterTris >= 3 then
        local meshObj = Mesh(self.Mat) 
        meshObj:BuildFromTriangles(masterTris) 
        meshObj:Draw() 
        meshObj:Destroy() 
    end
end