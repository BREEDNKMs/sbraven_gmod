# Raven NPC + Playermodel with skills for Garry's Mod (WIP)
This README was written by GitHub Copilot 
WARNING: Work in progress — many features are incomplete and under active development.

This is an experimental Garry's Mod (GMod) addon that attempts to port skill abilities and related asset metadata from the game Stellar Blade. "SB" stands for Stellar Blade; "Raven" is the example NPC included with the project and used as a reference/test subject. The addon contains prototype logic to reproduce skill behavior, sounds, and effects in GMod for testing and prototyping.
This also includes some basic scripts to port assets from Stellar Blade to Garry's Mod. Sources for model data also exist in this branch. 

Status
- Project: Work in progress
- Playable: Very limited — a few skills and effects are prototyped
- Known issues: missing assets, audio fallbacks, animation/behavior differences, incomplete AI, missing / cheaply replicated effects 

Requirements
- Garry's Mod installed
- Access to Stellar Blade game files (you must own the game)
- FModel (or a similar Unreal asset extractor) to export JSON asset properties from Stellar Blade
- Basic familiarity with installing GMod addons (copying files into the garrysmod/addons/ folder)

Installation (for testers)
1. Download this repository (zip or clone):
   - https://github.com/BREEDNKMs/sbraven_gmod/releases
   - Or clone this repo and pick the branch you want to test.

2. Place the repository contents inside your Garry's Mod addons folder. The addon must be named sbraven (the addon code expects this path). Example (Windows):
   C:\Program Files (x86)\Steam\steamapps\common\GarrysMod\garrysmod\addons\sbraven

   Linux example:
   ~/.steam/steam/steamapps/common/GarrysMod/garrysmod/addons/sbraven

Minimal example directory layout after installation:
- garrysmod/
  - addons/
    - sbraven/
      - lua/
      - materials/
      - models/
      - data_static/           <-- required: user-extracted JSON assets go here
      - README.md
      - ...other addon files...

Extracting JSON properties from Stellar Blade (using FModel)
- Launch FModel and point it at your local Stellar Blade installation.
- Locate the asset(s) you need (animations, sound cues, metadata).
- Use FModel's export functionality to export asset properties as JSON. Preserve folder structure when exporting so the addon can find files using the same relative paths the game uses.

Important example
- After extracting, put the exported JSON files into this folder inside the addon (maintain the game's subfolders):
  E:\Program Files\Steam\steamapps\common\GarrysMod\garrysmod\addons\sbraven\data_static\SB\Content\Sound\Voice\Monster\Raven\M_Raven_vo_SkillLaugh_Cue.json

- The addon scans data_static for skill metadata and audio cues. If JSON files are missing or not placed with the expected paths, many features will not function.

Model availability
- The original Stellar Blade model referenced by this project was removed from the Steam Workshop. For testing:
  - Check the Releases section of this repository for packaged model files and guidance.
  - The repository may include a copy of the model or a link to re-hosted assets. Respect all copyright and EULA restrictions for original game assets.

Usage notes
- This addon is experimental and intended for testers and developers only.
- Expect missing sounds, incorrect animations, or mismatched hitboxes.
- Check the server or client console for errors and missing-asset warnings (these often indicate incorrect paths in data_static).

Contributing and testing
- If you test this addon, please:
  - Open an issue with reproducible steps, your OS, GMod version, the exact addon path you used, and any console output.
  - If you submit fixes, open a pull request or start a discussion describing the approach.

Legal / IP notice
- Stellar Blade is a commercial game and its assets are owned by their respective rights holders.
- This project does not claim ownership of original Stellar Blade content. You are responsible for extracting and using game assets only if you own the game and comply with the game's EULA and local laws.
- This repository provides tooling and glue code for research and prototyping only.

Support / Contact
- Open an issue on the repository for problems or to volunteer as a tester. Include as much detail as possible.
