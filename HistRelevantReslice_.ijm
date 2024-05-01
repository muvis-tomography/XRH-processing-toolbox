//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Reslice volume to histological-relevant planes script for Fiji/ImageJ (v20210211) by OLK  ~~~~~~~~
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

/*
 * v20210311
 * memory optimisation param added
 * v20210211
 * Modified threshold in "function SimpleCropVolume()" and added an if check for 32-bit datasets.
 * Old threshold of [2, max] was too aggressive on some 32-bit datasets resulting in threshold out everything
 */


//////////////////////////////////////////////////////////////////////////
//-----------------------------------------------------------------------/
// get Input parameters
//-----------------------------------------------------------------------/
//////////////////////////////////////////////////////////////////////////
function SimpleCropVolume() {
	//Crop to remove empty canvas cells maintaining all CT-volume data
	run("Select None");
	CropVolumeName = getTitle();
	
	getDimensions(width, height, null, null, null); 
	widthCrop = width+25; 
	heightCrop=height+25;
	run("Canvas Size...", "width=widthCrop height=heightCrop position=Center zero"); //increase canvas to make sure 0 excist around the image
	if (bitDepth==32) {
		getMinAndMax(min, max);	
		setThreshold(0.01, max); 
		run("Threshold...");	
	}else {
		getMinAndMax(min, max);	
		setThreshold(1, max); 
		run("Threshold...");
	}
	run("Create Selection"); 
	resetThreshold();
	run("Crop"); 
	run("Select None"); //crop the volume
  }
	
  function CropToWax(){
	//Crop to Wax to reduce volume size
	//N.B. Wax needs to be aligned along the Z-plane at this stage or else you will end up cropping wax/tissue
	run("Select None");
	CropVolumeName = getTitle();
	
	//generate temp AVG Z-project to work out cropping mask that excludes air
	run("Z Project...", "projection=[Average Intensity]"); 
	rename("AVG");
	setAutoThreshold("Intermodes  dark"); 
	run("Threshold..."); 
	run("Convert to Mask"); 
	close("Threshold");
	run("Options...", "iterations=3 count=1 do=Nothing"); 
	run("Open");
	run("Options...", "iterations=20 count=1 do=Nothing"); 
	run("Dilate");
	run("Options...", "iterations=1 count=1 do=Nothing"); //restore defaults
	run("Divide...", "value=255"); // convert to mask [0,1] binary mask
	
	selectWindow(CropVolumeName);
	imageCalculator("Multiply stack", CropVolumeName,"AVG"); 
	close("AVG"); //apply crop mask
	setAutoThreshold("Intermodes dark"); 
	run("Threshold...");
	run("Create Selection"); 
	resetThreshold();
	run("Crop"); 
	run("Select None"); //crop the volume
}

function CropToWaxManual(){
  	run("Select None");
	CropVolumeName = getTitle();
	
	setTool("rectangle");
	string = "Make selection or continue..." ;
	waitForUser(string);
	run("Crop"); 
	run("Select None"); //crop the volume
  }


//............................//
// get Input volume name      //
//............................//
	waitForUser("Action required", "Select Input Volume window *then* OK [ESC to abort]"); 
	InputVolume = getTitle(); 
	bitDepthVolume = bitDepth();
	print("\\Clear"); // Clear Log Window
	getDateAndTime(year, month, week, day, hour, min, sec, msec); //N.B. 'month' and 'dayOfWeek' are zero-based indexes
	month = month +1; // add 1 to month to make it 1-based index
	if (month < 10) {
		monthStr ="0" + month;
	} else {
		monthStr ="" + month;
	} //change month to format Jan = 01, Feb =02, ...
	if (day<10) {
		dayStr = "0"+day;
	} else {
		dayStr = ""+day;
	}  	
	print("Date: "+year+"/"+monthStr+"/"+dayStr); //print(month);
	YYYYDDMM = ""+year +""+monthStr+""+dayStr; //print(YYYYDDMM);
	print("Volume name :",InputVolume); 
	print("bitDepth : ", bitDepthVolume);

//.............................//
// create box & get USER value //
//.............................//

	Dialog.create("User Input Values");	//Creates a dialog box
	Dialog.addMessage("Cropping option");
	OperationsArray = newArray("Manual", "Automatic");
	Dialog.addChoice("Cropping to wax: " , OperationsArray); //1
	Dialog.addCheckbox("Optimise memory usage", true); //2
	//-----------------------------------------------------------------------
    Dialog.show();
	//-----------------------------------------------------------------------
	CropSelection = Dialog.getChoice(); //1
	OptimiseMemory = Dialog.getCheckbox(); //2

	
//get ready
	run("Set Measurements...", "area mean standard modal min centroid center bounding fit feret's integrated median stack redirect=None decimal=7");
	run("Clear Results");
	print("===============Reslicing volume to histological-relevant planes===============");
	setTool("line");
	setSlice(nSlices/2);
	selectWindow(InputVolume); 
	run("Duplicate...", "duplicate"); 
	rename("InputVolume_temp");
	if(OptimiseMemory){
		close(InputVolume);
		run("Collect Garbage");
	}
	//get user input
		waitForUser("Draw line parallel to the tissue on the wax/air interface");
		getLine(z1x1, z1y1, z1x2, z1y2, null);	
		run("Measure"); angleZ = getResult("Angle", 0); 
		drawnLineLength = getResult("Length", 0);
	
	// canlulate rotation angles
		if (angleZ<abs(90)) {
			if (angleZ>0) {
				rotateAboutZ=-(90-angleZ);
			} else {
				rotateAboutZ=-(90-angleZ);
			}
		}else{
			if (angleZ>0) {
				rotateAboutZ=(angleZ-90);
			} else {
				rotateAboutZ=(angleZ+90);
			}
		}
		
		angleTempDeg=90-angleZ; //get drawn line and rotate 90o to use for the reslice guide
		angleTempRad = angleTempDeg * PI / 180; //change ang to rad
		dX = cos(angleTempRad) * drawnLineLength / 2; 
		dY = sin(angleTempRad) * drawnLineLength / 2;
	
	//get the centre of the image to draw the reslice guide
		getDimensions(width, height, null, null, null);
		centerX=width/2 ; 
		centerY = height/2; 
		run("Select None");
	
	//draw the reslice guide 90o to the drawn using centre and angle
		makeLine(centerX - dX, centerY - dY, centerX + dX, centerY + dY); 
		
	// reslice and get user input
		run("Reslice [/]...", "output=1.000 start=Top avoid"); 
		rename("SliceZtemp");
		waitForUser("Draw line parallel to the tissue on the wax/air interface");
		run("Measure"); 
		angleY = getResult("Angle", 1); 
		close("SliceZtemp");
		
	// calculate rotation angles
		if (angleY<abs(90)) {
			if (angleY>0) {
				rotateAboutY=-(90-angleZ);
			} else {
				rotateAboutY=-(90-angleY);
			}
		}else{
			if (angleY>0) {
				rotateAboutY=(angleZ-90);
			} else {
				rotateAboutY=(angleY+90);
			}
		}
	
	selectWindow("InputVolume_temp");
	print("rotating about Z-axis by :",rotateAboutZ,"degrees"); //Angle to make wax face || to Y'Y
	run("Select None");
	run("Rotate... ", "angle=rotateAboutZ grid=1 interpolation=Bicubic enlarge stack");
	SimpleCropVolume(); //Call CropVolume function to to remove empty camvas cells
	run("Reslice [/]...", "output=1.000 start=Top avoid"); 
	rename("InputVolume_temp_reslice");
	close("InputVolume_temp"); 
	run("Collect Garbage");
	
	selectWindow("InputVolume_temp_reslice");
	print("rotating about Y-axis by :",rotateAboutY,"degrees"); //Angle to make wax face || to X'X
	setSlice(nSlices/2);
	run("Rotate... ", "angle=rotateAboutY grid=1 interpolation=Bicubic enlarge stack");
	run("Rotate 90 Degrees Right");
	if (CropSelection == "Automatic") {
		CropToWax();  //Call CropToWax function to to remove empty camvas cells and some air 
	}else {
		CropToWaxManual(); //Call CropToWaxManual function to to remove empty camvas cells and some air
	}
	run("Collect Garbage");
	run("Reslice [/]...", "output=1.000 start=Top avoid"); 
	rename("Reslice_" + InputVolume);
	
	InputVolume = getTitle(); //reasign InputVolume name to resliced volume
	close("InputVolume_temp_reslice"); 
	run("Collect Garbage");

	waitForUser("Please scroll through the resliced volume and check that \nyou are happy with the slicing direction. \n \nIf not, you can inverse the stack order, on the next step" );
	Dialog.create("Reverse or not Reverse?");
	items = newArray("It looks good. Do Nothing.", "Stack needs reversing. Reverse now!");
	Dialog.addRadioButtonGroup("You happy with the rolling? \nIs rolling from tissue towards the cassette?", items, 2, 1, "It looks good. Do Nothing.");
	Dialog.show();
	ReverseStackCheck=Dialog.getRadioButton();
	if (ReverseStackCheck == "Stack needs reversing. Reverse now!") {
	  	selectWindow(InputVolume); 
		run("Reverse");
	  	print("User said: "+ReverseStackCheck);
	}