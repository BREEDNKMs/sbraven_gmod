local jsonfile = "E:/Stellar Blade/Output/Exports/SB/Content/Art/Character/Monster/CH_M_NA_53/Animation/m_raven_slashchaincombo.json" 
local charsoundsetfile = "E:/Stellar Blade/Output/Exports/SB/Content/Sound/SoundAsset/CharacterSoundset/CSS_MON_53_Raven.json" 
local gamepath = "E:/Stellar Blade/Output/Exports/SB/Content" 

-- Utility: check if path is a directory
local function isdir(path)
    local attr = winfile.attributes(path)
    return attr and attr.mode == "directory"
end 

local sound = { } 
sound.ListOverrides = { } 
sound.Add = function(cue, tblsoundfiles) -- cue is the cue filename, tblsoundfiles is the sounds that exist 
	local tabletostring = '{'
	for i, v in ipairs(tblsoundfiles) do
		tabletostring = tabletostring .. '"' .. v .. '"'
		if i < #tblsoundfiles then
			tabletostring = tabletostring .. ','
		end
	end
	tabletostring = tabletostring .. '}'
	if printtabletostringsnow then 
		print("sound.Add( ") 
		print("{ ") 
		print('    name = "' .. cue .. '", ') 
		print("    channel = CHAN_BODY, ") 
		print("    volume = 1, ") 
		print("    soundlevel = 100, ") 
		print("    sound = " .. tabletostring) 
		print("}) ") 
	else 
		sound.ListOverrides[cue] = tabletostring 
	end 
end 

sound.PrintOverrides = function() 
	for k,v in pairs(sound.ListOverrides) do 
		print("sound.Add( ") 
		print("{ ") 
		print('    name = "' .. k .. '", ') 
		print("    channel = CHAN_BODY, ") 
		print("    volume = 1, ") 
		print("    soundlevel = 100, ") 
		print("    sound = " .. v) 
		print("}) ") 
	end 
end 

local ParseCue = function(dir) 
	dir = string.sub(dir,6) -- strip off /Game 
	dir = gamepath..dir -- join both 
	dir = dir..".json" -- append json 
	-- print(dir) 
	-- if there is a single SoundWaveAssetPtr[AssetPathName], create normal sound 
	-- if there are multiple, create soundscript 
	local parsingcue,soundstable = false, { } 
	for line in io.lines(dir) do -- find SoundWaveAssetPtr[AssetPathName] 
		if string.find(line,"SoundWaveAssetPtr") then 
			parsingcue = true 
		elseif string.find(line,"AssetPathName") and parsingcue then 
			local str = string.Explode('"',line) 
			for k,v in pairs(str) do 
				if string.find(v,"Game") then 
					local returnval = v 
					returnval = string.StripExtension(returnval) 
					returnval = string.sub(returnval,13) 
					returnval = returnval..".wav" 
					table.insert(soundstable,returnval) 
				end 
			end 
		end 
	end 
	return soundstable 
end 

-- Collect JSON files (single or multiple)
local jsonfiles = {}
if isdir(jsonfile) then
    for file in winfile.dir(jsonfile) do
        if file ~= "." and file ~= ".." and file:match("%.json$") then
            table.insert(jsonfiles, jsonfile .. "/" .. file)
        end
    end
else
    table.insert(jsonfiles, jsonfile)
end

for _, jsonpath in ipairs(jsonfiles) do
    print("Parsing:", jsonpath)
	local mylines = io.lines(jsonpath)

	local animnotify_cuefiles = { } 

	local animnotifyseconds = { } 
	local eventframes = { } 

	local animnotify_playsound = { } 
	local animnotify_charsound = { } 
	-- direct path to sound filename 
	-- frame: 8 (the frame this event plays) 
	local animnotify_footsteps = { } -- includes subtables of: 
	-- dir: left or right 
	-- frame: 8 (the frame this event plays) 

	local numframes, framerate, sequenceduration, curobject 

	local strSoundMode, lastSavedKey 
	-- local mylines = io.lines(jsonfile) 
	local i = 0 
	local targetstringline = 0 
	for k,v in mylines do 
		i = i + 1 
		local strings = string.Explode(" ",k) 
		for num,str in pairs(strings) do 
			-- if type has AnimNotify_PlaySound 
			-- store value of ObjectPath 
			-- explore around main cue 
			-- get sound paths 
			-- print(str) 
			if str == '"PlaySound",' then 
				-- PlaySound: find the AnimNotify_PlaySound_0 object from ObjectName field 
				strSoundMode = "PlaySound" -- find ObjectName and store in 
			elseif str == '"SBFootStep",' then 
				strSoundMode = "SBFootStep" -- then find ObjectName and store key in animnotify_footsteps 
			elseif str == '"SBCharSESound",' then -- mapped cue files in CSS_MON_53_Raven 
				strSoundMode = "SBCharSESound" -- then find ObjectName and store key in animnotify_footsteps 
			
			end 
			
			if str == '"LinkValue":' and strSoundMode then -- the second in which this event will be called. convert to frame. also clear out strSoundMode, this is last input we needed 
				local seconds = tonumber(string.sub(strings[num+1],1,-2)) 
				animnotifyseconds[curobject] = seconds 
				curobject = nil 
				strSoundMode = nil 
			end 
			
			if str == '"AnimNotify_PlaySound",' then -- second line has the object name, 8th has path 
				targetstringline = i + 1 
			elseif str == '"SBAnimNotify_FootStep",' then 
				targetstringline = i + 1 
			elseif str == '"SBAnimNotify_CharSESound",' then 
				targetstringline = i + 1 
			end 
			
			
			if str == '"ObjectName":' then -- next key 
				if strSoundMode == "SBFootStep" or strSoundMode == "PlaySound" or strSoundMode == "SBCharSESound" then 
					-- print(strings[num+1]) 
					local relevantObj = string.Explode(":",strings[num+1]) 
					if relevantObj[2] then 
						curobject = string.sub(relevantObj[2],1,-4) 
						-- print("curobject:", curobject) 
					end 
				end 
					-- strSoundMode = nil 
			elseif str == '"NumFrames":' then 
				-- print(strings[num+1]) 
				numframes = string.sub(strings[num+1],1,-2) 
				numframes = tonumber(numframes) 
			elseif str == '"SequenceLength":' then 
				sequenceduration = string.sub(strings[num+1],1,-2) 
				sequenceduration = tonumber(sequenceduration) 
				framerate = numframes / sequenceduration 
			end 
			
			-- footstep: NotifyName: SBFootStep 
			-- refer to object SBAnimNotify_FootStep_0 
			-- refer to its property and FootStepSetKey 
			-- depending on R or L save it as R or L 
			-- if none matches, choose randomly 
		end 
		
		-- handle delayed parse operations  
		if i == targetstringline then 
			local targetlinebreakdown = string.Explode('"',k) 
			for num,str in pairs(targetlinebreakdown) do 
				if string.find(str,"AnimNotify_PlaySound") then -- AnimNotify_PlaySound_0 
					-- print("PlaySound names",str) 
					local savetable = { } 
					animnotify_playsound[str] = savetable 
					targetstringline = i + 7 
					lastSavedKey = str 
				elseif string.find(str,"/Game/Sound/") then -- "ObjectPath": "/Game/Sound/Skill/Monster/Raven/M_Raven_Jump_Cue.0" 
					-- strip off index from the ending 
					str = string.StripExtension(str) 
					animnotify_playsound[lastSavedKey].dir = str 
					targetstringline = 0 
					lastSavedKey = nil 
				elseif string.find(str,"SBAnimNotify_FootStep") then -- "Name": "SBAnimNotify_FootStep_5", 
					-- print("FootStep names:",str) 
					local savetable = { } 
					lastSavedKey = str 
					animnotify_footsteps[str] = savetable 
					targetstringline = i + 5 
				elseif string.find(str,"FootStepSetKey") then -- "FootStepSetKey": "R", 
					-- get last winning key 
					local footstepdir = targetlinebreakdown[num+2] 
					animnotify_footsteps[lastSavedKey].dir = footstepdir 
					lastSavedKey = nil 
					-- print(footstepdir) 
					targetstringline = 0 
				elseif string.find(str,"SBAnimNotify_CharSESound") then -- "Name": "SBAnimNotify_CharSESound_7",
					-- print("CharSESound names:",str) 
					local savetable = { } 
					lastSavedKey = str 
					animnotify_charsound[str] = savetable 
					targetstringline = i + 5 
				elseif string.find(str,"VoiceKey") or string.find(str,"ReactionKey") then -- "VoiceKey": "R", 
					-- get last winning key 
					local soundkey = targetlinebreakdown[num+2] 
					soundkey = string.StripExtension(soundkey) 
					animnotify_charsound[lastSavedKey].dir = string.upper(soundkey) 
					-- print("key saved:",lastSavedKey,string.upper(soundkey)) 
					lastSavedKey = nil 
					targetstringline = 0 
				end 
			end 
		end 
		
	end 

	for k,v in pairs(animnotifyseconds) do -- v is LinkValue 
		-- print("seconds for",k,v) 
		eventframes[k] = math.Round((v / sequenceduration) * (numframes - 1)) 
	end 

	for k,v in pairs(animnotify_playsound) do 
		local soundPath = v.dir
		if soundPath then
			-- print("PlaySound cue:", soundPath)
			local sounds = ParseCue(soundPath)
			v.sounds = sounds
			v.cue = soundPath:match(".*/(.+)")
			if sounds and #sounds > 1 then
				sound.Add(v.cue, sounds)
			end
		end
	end


	for k,v in pairs(animnotify_charsound) do -- SBAnimNotify_CharSESound_21 = { dir = "SKILLLAUGH" } 
		-- print(v.dir,"is in animnotify_charsound") 
		local soundKey = v.dir
		if soundKey then
			local parsingcue = false
			for line in io.lines(charsoundsetfile) do
				if string.find(line, "Key") then
					local tblStrings = string.Explode('"', line)
					for _, v3 in pairs(tblStrings) do 
						v3 = string.upper(v3) 
						if v3 == soundKey then
							parsingcue = true -- start capturing until SoundCue found
						end
					end
				elseif string.find(line, "/Game/") and parsingcue then
					parsingcue = false
					local tblStrings = string.Explode('"', line)
					for _, v3 in pairs(tblStrings) do
						if string.find(v3, "/Game/") then
							local parsestring = string.StripExtension(v3)

							local sounds = ParseCue(parsestring) -- explore cue file to return sound paths in a table 
							v.sounds = sounds
							v.cue = parsestring:match(".*/(.+)")

							if sounds then
								sound.Add(v.cue, sounds)
							end 
						end
					end
				elseif string.find(line, '"SoundSource": null,') and parsingcue then
					-- print("sound source is NULL")
					parsingcue = false
				end
			end
		end
	end

	for k,v in pairs(eventframes) do -- build events now 
		local footstep = string.find(k,"FootStep") 
		local PlaySound = string.find(k,"PlaySound") 
		local CharSESound = string.find(k,"CharSESound") 
		if footstep then -- done 
			local dir = animnotify_footsteps[k].dir 
			if string.find(dir,"L") then 
				dir = "L" 
			elseif string.find(dir,"R") then 
				dir = "R" 
			else 
				dir = math.random() > 0.5 and "R" or "L" 
			end 
			if dir == "R" then 
				print('	{event AE_NPC_RIGHTFOOT ',tostring(v),' "" }') 
			else 
				print('	{event AE_NPC_LEFTFOOT ',tostring(v),' "" }') 
			end 
		elseif PlaySound then 
			local soundtable = animnotify_playsound[k].sounds 
			local soundcount = #soundtable 
			local eventid = "1004" 
			local name = "PlaySound" -- if this returns means unhandled definition 
			if soundcount > 1 then 
				-- print("PlaySound has multiple sounds") 
				name = animnotify_playsound[k].cue 
				eventid = "AE_SV_PLAYSOUND" 
			elseif soundcount == 1 then 
				name = "*"..soundtable[1] 
			end 
			-- 1004 for direct wav files 
			-- AE_SV_PLAYSOUND for soundscripts 
			print('	{event '..eventid..' ',tostring(v),' "'..name..'" }') 
			-- print(k,animnotify_playsound[k].dir) 
		elseif CharSESound then 
			local soundtable, soundcount, eventid = animnotify_charsound[k].sounds, 0, "1004" 
			if soundtable then 
				soundcount = #soundtable 
			end 
			local name = "CharSESound" -- unhandled definition 
			if soundcount > 1 then -- soundscript 
				name = animnotify_charsound[k].cue 
				eventid = "AE_SV_PLAYSOUND" 
			elseif soundcount == 1 then -- single sound 
				name = "*"..soundtable[1] 
			end 
			-- 1004 for direct wav files 
			-- AE_SV_PLAYSOUND for soundscripts 
			print('	{event '..eventid..' ',tostring(v),' "'..name..'" }') 
			-- print(k,animnotify_charsound[k].dir) 
		end 
		-- print("frames",k,v) 
	end 
end 

sound.PrintOverrides() 
