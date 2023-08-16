//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Median3D and HighPassFilter by OLK  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
/*
   Copyright 2016, 2017 University of Southampton
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

/* v20220308
 *  
 * ChangeLog:
 * 	20230109
 * 		added Opt-out of Duplicate option
 * 	20220308
 * 		added CLAHE 512/1500 bins option
 * 		improved print-outs
 * 	
 *	20211008
 *		added option to opt-out of automatic 32to16bit convertion [-10 100]
 *  20201201
 *  	setMinAndMax(-10, 50) --> setMinAndMax(-50, 100);  
 *  	unpick rename function syntaxerrors
 *  20201124
 *  	add script settings on the filename
 *  	change filename to XRH-enhance
*/


function addSettingsPrefix (sigma, Xrad, Yrad, Zrad, CLAHE) {	
	//replace OLK script standard prefix with script's params: e.g. 4,2,2,2,0 --> 42220_[VolumeName]
	VolumeName = getTitle(); print(VolumeName);
	if (startsWith(VolumeName, "Med3D_HPass_Reslice")) {
		rename(replace(VolumeName, "Med3D_HPass_Reslice", sigma +""+ Xrad +""+ Yrad +""+ Zrad +""+ CLAHE));}	
	if (startsWith(VolumeName, "Med3D_HPass")) {
		rename(replace(VolumeName, "Med3D_HPass", sigma +""+ Xrad +""+ Yrad +""+ Zrad +""+ CLAHE));	
	}
}



//............................//
// set DEFAULT value          //
//............................//
sigma = 2.0; Xrad = 1.0; Yrad = 1.0; Zrad = 1.0; CLAHE = 0;
//.............................//
// create box & get USER value //
//.............................//
Dialog.create("User Input Values");	//Creates a dialog box
Dialog.addNumber("Gaussian Blur..., sigma=:", sigma); 					// Resolution input
Dialog.addNumber("3D Median..., X radius=:", Xrad); 
Dialog.addNumber("3D Median..., Y radius=:", Yrad); 
Dialog.addNumber("3D Median..., Z radius=:", Zrad);
Dialog.addNumber("CLAHE..., 0: DoNotUse, 1:accurate(slow) 2:fast:", CLAHE);
Dialog.addCheckbox("    CLAHE: Use 512 Bins instead of default 1500", false);
Dialog.addCheckbox("    [-50 100]   32-bit >> 16-bit convertion ", true);
Dialog.addCheckbox("    Apply on New Volume (Duplicate)", true);
Dialog.show();
sigma = Dialog.getNumber();
Xrad = Dialog.getNumber();
Yrad = Dialog.getNumber();
Zrad = Dialog.getNumber();
CLAHE = Dialog.getNumber();
CLAHE512 = Dialog.getCheckbox();
Auto32to16Convert = Dialog.getCheckbox();
ApplyOnNewVolume = Dialog.getCheckbox();

//print out settings
	if (CLAHE==0) {CLAHEprint = "No";}
	if (CLAHE==1) {
		if (CLAHE512) {CLAHEprint = "Yes 512-Bins (Accurate)";} else {CLAHEprint = "Yes 1500-Bins (Accurate)";}}
	if (CLAHE==2) {
		if (CLAHE512) {CLAHEprint = "Yes 512-Bins (Fast)";} else {CLAHEprint = "Yes 1500-Bins (Fast)";}}
	if (Auto32to16Convert==1) {Auto32to16ConvertPrint="Yes";}
	if (Auto32to16Convert==0) {Auto32to16ConvertPrint="No";}
		print("\\Clear");
		print("Selected settings: ");
		print("Unsharp Radius =" + sigma + ", Xrad ="+Xrad + ", Yrad =" + Yrad + ", Zrad =" + Zrad + ", CLAHE =" + CLAHEprint + ",  Auto32to16Convert: " + Auto32to16ConvertPrint);
		print(""); //add extra line for print-update to replace

OriginalStackName = getTitle(); //print(stackName);

if (ApplyOnNewVolume) {
	run("Duplicate...", "duplicate");
	}

run("Median 3D...", "x=Xrad y=Yrad z=Zrad");
resetMinAndMax();
rename("Med3D_HPass_"+OriginalStackName);
stackName = getTitle(); //print(stackName);
run("32-bit");


for (i=1;i<=nSlices;i++) {
	setBatchMode(true); // suppress printouts
	setSlice(i);
	print("\\Update:" + "Processing :", i, " / ", nSlices);
	run("Duplicate...", "title=copy"); 		//print ("Duplicate slice " + i); 
	selectWindow("copy");
	run("Duplicate...", "title=copy2");
	//run("Gaussian Blur...", "sigma");
	run("Gaussian Blur...", "sigma=sigma"); //print ("running Gaussian Blur..."); 
	rename("blured");
	imageCalculator("Subtract create 32-bit", "copy","blured");
	selectWindow("Result of copy");
	rename("high_pass_filter"); 			//print ("Sharpening edges...");
	selectWindow("blured"); close();
	selectWindow("high_pass_filter");
	imageCalculator("Average", stackName,"high_pass_filter");
	//selectWindow("Result of copy");
	//rename("HP_filtered");
	selectWindow("high_pass_filter"); rename(i); //close();
	selectWindow("copy"); close();
	selectWindow(stackName); 
	setBatchMode(false); // suppress printouts
}


	if (CLAHE==1) {
		if (CLAHE512==false){
			for (i=1;i<=nSlices;i++) {
				setBatchMode(true); // suppress printouts
				setSlice(i);
				run("Enhance Local Contrast (CLAHE)", "blocksize=19 histogram=1500 maximum=3 mask=*None*");
				print("\\Update:" + "CLAHE Processing :", i, " / ", nSlices);}
				}
		if (CLAHE512==true){
				for (i=1;i<=nSlices;i++) {
					setBatchMode(true); // suppress printouts
					setSlice(i);
					run("Enhance Local Contrast (CLAHE)", "blocksize=19 histogram=512 maximum=3 mask=*None*");
					print("\\Update:" + "CLAHE Processing :", i, " / ", nSlices);}
					}
	}
					
	if (CLAHE==2) {
		if (CLAHE512==false){
			for (i=1;i<=nSlices;i++) {
				setBatchMode(true); // suppress printouts
				setSlice(i);
				run("Enhance Local Contrast (CLAHE)", "blocksize=19 histogram=1500 maximum=3 mask=*None* fast_(less_accurate)");
				print("\\Update:" + "CLAHE Processing :", i, " / ", nSlices);}
		}
		if (CLAHE512==true){
				for (i=1;i<=nSlices;i++) {
					setBatchMode(true); // suppress printouts
					setSlice(i);
					run("Enhance Local Contrast (CLAHE)", "blocksize=19 histogram=512 maximum=3 mask=*None* fast_(less_accurate)");
					print("\\Update:" + "CLAHE Processing :", i, " / ", nSlices);}
				}
	}

	setBatchMode(false);

run("Enhance Contrast", "saturated=0.05"); print("All Done!");
if (Auto32to16Convert) {
	setMinAndMax(-50, 100); run("16-bit");
}

// Add Settings
addSettingsPrefix (sigma, Xrad, Yrad, Zrad, CLAHE);


// Optional .................... //

// run("Specify...", "width=1800 height=1800 x=1000 y=1000 slice=175 oval centered");
// run("Make Inverse"); run("Color Picker...");
// setForegroundColor(0, 0, 0); run("Fill", "stack");



