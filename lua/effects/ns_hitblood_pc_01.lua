-- lua/effects/stellar_blood_impact.lua

EFFECT.Mat = Material("effects/blood_drop") -- used by Gemini 

-- below created by Microsoft Copilot 
EFFECT.MistCount     = 1   -- NE_BloodM002 equivalent
EFFECT.DropletCount  = 1   -- NE_BloodM equivalent
EFFECT.CollisionCount= 1   -- NE_CollisionBloodParticlesM equivalent

local FX_BLOODSPRAY_DROPS = 1
local FX_BLOODSPRAY_GORE  = 2
local FX_BLOODSPRAY_CLOUD = 4
local FX_BLOODSPRAY_ALL   = 255

function EFFECT:Init( data )
	local ent = data:GetEntity()
	if !IsValid(ent) then return end
	local bloodColor = ent.GetBloodColor and ent:GetBloodColor() or BLOOD_COLOR_RED 
	if bloodColor == -1 then return end 	-- DONT_BLEED (-1) check 
	local scale = data:GetScale()
	if scale <= 0 then scale = 1.0 end
	scale = scale * 0.4 
	if math.random() > 0.5 then 
		local origin   = data:GetOrigin()
		local normal   = VectorRand()
		local ent      = data:GetEntity()
		local angles   = data:GetAngles()
		local relPos   = data:GetStart()

		-- Mist spray (fast dissipating cloud)
		for i=1,self.MistCount do
			local ed = EffectData()
			ed:SetOrigin(origin + normal * 2)
			ed:SetNormal(normal)
			ed:SetScale(scale * 0.6) -- smaller, faster
			ed:SetFlags(FX_BLOODSPRAY_CLOUD)
			ed:SetColor(bloodColor)
			util.Effect("bloodspray", ed, true, true)
		end

		-- Heavy droplets (chunky arcs)
		for i=1,self.DropletCount do
			local ed = EffectData()
			ed:SetOrigin(origin + normal * 4)
			ed:SetNormal(normal)
			ed:SetScale(scale * 1.2) -- larger blobs
			ed:SetFlags(FX_BLOODSPRAY_DROPS)
			ed:SetColor(bloodColor)
			util.Effect("bloodspray", ed, true, true)
		end

		-- Collision streaks (impact splatter)
		for i=1,self.CollisionCount do
			local ed = EffectData()
			ed:SetOrigin(origin)
			ed:SetNormal(normal)
			ed:SetScale(scale)
			ed:SetColor(bloodColor)
			util.Effect("bloodimpact", ed, true, true)
		end
	else 
		-- 1. Fetch base effect data

		-- Niagara Properties provided via EffectData
		local localPos = data:GetStart()    -- Expected to be Vector(0, 0, 10)
		local localAng = data:GetAngles()   -- Expected to be Angle(0, -90, 90) (Pitch, Yaw, Roll)
		local boneID = data:GetHitBox()     -- Expected to be the Bone ID for "FX_CenterofMass"

		-- 2. Calculate actual World Position and Angles from the Bone
		local bonePos, boneAng
		if boneID and boneID >= 0 then
			bonePos, boneAng = ent:GetBonePosition(boneID)
		end
		
		-- Fallback to entity origin if the bone doesn't exist
		if not bonePos then
			bonePos = ent:GetPos()
			boneAng = ent:GetAngles()
		end

		-- Translate the Niagara RelativeLocation and RelativeRotation into World Space
		local worldPos, worldAng = LocalToWorld(localPos, localAng, bonePos, boneAng)
		local emitNormal = worldAng:Forward()

		-- 3. Emulate NE_BloodM & NE_CollisionBloodParticlesM (The Volumetric Cloud & Drops)
		-- As seen in the C++, Flags dictate the output: 1 (Drops) + 2 (Gore) + 4 (Cloud) = 7
		local sprayData = EffectData()
		sprayData:SetOrigin( worldPos )
		sprayData:SetNormal( emitNormal )
		-- The Niagara script scaled particles up to 3.0 over time. 
		-- We multiply the base scale by 3 to simulate that volumetric expansion.
		sprayData:SetScale( scale * 3.0 ) 
		sprayData:SetFlags( 7 ) -- FX_BLOODSPRAY_DROPS | FX_BLOODSPRAY_GORE | FX_BLOODSPRAY_CLOUD
		sprayData:SetColor( bloodColor )
		
		util.Effect( "bloodspray", sprayData )

		-- 4. Emulate NE_BloodM002 (The Instantaneous Gore Burst / Splash)
		-- bloodimpact closely mimics the initial heavy frame burst seen in the Niagara spawn burst
		local impactData = EffectData()
		impactData:SetOrigin( worldPos )
		impactData:SetNormal( emitNormal )
		impactData:SetScale( scale * 1.5 ) -- Slightly smaller core impact
		impactData:SetColor( bloodColor )
		
		util.Effect( "bloodimpact", impactData )
	end 
end

function EFFECT:Think()
    -- Sub-effects handle their own lifetimes and physics (gravity, collision)
    return false 
end

function EFFECT:Render()
    -- We don't need to render anything natively on this parent effect
end