// =============================================================================
// Lab-Frame Kymograph
// ImageJ/Fiji Macro
//
// Purpose:
// Generates a lab-frame kymograph from a maximally projected YFP time-lapse
// image using Fiji's LOI Interpolator.
//
// Lines of interest (LOIs) tracing the tissue are manually drawn at selected
// time points and added sequentially to the ROI Manager. LOIs are defined while
// keeping the most recently formed somite boundary at a fixed reference
// position. Fiji's LOI Interpolator interpolates between successive LOIs to
// generate a continuous kymograph.
//
// For the analyses reported here, the LOI line width was set to 30 pixels
// (37.5 µm), and fluorescence intensity was averaged across the line width.
//
// As the tissue grows and new somites form, the LOI length and reference
// position are updated accordingly. 
//
// Input requirements:
//   1. Open the maximally projected YFP time-lapse image.
//   2. Set the LOI line width to 30 pixels (37.5 µm).
//   3. Draw LOIs along the tissue at selected time points, keeping the most
//      recently formed somite boundary at the reference position, and add them
//      sequentially to the ROI Manager.
//   4. Ensure that each LOI retains its corresponding slice/time-point
//      information for interpolation.
//   5. The input image title must end with ".tif".
//
// Output:
//   A lab-frame kymograph named:
//       "LF_Kymograph of <original image name>.tif"
//
// =============================================================================

// -----------------------------------------------------------------------------
// Parse information from the input image title.
// -----------------------------------------------------------------------------
title = getTitle;
file = substring(title, 0, indexOf(title, ".tif"));

// -----------------------------------------------------------------------------
// Generate the kymograph using Fiji's LOI Interpolator.
//
// Fluorescence intensity is averaged across the full line width.
// For the published analysis, the LOI width was set to 30 pixels (37.5 µm).
// -----------------------------------------------------------------------------
roiManager("Select", 0);
setTool("polyline");

// Read the line coordinates and width from ROI #0.
getLine(x1, y1, x2, y2, lineWidth);

// Apply the ROI line width and generate the kymograph.
run("Line Width...", "line=" + lineWidth);
run("LOI Interpolator", "average_over_line_width show_kymograph");


// -----------------------------------------------------------------------------
// Measure the length and associated slice/time point of each ROI.
//
// These measurements are subsequently used to identify decreases in trajectory
// length between consecutive time points. Such decreases are used to calculate
// the horizontal displacement required to maintain a fixed laboratory-frame
// coordinate in the kymograph.
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
// Calculate the total horizontal displacement required for the lab-frame
// kymograph.
//
// When the ROI length decreases from one consecutive slice/time point to the
// next, the difference in length is converted from calibrated units to pixels.
// These decreases are summed in D.
//
// D is then added to the kymograph width so that subsequent horizontal shifts
// can be introduced without clipping the image.
// -----------------------------------------------------------------------------
D = 0;

for (i = 0; i < nResults; i++) {

    Length_i0 = getResult("Length", i-1);
    Slice_i0  = getResult("Slice", i-1);

    Length_i1 = getResult("Length", i);
    Slice_i1  = getResult("Slice", i);

    print(Slice_i0, Length_i0);
    print(Slice_i1, Length_i1);

    // Detect a decrease in trajectory length between consecutive slices.
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
// Expand the initial kymograph to accommodate the cumulative displacement.
// -----------------------------------------------------------------------------
selectWindow("Kymograph of " + title);

getDimensions(width, height, channels, slices, frames);

// Convert the final measured trajectory length to pixels.
PixelLength_in = getResult("Length", nResults-1) / pixelHeight;

print(getResult("Length", nResults-1));

// Increase the canvas width by the cumulative displacement D.
// The original kymograph remains anchored at the top-left corner.
run("Canvas Size...",
    "width=" + PixelLength_in + D +
    " height=" + height +
    " position=Top-Left zero");


// -----------------------------------------------------------------------------
// Reconstruct the kymograph in the laboratory reference frame.
//
// For every decrease in trajectory length between consecutive time points,
// calculate the corresponding displacement M. The kymograph rows beginning at
// that time point are then shifted to the right by M pixels.
//
// Applying these shifts cumulatively preserves the spatial position of the
// tissue in the laboratory frame rather than allowing shortening of the
// trajectory to reset the spatial origin.
// -----------------------------------------------------------------------------
M = 0;

for (i = 0; i < nResults; i++) {

    Length_i0 = getResult("Length", i-1);
    Slice_i0  = getResult("Slice", i-1);

    Length_i1 = getResult("Length", i);
    Slice_i1  = getResult("Slice", i);

    // Process only consecutive slices in which the measured trajectory becomes
    // shorter.
    if ((Slice_i1 - Slice_i0 == 1) & (Length_i1 < Length_i0)) {

        // Amount of shortening, expressed in pixels.
        M = round((Length_i0 - Length_i1) / pixelHeight);

        getDimensions(width, height, channels, slices, frames);

        // Select all kymograph rows from the detected shortening event onward.
        makeRectangle(0, Slice_i1-1, width, height-Slice_i1+1);

        // Shift this portion of the kymograph horizontally by M pixels.
        run("Cut");
        makeRectangle(M, Slice_i1-1, width, height-Slice_i1+1);
        run("Paste");

        run("Select None");
    }
}


// -----------------------------------------------------------------------------
// Rename and display the final lab-frame kymograph.
// -----------------------------------------------------------------------------
rename("LF_Kymograph of " + file + ".tif");

run("Set... ", "zoom=75");
setLocation(8, 130);


// -----------------------------------------------------------------------------
// Clean up temporary windows and return to the original image.
// -----------------------------------------------------------------------------
close("Log");
close("Results");

selectWindow(title);

