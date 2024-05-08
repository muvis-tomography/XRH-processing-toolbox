/*
version: BackgroundCorrBPFilteredVolsBasedOnUserROI_v20180829_Licensed

Author: Orestis L. Katsamenis
University of Southampton, Southampton, UK
Year: 2021

   Copyright 2021 University of Southampton
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

function CalibrateVolume(InputVolume, BckCorVolumeName) {

  if (isOpen("ROI Manager")) {
     selectWindow("ROI Manager");
     run("Close");
  }

	// Grey Calibration to match input volume//
	run("Set Measurements...", "area mean standard modal min centroid center bounding fit feret's integrated median redirect=None decimal=7");
	print("- - - - - - - - - -");
	print("Calibrating Background corrected volume . . . ");
	print("- - - - - - - - - -");

	//--------------------------------------------------------------------------
	// select BckCorr volume - Wax --------------------------------------------------
	setTool("rectangle");
	run("Clear Results");
	selectWindow(BckCorVolumeName); 
	resetMinAndMax;
	setSlice(nSlices/2);
	waitForUser( "Pause","select Wax ROI in BckCorVolume Volume and then press OK \n ...");
	BckCorVolumeWaxSlice = getSliceNumber();
	roiManager("Add"); // Add Wax selection to ROI Manager
	run("Measure"); 
	BckCorVolumeWax = getResult("Mean"); // get Wax Mean value from LS volume
	print("BckCorVolumeWax = ", BckCorVolumeWax); 
	run("Select None");
	//--------------------------------------------------------------------------
	// select BckCor volume volume - Tissue -----------------------------------------------
	run("Clear Results");
	selectWindow(BckCorVolumeName);
	waitForUser( "Pause","select Tissue ROI in LS Volume and then press OK \n ...");
	BckCorVolumeTissueSlice = getSliceNumber();
	roiManager("Add"); // Add Wax selection to ROI Manager
	run("Measure"); BckCorVolumeTissue = getResult("Mean"); // get Wax Mean value from LS volume
	print("BckCorVolumeTissue = ", BckCorVolumeTissue); 
	run("Select None");

	//--------------------------------------------------------------------------
	// select Input volume - Wax ----------------------------------------------
	run("Clear Results");
	selectWindow(InputVolume);
	setSlice(BckCorVolumeWaxSlice); // go to appropriate slice in the stack
	roiManager("Select", 0); 
	run("Measure"); 
	InputVolumeWax = getResult("Mean"); // get Wax Mean value from LS volume
	print("InputVolumeWax = ", BckCorVolumeWax); 
	run("Select None");
	//--------------------------------------------------------------------------
	// select Input volume - Tissue -------------------------------------------
	run("Clear Results");
	selectWindow(InputVolume);
	setSlice(BckCorVolumeTissueSlice); // go to appropriate slice in the stack
	roiManager("Select", 1); 
	run("Measure"); 
	InputVolumeTissue = getResult("Mean"); // get Wax Mean value from LS volume
	print("InputVolumeWax = ", InputVolumeTissue); 
	run("Select None");


	//............................//
	// set values for grey calibration  //
	//............................//
	CfactorInputVolume = (InputVolumeTissue-InputVolumeWax)/InputVolumeTissue;
	CfactorBckCorVolume = (BckCorVolumeTissue-BckCorVolumeWax)/BckCorVolumeTissue;
	CalFactor = CfactorInputVolume/CfactorBckCorVolume;

	//.............................//
	// create box & get USER value //
	//.............................//
	Dialog.create("User Input Values");	//Creates a dialog box
	Dialog.addNumber("Tissue|Wax contrast measured in Input Volume..., CfactorInputVolume=:", CfactorInputVolume); 					// Resolution input
	Dialog.addNumber("Tissue|Wax contrast measured in Background Corrected Volume..., CfactorBckCorVolume=:", CfactorBckCorVolume);
	Dialog.addNumber("Calculated Calibration Factor..., CalFactor=:", CalFactor);
	//Dialog.addNumber("Offset..., Offset=:", Offset);
	Dialog.show();
	CfactorPhantom = Dialog.getNumber();
	CfactorScan = Dialog.getNumber();
	CalFactor = Dialog.getNumber();
	//Offset = Dialog.getNumber();

	waitForUser( "Pause", "      The volume: \n" + BckCorVolumeName + "\n      will be calibrated to match \n" + InputVolume + "\n      press OK \n ...");
	selectWindow(BckCorVolumeName); //rename("c"+BckCorVolumeName); // "c" for Calibrate

	// Match contrast using the CalFactor ---------
	run("Multiply...", "value=CalFactor stack");

	// Offset BckCorVolume tissue intensity to match InputVolume's -----
	setSlice(BckCorVolumeTissueSlice); // go to appropriate slice in the stack
	roiManager("Select", 1); run("Measure"); 
	calBckCorTissue = getResult("Mean"); // get Wax Mean value from LS volume
	Offset = InputVolumeTissue-calBckCorTissue;
	print("Offset (InputVolumeTissue-calBckCorTissue) = ", Offset); 
	run("Select None");
	run("Add...", "value=Offset stack"); resetMinAndMax();
	selectWindow(InputVolume); bitDepthInput = bitDepth();
	//selectWindow("c"+BCorVolumeName);
	selectWindow(BckCorVolumeName);
	if (bitDepthInput == 16) {
		setMinAndMax(0, 65535); run("16-bit");}
	if (bitDepthInput == 8) {
		setMinAndMax(0, 255); run("8-bit");}
	volume = getTitle();

}





//............................//
// set DEFAULTS & Initiate    //
//............................//
run("Clear Results"); 
run("Set Measurements...", "mean min redirect=None decimal=3");
negativeBckValueFlag =0; 
negativeBckValue =0;

//-----------------------------------------------------------------------
// get Input volume name
waitForUser("Action required", "Select Input Volume window *then* OK [ESC to abort]"); 
InputVolume = getTitle(); 
bitDepthInput = bitDepth();
InputVolumeCorrected = "sc_"+InputVolume //SC: Background Slope correction
run("Duplicate...", "title=InputVolumeTemp duplicate"); 
rename(InputVolumeCorrected);

//-----------------------------------------------------------------------
// get background ROI
setTool("rectangle"); 
waitForUser("Action required - Select Background", "1. SELECT - Select a *pure* Background (usually Wax only) region in the slice \n\n2. CHECK - By scrolling through the stack make sure the region remains pure (background-only) throughout the volume. \n\n3. FINISH - Confirm by clicking OK [ESC to abort]"); 
run("Duplicate...", "title=background duplicate");

//-----------------------------------------------------------------------
// Main Script

selectWindow("background"); 
//run("32-bit");
greyBckCore = newArray(nSlices);

for (i=1; i<=nSlices; i++) {
	setSlice(i);
	run("Select All"); 
	run("Measure");
	greyBckCore[i-1] =getResult("Mean",i-1);
	// linear shift to positive values (in case of 32bit datasets)
	if (greyBckCore[i-1]<negativeBckValue){
		print ("negative Grey value fount!");
		negativeBckValueFlag = 1;
		negativeBckValue = greyBckCore[i-1];
		}
}

selectWindow(InputVolumeCorrected); 
run("Select None"); 
run("32-bit");
//print(negativeBckValueFlag);
if (negativeBckValueFlag==1) {
	print ("Flag =1; Shifting to positive valuers");
	for (i=1; i<=nSlices; i++) {
		setSlice(i);
		corValueTemp = greyBckCore[i-1]-negativeBckValue;
		run("Subtract...", "value=corValueTemp slice");
		}
	}
	else {
		for (i=1; i<=nSlices; i++) {
			setSlice(i);
			greyBckCoreTemp=greyBckCore[i-1];
			run("Subtract...", "value=greyBckCoreTemp slice");
			}
		}




//-----------------------------------------------------------------------
//Calibrate and Return to Input's bit-depth
CalibrateVolume(InputVolume, InputVolumeCorrected);

//-----------------------------------------------------------------------
//Create preview
selectWindow(InputVolumeCorrected);
	Width = getWidth(); Height = getHeight();
	makeLine(5, Height-5, Width-5, 5);
	run("Reslice [/]...", "output=1.000 slice_count=1 avoid"); rename("corrected");
	resetMinAndMax(); run("Enhance Contrast", "saturated=0.35"); run("8-bit");
	selectWindow("background"); close();
selectWindow(InputVolume);
	Width = getWidth(); Height = getHeight();
	makeLine(5, Height-5, Width-5, 5);
	run("Reslice [/]...", "output=1.000 slice_count=1 avoid"); rename("input");
	resetMinAndMax(); run("Enhance Contrast", "saturated=0.35"); run("8-bit");
run("Combine...", "stack1=input stack2=corrected"); rename("SlopeCorrectionPreview-of-"+InputVolume);

