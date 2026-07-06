local mi_b_lenscircle_01_21 = Material("sprites/mi_b_lenscircle_01_21") 
local light_glow02_add = Material("sprites/light_glow02_add") 
local ma_a_alarm_02 = Material("sprites/ma_a_alarm_02") 

function EFFECT:Init(data) 
	local Pos, Ang, Scale, Time, Flags = data:GetOrigin(), data:GetAngles(), data:GetScale(), data:GetMagnitude(), data:GetFlags() 
	if Time <= 0 then Time = 0.8 end 
	-- print(data:GetHitBox(),data:GetEntity():GetBoneName(data:GetHitBox())) 
	Scale = Scale * 14 
	self.CreationTime = CurTime() 
	self.DieTime = Time 
	self:SetModelScale(Scale) 
	if IsValid(data:GetEntity()) then 
		-- self:AddEffects(EF_FOLLOWBONE) 
		self:SetOwner(data:GetEntity()) 
		-- self:SetParent(data:GetEntity(),data:GetHitBox()) 
		self:FollowBone(data:GetEntity(),data:GetHitBox()) 
		self:SetLocalPos(data:GetStart()) 
	end 
	-- print(data:GetStart(),Ang,Scale,Time,Flags) 
end 

function EFFECT:Think(data) 
	self:SetNextClientThink(CurTime()+FrameTime()) 
	if CurTime() > self.CreationTime + self.DieTime then return false end 
	return true 
end 

function EFFECT:Render() 
	local purple = Color(233,0,255,255)
	local yellow = Color(225,255,0,255)
	local blendin, blendout = 0.33, 0.5
	local Cycle = math.Clamp((CurTime() - self.CreationTime) / self.DieTime,0,1)

	local col 
	if Cycle <= blendin then 
		col = yellow 
	elseif Cycle >= blendout then 
		col = purple 
	else 
		-- remap Cycle's position within [blendin, blendout] to a 0-1 fraction 
		local frac = (Cycle - blendin) / (blendout - blendin) 
		col = yellow:Lerp(purple, frac) 
	end 
	local Pos = self:GetPos() 
	local mat = mi_b_lenscircle_01_21 
	render.SetMaterial(mat) 
	local emissiveblendtint = col:ToVector()*5 
	local emissiveblendstrength = math.Clamp(1-Cycle,0,1)  
	mat:SetVector("$emissiveblendtint",emissiveblendtint) 
	mat:SetVector("$detailtint",col:ToVector()) 
	mat:SetFloat("$emissiveblendstrength",emissiveblendstrength) 
	mat:SetFloat("$detailblendfactor",emissiveblendstrength) 
	local spritescale = (self:GetModelScale()*Cycle) 
	render.DrawSprite(Pos,spritescale,spritescale,col:ToVector()) 
	mat:SetUndefined("$emissiveblendtint") 
	mat:SetUndefined("$emissiveblendstrength") 
	mat:SetUndefined("$detailtint") 
	local mat = light_glow02_add 
	render.SetMaterial(mat) 
	-- mat:SetFloat("$emissiveblendstrength",emissiveblendstrength) 
	local spritescale = (self:GetModelScale()*Cycle)*4 
	local col2 = Color(col.r*(1-Cycle),col.g*(1-Cycle),col.b*(1-Cycle),255) 
	render.DrawSprite(Pos,spritescale,spritescale,col2) 
	render.DrawSprite(Pos,spritescale,spritescale,col2) 
	render.DrawSprite(Pos,spritescale,spritescale,col2) 
	render.DrawSprite(Pos,spritescale,spritescale,col2) 
	-- render.SetMaterial(ma_a_alarm_02) 
	-- render.DrawSprite(Pos,128,128,Color(255,255,255,255)) 
	self:MA_A_Alarm_02_Render(Cycle,self:GetPos(),col) 
	self:MA_A_Alarm_02_Render(Cycle,self:GetPos()+Vector(0,0,(1-Cycle) * 15),col) 
	self:MA_A_Alarm_02_Render(Cycle,self:GetPos()-Vector(0,0,(1-Cycle) * 15),col) 
end 

function EFFECT:MA_A_Alarm_02_Render(Cycle,Pos,col)
    local camPos, camAng = EyePos(), EyeAngles() 
    
    -- Calculate screen-aligned start and end positions using the camera's right vector
    local camRight = camAng:Right()
	local ribbonLength = Cycle * 150 
	local ribbonWidth = (1-Cycle) * 64 
	local ribbonMinWidth = (1-Cycle) * 4 
	-- print(ribbonWidth) 
    local StartPos = Pos - (camRight * ribbonLength) -- Left side of the screen
    local EndPos   = Pos + (camRight * ribbonLength) -- Right side of the screen
    
    local delta = EndPos - StartPos
    local length = delta:Length()
    
    -- Safety check for zero-length beams
    if length < 0.1 then return end
    local dir = delta / length

    -- Define the custom width profile mapping along the beam length (t = 0.0 to 1.0)
    local segments = {
        {t = 0.0, width = ribbonMinWidth},
        {t = 0.3, width = ribbonWidth},
        {t = 0.6, width = ribbonWidth},
        {t = 1.0, width = ribbonMinWidth}
    }

    render.SetMaterial(ma_a_alarm_02)
    
    local quadCount = #segments - 1
    mesh.Begin(MATERIAL_QUADS, quadCount)
    
    -- Smoothly fade out the beam alpha over its lifetime
    local lifeLeft = (CurTime() - self.CreationTime) / self.DieTime
    local alpha = math.Clamp(lifeLeft * 255, 0, 255)

    for i = 1, quadCount do
        local p1 = segments[i]
        local p2 = segments[i + 1]

        local worldPos1 = StartPos + dir * (p1.t * length)
        local worldPos2 = StartPos + dir * (p2.t * length)

        -- This cross product now automatically extracts the camera's UP vector,
        -- ensuring the beam height always expands perfectly perpendicular to your viewport.
        local toCam1 = (worldPos1 - camPos):GetNormalized()
        local right1 = dir:Cross(toCam1):GetNormalized()

        local toCam2 = (worldPos2 - camPos):GetNormalized()
        local right2 = dir:Cross(toCam2):GetNormalized()

        local v1 = worldPos1 - right1 * (p1.width * 0.5)
        local v2 = worldPos1 + right1 * (p1.width * 0.5)
        local v3 = worldPos2 + right2 * (p2.width * 0.5)
        local v4 = worldPos2 - right2 * (p2.width * 0.5)

        -- Vertex 1
        mesh.Position(v1)
        mesh.TexCoord(0, p1.t, 0)
        mesh.Color(col.r,col.g,col.b, alpha)
        mesh.AdvanceVertex()

        -- Vertex 2
        mesh.Position(v2)
        mesh.TexCoord(0, p1.t, 1)
        mesh.Color(col.r,col.g,col.b, alpha)
        mesh.AdvanceVertex()

        -- Vertex 3
        mesh.Position(v3)
        mesh.TexCoord(0, p2.t, 1)
        mesh.Color(col.r,col.g,col.b, alpha)
        mesh.AdvanceVertex()

        -- Vertex 4
        mesh.Position(v4)
        mesh.TexCoord(0, p2.t, 0)
        mesh.Color(col.r,col.g,col.b, alpha)
        mesh.AdvanceVertex()
    end

    mesh.End()
end