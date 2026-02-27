EFFECT.ModelName = "models/stellarblade/Sword_Line_02_A.mdl"
EFFECT.Duration = 2
EFFECT.StartAngle = 0 
EFFECT.CullDuration = 0.2 
EFFECT.Material = "sprites/mi_a_swordtrail_01_2_tex" 
EFFECT.DieTime = 0.4 -- the time in which the effect will be removed entirely 

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

-- Example usage:
-- local v = GetLUTVector(0.5) -- Vector(25.100002, 8.5, 6.25)
-- print(v) -- uses Vector tostring in your environment

function EFFECT:Init( data )
    self.CreationTime = CurTime()
    self:SetModel( self.ModelName )
    -- self:SetPos( data:GetOrigin() )
    self:SetAngles( data:GetAngles() )
	self:SetModelScale(data:GetScale()*0.20) 
	self:SetMaterial("sprites/mi_a_swordtrail_01_2") -- this does not work, self:GetMaterial() returns "" 
    self.Meshes = {} 
	self:SetOwner(data:GetEntity()) 
	self:SetParent(data:GetEntity()) 
    
    local visualMeshes = util.GetModelMeshes( self:GetModel() )
    
    for _, meshData in ipairs( visualMeshes ) do
        table.insert( self.Meshes, {
            Mesh = nil, -- Do NOT initialize the mesh object here yet
            Material = self.Material and Material(self.Material) or Material( meshData.material ),
            OriginalTriangles = meshData.triangles,
            HasData = false
        })
    end
end

function EFFECT:Think() 
	self:SetNextClientThink(CurTime()+FrameTime()) 
    local cullfraction = math.min(( CurTime() - self.CreationTime ) / self.CullDuration,1)
    local die = ( CurTime() - self.CreationTime ) / self.DieTime
    
    -- Cleanup and terminate after 2 seconds
    if die >= 1 then
        if self.Meshes then
            for _, meshData in ipairs( self.Meshes ) do
                if meshData.Mesh then
                    meshData.Mesh:Destroy() -- Crucial: Prevent memory leaks!
                end
            end
        end
        return false
    end
    
    -- Update the mesh culling dynamically
    self:UpdateMeshes( cullfraction )
    
    return true
end

function EFFECT:UpdateMeshes( fraction )
    local currentAngle = fraction * 360
    
    for _, meshData in ipairs( self.Meshes ) do
        local newTriangles = {}
        local origTriangles = meshData.OriginalTriangles
        
        for i = 1, #origTriangles, 3 do
            local v1 = origTriangles[i]
            local v2 = origTriangles[i + 1]
            local v3 = origTriangles[i + 2]
            
            if not v1 or not v2 or not v3 then break end
            
            local cx = ( v1.pos.x + v2.pos.x + v3.pos.x ) / 3
            local cy = ( v1.pos.y + v2.pos.y + v3.pos.y ) / 3
            
            -- Get the raw angle from the center (-180 to 180)
            local ptAngle = math.deg( math.atan2( -cy, cx ) )
            
            -- SHIFT THE ANGLE: Subtract our desired starting angle
            ptAngle = ptAngle - self.StartAngle
            
            -- NORMALIZE: Lua's modulo perfectly wraps negative angles back to the 0-359 range
            ptAngle = ptAngle % 360
            
            -- Now, whatever StartAngle you chose acts as the true '0' for the sweep
            if ptAngle <= currentAngle then
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
    if !self.Meshes then return end
	local fraction = ( CurTime() - self.CreationTime ) / self.DieTime
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
	-- print("fraction:",fraction,"cullfraction:",cullfraction) 
    
	for _, meshData in ipairs( self.Meshes ) do
		-- Only render if the mesh actually contains triangles
		if meshData.HasData and meshData.Mesh then
			local material = meshData.Material 
			-- local brightness = 40.0-fraction
			local brightness = 1
			local material = Material("sprites/mi_a_swordtrail_01_2" ) -- refract texture 
			render.SetMaterial( Material("sprites/mi_a_swordtrail_01_2" )) 
			-- print("material is:",material) 
			-- print(GetLUTVector(fraction)) 
			-- material:SetVector("$color2", Vector(50,50,50)) -- brightness 
			material:SetFloat("$refractamount",(1-fraction)*(0.15)) 
			meshData.Mesh:Draw()
			material:SetUndefined("$refractamount") 
			
			local material = meshData.Material -- albedo texture 
			render.SetMaterial( material ) 
			-- print("material is:",material) 
			-- print(GetLUTVector(fraction)) 
			local color = GetLUTVector(fraction) 
			color = Vector(color.z,color.y,color.x) 
			color = color * Vector(1,2,3) 
			material:SetVector("$color2", color) -- brightness 
			material:SetVector("$refracttint", color) -- brightness 
			-- material:SetVector("$color2", Vector(50,50,50)) -- brightness 
			meshData.Mesh:Draw()
			material:SetUndefined("$color2") 
			material:SetUndefined("$refracttint",Vector(1,1,1)) 
			
		end
	end
        
    cam.PopModelMatrix()
	debugoverlay.Line(self:GetPos(),self:GetPos()+self:GetForward()*500,FrameTime()*2) 
end