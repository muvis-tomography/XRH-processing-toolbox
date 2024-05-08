//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// ThickSlice stack generation script for Fiji/ImageJ (v20200212) by OLK   ~~~~~~~~
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
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

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

	string = "Make selection or continue..." 
	waitForUser(string)

//............................//
// set DEFAULT value          //
//............................//
	run("Clear Results"); 
	SliceThickness = 10; 
	RangeMin = 1; 
	RangeMax = nSlices; 
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
	Dialog.addNumber("RangeMin..., RangeMin=:", RangeMin);
	Dialog.addNumber("RangeMax..., RangeMax=:", RangeMax); 		
	//Dialog.addString("Operation..., Operation=:", "Average Intensity"); 
	OperationsArray = newArray("Average Intensity","Max Intensity", "Sum Slices", "Min Intensity", "Standard Deviation")
	Dialog.addChoice("Operation: " , OperationsArray);
	Dialog.addNumber("Gamma Correction factor..., Gamma=:", 0.985); 
//-----------------------------------------------------------------------
    Dialog.show();
//-----------------------------------------------------------------------
//Variables -------------------------------------------------------------
	SliceThickness =Dialog.getNumber();
	RangeMin =Dialog.getNumber();
	RangeMax = Dialog.getNumber();
	Operation = Dialog.getChoice(); 
	print(Operation);
	//Dialog.getString(); 
	//EllipseW = Dialog.getNumber();
	GmmaCor = Dialog.getNumber();
//-----------------------------------------------------------------------

selectWindow(InputVolume);
print("Slice range : ",RangeMin, " ,", RangeMax);
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

	selectWindow(InputVolume);
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

// Rename processed volume
selectWindow("ThickSliceStack"); 
if (Operation == "Average Intensity") OperationFileName="AvgInt";
if (Operation == "Max Intensity") OperationFileName="MaxInt";
if (Operation == "Sum Slices") OperationFileName="SumInt";
if (Operation == "Min Intensity") OperationFileName="MinInt";
if (Operation == "Standard Deviation") OperationFileName="StDev";

rename(OperationFileName + "_ROI_of_" + InputVolume);
