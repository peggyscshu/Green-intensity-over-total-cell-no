/*
 * - Measure the bac aggregation/ cell no.
 * - Modification in this version 1.2
 *   1. For image with higher frame size from XXXXX?
 *   2. Increase the default setting for region selection.
 *   3. Apply "Deblur and background subtraction" to create the mask of bac.
 *   4. The intensity of bac was from the background subtracted green channel.
 *   5. Apply "Deblur and Background subtraction" prior to count nucleus.
 * - Compiled by Shao-Chun, Peggy, Hsu by 2024/1/10
 * - peggyschsu@ntu.edu.tw
 * 
 */


//Prepare for quantification
	tifName = getTitle();
	Name = replace(tifName, ".TIF", "");
	path = getDirectory("image");
	rename("Raw");
	Image.removeScale();
	run("Specify...", "width=7000 height=7000 x=3876 y=4584 oval centered");
	setTool("oval");
	waitForUser("Please modify with the points to make it fit");
	setBackgroundColor(0, 0, 0);
	run("Clear Outside");
	run("Duplicate...", "Raw-1");
	selectWindow("Raw");
	close();
	selectWindow("Raw-1");
	rename("Raw");
	run("Duplicate...", "title=QuanG");
//Quantify dots no
	selectWindow("QuanG");
	run("Split Channels");
	selectWindow("QuanG (green)");
	rename(Name);
	//Generate ROI
		selectWindow(Name);
		run("Duplicate...", "title=QuanG_mask");
		run("Gaussian Blur...", "sigma=2");
		run("Subtract Background...", "rolling=20");
		setThreshold(15, 255, "raw");
		run("Convert to Mask");
		run("Erode");
		run("Analyze Particles...", "size=2-Infinity add");
		roiManager("Save", path + File.separator + Name + "_Gpostive.zip");
	//Measure background subtracted Bac image
		selectWindow(Name);
		run("Subtract Background...", "rolling=20");
		roiManager("Show All");
		run("Set Measurements...", "integrated redirect=None decimal=2");
		roiManager("Measure");
		run("Summarize");
		bac_puncta_no = roiManager("count");
		bac_intsum_mean = getResult("IntDen", bac_puncta_no);
		bac_int_sum = bac_intsum_mean * bac_puncta_no;
		/*
		print(bac_puncta_no);
		print(bac_intsum_mean);
		print(bac_int_sum);
		 */
	//Clear
		selectWindow("QuanG (red)");
		close();
		selectWindow(Name);
		close();
		roiManager("deselect");
		roiManager("Delete");
		run("Clear Results");
//Quantify Nucleus
	selectWindow("QuanG (blue)");
	run("Gaussian Blur...", "sigma=2");
	run("Subtract Background...", "rolling=50");
	setThreshold(81, 255);
	run("Convert to Mask");
	run("Watershed");
	run("Find Maxima...", "prominence=5 light output=Count");
	cell_count = Table.get("Count", 0);
//Creat result table
	bac_intOvercell_count = bac_int_sum/cell_count;
	Table.deleteColumn("Count");
	Table.set("Bac aggregate no.", 0, bac_puncta_no);
	Table.set("Bac intensity sum", 0, bac_int_sum);
	Table.set("Cell count", 0, cell_count);
	Table.set("Bac int/ Cell no", 0, bac_intOvercell_count);
	Table.rename("Results", Name);
//Save result
	selectWindow("QuanG (blue)");
	saveAs("Tiff", path + File.separator + Name + "_DAPI.tif");
//Clear
	selectWindow("QuanG_mask");
	close();
	selectWindow(Name + "_DAPI.tif");
	close();	
//Data validation
	selectWindow("Raw");
	open(path + File.separator + Name + "_Gpostive.zip");
	roiManager("Show All without labels");
//Status disclose
    waitForUser("Please check the ROI of bac and then save the measurements.");