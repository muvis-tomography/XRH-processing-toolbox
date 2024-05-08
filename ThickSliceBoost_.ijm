//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// ThickSliceBoost stack generation script for Fiji/ImageJ (v202200303) by OLK   ~~~~~~~~
/*
   Copyright 2021 University of Southampton
   Dr. Orestis L. Katsamenis
   μ-VIS X-ray Imaging Centre (www.muvis.org)
   Faculty of Engineering and Physical Sciences 

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
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
/*
 * v202200303
 * 		fixed typo in CombOperationFileName="AvgInt"
 * v20220228
 * 		fixed bug where thick slices combination was always done using "multiplication" instead of respecting user's input
 * 		Replaces "Sum Slices" operation that was not recognised with "Add"
 * 		Added "Subtract","Multiply", "Difference" operations
 * 		minor edits on GUI menu
 */
//
function ThickSliceSNRBoost (InputTemp, SliceThickness, RangeMin, RangeMax, Operation, GmmaCor) { 
// function description
		selectWindow(InputTemp);
		getDimensions(widthInput, heightInput, channelsInput, slicesInput, framesInput);
		ThickSliceRollfunction(InputTemp, SliceThickness, RangeMin, RangeMax, Operation, GmmaCor);
		rename("Thick");
		run("Size...", "width="+widthInput+" height="+heightInput+" depth="+slicesInput+" constrain average interpolation=Bicubic");
		rename("ResizedThick");
		imageCalculator("Average create 32-bit stack", InputTemp, "ResizedThick");
		rename("ThickBoostedTemp");
		close("Thick");
		close("ResizedThick");
}

function ThickSliceRollfunction (InputTemp, SliceThickness, RangeMin, RangeMax, Operation, GmmaCor) {
	// Function based on OLK ThickSlice stack generation script for Fiji/ImageJ (v20200212)
				
//		selectWindow(InputVolume);
//		print("Slice range : ",RangeMin, " ,", RangeMax);
		Range = RangeMax-RangeMin; 
		print("Range : ", Range, "clices"); 
		ThickSliceNumber = Range - SliceThickness; 
		print("Thick slice stack size (slices) : ", ThickSliceNumber);
		
			 
		setBatchMode(true);
		print(" "); //add empty line to capture progress
		for (i = 0; i < ThickSliceNumber; i++) {
		
			ThicknessMinTemp = RangeMin + i; 
			counter = i+1;
			// print("\\Update:" + "Processing :", counter, " / ", ThickSliceNumber, "  | Slice: ", ThicknessMinTemp);
			print("\\Update:" + "Processing :", counter, " / ", ThickSliceNumber);
			ThicknessMaxTemp = ThicknessMinTemp + SliceThickness; // print(ThicknessMaxTemp);
		
			selectWindow(InputTemp);
			run("Duplicate...", "duplicate range=&ThicknessMinTemp-&ThicknessMaxTemp");
			rename("TempThickSliceStack");
			run("Z Project...", "projection=&Operation");
			if (i == 0) { 
				rename("ThickSliceStack");
			}else {
				ThickSliceTempName = (i+1); 
				rename(ThickSliceTempName);
				close("TempThickSliceStack");
			}
			if (i != 0) {
				img2 = ThickSliceTempName;
				run("Concatenate...", "title=ThickSliceStack open image1=ThickSliceStack image2=&img2");
			}
		  }
		setBatchMode(false);
}


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
	waitForUser( "Pause","select Low Intensity (dark area) ROI in Processed Volume and then press OK \n ...");
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
	waitForUser( "Pause","select High Intensity (bright area) in Processed Volume and then press OK \n ...");
	BckCorVolumeTissueSlice = getSliceNumber();
	roiManager("Add"); // Add Wax selection to ROI Manager
	run("Measure"); 
	BckCorVolumeTissue = getResult("Mean"); // get Wax Mean value from LS volume
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
	roiManager("Select", 1); 
	run("Measure"); 
	calBckCorTissue = getResult("Mean"); // get Wax Mean value from LS volume
	Offset = InputVolumeTissue-calBckCorTissue;
	print("Offset (InputVolumeTissue-calBckCorTissue) = ", Offset); 
	run("Select None");
	run("Add...", "value=Offset stack"); 
	resetMinAndMax();
	selectWindow(InputVolume); 
	bitDepthInput = bitDepth();
	//selectWindow("c"+BCorVolumeName);
	selectWindow(BckCorVolumeName);
	if (bitDepthInput == 16) {
		run("16-bit");}
	if (bitDepthInput == 8) {
		run("8-bit");}
	//volume = getTitle();

}




//............................////............................////............................//
//............................////............................////............................//
//............................////............................////............................//
// Main body

//............................//
// get Input volume name      //
//............................//
	waitForUser("Action required", "Select Input Volume window *then* OK [ESC to abort]"); 
	InputVolume = getTitle(); 
	bitDepthVolume = bitDepth();
	print("\\Clear"); // Clear Log Window
	print(InputVolume); 	
	print("bitDepth : ", bitDepthVolume);
	
//............................//
// Wait for user selection    //
//............................//

	//string = "Make selection or continue..." 
	//waitForUser(string)

	//............................//
	// set DEFAULT value          //
	//............................//
		run("Clear Results"); 
		SliceThickness = 5; 
		RangeMin = 1; 
		RangeMax = nSlices; 
		KeepPartialVolume = false; 
		print("- - - - - - - - - -");
		print("Staring script . . . ");
		print("- - - - - - - - - -");
	
	
	//.............................//
	// create box & get USER value //
	//.............................//
	//-----------------------------------------------------------------------
		Dialog.create("User Input Values");	//Creates a dialog box
		Dialog.addMessage("====================================");
	//-----------------------------------------------------------------------
		Dialog.addMessage("THICK SLICE PARAMETERS");
		Dialog.addNumber("SliceThickness..., Number of Slices=:", SliceThickness);
		//Dialog.addMessage("RangeMin..., RangeMin=:", RangeMin);
		//Dialog.addMessage("RangeMax..., RangeMax=:", RangeMax); 		
		//Dialog.addString("Operation..., Operation=:", "Average Intensity"); 
		OperationsArray = newArray("Average Intensity","Max Intensity", "Min Intensity", "Standard Deviation", "Median")
		Dialog.addChoice("Booster Volume | Generate using 3D (thick slice)... " , OperationsArray);
		BoostVolumesCombinationOperationsArray = newArray("Average Intensity","Max Intensity","Min Intensity", "Standard Deviation", "Add","Subtract","Multiply", "Difference")
		Dialog.addChoice("Boosted Volume | Combine Booster with Input volume using... " , BoostVolumesCombinationOperationsArray);
		Dialog.addNumber("Gamma Correction factor..., Gamma=:", 1); 
		Dialog.addCheckbox("Keep Partial Volumes", false);
	//-----------------------------------------------------------------------
	    Dialog.show();
	//-----------------------------------------------------------------------
	//Variables -------------------------------------------------------------
		SliceThickness =Dialog.getNumber();
		//RangeMin =Dialog.getNumber();
		//RangeMax = Dialog.getNumber();
		Operation = Dialog.getChoice(); 
		BoostVolumesCombinationOperation = Dialog.getChoice();
		print(Operation);
		//Dialog.getString(); 
		//EllipseW = Dialog.getNumber();
		GmmaCor = Dialog.getNumber();
		KeepPartialVolume = Dialog.getCheckbox();
	//-----------------------------------------------------------------------



for (i = 0; i < 4; i++) {
	if (i==1) {
		//InputVolume = "XY"; //Replace this with varable in future
		selectWindow(InputVolume); 
		RangeMax = nSlices;
		ThickSliceSNRBoost(InputVolume, SliceThickness, RangeMin, RangeMax, Operation, GmmaCor);
		rename("ThickBoostedXY");
	}
	if (i==2) {
		//InputVolume = "XY"; //Replace this with varable in future
		selectWindow(InputVolume);
		run("Reslice [/]...", "output=1.000 start=Top avoid");
		rename("XZ");  RangeMax = nSlices;
		ThickSliceSNRBoost("XZ", SliceThickness, RangeMin, RangeMax, Operation, GmmaCor);
		run("Reslice [/]...", "output=1.000 start=Top avoid");
		rename("ThickBoostedXZ");
		selectWindow("ThickBoostedTemp");
		close("ThickBoostedTemp"); 
		close("XZ");
	}
		
	if (i==3) {
		//InputVolume = "XY"; //Replace this with varable in future
		selectWindow(InputVolume);
		run("Reslice [/]...", "output=1.000 start=Left avoid");
		rename("YZ");  
		RangeMax = nSlices;
		ThickSliceSNRBoost("YZ", SliceThickness, RangeMin, RangeMax, Operation, GmmaCor);
		run("Reslice [/]...", "output=1.000 start=Top avoid");
		close("ThickBoostedTemp");
		selectWindow("Reslice of ThickBoostedTemp");
		run("Rotate 90 Degrees Left");
		run("Flip Vertically", "stack");
		rename("ThickBoostedYZ");
		
		close("ThickBoostedTemp"); 
		close("YZ");

		}

	}



	imageCalculator(""+BoostVolumesCombinationOperation+" create 32-bit stack", "ThickBoostedXZ","ThickBoostedYZ");
	selectWindow("Result of ThickBoostedXZ"); 
	rename("XZYZ");
	if (KeepPartialVolume==false){
		close("ThickBoostedXZ"); 
		close("ThickBoostedYZ");
	}
	imageCalculator(""+BoostVolumesCombinationOperation+" create 32-bit stack", "XZYZ","ThickBoostedXY");
	selectWindow("Result of XZYZ");
		// Rename processed volume
		if (Operation == "Average Intensity") OperationFileName="AvgInt";
		if (Operation == "Max Intensity") OperationFileName="MaxInt";
		if (Operation == "Add") OperationFileName="SumInt";
		if (Operation == "Min Intensity") OperationFileName="MinInt";
		if (Operation == "Standard Deviation") OperationFileName="StDev";
		if (Operation == "Median") OperationFileName="Med";

		if (BoostVolumesCombinationOperation == "Average Intensity") CombOperationFileName="AvgInt";
		if (BoostVolumesCombinationOperation == "Max Intensity") CombOperationFileName="MaxInt";
		if (BoostVolumesCombinationOperation == "Add") CombOperationFileName="SumInt";
		if (BoostVolumesCombinationOperation == "Min Intensity") CombOperationFileName="MinInt";
		if (BoostVolumesCombinationOperation == "Standard Deviation") CombOperationFileName="StDev";
		if (BoostVolumesCombinationOperation == "Subtract") CombOperationFileName="Sub";
		if (BoostVolumesCombinationOperation == "Multiply") CombOperationFileName="Prod";
		if (BoostVolumesCombinationOperation == "Difference") CombOperationFileName="Dif";
				
		rename("3D"+CombOperationFileName+"-of-" + SliceThickness +"x" + OperationFileName + "_" + InputVolume);
		CalibrationVolumeName = getTitle();
		
	if (KeepPartialVolume==false){
		close("XZYZ"); 
		close("ThickBoostedXY");
	}
/*
		imageCalculator("Multiply create 32-bit stack", CalibrationVolumeName, InputVolume); 
		close(CalibrationVolumeName);
		selectWindow("Result of "+ CalibrationVolumeName); rename(CalibrationVolumeName);
*/
		


//-----------------------------------------------------------------------
//Calibrate and Return to Input's bit-depth
	CalibrateVolume(InputVolume, CalibrationVolumeName);

	
	