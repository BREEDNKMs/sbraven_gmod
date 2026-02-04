// Created by Crowbar 0.74

$ambientboost // please always include this into your player models and arm models
$modelname "alvaroports/SBRavenPM.mdl"

$model head "head_2.smd" {

	eyeball righteye "ValveBiped.Bip01_Head1" -1.23759 -2.507 67.4045 "Eye_r" 1 4 "pupil_r" 1.2
	eyeball lefteye "ValveBiped.Bip01_Head1" 1.23759 -2.507 67.4045 "Eye_l" 1 -4 "pupil_l" 1.2
	flexcontroller eyes range -45 45 eyes_updown
	flexcontroller eyes range -45 45 eyes_rightleft
	
	eyelid  upper_right "head" lowerer 1 -0.2347 neutral 0 0.1514 raiser 2 0.2382 split 0.1 eyeball righteye
	eyelid  lower_right "head" lowerer 3 -0.2854 neutral 0 -0.2327 raiser 4 -0.1032 split 0.1 eyeball righteye
	eyelid  upper_left "head" lowerer 1 -0.2255 neutral 0 0.1352 raiser 2 0.2083 split -0.1 eyeball lefteye
	eyelid  lower_left "head" lowerer 3 -0.3361 neutral 0 -0.2525 raiser 4 -0.1341 split -0.1 eyeball lefteye

//	eyelid  upper_right "alyx_expressions-2-5" lowerer 1 -0.2347 neutral 0 0.1514 raiser 2 0.2382 split 0.1 eyeball righteye
//	eyelid  lower_right "alyx_expressions-2-5" lowerer 3 -0.2854 neutral 0 -0.2327 raiser 4 -0.1032 split 0.1 eyeball lefteye
//	eyelid  upper_left "alyx_expressions-2-5" lowerer 1 -0.2255 neutral 0 0.1352 raiser 2 0.2083 split -0.1 eyeball lefteye
//	eyelid  lower_left "alyx_expressions-2-5" lowerer 3 -0.3361 neutral 0 -0.2525 raiser 4 -0.1341 split -0.1 eyeball lefteye

	mouth 0 "mouth" "ValveBiped.Bip01_Head1" 0 1 0		// mouth illumination

	flexfile "head" {
		$include "standardflex_v3.qci"
	}

	$include "facerules_v3.qci"
//	$include "Bodyrules_xsi.qci"
}

$bodygroup "body"
{
	studio "Body.smd"
	blank
}
//$bodygroup "head"
//{
//	studio "head.smd"
//	blank
//}
$bodygroup "hair"
{
	studio "hair.smd"
	blank
}
$bodygroup "hair2"
{
	studio "hair_2.smd"
	blank
}
$bodygroup "hair3"
{
	studio "hair_3.smd"
	blank
}
$bodygroup "Heels"
{
	studio "Heels.smd"
	blank
}
$bodygroup "Neck Guard"
{
	studio "Neck_Guard.smd"
	blank
}
$bodygroup "Forearm Guards"
{
	studio "Forearm_Guards.smd"
	blank
}
$bodygroup "Armor"
{
	studio "Armor.smd"
	blank
}
$bodygroup "Armor 2"
{
	studio "Armor2.smd"
	blank
}
$bodygroup "RavensuitVinyl_Blur"
{
	studio "RavensuitVinyl_Blur.smd"
	blank
}
$bodygroup "Suit"
{
	studio "Suit.smd"
	blank
}

$surfaceprop "flesh"

$contents "solid" 
$mostlyopaque

$cdmaterials "models\alvaroports\SBRaven\" 
$cdmaterials "models\alvaroports\shared\" 
$cdmaterials "models\alyx\" 

$proceduralbones "alyx.vrd"
$include "../../sourcesdk_content/gm_playermodel_examples/Humans/Standardhierarchy.qci"                
$alwayscollapse "ValveBiped"                
$alwayscollapse "XSISceneRoot"                
$include "../../sourcesdk_content/gm_playermodel_examples/Humans/standardikchains.qci"                
//$include "../../sourcesdk_content/gm_playermodel_examples/Humans/female/commonbones.qci"      

$attachment "forward" "ValveBiped.Bip01_Head1" 0.0 0.0 0.0 rotate 0 -80 -90
//$attachment "anim_attachment_RH" "ValveBiped.Anim_Attachment_RH" 0 0 0 rotate -90 -90 0
//$attachment "anim_attachment_LH" "ValveBiped.Anim_Attachment_LH" 0 0 0 rotate -90 -90 0
$attachment "anim_attachment_head" "ValveBiped.Bip01_Head1" 0 0 0 rotate -90 -90 0
$attachment "lefteye" "ValveBiped.Bip01_Head1"  1.3 -2.93 67.2 absolute
$attachment "righteye" "ValveBiped.Bip01_Head1"  -1.31 -2.93 67.2 absolute
$attachment "nose" "ValveBiped.Bip01_Head1" 1.70 -5.3 0.00 rotate 0 -80 -90
$attachment "mouth" "ValveBiped.Bip01_Head1" 0.20 -4.90 0.00 rotate 0 -80 -90
$attachment "amulet" "ValveBiped.Bip01_Spine4"  0.30 5.00 0.00 rotate 0 90 90
$attachment "chest" "ValveBiped.Bip01_Spine4" -4.00 4.00 0.00 rotate 0 83 90
$attachment "hips" "ValveBiped.Bip01_Pelvis" -0.00 0.00 -0.00 rotate -90 -90 0
$attachment "lefthand" "ValveBiped.Bip01_L_Hand" 3.50 -0.50 0.00 rotate -0 -0 0
$attachment "righthand" "ValveBiped.Bip01_R_Hand" 3.50 -0.50 0.00 rotate 0 0 0
$attachment "pouch1" "ValveBiped.Bip01_Pelvis" 5.50 1.00 2.00 rotate -90 -90 0
$attachment "pouch2" "ValveBiped.Bip01_Pelvis" 6.50 0.50 -2.00 rotate -90 -90 0
//$attachment "physgun_attachment" "valvebiped.physgun_attachment" 0 0 0 rotate -90 0 -90
$attachment "emp" "ValveBiped.Bip01_R_Hand" 0.00 0.00 5.00 rotate -90 0 -90
$attachment "emp_LH" "ValveBiped.Bip01_L_Hand" 0.00 0.00 5.00 rotate -90 0 -90
$attachment "Emp_Holster" "ValveBiped.Bip01_Pelvis" 0 0 0 rotate -90 0 -90
//$attachment "gun" "valvebiped.weapon_bone" 0 0 0
$attachment	"R_shoulderBladeAim" "ValveBiped.Bip01_Spine"	2.621	-2.0003	-3.2233	rotate	0.0000	0.0000	0.0000
$attachment	"L_shoulderBladeAim" "ValveBiped.Bip01_Spine"	2.621	-2.0003	3.1509	rotate	0.0000	0.0000	0.0000

$attachment "Root" "ValveBiped.Bip01_Pelvis" -0.00 -41.99 -0.44 rotate 180.00 0.00 90.00
$attachment "Bip001" "ValveBiped.Bip01_Pelvis" -0.00 -0.00 0.00 rotate 0 0 0
$attachment "ValveBiped.Bip01_Pelvis" "ValveBiped.Bip01_Pelvis" -0.00 -0.00 0.00 rotate 0 0 0
$attachment "ValveBiped.Bip01_Spine" "ValveBiped.Bip01_Spine" -0.00 -0.00 0.00 rotate 0 0 0
$attachment "ValveBiped.Bip01_Spine1" "ValveBiped.Bip01_Spine1" -0.00 -0.00 0.00 rotate 0 0 0
$attachment "ValveBiped.Bip01_Spine2" "ValveBiped.Bip01_Spine2" -0.00 -0.00 0.00 rotate 0 0 0
$attachment "ValveBiped.Bip01_Neck1" "ValveBiped.Bip01_Neck1" -0.00 -0.00 0.00 rotate 0 0 0
$attachment "ValveBiped.Bip01_L_Clavicle" "ValveBiped.Bip01_L_Clavicle" -0.00 -0.00 0.00 rotate 0 0 0
$attachment "ValveBiped.Bip01_L_UpperArm" "ValveBiped.Bip01_L_UpperArm" -0.00 -0.00 0.00 rotate 0 0 0
$attachment "ValveBiped.Bip01_L_Forearm" "ValveBiped.Bip01_L_Forearm" -0.00 -0.00 0.00 rotate 0 0 0
$attachment "ValveBiped.Bip01_L_Hand" "ValveBiped.Bip01_L_Hand" -0.00 -0.00 0.00 rotate 0 0 0
$attachment "ValveBiped.Bip01_L_Finger0" "ValveBiped.Bip01_L_Finger0" -0.00 -0.00 0.00 rotate 0 0 0
$attachment "ValveBiped.Bip01_L_Finger01" "ValveBiped.Bip01_L_Finger01" -0.00 -0.00 0.00 rotate 0 0 0
$attachment "ValveBiped.Bip01_L_Finger02" "ValveBiped.Bip01_L_Finger02" -0.00 -0.00 0.00 rotate 0 0 0
$attachment "ValveBiped.Bip01_L_Finger1" "ValveBiped.Bip01_L_Finger1" -0.00 -0.00 0.00 rotate 0 0 0
$attachment "ValveBiped.Bip01_L_Finger11" "ValveBiped.Bip01_L_Finger11" -0.00 -0.00 0.00 rotate 0 0 0
$attachment "ValveBiped.Bip01_L_Finger12" "ValveBiped.Bip01_L_Finger12" -0.00 -0.00 0.00 rotate 0 0 0	
$attachment "ValveBiped.Bip01_L_Finger2" "ValveBiped.Bip01_L_Finger2" -0.00 -0.00 0.00 rotate 0 0 0
$attachment "ValveBiped.Bip01_L_Finger21" "ValveBiped.Bip01_L_Finger21" -0.00 -0.00 0.00 rotate 0 0 0
$attachment "ValveBiped.Bip01_L_Finger22" "ValveBiped.Bip01_L_Finger22" -0.00 -0.00 0.00 rotate 0 0 0
$attachment "ValveBiped.Bip01_L_Finger3" "ValveBiped.Bip01_L_Finger3" -0.00 -0.00 0.00 rotate 0 0 0
$attachment "ValveBiped.Bip01_L_Finger31" "ValveBiped.Bip01_L_Finger31" -0.00 -0.00 0.00 rotate 0 0 0
$attachment "ValveBiped.Bip01_L_Finger32" "ValveBiped.Bip01_L_Finger32" -0.00 -0.00 0.00 rotate 0 0 0
$attachment "ValveBiped.Bip01_L_Finger4" "ValveBiped.Bip01_L_Finger4" -0.00 -0.00 0.00 rotate 0 0 0
$attachment "ValveBiped.Bip01_L_Finger41" "ValveBiped.Bip01_L_Finger41" -0.00 -0.00 0.00 rotate 0 0 0
$attachment "ValveBiped.Bip01_L_Finger42" "ValveBiped.Bip01_L_Finger42" -0.00 -0.00 0.00 rotate 0 0 0
$attachment "SC_BurstStanceConstraint" "ValveBiped.Bip01_L_Hand" -4.28 4.51 1.47 rotate -81.41 -11.43 -25.38
$attachment "Ab-L-Forearm-Tw0" "ValveBiped.Bip01_L_Forearm" -0.00 6.81 0.00 rotate -0.00 -72.51 0.00
$attachment "Ab-L-Forearm-Tw1" "ValveBiped.Bip01_L_Forearm" -0.00 3.43 0.00 rotate -0.00 -84.04 0.00
$attachment "Dm-L-BrochiDn" "ValveBiped.Bip01_L_Forearm" -0.00 -0.00 -0.90 rotate 0.00 0.00 -0.00
$attachment "Ab-L-BrochiDn" "ValveBiped.Bip01_L_Forearm" -0.00 -0.00 -0.92 rotate 0.00 0.00 -0.00
$attachment "Ab_Drone_Ctl" "ValveBiped.Bip01_L_Forearm" -0.00 10.24 0.00 rotate -69.94 59.54 7.57
$attachment "Dm-L-UpperArm-Tw" "ValveBiped.Bip01_L_UpperArm" -0.00 0.00 0.00 rotate -0.00 -10.04 -0.00
$attachment "Dm-L-Becep" "ValveBiped.Bip01_L_UpperArm" 0.00 0.00 0.00 rotate -0.00 -10.04 -0.00
$attachment "Ab-L-Becep" "ValveBiped.Bip01_L_UpperArm" 0.00 0.00 0.00 rotate 0.00 -10.04 -0.00
$attachment "Ab-L-UpperArm-Tw1" "ValveBiped.Bip01_L_UpperArm" -0.00 3.45 -0.00 rotate -0.00 -5.02 -0.00
$attachment "Ab-L-UpperArm-Tw0" "ValveBiped.Bip01_L_UpperArm" -0.00 -0.00 0.00 rotate -0.00 -8.03 -0.00
$attachment "Dm-L-Deltoid-A" "ValveBiped.Bip01_L_UpperArm" -0.00 0.00 0.00 rotate -3.69 -5.94 -20.30
$attachment "Dm-L-Deltoid-Point" "ValveBiped.Bip01_L_UpperArm" 0.14 -2.19 0.34 rotate 18.76 94.44 -0.43
$attachment "Ab-L-Deltoid" "ValveBiped.Bip01_L_UpperArm" 0.14 -2.19 0.34 rotate 18.76 94.44 -0.43
$attachment "Dm-L-Elbow-Point" "ValveBiped.Bip01_L_UpperArm" -0.00 10.24 -0.00 rotate -13.31 0.00 0.00
$attachment "Dm-L-Elbow" "ValveBiped.Bip01_L_UpperArm" -0.00 10.24 -0.00 rotate -16.66 0.00 0.00
$attachment "Ab-L-Elbow" "ValveBiped.Bip01_L_UpperArm" -0.00 10.25 0.00 rotate 74.18 0.41 -0.07
$attachment "Dm-L-BrochiUp" "ValveBiped.Bip01_L_UpperArm" -0.03 9.89 -0.89 rotate -0.00 -5.84 0.00
$attachment "Ab-L-BrochiUp" "ValveBiped.Bip01_L_UpperArm" -0.03 9.85 -0.89 rotate 0.00 174.16 0.00
$attachment "Ab-L-Tricep" "ValveBiped.Bip01_L_UpperArm" -0.00 6.81 -0.00 rotate 0.00 -0.00 0.00
$attachment "Dm-L-Side-Point" "ValveBiped.Bip01_L_Clavicle" 0.00 3.83 -0.00 rotate 3.42 -0.30 94.97
$attachment "Ab-L-Side" "ValveBiped.Bip01_L_Clavicle" 0.00 3.83 -0.00 rotate 3.42 -0.30 94.97
$attachment "Ab-L-Shoulder1" "ValveBiped.Bip01_L_Clavicle" -0.29 4.39 2.00 rotate 14.26 15.54 140.67
$attachment "ValveBiped.Bip01_R_Clavicle" "ValveBiped.Bip01_R_Clavicle" -0.00 -0.00 0.00 rotate 0 0 0
$attachment "ValveBiped.Bip01_R_UpperArm" "ValveBiped.Bip01_R_UpperArm" -0.00 -0.00 0.00 rotate 0 0 0
$attachment "ValveBiped.Bip01_R_Forearm" "ValveBiped.Bip01_R_Forearm" -0.00 -0.00 0.00 rotate 0 0 0
$attachment "ValveBiped.Bip01_R_Hand" "ValveBiped.Bip01_R_Hand" -0.00 -0.00 0.00 rotate 0 0 0
$attachment "ValveBiped.Bip01_R_Finger0" "ValveBiped.Bip01_R_Finger0" -0.00 -0.00 0.00 rotate 0 0 0
$attachment "ValveBiped.Bip01_R_Finger01" "ValveBiped.Bip01_R_Finger01" -0.00 -0.00 0.00 rotate 0 0 0
$attachment "ValveBiped.Bip01_R_Finger02" "ValveBiped.Bip01_R_Finger02" -0.00 -0.00 0.00 rotate 0 0 0
$attachment "ValveBiped.Bip01_R_Finger1" "ValveBiped.Bip01_R_Finger1" -0.00 -0.00 0.00 rotate 0 0 0
$attachment "ValveBiped.Bip01_R_Finger11" "ValveBiped.Bip01_R_Finger11" -0.00 -0.00 0.00 rotate 0 0 0
$attachment "ValveBiped.Bip01_R_Finger12" "ValveBiped.Bip01_R_Finger12" -0.00 -0.00 0.00 rotate 0 0 0
$attachment "ValveBiped.Bip01_R_Finger2" "ValveBiped.Bip01_R_Finger2" -0.00 -0.00 0.00 rotate 0 0 0
$attachment "ValveBiped.Bip01_R_Finger21" "ValveBiped.Bip01_R_Finger21" -0.00 -0.00 0.00 rotate 0 0 0
$attachment "ValveBiped.Bip01_R_Finger22" "ValveBiped.Bip01_R_Finger22" -0.00 -0.00 0.00 rotate 0 0 0
$attachment "ValveBiped.Bip01_R_Finger3" "ValveBiped.Bip01_R_Finger3" -0.00 -0.00 0.00 rotate 0 0 0
$attachment "ValveBiped.Bip01_R_Finger31" "ValveBiped.Bip01_R_Finger31" -0.00 -0.00 0.00 rotate 0 0 0
$attachment "ValveBiped.Bip01_R_Finger32" "ValveBiped.Bip01_R_Finger32" -0.00 -0.00 0.00 rotate 0 0 0
$attachment "ValveBiped.Bip01_R_Finger4" "ValveBiped.Bip01_R_Finger4" -0.00 -0.00 0.00 rotate 0 0 0
$attachment "ValveBiped.Bip01_R_Finger41" "ValveBiped.Bip01_R_Finger41" -0.00 -0.00 0.00 rotate 0 0 0
$attachment "ValveBiped.Bip01_R_Finger42" "ValveBiped.Bip01_R_Finger42" -0.00 -0.00 0.00 rotate 0 0 0
$attachment "SC_WeaponConstraint" "ValveBiped.Bip01_R_Hand" -0.00 2.47 1.10 rotate 20.57 15.05 -3.05
$attachment "Ab-R-Forearm-Tw0" "ValveBiped.Bip01_R_Forearm" -0.00 6.81 0.00 rotate 0.00 72.51 0.00
$attachment "Ab-R-Forearm-Tw1" "ValveBiped.Bip01_R_Forearm" 0.00 3.43 0.00 rotate 0.00 84.75 0.00
$attachment "Dm-R-BrochiDn" "ValveBiped.Bip01_R_Forearm" -0.00 -0.00 -0.90 rotate 0.00 0.00 0.00
$attachment "Ab-R-BrochiDn" "ValveBiped.Bip01_R_Forearm" -0.00 -0.00 -0.92 rotate 0.00 0.00 0.00
$attachment "Dm-R-Elbow-Point" "ValveBiped.Bip01_R_UpperArm" 0.00 10.24 0.00 rotate -13.31 -0.00 -0.00
$attachment "Dm-R-Elbow" "ValveBiped.Bip01_R_UpperArm" 0.00 10.24 -0.00 rotate -16.66 -0.00 -0.00
$attachment "Ab-R-Elbow" "ValveBiped.Bip01_R_UpperArm" 0.00 10.25 0.00 rotate 74.27 -0.00 -0.00
$attachment "Dm-R-BrochiUp" "ValveBiped.Bip01_R_UpperArm" 0.03 9.89 -0.89 rotate 0.01 5.86 -0.03
$attachment "Ab-R-BrochiUp" "ValveBiped.Bip01_R_UpperArm" 0.03 9.85 -0.89 rotate -0.01 -174.14 -0.03
$attachment "Dm-R-UpperArm-Tw" "ValveBiped.Bip01_R_UpperArm" -0.00 0.00 0.00 rotate 0.00 10.04 -0.00
$attachment "Dm-R-Becep" "ValveBiped.Bip01_R_UpperArm" -0.00 0.00 0.00 rotate 0.00 10.04 -0.00
$attachment "Ab-R-Becep" "ValveBiped.Bip01_R_UpperArm" -0.00 0.00 0.00 rotate 0.00 10.04 -0.00
$attachment "Ab-R-UpperArm-Tw0" "ValveBiped.Bip01_R_UpperArm" -0.00 0.00 0.00 rotate -0.00 8.03 -0.00
$attachment "Ab-R-UpperArm-Tw1" "ValveBiped.Bip01_R_UpperArm" 0.00 3.43 0.00 rotate 0.00 5.02 -0.00
$attachment "Ab-R-Tricep" "ValveBiped.Bip01_R_UpperArm" 0.00 6.81 0.00 rotate -0.00 -0.00 0.00
$attachment "Dm-R-Deltoid-A" "ValveBiped.Bip01_R_UpperArm" -0.00 0.00 0.00 rotate -3.69 5.94 20.30
$attachment "Dm-R-Deltoid-Point" "ValveBiped.Bip01_R_UpperArm" -0.14 -2.19 0.34 rotate -161.24 -94.44 0.43
$attachment "Ab-R-Deltoid" "ValveBiped.Bip01_R_UpperArm" -0.14 -2.19 0.34 rotate -161.24 -94.44 0.43
$attachment "Dm-R-Side-Point" "ValveBiped.Bip01_R_Clavicle" -0.00 3.83 -0.00 rotate 3.36 0.30 -94.97
$attachment "Ab-R-Side" "ValveBiped.Bip01_R_Clavicle" -0.00 3.83 -0.00 rotate 3.36 0.30 -94.97
$attachment "Ab-R-Shoulder1" "ValveBiped.Bip01_R_Clavicle" 0.30 4.39 2.00 rotate 14.22 -15.59 -140.66
$attachment "ValveBiped.Bip01_Head1" "ValveBiped.Bip01_Head1" -0.00 -0.00 0.00 rotate 0 0 0
$attachment "HBn_Root" "ValveBiped.Bip01_Head1" 0.00 -0.00 0.00 rotate 0.00 -0.00 0.00
$attachment "HBN_CK01" "ValveBiped.Bip01_Head1" -0.61 2.41 -3.11 rotate -165.63 4.38 3.15
$attachment "HBN_CK02" "ValveBiped.Bip01_Head1" -0.40 -3.38 -4.59 rotate -164.85 2.76 2.75
$attachment "HBN_CK03" "ValveBiped.Bip01_Head1" -0.17 -9.97 -6.37 rotate -168.47 5.20 1.74
$attachment "HBN_CK04" "ValveBiped.Bip01_Head1" -0.09 -16.71 -7.74 rotate -169.62 5.90 3.37
$attachment "HBN_CK05" "ValveBiped.Bip01_Head1" 0.18 -23.52 -8.98 rotate -172.06 16.05 7.86
$attachment "HBN_CK06" "ValveBiped.Bip01_Head1" 0.93 -31.02 -9.99 rotate -164.45 32.74 13.45
$attachment "HBN_CK07" "ValveBiped.Bip01_Head1" 1.59 -38.82 -11.80 rotate -142.81 45.93 23.88
$attachment "HBN_CK08" "ValveBiped.Bip01_Head1" 1.08 -45.08 -14.71 rotate -103.03 41.31 51.06
$attachment "HBN_CK09" "ValveBiped.Bip01_Head1" -0.13 -48.48 -18.59 rotate -81.20 20.77 51.17
$attachment "FX_RavenHairEnd_1" "ValveBiped.Bip01_Head1" -1.82 -49.36 -23.18 rotate -81.20 20.77 51.17
$attachment "HBn_LF01" "ValveBiped.Bip01_Head1" 2.65 3.89 2.11 rotate 9.09 -67.19 175.79
$attachment "HBn_LF02" "ValveBiped.Bip01_Head1" 2.94 -0.04 2.35 rotate 33.24 -56.59 159.35
$attachment "HBn_LF03" "ValveBiped.Bip01_Head1" 3.48 -3.89 3.59 rotate 39.62 -52.58 163.23
$attachment "HBn_LF04" "ValveBiped.Bip01_Head1" 4.64 -7.79 5.29 rotate 10.10 -55.26 -176.01
$attachment "HBn_LF05" "ValveBiped.Bip01_Head1" 5.54 -11.89 5.72 rotate 25.46 -46.00 122.11
$attachment "HBn_LF06" "ValveBiped.Bip01_Head1" 3.40 -14.53 6.78 rotate 27.24 -35.38 79.39
$attachment "HBN_LMA01" "ValveBiped.Bip01_Head1" 2.96 3.37 -1.32 rotate -167.89 -60.46 3.60
$attachment "HBN_LMA02" "ValveBiped.Bip01_Head1" 4.37 -2.23 -1.92 rotate -149.72 -52.98 -5.94
$attachment "HBN_LMA03" "ValveBiped.Bip01_Head1" 6.42 -8.17 -3.92 rotate 178.08 -44.31 26.92
$attachment "HBN_LMA04" "ValveBiped.Bip01_Head1" 9.33 -14.26 -3.76 rotate 171.53 -48.26 34.02
$attachment "HBN_LMA05" "ValveBiped.Bip01_Head1" 12.29 -19.89 -3.13 rotate 176.55 -58.14 14.25
$attachment "HBN_LMA06" "ValveBiped.Bip01_Head1" 13.66 -26.72 -2.91 rotate -152.28 -81.32 -8.75
$attachment "HBN_LMA07" "ValveBiped.Bip01_Head1" 15.71 -32.77 -3.36 rotate -10.94 -80.52 -141.79
$attachment "HBN_LMA08" "ValveBiped.Bip01_Head1" 18.71 -38.55 -3.57 rotate -142.77 -103.45 14.64
$attachment "HBN_LMA09" "ValveBiped.Bip01_Head1" 22.65 -41.73 -2.85 rotate -121.53 -112.01 16.48
$attachment "FX_RavenHairEnd_2" "ValveBiped.Bip01_Head1" 26.46 -42.90 -1.51 rotate -121.53 -112.01 16.48
$attachment "HBN_LMB01" "ValveBiped.Bip01_Head1" 1.09 0.77 -2.01 rotate -167.69 -19.68 12.89
$attachment "HBN_LMB02" "ValveBiped.Bip01_Head1" 3.27 -6.30 -3.53 rotate 178.04 -19.21 14.96
$attachment "HBN_LMB03" "ValveBiped.Bip01_Head1" 5.03 -13.23 -3.30 rotate -167.84 -22.79 24.07
$attachment "HBN_LMB04" "ValveBiped.Bip01_Head1" 8.46 -19.46 -4.71 rotate -172.51 -6.70 24.56
$attachment "HBN_LMB05" "ValveBiped.Bip01_Head1" 11.23 -25.27 -5.55 rotate -173.23 22.14 25.08
$attachment "HBN_LMB06" "ValveBiped.Bip01_Head1" 13.96 -31.86 -6.33 rotate -176.38 57.96 15.11
$attachment "HBN_LMB07" "ValveBiped.Bip01_Head1" 15.45 -38.86 -6.57 rotate -51.02 96.98 112.66
$attachment "HBN_LMB08" "ValveBiped.Bip01_Head1" 13.45 -45.62 -5.90 rotate -155.04 100.65 -8.36
$attachment "FX_RavenHairEnd_3" "ValveBiped.Bip01_Head1" 10.31 -50.46 -5.45 rotate -155.04 100.65 -8.36
$attachment "HBN_LMC01" "ValveBiped.Bip01_Head1" 2.84 1.35 -0.10 rotate -98.75 -73.31 -76.19
$attachment "HBN_LMC02" "ValveBiped.Bip01_Head1" 3.37 -5.15 -2.03 rotate -179.00 -64.71 12.69
$attachment "HBN_LMC03" "ValveBiped.Bip01_Head1" 4.90 -11.47 -2.08 rotate -178.08 -57.08 9.10
$attachment "HBN_LMC04" "ValveBiped.Bip01_Head1" 6.02 -17.39 -2.19 rotate -177.37 -52.41 10.50
$attachment "HBN_LMC05" "ValveBiped.Bip01_Head1" 7.51 -24.08 -2.39 rotate 168.49 -45.89 28.91
$attachment "HBN_LMC06" "ValveBiped.Bip01_Head1" 10.06 -30.86 -1.37 rotate 162.32 -53.80 38.36
$attachment "HBN_LMC07" "ValveBiped.Bip01_Head1" 12.74 -36.89 -0.17 rotate 159.87 -62.67 31.31
$attachment "HBN_LMC08" "ValveBiped.Bip01_Head1" 14.23 -43.21 0.87 rotate -174.58 -66.01 -6.36
$attachment "HBN_LMC09" "ValveBiped.Bip01_Head1" 14.09 -48.65 0.66 rotate -179.07 -63.45 -11.57
$attachment "FX_RavenHairEnd_4" "ValveBiped.Bip01_Head1" 13.19 -53.42 0.63 rotate -179.07 -63.45 -11.57
$attachment "HBN_LMD01" "ValveBiped.Bip01_Head1" 1.02 0.12 -1.98 rotate -170.18 -5.18 0.55
$attachment "HBN_LMD02" "ValveBiped.Bip01_Head1" 1.17 -5.94 -3.03 rotate 176.73 -10.62 7.56
$attachment "HBN_LMD03" "ValveBiped.Bip01_Head1" 2.06 -13.26 -2.61 rotate -167.60 -13.31 9.90
$attachment "HBN_LMD04" "ValveBiped.Bip01_Head1" 3.72 -20.57 -4.21 rotate -179.19 -18.77 2.73
$attachment "HBN_LMD05" "ValveBiped.Bip01_Head1" 4.13 -28.41 -4.32 rotate -172.69 -33.43 6.86
$attachment "HBN_LMD06" "ValveBiped.Bip01_Head1" 5.56 -35.80 -5.12 rotate -166.03 -52.34 -2.89
$attachment "HBN_LMD07" "ValveBiped.Bip01_Head1" 6.55 -42.66 -6.16 rotate -124.75 -78.65 -45.25
$attachment "HBN_LMD08" "ValveBiped.Bip01_Head1" 7.66 -49.28 -7.26 rotate 7.37 -84.41 -173.74
$attachment "FX_RavenHairEnd_5" "ValveBiped.Bip01_Head1" 9.02 -54.91 -7.18 rotate 7.37 -84.41 -173.74
$attachment "HBN_LME01" "ValveBiped.Bip01_Head1" 2.08 2.59 -2.27 rotate -176.25 -23.36 11.47
$attachment "HBN_LME02" "ValveBiped.Bip01_Head1" 3.16 -2.11 -2.56 rotate -160.92 -18.71 -0.75
$attachment "HBN_LME03" "ValveBiped.Bip01_Head1" 3.65 -7.16 -4.21 rotate -178.04 -17.32 -4.54
$attachment "HBN_LME04" "ValveBiped.Bip01_Head1" 3.29 -12.42 -4.38 rotate -172.14 -31.83 -8.45
$attachment "HBN_LME05" "ValveBiped.Bip01_Head1" 2.89 -17.74 -5.01 rotate -167.00 -31.63 -3.28
$attachment "HBN_LME06" "ValveBiped.Bip01_Head1" 3.27 -23.71 -6.17 rotate -168.70 -32.52 4.78
$attachment "HBN_LME07" "ValveBiped.Bip01_Head1" 4.32 -29.20 -7.11 rotate -168.96 -27.20 12.55
$attachment "HBN_LME08" "ValveBiped.Bip01_Head1" 5.93 -34.25 -8.03 rotate -168.00 -31.47 20.88
$attachment "HBN_LME09" "ValveBiped.Bip01_Head1" 8.24 -38.75 -8.94 rotate -154.33 -39.47 20.16
$attachment "HBN_LME10" "ValveBiped.Bip01_Head1" 11.22 -42.68 -10.69 rotate -129.70 -48.75 19.53
$attachment "HBN_LME11" "ValveBiped.Bip01_Head1" 14.89 -44.66 -13.14 rotate -105.09 -52.54 6.70
$attachment "FX_RavenHairEnd_6" "ValveBiped.Bip01_Head1" 18.43 -45.41 -15.76 rotate -105.09 -52.54 6.70
$attachment "HBN_LMF01" "ValveBiped.Bip01_Head1" 1.54 2.61 -2.93 rotate -168.77 -22.42 1.19
$attachment "HBN_LMF02" "ValveBiped.Bip01_Head1" 2.10 -3.25 -4.01 rotate -166.27 -24.24 1.77
$attachment "HBN_LMF03" "ValveBiped.Bip01_Head1" 2.97 -9.85 -5.49 rotate -165.66 -5.93 2.76
$attachment "HBN_LMF04" "ValveBiped.Bip01_Head1" 3.55 -17.61 -7.46 rotate -160.77 -3.90 9.44
$attachment "HBN_LMF05" "ValveBiped.Bip01_Head1" 4.99 -25.16 -10.14 rotate -164.55 -5.07 1.73
$attachment "HBN_LMF06" "ValveBiped.Bip01_Head1" 5.38 -32.27 -12.10 rotate -157.61 41.27 7.83
$attachment "HBN_LMF07" "ValveBiped.Bip01_Head1" 4.47 -39.31 -14.22 rotate -123.52 52.44 50.67
$attachment "HBN_LMF08" "ValveBiped.Bip01_Head1" 4.53 -45.34 -17.78 rotate -129.02 53.80 58.56
$attachment "FX_RavenHairEnd_7" "ValveBiped.Bip01_Head1" 5.87 -50.85 -20.71 rotate -129.02 53.80 58.56
$attachment "HBn_RF01" "ValveBiped.Bip01_Head1" -2.64 3.89 2.11 rotate -174.98 -67.48 -7.67
$attachment "HBn_RF02" "ValveBiped.Bip01_Head1" -2.85 0.09 1.98 rotate 149.07 -62.25 14.38
$attachment "HBn_RF03" "ValveBiped.Bip01_Head1" -3.82 -3.96 3.01 rotate 164.23 -62.72 -14.79
$attachment "HBn_RF04" "ValveBiped.Bip01_Head1" -5.96 -7.83 3.57 rotate -167.93 -56.39 -23.91
$attachment "HBn_RF05" "ValveBiped.Bip01_Head1" -6.89 -11.62 3.11 rotate -19.07 -103.02 -139.16
$attachment "HBn_RFF01" "ValveBiped.Bip01_Head1" -2.12 3.68 3.62 rotate -166.90 -25.15 -5.68
$attachment "HBn_RFF02" "ValveBiped.Bip01_Head1" -2.12 -0.18 2.81 rotate 174.20 -23.54 -3.90
$attachment "HBn_RFF03" "ValveBiped.Bip01_Head1" -2.55 -4.11 3.18 rotate 144.20 -18.88 -13.91
$attachment "HBn_RFF04" "ValveBiped.Bip01_Head1" -4.06 -7.07 5.38 rotate -178.43 -15.73 -18.29
$attachment "HBn_RFF05" "ValveBiped.Bip01_Head1" -5.03 -10.08 5.30 rotate -166.42 -20.24 2.64
$attachment "HBn_RFF06" "ValveBiped.Bip01_Head1" -4.64 -13.06 4.62 rotate 161.27 -33.54 61.75
$attachment "HBN_RMA01" "ValveBiped.Bip01_Head1" -3.22 3.36 -1.07 rotate -35.29 -71.04 -158.71
$attachment "HBN_RMA02" "ValveBiped.Bip01_Head1" -4.45 -2.20 -2.16 rotate 152.54 -110.76 3.28
$attachment "HBN_RMA03" "ValveBiped.Bip01_Head1" -6.96 -8.21 -3.24 rotate 1.03 -57.97 149.62
$attachment "HBN_RMA04" "ValveBiped.Bip01_Head1" -10.54 -14.54 -3.17 rotate -2.40 -59.23 150.64
$attachment "HBN_RMA05" "ValveBiped.Bip01_Head1" -14.49 -21.00 -3.33 rotate -15.21 -52.88 165.09
$attachment "HBN_RMA06" "ValveBiped.Bip01_Head1" -17.52 -26.91 -4.40 rotate -48.00 -53.51 -167.79
$attachment "HBN_RMA07" "ValveBiped.Bip01_Head1" -20.26 -31.75 -7.13 rotate -35.01 -52.14 -166.76
$attachment "HBN_RMA08" "ValveBiped.Bip01_Head1" -21.72 -36.93 -9.16 rotate -2.86 -62.66 -172.05
$attachment "HBN_RMA09" "ValveBiped.Bip01_Head1" -21.19 -42.48 -9.29 rotate -133.10 -107.18 -23.83
$attachment "FX_RavenHairEnd_8" "ValveBiped.Bip01_Head1" -18.89 -48.23 -7.92 rotate -133.10 -107.18 -23.83
$attachment "HBN_RMB01" "ValveBiped.Bip01_Head1" -2.06 1.22 -1.76 rotate -14.12 -32.81 171.63
$attachment "HBN_RMB02" "ValveBiped.Bip01_Head1" -3.91 -5.18 -3.15 rotate 2.59 -30.00 159.71
$attachment "HBN_RMB03" "ValveBiped.Bip01_Head1" -6.03 -11.32 -2.90 rotate 9.35 -21.96 155.29
$attachment "HBN_RMB04" "ValveBiped.Bip01_Head1" -8.18 -16.88 -1.99 rotate -12.36 -22.89 164.35
$attachment "HBN_RMB05" "ValveBiped.Bip01_Head1" -10.54 -23.17 -3.34 rotate -10.68 -16.55 168.12
$attachment "HBN_RMB06" "ValveBiped.Bip01_Head1" -12.37 -30.01 -4.62 rotate 16.07 -30.54 160.40
$attachment "HBN_RMB07" "ValveBiped.Bip01_Head1" -13.67 -36.56 -2.98 rotate 17.16 -34.36 150.02
$attachment "HBN_RMB08" "ValveBiped.Bip01_Head1" -15.81 -42.41 -1.42 rotate -3.69 -30.22 140.24
$attachment "HBN_RMB09" "ValveBiped.Bip01_Head1" -19.23 -46.26 -1.70 rotate -34.19 -50.27 126.64
$attachment "FX_RavenHairEnd_9" "ValveBiped.Bip01_Head1" -23.17 -46.89 -3.24 rotate -34.19 -50.27 126.64
$attachment "HBN_RMC01" "ValveBiped.Bip01_Head1" -2.11 3.03 -2.67 rotate -6.00 -26.54 170.65
$attachment "HBN_RMC02" "ValveBiped.Bip01_Head1" -3.11 -1.66 -3.12 rotate -10.88 -24.58 173.43
$attachment "HBN_RMC03" "ValveBiped.Bip01_Head1" -4.13 -6.82 -4.03 rotate -2.09 -23.90 173.33
$attachment "HBN_RMC04" "ValveBiped.Bip01_Head1" -4.82 -12.06 -4.21 rotate -5.65 -26.41 165.02
$attachment "HBN_RMC05" "ValveBiped.Bip01_Head1" -6.68 -17.98 -4.76 rotate -7.08 -25.67 163.89
$attachment "HBN_RMC06" "ValveBiped.Bip01_Head1" -8.72 -23.84 -5.45 rotate -8.14 -24.21 168.54
$attachment "HBN_RMC07" "ValveBiped.Bip01_Head1" -10.25 -29.60 -6.23 rotate -13.93 -33.65 -178.61
$attachment "HBN_RMC08" "ValveBiped.Bip01_Head1" -10.84 -34.89 -7.32 rotate -23.41 -43.95 -167.17
$attachment "HBN_RMC09" "ValveBiped.Bip01_Head1" -11.19 -40.00 -8.85 rotate -38.02 -48.09 -157.36
$attachment "HBN_RMC10" "ValveBiped.Bip01_Head1" -11.81 -44.68 -10.98 rotate -85.21 -47.90 -127.77
$attachment "HBN_RMC11" "ValveBiped.Bip01_Head1" -13.79 -47.93 -14.39 rotate 55.78 -148.00 62.59
$attachment "FX_RavenHairEnd_10" "ValveBiped.Bip01_Head1" -16.96 -48.52 -17.57 rotate 55.78 -148.00 62.59
$attachment "HBN_RMD01" "ValveBiped.Bip01_Head1" -2.89 1.56 -0.65 rotate -25.68 -53.93 -171.68
$attachment "HBN_RMD02" "ValveBiped.Bip01_Head1" -4.16 -3.99 -2.15 rotate -3.73 -43.17 -178.01
$attachment "HBN_RMD03" "ValveBiped.Bip01_Head1" -4.23 -10.71 -2.47 rotate -5.72 -39.03 174.53
$attachment "HBN_RMD04" "ValveBiped.Bip01_Head1" -5.24 -17.03 -2.96 rotate -8.94 -43.09 176.87
$attachment "HBN_RMD05" "ValveBiped.Bip01_Head1" -6.16 -22.67 -3.62 rotate 11.29 -48.25 157.19
$attachment "HBN_RMD06" "ValveBiped.Bip01_Head1" -7.72 -28.78 -2.79 rotate 19.91 -63.98 158.03
$attachment "HBN_RMD07" "ValveBiped.Bip01_Head1" -8.15 -34.92 -1.86 rotate -106.82 -80.72 -61.42
$attachment "HBN_RMD08" "ValveBiped.Bip01_Head1" -7.03 -40.39 -2.73 rotate -156.12 -71.47 -32.26
$attachment "HBN_RMD09" "ValveBiped.Bip01_Head1" -7.95 -45.90 -3.46 rotate -163.15 -56.44 -39.83
$attachment "FX_RavenHairEnd_11" "ValveBiped.Bip01_Head1" -9.61 -49.36 -4.08 rotate -163.15 -56.44 -39.83
$attachment "HBN_RME01" "ValveBiped.Bip01_Head1" -1.38 2.53 -2.57 rotate -12.08 -15.91 -179.10
$attachment "HBN_RME02" "ValveBiped.Bip01_Head1" -1.63 -3.29 -3.77 rotate -12.41 -13.29 176.46
$attachment "HBN_RME03" "ValveBiped.Bip01_Head1" -2.40 -10.14 -5.24 rotate -4.50 -16.24 172.63
$attachment "HBN_RME04" "ValveBiped.Bip01_Head1" -3.53 -17.59 -5.81 rotate -25.94 -21.06 179.63
$attachment "HBN_RME05" "ValveBiped.Bip01_Head1" -4.78 -24.46 -8.93 rotate -23.22 -33.05 -171.51
$attachment "HBN_RME06" "ValveBiped.Bip01_Head1" -5.36 -31.51 -11.41 rotate -27.45 -50.23 -147.85
$attachment "HBN_RME07" "ValveBiped.Bip01_Head1" -4.06 -38.60 -13.63 rotate -85.56 -72.19 -99.52
$attachment "HBN_RME08" "ValveBiped.Bip01_Head1" -4.70 -46.18 -16.07 rotate -160.04 -60.76 -39.00
$attachment "FX_RavenHairEnd_12" "ValveBiped.Bip01_Head1" -7.60 -53.57 -17.41 rotate -160.04 -60.76 -39.00
$attachment "HBN_RMF01" "ValveBiped.Bip01_Head1" -0.28 0.12 -1.98 rotate -9.82 -5.18 179.45
$attachment "HBN_RMF02" "ValveBiped.Bip01_Head1" -0.43 -5.94 -3.03 rotate 3.23 -4.44 172.80
$attachment "HBN_RMF03" "ValveBiped.Bip01_Head1" -1.32 -13.26 -2.61 rotate -14.90 -11.38 -177.83
$attachment "HBN_RMF04" "ValveBiped.Bip01_Head1" -1.43 -20.67 -4.54 rotate -13.98 -33.20 179.76
$attachment "HBN_RMF05" "ValveBiped.Bip01_Head1" -2.50 -28.29 -6.13 rotate -8.20 -73.23 176.70
$attachment "HBN_RMF06" "ValveBiped.Bip01_Head1" -3.96 -35.71 -6.44 rotate -169.37 -56.03 -8.49
$attachment "HBN_RMF07" "ValveBiped.Bip01_Head1" -3.92 -42.69 -7.17 rotate -167.77 -9.74 -2.24
$attachment "HBN_RMF08" "ValveBiped.Bip01_Head1" -3.94 -49.34 -8.59 rotate -165.36 20.49 7.84
$attachment "FX_RavenHairEnd_13" "ValveBiped.Bip01_Head1" -3.66 -55.35 -10.05 rotate -165.36 20.49 7.84
$attachment "FX_Mark_02" "ValveBiped.Bip01_Head1" 0.00 4.84 1.81 rotate -90.00 -90.00 0.00
$attachment "Ab-NeckSub" "ValveBiped.Bip01_Spine2" -0.00 7.40 0.04 rotate 19.69 -0.00 0.00
$attachment "Ab-L-Shoulder0" "ValveBiped.Bip01_Spine2" 0.00 1.27 -2.92 rotate 1.60 167.69 -66.50
$attachment "Ab-L-Trape0" "ValveBiped.Bip01_Spine2" 0.00 5.94 -2.67 rotate -0.72 -157.51 -90.53
$attachment "Ab-L-Trape1" "ValveBiped.Bip01_Spine2" 5.27 5.77 -1.83 rotate -158.16 20.75 -85.16
$attachment "Ab-L-Pectro0" "ValveBiped.Bip01_Spine2" 3.26 2.63 3.05 rotate 19.14 -6.22 125.61
$attachment "Ab-L-Pectro1" "ValveBiped.Bip01_Spine2" 3.26 2.63 3.05 rotate 40.06 -8.24 127.40
$attachment "Ab-R-Pectro0" "ValveBiped.Bip01_Spine2" -3.26 2.63 3.05 rotate 19.14 6.22 -125.61
$attachment "Ab-R-Pectro1" "ValveBiped.Bip01_Spine2" -3.26 2.63 3.05 rotate -40.06 -8.24 52.60
$attachment "Ab-R-Shoulder0" "ValveBiped.Bip01_Spine2" 0.00 1.27 -2.92 rotate 1.60 -167.69 66.54
$attachment "Ab-R-Trape0" "ValveBiped.Bip01_Spine2" 0.00 5.94 -2.67 rotate -0.72 157.53 90.53
$attachment "Ab-R-Trape1" "ValveBiped.Bip01_Spine2" -5.27 5.78 -1.83 rotate -158.15 -20.75 85.15
$attachment "Dm-L-Breast-Point" "ValveBiped.Bip01_Spine2" 1.82 1.69 1.77 rotate 99.45 21.73 3.53
$attachment "Dm-L-Breast" "ValveBiped.Bip01_Spine2" 1.82 1.69 1.77 rotate 99.21 17.76 2.93
$attachment "Ab-L-Breast-Link" "ValveBiped.Bip01_Spine2" 1.82 1.69 1.77 rotate 99.21 17.76 2.93
$attachment "Ab-L-Breast" "ValveBiped.Bip01_Spine2" 1.82 1.69 1.77 rotate 99.21 17.76 2.93
$attachment "Dm-R-Breast-Point" "ValveBiped.Bip01_Spine2" -1.82 1.69 1.77 rotate -80.55 -21.73 -3.53
$attachment "Dm-R-Breast" "ValveBiped.Bip01_Spine2" -1.82 1.69 1.77 rotate -80.89 -15.72 -2.64
$attachment "Ab-R-Breast-Link" "ValveBiped.Bip01_Spine2" -1.82 1.69 1.77 rotate -80.89 -15.72 -2.64
$attachment "Ab-R-Breast" "ValveBiped.Bip01_Spine2" -1.82 1.69 1.77 rotate -80.89 -15.72 -2.64
$attachment "Dm-L-Trape-Cnt" "ValveBiped.Bip01_Spine2" 1.94 5.47 1.27 rotate -84.41 -6.46 89.71
$attachment "Dm-L-Trape" "ValveBiped.Bip01_Spine2" 3.10 5.90 -2.63 rotate 109.87 22.49 -90.05
$attachment "Ab-L-AX1" "ValveBiped.Bip01_Spine2" 2.72 5.70 -2.68 rotate 104.86 27.46 -90.06
$attachment "Dm-R-Trape-Cnt" "ValveBiped.Bip01_Spine2" -1.94 5.47 1.27 rotate -95.61 -6.47 90.29
$attachment "Dm-R-Trape" "ValveBiped.Bip01_Spine2" -3.10 5.90 -2.63 rotate -70.12 -22.49 90.04
$attachment "Ab-R-AX1" "ValveBiped.Bip01_Spine2" -2.72 5.70 -2.68 rotate -75.15 -27.47 90.06
$attachment "FX_WeakPoint" "ValveBiped.Bip01_Spine2" 0.00 1.68 -3.78 rotate 0.00 0.00 -0.00
$attachment "FX_Mark_03" "ValveBiped.Bip01_Spine2" -0.00 1.78 0.86 rotate -90.00 -90.00 0.00
$attachment "LockOnTargetUI" "ValveBiped.Bip01_Spine1" 0.00 -2.10 2.10 rotate 0.00 0.00 0.00
$attachment "FX_Mark_01" "ValveBiped.Bip01_Spine1" 0.00 -1.33 1.27 rotate -90.00 -90.00 0.00
$attachment "SC_Missile" "ValveBiped.Bip01_Spine1" -0.00 -0.00 -0.00 rotate 0.00 0.00 0.00
$attachment "ValveBiped.Bip01_L_Thigh" "ValveBiped.Bip01_L_Thigh" -0.00 -0.00 0.00 rotate 0 0 0
$attachment "ValveBiped.Bip01_L_Calf" "ValveBiped.Bip01_L_Calf" -0.00 -0.00 0.00 rotate 0 0 0
$attachment "ValveBiped.Bip01_L_Foot" "ValveBiped.Bip01_L_Foot" -0.00 -0.00 0.00 rotate 0 0 0
//$attachment "ValveBiped.Bip01_L_Toe0" "ValveBiped.Bip01_L_Toe0" -0.00 -0.00 0.00 rotate 0 0 0
$attachment "FX_Foot_L" "ValveBiped.Bip01_L_Foot" 0.00 0.00 0.00 rotate 90.00 -90.00 0.00
$attachment "Ab-L-Calf-Tw1" "ValveBiped.Bip01_L_Calf" 0.00 5.61 0.00 rotate 0.00 -6.81 -0.00
$attachment "Ab-L-Calf-Tw0" "ValveBiped.Bip01_L_Calf" 0.00 11.14 0.00 rotate 0.00 -13.62 -0.00
$attachment "Ab-L-Ankle" "ValveBiped.Bip01_L_Calf" -0.00 15.20 -0.00 rotate 9.19 -13.27 -2.31
$attachment "Ab-L-Knee" "ValveBiped.Bip01_L_Calf" 0.00 0.00 -0.00 rotate 90.22 -0.00 0.00
$attachment "Ab-L-Thigh-Tw0" "ValveBiped.Bip01_L_Thigh" 0.00 -0.00 -0.00 rotate -0.00 -4.05 -0.00
$attachment "Ab-L-Hip" "ValveBiped.Bip01_L_Thigh" -0.00 -0.00 0.00 rotate -85.16 -4.43 -2.22
$attachment "Ab-L-Hip-Reg" "ValveBiped.Bip01_L_Thigh" -0.00 -0.00 0.00 rotate -85.17 -4.14 -2.20
$attachment "Dm-L-Knee" "ValveBiped.Bip01_L_Thigh" -0.00 18.96 -0.00 rotate 4.53 0.00 0.00
$attachment "Dm-L-Knee-Sub" "ValveBiped.Bip01_L_Thigh" -0.00 13.23 -0.26 rotate 2.60 -0.00 -0.00
$attachment "Ab-L-Knee-SubA" "ValveBiped.Bip01_L_Thigh" -0.00 13.25 -0.25 rotate 2.60 -0.00 0.00
$attachment "Ab-L-Knee-SubB" "ValveBiped.Bip01_L_Thigh" -0.00 13.23 -0.26 rotate -2.60 -178.07 0.09
$attachment "Dm-L-Venter-A" "ValveBiped.Bip01_L_Thigh" 0.00 -0.00 -0.00 rotate -85.15 -4.03 -2.55
$attachment "Ab-L-Venter2" "ValveBiped.Bip01_L_Thigh" -0.11 0.00 0.00 rotate -43.74 83.84 48.89
$attachment "Ab-L-Thigh-Tw1" "ValveBiped.Bip01_L_Thigh" 0.00 6.35 -0.00 rotate -0.00 -1.62 0.00
$attachment "ValveBiped.Bip01_R_Thigh" "ValveBiped.Bip01_R_Thigh" -0.00 -0.00 0.00 rotate 0 0 0
$attachment "ValveBiped.Bip01_R_Calf" "ValveBiped.Bip01_R_Calf" -0.00 -0.00 0.00 rotate 0 0 0
$attachment "ValveBiped.Bip01_R_Foot" "ValveBiped.Bip01_R_Foot" -0.00 -0.00 0.00 rotate 0 0 0
//$attachment "ValveBiped.Bip01_R_Toe0" "ValveBiped.Bip01_R_Foot" -0.00 -0.00 0.00 rotate 0 0 0
$attachment "FX_Foot_R" "ValveBiped.Bip01_R_Foot" -0.00 -0.00 0.00 rotate 90.00 -90.00 0.00
$attachment "Ab-R-Calf-Tw1" "ValveBiped.Bip01_R_Calf" -0.00 5.61 -0.00 rotate -0.00 6.81 0.00
$attachment "Ab-R-Calf-Tw0" "ValveBiped.Bip01_R_Calf" -0.00 11.14 -0.00 rotate -0.00 13.62 0.00
$attachment "Ab-R-Ankle" "ValveBiped.Bip01_R_Calf" -0.00 15.20 -0.00 rotate 9.19 13.27 2.31
$attachment "Ab-R-Thigh-Tw1" "ValveBiped.Bip01_R_Thigh" 0.00 6.35 -0.00 rotate 0.00 2.02 -0.00
$attachment "Ab_RV_ACC_R01" "ValveBiped.Bip01_R_Thigh" 1.61 6.86 -5.12 rotate -29.26 -15.42 -27.71
$attachment "Ab_RV_ACC_R02" "ValveBiped.Bip01_R_Thigh" 2.39 7.92 -5.82 rotate -39.49 -13.82 -25.68
$attachment "Ab_RV_ACC_R03" "ValveBiped.Bip01_R_Thigh" 3.36 9.22 -7.09 rotate -19.92 -14.40 -23.70
$attachment "Ab-R-Thigh-Tw0" "ValveBiped.Bip01_R_Thigh" -0.00 0.00 0.00 rotate -0.00 4.05 -0.00
$attachment "Ab-R-Knee" "ValveBiped.Bip01_R_Thigh" 0.00 18.80 -0.00 rotate 92.04 -0.00 -0.00
$attachment "Dm-R-Knee" "ValveBiped.Bip01_R_Thigh" 0.00 18.96 -0.00 rotate 4.53 -0.00 -0.00
$attachment "Dm-R-Knee-Sub" "ValveBiped.Bip01_R_Thigh" 0.00 13.23 -0.24 rotate 2.44 -0.00 -0.00
$attachment "Ab-R-Knee-SubA" "ValveBiped.Bip01_R_Thigh" 0.00 13.25 -0.23 rotate 2.44 -0.00 -0.00
$attachment "Ab-R-Knee-SubB" "ValveBiped.Bip01_R_Thigh" 0.00 13.23 -0.24 rotate 2.44 0.00 -0.00
$attachment "Dm-R-Venter-A" "ValveBiped.Bip01_R_Thigh" -0.00 0.00 0.00 rotate -85.24 4.05 1.14
$attachment "Ab-R-Venter2" "ValveBiped.Bip01_R_Thigh" 0.11 0.00 0.00 rotate -44.01 -83.44 -48.61
$attachment "Ab-R-Hip" "ValveBiped.Bip01_R_Thigh" 0.00 -0.00 0.00 rotate -85.24 4.23 1.14
$attachment "Ab-R-Hip-Reg" "ValveBiped.Bip01_R_Thigh" 0.00 -0.00 0.00 rotate -85.25 4.23 1.14
$attachment "FX_CenterofMass" "ValveBiped.Bip01_Spine" -0.00 0.00 -0.00 rotate -90.00 -90.00 0.00
$attachment "Dm-L-Thigh-point" "ValveBiped.Bip01_Pelvis" 3.87 -0.00 0.00 rotate -5.67 -0.10 178.96
$attachment "Dm-L-AX2-Root" "ValveBiped.Bip01_Pelvis" 3.87 0.02 -0.01 rotate -5.60 -1.70 179.61
$attachment "Dm-L-AX2" "ValveBiped.Bip01_Pelvis" 5.50 2.10 -0.00 rotate -8.53 -5.45 111.39
$attachment "Ab-L-AX2" "ValveBiped.Bip01_Pelvis" 5.50 2.10 -0.00 rotate -8.53 -5.45 111.39
$attachment "Ab-L-Venter" "ValveBiped.Bip01_Pelvis" 3.87 -0.00 0.01 rotate -89.83 -0.21 21.36
$attachment "Dm-R-Thigh-point" "ValveBiped.Bip01_Pelvis" -3.87 0.00 -0.00 rotate -5.67 0.10 -178.96
$attachment "Dm-R-AX2-Root" "ValveBiped.Bip01_Pelvis" -3.87 0.02 -0.01 rotate -5.60 1.70 -179.62
$attachment "Dm-R-AX2" "ValveBiped.Bip01_Pelvis" -5.50 2.10 -0.00 rotate -8.52 174.55 68.61
$attachment "Ab-R-AX2" "ValveBiped.Bip01_Pelvis" -5.50 2.10 -0.00 rotate -8.52 174.55 68.61
$attachment "Ab-R-Venter" "ValveBiped.Bip01_Pelvis" -3.87 -0.00 0.01 rotate -89.88 0.37 -21.24
$attachment "Ab_RV_ACC_F01" "ValveBiped.Bip01_Pelvis" -0.00 1.45 3.29 rotate -178.51 -0.00 -0.00
$attachment "Ab_RV_ACC_F02" "ValveBiped.Bip01_Pelvis" -0.00 -2.12 3.19 rotate 179.06 -0.00 -0.00
$attachment "Ab_RV_ACC_F03" "ValveBiped.Bip01_Pelvis" -0.00 -5.33 3.24 rotate 178.93 -0.00 -0.00
$attachment "Ab_RV_ACC_F04" "ValveBiped.Bip01_Pelvis" -0.00 -8.35 3.30 rotate -176.44 0.00 -0.00
$attachment "Ab-Bk-SuiteA-01" "ValveBiped.Bip01_Pelvis" -0.00 0.01 0.01 rotate -134.72 0.00 0.00
$attachment "Ab-Bk-SuiteA-02" "ValveBiped.Bip01_Pelvis" -0.00 -6.05 -6.11 rotate -134.72 0.00 0.00
$attachment "Ab-Bk-SuiteA-03" "ValveBiped.Bip01_Pelvis" -0.00 -12.11 -12.23 rotate -134.72 0.00 0.00
$attachment "ValveBiped.Bip01_Prop1" "lPectoral" -0.00 -0.00 0.00 rotate 0 0 0
$attachment "SC_Weapon" "ValveBiped.Bip01_R_Hand" -0.00 0.00 -0.00 rotate 0.00 90.00 0.00
$attachment "ValveBiped.Bip01_Prop2" "rPectoral" -0.00 -0.00 0.00 rotate 0 0 0
$attachment "SC_LinkTarget" "ValveBiped.Bip01_Pelvis" -0.00 -41.99 -0.44 rotate 180.00 0.00 90.00
$attachment "Sc_M_Raven_ChaseGrab" "ValveBiped.Bip01_Pelvis" -0.00 -41.99 -0.44 rotate -90.00 -90.00 0.00
$attachment "Sc_M_Raven_BetaGrab" "ValveBiped.Bip01_Pelvis" -0.00 -41.99 -0.44 rotate -90.00 -90.00 0.00
$attachment "Sc_M_Raven_BetaGrabChain" "ValveBiped.Bip01_Pelvis" -0.00 -41.99 -0.44 rotate -90.00 -90.00 0.00
$attachment "Sc_M_Raven_BetaCounterGrab" "ValveBiped.Bip01_Pelvis" -0.00 -41.99 -0.44 rotate -90.00 -90.00 0.00
$attachment "Sc_M_Raven_ParryCounterSlash" "ValveBiped.Bip01_Pelvis" -0.00 -41.99 -0.44 rotate -90.00 -90.00 0.00
$attachment "Sc_M_Raven_BetaSkillCounter" "ValveBiped.Bip01_Pelvis" -0.00 -41.99 -0.44 rotate -90.00 -90.00 0.00
$attachment "Sc_M_Raven_ShieldBreakerCounter" "ValveBiped.Bip01_Pelvis" -0.00 -41.99 -0.44 rotate -90.00 -90.00 0.00
$attachment "Sc_EveLinkAttackCheck" "ValveBiped.Bip01_Pelvis" 0.00 -41.99 -504.44 rotate 180.00 0.00 90.00
$attachment "SC_LinkTarget_Raven" "ValveBiped.Bip01_Pelvis" -0.00 -41.99 -0.44 rotate -0.00 -90.00 0.00
$attachment "LockOnTarget" "ValveBiped.Bip01_Pelvis" -0.00 -14.69 -0.44 rotate 180.00 0.00 90.00
$attachment "Sc_BackAttack" "ValveBiped.Bip01_Pelvis" 0.00 -41.99 -50.84 rotate -90.00 -90.00 0.00
$attachment "Sc_Combo_Parrying" "ValveBiped.Bip01_Pelvis" -0.00 -41.99 51.53 rotate -90.00 90.00 0.00
$attachment "Sc_ComboParry_LinkAttack2-1" "ValveBiped.Bip01_Pelvis" -0.00 -41.99 -0.44 rotate -90.00 90.00 0.00
$attachment "Sc_ComboParry_LinkAttack2" "ValveBiped.Bip01_Pelvis" -0.00 -41.99 41.56 rotate -90.00 90.00 0.00
$attachment "Sc_ComboParry_LinkAttack2-2" "ValveBiped.Bip01_Pelvis" -0.00 -41.99 83.56 rotate -90.00 90.00 0.00
$attachment "Sc_Air_DropAttack" "ValveBiped.Bip01_Pelvis" -0.00 -41.99 -0.44 rotate -90.00 -90.00 0.00
$attachment "Sc_AreaCheck" "ValveBiped.Bip01_Pelvis" -0.00 -41.99 251.56 rotate 180.00 -90.00 0.00
$attachment "SC_CommandDisplay" "ValveBiped.Bip01_Pelvis" 0.00 85.20 28.45 rotate 180.00 0.00 90.00
$attachment "RootSocket" "ValveBiped.Bip01_Pelvis" -0.00 -41.99 -0.44 rotate -90.00 -90.00 0.00
$attachment "BodyLookAt" "ValveBiped.Bip01_Pelvis" 0.00 8.41 -0.44 rotate 180.00 0.00 90.00
$attachment "Sc_BackJumpCombo_1" "ValveBiped.Bip01_Pelvis" -4.20 42.01 62.56 rotate -135.00 -90.00 0.00
$attachment "Sc_BackJumpCombo_2" "ValveBiped.Bip01_Pelvis" 4.20 54.61 58.36 rotate -135.00 -90.00 0.00
$attachment "LockOnTarget_Middle" "ValveBiped.Bip01_Pelvis" -0.00 -8.39 -0.44 rotate 180.00 0.00 90.00
$attachment "Sc_EvadeBackSwordAura_1" "ValveBiped.Bip01_Pelvis" -0.00 -8.39 20.56 rotate -90.00 -90.00 0.00
$attachment "Sc_SwordAuraCombo_1" "ValveBiped.Bip01_Pelvis" -0.00 -8.39 20.56 rotate -60.00 -90.00 0.00
$attachment "Sc_SwordAuraCombo_2" "ValveBiped.Bip01_Pelvis" -0.00 0.01 20.56 rotate -120.00 -90.00 0.00
$attachment "Sc_SwordAuraCombo_3" "ValveBiped.Bip01_Pelvis" -0.00 4.21 20.56 rotate -90.00 -90.00 0.00
$attachment "Sc_AreaCheck2" "ValveBiped.Bip01_Pelvis" -0.00 -41.99 629.56 rotate 180.00 -90.00 0.00
$attachment "Sc_AreaCheck3" "ValveBiped.Bip01_Pelvis" -0.00 -41.99 419.56 rotate 180.00 -90.00 0.00
$attachment "SC_GaugeDisplay" "ValveBiped.Bip01_Pelvis" 0.00 31.17 -1.63 rotate 180.00 0.00 90.00

$attachment "FX_Core_01" "ValveBiped.Bip01_L_Clavicle" 2.80 -0.35 -4.00 rotate -0 0 90
$attachment "FX_Core_02" "ValveBiped.Bip01_R_Clavicle" 2.80 -1.70 3.89 rotate 0 0 90
$attachment "FX_Core_03" "ValveBiped.Bip01_Spine" 1.71 -3.53 2.61 rotate -0 -0 90
$attachment "FX_Core_04" "ValveBiped.Bip01_Spine" 1.89 -3.40 -2.57 rotate 0 -0 90

$bbox -25.758 -35.422 -2.125 29.884 35.422 84.294

$include sharedbones.qci

//$keyvalues
//{
//	particles 
//	{
//		"effect"		 
//		{
//			"name" "ravencoreglow_8"
//			"attachment_type" "follow_attachment"
//			"attachment_point" "FX_Core_01"
//		}
//		"effect"		 
//		{
//			"name" "ravencoreglow_4"
//			"attachment_type" "follow_attachment"
//			"attachment_point" "FX_Core_02"
//		}
//		"effect"		 
//		{
//			"name" "ravencoreglow_2"
//			"attachment_type" "follow_attachment"
//			"attachment_point" "FX_Core_03"
//		}
//		"effect"		 
//		{
//			"name" "ravencoreglow_2"
//			"attachment_type" "follow_attachment"
//			"attachment_point" "FX_Core_04"
//		}
//	} 
//}

$jigglebone "lPectoral"
{
	is_flexible
	{
		length 100
		tip_mass 10
		pitch_stiffness 200
		pitch_damping 9.45
		yaw_stiffness 200
		yaw_damping 9.45
		along_stiffness 100
		along_damping 0
		angle_constraint 68.999999
	}
}
$jigglebone "rPectoral"
{
	is_flexible
	{
		length 100
		tip_mass 10
		pitch_stiffness 200
		pitch_damping 9.4
		yaw_stiffness 200
		yaw_damping 9.4
		along_stiffness 100
		along_damping 0
		angle_constraint 68.999999
	}
}


// hair jiggle macros: adjust these values then recompile
$definemacro HAIR_ROOT BoneName BoneLength \\
$jigglebone $BoneName$ { \\
    is_flexible { \\
        length $BoneLength$ \\
        tip_mass 2 \\
        pitch_stiffness 400 \\
        pitch_damping 14 \\
        yaw_stiffness 400 \\
        yaw_damping 14 \\
        along_stiffness 400 \\
        along_damping 60 \\
        angle_constraint 10 \\
        yaw_constraint -20 20 \\
        pitch_constraint -8 12 \\
    } \\
    has_base_spring { \\
        base_mass 5 \\
        stiffness 900 \\
        damping 40 \\
        left_constraint -0.5 0.5 \\
        up_constraint -0.5 0.5 \\
        forward_constraint -0.5 0.5 \\
        left_friction 20 \\
        up_friction 20 \\
        forward_friction 20 \\
    } \\
} \\

$definemacro HAIR_MID BoneName BoneLength \\
$jigglebone $BoneName$ { \\
    is_flexible { \\
        length $BoneLength$ \\
        tip_mass 4 \\
        pitch_stiffness 160 \\
        pitch_damping 10 \\
        yaw_stiffness 160 \\
        yaw_damping 10 \\
        along_stiffness 250 \\
        along_damping 45 \\
        angle_constraint 18 \\
        yaw_constraint -25 25 \\
        pitch_constraint -12 22 \\
    } \\
    has_base_spring { \\
        base_mass 10 \\
        stiffness 700 \\
        damping 30 \\
        left_constraint -1 1 \\
        up_constraint -1 1 \\
        forward_constraint -1 1 \\
        left_friction 12 \\
        up_friction 12 \\
        forward_friction 12 \\
    } \\
} \\

$definemacro HAIR_TIP BoneName BoneLength \\
$jigglebone $BoneName$ { \\
    is_flexible { \\
        length $BoneLength$ \\
        tip_mass 8 \\
        pitch_stiffness 60 \\
        pitch_damping 8 \\
        yaw_stiffness 60 \\
        yaw_damping 8 \\
        along_stiffness 80 \\
        along_damping 20 \\
        angle_constraint 30 \\
        yaw_constraint -45 45 \\
        pitch_constraint -25 35 \\
    } \\
    has_base_spring { \\
        base_mass 20 \\
        stiffness 400 \\
        damping 25 \\
        left_constraint -2 2 \\
        up_constraint -2 2 \\
        forward_constraint -2 2 \\
        left_friction 8 \\
        up_friction 8 \\
        forward_friction 8 \\
    } \\
} \\

// left front 
$HAIR_ROOT HBn_LF01 4.931
$HAIR_ROOT HBn_LF02 4.478
$HAIR_MID HBn_LF03 4.636
$HAIR_MID HBn_LF04 5.009
$HAIR_TIP HBn_LF05 4.781

// left back 
$HAIR_ROOT HBn_LMA01 4.501
$HAIR_MID HBn_LMA02 6.589
$HAIR_MID HBn_LMA03 7.491
$HAIR_TIP HBn_LMA04 7.660
$HAIR_TIP HBn_LMA05 7.256

$HAIR_ROOT HBn_LMB01 2.698
$HAIR_MID HBn_LMB02 8.572
$HAIR_MID HBn_LMB03 8.117
$HAIR_TIP HBn_LMB04 8.230
$HAIR_TIP HBn_LMB05 7.367

$HAIR_ROOT HBn_LMC01 3.235	
$HAIR_MID HBn_LMC02 7.721
$HAIR_MID HBn_LMC03 7.375
$HAIR_TIP HBn_LMC04 6.848
$HAIR_TIP HBn_LMC05 7.778

$HAIR_ROOT HBn_LMD01 2.837
$HAIR_MID HBn_LMD02 6.982
$HAIR_MID HBn_LMD03 8.383
$HAIR_TIP HBn_LMD04 8.698
$HAIR_TIP HBn_LMD05 6.100

$HAIR_ROOT HBn_LME01 3.921
$HAIR_MID HBn_LME02 5.477
$HAIR_MID HBn_LME03 6.060
$HAIR_TIP HBn_LME04 5.994
$HAIR_TIP HBn_LME05 6.100
$HAIR_TIP HBn_LME06 6.917
$HAIR_TIP HBn_LME07 6.435

$HAIR_ROOT HBn_LMF01 4.188
$HAIR_MID HBn_LMF02 6.792
$HAIR_MID HBn_LMF03 7.745
$HAIR_TIP HBn_LMF04 9.115

// right front 
$HAIR_ROOT HBn_RF01 4.931
$HAIR_ROOT HBn_RF02 4.324
$HAIR_MID HBn_RF03 4.873
$HAIR_TIP HBn_RF04 5.057

$HAIR_ROOT HBn_RFF01 5.525
$HAIR_ROOT HBn_RFF02 4.477
$HAIR_MID HBn_RFF03 4.514
$HAIR_TIP HBn_RFF04 4.518
$HAIR_TIP HBn_RFF05 3.598

// right back 

$HAIR_ROOT HBn_RMA01 4.646
$HAIR_MID HBn_RMA02 6.589
$HAIR_MID HBn_RMA03 7.491
$HAIR_TIP HBn_RMA04 8.250
$HAIR_TIP HBn_RMA05 8.605

$HAIR_ROOT HBn_RMB01 3.138
$HAIR_MID HBn_RMB02 7.721
$HAIR_MID HBn_RMB03 7.375
$HAIR_TIP HBn_RMB04 6.848
$HAIR_TIP HBn_RMB05 7.778
$HAIR_TIP HBn_RMB06 8.178

$HAIR_ROOT HBn_RMC01 4.489
$HAIR_MID HBn_RMC02 5.477
$HAIR_MID HBn_RMC03 6.061
$HAIR_TIP HBn_RMC04 5.994
$HAIR_TIP HBn_RMC05 7.077
$HAIR_TIP HBn_RMC06 7.090

$HAIR_ROOT HBn_RMD01 3.424
$HAIR_MID HBn_RMD02 6.687
$HAIR_MID HBn_RMD03 7.638
$HAIR_TIP HBn_RMD04 7.290
$HAIR_TIP HBn_RMD05 6.530
$HAIR_TIP HBn_RMD06 7.225

$HAIR_ROOT HBn_RME01 3.744
$HAIR_MID HBn_RME02 6.749
$HAIR_MID HBn_RME03 8.003
$HAIR_TIP HBn_RME04 8.581
$HAIR_TIP HBn_RME05 8.690

$HAIR_ROOT HBn_RMF01 2.612
$HAIR_MID HBn_RMF02 6.982
$HAIR_MID HBn_RMF03 8.383
$HAIR_TIP HBn_RMF04 8.698
$HAIR_TIP HBn_RMF05 8.922

// center 

$HAIR_ROOT HBn_CK01 3.957 
$HAIR_MID HBn_CK02 6.792
$HAIR_MID HBn_CK03 7.745
$HAIR_TIP HBn_CK04 7.810 
$HAIR_TIP HBn_CK05 7.868


$jigglebone "Front Cloth"
{
	is_flexible
	{
		length 170
		tip_mass 0
		pitch_stiffness 60
		pitch_damping 6
		yaw_stiffness 60
		yaw_damping 6
		along_stiffness 50
		along_damping 0
		angle_constraint 16
	}
}
$jigglebone "Front Cloth.001"
{
	is_flexible
	{
		length 170
		tip_mass 0
		pitch_stiffness 60
		pitch_damping 6
		yaw_stiffness 60
		yaw_damping 6
		along_stiffness 50
		along_damping 0
		angle_constraint 16
	}
}
$jigglebone "Front Cloth.002"
{
	is_flexible
	{
		length 170
		tip_mass 0
		pitch_stiffness 60
		pitch_damping 6
		yaw_stiffness 60
		yaw_damping 6
		along_stiffness 50
		along_damping 0
		angle_constraint 16
	}
}
$jigglebone "Front Cloth.003"
{
	is_flexible
	{
		length 170
		tip_mass 0
		pitch_stiffness 60
		pitch_damping 6
		yaw_stiffness 60
		yaw_damping 6
		along_stiffness 50
		along_damping 0
		angle_constraint 16
	}
}
$jigglebone "Front Cloth.004"
{
	is_flexible
	{
		length 170
		tip_mass 0
		pitch_stiffness 60
		pitch_damping 6
		yaw_stiffness 60
		yaw_damping 6
		along_stiffness 50
		along_damping 0
		angle_constraint 16
	}
}
$include sbravenpm_shared.qci 
$animation "a_reference" "sbravenpm_anims\reference.smd" 
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

//$include "sbravenpm_anims.qci" 
//$include "sbravenpm_anims_rootmotion.qci" 
//$include "sbravenpm_testposes.qci" 

$includemodel "stellarblade/raven_animations.mdl"
$include "c_knife_anims.qci" 
$includemodel "f_anm.mdl"
$includemodel "alyx_animat_ep2.mdl"
$includemodel "alyx_post_ep2.mdl"
$includemodel "alyx_gest_ep2.mdl"
$includemodel "alyx_animat_ep1.mdl"
$includemodel "alyx_post_ep1.mdl"
$includemodel "alyx_gest_ep1.mdl"
$includemodel "alyx_animations.mdl"
$includemodel "alyx_postures.mdl"
$includemodel "alyx_gestures.mdl"
$includemodel "humans/female_shared.mdl"
$includemodel "humans/female_ss.mdl"
$includemodel "humans/female_gestures.mdl"
$includemodel "humans/female_postures.mdl"

$collisionjoints "sbravenpm_physics.smd" 
{ 
	$mass 70
	$inertia 10
	$damping 0.01
	$rotdamping 1.5
	$rootbone "valvebiped.bip01_pelvis"

	$jointconstrain "ValveBiped.Bip01_R_Thigh" x limit -12 12 0
	$jointconstrain "ValveBiped.Bip01_R_Thigh" y limit -8 75 0
	$jointconstrain "ValveBiped.Bip01_R_Thigh" z limit -97 32 0

	$jointconstrain "ValveBiped.Bip01_R_Calf" x limit 0 0 0
	$jointconstrain "ValveBiped.Bip01_R_Calf" y limit 0 0 0
	$jointconstrain "ValveBiped.Bip01_R_Calf" z limit -12 126 0

	$jointconstrain "ValveBiped.Bip01_L_Thigh" x limit -12 12 0
	$jointconstrain "ValveBiped.Bip01_L_Thigh" y limit -73 6 0
	$jointconstrain "ValveBiped.Bip01_L_Thigh" z limit -93 30 0

	$jointconstrain "ValveBiped.Bip01_L_Calf" x limit 0 0 0
	$jointconstrain "ValveBiped.Bip01_L_Calf" y limit 0 0 0
	$jointconstrain "ValveBiped.Bip01_L_Calf" z limit -8 126 0

	$jointconstrain "ValveBiped.Bip01_L_Foot" x limit 0 0 0
	$jointconstrain "ValveBiped.Bip01_L_Foot" y limit -19 19 0
	$jointconstrain "ValveBiped.Bip01_L_Foot" z limit -15 35 0

	$jointconstrain "ValveBiped.Bip01_Spine2" x limit -48 48 0
	$jointconstrain "ValveBiped.Bip01_Spine2" y limit -25 25 0
	$jointconstrain "ValveBiped.Bip01_Spine2" z limit -25 50 0

	$jointconstrain "ValveBiped.Bip01_R_UpperArm" x limit -39 39 0
	$jointconstrain "ValveBiped.Bip01_R_UpperArm" y limit -79 95 0
	$jointconstrain "ValveBiped.Bip01_R_UpperArm" z limit -93 23 0

	$jointconstrain "ValveBiped.Bip01_R_Forearm" x limit 0 0 0
	$jointconstrain "ValveBiped.Bip01_R_Forearm" y limit 0 0 0
	$jointconstrain "ValveBiped.Bip01_R_Forearm" z limit -149 4 0

	$jointconstrain "ValveBiped.Bip01_L_UpperArm" x limit -30 30 0
	$jointconstrain "ValveBiped.Bip01_L_UpperArm" y limit -95 84 0
	$jointconstrain "ValveBiped.Bip01_L_UpperArm" z limit -86 26 0

	$jointconstrain "ValveBiped.Bip01_L_Forearm" x limit 0 0 0
	$jointconstrain "ValveBiped.Bip01_L_Forearm" y limit 0 0 0
	$jointconstrain "ValveBiped.Bip01_L_Forearm" z limit -149 4 0

	$jointconstrain "ValveBiped.Bip01_L_Hand" x limit -37 37 0
	$jointconstrain "ValveBiped.Bip01_L_Hand" y limit 0 0 0
	$jointconstrain "ValveBiped.Bip01_L_Hand" z limit -57 59 0

	$jointconstrain "ValveBiped.Bip01_Head1" x limit -20 20 0
	$jointconstrain "ValveBiped.Bip01_Head1" y limit -25 25 0
	$jointconstrain "ValveBiped.Bip01_Head1" z limit -13 30 0

	$jointconstrain "ValveBiped.Bip01_R_Hand" x limit -60 60 0
	$jointconstrain "ValveBiped.Bip01_R_Hand" y limit 0 0 0
	$jointconstrain "ValveBiped.Bip01_R_Hand" z limit -57 70 0

	$jointconstrain "ValveBiped.Bip01_R_Foot" x limit 0 0 0
	$jointconstrain "ValveBiped.Bip01_R_Foot" y limit -25 6 0
	$jointconstrain "ValveBiped.Bip01_R_Foot" z limit -15 35 0

	$jointcollide "ValveBiped.Bip01_L_Forearm" "ValveBiped.Bip01_Pelvis"
	$jointcollide "ValveBiped.Bip01_R_Forearm" "ValveBiped.Bip01_Pelvis"
	$jointcollide "ValveBiped.Bip01_L_Forearm" "ValveBiped.Bip01_Spine2"
	$jointcollide "ValveBiped.Bip01_R_Forearm" "ValveBiped.Bip01_Spine2"
	$jointcollide "ValveBiped.Bip01_R_Thigh" "ValveBiped.Bip01_L_Thigh"
	$jointcollide "ValveBiped.Bip01_R_Calf" "ValveBiped.Bip01_L_Calf"
	$jointcollide "ValveBiped.Bip01_L_Foot" "ValveBiped.Bip01_R_Foot"
	$jointcollide "ValveBiped.Bip01_L_Foot" "ValveBiped.Bip01_R_Calf"
	$jointcollide "ValveBiped.Bip01_R_Foot" "ValveBiped.Bip01_L_Calf"
	$jointcollide "ValveBiped.Bip01_L_Forearm" "ValveBiped.Bip01_L_Thigh"
	$jointcollide "ValveBiped.Bip01_L_Forearm" "ValveBiped.Bip01_R_Thigh"
	$jointcollide "ValveBiped.Bip01_R_Forearm" "ValveBiped.Bip01_L_Thigh"
	$jointcollide "ValveBiped.Bip01_R_Forearm" "ValveBiped.Bip01_R_Thigh"
} 
