EFFECT.ModelName = "models/stellarblade/Sword_Line_02_A.mdl"
EFFECT.Duration = 2
local refractamount = 0.15 

-- NEW SETTINGS --
EFFECT.StartAngle = -75   -- The angle where the culling slice begins
EFFECT.EndAngle = 145   -- The angle where the culling slice finishes
EFFECT.CCW = false      -- Counter-Clockwise rotation toggle
EFFECT.CullNormal = Vector(0, 0, 1) -- The axis to spin around (Default: Up/Yaw axis)

EFFECT.CullDuration = 0.2 
EFFECT.Material = "sprites/mi_a_swordtrail_01_2_tex" 
EFFECT.RefractMaterial = Material("sprites/mi_a_swordtrail_01_2") 
EFFECT.DieTime = 0.4 -- the time in which the effect will be removed entirely 
EFFECT.ColorScaler = Vector(1,2,3) 
EFFECT.ReplaceColors = true 

-- LUT Vector sampler with piecewise easing (no table parser; control points embedded)
-- Returns Vector(r,g,b). HDR values allowed (>1). t in [0,1].
local CP = {
    -- sampled control points (t, r,g,b) chosen from the provided LUT
    {t = 0.000000, v = Vector(50.000000, 17.000000, 12.500000)},
    {t = 0.125000, v = Vector(47.858336, 16.2689095, 11.9624335)},
    {t = 0.250000, v = Vector(42.218750, 14.343750, 10.546875)},
    {t = 0.375000, v = Vector(34.242362, 11.620886, 8.5447695)},
    {t = 0.500000, v = Vector(25.100002, 8.500000, 6.250000)},
    {t = 0.625000, v = Vector(15.9576395, 5.37911365, 3.9552307)},
    {t = 0.750000, v = Vector(7.981247, 2.65625, 1.953125)},
    {t = 0.875000, v = Vector(2.34166715, 0.73109055, 0.53756665)},
    {t = 1.000000, v = Vector(0.200000, 0.000000, 0.000000)}
}

-- choose easing by global t (piecewise policy)
local function chooseEasingByT(t)
    if t <= 0.25 then
        return math.ease.InQuad
    elseif t <= 0.75 then
        return math.ease.InOutCubic
    else
        return math.ease.OutQuad
    end
end

-- Main function: returns Vector(r,g,b)
-- t expected in [0,1] (but function will handle slightly out-of-range by clamping to ends)
local function GetLUTVector(t)
    if t ~= t then t = 0 end -- guard NaN
    if t <= CP[1].t then return CP[1].v end
    if t >= CP[#CP].t then return CP[#CP].v end

    -- find segment
    local segIdx = 1
    for i = 1, #CP-1 do
        if t >= CP[i].t and t <= CP[i+1].t then
            segIdx = i
            break
        end
    end

    local a = CP[segIdx]
    local b = CP[segIdx+1]
    -- local normalized u inside the segment
    local segSpan = (b.t - a.t)
    local u = 0
    if segSpan > 0 then
        u = (t - a.t) / segSpan
    else
        u = 0
    end

    -- choose easing based on global t (piecewise policy)
    local ease = chooseEasingByT(t) 
    local ue = ease(u)

    -- interpolate and return Vector (HDR allowed; no clamping)
    return LerpVector(ue,a.v, b.v)
end

function EFFECT:Init( data ) 
    self.CreationTime = CurTime() 
	self.LocalPos = data:GetStart() 
	self.LocalAng = data:GetAngles() 
	-- self.LocalAng.x = self.LocalAng.x 
    self:SetModel( self.ModelName ) 
    self:SetModelScale(data:GetScale()*0.20) 
    self:SetMaterial("sprites/mi_a_swordtrail_01_2") 
    self.Meshes = {} 
	self:SetAngles(self:GetAngles()) 
	if IsValid(data:GetEntity()) then 
		self.OwnerAng = data:GetEntity():GetAngles() 
		self.OwnerAng.x = 0 
		-- print("ent is:",data:GetEntity()) 
		self:SetOwner(data:GetEntity()) 
		local Owner = data:GetEntity() 
		local RootSocket = Owner:LookupAttachment("RootSocket") 
		if RootSocket > 0 then 
			local att = Owner:GetAttachment(RootSocket)
			if att then
				-- Convert the cached LocalPos and LocalAng to World coordinates relative to the attachment
				local wPos, wAng = LocalToWorld(self.LocalPos, self.LocalAng, att.Pos, att.Ang)
				self:SetPos(wPos) 
				self:SetAngles(wAng) 
				
				-- Ensure Sword_Line_02_B also mimics this exact position
				if IsValid(self.Sword_Line_02_B) then
					self.Sword_Line_02_B:SetPos(wPos)
					self.Sword_Line_02_B:SetAngles(wAng)
				end
			end
		else 
			self:SetParent(self:GetOwner()) 
			self:SetLocalPos(self.LocalPos) 
			self:SetAngles(self.LocalAng) 
		end 
	end 
	-- self:SetLocalPos(self.LocalPos) 
	self.Emitter = ParticleEmitter(self:GetPos()) 
	-- self.MeshTrail_Light = self.Emitter:Add("sprites/bluelight1",self:GetPos()) 
	self.MeshTrail_Light = self.Emitter:Add("sprites/light_glow02_add",self:GetPos()) 
	self.MeshTrail_Light:SetStartSize(160) 
	self.MeshTrail_Light:SetDieTime(0.5) 
	self:SetRenderMode(1) 
	
	self.Sword_Line_02_B = ClientsideModel("models/stellarblade/Sword_Line_02_B.mdl",RENDERGROUP_BOTH) 
	local Sword_Line_02_B = self.Sword_Line_02_B 
	Sword_Line_02_B.StartAngle = self.StartAngle   -- The angle where the culling slice begins
	Sword_Line_02_B.EndAngle = self.EndAngle   -- The angle where the culling slice finishes
	Sword_Line_02_B.CCW = self.CCW      -- Counter-Clockwise rotation toggle
	Sword_Line_02_B.CullNormal = self.CullNormal -- The axis to spin around (Default: Up/Yaw axis)

	Sword_Line_02_B.CullDuration = self.CullDuration 
	-- Sword_Line_02_B.Material = "sprites/mi_a_swordtrail_01_2_tex" -- comment material to use model's own material 
	Sword_Line_02_B.RefractMaterial = nil 
	Sword_Line_02_B.DieTime = self.DieTime -- the time in which the effect will be removed entirely 
	Sword_Line_02_B.ColorScaler = Vector(0.1,0.1,0.1) 
	Sword_Line_02_B.ReplaceColors = true 
	Sword_Line_02_B.CreationTime = CurTime() 
	if IsValid(data:GetEntity()) then 
		Sword_Line_02_B:SetOwner(data:GetEntity()) 
		Sword_Line_02_B:SetParent(self:GetParent()) 
	end 
	Sword_Line_02_B:SetRenderMode(1) 
	-- Sword_Line_02_B:SetLocalPos(self.LocalPos) 
	Sword_Line_02_B:SetAngles(self:GetAngles()) 
	Sword_Line_02_B:SetModelScale(self:GetModelScale()) 
	Sword_Line_02_B.RenderOverride = self.Render 
    
	-- Initialize meshes for Sword_Line_02_B
	Sword_Line_02_B.Meshes = {}
	local visualMeshesB = util.GetModelMeshes( "models/stellarblade/Sword_Line_02_B.mdl" )
	if visualMeshesB then
		for _, meshData in ipairs( visualMeshesB ) do
			table.insert( Sword_Line_02_B.Meshes, {
				Mesh = nil, 
				Material = Sword_Line_02_B.Material and Material(Sword_Line_02_B.Material) or Material( meshData.material ),
				triangles = meshData.triangles,
				HasData = false
			})
		end
	end
	
    local visualMeshes = util.GetModelMeshes( self:GetModel() )
    
    for _, meshData in ipairs( visualMeshes ) do
        table.insert( self.Meshes, {
            Mesh = nil, -- Do NOT initialize the mesh object here yet
            Material = self.Material and Material(self.Material) or Material( meshData.material ),
            triangles = meshData.triangles,
            HasData = false
        })
    end
end

function EFFECT:Think() 
    self:SetNextClientThink(CurTime()+FrameTime()) 
	local Owner = self:GetOwner() 
	if IsValid(Owner) then 
		local RootSocket = Owner:LookupAttachment("RootSocket") 
		if RootSocket > 0 then 
			local att = Owner:GetAttachment(RootSocket)
			if att then
				-- Convert the cached LocalPos and LocalAng to World coordinates relative to the attachment
				local wPos, wAng = LocalToWorld(self.LocalPos, self.LocalAng, att.Pos, att.Ang)
				self:SetPos(wPos) 
				-- self:SetAngles(wAng) 
				
				-- Ensure Sword_Line_02_B also mimics this exact position
				if IsValid(self.Sword_Line_02_B) then
					self.Sword_Line_02_B:SetPos(wPos)
					-- self.Sword_Line_02_B:SetAngles(wAng)
				end
			end
		end 
	end 
	debugoverlay.Cross(self:GetPos(),15,FrameTime()*2) 
    local cullfraction = math.min(( CurTime() - self.CreationTime ) / self.CullDuration,1)
    local die = ( CurTime() - self.CreationTime ) / self.DieTime
    
    -- Cleanup and terminate
    if die >= 1 then
        if self.Meshes then
            for _, meshData in ipairs( self.Meshes ) do
                if meshData.Mesh and meshData.Mesh:IsValid() then
                    meshData.Mesh:Destroy() -- Crucial: Prevent memory leaks!
                end
            end
			self.Meshes = nil 
        end
		if IsValid(self.Emitter) then self.Emitter:Finish() end 
		if IsValid(self.Sword_Line_02_B) then 
			-- Destroy the B meshes before removing the entity
			if self.Sword_Line_02_B.Meshes then
				for _, meshData in ipairs( self.Sword_Line_02_B.Meshes ) do
					if meshData.Mesh and meshData.Mesh:IsValid() then meshData.Mesh:Destroy() end
				end
				self.Sword_Line_02_B.Meshes = nil 
			end
			self.Sword_Line_02_B.RenderOverride = function() end 
			SafeRemoveEntity(self.Sword_Line_02_B) 
		end 
        return false
    end
    
    -- Update the mesh culling dynamically
    self:UpdateMeshes( cullfraction )
	
	-- Run the exact same culling math but trick it into using Sword_Line_02_B as "self"
	if IsValid(self.Sword_Line_02_B) then
		self.UpdateMeshes( self.Sword_Line_02_B, cullfraction )
	end
    
    return true
end

function EFFECT:UpdateMeshes( fraction )
    -- Calculate the vectors to build a 2D plane on our custom culling normal
	local normal = (self.CullNormal or Vector(0, 0, 1)):GetNormalized()
    local cullAng = normal:Angle()
    local planeX = cullAng:Right()
    local planeY = cullAng:Up()
    
    -- Calculate the total size of the arc we want to sweep
    local totalSweep = (self.EndAngle - self.StartAngle) % 360
    if self.CCW then
        totalSweep = (self.StartAngle - self.EndAngle) % 360
    end
    -- If it's mathematically 0, we assume it means a full 360 degree sweep
    if totalSweep == 0 then totalSweep = 360 end
    
    local currentSweep = totalSweep * fraction
    
    -- Calculate the current sweeping angle
    local currentAngleDeg
    if self.CCW then
        currentAngleDeg = self.StartAngle - currentSweep
    else
        currentAngleDeg = self.StartAngle + currentSweep
    end
    
    -- Convert the 2D angle back into a 3D local direction vector using our custom plane
    local rad = math.rad( currentAngleDeg )
    local sweepDirLocal = planeX * math.cos( rad ) + planeY * math.sin( rad )
    
    -- Transform the local direction to world space so debug lines render correctly if the entity is rotated
    local sweepDirWorld = Vector( sweepDirLocal.x, sweepDirLocal.y, sweepDirLocal.z )
    sweepDirWorld:Rotate( self:GetAngles() )
    
	local spriteDistance = self:BoundingRadius()*0.75 
	local intensityInterval = 0.87 
	if self.MeshTrail_Light then 
		local currentIntensity = 0
		self.MeshTrail_Light:SetPos(self:GetPos()+sweepDirWorld*spriteDistance) 
		if fraction < intensityInterval then -- increase trail light up to 128 until 0.7 
			currentIntensity = fraction / intensityInterval 
			local size = currentIntensity * 128
			self.MeshTrail_Light:SetStartSize(size) 
			self.MeshTrail_Light:SetEndSize(size) 
		else -- fade from 128 to 0 
			local fadeFraction = (fraction - intensityInterval) / (1-intensityInterval) 
			currentIntensity = 1 - fadeFraction
			local size = 128 * (1 - fadeFraction)
			self.MeshTrail_Light:SetStartSize(size) 
			self.MeshTrail_Light:SetEndSize(size) 
		end 
		if IsValid(self.Emitter) then 
			local spawnCount = math.ceil(1 + (10 * currentIntensity))
			for i = 1, spawnCount do -- increase total sprite amount as we are closer to highest interval 
				local p = self.Emitter:Add("sprites/mi_a_gpusparks_01_tr",self.MeshTrail_Light:GetPos()) 
				if p then
					p:SetStartSize(3.2 + math.random(0, 6.4 * currentIntensity)) -- random max increasing as the interval is closer to highest intensity 
					p:SetEndSize(0) 
					p:SetStartAlpha(255) 
					p:SetEndAlpha(255) 
					p:SetColor(200,200,255) 
					p:SetDieTime(math.Rand(0.2,0.4)) 
					p:SetVelocity(VectorRand() * (40 + (150 * currentIntensity))) -- random velocity increasing as the interval is closer to highest intensity 
					p:SetVelocityScale(true) 
					-- print(p:GetVelocity()) 
					p:SetStartLength(0.1 * currentIntensity) 
					p:SetEndLength(0) 
				end
			end 
			
			-- Get the normal axis in world space so the particles know what to orbit around
			local worldNormal = Vector(normal.x, normal.y, normal.z)
			worldNormal:Rotate(self:GetAngles())
			
			local currLightPos = self.MeshTrail_Light:GetPos()
			self.LastParticlePos = self.LastParticlePos or currLightPos
			self.LastParticleTime = self.LastParticleTime or SysTime()
			
			local elapsed = SysTime() - self.LastParticleTime
			local interval = Lerp(currentIntensity, 0.0035, 0.0015) -- Scale interval dynamically from low (0.0035) to max (0.0015) intensity
			local spawnCount = math.floor(elapsed / interval)
			
			if spawnCount > 0 then
				for i = 1, spawnCount do 
					-- Interpolate the position so particles spawn smoothly across the gap between frames
					local lerpFraction = i / spawnCount
					local spawnPos = LerpVector(lerpFraction, self.LastParticlePos, currLightPos)
					
					local p = self.Emitter:Add("sprites/light_glow02_add", spawnPos + VectorRand(-10,10)) 
					if p then 
						p.Origin = self:GetPos() 
						p.Axis = worldNormal -- Cache the rotational axis on the particle
						p:SetStartSize(6*(math.random()*currentIntensity)) 
						p:SetEndSize(0) 
						p:SetStartAlpha(255) 
						p:SetEndAlpha(0) 
						p:SetColor(0,255,255) 
						p:SetDieTime(2) 
						p:SetCollide(true) 
						-- Initialize starting velocity to move along the CW tangent
						local initialDir = (spawnPos - p.Origin):GetNormalized()
						p:SetVelocity(initialDir:Cross(p.Axis):GetNormalized() * math.random(80,120)) 
						local randforvelocity = math.random()
						
						-- Continuously update velocity to maintain circular CW orbit
						p:SetThinkFunction(function(pa)
							local Interval = math.Clamp(pa:GetLifeTime()/pa:GetDieTime(),0,1) 
							local diff = pa:GetPos() - pa.Origin
							-- Fallback to prevent divide-by-zero if particle hits exact center
							if diff:LengthSqr() < 0.001 then diff = VectorRand() end 
							local dir = diff:GetNormalized()
							
							-- Cross product: dir x axis = clockwise tangent vector
							local tangent = dir:Cross(pa.Axis):GetNormalized()
							pa:SetVelocity(tangent * 100*(randforvelocity*currentIntensity))
							-- also set color from p.Color from Color(255,255,255) to Color(0,255,255) as interval proceeds 
							p:SetColor((1-Interval) * 255,255,255) 
							pa:SetNextThink(CurTime())
						end)
						p:SetNextThink(CurTime())
					end
				end 
				
				-- Save time and position trackers for the next frame
				self.LastParticleTime = self.LastParticleTime + (spawnCount * interval)
				self.LastParticlePos = currLightPos
			end 
		end 
	end 
	-- debugoverlay.Line(self:GetPos(),self:GetPos()+self:GetForward()*spriteDistance,FrameTime()*2, Color(255, 255, 255)) -- the forward dir in white color 
	-- debugoverlay.Line(self:GetPos(),self:GetPos()+sweepDirWorld*spriteDistance,FrameTime()*2,Color(255,0,0)) -- the rotating culling line in red color 
    
    for _, meshData in ipairs( self.Meshes ) do
        local newTriangles = {}
        local origTriangles = meshData.triangles
        
        for i = 1, #origTriangles, 3 do
            local v1 = origTriangles[i]
            local v2 = origTriangles[i + 1]
            local v3 = origTriangles[i + 2]
            
            if not v1 or not v2 or not v3 then break end
            
            -- Get 3D Centroid
            local cx3 = ( v1.pos.x + v2.pos.x + v3.pos.x ) / 3
            local cy3 = ( v1.pos.y + v2.pos.y + v3.pos.y ) / 3
            local cz3 = ( v1.pos.z + v2.pos.z + v3.pos.z ) / 3
            local centroid = Vector(cx3, cy3, cz3)
            
            -- Project the 3D centroid onto our custom 2D culling plane using Dot Products
            local cx = centroid:Dot(planeX)
            local cy = centroid:Dot(planeY)
            
            -- Get the raw angle from the center on this new custom plane
            local ptAngle = math.deg( math.atan2( cy, cx ) )
            
            -- Calculate the rotational distance from our StartAngle depending on CCW / CW
            local dist
            if self.CCW then
                dist = (self.StartAngle - ptAngle) % 360
            else
                dist = (ptAngle - self.StartAngle) % 360
            end
            
            -- If the rotational distance is within our sweep range, it is rendered
            if dist <= currentSweep then
                table.insert( newTriangles, v1 )
                table.insert( newTriangles, v2 )
                table.insert( newTriangles, v3 )
            end
        end
        
        if meshData.Mesh then
            meshData.Mesh:Destroy()
            meshData.Mesh = nil
        end
        
        if #newTriangles >= 3 then
            meshData.Mesh = Mesh()
            meshData.Mesh:BuildFromTriangles( newTriangles )
            meshData.HasData = true
        else
            meshData.HasData = false
        end
    end
end

function EFFECT:Render()
    if not self.Meshes then return end
    local fraction = ( CurTime() - self.CreationTime ) / self.DieTime
	-- print("fraction is:",fraction) 
    local cullfraction = math.min(( CurTime() - self.CreationTime ) / self.CullDuration,1)
    
    -- Set up a matrix to handle the Entity's Position, Angles, and Scale
    local mat = Matrix()
    mat:Translate( self:GetPos() )
    mat:SetAngles( self:GetAngles() )
    
    -- Obey self:GetModelScale()
    local scale = self:GetModelScale() 
    mat:Scale( Vector( scale, scale, scale ) )
    
    -- Apply the matrix transformation
    cam.PushModelMatrix( mat )
    
    for _, meshData in ipairs( self.Meshes ) do
        -- Only render if the mesh actually contains triangles
        if meshData.HasData and meshData.Mesh then
            local material = meshData.Material 
            
			if self.RefractMaterial then 
				-- Refract pass
				local brightness = 1
				local refractMat = self.RefractMaterial 
				render.SetMaterial( refractMat ) 
				refractMat:SetFloat("$refractamount",(1-fraction)*(refractamount)) 
				meshData.Mesh:Draw()
				refractMat:SetUndefined("$refractamount") 
				-- print("(1-fraction)*(refractamount):",(1-fraction)*(refractamount))
			end 
            
            -- Albedo pass
            local albedoMat = meshData.Material 
            render.SetMaterial( albedoMat ) 
            
            local color = GetLUTVector(fraction) 
			if self.ReplaceColors then 
				color = Vector(color.z,color.y,color.x) 
			end 
            color = color * self.ColorScaler 
            albedoMat:SetVector("$color2", color) -- brightness 
            albedoMat:SetVector("$refracttint", color) -- tint 
            albedoMat:SetVector("$detailtint", color) -- tint 
            meshData.Mesh:Draw()
            
            albedoMat:SetUndefined("$color2") 
            albedoMat:SetUndefined("$refracttint") 
            albedoMat:SetUndefined("$detailtint") 
        end
    end
        
    cam.PopModelMatrix()
end