//******* STRIP SENSOR ANALYSIS 
//******* Sara De Bragança, 19 Aug 2018 

//OPEN STRIPS TO ANALYSE
		run("Close All");
		setBatchMode(true);
		open();
		ImagePath=File.directory;
		ImageName=File.nameWithoutExtension;

//MAKE A DUPLICATE TO AVOID CHANGES ON THE ORIGINAL FILE
		rename("original")
		run("Duplicate...", "title=duplicate duplicate");
		selectWindow("original");
		close();
		selectWindow("duplicate");
		setBatchMode("show");	 	
		getLocationAndSize(x, y, width, height); //Returns the location and size, in screen coordinates, of the active image window.

 			Dialog.create("Sensor Strips Analysis");
 			Dialog.addString("Image title:", ImageName, 15);
  			Dialog.addNumber("Total nº of strips:", 0 );
  			Dialog.addCheckbox("Show invert LUT",false); //It could help see by eye the signal better for really small concentrations, it does not change the pixel values!
  			Dialog.addCheckbox("Add strip tag",true);
  			Dialog.addCheckbox("Automatically save all data", true);
   			Dialog.addMessage("By selecting this last checkbox, all data will\nbe saved in a folder located in the same\n directory as the original image.");
   			Dialog.addString("Folder name:", "imgJ_analysis",15);
  			Dialog.setLocation(x+(width/30)+width,y);
  			Dialog.show;
  			ImageName = Dialog.getString;
  			stripsnumber = Dialog.getNumber;
  			invertLUT = Dialog.getCheckbox;
  			striptag = Dialog.getCheckbox;
  			autosave = Dialog.getCheckbox;
  			FolderName = Dialog.getString;		

//Confirm that there is no file with the same name in the path chosen, because otherwise it will be replaced when running the macro.
		exist=File.exists(ImagePath+ImageName+"_"+FolderName);
		if(exist==true){	
			Dialog.create("Action Required");
				Dialog.addMessage("There is an existing folder with the chosen name! \n If you choose to continue, there is a risk that\n some data might be replaced.\n If You exit the macro, no changes will be made to the folder.\n Please, decide how to proceed.");
				decision = newArray("Continue", "Rename Folder", "Exit Macro");
				Dialog.addRadioButtonGroup("Do:",decision , 3, 1, "Exit Macro");	
			Dialog.show();
			decision = Dialog.getRadioButton();

			if(decision=="Continue"){
				Folder=File.makeDirectory(ImagePath+ImageName+"_"+FolderName);
			}else{
				if(decision=="Exit Macro"){
					exit("Macro stopped.");
				}else{
					Dialog.create("Action Required");
 					Dialog.addString("New Folder Name:", "imgJ_analysis");
 					Dialog.show();
 					FolderName = Dialog.getString;	
 					
 					exist=File.exists(ImagePath+ImageName+"_"+FolderName);
 					if(exist==true){	
						waitForUser("There is an existing folder with the chosen name! \n The macro will exit.");
						exit("Macro stopped.");
 					}else{
 						Folder=File.makeDirectory(ImagePath+ImageName+"_"+FolderName);
 					}
				}
			}
				
		}else{
			Folder=File.makeDirectory(ImagePath+ImageName+"_"+FolderName);
		}


//SELECT & CROP THE TEST LINE
		
		if(invertLUT==true){
			selectWindow("duplicate");
			setBatchMode("hide");
			run("Duplicate...", "title=invertLUT");
			run("8-bit");
			run("Invert LUT");
			selectWindow("invertLUT");
			setBatchMode("show");
			waitForUser("In order to proceed, draw a\n rectangle selecting the test band\n in all strips and then press OK."); 
			 if (selectionType()<0)
			      exit("Rectangle selection required!");
			getSelectionBounds(x, y, width, height);
			run("Crop");	
			selectWindow("duplicate");
			rename("original_cropped.tif");
			setTool("rectangle");
			makeRectangle(x, y, width, height);
			run("Crop");
			if (autosave==true) {
				selectWindow("invertLUT");
				saveAs("Tiff", ImagePath+ImageName+"_"+FolderName+"/invertLUT.tif]");
				close("invertLUT.tif");
				selectWindow("original_cropped.tif");
				saveAs("Tiff", ImagePath+ImageName+"_"+FolderName+"/original_cropped.tif]");
			}
			
	
		}else{
			selectWindow("duplicate");
			rename("original_cropped.tif");
			waitForUser("In order to proceed, draw a\n rectangle selecting the test band\n in all strips and then press OK."); 
			 if (selectionType()<0)
			      exit("Rectangle selection required!");
			run("Crop");
			if (autosave==true) {
				saveAs("Tiff", ImagePath+ImageName+"_"+FolderName+"/original_cropped.tif]");
			}
			setBatchMode("hide");
		}
			
		
				
//ADJUST THE BRITHNESS TO ELIMINATE BACKGROUND PEAK 
		selectWindow("original_cropped.tif");
		//run("Brightness/Contrast...");
		setMinAndMax(56, 255);
		call("ij.ImagePlus.setDefault16bitRange", 8);		
		
//MAKE A MASK TO DESTROY ALL THE BACKGROUND NOISE
		selectWindow("original_cropped.tif");
		run("Duplicate...", "title=background_mask");
		run("8-bit");
		run("Median...", "radius=5");
		setBatchMode("show");
		setThreshold(35, 255);
		showMessageWithCancel("Action Required","Please, confirm that the threshold limits are correct,\n and press OK to Continue.\n(Note: If the threshold limits are not correct press Cancel\n and refer to the macro script or the author.)");
		run("Convert to Mask");
		run("Divide...", "value=255");
		setBatchMode("hide");
		
//RGB to 8-BIT CONVERSION 
	/* RGB images are converted to grayscale using on tof two formulas:
	    gray=(red+green+blue)/3 as default or 
	    gray=0.299red+0.587green+0.114blue if "Weighted RGB to Grayscale Conversion" is checked in Edit>Options>Conversions. 
	    https://sites.google.com/site/learnimagej/tutorials/converting-image-formats
	    */
		selectWindow("original_cropped.tif");
		run("Duplicate...", "title=[8-bit grayscale (direct conversion)]");
		run("Conversions...", "scale");
		run("8-bit");
		imageCalculator("Multiply", "8-bit grayscale (direct conversion)","background_mask");

		selectWindow("original_cropped.tif");
		run("Duplicate...", "title=[8-bit grayscale (weighted conversion)]");
		run("Conversions...", "scale");
		run("8-bit");
		imageCalculator("Multiply", "8-bit grayscale (weighted conversion)","background_mask");
		

//SPLIT CHANNELS AND SELECT THE CHANNEL FOR THE ANALYSIS
		selectWindow("original_cropped.tif");
		run("Split Channels");
		imageCalculator("Multiply", "original_cropped.tif (red)","background_mask");
		imageCalculator("Multiply", "original_cropped.tif (blue)","background_mask");
		imageCalculator("Multiply", "original_cropped.tif (green)","background_mask");
		close("background_mask");
		close("original_cropped.tif");
		setBatchMode("exit and display");
		run("Tile");
		setBatchMode(true);
		
 		Dialog.create("Sensor Strips Analysis");
 			Dialog.setInsets(5, 0, 5); 
  			Dialog.addMessage("The following options refer to the images\n obtained from processing the original RGB\n image. Choose which ones you wish to\n analyze. For the best signal resolution\n choose the images with the best contrast.")
  			channels = newArray("red", "green", "blue","all");
  			Dialog.addRadioButtonGroup("Original RGB channel:", channels, 1, 4, "all");
  			imgs = newArray("8-bit grayscale (direct conversion)", "8-bit grayscale (weighted conversion)","all");
  			Dialog.addRadioButtonGroup("Original RGB converted to:", imgs, 3, 1, "none");
  			Dialog.setLocation(x+(width/30)+width,y);
  			Dialog.show();
  			chosen_channel = Dialog.getRadioButton; 
			chosen_img = Dialog.getRadioButton; 

// PLOT PROFILES AND EXTRACT DATA TO .CSV
		run("Set Measurements...", "area mean standard min redirect=None decimal=5");
		
		if(striptag==true){
			setOption("ExpandableArrays", true);
  			tags = newArray;
			Dialog.create("Strips' Tags");
				for(i=1;i<=stripsnumber;i++){
					Dialog.addString("Strip "+i+":","");
				}
			Dialog.show;
			for(i=1;i<=stripsnumber;i++){
				stripname=Dialog.getString;
				tags[i-1] = stripname; 
			}
		}

		//CHANNEL ANALYSIS
		if(chosen_channel=="all"){
			channels=newArray("red","blue","green");
			for(i=0;i<=2;i++){
					
					//ProfilePlot
							selectWindow("original_cropped.tif ("+channels[i]+")");
							width=getWidth; 
							run("Select All");
							run("Plot Profile");
							Plot.setLimits(0,width,0,255);
							
					//Mean Gray Value
							selectWindow("original_cropped.tif ("+channels[i]+")");
							setThreshold(10, 255);
							run("Analyze Particles...", "size=50-Infinity show=Outlines display clear");
							if(striptag==true){
								for(k=1;k<=stripsnumber;k++){ 
									setResult("Strip Tag", k-1, tags[k-1]);
								}	
							}
							
					//Save Data
							if (autosave==true) {
								
								selectWindow("original_cropped.tif ("+channels[i]+")");
								saveAs("Tiff", ImagePath+ImageName+"_"+FolderName+"/"+ImageName+"_processed_"+channels[i]+"_channel.tif");
								
								selectWindow("Plot of original_cropped.tif ("+channels[i]+")");
								saveAs("Jpeg", ImagePath+ImageName+"_"+FolderName+"/2D_profile_plot_"+channels[i]+"_channel.jpg");
								
								selectWindow("Results");
								saveAs("Results", ImagePath+ImageName+"_"+FolderName+"/extracted_data_"+channels[i]+"_channel.csv");
								run("Close"); 
							}					
			}
		}else{
					//ProfilePlot
							selectWindow("original_cropped.tif ("+chosen_channel+")");
							width=getWidth; 
							run("Select All");
							run("Plot Profile");
							Plot.setLimits(0,width,0,255);
							
					//Mean Gray Value
							selectWindow("original_cropped.tif ("+chosen_channel+")");
							setThreshold(10, 255);
							run("Analyze Particles...", "size=50-Infinity show=Outlines display clear");
							if(striptag==true){
								for(k=1;k<=stripsnumber;k++){ 
									setResult("Strip Tag", k-1, tags[k-1]);
								}	
							}							
							
					//Save Data
							if (autosave==true) {
								
								selectWindow("original_cropped.tif ("+chosen_channel+")");
								saveAs("Tiff", ImagePath+ImageName+"_"+FolderName+"/"+ImageName+"_processed_"+chosen_channel+"_channel.tif");
								
								selectWindow("Plot of original_cropped.tif ("+chosen_channel+")");
								saveAs("Jpeg", ImagePath+ImageName+"_"+FolderName+"/2D_profile_plot_"+chosen_channel+"_channel.jpg");
								
								selectWindow("Results");
								saveAs("Results", ImagePath+ImageName+"_"+FolderName+"/extracted_data_"+chosen_channel+"_channel.csv");
								run("Close"); 
							}
		}


		//CONVERTED RGB IMG ANALYSIS
		if(chosen_img!="null"){
				if(chosen_img=="all"){
					imgs = newArray("8-bit grayscale (direct conversion)", "8-bit grayscale (weighted conversion)");
					for(i=0;i<=1;i++){
							
							//ProfilePlot
									selectWindow(imgs[i]);
									width=getWidth; 
									run("Select All");
									run("Plot Profile");
									Plot.setLimits(0,width,0,255);
									
							//Mean Gray Value
									selectWindow(imgs[i]);
									setThreshold(10, 255);
									run("Analyze Particles...", "size=50-Infinity show=Outlines display clear");
									if(striptag==true){
										for(k=1;k<=stripsnumber;k++){ 
											setResult("Strip Tag", k-1, tags[k-1]);
										}	
									}
									
							//Save Data
									if (autosave==true) {
										
										selectWindow(imgs[i]);
										saveAs("Tiff", ImagePath+ImageName+"_"+FolderName+"/"+ImageName+"_processed_"+imgs[i]+".tif");
										
										selectWindow("Plot of "+imgs[i]);
										saveAs("Jpeg", ImagePath+ImageName+"_"+FolderName+"/2D_profile_plot_"+imgs[i]+".jpg");
										
										selectWindow("Results");
										saveAs("Results", ImagePath+ImageName+"_"+FolderName+"/extracted_data_"+imgs[i]+".csv");
										run("Close"); 
									}					
					}
				}else{
							
							//ProfilePlot
									selectWindow(chosen_img);
									width=getWidth; 
									run("Select All");
									run("Plot Profile");
									Plot.setLimits(0,width,0,255);
									
							//Mean Gray Value
									selectWindow(chosen_img);
									setThreshold(10, 255);
									run("Analyze Particles...", "size=50-Infinity show=Outlines display clear");
									if(striptag==true){
										for(k=1;k<=stripsnumber;k++){ 
											setResult("Strip Tag", k-1, tags[k-1]);
										}	
									}
									
							//Save Data
									if (autosave==true) {
										
										selectWindow(chosen_img);
										saveAs("Tiff", ImagePath+ImageName+"_"+FolderName+"/"+ImageName+"_processed_"+chosen_img+".tif");
										
										selectWindow("Plot of "+chosen_img);
										saveAs("Jpeg", ImagePath+ImageName+"_"+FolderName+"/2D_profile_plot_"+chosen_img+".jpg");
										
										selectWindow("Results");
										saveAs("Results", ImagePath+ImageName+"_"+FolderName+"/extracted_data_"+chosen_img+".csv");
										run("Close"); 
									}
				}
		}
								

//CLOSE ALL WINDOWS AND FINISH 
	
		if (autosave==true) {
			run("Close All");
		}else{
			setBatchMode("exit and display");
		}
		waitForUser("ANALYSIS COMPLETED! (Macro by Sara De Bragança, 19 AUG 2018)"); 
