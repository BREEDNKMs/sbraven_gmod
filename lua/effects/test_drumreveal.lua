EFFECT.ModelName = "models/stellarblade/Sword_Line_02_A.mdl"
EFFECT.Duration = 2

function EFFECT:Init( data )
    self.StartTime = CurTime() 
    self:SetModel( self.ModelName )
    self:SetPos( data:GetOrigin() )
    self:SetAngles( data:GetAngles() or Angle( 0, 0, 0 ) )
    self.StartAngle = 75
    self.Meshes = {}
    
    local visualMeshes = util.GetModelMeshes( self.ModelName )
    if not visualMeshes then return end
    
    for _, meshData in ipairs( visualMeshes ) do
        table.insert( self.Meshes, {
            Mesh = nil, -- Do NOT initialize the mesh object here yet
            Material = Material( meshData.material ),
            OriginalTriangles = meshData.triangles,
            HasData = false
        })
    end
end

function EFFECT:Think()
    local fraction = ( CurTime() - self.StartTime ) / self.Duration
    
    -- Cleanup and terminate after 2 seconds
    if fraction >= 1 then
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
    self:UpdateMeshes( fraction )
    
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

-- Note: For lua EFFECTs, the draw hook is technically named Render(), not Draw()
function EFFECT:Render()
    if not self.Meshes then return end
	local fraction = ( CurTime() - self.StartTime ) / self.Duration
    
    -- Set up a matrix to handle the Entity's Position, Angles, and Scale
    local mat = Matrix()
    mat:Translate( self:GetPos() )
    mat:SetAngles( self:GetAngles() )
    
    -- Obey self:GetModelScale()
    local scale = self:GetModelScale() or 1
    mat:Scale( Vector( scale, scale, scale ) )
    
    -- Apply the matrix transformation
    cam.PushModelMatrix( mat )
    
        for _, meshData in ipairs( self.Meshes ) do
            -- Only render if the mesh actually contains triangles
            if meshData.HasData and meshData.Mesh then
				local material = self:GetMaterial() != "" and self:GetMaterial() or meshData.Material 
				local brightness = 40.0-fraction
                render.SetMaterial( material ) 
				material:SetVector("$color2",Vector(7.13, 8.69, 10.0) * (brightness)) -- brightness 
                meshData.Mesh:Draw()
				material:SetUndefined("$color2",Vector(50,50,50)) 
            end
        end
        
    cam.PopModelMatrix()
end