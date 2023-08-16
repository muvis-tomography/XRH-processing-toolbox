//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// XRH process by OLK v20230704 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
/*
   Copyright 2020, 2021 University of Southampton
   Dr. Orestis L. Katsamenis
   μ-VIS X-Ray Imaging Centre
   Faculty of Engineering and the Environment

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
*/

/* ChangeLog:
 *  20230704
 * 	Integrated SR edits and now script respects user selected XRH-Enhance_ params, which were previously ignored  
 *  20211124
 *  	Fixed inability to run 32to16 bit conversion due to incorrect calling of the XRH_enhance function following 
 *  		XRH_enhance latest release
 *  	added option to omit 32to16 bit conversion 
 *  20210311
 *  	added memory optimisation option
 *  20210216
 *  	added updated LS script that allows calibration and generates a single-slice visualisation of the corrections
 *  20201201
 *  	fixed bug where enchance settings were not passed to XRH-Enhance script due to wrong syntax in run() "+sigma+"

*/



//............................//
// set DEFAULT value          //
//............................//
sigma = 2.0; Xrad = 1.0; Yrad = 1.0; Zrad = 1.0; CLAHE = 0; VoxelSize = 1.0; 32to16 = true;
//.............................//
// create box & get USER value //
//.............................//
	Dialog.create("User Input Values");	//Creates a dialog box
	Dialog.addMessage("Workflow:");
	Dialog.addMessage("HistRelevantReslice >>> XRH-Enhance >>> Suppress Lines >>> AddScale");
	Dialog.addCheckbox("Optimise memory usage", true); //0
	Dialog.addCheckbox("Run Histological relevant reslicing", true); //1
	Dialog.addCheckbox("Run Line suppression", false); //2
	Dialog.addMessage("XRH Enhance script Settings ====================");
	Dialog.addNumber("Gaussian Blur..., sigma=:", sigma); //3
	Dialog.addNumber("3D Median..., X radius=:", Xrad); //4
	Dialog.addNumber("3D Median..., Y radius=:", Yrad); //5
	Dialog.addNumber("3D Median..., Z radius=:", Zrad);//6
	Dialog.addNumber("CLAHE..., 0: DoNotUse, 1:accurate 2:fast:", CLAHE); //7
	Dialog.addCheckbox("Set Scale when done", false); //8
	Dialog.addCheckbox("[-50 100] 32 >> 16bit", true); //9
	//Dialog.addNumber("Voxel edge size (mm) =:", VoxelSize); //9
//-----------------------------------------------------------------------
    Dialog.show();
//-----------------------------------------------------------------------
//Variables -------------------------------------------------------------
	OptimiseMemory = Dialog.getCheckbox(); //0
	HistReslice = Dialog.getCheckbox(); //1
	LineSuppr = Dialog.getCheckbox(); //2	
	sigma = Dialog.getNumber(); //3
	Xrad = Dialog.getNumber(); //4
	Yrad = Dialog.getNumber(); //5
	Zrad = Dialog.getNumber(); //6
	CLAHE = Dialog.getNumber() //7
	SetVoxelSize = Dialog.getCheckbox(); //8 
	_32to16 = Dialog.getCheckbox(); //9
	//VoxelSize = Dialog.getNumber(); //9
	
////////////////////////////////
// 	Start processing scrips
////////////////////////////////
InputVolume = getTitle();
if (HistReslice) {
	print ("running HistRelevantReslice ");
	if (OptimiseMemory)	{
		run("HistRelevantReslice ", "cropping=Manual optimise");
		}
	else{
		run("HistRelevantReslice ", "cropping=Manual");
		}
		
	ResliceVolumeName = getTitle();
	Dialog.create("Reverse or not Reverse?");
	items = newArray("It looks good. Do Nothing.", "Stack needs reversing. Reverse now!");
	Dialog.addRadioButtonGroup("You happy with the rolling? \nIs rolling from tissue towards the cassette?", items, 2, 1, "It looks good. Do Nothing.");
	run("Collect Garbage");
	Dialog.show();
	ReverseStackCheck=Dialog.getRadioButton();
	if (ReverseStackCheck == "Stack needs reversing. Reverse now!") {
	  	selectWindow(ResliceVolumeName); run("Reverse");
	  	print("User said: "+ReverseStackCheck);
	  	}
	  	
	  	selectWindow(ResliceVolumeName);
}

preEnchancedVolumeName = getTitle();

if (_32to16) {
	run("XRH-Enhance ", "gaussian="+sigma+" 3d="+Xrad+" 3d_0="+Yrad+" 3d_1="+Zrad+" clahe...,=0 [-50 "); }
	else {
		run("XRH-Enhance ", "gaussian="+sigma+" 3d="+Xrad+" 3d_0="+Yrad+" 3d_1="+Zrad+" clahe...,=0 "); 
	}
	
EnchancedVolumeName = getTitle();
  	
  	if (OptimiseMemory) {
		close(preEnchancedVolumeName);
		run("Collect Garbage");
  	}

selectWindow(EnchancedVolumeName);
if (LineSuppr) {
	run("Brightness/Contrast...");
	run("Suppress lines OLK ");
	//setMinAndMax(0, 100); run("16-bit");
}


run("Select All");
waitForUser("Manual Crop ?", "Crop to selection"); run("Crop");

run("addVolumeDimensions ");

if (SetVoxelSize) {	
	run("Set Scale...");
}