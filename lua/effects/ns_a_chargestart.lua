-- ns_a_chargestart uses targetequipment 
local NE_FlareM = { } 
NE_FlareM.Material = Material("sprites/mi_b_lenscircle_01_15_afterdof") 

EFFECT.MAT = "sprites/physg_glow1.vmt" 

EFFECT.Ribbon_Mat = Material("sprites/T_A_StreakSwirl_01")
EFFECT.SegmentLifetime = 0.4
EFFECT.BaseWidth = 10.0
EFFECT.TilingLength = 250.0
EFFECT.WidthCurve = {
    {0.0, 0.2},
    {0.2, 1.0},
    {0.8, 0.8},
    {1.0, 0.0}
}

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

-- Create a ribbon driver object
local function CreateRibbon(origin, lifetimeMax)
    local spawnOffset = VectorRand(-125, 125)
    local spawnPos = origin + spawnOffset
    local endPos = origin

    local dist = spawnPos:Distance(endPos)
    local bend = (spawnPos + endPos) * 0.5 + VectorRand() * (dist * 0.25 + 10)

	local ease 
	for k,v in RandomPairs(math.ease) do ease = v break end 

    local r = {
        Active = false,
        StartDelay = math.Rand(0, lifetimeMax * 0.5),
        Birth = nil,
        Life = math.Rand(0.5, math.max(0.5, lifetimeMax)),
        SpawnPos = spawnPos,
        EndPos = endPos,
        BendPoint = bend,
        EaseFunction = ease,
        TrailPoints = {},
        LastPos = spawnPos
    }

    -- add initial point
    table.insert(r.TrailPoints, 1, {
        pos1 = r.SpawnPos,
        pos2 = r.SpawnPos,
        timestamp = CurTime(),
        segLen = 0,
        cumulative = 0,
        rand = math.Rand(0.8, 1.2),
        twistStrength = math.Rand(-1,1) * 0.6
    })

    return r
end

-- Add point into a ribbon's TrailPoints (mirrors provided AddPoint)
local function RibbonAddPoint(self, ribbon, pos)
    local segLen = 0
    if ribbon.LastPos then
        segLen = ribbon.LastPos:Distance(pos)
    end
    local prev = ribbon.LastPos or pos
    ribbon.TotalLength = (ribbon.TotalLength or 0) + segLen

    table.insert(ribbon.TrailPoints, 1, {
        pos1 = prev,
        pos2 = pos,
        timestamp = CurTime(),
        segLen = segLen,
        cumulative = ribbon.TotalLength,
        rand = math.Rand(0.8, 1.2),
        twistStrength = math.Rand(-1,1) * 0.6
    })

    ribbon.LastPos = pos
end


function EFFECT:Init(data) 
    self.Origin = data:GetOrigin() or vector_origin 
	self.LocalPos = data:GetStart() 
	self.Entity = data:GetEntity() 
	self:SetOwner(self.Entity) 
	-- self:SetPos(data:GetOrigin()) 
	self:SetAngles(data:GetAngles()) 
	self.Scale = data:GetScale() * 1 
	-- print("scale is",self.Scale) 
	self.LifeTime = data:GetMagnitude() * 1 
	-- print("LifeTime is",self.LifeTime) 
    self.CreationTime = CurTime() 
    self.Emitter = ParticleEmitter(self.Origin, false) 
	self:AddEffects(EF_FOLLOWBONE) 
	local handBone = self.Entity:LookupBone("ValveBiped.Bip01_R_Hand") 
	print("handBone is:",handBone) 
	-- local parentPos = self.Entity:GetBoneMatrix(handBone) 
	self:SetParent(self.Entity,handBone) 
	self:SetLocalPos(vector_origin) 
	
	self:NE_SpriteM_Init(data) 
	
	-- We'll spawn 4 ribbons
    self.Ribbons = {}
    for i = 1, 10 do
        self.Ribbons[i] = CreateRibbon(self.Origin, self.LifeTime)
        self.Ribbons[i].TotalLength = 0
    end

    -- render bounds based on possible spawn offsets
    self:SetRenderBoundsWS(self.Origin + Vector(-600, -600, -600), self.Origin + Vector(600, 600, 600))
end

-- Safe unclamped lerp for vectors (some math.ease variants expect unclamped values)
local function VecLerpUnclamped(t, a, b)
    return a + (b - a) * t
end

-- Quadratic bezier evaluation between a (start), b (bend), c (end) for parameter t
local function QuadraticBezier(a, b, c, t)
    local omt = 1 - t
    return a * (omt * omt) + b * (2 * omt * t) + c * (t * t)
end

function EFFECT:NE_SpriteM_Init(data) 
	local origin = self:GetPos() 
	
	local SpawnParticleCumuls = function(pos) 
		
		for i = 1, 50 do
			-- Random spawn offset (VectorRand-like but within -500..500 on each axis)
			local spawnOffset = Vector(
				math.Rand(-40, 40),
				math.Rand(-40, 40),
				math.Rand(-40, 40)
			)
			local spawnPos = pos + spawnOffset
			local endPos = origin -- as requested, end position is data:GetOrigin()

			local p = self.Emitter:Add(self.MAT, spawnPos)

			-- life between 1 and 2 seconds
			local life = math.Rand(1, 2)
			p:SetDieTime(life) -- (SetDieTime expects seconds lifetime)
			p.SpawnTime = CurTime()
			p.TotalLife = life

			-- cache start/end on particle as requested
			p.SpawnPosition = spawnPos
			p.EndPosition = endPos

			-- pick a random easing method and cache it
			for k,v in RandomPairs(math.ease) do p.EaseFunction = v break end 
			-- local ease = easeMethods[math.random(1, #easeMethods)] or math.ease.InOutQuad
			-- p.EaseFunction = ease

			-- bend point: midpoint with a randomized perpendicular-ish offset
			local mid = (spawnPos + endPos) * 0.5
			-- offset magnitude proportional to distance (so long shots bend more)
			local dist = spawnPos:Distance(endPos)
			local offset = VectorRand() * (dist * 0.25 + 20)
			p.BendPoint = mid + offset

			-- visual properties
			p:SetStartAlpha(255)
			p:SetEndAlpha(255)
			p:SetStartSize(0.2)
			p:SetEndSize(0.5)
			p:SetRoll(math.Rand(0, 360))
			p:SetRollDelta(math.Rand(-90, 90))
			p:SetColor(255, 255, 255)
			p:SetAirResistance(30)
			p:SetVelocity(Vector(0, 0, 0))
			p:SetCollide(false)

			-- Keep last position for velocity fallback
			p.LastPos = spawnPos

			-- Think function: manually place the particle along a quadratic-bezier path
			p:SetThinkFunction(function(part)
				-- Protect if the particle already died or missing fields
				local now = CurTime()
				local age = now - (part.SpawnTime or 0)
				local lifeLen = part.TotalLife or 1

				if age >= lifeLen then
					-- let the particle die naturally (SetDieTime was already set)
					return
				end

				local t = age / lifeLen
				-- We intentionally do NOT clamp t before passing to the ease function in case
				-- the easing method expects unclamped input. However, we will guard against nil.
				local easeFunc = part.EaseFunction or math.ease.InOutQuad
				local te = 0
				-- Protect ease call (some custom ease libs might error if given nil)
				local ok, res = pcall(easeFunc, t)
				if ok and type(res) == "number" then
					te = res
				else
					te = math.Clamp(t, 0, 1)
				end

				-- Evaluate quadratic bezier using eased parameter
				local newPos = QuadraticBezier(part.SpawnPosition, part.BendPoint, part.EndPosition, te)

				-- Manually set particle position
				part:SetPos(newPos)

				-- Update velocity roughly (helps lighting/particles that sample velocity)
				local dt = FrameTime()
				if dt > 0 then
					local vel = (newPos - part.LastPos) / dt
					part:SetVelocity(vel)
				end
				part.LastPos = newPos

				-- schedule next think (small interval)
				part:SetNextThink(CurTime() + FrameTime())
			end)
			p:SetNextThink(CurTime() + FrameTime())
		end
		
	end 
	
	for i = 1, 4 do 
		SpawnParticleCumuls(self:GetPos() + VectorRand(-100,100)) 
	end 
	local dlight = DynamicLight(self.Entity:EntIndex()) 
	dlight.brightness = 10 
	dlight.decay = 1000 
	dlight.dietime = CurTime() + FrameTime() 
	dlight.pos = self:GetPos() 
	dlight.size = 20 
	dlight.r = 0 
	dlight.g = 255 
	dlight.b = 255 
	dlight.style = 0 
	dlight.dir = -self:GetOwner():GetOwner():GetUp() 
end 

function EFFECT:Think() 
	local now = CurTime()
    local elapsed = now - self.CreationTime

    -- End effect when global lifetime passed AND all ribbons finished
    local allDone = true

    for _, r in ipairs(self.Ribbons) do
        if not r.Active then
            if elapsed >= r.StartDelay then
                r.Active = true
                r.Birth = now
            else
                allDone = false
                continue
            end
        end

        -- Check if this ribbon still alive
        local rAge = now - (r.Birth or 0)
        if rAge >= r.Life then
            -- allow segments to fade out naturally; mark done
            -- prune old points until empty
            for i = #r.TrailPoints, 1, -1 do
                if (now - r.TrailPoints[i].timestamp) > self.SegmentLifetime then
                    table.remove(r.TrailPoints, i)
                end
            end
            if #r.TrailPoints == 0 then
                r.Done = true
            else
                allDone = false
            end
            continue
        end

        allDone = false

        -- Move along quadratic bezier from SpawnPos -> Bend -> EndPos using easing
        local tRaw = rAge / r.Life
        local ok, res = pcall(r.EaseFunction, tRaw)
        local te = nil
        if ok and type(res) == "number" then te = res else te = math.Clamp(tRaw, 0, 1) end

        -- local newPos = QuadraticBezier(r.SpawnPos, r.BendPoint, r.EndPos, te)
        local newPos = QuadraticBezier(r.SpawnPos, r.BendPoint, self:GetPos(), te) -- endpos should be dynamic, as it is attached to weapon's hand bone merge point 

        -- Spawn a new point if moved sufficiently since last appended point
        if not r.LastAppendPos or r.LastAppendPos:Distance(newPos) > 2 then
            RibbonAddPoint(self, r, newPos)
            r.LastAppendPos = newPos
        end

        -- Prune old points older than SegmentLifetime
        for i = #r.TrailPoints, 1, -1 do
            if (now - r.TrailPoints[i].timestamp) > self.SegmentLifetime then
                table.remove(r.TrailPoints, i)
            end
        end
    end
	
	if CurTime() > self.CreationTime + self.LifeTime then 
		if IsValid(self.Emitter) then self.Emitter:Finish() end 
		-- disable dlight if it hadn't removed itself 
		local dlight = DynamicLight(self.Entity:EntIndex()) 
		dlight.dietime = CurTime() 
		dlight.brightness = 0 
		dlight.size = 9999 
		dlight.r = 0 
		dlight.g = 0 
		dlight.b = 0 
		dlight.nomodel = true 
		dlight.pos = self:GetPos() 
		dlight.dir = -self:GetOwner():GetOwner():GetUp() 
		if allDone then 
			return false 
		end 
	end 
	local dlight_scale = 1200 
	local Cycle = math.Clamp((CurTime() - self.CreationTime) / self.LifeTime, 0, 1) 
	-- print("ns_a_chargestart cycle:",Cycle) 
	local dlight = DynamicLight(self.Entity:EntIndex()) 
	dlight.brightness = 1 * (1-Cycle) 
	-- print("brightness is:",1 * (1-Cycle)) 
	dlight.decay = 1000 
	dlight.dietime = CurTime() + FrameTime() 
	dlight.pos = self:GetPos() 
	dlight.size = dlight_scale * Cycle 
	dlight.r = 0 * (1-Cycle) 
	dlight.g = 255 * (1-Cycle) 
	dlight.b = 255 * (1-Cycle) 
	dlight.minlight = 100 * (1-Cycle) 
	dlight.innerangle = 0 
	dlight.outerangle = 100 
	dlight.style = 0
	dlight.dir = -self:GetOwner():GetOwner():GetUp() 
	self:SetNextClientThink(CurTime()+FrameTime()) 
	return true 
end 

function EFFECT:Render() 
	local mat = NE_FlareM.Material 
	render.SetMaterial(mat) 
	local scale = math.sin(CurTime()*1/engine.AbsoluteFrameTime()) * 32 
	render.DrawSprite(self:GetPos(),128+scale,128+scale) 
	
	local now = CurTime()
    local mat = self.Ribbon_Mat
    render.SetMaterial(mat)

    local allSegInfos = {}

    -- Build segInfos per-ribbon, but keep ribbons separate to avoid stitching
    for _, r in ipairs(self.Ribbons) do
        local pts = r.TrailPoints
        if not pts or #pts < 2 then
            -- still might show single-point trailing, skip if insufficient
            continue
        end

        local segInfos = {}
        for i = #pts, 1, -1 do
            local seg = pts[i]
            local lifeFrac = math.Clamp((now - seg.timestamp) / (self.SegmentLifetime or 0.4), 0, 1)
            local invLife = 1 - lifeFrac

            local alpha = math.sin(math.pi * invLife)
            local intensity = Lerp(invLife, 1.5, 0.2)

            local acol = math.Clamp(255 * alpha, 0, 255)

            local widthMul = SampleCurve(self.WidthCurve, lifeFrac)
            local halfWidth = (self.BaseWidth * widthMul * (self.WidthMultiplier or 1)) * 0.5

            local p1 = seg.pos1
            local p2 = seg.pos2

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

                local twistAngle = 0
                if r.TwistCurve then
                    local twistNormalized = SampleCurve(r.TwistCurve, lifeFrac)
                    twistAngle = twistNormalized * (seg.twistStrength or 1.0)
                else
                    -- small twist based on adjacent segments
                    if i < #pts then
                        local nextSeg = pts[i+1]
                        if nextSeg then
                            local nextT = (nextSeg.pos2 - nextSeg.pos1)
                            if nextT:LengthSqr() > 1e-6 then
                                nextT:Normalize()
                                local dot = math.Clamp(tangent:Dot(nextT), -1, 1)
                                local ang = math.acos(dot)
                                twistAngle = ang * 0.5 * (seg.rand or 1.0)
                            end
                        end
                    end
                end

                if math.abs(twistAngle) > 1e-6 then
                    right = RotateVectorAroundAxis(right, tangent, twistAngle)
                    right = right:GetNormalized()
                end

                local off = right * halfWidth

                local t = Vector(tangent.x, tangent.y, tangent.z):GetNormalized()
                local b = Vector(right.x, right.y, right.z):GetNormalized()
                local n = t:Cross(b)
                if n:LengthSqr() < 1e-6 then
                    n = Vector(0,0,1)
                else
                    n = n:GetNormalized()
                end

                local uCoord = (seg.cumulative or 0) / (self.TilingLength or 250)
                local uA, vA = 0, uCoord
                local uB, vB = 1, uCoord
                local tuA, tvA = TransformUV(uA, vA, 0.5, 0.5, 1, 1, -90, 0, 0)
                local tuB, tvB = TransformUV(uB, vB, 0.5, 0.5, 1, 1, -90, 0, 0)

                table.insert(segInfos, {
                    left = { pos = p1 - off, u = tuA, v = tvA },
                    right = { pos = p2 + off, u = tuB, v = tvB },
                    color = Color(255, 200, 255, acol),
                    normal = n,
                    tangent = t,
                    binormal = b
                })
            end
        end

        -- Convert segInfos to triangles for this ribbon only
        if #segInfos >= 2 then
            local tris = {}
            for i = 1, #segInfos - 1 do
                local a = segInfos[i]
                local b = segInfos[i + 1]

                -- Triangle 1
                table.insert(tris, { pos = a.left.pos,  u = a.left.u,  v = a.left.v,  color = a.color, normal = a.normal, tangent = a.tangent, binormal = a.binormal })
                table.insert(tris, { pos = a.right.pos, u = a.right.u, v = a.right.v, color = a.color, normal = a.normal, tangent = a.tangent, binormal = a.binormal })
                table.insert(tris, { pos = b.left.pos,  u = b.left.u,  v = b.left.v,  color = b.color, normal = b.normal, tangent = b.tangent, binormal = b.binormal })

                -- Triangle 2
                table.insert(tris, { pos = b.left.pos,  u = b.left.u,  v = b.left.v,  color = b.color, normal = b.normal, tangent = b.tangent, binormal = b.binormal })
                table.insert(tris, { pos = a.right.pos, u = a.right.u, v = a.right.v, color = a.color, normal = a.normal, tangent = a.tangent, binormal = a.binormal })
                table.insert(tris, { pos = b.right.pos, u = b.right.u, v = b.right.v, color = b.color, normal = b.normal, tangent = b.binormal, binormal = b.binormal })
            end

            -- Draw mesh for this ribbon
            local meshObj = Mesh(self.Mat)
            meshObj:BuildFromTriangles(tris)
            meshObj:Draw()
            meshObj:Destroy()
        end
    end
	
end 