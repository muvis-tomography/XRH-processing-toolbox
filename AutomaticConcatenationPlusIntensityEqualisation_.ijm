//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Automatic Concatenation Plus Intensity Equalisation (v20211014) by OLK  ~~~~~~~~
/*
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

//////////////////////////////////////////
	//fraction number for refImage position; e.g refImagePosition =4, means refImage =500 on a 2000-slice stack)
	//fraction number for refImage position; e.g refImagePosition =4, means refImage =500 on a 2000-slice stack)
	//notes = dublicate and normalise both --> substract --> square --> find min
	//refImageStackFraction = 4.5

/* changeLog
 *  v20211014
 *  	added manual slice selection option
 *  	added increased ROI selection for when sample mostly on edge of field
 *  	added limit slice search range for faster search
 *  v20181203 
 *  	first release
 */


// manualSliceSelect = true


// get windows' titles
waitForUser("Action required", "Select BOTTOM stack *then* OK [ESC to abort]"); 
btm = getTitle(); bitDepthBtm = bitDepth();
//waitForUser("Thanks!", "WindowTitle :" + btm + "  | bitDepth :" + bitDepthBtm + " bit"); 
waitForUser("Action required", "Select TOP stack *then* OK [ESC to abort]"); 
top = getTitle(); bitDepthTop = bitDepth();
//waitForUser("Thanks!", "WindowTitle :" + top + "  | bitDepth :" + bitDepthTop + " bit"); 

//-----------------------------------------------------------------------
	Dialog.create("Thanks!");
	Dialog.addMessage("BottomVolume :" + btm + "  | bitDepth :" + bitDepthTop + " bit \n \nTopVolume :" + top + "  | bitDepth :" + bitDepthBtm + " bit ");
	Dialog.addCheckbox("Limit slice search range to first 1/3 of Top volume ", true);
	Dialog.addCheckbox("Increase ROI volume; sample mostly at the edge of the field ", false);
	Dialog.addCheckbox("Find concatenation slice Manually ", false);
//-----------------------------------------------------------------------
	Dialog.show();	
//-----------------------------------------------------------------------
	LimitRange = Dialog.getCheckbox();
	increasedROI =  Dialog.getCheckbox();
	manualSliceSelect = Dialog.getCheckbox();
	
// waitForUser("Thanks!", "BottomVolume :" + btm + "  | bitDepth :" + bitDepthTop + " bit \n \nTopVolume :" + top + "  | bitDepth :" + bitDepthBtm + " bit "); 

//Check both volumes are of same bitDepth
if (bitDepthBtm != bitDepthTop) {
	waitForUser("ERROR", "type of volume 1 <> type of volume 2! Quitting."); exit("bitDepthBtm:" + bitDepthBtm + " <> bitDepthTop:" + bitDepthTop);
	}

//Initiate Automacit slice location	
if (manualSliceSelect == false) {
	
	selectWindow(btm); run("Set... ", "zoom=50"); 
	selectWindow(top); run("Set... ", "zoom=50");

	selectWindow(btm); run("Select All");
	waitForUser("Action required", "Get volumes side-by-side and using the scroll bar navigate (approximately) to where the two volumes should fused \n*then* OK [ESC to abort]; \n \nN.B. try to keep outside the Chinese-hat region!"); 
	
	selectWindow(btm); run("Select None");
	refImageSlice = getSliceNumber(); waitForUser("Selected slice", "Bottom volume slice:" + refImageSlice); 
	
	setSlice(refImageSlice);
	if (increasedROI == true) {
		refROIpers =1.05;
		}
		else {
			refROIpers =2;
		}
		
	h =getHeight(); w =getWidth();  
	makeRectangle(h/2-h/(refROIpers*2), w/2-w/(refROIpers*2), h/refROIpers, h/refROIpers);
	run("Duplicate...", "title=btmRefImage"); run("Set... ", "zoom=25");

	setBatchMode(true);			// Activate batch mode for fast processing
	
	//normalise
	run("Clear Results"); selectWindow("btmRefImage"); 
	run("Select All"); run("Measure");
	CalValue_temp =getResult("Max", 0);	
	run("Divide...", "value=CalValue_temp");
	
	selectWindow(top); run("Select All");
	makeRectangle(h/2-h/(refROIpers*2), w/2-w/(refROIpers*2), h/refROIpers, h/refROIpers);
	run("Duplicate...", "title=TopScout duplicate");
	
	//normalise
	run("Clear Results"); selectWindow("TopScout"); 
	
	if (LimitRange == true) {
		SearchSliceLim = nSlices/3;
		}
		else {
			LimitRange = nSlices;
	}
	
	for (i=1;i<=LimitRange;i++) {
		setSlice(i);
		run("Select All"); run("Measure");
		CalValue_temp =getResult("Max", 0);
		run("Divide...", "value=CalValue_temp slice");
		run("Clear Results");
		}
	
	imageCalculator("Subtract create 32-bit stack", "TopScout","btmRefImage");
	selectWindow("Result of TopScout"); run("Set... ", "zoom=15");
	
		stDevGrey =newArray(nSlices);
		for (i=1;i<=nSlices;i++) {
			setSlice(i); run("Select All");
			getStatistics(area, mean, min, max, std, histogram);
			stDevGrey[i-1] =std;
			//print(min);
			}
			
			Array.getStatistics(stDevGrey, min, max, mean, stdDev);
		    for (i=0; i<stDevGrey.length; i++) {
		          if (stDevGrey[i]==min) ConcSliceNumber =i+1;
		  } 
		  
	setBatchMode(false);
	
	print ("MinGrey(std) ="); print (min);
	print ("on slice: ", ConcSliceNumber, "of Volume 2 (top)");
	close("TopScout"); close("btmRefImage"); //close ("Result of TopScout");
	}
	else {
		waitForUser("Action required", "Get volumes side-by-side and using the scroll bar navigate to where the two volumes should fused. \nnote the slice numbers of each volume *then* OK [ESC to abort]; \n \nN.B. try to keep outside the Chinese-hat region!"); 
		selectWindow(btm);
		refImageSlice = getSliceNumber();
		selectWindow(top);
		ConcSliceNumber = getSliceNumber();
		h =getHeight(); w =getWidth();
		//refImageSlice =  getNumber("Concatenate Bottom volume on slice :",0000);
		//ConcSliceNumber = getNumber("Concatenate Top volume on slice :",0000);
	}


selectWindow(top); TopRangeMax =nSlices; TopRangeMin =ConcSliceNumber+1;
run("Select All");
run("Duplicate...", "duplicate range=TopRangeMin-TopRangeMax");
rename("topTemp");

selectWindow(btm);
run("Select All");
run("Duplicate...", "duplicate range=1-refImageSlice");
rename("btmTemp");




////////////////////////////////////////
////////////////////////////////////////
////////////////////////////////////////


ROINo =round(h/100); //number of sampling ROIs for intensity equilisation
ROIsize =round(h/(ROINo)*0.8);
CalBtmValues = newArray(ROINo+1);
CalTopValues = newArray(ROINo+1);

run("Clear Results");
selectWindow("btmTemp"); setSlice(nSlices); run("Select None");
run("Duplicate...", "title=CalBtmSlice_temp ");
selectWindow("topTemp"); setSlice(1); run("Select None");
run("Duplicate...", "title=CalTopSlice_temp ");

for (i=1;i<=2;i++) {
	run("Clear Results"); 
	if (i==1) 
		TargetWindow = "CalBtmSlice_temp";
	else 
		TargetWindow = "CalTopSlice_temp";
	
	selectWindow(TargetWindow);
	for (ii=1;ii<=ROINo-1;ii++) { 
		//makeRectangle(200,  20*ii, 10, 10);
		makeRectangle((w/2-ROIsize/2),  round(h/ROINo)*ii, ROIsize, ROIsize);
		run("Measure");
			if (i==1) 
				CalBtmValues[ii] =getResult("Mean",ii-1);
			else 
				CalTopValues[ii] =getResult("Mean",ii-1);	
	};
	run("Select None");
};

//Intensity equalisation curve - i.e. deal with heel-effect

Fit.doFit("Straight Line", CalTopValues, CalBtmValues);
print("a="+d2s(Fit.p(0),6)+", b="+d2s(Fit.p(1),6));
Fit.plot();

a=Fit.p(0); b=Fit.p(1);

close("CalBtmSlice_temp");close("CalTopSlice_temp");
selectWindow("topTemp");
run("Multiply...", "value=b stack");
run("Add...", "value=a stack");

/*
run("Concatenate...", "image1=btm image2=top");
makeLine(1965, 21, 18, 1971);
run("Reslice [/]...", "output=1.000 slice_count=1 avoid");
*/


////////////////////////////////////////
run("Concatenate...", "title=concatenated_stack image1=btmTemp image2=topTemp");
close("Result of TopScout"); 

//preview concatenation 
makeLine(5, h-5, w-5, 5);
run("Radial Reslice", "angle=360 degrees_per_slice=22.5 direction=Clockwise rotate_about_centre suppress_reversed_duplicates"); 
rename("Radial Reslice of concatenated_stack - PREVIEW");
