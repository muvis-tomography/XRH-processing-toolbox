macro "import_raw_vol [v]" {
/*
	 Copyright 2017 University of Southampton
	 Charalambos Rossides
	 Bio-Engineering group
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

	------------

	ImageJ/FiJi macro to automate the process of imprting .vol or .raw files.
	Bound to the keyboard shortcut [v], it opens a system dialog where the user selects a .vgi, .vol or .raw file to improt.
	It assumes that a .raw filename is of the format <<path_to_file>>_<<SizeX>>x<<SizeY>>x<<SizeZ>>x<<Bitsize>>bit
	or a .vol file and a .vgi file exist in the same directory, with the .vgi file containing the necessary information to import the .vol file.
	It also assumes that .raw files are saved in big-endian order, whereas .vol files are saved in little-endian order.
	The special characters ".", "[" and "]" are allowed in the path.
*/

/* ChangeLog
 * v20211014 
 * 	added option for user to select between Virtual or real import
 * 	v20220524 will now import 32bit float = PJB
 */

 
Dialog.create("Import volume");
Dialog.addCheckbox("Import as Virtual Stack ", false);
Dialog.addMessage("Use Virtual Stack if the volume is too big for system's available memory");
Dialog.show();
VirtualImport = Dialog.getCheckbox();

	path = File.openDialog("Import .vgi/.vol or .raw file:");
	pathfile = substring(path, 0, lastIndexOf(path, "."));
	extension = substring(path, lastIndexOf(path, ".")+1, lengthOf(path));

	if(extension=="vol" || extension=="vgi"){
	  vgifile=File.openAsString(pathfile+".vgi");
	  rows=split(vgifile, "\n");

	  for(i=0; i<rows.length; i++){
	    columns=split(rows[i],"=");

	    if (indexOf(columns[0], "size", 0)==0){
	      size = split(columns[1]," ");
	      sizeW=size[0];
	      sizeH=size[1];
	      sizeZ=size[2];
	    }

	    if (indexOf(columns[0], "bitsperelement", 0)==0){
	    	bitsize = split(columns[1]," ");
	      	bitsize = bitsize[0];
	    }

	    if (indexOf(columns[0], "datatype", 0)==0){
	    	datatype = split(columns[1]," ");
	    	datatype = datatype[0];

	      if (datatype=="float"){
	      		datatype = "Real";
	      	}
	      	else{
	      		datatype = "Unsigned";
	        }
	    }
	  }

	  filename = pathfile +".vol";
	  if (VirtualImport==true) {
	  	run("Raw...", "open='" + filename +"' image=[" + bitsize + "-bit " + datatype + "] width="+sizeW + " height="+sizeH + " number="+sizeZ +" little-endian use");
	  	}
	  	else {
	  		run("Raw...", "open='" + filename +"' image=[" + bitsize + "-bit " + datatype + "] width="+sizeW + " height="+sizeH + " number="+sizeZ +" little-endian ");
	  	}
	}

	if(extension=="raw"){
	  settings=substring(path, lastIndexOf(path, "_")+1, lengthOf(path));
	  settings=split(settings, ".");
	  settings=split(settings[0], "[xX]");
	  sizeW=settings[0];
	  sizeH=settings[1];
	  sizeZ=settings[2];
	  bitsize=split(settings[3], "bit");
	  bitsize=bitsize[0];

	  filename = pathfile +".raw";
	  cmd = "open='" + filename + "' ";

	  if (bitsize == 8){
	  	cmd += " image=[8-bit]"
	  }else if (bitsize == 32){
	  	cmd += "image=["+bitsize+"-bit Real]";
	  }else{
	  	cmd += "image=[" + bitsize + "-bit Unsigned]";
	  }
	  cmd += "width=" + sizeW + " height=" + sizeH + " number=" + sizeZ + " big-endian";
	  if(VirtualImport == true){
	  	cmd += " use";
	  }
	  run("Raw...", cmd);
	 
}