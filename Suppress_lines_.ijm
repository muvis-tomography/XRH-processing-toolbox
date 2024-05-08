//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Suppress Lines Filter by OLK v20210216 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
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

function LSVisualisation(volume, InputVolume) { 
	// Generate LS visualisation 
	
	//Duplicate central slices
		
		selectWindow(InputVolume);
		setSlice(nSlices/2); 
		run("Duplicate...", "title=Montage-input");
		run("Enhance Contrast", "saturated=0.035"); 
		run("8-bit");
		selectWindow(volume); 
		setSlice(nSlices/2); 
		run("Duplicate...", "title=Montage-LS");
		run("Enhance Contrast", "saturated=0.035"); 
		run("8-bit");
	
	// Calculate difference image & convert to 8-bit
		imageCalculator("Difference create", "Montage-input","Montage-LS");	
		run("Enhance Contrast", "saturated=0.035");
		selectWindow("Result of Montage-input"); 
		rename("Montage-diff");  
		run("8-bit");
	
	// Make montage
		// combine input with output
			run("Combine...", "stack1=Montage-input stack2=Montage-LS");
			run("Enhance Contrast", "saturated=0.35");  
			run("8-bit");
		// combite input+output with differnce
			run("Combine...", "stack1=[Combined Stacks] stack2=Montage-diff");
			resetMinAndMax(); 
			run("Enhance Contrast", "saturated=0.35"); 
			run("8-bit");
	
	rename("LinesSuppression_Input-Output-Difference");
		
} // end of function




//............................//
// set DEFAULT value          //
//............................//
	run("Clear Results"); 
	NoLines = 1; 
	BandWidth = 0.02; 
	EllipseW = 0.005; 
	GmmaCor=0.985; 
	LSrun = true; 
	calibrationRun = true;
	print("- - - - - - - - - -");
	print("Staring script . . . ");
	print("- - - - - - - - - -");

//.............................//
// create box & get USER value //
//.............................//
//-----------------------------------------------------------------------
	Dialog.create("User Input Values");	//Creates a dialog box
	Dialog.addCheckbox(" Run Lines Suppression", LSrun);
	Dialog.addCheckbox(" Run Calibration", calibrationRun);  
	Dialog.addMessage("====================================");
//-----------------------------------------------------------------------
	Dialog.addMessage("SUPPRESS LINES PARAMETERS");
	Dialog.addNumber("No of Dif. line oriendations..., Lines=:", NoLines);
	Dialog.addNumber("Frequency Bandwidth..., BandWidth=:", 0.01); 		
	Dialog.addNumber("Orientation rigidity..., EllipseWidth=:", 0.005); 
	Dialog.addNumber("Gamma Correction factor..., Gamma=:", 0.985); 
//-----------------------------------------------------------------------
    Dialog.show();
//-----------------------------------------------------------------------
//Variables -------------------------------------------------------------
	LSrun =Dialog.getCheckbox();
	calibrationRun =Dialog.getCheckbox();
	NoLines = Dialog.getNumber();
	BandWidth = Dialog.getNumber();
	EllipseW = Dialog.getNumber();
	GmmaCor = Dialog.getNumber();
	Angle =newArray(NoLines);
	
//-----------------------------------------------------------------------
// get Input volume name
waitForUser("Action required", "Select Input Volume window *then* OK [ESC to abort]"); 
InputVolume = getTitle(); bitDepthInput = bitDepth();

//-----------------------------------------------------------------------
// Check and Run Line Suppression  //
//-----------------------------------------------------------------------
if (LSrun==true) {
	// dublicate volume and start the script
	run("Duplicate...", "duplicate"); 
	run("32-bit"); rename("LS_"+InputVolume); 
	volume = getTitle();
	selectWindow(volume); 
	setTool("line");
	for (i = 1; i <= NoLines; i++) {
		waitForUser("Draw Line!"); 
		run("Measure"); 
		Angle[i-1] =getResult("Angle", i-1); 
		print("Angle :", Angle[i-1], "Filter angle :", Angle[i-1]+90);
		//Hypotenuse[i-1] =getResult("Length", i-1); print(Hypotenuse[i-1]);
	}
	
	selectWindow(volume); 
	run("FFT"); 
	selectWindow("FFT of " + volume);
	
	//Get Dimensions
	Width=getWidth(); 
	Height=getHeight();
	
	// Elipse calculations
	// hypotenuse_temp = ((Width/2)*(Width/2)+(Height/2)*(Height/2)); print("hypotenuse_temp =" + hypotenuse_temp);
	// hypotenuse45 = sqrt(hypotenuse_temp); print("hypotenuse45 =" + hypotenuse45);
	
	setForegroundColor(0, 0, 0);
	for (i = 1; i <= NoLines; i++) {
		// 1st hald of FFT
		print("drawing elipse 1 of 2 for angle No: " + i);
		//hypotenuse = cos(Angle[i-1])*hypotenuse45;
		X_temp_b = (cos((Angle[i-1]+90)*PI/180)*Width);  ///*
		Y_temp_b = (sin((Angle[i-1]+90)*PI/180)*Height); ///*
		X_temp_a = floor(Width/2);
		Y_temp_a = floor(Height/2);
		slope = (X_temp_b - X_temp_a)/(Y_temp_b - Y_temp_a);
	
		X1a = (Width/2);
		Y1a = (Height/2);
		if (Angle[i-1]+90 < 0) {
			X1b = floor(Width/2 + (X_temp_b)); 
			Y1b = floor(Height/2 - (Y_temp_b));///- --> +
						//Y1b = 0; }
		}else {
			X1b = floor(Width/2 - (X_temp_b)); 
			Y1b = floor(Height/2 + (Y_temp_b));
		} ///+ --> -
			//Y1b = 0; }
		
	//	EF = hypotenuse45/sqrt((X1b-X1a)*(X1b-X1a)+(Y1b-Y1a)*(Y1b-Y1a)); //EnlogationFactor
		
		print ("X,Y1a: ", X1a, Y1a, "|| X,Y1b: ", X1b, Y1b, "|| slope: ", slope, "|| X,Y_temp: ", X_temp_b, Y_temp_b);
		MaskR = Width*BandWidth; 
		MaskX = Width/2-MaskR; 
		MaskY = Width/2-MaskR; 
		MaskDiam = MaskR*2; 
		makeEllipse(X1a, Y1a, X1b, Y1b, EllipseW); 
		setKeyDown("alt"); 
		makeOval(MaskX, MaskX, MaskDiam, MaskDiam);
		run("Fill", "slice"); 
	
		// 2nd hald of FFT	
		print("drawing elipse 2 of 2 for angle No: " + i);
		X2b = Width - X1b; 
		Y2b = Height - Y1b;
		makeEllipse(X1a, Y1a, X2b, Y2b,EllipseW); 
		setKeyDown("alt"); 
		makeOval(MaskX, MaskX, 
		MaskDiam, MaskDiam);
		run("Fill", "slice"); 
		run("Select None");
	}
	
		run("Duplicate...", " "); 
		rename("FFTSpace"); 
		selectWindow("FFT of " +  volume); 
		close();
		selectWindow(volume);
		
	for (i=1; i<=nSlices; i++) {
		setBatchMode(true); // suppress printouts
		setSlice(i);
		selectWindow(volume); 
		run("Select None"); 
		run("Custom Filter...", "filter=FFTSpace"); //resetMinAndMax();
		//selectWindow("FFTSpace"); close();
		setBatchMode(false);
	}
	
	// Gamma correction to return contrast levels
	selectWindow(volume); 
	run("Gamma...", "value=GmmaCor stack"); //run("16-bit");
}

// if calibrationRun == false generate difference visualisation now, if true, continue to Calbiration
if (calibrationRun == false) {
	LSVisualisation(volume, InputVolume);
}

//================================================////================================================//
//============================================CALIBRATION=============================================//
//================================================////================================================//
if (calibrationRun==true) {

  //check is Suppress lines was bypassed and if so set volume name
	if (LSrun == false) {
		run("Duplicate...", " "); 
		rename("LS_"+InputVolume); 
		volume = getTitle(); 
		close();
		print(InputVolume);
		print(volume);
	}

  if (isOpen("ROI Manager")) {
     selectWindow("ROI Manager");
     run("Close");
  }

	// Grey Calibration to match input volume//
	run("Set Measurements...", "area mean standard modal min centroid center bounding fit feret's integrated median redirect=None decimal=7");
	
	print("- - - - - - - - - -");
	print("Calibrating LS volume . . . ");
	print("- - - - - - - - - -");

	//--------------------------------------------------------------------------
	// select LS volume - Wax --------------------------------------------------
	setTool("rectangle");
	run("Clear Results");
	selectWindow(volume); 
	resetMinAndMax;
	waitForUser( "Pause","select Wax ROI in LS Volume and then press OK \n ..."); 
	LSWaxSlice = getSliceNumber();
	roiManager("Add"); // Add Wax selection to ROI Manager
	run("Measure"); 
	LSWax = getResult("Mean"); // get Wax Mean value from LS volume
	print("LSWax = ", LSWax); 
	run("Select None");	
	//--------------------------------------------------------------------------
	// select LS volume - Tissue -----------------------------------------------
	run("Clear Results");
	selectWindow(volume); 
	waitForUser( "Pause","select Tissue ROI in LS Volume and then press OK \n ..."); 
	LSTissueSlice = getSliceNumber();
	roiManager("Add"); // Add Wax selection to ROI Manager
	run("Measure"); 
	LSTissue = getResult("Mean"); // get Wax Mean value from LS volume
	print("LSWax = ", LSTissue); 
	run("Select None");

	//--------------------------------------------------------------------------
	// select Inpupt volume - Wax ----------------------------------------------
	run("Clear Results");
	selectWindow(InputVolume); 
	setSlice(LSWaxSlice); // go to appropriate slice in the stack
	roiManager("Select", 0); 
	run("Measure"); 
	InputVolumeWax = getResult("Mean"); // get Wax Mean value from LS volume
	print("InputVolumeWax = ", InputVolumeWax); 
	run("Select None");
	//--------------------------------------------------------------------------
	// select Inpupt volume - Tissue -------------------------------------------
	run("Clear Results");
	selectWindow(InputVolume); 
	setSlice(LSTissueSlice); // go to appropriate slice in the stack
	roiManager("Select", 1); 
	run("Measure"); 
	InputVolumeTissue = getResult("Mean"); // get Wax Mean value from LS volume
	print("InputVolumeWax = ", InputVolumeTissue); 
	run("Select None");
	
	
	//............................//
	// set values for grey calibration  //
	//............................//
	CfactorInputVolume = (InputVolumeTissue-InputVolumeWax)/InputVolumeTissue; 
	CfactorLSVolume = (LSTissue-LSWax)/LSTissue; 
	CalFactor = 	CfactorInputVolume/CfactorLSVolume; 
	//.............................//
	// create box & get USER value //
	//.............................//
	Dialog.create("User Input Values");	//Creates a dialog box
	Dialog.addNumber("Tissue|Wax contrast measured in Input Volume..., CfactorPhantom=:", CfactorInputVolume); 					// Resolution input
	Dialog.addNumber("Tissue|Wax contrast measured in LS Volume..., CfactorLSVolume=:", CfactorLSVolume); 
	Dialog.addNumber("Calculated Calibration Factor..., CalFactor=:", CalFactor); 
	//Dialog.addNumber("Offset..., Offset=:", Offset);
	Dialog.show();
	CfactorPhantom = Dialog.getNumber();
	CfactorScan = Dialog.getNumber();
	CalFactor = Dialog.getNumber();
	//Offset = Dialog.getNumber();
	
	waitForUser( "Pause", "      The volume: \n" + volume + "\n      will be calibrated to match \n" + InputVolume + "\n      press OK \n ...");
	selectWindow(volume); 
	run("Duplicate...", "duplicate"); 
	rename("c"+volume); // "c" for Calibrate

	// Match contrast using the CalFactor ---------
	run("Multiply...", "value=CalFactor stack"); 
	
	// Offset LSVolume tissue intensity to match InputVolume's -----
	setSlice(LSTissueSlice); // go to appropriate slice in the stack
	roiManager("Select", 1); 
	run("Measure"); 
	calLSTissue = getResult("Mean"); // get Wax Mean value from LS volume
	Offset = InputVolumeTissue-calLSTissue;
	print("Offset (InputVolumeTissue-calLSTissue) = ", Offset); 
	run("Select None");
	run("Add...", "value=Offset stack"); 
	resetMinAndMax();
	if (bitDepthInput == 16) {
		setMinAndMax(0, 65535); 
		run("16-bit");
	}
	if (bitDepthInput == 8) {
		setMinAndMax(0, 255); 
		run("8-bit");
	}
	volume = getTitle(); 
	close("LS_"+InputVolume);


// Generate difference visualisation now
	LSVisualisation(volume, InputVolume);
}


	
