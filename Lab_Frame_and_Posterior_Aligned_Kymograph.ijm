// =============================================================================
// Lab-Frame and Posterior-Aligned Kymograph Analysis
// ImageJ/Fiji Macro
//
// Purpose:
// Generates posterior-aligned (PS) and laboratory-frame (LF) kymographs from
// a maximum-projected YFP time-lapse image using Fiji's LOI Interpolator.
//
// Lines of interest (LOIs) are manually drawn along the tissue at selected
// time points and added sequentially to the ROI Manager. The most recently
// formed somite boundary is used as the posterior (PS) reference position.
// Fiji's LOI Interpolator interpolates between successive LOIs to generate
// continuous kymographs.
//
// For the analyses reported in the associated study, the LOI width was set to
// 30 pixels (37.5 µm), and fluorescence intensity was averaged across the
// line width.
//
// The macro first generates a posterior-aligned kymograph and extracts an
// intensity profile at a fixed position relative to the posterior reference.
// It then generates a second kymograph and reconstructs it in the laboratory
// reference frame by accounting for changes in LOI length over time.
//
// Input requirements:
//   1. Open the maximum-projected YFP time-lapse image.
//   2. Draw LOIs along the tissue at selected time points and add them
//      sequentially to the ROI Manager.
//   3. Keep the most recently formed somite boundary at the posterior
//      reference position when defining the LOIs.
//   4. Ensure that each LOI retains its corresponding slice/time-point
//      information for interpolation.
//   5. For the analyses reported here, use an LOI width of 30 pixels
//      (37.5 µm).
//   6. The input image title must end with ".tif".
//
// Output:
//   PS_Kymograph of <input>.tif   Posterior-aligned kymograph
//   PS_<input>.zip                ROI set used for PS alignment
//   PS_<input>.csv                Intensity profile from the PS kymograph
//   LF_Kymograph of <input>.tif   Laboratory-frame kymograph
//
// =============================================================================


// -----------------------------------------------------------------------------
// Read the input image name and define analysis parameters.
// -----------------------------------------------------------------------------
input = getInfo("image.Directory");
title = getTitle;
file = substring(title, 0, indexOf(title, ".tif"));

deltaposit = 20;       // Horizontal offset (pixels) of the intensity-profile
                       // line from the posterior (PS) reference position.
AnalyseLineWidth = 10; // Width (pixels) of the line used for profile extraction.


// =============================================================================
// PART 1 — POSTERIOR-ALIGNED (PS) KYMOGRAPH
// =============================================================================
//
// Generate a kymograph aligned to the posterior reference defined by the LOIs.
// The LOIs are flipped by the LOI Interpolator so that the posterior reference
// remains at a fixed spatial position in the resulting kymograph.
// -----------------------------------------------------------------------------

roiManager("Select", 0);
setTool("polyline");

// Read the line coordinates and width from ROI #0.
getLine(x1, y1, x2, y2, lineWidth);

// Apply the ROI line width and generate the posterior-aligned kymograph.
// Fluorescence intensity is averaged across the full LOI width.
run("Line Width...", "line=" + lineWidth);
run("LOI Interpolator", "rois_are_flipped average_over_line_width show_kymograph");


// -----------------------------------------------------------------------------
// Extract an intensity profile from the posterior-aligned kymograph.
//
// The profile is measured along a vertical line positioned 20 pixels from the
// posterior reference. For the analyses reported here, the profile line width
// was 10 pixels.
// -----------------------------------------------------------------------------

makeLine(deltaposit, 0, deltaposit, 480, AnalyseLineWidth);


// -----------------------------------------------------------------------------
// Save the posterior-aligned kymograph and the corresponding ROI set.
// -----------------------------------------------------------------------------

saveAs("Tiff", input + "PS_Kymograph of " + file + ".tif");
roiManager("Save", input + "/PS_" + file + ".zip");


// -----------------------------------------------------------------------------
// Generate and save the intensity profile from the posterior-aligned
// kymograph.
// -----------------------------------------------------------------------------

run("Plot Profile");
Plot.showValues();

selectWindow("Results");
String.copyResults();
saveAs("Results", input + "/PS_" + file + ".csv");
close("Results");

close("PS_Kymograph of " + file + ".tif");
close("Plot of PS_Kymograph of " + file);


// =============================================================================
// PART 2 — LABORATORY-FRAME (LF) KYMOGRAPH
// =============================================================================
//
// Return to the original time-lapse image and generate a second kymograph
// without posterior alignment. This kymograph is subsequently corrected for
// changes in LOI length to reconstruct tissue position in the laboratory
// reference frame.
// -----------------------------------------------------------------------------

selectWindow(title);

// Read the line coordinates and width from ROI #0.
getLine(x1, y1, x2, y2, lineWidth);

// Apply the ROI line width and generate the initial kymograph.
run("Line Width...", "line=" + lineWidth);
run("LOI Interpolator", "average_over_line_width show_kymograph");


// -----------------------------------------------------------------------------
// Measure the length and corresponding slice/time point of each LOI.
//
// These measurements are used to identify decreases in LOI length between
// consecutive time points. Such decreases correspond to changes in the
// spatial reference caused by formation of new somite boundaries and are
// subsequently used to reconstruct the laboratory-frame coordinates.
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
// When the LOI length decreases between consecutive slices/time points, the
// decrease is converted from calibrated distance to pixels and added to the
// cumulative displacement D.
//
// The kymograph canvas is subsequently expanded by D pixels to provide enough
// space for the laboratory-frame reconstruction without clipping.
// -----------------------------------------------------------------------------

D = 0;

for (i = 0; i < nResults; i++) {

    Length_i0 = getResult("Length", i-1);
    Slice_i0  = getResult("Slice", i-1);

    Length_i1 = getResult("Length", i);
    Slice_i1  = getResult("Slice", i);

    print(Slice_i0, Length_i0);
    print(Slice_i1, Length_i1);

    // Identify a decrease in LOI length between consecutive time points.
    if ((Slice_i1 - Slice_i0 == 1) & (Length_i1 < Length_i0)) {

        // Convert the decrease in calibrated length to pixels and add it to
        // the cumulative displacement.
        D += round((Length_i0 - Length_i1) / pixelHeight);

        print(Slice_i1, D);
    }
}

print(D);

run("Select None");


// -----------------------------------------------------------------------------
// Expand the initial kymograph to accommodate the cumulative horizontal
// displacement.
// -----------------------------------------------------------------------------

selectWindow("Kymograph of " + title);

getDimensions(width, height, channels, slices, frames);

// Convert the final measured LOI length from calibrated units to pixels.
PixelLength_in = getResult("Length", nResults-1) / pixelHeight;

print(getResult("Length", nResults-1));

// Increase the canvas width by the cumulative displacement D while keeping
// the original kymograph anchored at the top-left corner.
run("Canvas Size...",
    "width=" + PixelLength_in + D +
    " height=" + height +
    " position=Top-Left zero");


// -----------------------------------------------------------------------------
// Reconstruct the kymograph in the laboratory reference frame.
//
// For each decrease in LOI length between consecutive time points, calculate
// the corresponding horizontal displacement M. All kymograph rows from that
// time point onward are shifted to the right by M pixels.
//
// Applying these shifts cumulatively preserves tissue position in the
// laboratory reference frame despite changes in LOI length associated with
// successive somite formation.
// -----------------------------------------------------------------------------

M = 0;

for (i = 0; i < nResults; i++) {

    Length_i0 = getResult("Length", i-1);
    Slice_i0  = getResult("Slice", i-1);

    Length_i1 = getResult("Length", i);
    Slice_i1  = getResult("Slice", i);

    // Process consecutive time points in which the measured LOI becomes
    // shorter.
    if ((Slice_i1 - Slice_i0 == 1) & (Length_i1 < Length_i0)) {

        // Convert the decrease in LOI length to pixels.
        M = round((Length_i0 - Length_i1) / pixelHeight);

        getDimensions(width, height, channels, slices, frames);

        // Select all kymograph rows from the detected shortening event onward.
        makeRectangle(0, Slice_i1-1, width, height-Slice_i1+1);

        // Shift the selected portion horizontally by M pixels.
        run("Cut");
        makeRectangle(M, Slice_i1-1, width, height-Slice_i1+1);
        run("Paste");

        run("Select None");
    }
}


// -----------------------------------------------------------------------------
// Save and display the final laboratory-frame kymograph.
// -----------------------------------------------------------------------------

rename("LF_Kymograph of " + file + ".tif");
saveAs("Tiff", input + "LF_Kymograph of " + file + ".tif");

run("Set... ", "zoom=75");
setLocation(8, 130);


// -----------------------------------------------------------------------------
// Clean up temporary windows.
// -----------------------------------------------------------------------------

close("Log");
close("Results");

close(title);
close("ROI Manager");