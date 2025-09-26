local tblWeapons = { "weapon_pistol", "weapon_alyxgun", "weapon_357", "weapon_glock_hl1", "weapon_357_hl1", "weapon_smg1", "weapon_ar2", "weapon_shotgun", "weapon_shotgun_hl1", "weapon_crossbow", "weapon_rpg", "weapon_mp5_hl1" } 
table.insert(tblWeapons,"weapon_ugold_automag") 
table.insert(tblWeapons,"weapon_ugold_dispersionpistol") 
table.insert(tblWeapons,"weapon_ugold_biorifle") 
table.insert(tblWeapons,"weapon_ugold_asmd") 
table.insert(tblWeapons,"weapon_ugold_stinger") 
table.insert(tblWeapons,"weapon_ugold_eightball") 
table.insert(tblWeapons,"weapon_ugold_razor") 
table.insert(tblWeapons,"weapon_ugold_minigun") 
table.insert(tblWeapons,"weapon_ugold_flak") 
table.insert(tblWeapons,"weapon_ugold_rifle") 
table.insert(tblWeapons,"weapon_ut99_enforcer") 
table.insert(tblWeapons,"weapon_ut99_flak") 
table.insert(tblWeapons,"weapon_ut99_eight") 
table.insert(tblWeapons,"weapon_ut99_rifle") 
table.insert(tblWeapons,"weapon_ut99_ripper") 
table.insert(tblWeapons,"weapon_ut99_minigun") 
table.insert(tblWeapons,"weapon_u4et_qsg") 
table.insert(tblWeapons,"weapon_u4et_bfg20k") 
table.insert(tblWeapons,"weapon_u4et_m16") 
table.insert(tblWeapons,"weapon_u4et_phasor") 
table.insert(tblWeapons,"weapon_u4et_fourball") 
table.insert(tblWeapons,"weapon_u4et_tomahawk") 
table.insert(tblWeapons,"weapon_u4et_howzy") 
table.insert(tblWeapons,"weapon_dgl") 
table.insert(tblWeapons,"weapon_orng_trithrower") 
table.insert(tblWeapons,"weapon_sin_assault") 
table.insert(tblWeapons,"weapon_yan6541") 
table.insert(tblWeapons,"weapon_yan6541_upgr") 

player_manager.AddValidModel( "Raven", "models/alvaroports/SBRavenPM.mdl" ) 
player_manager.AddValidHands( "Raven", "models/alvaroports/SBRavenVM.mdl", 0, "0000000" ) 

local NPC = {
	Name = "Raven (Friend)",
	Class = "npc_sb_raven",
	Category = "Other",
	Weapons = tblWeapons,
	Model = "models/alvaroports/sbravenpm.mdl",
	KeyValues = { citizentype = 4, Numgrenades = 5, npcclass = 2 }
} 

list.Set( "NPC", "CH_M_NA_53", NPC ) 

NPC = {
	Name = "Raven (Enemy)",
	Class = "npc_sb_raven",
	Category = "Other",
	Weapons = tblWeapons,
	Model = "models/alvaroports/sbravenpm.mdl",
	KeyValues = { citizentype = 4, Numgrenades = 5, npcclass = 5 }
} 

list.Set( "NPC", "CH_M_NA_53_enemy", NPC ) 