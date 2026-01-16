-- call with ent = your ClientsideModel or entity
local function PrintModelSizes(ent, appliedScaleVec)
    if not IsValid(ent) then return end
	print("Assessing ent matrix scale:",ent," at time:",CurTime()) 
    local mins, maxs = ent:OBBMins(), ent:OBBMaxs() -- bounding box in model space
    local nativeSize = maxs - mins -- vector
    local worldSize = Vector(nativeSize.x * appliedScaleVec.x,
						     nativeSize.y * appliedScaleVec.y,
						     nativeSize.z * appliedScaleVec.z)

    print("Native OBB size (model units):", nativeSize)
    print("Applied scale:", appliedScaleVec)
    print("Resulting world size (same units as model):", worldSize)
    -- Convert to Hammer Units (inches) if model units are meters/centimeters etc:
    -- Example: if nativeSize was in cm and you want Hammer Units (inches):
    local worldSizeInches = worldSize / 2.54 -- if worldSize is in cm
    print("World size (approx inches/Hammer units if model units are cm):", worldSizeInches)
end

-- Example: attach this where you create `p = emitter:Add(...)`
-- Replace `ShaderLUT` with the flat array you extracted from the JSON.
-- You can paste the full ShaderLUT (the huge float list) here or load it from a file.

-- ===== Helper functions =====
local function BuildColorLUTFromShaderLUT(shaderLUT)
    -- shaderLUT: flat array of numbers (R,G,B,A,R,G,B,A,...)
    local lut = {}
    if not shaderLUT or #shaderLUT == 0 then return lut end

    -- assume 4 values per sample; if length not multiple of 4 try to bail gracefully
    local n = #shaderLUT
    local perSample = 4
    if (n % perSample) ~= 0 then
		-- try to fall back: if only RGB stored, treat as RGB with alpha=1
		if (n % 3) == 0 then perSample = 3 end
    end

    local samples = math.floor(n / perSample)
    -- detect whether values are in 0..1 or 0..255 (peak)
    local maxv = 0
    for i = 1, math.min(n, 32) do
		if math.abs(shaderLUT[i]) > maxv then maxv = math.abs(shaderLUT[i]) end
    end
    local uses255 = maxv > 2.0 -- heuristic: values >2 imply 0..255 range

    local idx = 1
    for s = 1, samples do
		local r = shaderLUT[idx] or 0; local g = shaderLUT[idx+1] or 0; local b = shaderLUT[idx+2] or 0
		local a = (perSample == 4) and (shaderLUT[idx+3] or 1) or 1
		idx = idx + perSample
		if uses255 then
		    -- clamp just in case
		    r = math.Clamp(r, 0, 255); g = math.Clamp(g, 0, 255); b = math.Clamp(b, 0, 255)
		    a = math.Clamp(a, 0, 255)
		else
		    -- convert 0..1 -> 0..255
		    r = math.Clamp(r * 255, 0, 255); g = math.Clamp(g * 255, 0, 255); b = math.Clamp(b * 255, 0, 255)
		    a = math.Clamp(a * 255, 0, 255)
		end
		lut[s] = { r = r, g = g, b = b, a = a }
    end

    return lut
end

local function Lerp(a,b,t)
    return a + (b - a) * t
end

local function SampleColorLUT(lut, t) -- t in [0,1]
    if not lut or #lut == 0 then return 255,255,255,255 end
    t = math.Clamp(t, 0, 1)
    local n = #lut
    if n == 1 then
		local s = lut[1]; return s.r, s.g, s.b, s.a
    end
    local fIndex = t * (n - 1)
    local i = math.floor(fIndex) + 1		      -- Lua indices
    local frac = fIndex - (i - 1)
    if i >= n then
		local s = lut[n]; return s.r, s.g, s.b, s.a
    end
    local s0 = lut[i]; local s1 = lut[i + 1]
    local r = Lerp(s0.r, s1.r, frac)
    local g = Lerp(s0.g, s1.g, frac)
    local b = Lerp(s0.b, s1.b, frac)
    local a = Lerp(s0.a, s1.a, frac)
    return math.floor(r+0.5), math.floor(g+0.5), math.floor(b+0.5), math.floor(a+0.5)
end

-- ===== Example: small sample taken from your JSON (you should paste the complete shader LUT here) =====
-- (the JSON's color curve ShaderLUT block is long; example snippet is shown in the file.)
-- See JSON color LUT excerpt: :contentReference[oaicite:5]{index=5}

local exampleShaderLUT = {
		9.0,
		10.499991,
		15.0,
		0.0,
		8.985679,
		10.4829855,
		14.974938,
		0.0,
		8.943673,
		10.433104,
		14.901427,
		0.0,
		8.875416,
		10.352048,
		14.781978,
		0.0,
		8.782342,
		10.241523,
		14.619099,
		0.0,
		8.665887,
		10.103232,
		14.415302,
		0.0,
		8.527484,
		9.938879,
		14.173097,
		0.0,
		8.368567,
		9.750166,
		13.894994,
		0.0,
		8.190573,
		9.538798,
		13.583503,
		0.0,
		7.994935,
		9.306478,
		13.241136,
		0.0,
		7.783087,
		9.054908,
		12.870401,
		0.0,
		7.5564637,
		8.785793,
		12.473811,
		0.0,
		7.3164997,
		8.500836,
		12.053875,
		0.0,
		7.0646296,
		8.201741,
		11.613102,
		0.0,
		6.802288,
		7.89021,
		11.154003,
		0.0,
		6.5309095,
		7.5679493,
		10.679091,
		0.0,
		6.2519274,
		7.236658,
		10.190873,
		0.0,
		5.966778,
		6.8980427,
		9.69186,
		0.0,
		5.676894,
		6.553807,
		9.184565,
		0.0,
		5.383711,
		6.205652,
		8.6714945,
		0.0,
		5.088663,
		5.8552837,
		8.155161,
		0.0,
		4.7931857,
		5.504404,
		7.638075,
		0.0,
		4.498712,
		5.1547165,
		7.1227455,
		0.0,
		4.2066765,
		4.8079247,
		6.611684,
		0.0,
		3.9185143,
		4.4657326,
		6.1074,
		0.0,
		3.6356597,
		4.1298428,
		5.612404,
		0.0,
		3.3595467,
		3.8019595,
		5.1292067,
		0.0,
		3.0916104,
		3.4837852,
		4.6603184,
		0.0,
		2.8332853,
		3.1770244,
		4.208249,
		0.0,
		2.5860052,
		2.88338,
		3.7755098,
		0.0,
		2.3512063,
		2.6045556,
		3.3646107,
		0.0,
		2.1303205,
		2.3422546,
		2.9780607,
		0.0,
		1.9247842,
		2.0981798,
		2.618372,
		0.0,
		1.736031,
		1.8740368,
		2.2880554,
		0.0,
		1.565496,
		1.671525,
		1.9896173,
		0.0,
		1.4146128,
		1.4923534,
		1.7255735,
		0.0,
		1.2848163,
		1.3382196,
		1.4984293,
		0.0,
		1.1775417,
		1.2108307,
		1.3106985,
		0.0,
		1.0942225,
		1.1118898,
		1.1648893,
		0.0,
		1.0362935,
		1.0430994,
		1.0635147,
		0.0,
		1.0051894,
		1.0061626,
		1.0090818,
		0.0,
		0.9962827,
		0.99930966,
		1.0,
		0.0,
		0.9869895,
		0.99758375,
		1.0,
		0.0,
		0.97769624,
		0.99585783,
		1.0,
		0.0,
		0.968403,
		0.994132,
		1.0,
		0.0,
		0.9591098,
		0.9924061,
		1.0,
		0.0,
		0.9498165,
		0.9906802,
		1.0,
		0.0,
		0.94052327,
		0.9889543,
		1.0,
		0.0,
		0.93123007,
		0.98722845,
		1.0,
		0.0,
		0.9219368,
		0.98550254,
		1.0,
		0.0,
		0.91264355,
		0.9837766,
		1.0,
		0.0,
		0.90335035,
		0.9820508,
		1.0,
		0.0,
		0.8940571,
		0.98032486,
		1.0,
		0.0,
		0.8847639,
		0.97859895,
		1.0,
		0.0,
		0.87547064,
		0.9768731,
		1.0,
		0.0,
		0.8661774,
		0.9751472,
		1.0,
		0.0,
		0.8568842,
		0.97342134,
		1.0,
		0.0,
		0.8475909,
		0.9716954,
		1.0,
		0.0,
		0.83829767,
		0.9699695,
		1.0,
		0.0,
		0.82900447,
		0.96824366,
		1.0,
		0.0,
		0.8197112,
		0.96651775,
		1.0,
		0.0,
		0.810418,
		0.9647919,
		1.0,
		0.0,
		0.8011247,
		0.963066,
		1.0,
		0.0,
		0.7918315,
		0.96134007,
		1.0,
		0.0,
		0.7825383,
		0.9596142,
		1.0,
		0.0,
		0.77324504,
		0.9578883,
		1.0,
		0.0,
		0.7639518,
		0.95616245,
		1.0,
		0.0,
		0.7546585,
		0.95443654,
		1.0,
		0.0,
		0.74536526,
		0.9527106,
		1.0,
		0.0,
		0.73607206,
		0.9509848,
		1.0,
		0.0,
		0.72677886,
		0.94925886,
		1.0,
		0.0,
		0.71748567,
		0.947533,
		1.0,
		0.0,
		0.7081924,
		0.9458071,
		1.0,
		0.0,
		0.69889915,
		0.9440812,
		1.0,
		0.0,
		0.6896059,
		0.9423553,
		1.0,
		0.0,
		0.68031263,
		0.9406294,
		1.0,
		0.0,
		0.67101943,
		0.9389035,
		1.0,
		0.0,
		0.66172624,
		0.93717766,
		1.0,
		0.0,
		0.652433,
		0.93545175,
		1.0,
		0.0,
		0.6431397,
		0.93372583,
		1.0,
		0.0,
		0.63384646,
		0.932,
		1.0,
		0.0,
		0.6245532,
		0.93027407,
		1.0,
		0.0,
		0.61526,
		0.9285482,
		1.0,
		0.0,
		0.6059668,
		0.9268223,
		1.0,
		0.0,
		0.59667355,
		0.9250964,
		1.0,
		0.0,
		0.5873803,
		0.92337054,
		1.0,
		0.0,
		0.57808703,
		0.9216446,
		1.0,
		0.0,
		0.56879383,
		0.9199188,
		1.0,
		0.0,
		0.5595006,
		0.91819286,
		1.0,
		0.0,
		0.5502074,
		0.91646695,
		1.0,
		0.0,
		0.5409142,
		0.9147411,
		1.0,
		0.0,
		0.53162086,
		0.9130152,
		1.0,
		0.0,
		0.52232766,
		0.91128933,
		1.0,
		0.0,
		0.5130344,
		0.9095634,
		1.0,
		0.0,
		0.5037412,
		0.9078375,
		1.0,
		0.0,
		0.49444795,
		0.90611166,
		1.0,
		0.0,
		0.48515475,
		0.90438575,
		1.0,
		0.0,
		0.47586143,
		0.90265983,
		1.0,
		0.0,
		0.46656823,
		0.900934,
		1.0,
		0.0,
		0.45727503,
		0.89920807,
		1.0,
		0.0,
		0.44798172,
		0.8974822,
		1.0,
		0.0,
		0.43868858,
		0.8957563,
		1.0,
		0.0,
		0.42939526,
		0.8940304,
		1.0,
		0.0,
		0.420102,
		0.89230454,
		1.0,
		0.0,
		0.41080886,
		0.8905786,
		1.0,
		0.0,
		0.40151554,
		0.8888527,
		1.0,
		0.0,
		0.39222234,
		0.88712686,
		1.0,
		0.0,
		0.3829291,
		0.88540095,
		1.0,
		0.0,
		0.37363583,
		0.8836751,
		1.0,
		0.0,
		0.36434263,
		0.8819492,
		1.0,
		0.0,
		0.3550493,
		0.8802233,
		1.0,
		0.0,
		0.34575623,
		0.8784974,
		1.0,
		0.0,
		0.33646291,
		0.8767715,
		1.0,
		0.0,
		0.32716972,
		0.87504566,
		1.0,
		0.0,
		0.31787646,
		0.87331975,
		1.0,
		0.0,
		0.3085832,
		0.87159383,
		1.0,
		0.0,
		0.29929,
		0.869868,
		1.0,
		0.0
}

local NiagaraDataInterfaceColorCurve_0 = {
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        0.9982762,
        0.9987933,
        1.0,
        1.0,
        0.99164724,
        0.9941531,
        1.0,
        1.0,
        0.9803357,
        0.98623496,
        1.0,
        1.0,
        0.96465164,
        0.97525615,
        1.0,
        1.0,
        0.94490564,
        0.96143395,
        1.0,
        1.0,
        0.92140764,
        0.94498533,
        1.0,
        1.0,
        0.8944682,
        0.92612773,
        1.0,
        1.0,
        0.8643976,
        0.90507835,
        1.0,
        1.0,
        0.8315059,
        0.8820541,
        1.0,
        1.0,
        0.79610366,
        0.85727257,
        1.0,
        1.0,
        0.7585008,
        0.83095056,
        1.0,
        1.0,
        0.7190082,
        0.80330575,
        1.0,
        1.0,
        0.6779354,
        0.77455485,
        1.0,
        1.0,
        0.6355935,
        0.7449154,
        1.0,
        1.0,
        0.59229225,
        0.7146046,
        1.0,
        1.0,
        0.5483419,
        0.6838393,
        1.0,
        1.0,
        0.50405294,
        0.65283704,
        1.0,
        1.0,
        0.45973557,
        0.6218149,
        1.0,
        1.0,
        0.41570038,
        0.5909903,
        1.0,
        1.0,
        0.3722571,
        0.56058,
        1.0,
        1.0,
        0.32971668,
        0.5308018,
        1.0,
        1.0,
        0.2883891,
        0.5018724,
        1.0,
        1.0,
        0.24858427,
        0.47400898,
        1.0,
        1.0,
        0.21061307,
        0.44742918,
        1.0,
        1.0,
        0.1747855,
        0.4223498,
        1.0,
        1.0,
        0.14141184,
        0.3989883,
        1.0,
        1.0,
        0.11080241,
        0.3775617,
        1.0,
        1.0,
        0.08326757,
        0.35828733,
        1.0,
        1.0,
        0.059117436,
        0.34138227,
        1.0,
        1.0,
        0.038662672,
        0.32706386,
        1.0,
        1.0,
        0.02221322,
        0.31554925,
        1.0,
        1.0,
        0.010079384,
        0.3070556,
        1.0,
        1.0,
        0.0025715828,
        0.30180007,
        1.0,
        1.0,
        0.0,
        0.3,
        1.0,
        1.0
} 

local colorLUT = BuildColorLUTFromShaderLUT(exampleShaderLUT)
local NiagaraDataInterfaceColorCurve_0 = BuildColorLUTFromShaderLUT(NiagaraDataInterfaceColorCurve_0)

-- ===== Spawn particle + attach ThinkFunction =====
-- This code assumes you already created 'p' via emitter:Add and set p:SetDieTime(die)
-- You must compute 'birthTime' and 'dieTime' (seconds) when you set the particle up.

-- Example wrapper that you call after creating p:
local function AttachColorCurveThink(p, birthTime, dieTime, colorLUT, isnormalized)
    -- dieTime = absolute die time (CurTime() + lifetime) OR pass lifetime and compute inside
    local lifetime = math.max(0.0001, dieTime - birthTime)

    -- schedule first think immediately
    if p.SetNextThink then p:SetNextThink(CurTime()) end

    -- attach the per-particle think function
    p:SetThinkFunction(function(part, dt)
		local now = CurTime()
		local age = now - birthTime
		if age >= lifetime then
		    -- particle should be dead; no more updates
		    return
		end

		local normalizedAge = age / lifetime -- 0..1
		local r,g,b,a = SampleColorLUT(colorLUT, normalizedAge)
		if isnormalized then 
			r = r 
			g = g 
			b = b 
			a = 255 -- somehow always 0 
		else 
			r = r * 255 
			g = g * 255 
			b = b * 255 
			a = 255 -- somehow always 0 
		end 

		-- apply color and alpha each frame
		-- SetColor usually takes 3 args (r,g,b)
		if part.SetColor then part:SetColor(r, g, b) end

		-- Alpha: try SetStartAlpha()/SetEndAlpha() if runtime alpha update is not supported.
		-- Many particles respect SetStartAlpha/SetEndAlpha only at spawn; some Lua builds allow updating alpha directly.
		if part.SetAlpha then
		    -- if engine exposes SetAlpha: use it
		    -- part:SetAlpha(a)
		else
		    -- fall back: try updating start/end alpha (works on many GMod builds)
		    -- if part.SetStartAlpha then part:SetStartAlpha(a) end
		    -- if part.SetEndAlpha then part:SetEndAlpha(a) end
		end

		-- schedule next think (try to run every frame)
		if part.SetNextThink then
		    part:SetNextThink(CurTime() + FrameTime())
		end
		-- print(r,g,b,a) 
    end)
end

-- Usage after you spawn a particle 'p' (example):
-- local birth = CurTime()
-- local lifetimeSeconds = 1.5 -- whatever you set with p:SetDieTime(...)
-- p:SetDieTime(lifetimeSeconds)
-- AttachColorCurveThink(p, birth, birth + lifetimeSeconds, colorLUT)

function EFFECT:Init(data)
    -- Get position and angles from the effect data
    local pos = data:GetOrigin() 
    local ang = data:GetAngles() 
	local localOffset = data:GetStart() 
	local ent = data:GetEntity() 
	local boneID = data:GetHitBox() 
	print("pos",pos,"ang:",ang,"localOffset:",localOffset,"ent:",ent,"boneID:",boneID) 
    self:SetPos(pos)
	-- data:SetAngles(Angle(data:GetAngles().y,data:GetAngles().p,data:GetAngles().z)) 
    self:SetAngles(ang)

    -- Get scale and lifetime multipliers, with default values of 1
    self.Scale = data:GetScale() ~= 0 and data:GetScale() or 1
	self.Scale = self.Scale * 0.1 
	
    local lifetimeMultiplier = data:GetMagnitude() ~= 0 and data:GetMagnitude() or 1

    -- Set the model for the shockwave
    self:SetModel("models/stellarblade/SM_A_shockWv_01.mdl")

    -- Set render properties for a bright, additive effect
    self:SetRenderMode(1)
	if IsValid(ent) then
        if boneID and boneID > 0 then
            -- 1. Parent to the specific Bone/Attachment ID as requested
			print("boneid is:",boneID) 
            self:SetParent(ent, boneID)
            
            -- 2. Apply Local Positioning
            -- Since we are now parented to the bone, '0,0,0' is the center of that bone.
            -- We use localOffset (RelativeLocation) to maintain the offset defined in JSON.
            if localOffset and localOffset ~= Vector(0,0,0) then
                self:SetLocalPos(localOffset)
            else
                self:SetLocalPos(Vector(0,0,0))
            end
            
            -- 3. Align Rotation
            -- SetLocalAngles(Angle(0,0,0)) aligns the effect exactly with the bone's rotation.
            -- If you passed RelativeRotation, you would apply it here.
            self:SetLocalAngles(Angle(0,0,0))
            
        else
            -- Fallback: Parent to entity root if no specific bone was found
            self:SetParent(ent)
            self:SetPos(pos)
            self:SetAngles(ang)
        end
    else
        -- No entity to parent to? Just spawn at the calculated world position.
        self:SetPos(pos)
        self:SetAngles(ang)
    end

    -- Initialize timing
    self.StartTime = CurTime()
    -- The original effect has a randomized lifetime between 0.25 and 0.5 seconds
    local randomLife = math.Rand(0.25, 0.5)
    self.LifeTime = randomLife * lifetimeMultiplier
    self.EndTime = self.StartTime + self.LifeTime

    -- The particle is invisible at spawn (Alpha = 0)
    self:SetColor(Color(255, 255, 255, 0))

    -- Initialize the scale matrix to prevent the model from appearing at full size for a frame
    local mat = Matrix()
    mat:Scale(Vector(0, 0, 0)) -- Start with zero scale
    self:EnableMatrix("RenderMultiply", mat)
	self.Hemisphere = self:InitHemisphere(data) 
	self:InitNE_SpriteM003_1(data) 
	self:InitNE_SpriteM004_3(data) 
end 

function EFFECT:InitHemisphere(data) 
	local pos = data:GetOrigin()
    local ang = data:GetAngles()
    local localOffset = data:GetStart() 
	local ent = data:GetEntity() 
	local boneID = data:GetHitBox() 
    local count = math.random(1, 2) -- spawn 1-2 hemispheres (tweak to 1-3)
    local baseScale = (data:GetScale() ~= 0) and data:GetScale() or 1
	baseScale = baseScale * 0.1 
    local baseLife  = (data:GetMagnitude() ~= 0) and data:GetMagnitude() or 0.5

    self.Hemisphere = {}
    for i = 1, count do
		local hem = ClientsideModel("models/stellarblade/SM_B_HemiSphere_02.mdl", RENDERGROUP_BOTH)
		hem:SetPos(pos)
		hem:SetParent(ent,boneID) 
		hem:SetLocalPos(localOffset) 
		hem:SetAngles(ang + Angle(0, math.Rand(-15,15), 0)) -- small yaw variation
		hem.Scale = baseScale * Lerp(i/count, 0.9, 1.1)
		hem.LifeTime = baseLife * Lerp(i/count, 0.95, 1.05)
		hem.DieTime = CurTime() + hem.LifeTime
		hem.CurrentScale = 0.01

		-- cache a matrix to reduce allocations
		hem._scaleMat = Matrix()
		hem._scaleVec = Vector(0.01, 0.01, 0.01)

		-- optional: assign dynamic material instance (engine dependent)
		-- local mat = hem:GetMaterial(0) -- might be nil; requires engine API
		-- if mat then hem:SetMaterial(CreateDynamicMaterial(mat)) end

		hem.RenderOverride = function(selfModel, flags)
			-- Choose preset: "faithful" (punchy) or "subtle" (gentle)
			local PRESET = "faithful" -- "subtle"

			-- lifetime calculation already in your code: lifeFrac = 1 - ((DieTime - CurTime()) / LifeTime)
			local lifeFrac = 1 - ((selfModel.DieTime - CurTime()) / selfModel.LifeTime)
			if lifeFrac >= 1 then SafeRemoveEntity(selfModel) return end
			lifeFrac = math.Clamp(lifeFrac, 0, 1)

			-- Preset tuning
			local baseScale = selfModel.Scale or 1
			local zFlat = 0.02 * baseScale -- keep hemisphere flat

			local peak, startSnap, settleMul
			if PRESET == "faithful" then
				startSnap = 0.18         -- fraction of base at very first snap
				peak = 1.4 * baseScale   -- main visible peak
				settleMul = 0.85         -- settle to 85% of peak
			else -- subtle
				startSnap = 0.12
				peak = 0.95 * baseScale
				settleMul = 1.05
			end

			-- SCALE (XY)
			local scaleXY
			if lifeFrac < 0.08 then
				local t = lifeFrac / 0.08
				scaleXY = Lerp(0, startSnap * baseScale, math.ease.OutQuad(t))
			elseif lifeFrac < 0.30 then
				local t = (lifeFrac - 0.08) / (0.30 - 0.08)
				scaleXY = Lerp(startSnap * baseScale, peak, math.ease.OutQuad(t))
			elseif lifeFrac < 0.55 then
				local t = (lifeFrac - 0.30) / (0.55 - 0.30)
				-- ease to settle
				scaleXY = Lerp(peak, peak * settleMul, math.ease.OutQuad(t))
			else
				local t = (lifeFrac - 0.55) / (1.0 - 0.55)
				-- optional slight final expansion or hold
				scaleXY = Lerp(peak * settleMul, peak * (1.0 + 0.05 * (PRESET=="faithful" and 1 or 0)), t)
			end

			-- Apply scale matrix (X,Y uniform; Z flattened)
			local mat = Matrix()
			mat:Scale(Vector(scaleXY, scaleXY, zFlat))
			selfModel:EnableMatrix("RenderMultiply", mat)

			-- ALPHA
			local alphaByte
			if lifeFrac < 0.04 then
				alphaByte = math.floor(255 * Lerp(0, 1, lifeFrac / 0.04))
			elseif lifeFrac < 0.30 then
				alphaByte = 255
			elseif lifeFrac < 0.60 then
				alphaByte = math.floor(255 * Lerp(1, 0.3, (lifeFrac - 0.30) / 0.30))
			else
				alphaByte = math.floor(255 * Lerp(0.3, 0, (lifeFrac - 0.60) / 0.40))
			end
			alphaByte = math.Clamp(alphaByte, 0, 255)

			-- COLOR & BRIGHTNESS
			local baseR, baseG, baseB = 255, 255, 255 -- JSON initial color = white
			-- slight tint toward pale blue as it fades
			local tintR = Lerp(baseR, 160, lifeFrac) -- 255 -> 160 across life
			local tintG = Lerp(baseG, 180, lifeFrac)
			local tintB = Lerp(baseB, 220, lifeFrac)

			-- brightness multiplier (emissive) approximation
			local brightness
			if lifeFrac < 0.30 then
				brightness = Lerp(3.0, 1.0, lifeFrac / 0.30) -- early bright -> normal
			elseif lifeFrac < 0.60 then
				brightness = Lerp(1.0, 0.4, (lifeFrac - 0.30) / 0.30)
			else
				brightness = Lerp(0.4, 0.08, (lifeFrac - 0.60) / 0.40)
			end

			-- If you cannot set a material float parameter, approximate brightness by multiplying color:
			local rOut = math.floor(math.Clamp(tintR * brightness, 0, 255))
			local gOut = math.floor(math.Clamp(tintG * brightness, 0, 255))
			local bOut = math.floor(math.Clamp(tintB * brightness, 0, 255))

			selfModel:SetColor(Color(rOut, gOut, bOut, alphaByte))

			-- Optionally drive material param (if you have a dynamic material instance)
			-- Example pseudo: if you created dynMat earlier and it supports SetFloatParameter:
			-- if selfModel._dynMat and selfModel._dynMat.SetFloatParameter then
			--     selfModel._dynMat:SetFloatParameter("Brightness", brightness)
			-- end

			-- Draw model
			selfModel:DrawModel(flags)
		end
		table.insert(self.Hemisphere, hem)
    end
end 

function EFFECT:Think()
    -- If the effect's lifetime has expired, remove it
    if CurTime() > self.EndTime then
		if IsValid(self.Hemisphere) then SafeRemoveEntity(self.Hemisphere) end 
		return false
    end

    -- Calculate the normalized age of the particle (0.0 to 1.0)
    local lifeFrac = (CurTime() - self.StartTime) / self.LifeTime
    lifeFrac = math.Clamp(lifeFrac, 0, 1) 
	
	local alphaByte
	if lifeFrac < 0.05 then
		alphaByte = math.floor(255 * Lerp(0, 1, lifeFrac / 0.05))               -- 0→1 in 5%
	elseif lifeFrac < 0.25 then
		alphaByte = 255                                                   -- hold full brightness
	elseif lifeFrac < 0.50 then
		local localT = (lifeFrac - 0.25) / (0.25)                                -- 0..1 across 0.25..0.50
		alphaByte = math.floor(255 * Lerp(1, 0.3, localT))                -- fade 1.0 → 0.3
	else
		local localT = (lifeFrac - 0.5) / 0.5
		alphaByte = math.floor(255 * Lerp(0.3, 0, localT))                -- fade remaining to 0
	end

    self:SetColor(Color(255, 255, 255, alphaByte)) 

	-- ## Scale Curve ##
    -- This curve replicates the Niagara "ScaleMeshSize" module's vector curve.
    -- X and Y scale uniformly from 0.0 to 1.0 over the lifetime.
    -- Z remains constant at 1.0.
    local scaleXY = lifeFrac
	
	local peak = 1.25 * self.Scale
	local baseline = 0.0 -- start from zero so model doesn't pop

	if lifeFrac < 0.06 then
		-- I0: initial pop to ~40% of peak
		local localT = lifeFrac / 0.06
		scaleXY = Lerp(baseline, peak * 0.4, math.ease.OutQuad(localT))
	elseif lifeFrac < 0.25 then
		-- I1: explosive growth to peak
		local localT = (lifeFrac - 0.06) / (0.25 - 0.06)
		scaleXY = Lerp(peak * 0.4, peak, math.ease.OutQuad(localT))
	elseif lifeFrac < 0.50 then
		-- I2: quick settle / shrink a bit from peak to settle value
		local localT = (lifeFrac - 0.25) / (0.50 - 0.25)
		scaleXY = Lerp(peak, peak * 0.85, 1 - localT) -- linear/soft settle (you can ease)
	else
		-- I3: gentle relax or tiny growth and then vanish with alpha
		local localT = (lifeFrac - 0.5) / 0.5
		scaleXY = Lerp(peak * 0.85, peak * 1.05, localT * 0.2) -- small final variation
	end
	
    -- local currentScale = Vector(scaleXY, scaleXY, 0.02 * self.Scale) * self.Scale

    -- Create a transformation matrix for scaling and apply it to the entity
    local mat = Matrix()
    mat:Scale(Vector(scaleXY, scaleXY, 0.02 * self.Scale))
	self:EnableMatrix("RenderMultiply", mat)
	-- print("scaleValue for ",self,":",currentScale,",Length():",currentScale:Length(),"lifeFrac:",lifeFrac,",at CurTime()",CurTime()) 
	-- PrintModelSizes(self,Vector(scaleValue, scaleValue, scaleValue)) 
    -- Keep the effect alive
    return true
end

function EFFECT:InitNE_SpriteM003_1(data) 
	print("InitNE_SpriteM003_1") 
	local MaterialFrames = {
    "sprites/MI_A_GPUSparks_01_Tr_000",
    "sprites/MI_A_GPUSparks_01_Tr_001",
    "sprites/MI_A_GPUSparks_01_Tr_002",
    "sprites/MI_A_GPUSparks_01_Tr_003"
	} 
	
	local pos = data:GetOrigin()
    local ang = data:GetAngles()
    local ent = data:GetEntity()
    -- self:SetPos(pos)
    -- self:SetAngles(ang)

    -- Scale and lifetime multipliers from effect data
    local Scale = data:GetScale() ~= 0 and data:GetScale() or 1
    local lifetimeMultiplier = data:GetMagnitude() ~= 0 and data:GetMagnitude() or 1 
	
	Scale = Scale * 0.42 

    -- Best-guess parameters taken from the Niagara script literal table
    local spawnCount = 25				      -- chosen from literal constants (10,25,30,60). 25 is a plausible spark burst.
    local baseLifetime = 1.5				   -- chosen from literal constants (1.5, 0.75, 0.35...). 1.5s gives visible fade and scale curves.
    local initialSpeed = 60				    -- literal 60.0 present in the table; used as base velocity magnitude.
    local coneAngle = 60				       -- degrees - spread of initial velocity (makes a burst).
    local startSize = 6 * Scale		   -- approximate start size (px units, adjust for your textures)
    local endSize = 2 * Scale		     -- approximate end size (shrinks toward death)
    local startAlpha = 255
    local endAlpha = 0
    local gravity = Vector(0, 0, -200)		 -- weak downward pull; adjust to taste
    local airResistance = 5				    -- slows particles over time

    -- Use ParticleEmitter to create particles and maintain them for lifetime
    local emitter = ParticleEmitter(pos)
    if not emitter then return end

    -- If the Niagara emitter was intended to be velocity aligned and use initial velocity
    -- we will sample directions within a cone aligned to the passed-in angles.
    local forward = ang:Forward()
    local right = ang:Right()
    local up = ang:Up()

    -- If we have an entity and it has velocity, pull that in as base (Niagara often uses emitter/owner velocity)
    local ownerVel = IsValid(ent) and ent:GetVelocity() or Vector(0,0,0)

    -- Shuffle the frames slightly per-particle for variety
    for i = 1, spawnCount do
		local matFrame = MaterialFrames[math.random(1, #MaterialFrames)]

		local p = emitter:Add(matFrame, pos)
		if not p then continue end

		-- Randomized direction within cone:
		-- pick a random unit vector within coneAngle degrees of forward
		local angleDeg = math.Rand(-coneAngle/2, coneAngle/2)
		local yaw = math.Rand(0, 360)
		local dir = (Angle(angleDeg, yaw, 0):Forward()):GetNormal()

		-- Mix with forward so it's roughly outward from the impact point
		dir = (forward + dir * 0.5):GetNormalized()

		-- initial speed with a little variance (Niagara often randomizes per particle)
		local speed = initialSpeed * math.Rand(0.7, 1.25) * Scale

		-- Set particle properties to match Niagara behaviour (velocity-aligned look, fade, scale over lifetime)
		p:SetVelocity(ownerVel + dir * speed)
		p:SetDieTime(baseLifetime * lifetimeMultiplier)
		p:SetStartAlpha(startAlpha)
		p:SetEndAlpha(endAlpha)

		-- Size over life: startSize → endSize (we approximate the float curves from the literal table)
		-- We'll also randomize using the MaterialRandomBinding concept
		local randScale = math.Rand(0.85, 1.15)
		p:SetStartSize(startSize * randScale)
		p:SetEndSize(endSize * randScale)

		-- Rotation jitter; Niagara used a SpriteRotationBinding
		p:SetRoll(math.Rand(0, 360))
		p:SetRollDelta(math.Rand(-360, 360) * 0.5)

		-- Color: the emitter uses a color curve (ColorBinding). We'll approximate with a warm spark color
		-- Start color near white/yellow, fade toward orange/transparent according to curve-like behaviour
		local r = math.Rand(220, 255)
		local g = math.Rand(160, 220)
		local b = math.Rand(40, 120)
		p:SetColor(r, g, b)

		-- Slight air resistance + gravity (gives nice arching motion)
		p:SetAirResistance(airResistance)
		p:SetGravity(gravity)

		-- Use collision and bounce lightly if you want sparks to hit world (optional)
		p:SetCollide(false) -- set to true if you want collision interactions
		AttachColorCurveThink(p,CurTime(), CurTime() + p:GetDieTime(), colorLUT, false) 
		-- p:SetBounce(0.3)

		-- Set a small lifetime-based custom parameter (if needed later) - this is just illustrative:
		-- p:SetBounce(0.2) etc.

		-- For GPU-like 'MaterialRandom' behaviour, set a user-defined parameter via velocity or roll if needed.
		-- (GMod particles don't have arbitrary user params; we emulate with roll/rolldelta or color variance.)
    end

    emitter:Finish()
end 

function EFFECT:InitNE_SpriteM004_3(data) 
	print("InitNE_SpriteM004_3") 
	local MaterialFrames = {
    "sprites/MI_A_GPUSparks_01_Tr_000",
    "sprites/MI_A_GPUSparks_01_Tr_001",
    "sprites/MI_A_GPUSparks_01_Tr_002",
    "sprites/MI_A_GPUSparks_01_Tr_003"
	} 
	
	local pos = data:GetOrigin()
    local ang = data:GetAngles()
    local ent = data:GetEntity()
    -- self:SetPos(pos)
    -- self:SetAngles(ang)

    -- Scale and lifetime multipliers from effect data
    local Scale = data:GetScale() ~= 0 and data:GetScale() or 1
    local lifetimeMultiplier = data:GetMagnitude() ~= 0 and data:GetMagnitude() or 1 
	
	Scale = Scale * 0.42 
	
	-- use the decoded values
	local L = {
		sizeMin = 0.30000001,
		sizeMax = 0.5,
		lifeMin = 0.69999999,
		lifeMax = 1.5,
		noiseAmp = 0.25924399,
		noiseFreq = 0.68092698,
		velMidZ = -100.0,
		rotationRange = 6.28318548,
		burstCount = 5,
		spreadAngleH = 30,
		spawnRadius = 40,
		spreadAngleV = 80,
		rollSpeedHint = 10
	}

	-- sensible GMod conversions
	local VEL_SCALE = 1   -- scale unreal velocity -> GMod
	local POS_SCALE = 1   -- scale spawnRadius down to gmod units
	local spawnCount = math.max(1, math.floor(L.burstCount)) -- integer

	-- color: Niagara default initial color in this system tends to be white (1,1,1,1)
	local startR, startG, startB = 255,255,255
	-- If we have an entity and it has velocity, pull that in as base (Niagara often uses emitter/owner velocity)
    local ownerVel = IsValid(ent) and ent:GetVelocity() or Vector(0,0,0)

	local emitter = ParticleEmitter(pos)
	for i=1, spawnCount do
		-- random offset on a circle (cylinder spawn)
		local angle = math.rad((math.random()-0.5) * L.spreadAngleH) + (2*math.pi)*(math.random())
		local radius = (math.random() ^ 0.6) * (L.spawnRadius * POS_SCALE)
		local offset = Vector(math.cos(angle) * radius, math.sin(angle) * radius, 0)

		-- pick lifetime and sizes directly from literals
		local life = L.lifeMin + math.random() * (L.lifeMax - L.lifeMin)
		local startSize = L.sizeMin + math.random() * (L.sizeMax - L.sizeMin)

		local matFrame = MaterialFrames[math.random(1, #MaterialFrames)]

		local p = emitter:Add(matFrame, pos)
		if (not p) then break end

		-- velocity: bias downward using velMidZ (scaled)
		local baseDown = Vector(0,0, L.velMidZ * VEL_SCALE)
		-- add a random cone velocity using spreadAngleV
		local spreadRads = math.rad(math.Rand(-L.spreadAngleV/2, L.spreadAngleV/2))
		local coneDir = Vector(
			math.sin(spreadRads) * (math.Rand(-1,1)),
			math.cos(spreadRads) * (math.Rand(-1,1)),
			math.cos(spreadRads)
		):GetNormalized() 

		local magnitude = math.Rand(50, 150) * VEL_SCALE -- adjustable base speed
		local vel = baseDown + coneDir * magnitude

		-- small curl/noise perturbation
		local noise = Vector(
		(math.Rand(-1,1) * L.noiseAmp),
		(math.Rand(-1,1) * L.noiseAmp),
		(math.Rand(-1,1) * L.noiseAmp * 0.25)
		)
		vel = vel + noise

		-- Particle properties
		p:SetVelocity(vel + ownerVel)
		p:SetDieTime(life)
		p:SetStartAlpha(255)
		p:SetEndAlpha(0)                 -- alpha fades out over lifetime (Niagara had an alpha fade)
		-- approximate Niagara scale/size curve by startSize -> endSize multiplier
		local endSize = startSize * (L.scaleB or 0.75) * 0.5  -- use scaleB as an end multiplier
		p:SetStartSize(startSize * 32)   -- sprite size: multiply to make pixels — tune as needed
		p:SetEndSize(endSize * 32)
		p:SetRoll(math.Rand(0, L.rotationRange))
		p:SetRollDelta(math.Rand(-L.rollSpeedHint, L.rollSpeedHint))
		p:SetAirResistance(5)
		p:SetGravity(Vector(0,0, -50))   -- small gravity; Niagara had negative Z bias
		p:SetColor(startR,startG,startB)

		-- optional: add a ThinkFunction to simulate the Niagara color/time curve if you want per-frame color changes
		-- but GMod particles do not normally expose per-particle Think in high performance usage.
		
		AttachColorCurveThink(p,CurTime(), CurTime() + p:GetDieTime(), NiagaraDataInterfaceColorCurve_0, true) 
	end

	emitter:Finish()

end 