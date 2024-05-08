//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Bicubic stack resize script for Fiji/ImageJ (v20200603) by OLK  ~~~~~~~~
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
	
	function MakeDimensionsEven (){
		getDimensions(width, height, channels, slices, frames);	
		if (slices % 2 != 0) {
			setSlice(nSlices); 
			run("Delete Slice"); //print("Z-dimension size is ", slices, "  Deleting last slice.");
		}
		
		if (width % 2 != 0) {
		widthEven = width -1;  
		//print("X-dimension size is ", width, "  Reducing by one.");
		} else {
			widthEven = width;
		}
			
		if (height % 2 != 0) {
			heightEven = height -1; 
		//print("Y-dimension size is ", width, "  Reducing by one."); print("");
		}else {
			heightEven = height;
		}
		
		run("Specify...", "width=widthEven height=heightEven x=0 y=0"); 
		run("Crop");
		run("Select None");
		
		run("Scale to Fit");
		
	}
	
	function MakeDimensionsOdd (){
		getDimensions(width, height, channels, slices, frames);	
		if (slices % 2 == 0) {
			setSlice(nSlices); 
			run("Delete Slice"); //print("Z-dimension size is ", slices, "  Deleting last slice.");
		}
		
		if (width % 2 == 0) {
			widthOdd = width -1; 
			//print("X-dimension size is ", width, "  Reducing by one.");
		} else {
			widthOdd = width; 
		}
			
		if (height % 2 == 0) {
			heightOdd = height -1; 
			//print("Y-dimension size is ", width, "  Reducing by one."); print("");
		}else {
			heightOdd = height;
		}
		
		run("Specify...", "width=widthOdd height=heightOdd x=0 y=0"); 
		run("Crop");
		run("Select None");
		
		run("Scale to Fit");
		
	}

//............................//
// get Input volume name      //
//............................//

	title = "Legacy Script Warning";
	message = "This is a legacy script. It is advised you use either:\n \n" +
			 "Image > Stacks > Tools > Reduce...\n" +
			 "or\n" +
			 "Image > Adjust > Size...";
	showMessage(title, message);
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
	print("Date: "+year+"/"+monthStr+"/"+dayStr); 
	//print(month);
	YYYYDDMM = ""+year +""+monthStr+""+dayStr + "-" + hour + "h" + min + "m"; 
	print(YYYYDDMM);
	print("Volume name :",InputVolume); 
	print("bitDepth : ", bitDepthVolume);
	setSlice(nSlices/2); 
	resetMinAndMax();


//.............................//
// create box & get USER value //
//.............................//
	//-----------------------------------------------------------------------
		Dialog.create("User Input Values");	//Creates a dialog box
		Dialog.addMessage("Binning factor:");
		Dialog.addNumber("Reduce X,Y,Z dimensions by a factor of :", 2); //1
	//-----------------------------------------------------------------------
	    Dialog.show();
	//-----------------------------------------------------------------------
	//Variables -------------------------------------------------------------
		binning = Dialog.getNumber(); //1

//............................//
// run main script            //
//............................//
	run("Duplicate...", "duplicate"); //duplicate stack to resize
	if (binning % 2 != 0) { //binning factor is an even number 3,5,7...
		MakeDimensionsOdd(); 
	}else { 				//binning factor is an odd number 2,4,6...
		MakeDimensionsEven();
	}
			
	getDimensions(width, height, channels, slices, frames);		
	widthNew = width/2; 
	heightNew = height/2; 
	depthNew = slices/2;
	run("Size...", "width=widthNew height=heightNew depth=depthNew constrain average interpolation=Bicubic");
	getDimensions(width, height, channels, slices, frames);		
	rename(InputVolume + "_bin" + binning + "x_" + width + "x" + height + "x" + slices + "x" + bitDepthVolume + "bit");
	setSlice(nSlices/2); 
	resetMinAndMax();

	
//............................//
// print out                  //
//............................//
	ResizeVolumeName = getTitle();
	print("Binnig factor :" + binning + "x");
	print("Resized volume dimensions (X x Y x Z):" + width + " x " + height + " x " + slices );
	print("Resized volume name :",ResizeVolumeName);



