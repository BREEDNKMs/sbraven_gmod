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

$bbox -25.758 -35.422 -2.125 29.884 35.422 84.294

$definebone "ValveBiped.Bip01_Pelvis" "" 0.002636 -0.734438 43.025146 0 0.000057 89.999982 0 0 0 0 0 0
$definebone "ValveBiped.Bip01_L_Thigh" "ValveBiped.Bip01_Pelvis" 3.061857 -4.181011 -0.610804 2.718226 -81.788578 -89.621316 0 0 0 0 0 0
$definebone "ValveBiped.Bip01_L_Calf" "ValveBiped.Bip01_L_Thigh" 18.476772 0.000093 0.000001 0.006186 0.923493 -0.282583 0 0 0 0 0 0
$definebone "ValveBiped.Bip01_L_Foot" "ValveBiped.Bip01_L_Calf" 17.49008 -0.000238 -0.000001 1.008864 -61.630375 0.170684 0 0 0 0 0 0
$definebone "ValveBiped.Bip01_R_Thigh" "ValveBiped.Bip01_Pelvis" -3.06533 -4.183575 -0.61148 2.715992 -98.214876 -90.381913 0 0 0 0 0 0
$definebone "ValveBiped.Bip01_R_Calf" "ValveBiped.Bip01_R_Thigh" 18.474852 -0.000163 -0.00001 -0.006187 0.920915 0.28138 0 0 0 0 0 0
$definebone "ValveBiped.Bip01_R_Foot" "ValveBiped.Bip01_R_Calf" 17.489574 0.001543 0 -1.110965 -61.621147 0.210905 0 0 0 0 0 0
$definebone "ValveBiped.Bip01_Spine" "ValveBiped.Bip01_Pelvis" -0.000117 -0.048882 -0.576226 4.944569 89.999579 89.999927 0 0 0 0 0 0
$definebone "ValveBiped.Bip01_Spine1" "ValveBiped.Bip01_Spine" 3.22448 0.767056 0.000496 0.000286 -1.674583 0 0 0 0 0 0 0
$definebone "ValveBiped.Bip01_Spine2" "ValveBiped.Bip01_Spine1" 3.223911 0.226376 -0.001944 -0.003438 5.748027 0 0 0 0 0 0 0
$definebone "ValveBiped.Bip01_Spine4" "ValveBiped.Bip01_Spine2" 5.187328 -1.262529 -0.001177 0.003782 11.121742 0.000688 0 0 0 0 0 0
$definebone "ValveBiped.Bip01_Neck1" "ValveBiped.Bip01_Spine4" 6.928421 -1.935274 -0.000227 -0.001203 21.370181 179.999745 0 0 0 0 0 0
$definebone "ValveBiped.Bip01_L_Clavicle" "ValveBiped.Bip01_Spine4" 4.047031 -1.419524 1.312322 -63.945563 170.169819 89.633378 0 0 0 0 0 0
$definebone "ValveBiped.Bip01_L_UpperArm" "ValveBiped.Bip01_L_Clavicle" 4.265503 1.434227 -0.404994 -0.015642 -19.967588 -90.176508 0 0 0 0 0 0
$definebone "ValveBiped.Bip01_L_Forearm" "ValveBiped.Bip01_L_UpperArm" 10.27916 0.000045 -0.000011 0.062059 -15.74431 -0.054432 0 0 0 0 0 0
$definebone "ValveBiped.Bip01_L_Hand" "ValveBiped.Bip01_L_Forearm" 10.68646 -0.000091 -0.000008 -6.114656 7.728801 90.151537 0 0 0 0 0 0
$definebone "ValveBiped.Bip01_R_Clavicle" "ValveBiped.Bip01_Spine4" 4.047779 -1.419909 -1.312459 64.042333 169.572574 -90.208685 0 0 0 0 0 0
$definebone "ValveBiped.Bip01_R_UpperArm" "ValveBiped.Bip01_R_Clavicle" 4.266745 1.424942 0.424926 -0.218355 -20.061599 90.164077 0 0 0 0 0 0
$definebone "ValveBiped.Bip01_R_Forearm" "ValveBiped.Bip01_R_UpperArm" 10.279192 -0.000012 0.000015 -0.02458 -15.745166 0.010945 0 0 0 0 0 0
$definebone "ValveBiped.Bip01_R_Hand" "ValveBiped.Bip01_R_Forearm" 10.686052 -0.000104 -0.000011 6.095009 7.462318 -89.591004 0 0 0 0 0 0
$definebone "lPectoral" "ValveBiped.Bip01_Spine2" 3.59013 -3.090273 1.193972 69.36038 88.726411 93.705927 0 0 0 0 0 0
$definebone "rPectoral" "ValveBiped.Bip01_Spine2" 3.589581 -3.089859 -1.196372 69.354813 -91.258315 -86.267277 0 0 0 0 0 0
$definebone "ValveBiped.Bip01_Head1" "ValveBiped.Bip01_Neck1" 3.236374 1.07959 0.000056 0.000859 17.346585 -0.000229 0 0 0 0 0 0
$definebone "ValveBiped.forward" "ValveBiped.Bip01_Head1" 0 0 0 0 -76 -90
$definebone "HBN_CK01" "ValveBiped.Bip01_Head1" 0.833721 3.805363 0.692955 31.792734 84.217803 -2.320078 0 0 0 0 0 0
$definebone "HBN_CK02" "HBN_CK01" 0.000029 6.792217 0.000031 2.066652 -0.653401 0.45768 0 0 0 0 0 0
$definebone "HBn_LF01" "ValveBiped.Bip01_Head1" 3.494724 -1.749056 -3.006912 61.374639 -69.02025 -171.258961 0 0 0 0 0 0
$definebone "HBn_LF02" "HBn_LF01" 0.00012 4.478321 0.000017 17.786677 -13.464109 -11.153199 0 0 0 0 0 0
$definebone "HBn_LF03" "HBn_LF02" 0.000044 4.636116 -0.000027 18.597801 -8.695328 2.052164 0 0 0 0 0 0
$definebone "HBn_LF04" "HBn_LF03" -0.000015 5.008659 0.000027 -16.419138 15.818042 4.354706 0 0 0 0 0 0
$definebone "HBn_LF05" "HBn_LF04" 0.000051 4.781166 0.000015 -25.822673 179.09536 -128.180944 0 0 0 0 0 0
$definebone "HBN_LMA01" "ValveBiped.Bip01_Head1" 2.253017 1.989082 -3.350106 75.888033 6.438899 -87.299182 0 0 0 0 0 0
$definebone "HBN_LMA02" "HBN_LMA01" 0.000141 6.589462 0.000151 -0.12204 -4.606128 11.823098 0 0 0 0 0 0
$definebone "HBN_LMB01" "ValveBiped.Bip01_Head1" -0.791183 2.26511 -1.234655 65.109721 47.250914 -43.195288 0 0 0 0 0 0
$definebone "HBN_LMB02" "HBN_LMB01" -0.000214 8.572269 -0.000079 -17.004529 10.112759 -12.768022 0 0 0 0 0 0
$definebone "HBN_LMC01" "ValveBiped.Bip01_Head1" 0.224213 0.240128 -3.218157 84.161311 33.104759 -50.273379 0 0 0 0 0 0
$definebone "HBN_LMC02" "HBN_LMC01" -0.000111 7.721058 -0.000278 3.466395 -9.600309 -16.261746 0 0 0 0 0 0
$definebone "HBN_LMD01" "ValveBiped.Bip01_Head1" -1.514488 2.104633 -1.150166 31.015404 89.134242 -1.666792 0 0 0 0 0 0
$definebone "HBN_LMD02" "HBN_LMD01" -0.000158 6.982349 -0.000074 -2.361221 8.794329 -11.441853 0 0 0 0 0 0
$definebone "HBN_LME01" "ValveBiped.Bip01_Head1" 1.196163 2.899168 -2.353085 59.020614 73.764192 -25.767462 0 0 0 0 0 0
$definebone "HBN_LME02" "HBN_LME01" 0.00009 5.476944 0.000006 -5.692398 -2.202797 16.362357 0 0 0 0 0 0
$definebone "HBN_LMF01" "ValveBiped.Bip01_Head1" 1.092754 3.649525 -1.738794 50.226223 82.793777 -8.514266 0 0 0 0 0 0
$definebone "HBN_LMF02" "HBN_LMF01" -0.000156 6.792206 -0.000119 6.176023 -2.787039 0.47464 0 0 0 0 0 0
$definebone "HBn_RF01" "ValveBiped.Bip01_Head1" 3.494541 -1.749065 3.007063 63.424939 103.924286 6.783764 0 0 0 0 0 0
$definebone "HBn_RF02" "HBn_RF01" 0.00001 4.323837 0.000096 -44.171441 25.738472 -13.172474 0 0 0 0 0 0
$definebone "HBn_RF03" "HBn_RF02" 0.000025 4.872898 -0.000019 -38.047671 -14.555246 21.041933 0 0 0 0 0 0
$definebone "HBn_RF04" "HBn_RF03" -0.000003 5.056652 0.000071 49.078942 -31.302586 -29.292813 0 0 0 0 0 0
$definebone "HBN_RMA01" "ValveBiped.Bip01_Head1" 2.292446 1.708639 3.661674 77.491201 167.454573 79.013377 0 0 0 0 0 0
$definebone "HBN_RMA02" "HBN_RMA01" -0.000128 6.589443 0.000217 -9.689579 10.135741 -0.409208 0 0 0 0 0 0
$definebone "HBN_RMB01" "ValveBiped.Bip01_Head1" -0.240505 2.066071 2.349267 38.953938 -105.738766 159.526895 0 0 0 0 0 0
$definebone "HBN_RMB02" "HBN_RMB01" -0.000151 7.721107 0 -7.23227 -6.674211 -11.930586 0 0 0 0 0 0
$definebone "HBN_RMC01" "ValveBiped.Bip01_Head1" 1.617565 3.431427 2.399265 32.777456 -93.564958 165.707165 0 0 0 0 0 0
$definebone "HBN_RMC02" "HBN_RMC01" -0.000143 5.47694 -0.000031 4.244069 3.45396 3.3078 0 0 0 0 0 0
$definebone "HBN_RMD01" "ValveBiped.Bip01_Head1" 0.361103 0.886686 3.287746 66.628147 -126.197321 146.976887 0 0 0 0 0 0
$definebone "HBN_RMD02" "HBN_RMD01" -0.00008 6.686642 0.000229 23.729737 -18.775652 -8.397328 0 0 0 0 0 0
$definebone "HBN_RME01" "ValveBiped.Bip01_Head1" 1.071865 3.225809 1.570115 16.135333 -92.551857 177.490102 0 0 0 0 0 0
$definebone "HBN_RME02" "HBN_RME01" 0.000412 6.748913 -0.000069 4.800414 1.272079 -3.592615 0 0 0 0 0 0
$definebone "HBN_RMF01" "ValveBiped.Bip01_Head1" -1.514561 2.104622 0.318056 2.698671 -90.074042 178.573561 0 0 0 0 0 0
$definebone "HBN_RMF02" "HBN_RMF01" 0.000187 6.982292 0.000012 -3.30144 -12.359671 -6.164281 0 0 0 0 0 0
$definebone "HBn_RFF01" "ValveBiped.Bip01_Head1" 3.553654 -3.478008 2.409276 43.662305 87.967174 0.046983 0 0 0 0 0 0
$definebone "HBn_RFF02" "HBn_RFF01" -0.000005 4.476906 -0.000015 -33.708882 21.61552 -8.652008 0 0 0 0 0 0
$definebone "HBn_RFF03" "HBn_RFF02" 0.000031 4.514126 -0.000023 -8.330325 -146.059593 166.886834 0 0 0 0 0 0
$definebone "HBn_RFF04" "HBn_RFF03" 0.000038 4.518387 -0.000019 30.299143 -140.271581 -171.79662 0 0 0 0 0 0
$definebone "HBn_RFF05" "HBn_RFF04" 0.000018 3.598331 0.000015 49.839194 -44.302922 -42.932472 0 0 0 0 0 0
$definebone "HBN_CK03" "HBN_CK02" -0.00005 7.74482 0.00003 -8.898155 3.904822 -0.999238 0 0 0 0 0 0
$definebone "HBN_CK04" "HBN_CK03" 0.000082 7.809704 0.000011 0.287793 0.351852 -1.927314 0 0 0 0 0 0
$definebone "HBN_CK05" "HBN_CK04" -0.000008 7.867676 0.000027 -7.328586 1.510946 -4.201384 0 0 0 0 0 0
$definebone "HBN_LMA03" "HBN_LMA02" 0.000034 7.491417 0.000032 10.568382 -10.953014 -19.108829 0 0 0 0 0 0
$definebone "HBN_LMA04" "HBN_LMA03" 0.000013 7.660305 -0.000069 7.287176 -3.558821 -3.61978 0 0 0 0 0 0
$definebone "HBN_LMA05" "HBN_LMA04" 0.000057 7.256271 0.00004 -27.950201 17.979935 -3.032955 0 0 0 0 0 0
$definebone "HBN_LMB03" "HBN_LMB02" -0.000093 8.117214 0.000051 44.261911 -16.362529 4.140135 0 0 0 0 0 0
$definebone "HBN_LMB04" "HBN_LMB03" -0.000034 8.230034 -0.000025 -19.894758 4.139394 -4.61145 0 0 0 0 0 0
$definebone "HBN_LMB05" "HBN_LMB04" 0.000059 7.366726 0.00006 -38.038147 3.59491 -0.88207 0 0 0 0 0 0
$definebone "HBN_LMC03" "HBN_LMC02" -0.00005 7.374859 -0.000009 -11.174109 2.83849 0.43178 0 0 0 0 0 0
$definebone "HBN_LMC04" "HBN_LMC03" 0.000074 6.848103 0.000003 0.372021 -1.927831 0.31421 0 0 0 0 0 0
$definebone "HBN_LMC05" "HBN_LMC04" -0.000034 7.777866 0.000004 10.455165 -8.757666 -10.662572 0 0 0 0 0 0
$definebone "HBN_LMD03" "HBN_LMD02" 0.000049 8.382866 -0.000086 33.68917 -14.7802 2.570521 0 0 0 0 0 0
$definebone "HBN_LMD04" "HBN_LMD03" 0.000015 8.697701 -0.000031 -27.176425 16.669802 -5.880554 0 0 0 0 0 0
$definebone "HBN_LME03" "HBN_LME02" -0.000093 6.06044 -0.000105 -32.94663 22.036753 -8.882279 0 0 0 0 0 0
$definebone "HBN_LME04" "HBN_LME03" 0.000021 5.994263 0.000025 16.534068 -3.880531 1.944736 0 0 0 0 0 0
$definebone "HBN_LME05" "HBN_LME04" -0.00001 6.100491 -0.000006 17.146958 -9.29057 -3.919372 0 0 0 0 0 0
$definebone "HBN_LME06" "HBN_LME05" 0.000036 6.916767 0.000018 12.635608 -6.186232 -5.518384 0 0 0 0 0 0
$definebone "HBN_LMF03" "HBN_LMF02" -0.000118 7.744781 -0.000049 -14.718943 0.885907 3.273539 0 0 0 0 0 0
$definebone "HBN_LMF04" "HBN_LMF03" 0.000084 9.115025 -0.000036 14.682209 -8.172499 -1.168373 0 0 0 0 0 0
$definebone "HBN_RMA03" "HBN_RMA02" 0.000147 7.491497 -0.000113 -6.136434 10.274738 -7.586365 0 0 0 0 0 0
$definebone "HBN_RMA04" "HBN_RMA03" -0.000147 8.24966 0.000139 -3.335072 0.906079 2.401322 0 0 0 0 0 0
$definebone "HBN_RMA05" "HBN_RMA04" 0.000059 8.605232 -0.000021 28.75245 -4.566413 5.820333 0 0 0 0 0 0
$definebone "HBN_RMB03" "HBN_RMB02" -0.000111 7.374866 -0.000047 2.689466 -2.662244 -6.360748 0 0 0 0 0 0
$definebone "HBN_RMB04" "HBN_RMB03" -0.00004 6.848064 -0.000036 14.181841 17.183631 15.672118 0 0 0 0 0 0
$definebone "HBN_RMB05" "HBN_RMB04" 0.000072 7.777819 -0.000036 10.665596 -3.019028 4.178125 0 0 0 0 0 0
$definebone "HBN_RMC03" "HBN_RMC02" -0.000072 6.060497 -0.000019 0.896794 -8.712857 -0.871241 0 0 0 0 0 0
$definebone "HBN_RMC04" "HBN_RMC03" 0.000027 5.994255 0.000011 -9.033307 8.783842 -7.231645 0 0 0 0 0 0
$definebone "HBN_RMC05" "HBN_RMC04" -0.000051 7.076881 -0.000033 0.595304 2.085158 -0.464841 0 0 0 0 0 0
$definebone "HBN_RMC06" "HBN_RMC05" -0.000021 7.089874 -0.000087 5.648502 -1.483281 4.060726 0 0 0 0 0 0
$definebone "HBN_RMD03" "HBN_RMD02" 0.000024 7.638023 -0.000015 -1.486597 7.502941 -4.556561 0 0 0 0 0 0
$definebone "HBN_RMD04" "HBN_RMD03" -0.000032 7.290234 -0.000017 -5.380593 1.373097 1.450959 0 0 0 0 0 0
$definebone "HBN_RMD05" "HBN_RMD04" -0.000023 6.530373 0.000013 -17.223118 0.385718 -15.002726 0 0 0 0 0 0
$definebone "HBN_RME03" "HBN_RME02" -0.000053 8.002647 0.000027 -6.715521 -6.62328 -3.867177 0 0 0 0 0 0
$definebone "HBN_RME04" "HBN_RME03" 0.000013 8.58057 -0.000107 -0.411838 19.171509 5.054237 0 0 0 0 0 0
$definebone "HBN_RME05" "HBN_RME04" 0.000193 8.689833 -0.00004 -23.630385 -7.707374 3.742851 0 0 0 0 0 0
$definebone "HBN_RMF03" "HBN_RMF02" -0.000002 8.382881 -0.000082 -5.724651 16.448074 7.736593 0 0 0 0 0 0
$definebone "HBN_RMF04" "HBN_RMF03" -0.000059 8.697681 0.000028 -29.226581 2.568975 -8.484875 0 0 0 0 0 0
$definebone "HBN_RMF05" "HBN_RMF04" -0.000151 8.921835 0.000071 -51.144224 5.661109 -13.569421 0 0 0 0 0 0
$definebone "HBN_LMD05" "HBN_LMD04" 0.000044 8.92181 -0.000025 33.289068 -11.207578 -4.369603 0 0 0 0 0 0
$definebone "HBN_LME07" "HBN_LME06" 0.000132 6.435059 -0.000046 9.833443 -6.678691 -2.146184 0 0 0 0 0 0
$definebone "HBN_RMB06" "HBN_RMB05" -0.000078 8.178055 0.000006 -24.227636 -21.850076 -4.986731 0 0 0 0 0 0
$definebone "HBN_RMD06" "HBN_RMD05" 0.000063 7.224884 0.000012 1.860965 -10.07392 2.091525 0 0 0 0 0 0
$definebone "Front Cloth" "ValveBiped.Bip01_Spine2" -0.436588 4.719023 -0.001076 -89.996369 97.05636 0 0 0 0 0 0 0
$definebone "Front Cloth.001" "Front Cloth" 0 2.775455 -0.000234 0.000057 0 -7.739915 0 0 0 0 0 0
$definebone "Front Cloth.002" "Front Cloth.001" 0 3.18977 0.000004 0 0 11.907152 0 0 0 0 0 0
$definebone "Front Cloth.003" "Front Cloth.002" 0 3.50465 0.000046 0 0 -15.004449 0 0 0 0 0 0
$definebone "Front Cloth.004" "Front Cloth.003" 0 2.863201 0.000001 0 0 -2.937382 0 0 0 0 0 0
$definebone "ValveBiped.Bip01_L_Finger2" "ValveBiped.Bip01_L_Hand" 3.121417 -0.195293 -0.025784 4.54774 -8.062616 2.687289 0 0 0 0 0 0
$definebone "ValveBiped.Bip01_L_Finger21" "ValveBiped.Bip01_L_Finger2" 1.655594 -0.000008 0.000009 -0.93392 -5.900105 -1.92044 0 0 0 0 0 0
$definebone "ValveBiped.Bip01_L_Finger22" "ValveBiped.Bip01_L_Finger21" 0.96077 -0.000004 -0.000007 0.177103 -12.39727 -0.000057 0 0 0 0 0 0
$definebone "ValveBiped.Bip01_L_Finger1" "ValveBiped.Bip01_L_Hand" 3.074357 -0.285835 0.756413 -0.819843 -10.597268 17.493494 0 0 0 0 0 0
$definebone "ValveBiped.Bip01_L_Finger11" "ValveBiped.Bip01_L_Finger1" 1.497176 0.000004 0.000005 3.176478 -1.984797 -2.127736 0 0 0 0 0 0
$definebone "ValveBiped.Bip01_L_Finger12" "ValveBiped.Bip01_L_Finger11" 0.793762 -0.000004 0.000006 0.148681 -13.998467 -0.000343 0 0 0 0 0 0
$definebone "ValveBiped.Bip01_L_Finger0" "ValveBiped.Bip01_L_Hand" 0.609298 -0.326641 0.524365 -46.296651 -23.16475 -88.737927 0 0 0 0 0 0
$definebone "ValveBiped.Bip01_L_Finger01" "ValveBiped.Bip01_L_Finger0" 1.55614 0.000002 -0.000004 5.076702 20.929866 -10.80049 0 0 0 0 0 0
$definebone "ValveBiped.Bip01_L_Finger02" "ValveBiped.Bip01_L_Finger01" 1.135902 0.000015 0.000004 0.645506 20.791557 0.000857 0 0 0 0 0 0
$definebone "ValveBiped.Bip01_L_Finger4" "ValveBiped.Bip01_L_Hand" 2.505715 -0.371597 -1.439179 14.339646 -9.119322 -26.657375 0 0 0 0 0 0
$definebone "ValveBiped.Bip01_L_Finger41" "ValveBiped.Bip01_L_Finger4" 1.064204 0 0 -0.037522 0.078086 0.049445 0 0 0 0 0 0
$definebone "ValveBiped.Bip01_L_Finger42" "ValveBiped.Bip01_L_Finger41" 0.640337 0 -0.000004 0.285053 -13.995597 -0.000748 0 0 0 0 0 0
$definebone "ValveBiped.Bip01_L_Finger3" "ValveBiped.Bip01_L_Hand" 2.839749 -0.191383 -0.70594 11.059863 -10.05565 -10.950082 0 0 0 0 0 0
$definebone "ValveBiped.Bip01_L_Finger31" "ValveBiped.Bip01_L_Finger3" 1.532969 0.000004 0.000005 -0.758591 -0.587526 0.364231 0 0 0 0 0 0
$definebone "ValveBiped.Bip01_L_Finger32" "ValveBiped.Bip01_L_Finger31" 0.832973 -0.000008 -0.000003 0.421358 -24.684929 -0.000231 0 0 0 0 0 0
$definebone "ValveBiped.Bip01_R_Finger2" "ValveBiped.Bip01_R_Hand" 3.121216 -0.194809 0.042612 -4.884697 -8.060314 -2.394162 0 0 0 0 0 0
$definebone "ValveBiped.Bip01_R_Finger21" "ValveBiped.Bip01_R_Finger2" 1.65556 0.000008 0.000007 0.861955 -5.884853 1.851284 0 0 0 0 0 0
$definebone "ValveBiped.Bip01_R_Finger22" "ValveBiped.Bip01_R_Finger21" 0.960909 0.000008 0.000008 -0.256287 -12.39434 -0.000057 0 0 0 0 0 0
$definebone "ValveBiped.Bip01_R_Finger1" "ValveBiped.Bip01_R_Hand" 3.077971 -0.291058 -0.739152 0.463864 -10.62442 -17.40629 0 0 0 0 0 0
$definebone "ValveBiped.Bip01_R_Finger11" "ValveBiped.Bip01_R_Finger1" 1.49726 -0.000011 -0.000004 -3.195444 -1.940612 2.263127 0 0 0 0 0 0
$definebone "ValveBiped.Bip01_R_Finger12" "ValveBiped.Bip01_R_Finger11" 0.793789 -0.000008 -0.000002 -0.240872 -13.997824 0.000747 0 0 0 0 0 0
$definebone "ValveBiped.Bip01_R_Finger0" "ValveBiped.Bip01_R_Hand" 0.612071 -0.330299 -0.518945 45.894257 -23.433175 105.40309 0 0 0 0 0 0
$definebone "ValveBiped.Bip01_R_Finger01" "ValveBiped.Bip01_R_Finger0" 1.555676 0.000008 -0.000004 1.098816 21.539898 17.408356 0 0 0 0 0 0
$definebone "ValveBiped.Bip01_R_Finger02" "ValveBiped.Bip01_R_Finger01" 1.136812 -0.000004 -0.000002 -0.551358 20.791615 0.000292 0 0 0 0 0 0
$definebone "ValveBiped.Bip01_R_Finger4" "ValveBiped.Bip01_R_Hand" 2.498421 -0.361462 1.454208 -14.67912 -9.038756 26.675649 0 0 0 0 0 0
$definebone "ValveBiped.Bip01_R_Finger41" "ValveBiped.Bip01_R_Finger4" 1.064594 0.000004 0.000004 0.038903 0.089779 -0.8261 0 0 0 0 0 0
$definebone "ValveBiped.Bip01_R_Finger42" "ValveBiped.Bip01_R_Finger41" 0.640362 -0.000008 -0.000002 -0.351283 -13.997252 0.000509 0 0 0 0 0 0
$definebone "ValveBiped.Bip01_R_Finger3" "ValveBiped.Bip01_R_Hand" 2.836422 -0.186302 0.721372 -11.409938 -9.99909 10.465244 0 0 0 0 0 0
$definebone "ValveBiped.Bip01_R_Finger31" "ValveBiped.Bip01_R_Finger3" 1.532739 -0.000004 0 0.762032 -0.57629 -0.220765 0 0 0 0 0 0
$definebone "ValveBiped.Bip01_R_Finger32" "ValveBiped.Bip01_R_Finger31" 0.833151 0.000004 0.000005 -0.554341 -24.681595 0.000456 0 0 0 0 0 0

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
$jigglebone "HBN_CK01"
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
$jigglebone "HBN_CK02"
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
$jigglebone "HBn_LF01"
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
$jigglebone "HBn_LF02"
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
$jigglebone "HBn_LF03"
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
$jigglebone "HBn_LF04"
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
$jigglebone "HBn_LF05"
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
$jigglebone "HBN_LMA01"
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
$jigglebone "HBN_LMA02"
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
$jigglebone "HBN_LMB01"
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
$jigglebone "HBN_LMB02"
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
$jigglebone "HBN_LMC01"
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
$jigglebone "HBN_LMC02"
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
$jigglebone "HBN_LMD01"
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
$jigglebone "HBN_LMD02"
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
$jigglebone "HBN_LME01"
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
$jigglebone "HBN_LME02"
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
$jigglebone "HBN_LMF01"
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
$jigglebone "HBN_LMF02"
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
$jigglebone "HBn_RF01"
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
$jigglebone "HBn_RF02"
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
$jigglebone "HBn_RF03"
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
$jigglebone "HBn_RF04"
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
$jigglebone "HBN_RMA01"
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
$jigglebone "HBN_RMA02"
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
$jigglebone "HBN_RMB01"
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
$jigglebone "HBN_RMB02"
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
$jigglebone "HBN_RMC01"
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
$jigglebone "HBN_RMC02"
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
$jigglebone "HBN_RMD01"
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
$jigglebone "HBN_RMD02"
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
$jigglebone "HBN_RME01"
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
$jigglebone "HBN_RME02"
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
$jigglebone "HBN_RMF01"
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
$jigglebone "HBN_RMF02"
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
$jigglebone "HBn_RFF01"
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
$jigglebone "HBn_RFF02"
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
$jigglebone "HBn_RFF03"
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
$jigglebone "HBn_RFF04"
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
$jigglebone "HBn_RFF05"
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
$jigglebone "HBN_CK03"
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
$jigglebone "HBN_CK04"
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
$jigglebone "HBN_CK05"
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
$jigglebone "HBN_LMA03"
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
$jigglebone "HBN_LMA04"
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
$jigglebone "HBN_LMA05"
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
$jigglebone "HBN_LMB03"
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
$jigglebone "HBN_LMB04"
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
$jigglebone "HBN_LMB05"
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
$jigglebone "HBN_LMC03"
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
$jigglebone "HBN_LMC04"
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
$jigglebone "HBN_LMC05"
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
$jigglebone "HBN_LMD03"
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
$jigglebone "HBN_LMD04"
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
$jigglebone "HBN_LME03"
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
$jigglebone "HBN_LME04"
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
$jigglebone "HBN_LME05"
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
$jigglebone "HBN_LME06"
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
$jigglebone "HBN_LMF03"
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
$jigglebone "HBN_LMF04"
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
$jigglebone "HBN_RMA03"
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
$jigglebone "HBN_RMA04"
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
$jigglebone "HBN_RMA05"
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
$jigglebone "HBN_RMB03"
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
$jigglebone "HBN_RMB04"
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
$jigglebone "HBN_RMB05"
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
$jigglebone "HBN_RMC03"
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
$jigglebone "HBN_RMC04"
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
$jigglebone "HBN_RMC05"
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
$jigglebone "HBN_RMC06"
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
$jigglebone "HBN_RMD03"
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
$jigglebone "HBN_RMD04"
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
$jigglebone "HBN_RMD05"
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
$jigglebone "HBN_RME03"
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
$jigglebone "HBN_RME04"
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
$jigglebone "HBN_RME05"
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
$jigglebone "HBN_RMF03"
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
$jigglebone "HBN_RMF04"
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
$jigglebone "HBN_RMF05"
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
$jigglebone "HBN_LMD05"
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
$jigglebone "HBN_LME07"
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
$jigglebone "HBN_RMB06"
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
$jigglebone "HBN_RMD06"
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

$ikchain "rhand" "ValveBiped.Bip01_R_Hand" knee 0.707 0.707 0
$ikchain "lhand" "ValveBiped.Bip01_L_Hand" knee 0.707 0.707 0
$ikchain "rfoot" "ValveBiped.Bip01_R_Foot" knee 0.707 -0.707 0
$ikchain "lfoot" "ValveBiped.Bip01_L_Foot" knee 0.707 -0.707 0

$ikautoplaylock "rfoot" 0.5 0.1
$ikautoplaylock "lfoot" 0.5 0.1

$cmdlist lockfeet { 
	ikrule lfoot footstep 
	ikrule rfoot footstep 
//	ikrule lhand footstep 
//	ikrule rhand footstep 
} 

$animation "a_proportions_corrective_animation" "sbravenpm_anims\a_proportions_corrective_animation.smd" 

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
	"sbravenpm_anims\reference.smd"
	fadein 0.2
	fadeout 0.2
	fps 30
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
	fadein 0.2
	fadeout 0.2
	fps 30
} 

$include "sbravenpm_anims.qci" 
//$include "sbravenpm_testposes.qci" 

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
