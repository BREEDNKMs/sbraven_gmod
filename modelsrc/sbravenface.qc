// Created by Crowbar 0.74

$ambientboost // please always include this into your player models and arm models
$modelname "alvaroports/SBRavenface.mdl"

$model head "head_2.smd" {

	eyeball righteye "ValveBiped.Bip01_Head1" -1.23759 -2.507 67.4045 "Eye_r" 1 4 "pupil_r" 1.2
	eyeball lefteye "ValveBiped.Bip01_Head1" 1.23759 -2.507 67.4045 "Eye_l" 1 -4 "pupil_l" 1.2
	flexcontroller eyes range -45 45 eyes_updown
	flexcontroller eyes range -45 45 eyes_rightleft

	eyelid  upper_right "head" lowerer 1 -0.2347 neutral 0 0.1514 raiser 2 0.2382 split 0.1 eyeball righteye
	eyelid  lower_right "head" lowerer 3 -0.2854 neutral 0 -0.2327 raiser 4 -0.1032 split 0.1 eyeball righteye
	eyelid  upper_left "head" lowerer 1 -0.2255 neutral 0 0.1352 raiser 2 0.2083 split -0.1 eyeball lefteye
	eyelid  lower_left "head" lowerer 3 -0.3361 neutral 0 -0.2525 raiser 4 -0.1341 split -0.1 eyeball lefteye

	mouth 0 "mouth" "ValveBiped.Bip01_Head1" 0 1 0		// mouth illumination

//	flexfile "Alyx_expressions-2-5" {
//		$include "standardflex_xsi.qci"
//	}

//	$include "facerules_v3.qci"
//	$include "Bodyrules_xsi.qci"
}


$surfaceprop "flesh"

$contents "solid" 
$mostlyopaque

$cdmaterials "models\alvaroports\SBRaven\" 
$cdmaterials "models\alvaroports\shared\" 

$attachment "forward" "ValveBiped.Bip01_Head1" 0 0 0 rotate 0 0 0
$attachment "eyes" "ValveBiped.Bip01_Head1" 0.0065 -2.9331 65.2068 absolute

$sequence "ragdoll" "sbravenpm_anims\ragdoll.smd" noanimation 


