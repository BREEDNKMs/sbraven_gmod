import bpy
import os
import sys
import json
import re
import struct
from pathlib import Path
from typing import Dict, List, Optional, Any, Tuple

# ==============================================================================
# CONFIGURATION
# ==============================================================================
CHAR_ID = "ch_m_na_03"

# Path to the predefined .psk mesh
PSK_PATH = rf"F:\Stellar Blade\Output\Exports\SB\Content\Art\Character\Monster\CH_M_NA_03\CH_M_NA_03.psk"

# Directory containing .psa animations & matching .json files (scanned recursively)
ANIMATION_DIR = rf"F:\Stellar Blade\Output\Exports\SB\Content\Art\Character\Monster\CH_M_NA_03\Animation"

# Character Sound Set (CSS) JSON path or directory containing CSS_*.json files
CSS_INPUT = rf"F:\Stellar Blade\Output\Exports\SB\Content\Sound\SoundAsset\CharacterSoundset\CSS_MON_03_Clriket.json"

# Root game export path (maps to Unreal /Game/ mount point)
GAME_PATH = rf"F:\Stellar Blade\Output\Exports\SB\Content"

# Target export folder for Blender Source Tools
EXPORT_DIR = rf"C:\Users\mainpc\mdl compile temp\stellar_blade_characters\{CHAR_ID}"

# Default sound channel for Source Engine / Garry's Mod sound.Add
DEFAULT_CHANNEL = "CHAN_AUTO"

# Set to True to clean the default Blender scene (cube, camera, light) before running
CLEAR_SCENE = True

# Global lookup table mapping sequence stem names (lowercased) -> .json file path
json_lookup: Dict[str, str] = {}


# ==============================================================================
# UNREAL AUDIO & SOUND CUE UTILITY FUNCTIONS
# ==============================================================================
def strip_unreal_index(path: str) -> str:
    """Removes trailing numeric indices (.0) or sub-object names from Unreal paths."""
    if not path:
        return ""
    clean = re.sub(r"\.\d+$", "", path.strip())
    clean = re.sub(r"\.[^./]+$", "", clean)
    return clean


def to_source_sound_path(asset_path: str) -> Optional[str]:
    """
    Converts an Unreal sound asset path into a Source Engine relative sound path
    (under sound/, lowercased, with .wav extension).
    """
    if not asset_path:
        return None
    s = str(asset_path).strip().replace("\\", "/")
    s = re.sub(r"\.\d+$", "", s)
    s = re.sub(r"\.[^./]+$", "", s)
    s = re.sub(r"^/Game/", "", s, flags=re.IGNORECASE)
    s = re.sub(r"^L10N/[^/]+/", "", s, flags=re.IGNORECASE)
    s = re.sub(r"/L10N/[^/]+/", "/", s, flags=re.IGNORECASE)
    s = re.sub(r"^Sound/", "", s, flags=re.IGNORECASE)
    s = s.lstrip("/")

    if not s.lower().endswith(".wav"):
        s += ".wav"
    return s.lower()


def objectpath_to_disk_json(object_path: str, base_game_path: str) -> Optional[Path]:
    """Resolves an Unreal ObjectPath (/Game/...) to a physical .json file path on disk."""
    if not object_path:
        return None
    clean = re.sub(r"\.\d+$", "", str(object_path).strip()).replace("\\", "/")
    if not clean.lower().startswith("/game"):
        return None

    rel = re.sub(r"^/Game/", "", clean, count=1, flags=re.IGNORECASE)
    if not rel:
        return None
    return Path(base_game_path) / (rel + ".json")


def distance_to_soundlevel(max_distance: Any) -> int:
    """Maps Unreal SoundCue MaxDistance (cm) to Source Engine soundlevel (dB)."""
    try:
        dist = float(max_distance)
    except (TypeError, ValueError):
        return 85

    if dist <= 1500:
        return 75   # Whispers, footsteps, cloth rustle
    elif dist <= 6000:
        return 85   # Standard combat voice / sword whoosh
    elif dist <= 25000:
        return 105  # Screams / heavy impacts
    else:
        return 130  # Distant boss actions


def extract_notify_name(obj_name: str) -> str:
    """Extracts clean notify name from ObjectName or ObjectPath string."""
    if not obj_name:
        return ""
    m = re.search(r":([^']+)'?$", obj_name)
    if m:
        return m.group(1)
    m = re.search(r".+/([^.]+)(?:\.\d+)?$", obj_name)
    if m:
        return m.group(1)
    return obj_name.strip("'")


# ==============================================================================
# SOUND CUE EVALUATOR & CHARACTER SOUND SET (CSS) MANAGERS
# ==============================================================================
class SoundCueEvaluator:
    def __init__(self, game_path: str):
        self.game_path = game_path
        self.cache: Dict[str, Optional[Dict[str, Any]]] = {}

    def parse_cue(self, cue_object_path: str) -> Optional[Dict[str, Any]]:
        if not cue_object_path:
            return None

        clean_path = re.sub(r"\.\d+$", "", cue_object_path.strip())
        if clean_path in self.cache:
            return self.cache[clean_path]

        disk_path = objectpath_to_disk_json(clean_path, self.game_path)
        if not disk_path or not disk_path.is_file():
            self.cache[clean_path] = None
            return None

        try:
            with open(disk_path, "r", encoding="utf-8") as f:
                nodes = json.load(f)
        except Exception:
            self.cache[clean_path] = None
            return None

        if not isinstance(nodes, list):
            self.cache[clean_path] = None
            return None

        cue_name = Path(clean_path).name or "SoundCue"
        cue_info = {
            "name": cue_name,
            "volume": 1.0,
            "pitch_min": 100,
            "pitch_max": 100,
            "soundlevel": 85,
            "sounds": []
        }

        root_cue = next((n for n in nodes if isinstance(n, dict) and n.get("Type") == "SoundCue"), None)
        if root_cue and "Properties" in root_cue:
            props = root_cue["Properties"]
            if "VolumeMultiplier" in props:
                cue_info["volume"] = float(props["VolumeMultiplier"])
            if "MaxDistance" in props:
                cue_info["soundlevel"] = distance_to_soundlevel(props["MaxDistance"])

        seen_waves = set()
        for node in nodes:
            if not isinstance(node, dict):
                continue
            n_type = node.get("Type")
            props = node.get("Properties", {})

            if n_type == "SoundNodeModulator":
                if "PitchMin" in props:
                    cue_info["pitch_min"] = round(float(props["PitchMin"]) * 100)
                if "PitchMax" in props:
                    cue_info["pitch_max"] = round(float(props["PitchMax"]) * 100)
                if "VolumeMin" in props and cue_info["volume"] == 1.0:
                    cue_info["volume"] = float(props["VolumeMin"])

            elif n_type == "SoundNodeWavePlayer":
                asset = None
                if "SoundWaveAssetPtr" in props and "AssetPathName" in props["SoundWaveAssetPtr"]:
                    asset = props["SoundWaveAssetPtr"]["AssetPathName"]
                elif "SoundWave" in node:
                    sw = node["SoundWave"]
                    asset = sw.get("ObjectPath") or sw.get("ObjectName")

                if asset:
                    src_wav = to_source_sound_path(asset)
                    if src_wav and src_wav not in seen_waves:
                        cue_info["sounds"].append(src_wav)
                        seen_waves.add(src_wav)

        if not cue_info["sounds"]:
            self.cache[clean_path] = None
            return None

        self.cache[clean_path] = cue_info
        return cue_info


class CharacterSoundSetManager:
    def __init__(self):
        self.sets: Dict[str, Dict[str, Dict[str, Any]]] = {}

    def load_css_file(self, file_path: Path):
        try:
            with open(file_path, "r", encoding="utf-8") as f:
                data = json.load(f)
        except Exception:
            return

        if not isinstance(data, list) or not data:
            return

        root = data[0]
        if not isinstance(root, dict) or "Properties" not in root:
            return

        css_name = root.get("Name", file_path.stem)
        sound_map: Dict[str, Dict[str, Any]] = {}

        def ingest_entry(entry: Dict[str, Any]):
            if not isinstance(entry, dict) or "Key" not in entry:
                return
            key = str(entry["Key"]).upper()
            val = entry.get("Value")
            if not isinstance(val, dict):
                return

            target = val
            if "HitTypeArray" in val and isinstance(val["HitTypeArray"], list) and val["HitTypeArray"]:
                first_hit = val["HitTypeArray"][0]
                if isinstance(first_hit, dict) and "HitSound" in first_hit:
                    target = first_hit["HitSound"]

            sound_source = target.get("SoundSource")
            if isinstance(sound_source, dict):
                sound_map[key] = {
                    "objectName": sound_source.get("ObjectName"),
                    "objectPath": sound_source.get("ObjectPath"),
                    "volumeMultiplier": float(target.get("VolumeMultiplier", 1.0)),
                    "pitchMultiplier": float(target.get("PitchMultiplier", 1.0)),
                    "boneSocket": target.get("BoneSocketName")
                }

        for prop_value in root["Properties"].values():
            if isinstance(prop_value, list):
                for item in prop_value:
                    ingest_entry(item)

        self.sets[css_name] = sound_map
        print(f"[*] Loaded CharacterSoundSet: {css_name} ({len(sound_map)} keys indexed)")

    def init_from_path(self, path_str: str):
        p = Path(path_str)
        if p.is_dir():
            for f in sorted(p.glob("*.json")):
                self.load_css_file(f)
        elif p.is_file():
            self.load_css_file(p)

    def resolve_sound(self, sound_key: str, anim_context_path: str = "") -> Optional[Dict[str, Any]]:
        if not sound_key:
            return None
        ukey = sound_key.upper()

        anim_ctx_lower = anim_context_path.lower()
        for css_name, sound_map in self.sets.items():
            token = re.sub(r"^CSS_(?:MON_\d+_|PC_)?", "", css_name, flags=re.IGNORECASE)
            if token and token.lower() in anim_ctx_lower:
                if ukey in sound_map:
                    return sound_map[ukey]

        for sound_map in self.sets.values():
            if ukey in sound_map:
                return sound_map[ukey]

        return None


class SoundRegistry:
    def __init__(self, default_channel: str = "CHAN_AUTO"):
        self.default_channel = default_channel
        self.entries: Dict[str, Dict[str, Any]] = {}

    def register(self, cue_info: Dict[str, Any], volume_override: float = 1.0):
        if not cue_info or not cue_info.get("name") or not cue_info.get("sounds"):
            return

        name = cue_info["name"]
        combined_vol = round(cue_info.get("volume", 1.0) * volume_override, 2)

        if name not in self.entries:
            self.entries[name] = {
                "channel": self.default_channel,
                "volume": combined_vol,
                "soundlevel": cue_info.get("soundlevel", 85),
                "pitch_min": cue_info.get("pitch_min", 100),
                "pitch_max": cue_info.get("pitch_max", 100),
                "sound": cue_info["sounds"]
            }

    def generate_soundscript_text(self) -> str:
        lines = [
            "-- ============================================================================",
            f"-- Generated Source Soundscripts (sound.Add) for {CHAR_ID}",
            "-- ============================================================================\n"
        ]
        for name, data in self.entries.items():
            lines.append("sound.Add({")
            lines.append(f'    name = "{name}",')
            lines.append(f'    channel = {data["channel"]},')
            lines.append(f'    volume = {data["volume"]},')
            lines.append(f'    soundlevel = {data["soundlevel"]},')
            if data["pitch_min"] != data["pitch_max"]:
                lines.append(f'    pitch = {{ {data["pitch_min"]}, {data["pitch_max"]} }},')
            else:
                lines.append(f'    pitch = {data["pitch_min"]},')

            if len(data["sound"]) == 1:
                lines.append(f'    sound = "{data["sound"][0]}"')
            else:
                lines.append('    sound = {')
                for i, snd in enumerate(data["sound"]):
                    comma = "," if i < len(data["sound"]) - 1 else ""
                    lines.append(f'        "{snd}"{comma}')
                lines.append('    }')
            lines.append("})\n")
        return "\n".join(lines)


# ==============================================================================
# ANIMATION JSON EVENT & FPS PARSER
# ==============================================================================
def parse_anim_events_and_fps(
    seq_name: str,
    css_manager: CharacterSoundSetManager,
    cue_evaluator: SoundCueEvaluator,
    sound_registry: SoundRegistry
) -> Tuple[Any, List[Tuple[int, str, str]]]:
    """
    Parses the corresponding JSON for an animation to:
    1. Calculate exact FPS (NumFrames / SequenceLength).
    2. Extract and chronologically sort animation audio events.
    """
    json_path = json_lookup.get(seq_name.lower())
    if not json_path or not os.path.isfile(json_path):
        return 15, []

    try:
        with open(json_path, "r", encoding="utf-8") as f:
            objects = json.load(f)
    except Exception:
        return 15, []

    if not isinstance(objects, list):
        return 15, []

    notifies_playsound: Dict[str, Dict[str, Any]] = {}
    notifies_charse:    Dict[str, Dict[str, Any]] = {}
    notifies_footstep:  Dict[str, Dict[str, Any]] = {}
    anim_sequence_obj:  Optional[Dict[str, Any]] = None

    for obj in objects:
        if not isinstance(obj, dict):
            continue
        obj_type = str(obj.get("Type") or obj.get("Class") or "")
        name = obj.get("Name")
        props = obj.get("Properties", {})

        if "AnimNotify_PlaySound" in obj_type and name:
            notifies_playsound[name] = props
        elif "AnimNotify_CharSESound" in obj_type and name:
            notifies_charse[name] = props
        elif "AnimNotify_FootStep" in obj_type and name:
            notifies_footstep[name] = props
        elif "AnimSequence" in obj_type:
            anim_sequence_obj = obj

    if not anim_sequence_obj or "Properties" not in anim_sequence_obj:
        return 15, []

    seq_props = anim_sequence_obj["Properties"]
    num_frames = seq_props.get("NumFrames")
    seq_length = seq_props.get("SequenceLength")

    if not num_frames or not seq_length:
        return 15, []

    num_frames = int(num_frames)
    seq_length = float(seq_length)

    fps = 15
    if seq_length > 0:
        calc_fps = round(num_frames / seq_length, 2)
        fps = int(calc_fps) if calc_fps.is_integer() else calc_fps

    events: List[Tuple[int, str, str]] = []
    notifies_list = seq_props.get("Notifies") or []
    anim_package_path = anim_sequence_obj.get("Package", str(json_path))

    for n in notifies_list:
        if not isinstance(n, dict):
            continue

        link_val = None
        if "EndLink" in n and isinstance(n["EndLink"], dict) and "LinkValue" in n["EndLink"]:
            link_val = n["EndLink"]["LinkValue"]
        elif "LinkValue" in n:
            link_val = n["LinkValue"]

        notify_obj_name = None
        if "Notify" in n and isinstance(n["Notify"], dict):
            notify_obj_name = n["Notify"].get("ObjectName") or n["Notify"].get("ObjectPath")

        if link_val is not None and notify_obj_name:
            link_val = float(link_val)

            # Skip orphaned/out-of-bounds notifies beyond the sequence length
            if link_val < 0.0 or link_val > seq_length:
                continue

            notify_name = extract_notify_name(notify_obj_name)
            frame = round((link_val / seq_length) * (num_frames - 1)) if seq_length > 0 else 0
            frame = max(0, min(frame, num_frames - 1))

            # 1. Footstep Notifies
            if notify_name in notifies_footstep:
                fs = notifies_footstep[notify_name]
                set_key = str(fs.get("FootStepSetKey", "")).upper()
                if "KD_B" in set_key:
                    events.append((frame, "AE_NPC_BODYFALL", ""))
                elif "L" in set_key:
                    events.append((frame, "AE_NPC_LEFTFOOT", ""))
                elif "R" in set_key:
                    events.append((frame, "AE_NPC_RIGHTFOOT", ""))
                else:
                    events.append((frame, "AE_NPC_LEFTFOOT", ""))

            # 2. Character Sound Set Notifies
            elif notify_name in notifies_charse:
                cs = notifies_charse[notify_name]
                key = cs.get("VoiceKey") or cs.get("ReactionKey")
                if key:
                    resolved = css_manager.resolve_sound(str(key), anim_package_path)
                    if resolved:
                        obj_name = str(resolved.get("objectName", ""))
                        obj_path = str(resolved.get("objectPath", ""))
                        vol = resolved.get("volumeMultiplier", 1.0)

                        if "SoundCue" in obj_name or "SoundCue" in obj_path:
                            cue_info = cue_evaluator.parse_cue(obj_path)
                            if cue_info:
                                sound_registry.register(cue_info, vol)
                                if (len(cue_info["sounds"]) == 1 and vol == 1.0 and
                                        cue_info["pitch_min"] == 100 and cue_info["pitch_max"] == 100):
                                    events.append((frame, "AE_SV_PLAYSOUND", "*" + cue_info["sounds"][0]))
                                else:
                                    events.append((frame, "AE_SV_PLAYSOUND", cue_info["name"]))

                        elif "SoundWave" in obj_name or "SoundWave" in obj_path:
                            wav_path = to_source_sound_path(obj_path)
                            if wav_path:
                                events.append((frame, "AE_SV_PLAYSOUND", "*" + wav_path))

            # 3. Direct PlaySound Notifies
            elif notify_name in notifies_playsound:
                ps = notifies_playsound[notify_name]
                sound_prop = ps.get("Sound")
                if isinstance(sound_prop, dict):
                    obj_name = str(sound_prop.get("ObjectName", ""))
                    obj_path = str(sound_prop.get("ObjectPath", ""))
                    vol = float(ps.get("VolumeMultiplier", 1.0))

                    if "SoundCue" in obj_name or "SoundCue" in obj_path:
                        cue_info = cue_evaluator.parse_cue(obj_path)
                        if cue_info:
                            sound_registry.register(cue_info, vol)
                            if (len(cue_info["sounds"]) == 1 and vol == 1.0 and
                                    cue_info["pitch_min"] == 100 and cue_info["pitch_max"] == 100):
                                events.append((frame, "AE_SV_PLAYSOUND", "*" + cue_info["sounds"][0]))
                            else:
                                events.append((frame, "AE_SV_PLAYSOUND", cue_info["name"]))

                    elif "SoundWave" in obj_name or "SoundWave" in obj_path:
                        wav_path = to_source_sound_path(obj_path)
                        if wav_path:
                            events.append((frame, "AE_SV_PLAYSOUND", "*" + wav_path))

    events.sort(key=lambda x: x[0])
    return fps, events


# ==============================================================================
# BLENDER & PSK/PSA LOADING HELPERS
# ==============================================================================
def clear_scene():
    """Removes existing objects and actions to prevent name collisions."""
    if bpy.context.object and bpy.context.object.mode != 'OBJECT':
        bpy.ops.object.mode_set(mode='OBJECT')
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)
    for action in list(bpy.data.actions):
        bpy.data.actions.remove(action)


def import_psk(filepath: str):
    """Imports the .psk mesh using DarklightGames/io_scene_psk_psa."""
    if not os.path.isfile(filepath):
        raise FileNotFoundError(f"PSK file not found at: {filepath}")

    if hasattr(bpy.ops.import_scene, "psk"):
        bpy.ops.import_scene.psk(filepath=filepath)
    elif hasattr(bpy.ops, "psk_import"):
        getattr(bpy.ops.psk_import, "import")(filepath=filepath)
    else:
        raise RuntimeError("Unreal PSK importer operator not found. Ensure io_scene_psk_psa is enabled.")


def read_psa_sequence_names(filepath: str) -> List[str]:
    """Fallback binary parser to extract sequence names from a PSA file."""
    sequence_names = []
    with open(filepath, 'rb') as f:
        while True:
            header = f.read(32)
            if len(header) < 32:
                break
            chunk_id, flags, data_size, data_count = struct.unpack('<20sIII', header)
            chunk_name = chunk_id.split(b'\x00')[0].decode('ascii', errors='ignore')
            data = f.read(data_size * data_count)
            if chunk_name == 'ANIMINFO':
                for i in range(data_count):
                    record = data[i * data_size : (i + 1) * data_size]
                    name_bytes = record[:64].split(b'\x00')[0]
                    sequence_names.append(name_bytes.decode('windows-1252', errors='ignore'))
                break
    return sequence_names


def populate_and_select_sequences(filepath: str):
    """Populates scene.psa_import.sequence_list so psa_import.import processes them."""
    pg = getattr(bpy.context.scene, 'psa_import', None)
    if pg is None:
        return

    load_func = None
    reader_cls = None
    for mod in sys.modules.values():
        if mod:
            if hasattr(mod, "load_psa_file"):
                load_func = getattr(mod, "load_psa_file")
            if hasattr(mod, "PsaReader"):
                reader_cls = getattr(mod, "PsaReader")

    if load_func:
        load_func(bpy.context, filepath)
    elif reader_cls:
        pg.sequence_list.clear()
        pg.psa.bones.clear()
        pg.psa_error = ''
        reader = reader_cls(os.path.abspath(filepath))
        for seq in reader.sequences.values():
            item = pg.sequence_list.add()
            item.action_name = seq.name.decode('windows-1252')
        for bone in reader.bones:
            item = pg.psa.bones.add()
            item.bone_name = bone.name.decode('windows-1252')
    else:
        pg.sequence_list.clear()
        pg.psa.bones.clear()
        pg.psa_error = ''
        names = read_psa_sequence_names(os.path.abspath(filepath))
        for name in names:
            item = pg.sequence_list.add()
            item.action_name = name

    for seq in pg.sequence_list:
        seq.is_selected = True


# ==============================================================================
# MAIN WORKFLOW
# ==============================================================================

# --- 1. CLEAN SCENE & IMPORT PSK ---
if CLEAR_SCENE:
    clear_scene()

print(f"[*] Step 1: Importing PSK: {PSK_PATH}")
import_psk(PSK_PATH)


# --- 2. SELECT ARMATURE ---
armature_obj = None
for obj in bpy.context.scene.objects:
    if obj.type == 'ARMATURE':
        armature_obj = obj
        break

if not armature_obj:
    raise RuntimeError("No armature object found in the scene after importing PSK.")

if bpy.context.object and bpy.context.object.mode != 'OBJECT':
    bpy.ops.object.mode_set(mode='OBJECT')

bpy.ops.object.select_all(action='DESELECT')
armature_obj.select_set(True)
bpy.context.view_layer.objects.active = armature_obj
print(f"[*] Step 2: Selected active armature: {armature_obj.name}")


# --- 3. RECURSIVELY IMPORT PSA FILES & INDEX JSONs ---
print(f"[*] Step 3: Searching for PSA and JSON files in: {ANIMATION_DIR}")
psa_files = []
if os.path.exists(ANIMATION_DIR):
    for root, _, files in os.walk(ANIMATION_DIR):
        for f in files:
            if f.lower().endswith(".psa"):
                psa_files.append(os.path.join(root, f))
            elif f.lower().endswith(".json"):
                json_lookup[os.path.splitext(f)[0].lower()] = os.path.join(root, f)
    psa_files.sort()
else:
    print(f"[!] Warning: Directory not found: {ANIMATION_DIR}")

print(f"[*] Found {len(psa_files)} PSA file(s) and {len(json_lookup)} JSON file(s).")

pg = getattr(bpy.context.scene, 'psa_import', None)
if pg:
    pg.fps_source = 'SEQUENCE'
    pg.should_write_keyframes = True
    pg.should_write_metadata = True
    pg.should_use_fake_user = True
    pg.should_overwrite = False
    pg.bone_mapping_mode = 'CASE_INSENSITIVE'

for idx, psa_path in enumerate(psa_files, 1):
    print(f"    [{idx}/{len(psa_files)}] Importing: {os.path.basename(psa_path)}")
    if bpy.context.object and bpy.context.object.mode != 'OBJECT':
        bpy.ops.object.mode_set(mode='OBJECT')
    bpy.ops.object.select_all(action='DESELECT')
    armature_obj.select_set(True)
    bpy.context.view_layer.objects.active = armature_obj

    populate_and_select_sequences(psa_path)
    getattr(bpy.ops.psa_import, "import")(filepath=psa_path)

for act in bpy.data.actions:
    act.use_fake_user = True


# --- 4 & 5. CONFIGURE BST OPTIONS ---
print("[*] Step 4 & 5: Configuring Blender Source Tools export options...")
os.makedirs(EXPORT_DIR, exist_ok=True)
bpy.context.scene.frame_start = 0
bpy.context.scene.frame_current = 0
bpy.context.scene.vs.export_path = EXPORT_DIR
bpy.context.scene.vs.export_format = 'SMD'

for target in [armature_obj, getattr(armature_obj, "data", None)]:
    if target and hasattr(target, "vs"):
        if hasattr(target.vs, "action_selection"):
            target.vs.action_selection = 'FILTERED'
        if hasattr(target.vs, "action_filter"):
            target.vs.action_filter = '*'
        if hasattr(target.vs, "subdir"):
            target.vs.subdir = 'anims'


# --- 6. EXPORT ANIMATIONS & MESH TO SMD ---
if armature_obj:
    if not armature_obj.animation_data:
        armature_obj.animation_data_create()
    if bpy.data.actions:
        armature_obj.animation_data.action = bpy.data.actions[0]

bpy.ops.object.select_all(action='DESELECT')
armature_obj.select_set(True)
bpy.context.view_layer.objects.active = armature_obj
for obj in bpy.context.scene.objects:
    if obj.type in {'ARMATURE', 'MESH'}:
        obj.select_set(True)

print(f"[*] Step 6: Exporting animations to SMD: {EXPORT_DIR}")
bpy.ops.export_scene.smd()

# Re-fetch live scene references to prevent RNA ReferenceError
if bpy.context.object and bpy.context.object.mode != 'OBJECT':
    bpy.ops.object.mode_set(mode='OBJECT')

bpy.ops.object.select_all(action='DESELECT')
armature_obj = next((obj for obj in bpy.context.scene.objects if obj.type == 'ARMATURE'), None)

mesh_children = [
    obj for obj in bpy.context.scene.objects
    if obj.type == 'MESH' and (
        (armature_obj and obj.parent == armature_obj) or
        (armature_obj and any(m.type == 'ARMATURE' and m.object == armature_obj for m in obj.modifiers))
    )
]
if not mesh_children:
    mesh_children = [obj for obj in bpy.context.scene.objects if obj.type == 'MESH']

for mesh_obj in mesh_children:
    mesh_obj.select_set(True)

if mesh_children:
    bpy.context.view_layer.objects.active = mesh_children[0]
    print(f"[*] Exporting mesh: {mesh_children[0].name}")
    bpy.ops.export_scene.smd()
else:
    print("[!] Warning: No mesh object found associated with the armature.")


# --- 7. CLEAN .001 SUFFIXES & NORMALIZE PATHS ---
print("[*] Step 7: Cleaning up .001 suffixes and organizing exported files...")
anims_dir = os.path.join(EXPORT_DIR, "anims")
os.makedirs(anims_dir, exist_ok=True)

def strip_numeric_suffixes(directory: str):
    """Renames any 'name.001.smd' or 'name.002.smd' to 'name.smd'."""
    for fname in os.listdir(directory):
        if fname.lower().endswith(".smd"):
            clean_name = re.sub(r"\.\d+(?=\.smd$)", "", fname, flags=re.IGNORECASE)
            if clean_name != fname:
                src = os.path.join(directory, fname)
                dst = os.path.join(directory, clean_name)
                if os.path.exists(dst):
                    os.remove(dst)
                os.rename(src, dst)
                print(f"    Renamed: {fname} -> {clean_name}")

strip_numeric_suffixes(EXPORT_DIR)
if os.path.isdir(anims_dir):
    strip_numeric_suffixes(anims_dir)

target_mesh_name = f"{CHAR_ID.lower()}.smd"
identified_mesh_smd = None

for fname in os.listdir(EXPORT_DIR):
    if fname.lower().endswith(".smd"):
        stem = re.sub(r"\.smd$", "", fname, flags=re.IGNORECASE)
        if stem.lower() == CHAR_ID.lower():
            identified_mesh_smd = fname
            break

for fname in os.listdir(EXPORT_DIR):
    if fname.lower().endswith(".smd") and fname != identified_mesh_smd:
        src = os.path.join(EXPORT_DIR, fname)
        dst = os.path.join(anims_dir, fname)
        if os.path.exists(dst):
            os.remove(dst)
        os.rename(src, dst)

# Windows-safe case rename
if identified_mesh_smd:
    src = os.path.join(EXPORT_DIR, identified_mesh_smd)
    dst = os.path.join(EXPORT_DIR, target_mesh_name)
    if src != dst:
        if src.lower() == dst.lower():
            temp_path = src + ".case_temp"
            os.rename(src, temp_path)
            os.rename(temp_path, dst)
        else:
            if os.path.exists(dst):
                os.remove(dst)
            os.rename(src, dst)
    final_mesh_smd = target_mesh_name
else:
    final_mesh_smd = target_mesh_name


# --- 8. PARSE AUDIO NOTIFIES & GENERATE QC + SOUNDSCRIPTS ---
print("[*] Step 8: Parsing Audio Notifies & Generating QC file...")

# Initialize Sound Modules
css_manager = CharacterSoundSetManager()
if os.path.exists(CSS_INPUT):
    css_manager.init_from_path(CSS_INPUT)
else:
    print(f"[!] Warning: CSS Input not found: {CSS_INPUT}")

cue_evaluator = SoundCueEvaluator(GAME_PATH)
sound_registry = SoundRegistry(DEFAULT_CHANNEL)

anim_smds = []
if os.path.isdir(anims_dir):
    anim_smds = [f for f in os.listdir(anims_dir) if f.lower().endswith(".smd")]
    anim_smds.sort()

qc_lines = [
    "// Auto Generated in batch with Sound Events",
    "$scale 0.42",
    "$origin 0 0 0 -90",
    f'$modelname "stellarblade/{CHAR_ID.lower()}.mdl"',
    '$cdmaterials "models/stellarblade/"',
    "",
    f'$model "body" "{final_mesh_smd}" {{',
    "",
    "}",
    "",
    '$surfaceprop "flesh"',
    '$attachment "eyes" "Bip001-Head" 0 0 0 rotate -90 0 -90',
    "",
    '$contents "solid"',
    "",
    '$alwayscollapse "blender_implicit"',
    "",
    '$alwayscollapse "Root"',
    "",
    '$alwayscollapse "Bip001"',
    "",
    r'$cdmaterials "models\unreali\"',
    ""
]

# Construct $sequence blocks with event lines
for anim_file in anim_smds:
    seq_name = os.path.splitext(anim_file)[0]
    seq_fps, events = parse_anim_events_and_fps(seq_name, css_manager, cue_evaluator, sound_registry)

    qc_lines.append(f'$sequence "{seq_name}" {{')
    qc_lines.append(f'\t"anims\\{anim_file}"\t')
    qc_lines.append("\tactivity ACT_IDLE  1")
    qc_lines.append(f"\tfps {seq_fps}")

    for frame, event_type, data in events:
        qc_lines.append(f'\t{{ event {event_type} {frame} "{data}" }}')

    qc_lines.append("}\n")

qc_name = f"{os.path.splitext(final_mesh_smd)[0]}.qc"
qc_path = os.path.join(EXPORT_DIR, qc_name)

with open(qc_path, "w", encoding="utf-8") as f:
    f.write("\n".join(qc_lines))

print(f"[✓] QC generated successfully: {qc_path}")
print(f"[✓] Total sequences processed: {len(anim_smds)}")

# Write soundscripts.txt to export directory
soundscripts_path = os.path.join(EXPORT_DIR, "soundscripts.txt")
soundscripts_content = sound_registry.generate_soundscript_text()

with open(soundscripts_path, "w", encoding="utf-8") as f:
    f.write(soundscripts_content)

print(f"[✓] Soundscripts generated successfully: {soundscripts_path}")
print(f"[✓] Total sound.Add entries created: {len(sound_registry.entries)}")
print("[✓] Process completed successfully!")