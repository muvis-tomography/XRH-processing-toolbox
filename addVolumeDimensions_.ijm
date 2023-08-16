//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// addVolumeDimensions by OLK  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
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


/*
 * 
 * ChangeLog:
 */



function addVolumeDimensions () {
		//Add dimensions to filename
		VolumeName = getTitle();
		
		// revome extension sfor .vol .raw .tif volume names
		////////////////////////////////////////////////////
		// remove .vol extension
			if (endsWith(VolumeName, ".vol")) {
				rename(replace(VolumeName, ".vol", ""));	
				VolumeName = getTitle();
			}
		// remove .raw extension
			if (endsWith(VolumeName, ".raw")) {
				rename(replace(VolumeName, ".raw", ""));	
				VolumeName = getTitle();
			}
		// remove .tif extension
			if (endsWith(VolumeName, ".tif")) {
				rename(replace(VolumeName, ".tif", ""));	
				VolumeName = getTitle();
			}
		
			
		// Get volume info 
			Stack.getDimensions(width, height, channels, slices, frames);
			bitDepthVolume = bitDepth(); print (bitDepthVolume);
		
		// Set new title with dimensions and bit-depth
		VolumeNameDim = VolumeName + "_" + width + "x" + height + "x" + slices + "x" + bitDepthVolume + "bit";
		
		// Apply correction
		msg = "Volume dimensions: " + width + "x" + height + "x" + slices + "x" + bitDepthVolume + "bit \n \n" +  "Rename volume to: \n"  + VolumeNameDim + "\n \nEnter to confirm ESC to exit";
		waitForUser("Add dimensions on filename", msg );
		rename(VolumeNameDim);

} //end of Function

addVolumeDimensions ();

