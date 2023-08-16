//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Auto Video Generation Single & Thick Slices Roll script for Fiji/ImageJ (v20200509) by OLK  ~~~~~~~~
/*
   Copyright 2018 University of Southampton
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
/* ChangeLog v20200619
 *  bug-fix: YYYYDDMM changed to YYYYMMDD
 *  bug-fix: YYYYMMDD var added as input to ExportVideoDescription funtion
 *  manual crop added to HistRelevantReslice
 */
/* ChangeLog v20200509
 *  1. added hour and min in YYYYMMDD to avoid multiple files having the same name
 */
/* ChangeLog v20200506
 1. fixed issue where algorithm will continue to manual thick slices when both automatic thick slice and manual thick slice options were off
 2. added auto save descriptions
 3. added source volume name in description file
 4. removed source volume name from video filename to shorten filename and added YYYYMMDD
 5. added option to manual contrast thickSliceRoll
 6. re-arranged menu
 7. removed SumInt and added StDev
 8. 'month' and 'dayOfWeek' are zero-based indexes +1 added to correctly display date
*/



//////////////////////////////////////////////////////////////////////////
//-----------------------------------------------------------------------/
// get Input parameters
//-----------------------------------------------------------------------/
//////////////////////////////////////////////////////////////////////////

//............................//
// get Input volume name      //
//............................//
	waitForUser("Action required", "Select Input Volume window *then* OK [ESC to abort]"); 
	InputVolume = getTitle(); bitDepthVolume = bitDepth();
	print("\\Clear"); // Clear Log Window
	getDateAndTime(year, month, week, day, hour, min, sec, msec); //N.B. 'month' and 'dayOfWeek' are zero-based indexes
		month = month +1; // add 1 to month to make it 1-based index
		if (month < 10) {monthStr ="0" + month;} else {monthStr ="" + month;} //change month to format Jan = 01, Feb =02, ...
		if (day<10) {dayStr = "0"+day;} else {dayStr = ""+day;}  	
		print("Date: "+year+"/"+monthStr+"/"+dayStr); //print(month);
	  	YYYYMMDD = ""+year +""+monthStr+""+dayStr + "-" + hour + "h" + min + "m"; print(YYYYMMDD);
	print("Volume name :",InputVolume); print("bitDepth : ", bitDepthVolume);

//............................//
// Wait for user selection    //
//............................//

	string = "1. Check Brightness & Contrast for Signle Slice Roll and tune if needed. \n2. Make selection or Continue..." ;
	setTool("rectangle"); run("Brightness/Contrast...");
	waitForUser(string);
	
//............................//
// set DEFAULT value          //
//............................//
	run("Clear Results"); SliceThickness = 20; RangeMin = 1; RangeMax = nSlices; EnhanceVideoContrast = 0.25;
	XYZstackVideos = false; ThickSliceVideos = false;
	print("- - - - - - - - - -");
	print("Staring script . . . ");
	print("- - - - - - - - - -");

//.............................//
// create box & get USER value //
//.............................//
//-----------------------------------------------------------------------
	Dialog.create("User Input Values");	//Creates a dialog box
	Dialog.addMessage("Auto Generate:");
	Dialog.addCheckbox("X,Y,Z Slice Roll videos", true); //1
	Dialog.addCheckbox("MIP, AVG, SUM ThickSlice Roll videos", true) //2
	Dialog.addMessage("====================================");
	Dialog.addMessage("Easy Stack Reslice:");
	Dialog.addCheckbox("Reslice volume to histological-relevant planes", false) //3
	Dialog.addMessage("====================================");
	Dialog.addMessage("Thick Slice Parameters");
	Dialog.addNumber("SliceThickness..., Number of Slices=:", SliceThickness); //4
	Dialog.addNumber("RangeMin..., RangeMin=:", RangeMin); //5
	Dialog.addNumber("RangeMax..., RangeMax=:", RangeMax); //6		
	Dialog.addMessage("---- Enhance Video Contrast ----");
	Dialog.addNumber("Gamma Correction factor..., Gamma=:", 0.985); //7
	Dialog.addNumber("Auto Enhancement [0 -1], Saturation=:", EnhanceVideoContrast); //8
	Dialog.addCheckbox("Allow manual Enhancement", true) //9
	Dialog.addMessage("====================================");
	Dialog.addMessage("Thick Slice stack preview");
	Dialog.addMessage("N.B. All Auto Generate options need to be deselected"); 
	Dialog.addCheckbox("Create Thick Slice stack only", false) //10
	OperationsArray = newArray("Average Intensity","Max Intensity", "Sum Slices", "Min Intensity", "Standard Deviation");
	Dialog.addChoice("Operation: " , OperationsArray); //11
//-----------------------------------------------------------------------
    Dialog.show();
//-----------------------------------------------------------------------
//Variables -------------------------------------------------------------
	XYZstackVideos =Dialog.getCheckbox(); //1
	ThickSliceVideos =Dialog.getCheckbox(); //2
	//==
	ResliceVolume =Dialog.getCheckbox(); //3
	SliceThickness =Dialog.getNumber(); //4
	RangeMin =Dialog.getNumber(); //5
	RangeMax = Dialog.getNumber(); //6
	GmmaCor = Dialog.getNumber(); //7
	EnhanceVideoContrast =Dialog.getNumber(); //8
	ThickSliceManualContrast =Dialog.getCheckbox(); //9
	ThickSliceStackOnly =Dialog.getCheckbox(); //10
	Operation = Dialog.getChoice(); //11


	if (ThickSliceManualContrast == true) {
		MinMaxManualContrast = ManualThickSliceContrast(); //Array.print(MinMaxManualContrast);
	}
	
	
//if Thick Slice stack only was selected, check that no Auto Generation options were selected too
	if ((ThickSliceStackOnly && XYZstackVideos) || (ThickSliceStackOnly && ThickSliceVideos)){waitForUser("Some Auto Generate options were selected. Exiting!"); exit();}
	else {print("Generating Thick Slice stacks only.");}

// Get save path if Auto generate is selected
	if (XYZstackVideos || ThickSliceVideos) {
		VideoSavePath =getDirectory("Choose a Directory");
	}

selectWindow(InputVolume);
print("Slice range : ",RangeMin, " ,", RangeMax);
Range = RangeMax-RangeMin; print("Range : ", Range, "slices"); 
ThickSliceNumber = Range - SliceThickness; print("Thick slice stack size (slices) : ", ThickSliceNumber);
print("Slice Thickness (slices) :", SliceThickness);
print(" ");



//////////////////////////////////////////////////////////////////////////
//-----------------------------------------------------------------------/
// Reslice volume to histological-relevant planes
//-----------------------------------------------------------------------/
//////////////////////////////////////////////////////////////////////////
if (ResliceVolume) {

   function SimpleCropVolume() {
	//Crop to remove empty canvas cells maintaining all CT-volume data
	run("Select None");
	CropVolumeName = getTitle();
	
	getDimensions(width, height, null, null, null); widthCrop = width+25; heightCrop=height+25;
	run("Canvas Size...", "width=widthCrop height=heightCrop position=Center zero"); //increase canvas to make sure 0 excist around the image
	getMinAndMax(min, max);	setThreshold(2, max); run("Threshold...");
	run("Create Selection"); resetThreshold();
	run("Crop"); run("Select None"); //crop the volume
  }
	
  function CropToWax(){
	//Crop to Wax to reduce volume size
	//N.B. Wax needs to be aligned along the Z-plane at this stage or else you will end up cropping wax/tissue
	run("Select None");
	CropVolumeName = getTitle();
	
	//generate temp AVG Z-project to work out cropping mask that excludes air
	run("Z Project...", "projection=[Average Intensity]"); rename("AVG");
	setAutoThreshold("Intermodes  dark"); run("Threshold..."); run("Convert to Mask"); close("Threshold");"
	run("Options...", "iterations=3 count=1 do=Nothing"); run("Open");
	run("Options...", "iterations=20 count=1 do=Nothing"); run("Dilate");
	run("Options...", "iterations=1 count=1 do=Nothing"); //restore defaults
	run("Divide...", "value=255"); // convert to mask [0,1] binary mask
	
	selectWindow(CropVolumeName);
	imageCalculator("Multiply stack", CropVolumeName,"AVG"); close("AVG"); //apply crop mask
	setAutoThreshold("Intermodes dark"); run("Threshold...");
	run("Create Selection"); resetThreshold();
	run("Crop"); run("Select None"); //crop the volume
  }

  function CropToWaxManual(){
  	run("Select None");
	CropVolumeName = getTitle();
	
	setTool("rectangle");
	string = "Make selection or continue..." ;
	waitForUser(string);
	run("Crop"); run("Select None"); //crop the volume
  }

  

//............................//
// get Input volume name      //
//............................//
	waitForUser("Action required", "Select Input Volume window *then* OK [ESC to abort]"); 
	InputVolume = getTitle(); bitDepthVolume = bitDepth();
	print("\\Clear"); // Clear Log Window
	getDateAndTime(year, month, week, day, hour, min, sec, msec); //N.B. 'month' and 'dayOfWeek' are zero-based indexes
		month = month +1; // add 1 to month to make it 1-based index
		if (month < 10) {monthStr ="0" + month;} else {monthStr ="" + month;} //change month to format Jan = 01, Feb =02, ...
		if (day<10) {dayStr = "0"+day;} else {dayStr = ""+day;}  	
		print("Date: "+year+"/"+monthStr+"/"+dayStr); //print(month);
	  	YYYYMMDD = ""+year +""+monthStr+""+dayStr; //print(YYYYMMDD);
	print("Volume name :",InputVolume); print("bitDepth : ", bitDepthVolume);

//.............................//
// create box & get USER value //
//.............................//

	Dialog.create("User Input Values");	//Creates a dialog box
	Dialog.addMessage("Cropping option");
	OperationsArray = newArray("Manual", "Automatic");
	Dialog.addChoice("Cropping to wax: " , OperationsArray); //11
	//-----------------------------------------------------------------------
    Dialog.show();
	//-----------------------------------------------------------------------
	CropSelection = Dialog.getChoice(); //11

	
//get ready
	run("Set Measurements...", "area mean standard modal min centroid center bounding fit feret's integrated median stack redirect=None decimal=7");
	run("Clear Results");
	print("===============Reslicing volume to histological-relevant planes===============");
	setTool("line");
	setSlice(nSlices/2);
	selectWindow(InputVolume); run("Duplicate...", "duplicate"); rename("InputVolume_temp");

	//get user input
		waitForUser("Draw line parallel to the tissue on the wax/air interface");
		getLine(z1x1, z1y1, z1x2, z1y2, null);	
		run("Measure"); angleZ = getResult("Angle", 0); drawnLineLength = getResult("Length", 0);
	
	// canlulate rotation angles
		if (angleZ<abs(90)) {
			if (angleZ>0) {rotateAboutZ=-(90-angleZ);} else {rotateAboutZ=-(90-angleZ);}}
		else{
			if (angleZ>0) {rotateAboutZ=(angleZ-90);} else {rotateAboutZ=(angleZ+90);}
			}
		
		angleTempDeg=90-angleZ; //get drawn line and rotate 90o to use for the reslice guide
		angleTempRad = angleTempDeg * PI / 180; //change ang to rad
		dX = cos(angleTempRad) * drawnLineLength / 2; 
		dY = sin(angleTempRad) * drawnLineLength / 2;
	
	//get the centre of the image to draw the reslice guide
		getDimensions(width, height, null, null, null);
		centerX=width/2 ; centerY = height/2; 
		run("Select None");
	
	//draw the reslice guide 90o to the drawn using centre and angle
		makeLine(centerX - dX, centerY - dY, centerX + dX, centerY + dY); 
		
	// reslice and get user input
		run("Reslice [/]...", "output=1.000 start=Top avoid"); rename("SliceZtemp");
		waitForUser("Draw line parallel to the tissue on the wax/air interface");
		run("Measure"); angleY = getResult("Angle", 1); close("SliceZtemp");
		
	// canlulate rotation angles
		if (angleY<abs(90)) {
			if (angleY>0) {rotateAboutY=-(90-angleZ);} else {rotateAboutY=-(90-angleY);}}
		else{
			if (angleY>0) {rotateAboutY=(angleZ-90);} else {rotateAboutY=(angleY+90);}
			}
	
	selectWindow("InputVolume_temp");
	print("rotating about Z-axis by :",rotateAboutZ,"degrees"); //Angle to make wax face || to Y'Y
	run("Select None");
	run("Rotate... ", "angle=rotateAboutZ grid=1 interpolation=Bicubic enlarge stack");
	SimpleCropVolume(); //Call CropVolume function to to remove empty camvas cells
	run("Reslice [/]...", "output=1.000 start=Top avoid"); rename("InputVolume_temp_reslice");
	close("InputVolume_temp");
	
	selectWindow("InputVolume_temp_reslice");
	print("rotating about Y-axis by :",rotateAboutY,"degrees"); //Angle to make wax face || to X'X
	setSlice(nSlices/2);
	run("Rotate... ", "angle=rotateAboutY grid=1 interpolation=Bicubic enlarge stack");
	run("Rotate 90 Degrees Right");
	if (CropSelection == "Automatic") {
		CropToWax(); } //Call CropToWax function to to remove empty camvas cells and some air 
	else {
		CropToWaxManual(); //Call CropToWaxManual function to to remove empty camvas cells and some air
	}

	run("Reslice [/]...", "output=1.000 start=Top avoid"); rename("Reslice_" + InputVolume);
	
	InputVolume = getTitle(); //reasign InputVolume name to resliced volume
	close("InputVolume_temp_reslice");

	waitForUser("Please scroll through the resliced volume and check that \nyou are happy with the slicing direction. \n \nIf not, you can inverse the stack order, on the next step" );
	Dialog.create("Reverse or not Reverse?");
	items = newArray("It looks good. Do Nothing.", "Stack needs revercing. Reverce now!");
	Dialog.addRadioButtonGroup("You happy with the rolling? \nIs rolling from tissue towards the cassette?", items, 2, 1, "It looks good. Do Nothing.");
	Dialog.show();
	ReverseStackCheck=Dialog.getRadioButton();
	if (ReverseStackCheck == "Stack needs revercing. Reverce now!") {
	  	selectWindow(InputVolume); run("Reverse");
	  	print("User said: "+ReverseStackCheck);
	  	}
} //end if ResliceVolume







//////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////
//-----------------------------------------------------------------------/
// Auto generate Videosideos
//-----------------------------------------------------------------------/
//////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////

function CheckStackDimensions (){
	getDimensions(width, height, channels, slices, frames);
	//print("-------------------- Checking Stack's dimensions --------------------");
	//print("Checking all dimensions of the stack are devided by 2 to avoid errors with some video codecs");
	//print("X,Y,Z dimensions =", width, height, slices);
		
	if (slices % 2 != 0) {
		setSlice(nSlices); 
		run("Delete Slice"); //print("Z-dimension size is ", slices, "  Deleting last slice.");
	}
	
	if (width % 2 != 0) {widthOdd = width -1; } //print("X-dimension size is ", width, "  Reducing by one.");}
	 else {widthOdd = width; }
		
	if (height % 2 != 0) {heightOdd = height -1; } //print("Y-dimension size is ", width, "  Reducing by one."); print("");}
	else {heightOdd = height;}
	
	run("Specify...", "width=widthOdd height=heightOdd x=0 y=0"); run("Crop");
	run("Select None");
	
	if (width < height) {run("Rotate 90 Degrees Right");} //rotate to better fit a wide-screen video
	run("Scale to Fit");
	
}


// . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .

function MIPbasedContrast () { //automatic contrast adjustment
	resetMinAndMax();
	CentrBlock1=((nSlices/2) - nSlices/5); 
	CentrBlock2=((nSlices/2) + nSlices/5);
	run("Duplicate...", "duplicate range=CentrBlock1-CentrBlock2");
	run("Z Project...", "projection=[Max Intensity]");
	run("Enhance Contrast", "saturated=EnhanceVideoContrast");
	//run("Enhance Contrast", "saturated=0.25");
	getMinAndMax(min, max); //print(min,max);
	close(); close(); //Close Z-stack and then the sampled central portion
	setMinAndMax(min, max-abs(max/10));
}

// . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .

function ManualThickSliceContrast () {
	//resetMinAndMax();
	ContrastOperationsArray = newArray("Average Intensity", "Max Intensity", "Standard Deviation");
	MinMaxManualContrast = newArray(6); j=0;
	
	for (contrastCounter = 0; contrastCounter < 3; contrastCounter++) {
		CentrBlock1=((nSlices/2) - nSlices/(SliceThickness/2)); 
		CentrBlock2=((nSlices/2) + nSlices/(SliceThickness/2));
		run("Duplicate...", "duplicate range=CentrBlock1-CentrBlock2");
		ContrastOperationsTemp = ContrastOperationsArray[contrastCounter]; print(ContrastOperationsTemp);
		run("Z Project...", "projection=&ContrastOperationsTemp");
	//	run("Enhance Contrast", "saturated=EnhanceVideoContrast");
		string = "Check Brightness & Contrast and tune if needed. \n===== " + ContrastOperationsTemp + " =====";
		run("Brightness/Contrast..."); 
		waitForUser(string);
		getMinAndMax(min, max); //print(min,max);
		close(); close(); //Close Z-stack and then the sampled central portion
		
		//add min and max values consequently into the minmaxmanualcontrast table
		MinMaxManualContrast[j] = min; MinMaxManualContrast[j+1] = max;
		j = j+2;
		}
		
	return MinMaxManualContrast;
	}

// . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .

function ExportVideoDescription (VideoSavePath, InputVolume, DescriptionSaveSufix, DescritionStringFlag, SliceThickness, YYYYMMDD) {
	//DescriptionSavePath = VideoSavePath + InputVolume + DescriptionSaveSufix;
	DescriptionSavePath = VideoSavePath + YYYYMMDD + DescriptionSaveSufix;
	//print(DescriptionSavePath);
	DescriptionTitle = "SourceVolumeFilename= " + InputVolume; // + DescriptionSaveSufix;
	File.append(DescriptionTitle, DescriptionSavePath);
	SliceThicknessInfo = "SliceThickness= " + SliceThickness; 
	File.append(SliceThicknessInfo, DescriptionSavePath);
	//print(DescritionStringFlag);
	if (DescritionStringFlag == "XYVideo") {
	DescritionString = "\nShortTitle= XY single slice roll - " + YYYYMMDD +" \n\nDescription= \"This is a cross-sectional view of the XRH image stack along the XY plane. \nXRH datasets are normally oriented (resliced) in a way that a scroll through the stack along the XY plane emulates the physical histology slicing of the tissue.\"";
	}
	else if (DescritionStringFlag == "XZVideo") {
	DescritionString = "\nShortTitle= XZ single slice roll - " + YYYYMMDD +"  \n\nDescription= \"This is a cross-sectional view of the XRH image stack along the XZ plane. \nXRH datasets are normally oriented (resliced) in a way that a scroll through the stack along the XY plane emulates the physical histology slicing of the tissue. XZ plane is normal to XY and YZ plane.\"";
	}
	else if (DescritionStringFlag == "YZVideo") {
	DescritionString = "\nShortTitle= YZ single slice roll - " + YYYYMMDD +"  \n\nDescription= \"This is a cross-sectional view of the XRH image stack along the YZ plane. \nXRH datasets are normally oriented (resliced) in a way that a scroll through the stack along the XY plane emulates the physical histology slicing of the tissue. YZ plane is normal to XY and XZ plane.\"";
	}
	//Thick slice XY stacks
	else if (DescritionStringFlag == "AvgInt") {
	DescritionString = "\nShortTitle= Average intensity projection thick slice roll - " + YYYYMMDD +"  \n\nDescription= \"This is a 2D visualisation rendering the a Average Intensity of " + SliceThickness + "x single XY slices along the z-axis of the stack.\nXRH datasets are normally oriented (resliced) in a way that a scroll through the stack along the XY plane emulates the physical histology slicing of the tissue.\"";
	}
	else if (DescritionStringFlag == "MaxInt") {
	DescritionString = "\nShortTitle= Maximum intensity projection thick slice roll - " + YYYYMMDD +"  \n\nDescription= \"This is a 2D visualisation rendering the Maximum Intensity of " + SliceThickness + "x single XY slices along the z-axis of the stack.\nXRH datasets are normally oriented (resliced) in a way that a scroll through the stack along the XY plane emulates the physical histology slicing of the tissue.\"";
	}
	else if (DescritionStringFlag == "StDev") {
	DescritionString = "\nShortTitle= Standard deviation projection thick slice roll - " + YYYYMMDD +"  \n\nDescription= \"This is a 2D visualisation rendering the Standard Deviation of " + SliceThickness + "x single XY slices along the z-axis of the stack.\nXRH datasets are normally oriented (resliced) in a way that a scroll through the stack along the XY plane emulates the physical histology slicing of the tissue.\"";
	}
	File.append(DescritionString, DescriptionSavePath);
	
}



//////////////////////////////////////////////////////////////////////////
//-----------------------------------------------------------------------/
// Auto generate X,Z,Y Slice Roll videos
//-----------------------------------------------------------------------/
//////////////////////////////////////////////////////////////////////////
if (XYZstackVideos) {
	print("===============Auto generating X,Z,Y Slice Roll videos===============");
	selectWindow(InputVolume); run("Duplicate...", "duplicate"); rename("VideoInputVolume");
	
	// Exporting Videos
	print("Exporting X,Y,Z slice roll videos...");
	// XY video
		CheckStackDimensions();		// Check all dimensions of the stack are devided by 2 to avoid errors with some video codecs
									// also check aspect ration is good for wide-screen display if not rotate 90o
		//VideoNamePath = VideoSavePath + InputVolume + "_XYSliceRoll.mp4";
		VideoNamePath = VideoSavePath + YYYYMMDD + "_XYSliceRoll.mp4";  
		setSlice(nSlices/2); //MIPbasedContrast(); //run("Enhance Contrast", "saturated = EnhanceVideoContrast");
		run("Movie...", "frame=15 container=.mp4 using=MPEG4 video=custom custom=128000 save=VideoNamePath");
		ExportVideoDescription (VideoSavePath, InputVolume, "_XYSliceRoll.txt", "XYVideo", 1, YYYYMMDD);
	
	// YZ video
		selectWindow("VideoInputVolume"); run("Duplicate...", "duplicate"); 
		run("Rotate 90 Degrees Right"); rename("Rotated90"); //volume is rotated 90o Right for faster reslice (top)
		selectWindow("Rotated90"); run("Reslice [/]...", "output=1.000 start=Top avoid"); rename("YZtemp"); 
		setSlice(nSlices/2); //MIPbasedContrast(); //run("Enhance Contrast", "saturated = EnhanceVideoContrast");
		CheckStackDimensions();
	  	//VideoNamePath = VideoSavePath + InputVolume + "_YZSliceRoll.mp4"; 
		VideoNamePath = VideoSavePath + YYYYMMDD + "_YZSliceRoll.mp4";
		run("Movie...", "frame=15 container=.mp4 using=MPEG4 video=custom custom=128000 save=VideoNamePath");
		close("YZtemp"); close("Rotated90");
		ExportVideoDescription (VideoSavePath, InputVolume, "_YZSliceRoll.txt", "YZVideo", 1, YYYYMMDD);
	
	// XZ video
		selectWindow("VideoInputVolume");
		run("Reslice [/]...", "output=1.000 start=Top avoid"); rename("XZtemp"); 
		setSlice(nSlices/2); //MIPbasedContrast(); //run("Enhance Contrast", "saturated = EnhanceVideoContrast");
		CheckStackDimensions();
	  	//VideoNamePath = VideoSavePath + InputVolume + "_XZSliceRoll.mp4"; 
		VideoNamePath = VideoSavePath + YYYYMMDD + "_XZSliceRoll.mp4";
		run("Movie...", "frame=15 container=.mp4 using=MPEG4 video=custom custom=128000 save=VideoNamePath");
		close("XZtemp");
		ExportVideoDescription (VideoSavePath, InputVolume, "_XZSliceRoll.txt", "XZVideo", 1, YYYYMMDD);
	
	// Save Log
	if (ThickSliceVideos == false){ // If Thick Slice is reqested too skip and save Log when both process are complete
	//VideoLogNamePath = VideoSavePath + InputVolume + "_XZSliceRoll_Log.txt";
	VideoLogNamePath = VideoSavePath + YYYYMMDD + "_SingleSliceRoll_Log.txt"; 
	selectWindow("Log"); saveAs("Text", VideoLogNamePath);
	}
}


//////////////////////////////////////////////////////////////////////////
//-----------------------------------------------------------------------/
// Auto generate Thick Slice videos if applicable
//-----------------------------------------------------------------------/
//////////////////////////////////////////////////////////////////////////
if (ThickSliceVideos) {
	print("===============Auto generating Thick XY Slice Roll videos===============");
	
	if (isOpen("VideoInputVolume")==false) {
	//check if VideoInputVolume exsist from previous operation. If not create it and check dimensions.
	// Check all dimensions of the stack are devided by 2 to avoid errors with some video codecs
	selectWindow(InputVolume); run("Duplicate...", "duplicate"); rename("VideoInputVolume");
	}
	
	AutoOperationArrey = newArray("Average Intensity","Max Intensity", "Standard Deviation");
  for (AutoCounter = 0; AutoCounter < 3; AutoCounter++){ //repeat for the three operations in AutoOperation array
  print("Processing ThickSlice video ", AutoCounter + 1, " / 3");
  setBatchMode(true);
	print(" "); //add empty line to capture progress
	for (i = 0; i < ThickSliceNumber; i++) {
		ThicknessMinTemp = RangeMin + i; 
		counter = i+1;
		// print("\\Update:" + "Processing :", counter, " / ", ThickSliceNumber, "  | Slice: ", ThicknessMinTemp);
		print("\\Update:" + ". . . generating thick slice:", counter, " / ", ThickSliceNumber);
		ThicknessMaxTemp = ThicknessMinTemp + SliceThickness; // print(ThicknessMaxTemp);
	
		selectWindow(InputVolume);
		run("Duplicate...", "duplicate range=&ThicknessMinTemp-&ThicknessMaxTemp");
		rename("TempThickSliceStack");
		AutoOperation = AutoOperationArrey[AutoCounter];
		run("Z Project...", "projection=&AutoOperation");
		if (i == 0) { 
			rename("ThickSliceStack");
		}
			else {
			ThickSliceTempName = (i+1); rename(ThickSliceTempName);
			close("TempThickSliceStack");
		}
		
			if (i != 0) {
				img2 = ThickSliceTempName;
				run("Concatenate...", "title=ThickSliceStack open image1=ThickSliceStack image2=&img2");
			}	
	}
  setBatchMode(false); 
	 
	 //print(" "); //spacer for the log file
	  
	// Rename processed volume
	selectWindow("ThickSliceStack"); 
	if (AutoOperation == "Average Intensity") OperationFileName="AvgInt";
	if (AutoOperation == "Max Intensity") OperationFileName="MaxInt";
	if (AutoOperation == "Standard Deviation") OperationFileName="StDev";
	//if (AutoOperation == "Min Intensity") OperationFileName="MinInt_";
	//if (AutoOperation == "Sum Intensity") OperationFileName="SumInt";
	
	rename(OperationFileName + InputVolume); // rename generated ThickSliceRoll stack
	
	CheckStackDimensions(); //check dimensions of ThickSlice stack are devided by 2
	
	setSlice(nSlices/2); 
	
	//check if ManualContrast was selected and apply manual range
	if (ThickSliceManualContrast == true){
		if (AutoOperation == "Average Intensity") setMinAndMax(MinMaxManualContrast[0], MinMaxManualContrast[1]);
		if (AutoOperation == "Max Intensity") setMinAndMax(MinMaxManualContrast[2], MinMaxManualContrast[3]);
		if (AutoOperation == "Standard Deviation") setMinAndMax(MinMaxManualContrast[4], MinMaxManualContrast[5]);
													//run("Enhance Contrast...", "saturated=EnhanceVideoContrast");
													//{setMinAndMax(MinMaxManualContrast[4], MinMaxManualContrast[5]); run("16-bit");}
	}
	else {
		MIPbasedContrast(); //run("Enhance Contrast", "saturated = EnhanceVideoContrast");
	}
	
  	//VideoNamePath = VideoSavePath + InputVolume + "_" + SliceThickness + "x" + OperationFileName + ".mp4"; 
	VideoNamePath = VideoSavePath + YYYYMMDD + "_" + SliceThickness + "x" + OperationFileName + ".mp4";
	run("Movie...", "frame=15 container=.mp4 using=MPEG4 video=custom custom=128000 save=VideoNamePath");
	ExportVideoDescription (VideoSavePath, InputVolume, "_" + SliceThickness + "x" + OperationFileName + ".txt", OperationFileName, SliceThickness, YYYYMMDD);
	}
	
	// Save Log
	if (XYZstackVideos == false){ // If Thick Slice is reqested too, skip and save Log when both process are complete
		//VideoLogNamePath = VideoSavePath + InputVolume + "_ThickSliceRoll_Log.txt"; 
		VideoLogNamePath = VideoSavePath + YYYYMMDD + "_ThickSliceRoll_Log.txt";
		selectWindow("Log"); saveAs("Text", VideoLogNamePath);} 
	else {
		//VideoLogNamePath = VideoSavePath + InputVolume + "_SlicesAndThickSliceRoll_Log.txt"; 
		VideoLogNamePath = VideoSavePath + YYYYMMDD + "_SingleSliceAndThickSliceRoll_Log.txt"; 
		selectWindow("Log"); saveAs("Text", VideoLogNamePath);}
	
	exit(); //exit script
}




//////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////
//-----------------------------------------------------------------------/
// Manual Thick Slice stack generation
//-----------------------------------------------------------------------/
//////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////
if (ThickSliceStackOnly)	 {
setBatchMode(true);
print(" "); //add empty line to capture progress
for (i = 0; i < ThickSliceNumber; i++) {

	ThicknessMinTemp = RangeMin + i; 
	counter = i+1;
	// print("\\Update:" + "Processing :", counter, " / ", ThickSliceNumber, "  | Slice: ", ThicknessMinTemp);
	print("\\Update:" + "Processing :", counter, " / ", ThickSliceNumber);
	ThicknessMaxTemp = ThicknessMinTemp + SliceThickness; // print(ThicknessMaxTemp);

	selectWindow(InputVolume);
	run("Duplicate...", "duplicate range=&ThicknessMinTemp-&ThicknessMaxTemp");
	rename("TempThickSliceStack");
	run("Z Project...", "projection=&Operation");
	if (i == 0) { 
		rename("ThickSliceStack");
	}
		else {
		ThickSliceTempName = (i+1); rename(ThickSliceTempName);
		close("TempThickSliceStack");
	}
	
		if (i != 0) {
			img2 = ThickSliceTempName;
			run("Concatenate...", "title=ThickSliceStack open image1=ThickSliceStack image2=&img2");
		}
  }
setBatchMode(false);

// Rename processed volume
selectWindow("ThickSliceStack"); 
if (Operation == "Average Intensity") OperationFileName="AvgInt";
if (Operation == "Max Intensity") OperationFileName="MaxInt";
if (Operation == "Sum Slices") OperationFileName="SumInt";
if (Operation == "Min Intensity") OperationFileName="MinInt";
if (Operation == "Standard Deviation") OperationFileName="StDev";

rename(OperationFileName + "_ROI_of_" + InputVolume);

// print Log file
selectWindow("Log");  //select Log-window
saveAs("Text", "[path/filename]");

}
