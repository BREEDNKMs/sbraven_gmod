-- Helper: Get the animation info table for a sequence
local function GetAnimInfoForSequence(ent, seq)
    if not IsValid(ent) then return nil end

    local seqname = ent:GetSequenceName(seq)
    if not seqname or seqname == "Unknown" then return nil end

    for i = 0, ent:GetAnimCount() - 1 do
        local info = ent:GetAnimInfo(i)
        if info and info.label then
            if string.find(info.label, "@" .. seqname, 1, true) or
               string.find(info.label, "a_" .. seqname, 1, true) or
               string.find(info.label, seqname, 1, true) then
                return info
            end
        end
    end

    return nil
end

-- Main: Get current frame in the sequence
local function GetEntityFrame(ent,seq,cycle)
    if !IsValid(ent) then return error("Tried to use a NULL Entity!") end

    seq = seq or ent:GetSequence()
    local animInfo = GetAnimInfoForSequence(ent, seq)
    if not animInfo or not animInfo.numframes then return 0 end

    local totalFrames = animInfo.numframes
    cycle = cycle or ent:GetCycle()
	if !cycle then cycle = 0 end 

    -- Convert cycle [0,1] into frame index
    local frame = math.floor(cycle * totalFrames + 0.5)
    return math.Clamp(frame, 0, totalFrames - 1)
end

local meta = FindMetaTable("Entity") 
if meta then 
	function meta:GetFrame(seq,cycle) 
		return GetEntityFrame(self,seq,cycle) 
	end 
end 