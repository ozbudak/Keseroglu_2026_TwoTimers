// =============================================================================
// Lab-Frame and Posterior-Aligned Kymograph Analysis
// ImageJ/Fiji Macro
//
// Purpose:
// Generates posterior-aligned (PS) and laboratory-frame (LF) kymographs from
// a maximum-projected YFP time-lapse image using Fiji's LOI Interpolator.
//
// Lines of interest (LOIs) are manually drawn along the tissue at selected
// time points and added sequentially to the ROI Manager.
//
// At the start of the analysis, the line width is set to 30 pixels (37.5 µm).
// The macro then reads the line width stored in ROI #0 and applies this value
// when generating the kymographs. Fluorescence intensity is averaged across
// the full LOI width.
//
// The macro first generates a posterior-aligned kymograph and extracts an
// intensity profile at a fixed position relative to the posterior reference.
// It then generates a laboratory-frame kymograph using the LOIs stored in the
// ROI Manager.
//
// Output:
//   PS_Kymograph of <input>.tif   Posterior-aligned kymograph
//   LF_PS_<input>.zip             ROI set used for the analysis
//   PS_<input>.csv                Intensity profile from the PS kymograph
//   LF_Kymograph of <input>.tif   Laboratory-frame kymograph
//
// =============================================================================


// -----------------------------------------------------------------------------
// Read the input image name, create the output directory, and define analysis
// parameters.
// -----------------------------------------------------------------------------

input = getInfo("image.Directory");
title = getTitle;
file = substring(title, 0, indexOf(title, ".tif"));
output = input + "Output\\";
File.makeDirectory(output);

deltaposit = 20;        // Distance (pixels) of the intensity-profile line from
                         // the posterior reference position.
AnalysisLineWidth = 10; // Width (pixels) of the intensity-profile line.


// =============================================================================
// PART 1 — POSTERIOR-ALIGNED (PS) KYMOGRAPH
// =============================================================================
//
// Set the LOI width to 30 pixels and verify that the ROI Manager is available.
// The LOIs stored in the ROI Manager define the tissue trajectory at the
// selected time points.
// -----------------------------------------------------------------------------

setTool(5);run("Line Width...", "line=30");
if (!isOpen("ROI Manager")) {
    showMessage("ROI Manager Required", 
        "Please add the LOIs to the ROI Manager before running this macro.");
    exit();
}

nn = roiManager("count");
roiManager("Select", nn-1);
getDimensions(widthn, heightn, channelsn, slicesn, framesn);

roiManager("Select", 0);
setTool("polyline");

// Read the line coordinates and stored line width from ROI #0.
getLine(x1, y1, x2, y2, lineWidth);

// Apply the LOI width stored in ROI #0 and generate the posterior-aligned
// kymograph. Fluorescence intensity is averaged across the full LOI width.
run("Line Width...", "line=" + lineWidth);
run("LOI Interpolator", "rois_are_flipped average_over_line_width show_kymograph");


// -----------------------------------------------------------------------------
// Define the intensity-profile line on the posterior-aligned kymograph.
//
// The vertical profile line is positioned at a fixed distance (deltaposit)
// from the posterior reference and spans all time points. Its width is defined
// by AnalysisLineWidth.
// -----------------------------------------------------------------------------

makeLine(deltaposit, 0, deltaposit, framesn-1, AnalysisLineWidth);


// -----------------------------------------------------------------------------
// Save the posterior-aligned kymograph and the ROI set used for the analysis.
// -----------------------------------------------------------------------------

saveAs("Tiff", output + "PS_Kymograph of " + file + ".tif");
roiManager("Save", output + "LF_PS_" + file + ".zip");


// -----------------------------------------------------------------------------
// Extract and save the intensity profile from the posterior-aligned kymograph.
// -----------------------------------------------------------------------------

run("Plot Profile");
Plot.showValues();

selectWindow("Results");
String.copyResults();
saveAs("Results", output + "PS_" + file + ".csv");
close("Results");

close("PS_Kymograph of " + file + ".tif");
close("Plot of PS_Kymograph of " + file);


// =============================================================================
// PART 2 — LABORATORY-FRAME (LF) KYMOGRAPH
// =============================================================================
//
// Return to the original time-lapse image and generate a laboratory-frame
// kymograph using the LOIs stored in the ROI Manager.
// -----------------------------------------------------------------------------

selectWindow(title);

// Read the line coordinates and stored line width from ROI #0.
getLine(x1, y1, x2, y2, lineWidth);

// Apply the stored LOI width and generate the laboratory-frame kymograph.
// Fluorescence intensity is averaged across the full LOI width.
run("Line Width...", "line=" + lineWidth);
run("LOI Interpolator", "average_over_line_width show_kymograph");


// -----------------------------------------------------------------------------
// Measure the length and corresponding slice/time point of every LOI.
// -----------------------------------------------------------------------------

selectWindow(title);
run("Clear Results");
print("\\Clear");

nn = roiManager("count");

for (i = 0; i < nn; i++) {

    roiManager("Select", i);

    getDimensions(width, height, channels, slices, frames);
    getPixelSize(unit, pixelWidth, pixelHeight);

    run("Measure");
    updateResults();
}


// -----------------------------------------------------------------------------
// Calculate the total horizontal displacement required for laboratory-frame
// reconstruction.
//
// For each decrease in LOI length between consecutive time points, convert the
// change in calibrated length to pixels and add it to the cumulative
// displacement D.
// -----------------------------------------------------------------------------

D = 0;

for (i = 0; i < nResults; i++) {

    Length_i0 = getResult("Length", i-1);
    Slice_i0  = getResult("Slice", i-1);

    Length_i1 = getResult("Length", i);
    Slice_i1  = getResult("Slice", i);

    print(Slice_i0, Length_i0);
    print(Slice_i1, Length_i1);

    // Detect a decrease in LOI length between consecutive time points.
    if ((Slice_i1 - Slice_i0 == 1) & (Length_i1 < Length_i0)) {

        // Convert the decrease in calibrated LOI length to pixels and add it
        // to the cumulative displacement.
        D += round((Length_i0 - Length_i1) / pixelHeight);

        print(Slice_i1, D);
    }
}

print(D);

run("Select None");


// -----------------------------------------------------------------------------
// Expand the laboratory-frame kymograph canvas to accommodate the total
// horizontal displacement.
// -----------------------------------------------------------------------------

selectWindow("Kymograph of " + title);

getDimensions(width, height, channels, slices, frames);

// Convert the final measured LOI length from calibrated units to pixels.
PixelLength_in = getResult("Length", nResults-1) / pixelHeight;

print(getResult("Length", nResults-1));

// Set the canvas width to the final LOI length plus the cumulative displacement
// while keeping the kymograph anchored at the top-left corner.
run("Canvas Size...",
    "width=" + PixelLength_in + D +
    " height=" + height +
    " position=Top-Left zero");


// -----------------------------------------------------------------------------
// Reconstruct the kymograph in the laboratory reference frame.
//
// At each time point where the LOI becomes shorter, calculate the corresponding
// displacement M. The kymograph rows from that time point onward are shifted
// horizontally by M pixels.
// -----------------------------------------------------------------------------

M = 0;

for (i = 0; i < nResults; i++) {

    Length_i0 = getResult("Length", i-1);
    Slice_i0  = getResult("Slice", i-1);

    Length_i1 = getResult("Length", i);
    Slice_i1  = getResult("Slice", i);

    // Process consecutive time points where the LOI becomes shorter.
    if ((Slice_i1 - Slice_i0 == 1) & (Length_i1 < Length_i0)) {

        // Convert the decrease in LOI length to pixels.
        M = round((Length_i0 - Length_i1) / pixelHeight);

        getDimensions(width, height, channels, slices, frames);

        // Select all kymograph rows from the shortening event onward.
        makeRectangle(0, Slice_i1-1, width, height-Slice_i1+1);

        // Shift the selected rows horizontally by M pixels.
        run("Cut");
        makeRectangle(M, Slice_i1-1, width, height-Slice_i1+1);
        run("Paste");

        run("Select None");
    }
}


// -----------------------------------------------------------------------------
// Rename and save the laboratory-frame kymograph, then display it at 100% zoom.
// -----------------------------------------------------------------------------

rename("LF_Kymograph of " + file + ".tif");
saveAs("Tiff", output + "LF_Kymograph of " + file + ".tif");

run("Set... ", "zoom=100");
setLocation(8, 130);


// -----------------------------------------------------------------------------
// Restore the line width and close temporary analysis windows.
// -----------------------------------------------------------------------------

setTool(5);run("Line Width...", "line=1");
close("Log");
close("Results");

close(title);
close("ROI Manager");
