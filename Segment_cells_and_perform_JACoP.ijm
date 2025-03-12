/*
 * Macro to perform Cellpose segmentation and subsequent BIOP JACoP colocalization analysis on every cell for all images in a folder.
 * Requires the Fiji Update Sites:
 * - CLIJ
 * - CLIJ2
 * - PT-BIOP
 * Cellpose is executed using the BIOP Cellpose wrapper. Therefore, a Python Cellpose environment (venv or conda) is required.
 * Run the wrapper at least once to set the cellpose environment path and type.
 * 
 * Input: a folder containing multichannel 2D images. Multiseries microscopy format files (.lif, .czi etc.) are also supported.
 * Output:
 * - labelmap images containing Cellpose segmentations
 * - Analyzed images with two extra channels containing the used masks (thresholds) for colocalization.
 *   The analysis parameters are added to the "Info" image property [Image>Show Info] as part of the TIFF header).
 * - .tsv files with colocalization results

 * Author: Bram van den Broek, Netherlands Cancer Institute, March 2024
 * b.vd.broek@nki.nl
 * 
 * 
 */

#@ String	file_message 			(value="<html><p style='font-size:12px; color:#3366cc; font-weight:bold'>File settings</p></html>", visibility="MESSAGE")
#@ File 	input					(label = "Input directory", style = "directory")
#@ File		output					(label = "Output directory", style = "directory")
#@ String 	fileExtension			(label = "Process files with extension", value = "lif")

#@ String	image_message 			(value="<html><p style='font-size:12px; color:#3366cc; font-weight:bold'>Image settings</p></html>", visibility="MESSAGE")
#@ Integer 	nucleiChannel			(label = "Nuclei channel (-1 if not used)", value = 1)
#@ Integer	cytoChannel 			(label = "Cytoplasm channel", value = 2)
#@ Integer	colocChannelA 			(label = "colocalization channel A", value = 2)
#@ Integer	colocChannelB 			(label = "colocalization channel B", value = 3)
#@ Integer	XYBinning				(label = "Image XY binning before analysis [1-n]", value = 1, min=1)
#@ Double	GaussianBlurSigma		(label = "Gaussian blur radius (sigma) before JACoP (pixels)", value = 1, min=0)

#@ String	segmentation_message 	(value = "<html><p style='font-size:12px; color:#3366cc; font-weight:bold'>Cell detection settings</p></html>", visibility="MESSAGE")
#@ String 	CellposeModel			(label = "Cellpose model", choices={"cyto3","cyto2_cp3","nuclei","custom"}, style="listBox", value="cyto3")
#@ Integer	CellposeDiameter		(label = "Cell diameter (pixels), 0 for automatic", value = 80, min=0, description="Estimation of the cell diameter. Automatic may work, but is not always the best choice.")
#@ Double 	flowThreshold			(label = "flow threshold [0.0 - 1.0], default 0.4", value = 0.4, min=0, max=1, style="format:0.0", description="higher values will accept more cells")
#@ Double	cellprobThreshold		(label = "probability threshold [-6.0 - 6.0], default 0.0", value = 0.0, min=-6, max=6, style="format:0.0", description="lower values will accept more cells and also enlarge the segmentations")
#@ Boolean	load_labelmap_boolean	(label = "Load segmentation label images from disk instead of Cellpose?", value=false)
#@ File		labelmapFolder			(label = "Folder containing label images", style = "directory", required=false, description="Load segmented labels from disk instead of running Cellpose segmentation. Label images should have the same basename as the input images, complemented with '_labelmap.tif'.")

#@ String	coloc_message 			(value = "<html><p style='font-size:12px; color:#3366cc; font-weight:bold'>JACoP settings</p></html>", visibility="MESSAGE")
#@ String	thresholdMethodA		(label = "Threshold method channel A", choices = {"Costes Auto-Threshold", "Default", "Huang", "Intermodes", "IsoData", "IJ_IsoData", "Li", "MaxEntropy", "Mean", "MinError", "Minimum", "Moments", "Otsu", "Percentile", "RenyiEntropy", "Shanbhag", "Triangle", "Yen", "Use Manual Threshold Below"}, style="list", value="Costes Auto-Threshold")
#@ String	thresholdMethodB		(label = "Threshold method channel B", choices = {"Costes Auto-Threshold", "Default", "Huang", "Intermodes", "IsoData", "IJ_IsoData", "Li", "MaxEntropy", "Mean", "MinError", "Minimum", "Moments", "Otsu", "Percentile", "RenyiEntropy", "Shanbhag", "Triangle", "Yen", "Use Manual Threshold Below"}, style="list", value="Costes Auto-Threshold")
#@ Integer 	manualThresholdA		(label = "Manual threshold channel A", value = 0, min=0, description="Only used when Threshold method is set to 'Use Manual Threshold Below'")
#@ Integer	manualThresholdB		(label = "Manual threshold channel B", value = 0, min=0, description="Only used when Threshold method is set to 'Use Manual Threshold Below'")

version = 1.0;

var nrOfImages = 0;
var current_image_nr = 0;
var processtime = 0;
var envPath = "";
var envType = "";
setOption("ExpandableArrays", true);
var boundingBox_X = newArray();
var boundingBox_Y = newArray();
var boundingBox_width = newArray();
var boundingBox_height = newArray();

outputSubfolder = output;	//initialize this variable
if(!File.exists(output)) File.makeDirectory(output);
saveSettings();

run("Set Measurements...", "area mean median min stack redirect=None decimal=3");
roiManager("reset");
run("Clear Results");
run("Input/Output...", "jpeg=85 gif=-1 file=.tsv use_file copy_row save_column save_row");
if(nImages>0) run("Close All");
print("\\Clear");
if(load_labelmap_boolean == false) check_cellpose();
CellposeModelPath = "path\\to\\own_cellpose_model";
run("CLIJ2 Macro Extensions", "cl_device=");

//Create parameter list
getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
MonthNames = newArray("Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec");
DayNames = newArray("Sun", "Mon","Tue","Wed","Thu","Fri","Sat");
List.set("00. ==Colocalization Script Analysis settings=", "");
List.set("00. Date ", " " + DayNames[dayOfWeek] + " " + dayOfMonth + " " + MonthNames[month] + " " + year);
List.set("00. Time ", " " + hour +":"+IJ.pad(minute,2)+":"+IJ.pad(second,2));
List.set("00. Version ", version);
List.set("01. input ", input);
List.set("02. output ", output);
List.set("03. fileExtension ", fileExtension);

List.set("04. nucleiChannel ", nucleiChannel);
List.set("05. cytoChannel ", cytoChannel);
List.set("06. colocChannelA ", colocChannelA);
List.set("07. colocChannelB ", colocChannelB);
List.set("08. XYBinning", XYBinning);
List.set("09. GaussianBlurSigma", GaussianBlurSigma);

List.set("10. CellposeModel", CellposeModel);
List.set("11. CellposeDiameter", CellposeDiameter);
List.set("12. flowThreshold", flowThreshold);
List.set("13. cellprobThreshold", cellprobThreshold);
List.set("14. load_labelmap_boolean", load_labelmap_boolean);
List.set("15. labelmapFolder", labelmapFolder);

List.set("16. thresholdMethodA", thresholdMethodA);
List.set("17. thresholdMethodB", thresholdMethodB);
List.set("18. manualThresholdA", manualThresholdA);
List.set("19. manualThresholdB", manualThresholdB);

parameterList = List.getList();


setBatchMode(true);

if(!File.exists(input)) exit("Error: Input folder '"+input+"' not found!");
scanFolder(input);
processFolder(input);

restoreSettings;



// function to scan folders/subfolders/files to count files with correct fileExtension
function scanFolder(input) {
	list = getFileList(input);
	list = Array.sort(list);
	for (i = 0; i < list.length; i++) {
		if(File.isDirectory(input + File.separator + list[i]))
			scanFolder(input + File.separator + list[i]);
		if(endsWith(list[i], fileExtension))
			nrOfImages++;
	}
	print(nrOfImages + " ."+fileExtension+" images found");
}


// function to scan folders/subfolders/files to find files with correct fileExtension
function processFolder(input) {
	list = getFileList(input);
	list = Array.sort(list);
	for (i = 0; i < list.length; i++) {
		if(File.isDirectory(input + File.separator + list[i])) {
			outputSubfolder = output + File.separator + list[i];	
			if(!File.exists(outputSubfolder)) File.makeDirectory(outputSubfolder);	//create the output subfolder if it doesn't exist
			path = input + File.separator + list[i];
			if(substring(path, path.length-1, path.length) == "/") {
				processFolder(substring(path, 0, path.length-1));	//remove the slash that otherwise ends up in the image name
			}
			else processFolder(path);
		}
		if(endsWith(list[i], fileExtension)) {
			current_image_nr++;
			showProgress(current_image_nr/nrOfImages);
			processFile(input, outputSubfolder, input + File.separator + list[i]);
		}
	}
	//	print("\\Clear");
	print("\\Update1:Finished processing "+nrOfImages+" files.");
	print("\\Update2:Average speed: "+d2s(current_image_nr/processtime,1)+" images per minute.");
	print("\\Update3:Total run time: "+d2s(processtime,1)+" minutes.");
	print("\\Update4:-------------------------------------------------------------------------");
}


function processFile(input, output, file) {
	starttime = getTime();
	print("\\Update1:Processing file "+current_image_nr+"/"+nrOfImages+": " + file);
	print("\\Update2:Average speed: "+d2s((current_image_nr-1)/processtime,1)+" images per minute.");
	time_to_run = (nrOfImages-(current_image_nr-1)) * processtime/(current_image_nr-1);
	if(time_to_run<5) print("\\Update3:Projected run time: "+d2s(time_to_run*60,0)+" seconds ("+d2s(time_to_run,1)+" minutes).");
	else if(time_to_run<60) print("\\Update3:Projected run time: "+d2s(time_to_run,1)+" minutes. You'd better get some coffee.");
	else if(time_to_run<480) print("\\Update3:Projected run time: "+d2s(time_to_run,1)+" minutes ("+d2s(time_to_run/60,1)+" hours). You'd better go and do something useful.");
	else if(time_to_run<1440) print("\\Update3:Projected run time: "+d2s(time_to_run,1)+" minutes. ("+d2s(time_to_run/60,1)+" hours). You'd better come back tomorrow.");
	else if(time_to_run>1440) print("\\Update3:Projected run time: "+d2s(time_to_run,1)+" minutes. This is never going to work. Give it up!");
	print("\\Update4:-------------------------------------------------------------------------");

	run("Bio-Formats Macro Extensions");
	Ext.setId(file);
	Ext.getSeriesCount(nr_series);

	run("CLIJ2 Macro Extensions", "cl_device="); //Necessary to do this here again, because you can only activate one Macro Extension at the time
//	Ext.CLIJ2_clear();
	filename = File.getName(file);
	fileExtension = substring(filename, lastIndexOf(filename, "."), lengthOf(filename));
	if(endsWith(fileExtension, "tif") || endsWith(fileExtension, "jpg") || endsWith(fileExtension, "png")) {	//Use standard opener
		open(file);
		if(XYBinning > 1) run("Bin...", "x="+XYBinning+" y="+XYBinning+" z=1 bin=Average");
		process_current_series(file, true, flatfield);
	}
	else {	//Use Bio-Formats
		for(s = 0; s < nr_series; s++) {
			run("Close All");
			roiManager("reset");
			run("Clear Results");
			
			run("Bio-Formats Importer", "open=["+file+"] autoscale color_mode=Default view=Hyperstack stack_order=XYCZT series_"+s+1);
			seriesName = getTitle();
			seriesName = replace(seriesName,"\\/","-");	//replace slashes by dashes in the seriesName
//			print(seriesName);
//			outputPath = output + File.separator + substring(seriesName)
			if(XYBinning > 1) run("Bin...", "x="+XYBinning+" y="+XYBinning+" z=1 bin=Average");
			process_current_series(seriesName, false);
		}
	}
}


function process_current_series(original, IJOpener) {
	Stack.setDisplayMode("grayscale");
	run("Enhance Contrast", "saturated=0.35");

	original = getTitle();
	
	getDimensions(width, height, channels, slices, frames);
	getPixelSize(unit, pw, ph);

	//save corrected image
	if(IJOpener) imageName = File.getNameWithoutExtension(original);
	else imageName = original;

	if(load_labelmap_boolean == false) {
		run("Cellpose ...", "env_path="+envPath+" env_type="+envType+" model=["+CellposeModel+"] model_path=["+CellposeModelPath+"] diameter="+CellposeDiameter+" ch1="+cytoChannel+" ch2="+nucleiChannel+" additional_flags=[--use_gpu, --flow_threshold, "+flowThreshold+", --cellprob_threshold, "+cellprobThreshold+"]");
		labelmap = select_image_containing_string("-cellpose");
		resetMinAndMax();
		run("glasbey_on_dark");
	}
	else {
		open(labelmapFolder + File.separator + imageName + "_labelmap.tif");
		labelmap = getTitle();
	}

	nrCells = getValue("Max");
	labelmap_to_ROI_Manager(labelmap);
	selectImage(original);
	Stack.setDisplayMode("composite");
	Stack.setChannel(colocChannelA);
	if(GaussianBlurSigma>0) run("Gaussian Blur...", "sigma="+GaussianBlurSigma+" slice");
	run("Enhance Contrast", "saturated=0.1");
	getLut(redsA, greensA, bluesA);
	Stack.setChannel(colocChannelB);
	if(GaussianBlurSigma>0) run("Gaussian Blur...", "sigma="+GaussianBlurSigma+" slice");
	run("Enhance Contrast", "saturated=0.1");
	getLut(redsB, greensB, bluesB);
	Stack.setChannel(nucleiChannel);
	resetMinAndMax;
	run("biop-Azure");
	roiManager("show all with labels");
//	setBatchMode("show");

	close("Results");
	run("BIOP JACoP", "channel_a="+colocChannelA+" channel_b="+colocChannelB+" threshold_for_channel_a=["+thresholdMethodA+"] threshold_for_channel_b=["+thresholdMethodB+"] manual_threshold_a="+manualThresholdA+" manual_threshold_b="+manualThresholdB+" crop_rois get_pearsons get_spearmanrank get_manders get_overlap costes_block_size=5 costes_number_of_shuffling=100");

	//Add the thresholded masks used in the colocalization to the original image as new channels
	selectImage(original);
	maskChannelA = channels+1;
	maskChannelB = channels+2;
	Stack.setChannel(channels);
	run("Add Slice", "add=channel");
	Stack.setChannel(maskChannelA);
	setLut(redsA, greensA, bluesA);
	setMinAndMax(0, 512);
	run("Add Slice", "add=channel");
	Stack.setChannel(maskChannelB);
	setLut(redsB, greensB, bluesB);
	setMinAndMax(0, 512);
	rename(original);
	Stack.setChannel(1);
	setMetadata("info", parameterList);

	for(i=0; i<nrCells; i++) {
		showStatus("Adding masks... ("+i+"/"+nrCells+")");
		showProgress(i, nrCells);
		selectImage(original + " (cell_"+i+1+") Report");
		roiManager("select", i);
		Roi.move(0,boundingBox_height[i]);	//Move selection
		run("Copy");
		selectImage(original);
		Stack.setChannel(maskChannelA);
		roiManager("select", i);
		Roi.move(boundingBox_X[i], boundingBox_Y[i]);
		run("Paste");
		
		selectImage(original + " (cell_"+i+1+") Report");
		Roi.move(boundingBox_width[i],boundingBox_height[i]);	//Move selection
		run("Copy");
		selectImage(original);
		Stack.setChannel(maskChannelB);
		Roi.move(boundingBox_X[i], boundingBox_Y[i]);
		run("Paste");
	}

	//Save results
	if(load_labelmap_boolean == false) {
		selectImage(labelmap);
		saveAs("Tiff", output + File.separator + imageName+"_labelmap");
		print("Saving labelmap:" + output + File.separator + imageName);
	}
	
	selectImage(original);
//	setBatchMode("show");
	saveAs("Tiff", output + File.separator + imageName+"_analyzed");
	print("Saving image:" + output + File.separator + imageName);

	saveAs("results", output + File.separator + imageName + "_results.tsv");

	run("Close All");
	endtime = getTime();
	processtime = processtime+(endtime-starttime)/60000;
}


//Check which version of the BIOP Cellpose wrapper is present, if at all.
function check_cellpose() {
	List.setCommands;
	if (List.get("Cellpose ...")!="") {
		//Get Cellpose settings
		//This works for the new wrapper
		envPath = getPref("Packages.ch.epfl.biop.wrappers.cellpose.ij2commands.Cellpose", "env_path");
		envType = getPref("Packages.ch.epfl.biop.wrappers.cellpose.ij2commands.Cellpose", "env_type");
		if(envType == "<null>") envType = "conda";	//Default is conda, but returns <null>
//		print("BIOP Cellpose wrapper detected");
	}
	else if (List.get("Cellpose Advanced")!="") {
		exit("Error: Old version of the Cellpose wrapper detected. Please Update the plugin via Help -> Update... and try again.");
	}
	else exit("ERROR: Cellpose wrapper not found! Update Fiji and activate the PT-BIOP Update site.");
	List.clear();
}


//Get the persistent value of the script parameter 'param' in class. N.B. This returns 'null' when the parameter is set to the default value!
function getPref(class, param) {
	return eval("js",
		"var ctx = Packages.ij.IJ.runPlugIn(\"org.scijava.Context\", \"\");" +
		"var ps = ctx.service(Packages.org.scijava.prefs.PrefService.class);" +
		"var " + param + " = ps.get(" + class + ".class, \"" + param + "\", \"<null>\");" +
		param + ";"
	);
}


function labelmap_to_ROI_Manager(labelmap) {
	Ext.CLIJ2_clear();
	
	roiManager("Reset");
	run("Clear Results");
	
	Ext.CLIJ2_push(labelmap);

	startTime = getTime();
	
	//Determine the largest bounding box required to fit all the labels
	Ext.CLIJ2_statisticsOfLabelledPixels(labelmap, labelmap);
	boundingBox_X = Table.getColumn("BOUNDING_BOX_X", "Results");
	boundingBox_Y = Table.getColumn("BOUNDING_BOX_Y", "Results");
	boundingBox_width = Table.getColumn("BOUNDING_BOX_WIDTH", "Results");
	boundingBox_height = Table.getColumn("BOUNDING_BOX_HEIGHT", "Results");
	Array.getStatistics(boundingBox_width, min, boundingBoxMax_X, mean, stdDev);
	Array.getStatistics(boundingBox_height, min, boundingBoxMax_Y, mean, stdDev);
//	print("Maximum boundingBox size: "+boundingBoxMax_X+", "+boundingBoxMax_Y);
	
	//Crop labels, pull to ROI Manager and shift to the correct location
	labels = Table.getColumn("IDENTIFIER", "Results");
	for (i = 0; i < labels.length; i++) {
		Ext.CLIJ2_crop2D(labelmap, label_cropped, boundingBox_X[i], boundingBox_Y[i], boundingBoxMax_X, boundingBoxMax_Y);
		Ext.CLIJ2_labelToMask(label_cropped, mask_label, labels[i]);
		Ext.CLIJ2_pullToROIManager(mask_label);
		roiManager("Select",i);
		Roi.move(boundingBox_X[i], boundingBox_Y[i]);
		roiManager("rename", "cell_"+labels[i]);
		roiManager("update");
	}
	
	run("Select None");
	roiManager("deselect");
	Ext.CLIJ2_release(labelmap);
	Ext.CLIJ2_release(mask_label);
	Ext.CLIJ2_release(label_cropped);
	
	run("Clear Results");
//	print("Done in "+getTime() - startTime+ " ms.");
}


//Select an image with a name that contains the string argument
function select_image_containing_string(name) {
	imageList = getList("image.titles");
	for(i=0 ; i<imageList.length ; i++) {
		if(matches(imageList[i],".*"+name+".*")) {
			selectWindow(imageList[i]);
			return getTitle();
		}
	}
	return;
}