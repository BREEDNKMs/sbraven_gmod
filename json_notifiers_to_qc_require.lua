-- combined_parser_with_json.lua
-- Requires rxi json.lua available as `require("json")`

-- Config (edit if needed)
local jsonfile = "E:/Stellar Blade/Output/Exports/SB/Content/Art/Character/PC/CH_P_EVE_01/Animation/"
local charsoundsetfile = "E:/Stellar Blade/Output/Exports/SB/Content/Sound/SoundAsset/CharacterSoundset/CSS_PC_EVE.json"
local gamepath = "E:/Stellar Blade/Output/Exports/SB/Content"

local json = require("json") 
npp:ClearConsole() 

-- utility: check if path is a directory (uses winfile like your environment)
local function isdir(path)
    local attr = winfile and winfile.attributes and winfile.attributes(path)
    return attr and attr.mode == "directory"
end

-- read whole file
local function read_all(path)
    local f, err = io.open(path, "rb")
    if not f then return nil, err end
    local data = f:read("*a")
    f:close()
    return data
end

-- strip trailing numeric index (.0/.1) and remove final extension if present
local function strip_extension(s)
    if not s then return s end
    -- remove trailing .N index like .0
    local noidx = s:gsub("%.%d+$", "")
    -- If it still has an extension after last dot (rare for /Game paths), try to strip by keeping everything up to last dot that isn't part of path components
    -- For typical /Game/Sound/.../Name or "/Game/Path/Name.SubName" the previous gsub suffices.
    return noidx
end

-- convert Unreal game path (/Game/Sound/... or /Game/...) into Source relative WAV path (no leading slash, no "/Game" or "/Game/Sound/")
local function to_source_sound_path(gamePath)
    if not gamePath then return nil end
    local s = tostring(gamePath)
    s = s:gsub("%.%d+$", "")        -- strip trailing index (.0)
    s = s:gsub("^/Game/Sound/", "") -- strip /Game/Sound/
    s = s:gsub("^/Game/", "")       -- strip /Game/
    s = s:gsub("^/", "")            -- remove leading slash if any remains
    if not s:lower():match("%.wav$") then
        s = s .. ".wav"
    end
    return s
end

-- build cue JSON path from objectPath ("/Game/...") -> <gamepath> + relative + ".json"
local function cue_json_path_from_gamepath(objectPath)
    if not objectPath then
        -- don't hard-error here; return nil so ParseCue can handle missing/unsupported paths
        -- (caller may log a debug message)
        return nil
    end

    -- normalize and remove trailing numeric index like ".0"
    local withoutIndex = tostring(objectPath):gsub("%.%d+$", "")
	-- print("withoutIndex:",withoutIndex) 
    withoutIndex = withoutIndex:match("^%s*(.-)%s*$") -- trim whitespace
	-- print("withoutIndex after match:",withoutIndex) 

    -- ensure it starts with "/Game" (accept both "/Game" and "/Game/")
    if not withoutIndex:match("^/Game") then
        -- not a game-path we can resolve to a cue JSON
		-- print("withoutIndex didn't match") 
        return nil
    end

    -- remove the leading "/Game/" (if present) in a safe way
    local rel = withoutIndex:gsub("^/Game/", "", 1)
	-- print("rel",rel) 
    -- if the string was exactly "/Game" (unlikely), rel will be empty -> return nil
    if rel == "" then return nil end
	rel = "/"..rel 

    local full = gamepath .. rel .. ".json"
    return full
end

-- JSON-first ParseCue: return array of Source-style WAV paths (no /Game prefix)
-- ParseCue: JSON-only, SoundNodeWavePlayer-first, AssetPathName preferred.
local function ParseCue(objectPath)
    if not objectPath then return nil end

    local cuefile = cue_json_path_from_gamepath(objectPath)
    if not cuefile then return nil end

    local content, err = read_all(cuefile)
    if not content then return nil end

    -- Decode JSON; if decode fails, bail (per your request to rely on JSON nodes)
    local ok, nodes = pcall(json.decode, content)
    if not ok or type(nodes) ~= "table" then
        return nil
    end

    local sounds = {}
    local seen = {}

    -- Helper: try to normalize candidate strings using string.StripExtension,
    -- then convert to Source path with to_source_sound_path.
    local function candidate_to_source_path(candidate, cueObjectPath)
        if not candidate then return nil end

        -- use imported gmod function to strip the extension (user-provided)
        local stripped = string.StripExtension(candidate)

        -- If stripped looks like "SoundWave'Name'", extract the inner name and
        -- attempt to resolve it relative to the cue's folder (best-effort).
        if stripped:match("^%w+'") and stripped:match("'$") and not stripped:match("^/Game") then
            local inner = stripped:match("^[^']+'(.-)'$")
            if inner and cueObjectPath then
                -- build base folder from the cue's objectPath (remove trailing index and last segment)
                local base = tostring(cueObjectPath):gsub("%.%d+$", "")
                -- folder portion (including trailing slash), e.g. "/Game/Sound/Character/Skill/"
                local folder = base:match("(.*/)")
                if folder then
                    stripped = folder .. inner
                else
                    -- fallback to the inner name only
                    stripped = inner
                end
            end
        end

        -- Finally convert to Source style and return
        local src = to_source_sound_path(stripped)
        return src
    end

    -- Iterate nodes and collect from SoundNodeWavePlayer only
    for _, node in ipairs(nodes) do
        if type(node) == "table" and node.Type == "SoundNodeWavePlayer" then
            local candidate = nil

            -- 1) Prefer Properties.SoundWaveAssetPtr.AssetPathName
            if node.Properties and node.Properties.SoundWaveAssetPtr and node.Properties.SoundWaveAssetPtr.AssetPathName then
                candidate = tostring(node.Properties.SoundWaveAssetPtr.AssetPathName)
            end

            -- 2) Fallback: SoundWave.ObjectName (per your instruction)
            if not candidate and node.SoundWave and node.SoundWave.ObjectName then
                candidate = tostring(node.SoundWave.ObjectName)
            end

            -- If we still have nothing, skip this wave player
            if not candidate then
                goto continue_waveplayer
            end

            -- Normalize and convert to source path
            local srcpath = candidate_to_source_path(candidate, objectPath)
            if srcpath and not seen[srcpath] then
                table.insert(sounds, srcpath)
                seen[srcpath] = true
            end
        end

        ::continue_waveplayer::
    end

    if #sounds == 0 then
        return nil
    end

    return sounds
end


-- sound helper & printer
local sound = {}
sound.ListOverrides = {}

sound.Add = function(cue, tblsoundfiles)
    local converted = {}
    for i, p in ipairs(tblsoundfiles) do
        if type(p) == "string" and p:match("^/Game") then
            converted[i] = to_source_sound_path(p)
        else
            converted[i] = p
        end
    end

    local tabletostring = '{'
    for i, v in ipairs(converted) do
        tabletostring = tabletostring .. '"' .. v .. '"'
        if i < #converted then
            tabletostring = tabletostring .. ','
        end
    end
    tabletostring = tabletostring .. '}'

    if printtabletostringsnow then
        print("sound.Add( ")
        print("{ ")
        print('    name = "' .. cue .. '", ')
        print("    channel = CHAN_AUTO, ")
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
        print("    channel = CHAN_AUTO, ")
        print("    volume = 1, ")
        print("    soundlevel = 100, ")
        print("    sound = " .. v)
        print("}) ")
    end
end

-- Collect JSON files (single or multiple)
local function collect_json_files(path)
    local files = {}
    if isdir(path) and winfile and winfile.dir then
        for file in winfile.dir(path) do
            if file ~= "." and file ~= ".." and file:match("%.json$") then
                table.insert(files, path .. "/" .. file)
            end
        end
    else
        table.insert(files, path)
    end
    return files
end

-- Extract notify object name from an ObjectName/ObjectPath string
local function extract_notify_name(objectName)
    if not objectName then return nil end
    -- patterns like "AnimNotify_PlaySound'TSeq:AnimNotify_PlaySound_11'" or "/Game/.../Name.0"
    -- try to find last colon-separated fragment
    local m = objectName:match(":(.-)'$") or objectName:match(":(.-)$")
    if m then return m end
    -- try after last / up to .N
    local after = objectName:match(".+/(.-)%.%d+$") or objectName:match(".+/(.-)$")
    if after then return after end
    -- fallback: take last token split by non-alnum
    local fallback = objectName:match("([^%/%:%']+)'?$")
    return fallback
end

-- Preload charsoundsetfile content (if present) to map keys -> cue path
local charsoundset_content = nil
local function load_charsoundset()
    if not charsoundsetfile then return nil end
    local c, err = read_all(charsoundsetfile)
    if not c then return nil end
    charsoundset_content = c
    return c
end
load_charsoundset()

-- Given a key (e.g. "SKILLLAUGH"), find associated cue path in charsoundset_content
local function find_cue_for_charsound_key(key)
    if not charsoundset_content or not key then return nil end
    -- Search case-insensitive for a "Key": "<key>" then find following /Game/... asset path
    local upcontent = charsoundset_content:upper()
    local ukey = tostring(key):upper()

    local startpos = upcontent:find('"KEY"%s*:%s*"' .. ukey .. '"')
    if startpos then
        -- from here, find the next /Game/... occurrence in original content (to preserve case)
        local tail = charsoundset_content:sub(startpos)
        local gp = tail:match("(/Game[%w%p]-)[\"'%,%s%}%]]")
        if gp then
            return strip_extension(gp)
        end
    else
        -- fallback: try to find Key with exact case in original
        local startpos2 = charsoundset_content:find('"Key"%s*:%s*"' .. key .. '"')
        if startpos2 then
            local tail = charsoundset_content:sub(startpos2)
            local gp = tail:match("(/Game[%w%p]-)[\"'%,%s%}%]]")
            if gp then
                return strip_extension(gp)
            end
        end
    end

    return nil
end

-- Main processing
local jsonfiles = collect_json_files(jsonfile)

for _, jsonpath in ipairs(jsonfiles) do
    print("Parsing:\t" .. tostring(jsonpath))
    local content, err = read_all(jsonpath)
    if not content then
        print("Failed to read:", jsonpath, err)
    else
        local ok, tbl = pcall(json.decode, content)
        if not ok or type(tbl) ~= "table" then
            print("Failed to decode JSON:", jsonpath)
        else
            -- caches per animation file
            local animnotify_playsound = {} -- name -> { type='wave'|'cue'|'invalid'|nil, wav=..., cuePath=..., objectPath=... }
            local animnotify_footsteps = {} -- name -> { dir = "L"/"R"/nil }
            local animnotify_charsound = {} -- name -> { dir = "KEY" }

            local numframes, sequenceduration

            -- first pass: collect objects of interest
            for _, obj in ipairs(tbl) do
                if type(obj) == "table" then
                    local t = obj.Type or obj.Class or ""
                    -- AnimNotify_PlaySound collection
                    if tostring(t):lower():find("animnotify_playsound") or t == "AnimNotify_PlaySound" then
                        local name = obj.Name
                        if name then
                            animnotify_playsound[name] = animnotify_playsound[name] or {}
                            local entry = animnotify_playsound[name]
                            entry.properties = obj.Properties

                            local soundProp = obj.Properties and obj.Properties.Sound
                            if soundProp then
                                local objNameField = tostring(soundProp.ObjectName or "")
                                local objPathField = tostring(soundProp.ObjectPath or "")

                                local isWave = objNameField:find("SoundWave")
                                local isCue  = objNameField:find("SoundCue")
                                local isClass = objNameField:find("SoundClass") or objPathField:find("SoundClass")

                                if isClass then
                                    entry.type = "invalid"
                                    entry.objectName = objNameField
                                    entry.objectPath = objPathField
                                elseif isWave then
                                    entry.type = "wave"
                                    entry.objectName = objNameField
                                    entry.objectPath = objPathField
                                    entry.wav = to_source_sound_path(strip_extension(objPathField))
                                elseif isCue then
                                    entry.type = "cue"
                                    entry.objectName = objNameField
                                    entry.objectPath = objPathField
                                    entry.cuePath = strip_extension(objPathField)
                                else
                                    -- fallback: use objectPath heuristics
                                    if objPathField:match("^/Game/") then
                                        if objPathField:lower():find("/sound/") and not objPathField:lower():find("soundclass") then
                                            entry.type = "wave"
                                            entry.wav = to_source_sound_path(strip_extension(objPathField))
                                            entry.objectPath = objPathField
                                        else
                                            entry.type = nil
                                            entry.objectPath = objPathField
                                        end
                                    else
                                        entry.type = nil
                                    end
                                end
                            end
                        end

                    -- footstep type
                    elseif tostring(t):lower():find("footstep") or (obj.Class and tostring(obj.Class):lower():find("footstep")) then
                        local name = obj.Name
                        if name then
                            animnotify_footsteps[name] = animnotify_footsteps[name] or {}
                            local fs = animnotify_footsteps[name]
                            if obj.Properties and obj.Properties.FootStepSetKey then
                                fs.dir = tostring(obj.Properties.FootStepSetKey)
                            end
                        end

                    -- char se sound type
                    elseif tostring(t):lower():find("charsesound") or (obj.Class and tostring(obj.Class):lower():find("charsesound")) then
                        local name = obj.Name
                        if name then
                            animnotify_charsound[name] = animnotify_charsound[name] or {}
                            local cs = animnotify_charsound[name]
                            if obj.Properties and (obj.Properties.VoiceKey or obj.Properties.ReactionKey) then
                                cs.dir = tostring(obj.Properties.VoiceKey or obj.Properties.ReactionKey)
                            end
                        end

                    -- AnimSequence: capture numframes, sequence length, and Notifies
                    elseif obj.Type == "AnimSequence" or (obj.Class and tostring(obj.Class):find("AnimSequence")) then
                        if obj.Properties then
                            numframes = tonumber(obj.Properties.NumFrames) or numframes
                            sequenceduration = tonumber(obj.Properties.SequenceLength) or sequenceduration
                        end
                    end
                end
            end

            -- second pass: find the Notifies array in AnimSequence(s)
            local foundNotifies = nil
            for _, obj in ipairs(tbl) do
                if type(obj) == "table" and obj.Type == "AnimSequence" and obj.Properties and obj.Properties.Notifies then
                    foundNotifies = obj.Properties.Notifies
                    numframes = tonumber(obj.Properties.NumFrames) or numframes
                    sequenceduration = tonumber(obj.Properties.SequenceLength) or sequenceduration
                    break
                end
            end

            if not foundNotifies then
                print("No Notifies found for:", jsonpath)
            else
                -- map: notify object name -> frame
                local eventframes = {}
                for _, n in ipairs(foundNotifies) do
                    local linkval = nil
                    if n.EndLink and n.EndLink.LinkValue ~= nil then
                        linkval = tonumber(n.EndLink.LinkValue)
                    elseif n.LinkValue ~= nil then
                        linkval = tonumber(n.LinkValue)
                    end

                    -- find object name referenced by this notify
                    local notifyObjectName = nil
                    if n.Notify and n.Notify.ObjectName then
                        notifyObjectName = extract_notify_name(n.Notify.ObjectName)
                    elseif n.Notify and n.Notify.ObjectPath then
                        notifyObjectName = extract_notify_name(n.Notify.ObjectPath)
                    end

                    if notifyObjectName and linkval and sequenceduration and numframes then
                        local frame = math.floor((linkval / sequenceduration) * (numframes - 1) + 0.5)
                        eventframes[notifyObjectName] = frame
                    end
                end

                -- Build events
                for objName, frame in pairs(eventframes) do
                    local ps = animnotify_playsound[objName]
                    local fs = animnotify_footsteps[objName]
                    local cs = animnotify_charsound[objName]

                    if fs then
                        local dir = fs.dir
                        if dir then
                            dir = tostring(dir)
                            if dir:upper():find("L") then dir = "L"
                            elseif dir:upper():find("R") then dir = "R"
                            else dir = (math.random() > 0.5) and "R" or "L" end
                        else
                            dir = (math.random() > 0.5) and "R" or "L"
                        end

                        if dir == "R" then
                            print('    {event AE_NPC_RIGHTFOOT ' .. tostring(frame) .. ' "" }')
                        else
                            print('    {event AE_NPC_LEFTFOOT ' .. tostring(frame) .. ' "" }')
                        end

                    elseif cs then
                        local soundKey = cs.dir and tostring(cs.dir) or nil
                        local sounds = nil
                        local cue_name = "CharSESound"

                        if soundKey then
                            -- find cue path in charsoundset file
                            local cuepath = find_cue_for_charsound_key(soundKey)
                            if cuepath then
                                sounds = ParseCue(cuepath)
                                cue_name = cuepath:match(".*/(.+)$") or cue_name
                            end
                        end

                        local soundcount = (sounds and #sounds) or 0
                        local name = "CharSESound"
                        if soundcount > 1 then
                            name = cue_name
                        elseif soundcount == 1 then
                            name = "*" .. sounds[1]
                        else
                            name = cue_name -- fallback to cue_name as a script reference
                        end
                        -- Always AE_SV_PLAYSOUND as requested
                        print('    {event AE_SV_PLAYSOUND ' .. tostring(frame) .. ' "' .. tostring(name) .. '" }')

                    elseif ps then
                        -- PlaySound handling
                        local eventid = "AE_SV_PLAYSOUND"
                        local name = nil

                        if ps.type == "wave" and ps.wav then
                            -- raw wav -> prefix '*' and use AE_SV_PLAYSOUND
                            name = "*" .. ps.wav

                        elseif ps.type == "cue" and ps.cuePath then
                            local sounds = ParseCue(ps.cuePath)
                            local cue_name = ps.cuePath:match(".*/(.+)$") or "PlaySound"
							print("adding sound:",cue_name,sounds) 
                            if sounds and #sounds > 1 then
                                sound.Add(cue_name, sounds)
                                name = cue_name
                            elseif sounds and #sounds == 1 then
                                name = "*" .. sounds[1]
                            else
                                name = cue_name
                            end

                        elseif ps.type == "invalid" then
                            -- known non-playable: skip
                            name = nil

                        else
                            -- unknown: try to coerce objectPath
                            if ps.objectPath then
                                local guessed = to_source_sound_path(ps.objectPath)
                                name = "*" .. guessed
                            else
                                name = nil
                            end
                        end

                        if name then
                            print('    {event ' .. eventid .. ' ' .. tostring(frame) .. ' "' .. tostring(name) .. '" }')
                        end

                    else
                        -- unhandled notify type: print comment for debugging
                        print("    -- Unhandled notify:", objName, "frame:", frame)
                    end
                end
            end
        end
    end
end

print("printing overrides") 
sound.PrintOverrides()
