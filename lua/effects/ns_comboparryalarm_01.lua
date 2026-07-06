-- lua/effects/effect_ma_a_dirtmask_01.lua

EFFECT.Mat = Material("sprites/ma_a_dirtmask_01")

local function PushVertex(pos, normal, u, v, r, g, b, a)
	mesh.Position(pos)
	mesh.Normal(normal)
	mesh.Color(r, g, b, a)
	mesh.TexCoord(0, u, v)
	mesh.AdvanceVertex()
end

function EFFECT:Init(data) 
	self:SetModelScale(data:GetScale()) 
	if self:GetModelScale() <= 10 then self:SetModelScale(80) end 
	if IsValid(data:GetEntity()) then self:SetPos(data:GetEntity():EyePos()) self:SetOwner(data:GetEntity()) self:SetParent(data:GetEntity()) end 
	debugoverlay.Cross(self:GetPos(),self:GetModelScale(),2) 

	-- Treat magnitude as lifetime in seconds
	self.LifeTime = 0.2
	self.DieTime = CurTime() + self.LifeTime
	self.CreationTime = CurTime()

	-- More segments = smoother circle
	self.Segments = math.Clamp(math.floor(12 + self:GetModelScale() * 6), 12, 48) 
end

function EFFECT:Think()
	return CurTime() < self.DieTime
end

function EFFECT:Render()
	local now = CurTime()
	local lifeFrac = math.Clamp((self.DieTime - now) / self.LifeTime, 0, 1)
	if lifeFrac <= 0 then return end

	local pos = self:GetPos()
	local eyeAng = EyeAngles()
	local right = eyeAng:Right() * self:GetModelScale()
	local up = eyeAng:Up() * self:GetModelScale()
	local normal = (EyePos() - pos):GetNormalized()

	-- Center stays fully red; outer vertices fade to transparent
	local centerA
	local midA = 200 
	local maxA = midA
	local bendPoint = 0.7 

	local corners = {
		pos + right + up,
		pos + right - up,
		pos - right + up,
		pos - right - up
	}

	local blocked = false
	for i = 1, 4 do
		local tr = util.TraceLine({
			start = EyePos(),
			endpos = corners[i],
			mask = MASK_NPCWORLDSTATIC
		})

		if tr.Hit then
			maxA = maxA - 50 
			-- blocked = true
			-- break
		end
	end

	if lifeFrac <= bendPoint then
		centerA = math.floor(Lerp(lifeFrac / bendPoint, 0, maxA))
	else
		centerA = math.floor(Lerp((lifeFrac - bendPoint) / (1 - bendPoint), maxA, 0))
	end
	
	local edgeA = 0

	render.SetMaterial(self.Mat)

	mesh.Begin(MATERIAL_TRIANGLES, self.Segments)

	local centerUV = 0.5

	for i = 1, self.Segments do
		local a1 = (i - 1) / self.Segments * math.pi * 2
		local a2 = i / self.Segments * math.pi * 2

		local c1, s1 = math.cos(a1), math.sin(a1)
		local c2, s2 = math.cos(a2), math.sin(a2)

		local v1 = pos + right * c1 + up * s1
		local v2 = pos + right * c2 + up * s2

		local u1, t1 = 0.5 + c1 * 0.5, 0.5 + s1 * 0.5
		local u2, t2 = 0.5 + c2 * 0.5, 0.5 + s2 * 0.5

		-- Triangle fan: center -> edge1 -> edge2
		PushVertex(pos, normal, centerUV, centerUV, 255, 0, 0, centerA)
		PushVertex(v1,  normal, u1, t1,        255, 0, 0, edgeA)
		PushVertex(v2,  normal, u2, t2,        255, 0, 0, edgeA)
	end

	mesh.End()
end