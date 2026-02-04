
$modelname stellarblade/raven_animations.mdl
$proceduralbones "alyx.vrd"
$include "../../sourcesdk_content/gm_playermodel_examples/Humans/Standardhierarchy.qci"                
$alwayscollapse "ValveBiped"                
$alwayscollapse "XSISceneRoot"                
$include "../../sourcesdk_content/gm_playermodel_examples/Humans/standardikchains.qci"                
//$include "../../sourcesdk_content/gm_playermodel_examples/Humans/female/commonbones.qci"      
$include Sharedbones.qci

$animblocksize 128

$animation "a_proportions_corrective_animation" "sbravenpm_anims\a_proportions_corrective_animation.smd" 
$animation "a_reference" "sbravenpm_anims\reference.smd" 

$animation "a_proportions" "sbravenpm_anims\a_proportions.smd" { 
	fps 30
	// Crowbar writes this subtract option to prevent jigglebone and poseparameter problems when delta sequences are recompiled.
	subtract "a_proportions_corrective_animation" 0
}

$animation "a_inverse_proportions" "sbravenpm_anims\a_inverse_proportions.smd" {
	fps 30
	// Crowbar writes this subtract option to prevent jigglebone and poseparameter problems when delta sequences are recompiled.
	subtract "a_proportions_corrective_animation" 0
} 

$sequence "reference" {
	"a_reference"
	fadein 1
	fadeout 1
	fps 1
	ikrule "rhand" release contact 0 fakeorigin 0 0 0 fakerotate 0 0 0 floor 0 height 0 radius 0 range 0 0 1 1 target 0
	ikrule "lhand" release contact 0 fakeorigin 0 0 0 fakerotate 0 0 0 floor 0 height 0 radius 0 range 0 0 1 1 target 1
	ikrule "rfoot" release contact 0 fakeorigin 0 0 0 fakerotate 0 0 0 floor 0 height 0 radius 0 range 0 0 1 1 target 2
	ikrule "lfoot" release contact 0 fakeorigin 0 0 0 fakerotate 0 0 0 floor 0 height 0 radius 0 range 0 0 1 1 target 3
}

$sequence "proportions" { // fixes bone locations to better resemble a woman character without altering original mesh 
	"a_proportions"
	autoplay
	predelta
	snap 
}

$sequence "inverse_proportions" { // reverses bone manipulations added with "a_proportions" for raven animations 
	"a_inverse_proportions"
	predelta
	snap
}

$sequence "ragdoll" {
	"sbravenpm_anims\ragdoll.smd"
	activity "ACT_DIERAGDOLL" 1
	fadein 1
	fadeout 1
	fps 1
} 

$include "sbravenpm_shared.qci"
$include "sbravenpm_anims_rootmotion.qci"
//$include "c_knife_anims.qci" 

// animations to override / delete from includemodels 
$sequence "range_knife_1" "sbravenpm_anims\reference.smd" noanimation 
$sequence "range_knife_2" "sbravenpm_anims\reference.smd" noanimation 
$sequence "walk_physgun_1" "sbravenpm_anims\reference.smd" noanimation 
$sequence "run_physgun_1" "sbravenpm_anims\reference.smd" noanimation 
$sequence "walk_pistol_1" "sbravenpm_anims\reference.smd" noanimation 
$sequence "run_pistol_1" "sbravenpm_anims\reference.smd" noanimation 
$sequence "jump_holding_land" "sbravenpm_anims\reference.smd" noanimation 

$sequence "idle_knife" "sbravenpm_anims\m_raven_battleidle01.smd" { 
	fps 60 
	activity ACT_HL2MP_IDLE_KNIFE 9999 
	origin 0 0 42 
	fadein 0.6
	fadeout 0.6 
	cmdlist lockfeet
	addlayer inverse_proportions
	
	fudgeloop 
} 

$sequence "walk_knife" {
	"a_walking_walk_cautious_SW"  // row 1 col 1 (SW slot → backward)
	"a_walking_walk_cautious_S"  // row 1 col 2 (S slot)
	"a_walking_walk_cautious_SE"  // row 1 col 3 (SE slot)

	"a_walking_walk_cautious_W"  // row 2 col 1 (W slot)
	"a_walking_walk_cautious_C"  // row 2 col 2 (Center still)
	"a_walking_walk_cautious_E"  // row 2 col 3 (E slot)

	"a_walking_walk_cautious_NW"  // row 3 col 1 (NW slot)
	"a_walking_walk_cautious_N"  // row 3 col 2 (N slot → forward)
	"a_walking_walk_cautious_NE"  // row 3 col 3 (NE slot)
	
	activity "ACT_HL2MP_WALK_KNIFE" 1
	blend "move_y" 1 -1
	blend "move_x" -1 1
	blendwidth 3
	fadein 0.7
	fadeout 0.7
	addlayer inverse_proportions
	
	LX LY 
	node "walking" 
	fudgeloop 
	{ event 6008 10 "" }
	{ event 6009 28 "" }
} 

$sequence "walk_knife_1" {
	"a_walking_walk_cautious_SW"  // row 1 col 1 (SW slot → backward)
	"a_walking_walk_cautious_S"  // row 1 col 2 (S slot)
	"a_walking_walk_cautious_SE"  // row 1 col 3 (SE slot)

	"a_walking_walk_cautious_W"  // row 2 col 1 (W slot)
	"a_walking_walk_cautious_C"  // row 2 col 2 (Center still)
	"a_walking_walk_cautious_E"  // row 2 col 3 (E slot)

	"a_walking_walk_cautious_NW"  // row 3 col 1 (NW slot)
	"a_walking_walk_cautious_N"  // row 3 col 2 (N slot → forward)
	"a_walking_walk_cautious_NE"  // row 3 col 3 (NE slot)
	
	activity "ACT_HL2MP_WALK_KNIFE" 1
	blend "move_y" 1 -1
	blend "move_x" -1 1
	blendwidth 3
	fadein 0.7
	fadeout 0.7
	addlayer inverse_proportions
	
	LX LY 
	node "walking" 
	fudgeloop 
	{ event 6008 10 "" }
	{ event 6009 28 "" }
} 

$sequence "run_knife" {
	"a_running_run_cautious_SW"  // row 1 col 1 (SW slot → backward)
	"a_running_run_cautious_S"  // row 1 col 2 (S slot)
	"a_running_run_cautious_SE"  // row 1 col 3 (SE slot)

	"a_running_run_cautious_W"  // row 2 col 1 (W slot)
	"a_running_run_cautious_C"  // row 2 col 2 (Center still)
	"a_running_run_cautious_E"  // row 2 col 3 (E slot)

	"a_running_run_cautious_NW"  // row 3 col 1 (NW slot)
	"a_running_run_cautious_N"  // row 3 col 2 (N slot → forward)
	"a_running_run_cautious_NE"  // row 3 col 3 (NE slot)
	
	activity "ACT_HL2MP_RUN_KNIFE" 1
	blend "move_y" 1 -1
	blend "move_x" -1 1
	blendwidth 3
	fadein 0.3
	fadeout 0.3
	addlayer inverse_proportions
	
	LX LY 
	node "running" 
	fudgeloop 
	{ event 6009 8 "" }
	{ event 6008 18 "" }
} 

$sequence "run_knife_1" {
	"a_running_run_cautious_SW"  // row 1 col 1 (SW slot → backward)
	"a_running_run_cautious_S"  // row 1 col 2 (S slot)
	"a_running_run_cautious_SE"  // row 1 col 3 (SE slot)

	"a_running_run_cautious_W"  // row 2 col 1 (W slot)
	"a_running_run_cautious_C"  // row 2 col 2 (Center still)
	"a_running_run_cautious_E"  // row 2 col 3 (E slot)

	"a_running_run_cautious_NW"  // row 3 col 1 (NW slot)
	"a_running_run_cautious_N"  // row 3 col 2 (N slot → forward)
	"a_running_run_cautious_NE"  // row 3 col 3 (NE slot)
	
	activity "ACT_HL2MP_RUN_KNIFE" 1
	blend "move_y" 1 -1
	blend "move_x" -1 1
	blendwidth 3
	fadein 0.3
	fadeout 0.3
	addlayer inverse_proportions
	
	LX LY 
	node "running" 
	fudgeloop 
	{ event 6009 8 "" }
	{ event 6008 18 "" }
} 

$sequence "Idle_subtle" { // frames 37 
	"a_eve_WalkC"
	fps 30 
	activity ACT_IDLE 1 
	fadein 0.3
	fadeout 0.3
	addlayer inverse_proportions
	
	LX LY 
	node "standing" 
	loop 
} 

$sequence "idle_all_01" { // frames 37 
	"a_eve_WalkC"
	fps 30 
	activity ACT_HL2MP_IDLE 1 
	fadein 0.3
	fadeout 0.3
	addlayer inverse_proportions
	
	LX LY 
	node "standing" 
	loop 
} 