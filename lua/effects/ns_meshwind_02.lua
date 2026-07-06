-- Asset Definitions (Pre-cache models & materials)
local MODEL_WIND = "models/stellarblade/sm_cylinder_03.mdl"
local FALLBACK_MODEL = "models/hunter/tubes/tube2x2x2.mdl" 
-- Clean circular visual fallback if custom model isn't mounted
local MAT_WIND_1 = "sprites/MI_B_MeshWind_01_1"
local MAT_WIND_2 = "sprites/MI_B_MeshWind_01_2"
local FALLBACK_MAT = "models/debug/debugwhite" 
-- Clean visual fallback
-- Create material instances with correct flags (Additive, VertexColor, Translucent)
local MaterialPrimary = Material(MAT_WIND_1)
if MaterialPrimary:IsError() then MaterialPrimary = Material(FALLBACK_MAT) end
local MaterialSecondary = Material(MAT_WIND_2)
if MaterialSecondary:IsError() then MaterialSecondary = Material("sprites/heatwave") end 

-- Heat distortion fallback/* STREAMING_CHUNK:Defining the main EFFECT initialization logic... */ 

function EFFECT:Init(data)-- Capture incoming parameters from the network dispatch block 
	local Pos = data:GetOrigin() local Ang = data:GetAngles() 
	local Scale = data:GetScale() local Time = data:GetMagnitude() -- Represents duration of active spawning (DieTime) 
	Scale = Scale * 0.12 
	-- print(Pos,Scale,Ang,Time) 
	-- Safety checks on variables
	self:SetModelScale(Scale > 0 and Scale or 2.0) -- Double global size as matched in decoded data
	self.SpawnDuration = Time > 0 and Time or 0.2

	-- Setup core lifecycle timestamps
	local now = CurTime()
	self.CreationTime = now
	self.DieTime = now + self.SpawnDuration

	-- Track active clientside models (wind-blade instances)
	self.Meshes = {}

	-- Internal spawn timing accumulator
	self.SpawnAccumulator = 0

	-- Configurable performance caps (Matching 350 particles/sec visually without lagging Lua execution)
	self.TargetSpawnRate = 40 -- Spawn rate adjusted to balance visual density with FPS limits
	self.MaxActiveMeshes = 64

	-- Handle system parentage and local attachment coordinates
	local ParentEnt = data:GetEntity()
	if IsValid(ParentEnt) then
		self:SetOwner(ParentEnt)
		self:SetParent(ParentEnt)
	end

	-- Initialize simulation time dilation scalar
	self.TimeDilation = 0.85
end -- Internal helper to safely instantiate a wind mesh

function EFFECT:SpawnWindMesh()
	if #self.Meshes >= self.MaxActiveMeshes then return end
	-- Determine model path with fallback safety
	local selectedModel = MODEL_WIND
	-- if not util.IsValidModel(selectedModel) then
		-- selectedModel = FALLBACK_MODEL
	-- end

	local csProp = ClientsideModel(selectedModel, RENDERGROUP_BOTH)
	if not IsValid(csProp) then return end
	csProp:SetRenderMode(RENDERMODE_TRANSCOLOR) 

	-- Configure spatial variance per mesh instance to match dynamic tornado feel
	local spawnOffset = VectorRand(-12, 12)
	local parentPos = self:GetPos()
	local parentAng = Angle(0, self:GetAngles().y, 0) -- Base calculation on yaw only
	local spawnPos = parentPos 
	local spawnAng = Angle(0, parentAng.y + math.random(-180,180), 0) -- Enforce pure horizontal output

	-- Set initial transforms
	-- csProp:SetNoDraw(true) -- Do not let the standard pipeline draw this, we override manually
	csProp:SetPos(spawnPos)
	csProp:SetAngles(spawnAng)

	-- Define unique particle tracking state
	local windMesh = {
		Model = csProp,
		SpawnTime = CurTime(),
		Lifetime = 0.2, -- Standard short wind-slash lifespan
		Velocity = (spawnAng:Forward() * math.random()*10), -- Propelling forward vector
		VortexSpin = math.random(-360, 360), -- Dynamic rotation rate around movement axis
		VortexMult = 1.0, -- Fully engaged vortex velocity curve scale
		Color = Color(255, 255, 255),
		RandomSeed = math.random(1, 100)
	}
	csProp:SetMaterial((windMesh.RandomSeed > 50) and MAT_WIND_1 or MAT_WIND_2) 
	csProp:SetColor(Color(1,1,1,1)) 

	-- Inject the specialized RenderOverride into our ClientsideModel instance
	csProp.RenderOverride = function(ent)
		if not IsValid(self) or not IsValid(ent) then return end
		
		local ageFraction = (CurTime() - windMesh.SpawnTime) / windMesh.Lifetime
		if ageFraction < 0 or ageFraction > 1 then return end
		
		-- Custom Color Modulation mapping to User.ParColor (Cyan Glow) and User.TrailColor (Intense Light Cyan/White-Hot)
		local baseColor = Vector(1.0, 2.0, 3.0) -- Super-saturated turquoise
		local trailColor = Vector(7.1, 8.6, 10.0) -- Extreme emissive core
		
		-- Blend colors based on age (White-hot at birth, fading to cyan then evaporating)
		local blendedColor = LerpVector(ageFraction, trailColor, baseColor)
		
		-- Approximate the linear fade curve of the pre-computed ShaderLUT
		local alpha = 1.0
		if ageFraction < 0.1 then
			alpha = ageFraction / 0.1 -- Rapid fade-in
		else
			alpha = (1.0 - ageFraction) ^ 1.5 -- Uniform dissipation decay curve
		end
		alpha = alpha *15 
		-- print(alpha) 
		if alpha <= 0 then alpha = 1 end 
		
		-- Set rendering parameters
		-- render.SetColorModulation(blendedColor.x, blendedColor.y, blendedColor.z)
		-- render.SetBlend(alpha)
		
		-- Alternate material look to create texture variance across the system
		-- local useMat = (windMesh.RandomSeed > 50) and MaterialPrimary or MaterialSecondary
		-- render.MaterialOverride(useMat)
		
		-- Draw the visual model
		ent:SetColor(Color(blendedColor.x*255,blendedColor.y*255,blendedColor.z*255,alpha))
		ent:DrawModel()
		
		-- Cleanup render state modifiers
		-- render.MaterialOverride(nil)
		-- render.SetColorModulation(1, 1, 1)
		-- render.SetBlend(1)
	end

	table.insert(self.Meshes, windMesh)
end 

function EFFECT:Think()
	local now = CurTime()
	local dT = FrameTime() * self.TimeDilation 
	-- Maintain parent alignment if owner is valid

	local owner = self:GetOwner()
	if IsValid(owner) then
		local parentAng = owner:GetAngles()
		local parentPos = owner:GetPos()
		self:SetAngles(parentAng)
		self:SetPos(parentPos)
	end

	-- Accumulate spawning timeline if the effect duration has not finished
	if now < self.DieTime then
		self.SpawnAccumulator = self.SpawnAccumulator + (dT * self.TargetSpawnRate)
		while self.SpawnAccumulator >= 1 do
			self:SpawnWindMesh()
			self.SpawnAccumulator = self.SpawnAccumulator - 1
		end
	end

	-- Tick physics, lifetimes and geometry updates on all alive active models
	for i = #self.Meshes, 1, -1 do
		local mesh = self.Meshes[i]
		
		if not IsValid(mesh.Model) then
			table.remove(self.Meshes, i)
			continue
		end
		
		local ageFraction = (now - mesh.SpawnTime) / mesh.Lifetime
		
		-- Remove model immediately if it has crossed its lifecycle threshold
		if ageFraction >= 1.0 then
			mesh.Model:Remove()
			table.remove(self.Meshes, i)
			continue
		end
		
		-- Applying movement, vortex forces, and rotation... 
		
		-- Update position along forward trajectory
		local currentPos = mesh.Model:GetPos()
		local moveStep = mesh.Velocity * dT
		
		-- Apply the Vortex Velocity function: spiraling inward/outward relative to local forward axis
		local currentAng = mesh.Model:GetAngles()
		local vortexAxis = currentAng:Forward()
		local vortexRadial = currentAng:Right() * math.sin(now * 12 + mesh.RandomSeed) * 80 * mesh.VortexMult
		
		-- Apply combined linear velocity with rotational turbulence
		mesh.Model:SetPos(currentPos + moveStep + (vortexRadial * dT))
		
		-- Update axial spinning
		local newAng = mesh.Model:GetAngles()
		newAng.y = newAng.y + (mesh.VortexSpin * dT) -- Apply spin exclusively to Yaw
		newAng.p = 0                                 -- Lock pitch
		newAng.r = 0                                 -- Lock roll
		mesh.Model:SetAngles(newAng)
		
		-- STREAMING_CHUNK:Constructing matrices for individual mesh scales... 
		
		-- Scale transformations derived from SBScaleMeshSize module logic
		local scaleX = Lerp(ageFraction, 2.7, 3.5) * self:GetModelScale()  -- Swift, dramatic forward stretching
		local scaleY = Lerp(ageFraction, 2.6, 3.4) * self:GetModelScale()  -- Gradual sideways thinning
		local scaleZ = Lerp(ageFraction, 2, 0.0) * self:GetModelScale()  -- Height compression (Evaporation mimic)
		
		local scaleVec = Vector(scaleX, scaleY, scaleZ)
		
		-- Apply matrices directly to the clientside entity rendering properties
		local mat = Matrix()
		mat:Scale(scaleVec)
		mesh.Model:EnableMatrix("RenderMultiply", mat)
	end

	-- Terminate custom EFFECT entity once all meshes have completely faded and cleared
	if now >= self.DieTime and #self.Meshes == 0 then
		return false -- Signals GMod to garbage collect the main effect entity
	end

	return true -- Keep Think active
end -- Structuring safety cleanups and effect termination... 

-- Handle unexpected removal/cleanup to avoid persistent client leaks in memory
function EFFECT:OnRemove()
	if self.Meshes then
		for _, mesh in ipairs(self.Meshes) do
			if IsValid(mesh.Model) then 
				mesh.Model:Remove() 
			end 
		end 
		self.Meshes = nil 
	end 
end 


function EFFECT:Render() end -- Render function is unused as the clientside models render themselves in DrawModel overrides