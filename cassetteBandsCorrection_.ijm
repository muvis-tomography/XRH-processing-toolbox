//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Fiji/ImageJ script to remove broad bands artefacts caused by beam hardening
// due to the pressece of the cassette for  (v20210224) by OLK
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
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
/*ChangeLog
 *
 * v20210318
 * 	BUG 	selectWindow("BckCor_" + InputVolume); >> 	selectWindow("BC_" + InputVolume); 
 * 	
 * v20210301
 *  * run("Gaussian Blur...", "sigma=20"); >>>  run("Median...", "sigma=20");
 * to correct for gradient on correction filter caused by "air" contribution on GBlur operation
 *
 * v20210301
 * added option for manual selection of area from where the background will be generated
 */

//================================================////================================================//
//============================================CALIBRATION=============================================//
//================================================////================================================//
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
		selectWindow(BckCorVolumeName); resetMinAndMax;
		waitForUser( "Pause","select Wax ROI in BckCorVolume Volume and then press OK \n ...");
		BckCorVolumeWaxSlice = getSliceNumber();
		roiManager("Add"); // Add Wax selection to ROI Manager
		run("Measure"); BckCorVolumeWax = getResult("Mean"); // get Wax Mean value from LS volume
		print("BckCorVolumeWax = ", BckCorVolumeWax); run("Select None");
		//--------------------------------------------------------------------------
		// select BckCor volume volume - Tissue -----------------------------------------------
		run("Clear Results");
		selectWindow(BckCorVolumeName);
		waitForUser( "Pause","select Tissue ROI in LS Volume and then press OK \n ...");
		BckCorVolumeTissueSlice = getSliceNumber();
		roiManager("Add"); // Add Wax selection to ROI Manager
		run("Measure"); BckCorVolumeTissue = getResult("Mean"); // get Wax Mean value from LS volume
		print("BckCorVolumeTissue = ", BckCorVolumeTissue); run("Select None");

		//--------------------------------------------------------------------------
		// select Input volume - Wax ----------------------------------------------
		run("Clear Results");
		selectWindow(InputVolume);
		setSlice(BckCorVolumeWaxSlice); // go to appropriate slice in the stack
		roiManager("Select", 0); run("Measure"); InputVolumeWax = getResult("Mean"); // get Wax Mean value from LS volume
		print("InputVolumeWax = ", BckCorVolumeWax); run("Select None");
		//--------------------------------------------------------------------------
		// select Input volume - Tissue -------------------------------------------
		run("Clear Results");
		selectWindow(InputVolume);
		setSlice(BckCorVolumeTissueSlice); // go to appropriate slice in the stack
		roiManager("Select", 1); run("Measure"); InputVolumeTissue = getResult("Mean"); // get Wax Mean value from LS volume
		print("InputVolumeWax = ", InputVolumeTissue); run("Select None");


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
		selectWindow(BckCorVolumeName); rename("c"+BckCorVolumeName); // "c" for Calibrate

		// Match contrast using the CalFactor ---------
		run("Multiply...", "value=CalFactor stack");

		// Offset BckCorVolume tissue intensity to match InputVolume's -----
		setSlice(BckCorVolumeTissueSlice); // go to appropriate slice in the stack
		roiManager("Select", 1); run("Measure"); calBckCorTissue = getResult("Mean"); // get Wax Mean value from LS volume
		Offset = InputVolumeTissue-calBckCorTissue;
		print("Offset (InputVolumeTissue-calBckCorTissue) = ", Offset); run("Select None");
		run("Add...", "value=Offset stack"); resetMinAndMax();
		selectWindow(InputVolume); bitDepthInput = bitDepth();
		selectWindow("c"+BckCorVolumeName);
		if (bitDepthInput == 16) {
			setMinAndMax(0, 65535); run("16-bit");}
		if (bitDepthInput == 8) {
			setMinAndMax(0, 255); run("8-bit");}
		volume = getTitle();

	}


//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////
  function Rotate(BandsAngle) {
  	print("Roatating to make bands parallel to the Y-axis based on user input");
  	print("Rotating volume by " + BandsAngle + " degrees \n" );
    roiManager("reset");
	getStatistics(null, meanFill, null, null, null, null);
	run("Rotate... ", "angle=BandsAngle grid=1 interpolation=Bilinear enlarge stack");

	if (bitDepth==32) {
			getMinAndMax(min, max);	setThreshold(0.001, max); run("Threshold...");	}
		else {
			getMinAndMax(min, max);	setThreshold(1, max); run("Threshold...");}

	run("Create Selection"); run("Make Inverse"); run("Enlarge...", "enlarge=2");
	roiManager("Add");
	resetThreshold();
	run("Set...", "value=meanFill stack"); run("Select None");
  }

//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////
  function RotateBack(rotateBackAngle) {
  	run("Select None");
	run("Rotate... ", "angle=rotateBackAngle grid=1 interpolation=Bilinear stack");
	roiManager("Select", 0); run("Make Inverse"); run("Enlarge...", "enlarge=-15");
	run("Rotate...", "rotate angle=rotateBackAngle");
	run("Crop"); roiManager("reset"); run("Select None");
    }







//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////
// Main Script Body
//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////

//.............................//
// create box & get USER value //
//.............................//
run("Clear Results"); BandSuppresionRun = true; calibrationRun = true; BandSuppresionManualRun = false;
//-----------------------------------------------------------------------
	Dialog.create("Suppress broad cassette lines");	//Creates a dialog box
	Dialog.addCheckbox(" Run Background Correction", BandSuppresionRun);
	Dialog.addCheckbox("     Let me select backround area", BandSuppresionManualRun);
	Dialog.addCheckbox(" Run Calibration", calibrationRun);
	Dialog.addMessage("====================================");
//-----------------------------------------------------------------------
    Dialog.show();
//-----------------------------------------------------------------------
//Variables -------------------------------------------------------------
	BandSuppresionRun = Dialog.getCheckbox();
	BandSuppresionManualRun = Dialog.getCheckbox();
	calibrationRun = Dialog.getCheckbox();

//................................................//
// get Input volume name, Date and print details  //
//................................................//
	waitForUser("Action required", "Select Input Volume window *then* OK [ESC to abort]");
	InputVolume = getTitle(); bitDepthVolume = bitDepth();
	print("\\Clear"); // Clear Log Window
	getDateAndTime(year, month, week, day, hour, min, sec, msec); //N.B. 'month' and 'dayOfWeek' are zero-based indexes
		month = month +1; // add 1 to month to make it 1-based index
		if (month < 10) {monthStr ="0" + month;} else {monthStr ="" + month;} //change month to format Jan = 01, Feb =02, ...
		if (day<10) {dayStr = "0"+day;} else {dayStr = ""+day;}
		print("Date: "+year+"/"+monthStr+"/"+dayStr); //print(month);
	  	YYYYDDMM = ""+year +""+monthStr+""+dayStr; //print(YYYYDDMM);
		print("Volume name :",InputVolume); print("bitDepth : ", bitDepthVolume);
		if (getBoolean("Is the volume resliced to histological-relevant orientation?") ==0) {
			print("Not properly oriented volume. Exiting! \n (Note: Run Histological Relevant Reslice first and try again)");
			exit("Not properly oriented volume. Exiting! \n \n ( Run XRH-Toolbx >> Histological Relevant Reslice first and try again )");
			}

//................................................//
//	get ready
//................................................//
	run("Set Measurements...", "area mean standard modal min centroid center bounding fit feret's integrated median stack redirect=None decimal=7");
	run("Clear Results");
	print("===============Suppressing broad cassette bands===============");
	setTool("line");
	setSlice(nSlices/2);
	selectWindow(InputVolume); run("Duplicate...", "duplicate"); rename("inputTemp");

	//get user input
		waitForUser("Draw line parallel to the broad band you want to suppress");
		getLine(z1x1, z1y1, z1x2, z1y2, null);
		run("Measure"); angleZ = getResult("Angle", 0); drawnLineLength = getResult("Length", 0);

	// canlulate rotation angles and rotate (bands parallel to Y'Y)
		if (angleZ<abs(90)) {
			if (angleZ>0) {rotateAboutZ=-(90-angleZ);} else {rotateAboutZ=-(90-angleZ);}}
		else{
			if (angleZ>0) {rotateAboutZ=(angleZ-90);} else {rotateAboutZ=(angleZ+90);}
			}
	//calculate rotating angle
		angleTempDeg=90-angleZ; //get drawn line and rotate 90o to use for the reslice guide
		angleTempRad = angleTempDeg * PI / 180; //change ang to rad
		dX = cos(angleTempRad) * drawnLineLength / 2;
		dY = sin(angleTempRad) * drawnLineLength / 2;

	 //ignore rotate if angle = +/- 90o; i.e. bands already parallel to Y-axis
		selectWindow("inputTemp"); run("Select None");

		if (rotateAboutZ != 0){
			if (abs(rotateAboutZ) != 180){
				Rotate(rotateAboutZ);
				}
		}

selectWindow("inputTemp");
getDimensions(inputWidth, inputHeight, null, inputSlices, null);


if (BandSuppresionManualRun) {
		// reslice user-defined sub volume (top) to get the bands parallel to stack Z-axis
		setTool("rectangle"); run("Select All");
		waitForUser("Select sub-volume", "Select sub-volume and THEN press OK \n \nGrub and drag the top- and bottom-middle selection handlers. \n Drag to modify sub-volume on which the background will be calculated. \n \nDo *not* modify the width of the selection, and try to select an area \n with no wax voids or other high-contrast elements");
		}

	// reslice volume (top) to get the bands parallel to stack Z-axis
		run("Reslice [/]...", "output=1.000 start=Top avoid"); rename("topReslice");
		selectWindow("topReslice");

	// Z-project AVG to get background and blur to lose tissue details
		run("Z Project...", "projection=[Average Intensity]"); run("32-bit"); rename("AVG_bck");
		//run("Gaussian Blur...", "sigma=20");
		run("Median...", "sigma=20");

if (BandSuppresionManualRun == false) {
	// Z-project stDev to get tissue contribution to the background and remove it
		selectWindow("topReslice");
		run("Z Project...", "projection=[Standard Deviation]"); rename("StDev_bck");
		//run("Gaussian Blur...", "sigma=20");
		run("Median...", "sigma=20");
		imageCalculator("Subtract create 32-bit", "AVG_bck","StDev_bck"); rename("BckProjection");
		}
for (n=1; n<=inputSlices; n++) {
	sliceNo = n;

	setBatchMode(true);
		selectWindow("inputTemp"); run("Select None"); setSlice(sliceNo);
		run("Duplicate...", "title=slice"); run("32-bit");

		if (BandSuppresionManualRun) {
				selectWindow("AVG_bck");}
			else {
				selectWindow("BckProjection");
			}

		SliceBckFrameStart = sliceNo-1;
		makeRectangle(0, SliceBckFrameStart, inputWidth, 1);
		run("Duplicate...", " ");
		run("Size...", "width=inputWidth height=inputHeight depth=1 average interpolation=Bilinear"); rename("SliceBck");

		//getStatistics(null, SliceBckMean, SliceBckMin, SliceBckMax, SliceBckStdev, null);
		getMinAndMax(SliceBckMin, SliceBckMax);
		run("32-bit"); run("Divide...", "value=SliceBckMax");
		setMinAndMax(0, 1);

		imageCalculator("Divide create 32-bit", "slice","SliceBck");

		if (n==1) {
				selectWindow("Result of slice"); rename("BckCor-temp"); }
			else {
				run("Concatenate...", " title=BckCor-temp image1=BckCor-temp image2=[Result of slice] image3=[-- None --]");
				setSlice(nSlices);
			}
	setBatchMode(false);

	}

//rename resulted volume
	selectWindow("BckCor-temp"); rename("BC_" + InputVolume);

//rotate back to initial volume orientation
	if (rotateAboutZ != 0){
		if (abs(rotateAboutZ) != 180){
			rotateBackAboutZ = -rotateAboutZ;
			RotateBack(rotateBackAboutZ); //Rotate back volume and crop to remove empty camvas cells
		}
	}

//Clean up
	//selectWindow("topReslice"); close();
	selectWindow("inputTemp"); close();
	//selectWindow("AVG_bck"); close();
	if (BandSuppresionManualRun == false) {
		selectWindow("StDev_bck"); close();
		selectWindow("BckProjection"); close();
		}

//Calibrate BckCorrected volume
if (calibrationRun==true) {
	selectWindow("BC_" + InputVolume);
	BckCorVolumeName = getTitle();
	CalibrateVolume(InputVolume, BckCorVolumeName);

}
