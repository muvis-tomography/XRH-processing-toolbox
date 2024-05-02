# XRH Processing Toolbox

This is a collection of macros for Fiji/ImageJ that were developed for working with XRH datasets, but can be used for any CTData set.
Brief details about using each script is given below.  For more details please see the code itself, this documentation is intended as a high level overview only. These scripts are intended to be used by people with priori image processing experience.
Where needed each script will prompt for input as it progresses with instructions on what to do, where possible all values will have reasonable defaults.

## addVolumeDimensions

Takes an image stack and adds the dimensions on to the end of the title in the format ``<Volume-name>_<x-dimension>x<y-dimension>x<z-dimension>x<bit-depth>bit``.
It will prompt for confirmation before actually doing the rename.  If saved as a raw file with this at the end of the filename fiji can automatically parse
it and open it without needing manual dimensions being entered.

## AutomaticConcatenationPlusIntensityEqualisation
Takes two overlapping scan volumes (with same bit depth) and finds the same slice in both prior to concatenating into a new stack.  The defaults should generally work satisfactorily, but can be overridden to provide
more flexibility if needed.  It will prompt the user to navigate to approximately the same slice in each stack and with then search either side of that oo the top stack to find the best match.  
Due to the physical configuration of the scanners this macro was written for heel effect is present in the scans, this is corrected when concatenating the scans otherwise there will be a 
significant step change.  Once complete the script will provide 8 different rotational slices of the concatenated stack so that the result can be evaluated.

## AutoVideoGenerationSingleAndThickSlicesRoll
Takes an image stack and automatically generates a series of videos that scroll through the stack showing different image processing options.  The video file name is auto generated based on the input volume name. For each video that is generated a .txt file with the same filename will be created with an auto generated description of how the video was generated.

The script will prompt user to adjust image and contrast of the stack
prior to generating the videos to enable contrast optimisation.  
The user can selection to enable auto generation of the following video types: 
- X, Y, Z single slice scroll through
- MIP, AVG & SUM thick slice scroll through.
Other options:
- Reslice volume - See HistRelevantReslice
- Slice thickness
- Start slice
- End slice
The output videos can have Gamma and saturation correction applied, or manual brightness/contrast can be selected.

If auto generation is disabled then the following single stacks can be created
- Average Intensity
- Max Intensity
- Sum slices
- Min Intensity
- Standard deviation

Prior to video generation the volume can be cropped to only show a ROI.

## BackgroundLinearSlopeCorrection
Takes a volume as input.  The user needs to select an area containing background.  This area must contain background (e.g. wax) throughout the entire stack.  It then goes through this background area and identifies any linear gradient between the slices.

TODO OLK TO add more in here.

## BicubisStackResize
TAkes on a volume and resizes it by the same amount in all dimensions. It prompts the user to enter how many times they want to bin the data, for example 2 would half the size of all dimensions.  If binning by an even number and the volume has an odd dimension it will remove 1 pixel in the required dimension to make it even.

## cassetteBandsCorrection
When scanning a wax block on a histology cassette the plastic cassette itself can cause artefacts that propagate through the image, this macro is designed to remove them.  This works on a single volume that has the issue and tries to remove the artefacts.  The volume must first be orientated so that scrolling through the Z stack scrolls through the histologically relevant plane.  This can be achieved using the HistologicalReleventReslice macro.

Once the user has selected the volume they will be prompted to draw a line parallel to the cassette artefact that they want to remove (a single slice will be presented for this to be done on).  The volume is then rotated so that the line is parallel to Y'Y. The volume is rotated back to the original angle at the end of the script.  If manual operation is chosen then the user has to manually select a background area of the volume.  Each slice will then be processed in turn.  The user can chose to do grey level calibration at the end to remove any offset introduced by the processing.

## HistRelevantReslice
Works on a single volume, and rotates it so that scrolling through the Z stack is the same as slicing the wax block with a microtome.

Options:
 - Manual/Automatic cropping of volume to wax.
 - Optimising memory usage - closes temporary volumes when no longer needed to free up system RAM.
 
 This script prompts the user to draw a line on the wax-air boundary for each plane and will then rotate the volume to align these with the axis, enlarging the volume as needed.  At the end an option is given to reverse the stack if it is slicing from cassette to top of block rather than top down.

## ImportRAWandNikonVOLfiles
A simple macro to make opening either RAW files or vgi./.vol files easier & quicker.  Can be bound to shortcut keys e.g. 'v' and 'g' to make opening even quicker.
Can either open a file in normal mode or virtual mode if the entire file isn't needed or there is not enough RAM. This will pop up the import RAW dialogue so that the read in values can be verified.


### .vol/vgi files
The macro can be given either a .vgi or a .vol file, it will then find the matching other file and use the combined information to open the volume.
It will automatically pull the x,y,z dimensions and the bit depth from the vgi file.

### Raw files
These need to have the filename in the format as described in addVolumeDimensions.  

## Suppress Lines
Works on a single volume to suppress repeating straight lines throughout the volume.  The user is prompted for a number of parameters:
- Number of line orientations to suppress
- Frequency bandwidth for the FFT filter used to suppress the Lines
- Orientation rigidity - how much the line can deviate from line specified.
- Gamma correction factor
- Calibration - adjust the post correction grey values to match the pre-correction ones

## ThickSliceBoost
Works on a single volume and will use a rolling thick slice window to combine slices to enhance the image.  

Options:
- Number of slices to include in calculation
- Operation to use to generate boosted volume
    - Average intensity
    - Max intensity
	- Min intensity
	- Standard deviation
	- Median
- Operation to use to combine boosted volume with original volume
	- Average Intensity
	- Max Intensity
	- Min Intensity
	- Standard deviation
	- Add
	- Subtract
	- Multiply
	- Difference
- Gamma correction factor

A volume of thick slices will be generated using the first algorithm selected, this volume is then combined with the original to enhance each slice using the second algorithm.  Grey levels can then be corrected using the gamma correction.

## Thick Slice Roll
Works on a single volume, will prompt user to crop an area of interest if desired.  Will go through the entire stack combining the desired number of slices into a single slice before moving onto the next one.
Options:
- Number of slices to use per thick slice
- Start slice
- End slice
- Operation
	- Average Intensity
	- Max Intensity
	- Sum slices
	- Min Intensity
	- Standard deviation
- Gamma correction factor.

## XRHEnhance
Works on a single volume and provides a range of options that can be used to improve the quality of a scan.  It will then run through the entire stack slice by slice, duplicating the slice and then applying a Gaussian blur of the specified size. This blurred image is then subtracted from the original image to create a high pass filter, this is then averaged with the original image.  Once this process is complete then if CLAHE is selected it will run "Enhance Local Contrast (CLAHE)" with the parameters specified. Finally the volume can be converted to 16bit and the options used added to the name stack as a prefix.

Options:
- Gaussian blue sigma
- 3D Median X radius
- 3D Median Y radius
- 3D Median Z radius
- CLAHE
	- 0: Do not use
	- 1: accurate (slow)
	- 2: fast
- CLAHE512 - use 512 bins instead of the usual 1500
- 32->16bit conversion - convert to 16 bit using the range -50 to 100
- Duplicate - apply on a new volume instead of the original




## XRHProcess
Works on a single volume and performs the following operations, see above for descriptions of the first 3 sub steps:
1 HistRelevantReslice
2 XRH-enhance
3 Suppress Lines
4 Add scale

Can chose to optimise memory usage, in which case the intermediate steps will be closed to free up system resources.  If adding a scale is selected it will use the inbuilt ``set scale`` command to add a scale to the volume.