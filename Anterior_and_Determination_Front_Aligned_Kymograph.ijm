// =============================================================================
// Anterior- and Determination-Front-Aligned Kymograph
// ImageJ/Fiji Macro
//
// Purpose:
// Generates spatially aligned kymographs using either the anterior (AN)
// boundary or the determination front (DF) as the anatomical reference.
//
// The reference trajectory is manually defined on the input kymograph and
// stored as ROI #0 in the ROI Manager. For each image row (time point), the
// macro determines the x-coordinate of the reference trajectory and
// horizontally shifts the row so that the selected anatomical reference
// remains at a fixed spatial position throughout the kymograph.
//
// The macro can be used for two alignment modes:
//
//       "AN" = anterior-aligned
//       "DF" = determination-front-aligned
//
// Input requirements:
//   1. Open the kymograph to be aligned.
//   2. Draw the desired anatomical reference trajectory (AN or DF) along the
//      kymograph.
//   3. The reference trajectory must span the vertical extent of the
//      kymograph and be stored as ROI #0 in the ROI Manager.
//   4. Set `Position` and `deltaposit` according to the desired alignment.
//   5. The input image title must contain "Kymograph" and end with ".tif".
//
// Alignment settings:
//       AN: Position = "AN"; deltaposit = 20;
//       DF: Position = "DF"; deltaposit = 0;
//
// `deltaposit` specifies the horizontal offset, in pixels, of the
// intensity-profile line relative to the aligned anatomical reference.
//
// For the analyses reported in the associated study, the intensity-profile
// line width was 10 pixels.
//
// Output:
//   <Position>_<kymograph>.tif    Spatially aligned kymograph
//   <Position>_<kymograph>.csv    Intensity profile extracted from the
//                                 aligned kymograph
//
// Note:
//   The output canvas is expanded to three times the width of the input
//   kymograph to provide sufficient space for horizontal translation of
//   individual image rows without clipping.
//
// =============================================================================


// ------------------------- USER-DEFINED SETTINGS -----------------------------

Position = "DF";          // "AN" = anterior; "DF" = determination front
deltaposit = 0;          // AN = 20 pixels; DF = 0 pixels
AnalyseLineWidth = 10;    // Width of the intensity-profile line (pixels)


// =============================================================================
// PART 1 — LOAD THE INPUT KYMOGRAPH AND REFERENCE TRAJECTORY
// =============================================================================

// Read information from the currently active kymograph.
input = getInfo("image.Directory");
title = getTitle;

subtitle = substring(title,
                     indexOf(title, "Kymograph"),
                     indexOf(title, ".tif"));

// Store the manually defined anatomical reference trajectory as ROI #0.
if (isOpen("ROI Manager")) {
    selectWindow("ROI Manager");
    run("Close");
    roiManager("Add");
} else {
    roiManager("Add");
}

getDimensions(width, height, channels, slices, frames);


// =============================================================================
// PART 2 — CREATE AN EXPANDED OUTPUT CANVAS
// =============================================================================
//
// Duplicate the input kymograph and expand its width threefold. The enlarged
// canvas provides sufficient space to translate individual image rows
// horizontally while preserving the complete image content.
// -----------------------------------------------------------------------------

selectWindow(title);
setLocation(-8, 0);

run("Duplicate...", "title=kymoshift");

str = newArray("width=", toString(width*3),
               " height=", toString(height),
               " position=Center zero");

strshift = String.join(str, "");
run("Canvas Size...", strshift);

setLocation(0, 483);


// =============================================================================
// PART 3 — INTERPOLATE THE ANATOMICAL REFERENCE TRAJECTORY
// =============================================================================
//
// Interpolate ROI #0 at approximately one-pixel intervals to obtain the
// position of the anatomical reference along the vertical extent of the
// kymograph.
// -----------------------------------------------------------------------------

roiManager("Select", 0);
roiManager("Set Line Width", 1);

run("Interpolate", "interval=1 smooth adjust");

Roi.getBounds(xxx, yyy, widthh, heightt);
Roi.getCoordinates(arrax, array);

Array.getStatistics(arrax, minx, maxx, meanx, stdDevx);
Array.getStatistics(array, miny, maxy, meany, stdDevy);

selectWindow(title);

minx = round(minx);


// =============================================================================
// PART 4 — DETERMINE THE REFERENCE POSITION FOR EACH IMAGE ROW
// =============================================================================
//
// Copy the interpolated trajectory coordinates into working arrays.
// x-coordinates are initially retained at full precision, whereas
// y-coordinates are rounded to the nearest image row.
// -----------------------------------------------------------------------------

a = newArray(arrax.length);

for (i = 0; i < arrax.length; i++) {
    a[i] = arrax[i];
}

b = newArray(array.length);

for (i = 0; i < array.length; i++) {
    b[i] = round(array[i]);
}

Array.getStatistics(a, minax, maxax, meanax, stdDevax);
Array.getStatistics(b, minby, maxby, meanby, stdDevby);


// -----------------------------------------------------------------------------
// Interpolation can produce multiple trajectory coordinates that map to the
// same image row after rounding. For each such group, use the midpoint between
// the first and last x-coordinate as the representative reference position.
// -----------------------------------------------------------------------------

x = newArray(a.length);

count = 0;
ini = 0;
fin = 0;

for (i = 1; i < a.length-1; i++) {

    if (b[i] - b[i-1] == 0) {

        count = count + 1;
        fin = a[i];
        upd = 0;

    } else {

        count1 = count;
        count = 0;

        x[i] = a[i];

        ini1 = ini;
        ini = a[i];

        fin1 = fin;
        fin = a[i];

        upd = 1;
    }

    // Assign the representative midpoint to all trajectory coordinates
    // belonging to the preceding image row.
    if (upd == 1) {

        for (j = 1; j <= count1; j++) {
            x[i-j] = (fin1 + ini1) / 2;
        }
    }
}


// -----------------------------------------------------------------------------
// Retain one representative x-coordinate for each unique image row.
// -----------------------------------------------------------------------------

selectWindow(title);

xx = newArray(x.length);
yy = newArray(b.length);

for (i = 0; i < x.length; i++) {
    x[i] = round(x[i]);
}

for (i = 0; i < b.length-1; i++) {

    if (b[i+1] - b[i] == 0) {

        xx[i] = "";
        yy[i] = "";

    } else {

        xx[i] = x[i];
        yy[i] = b[i];
    }
}


// =============================================================================
// PART 5 — ALIGN THE KYMOGRAPH
// =============================================================================
//
// Shift each image row horizontally according to the x-coordinate of the
// anatomical reference trajectory. This places the selected reference
// (AN or DF) at the same x-position throughout the output kymograph.
// -----------------------------------------------------------------------------

for (i = 0; i < yy.length; i++) {

    if (yy[i] != "") {

        selectWindow(title);

        // Calculate the horizontal position at which the current row should
        // be placed in the expanded output canvas.
        xtart = minx - xx[i] + width;

        // Copy one row from the original kymograph.
        makeRectangle(0, yy[i], width, 1);
        run("Copy");

        // Paste the row at its reference-dependent horizontal position.
        selectWindow("kymoshift");
        makeRectangle(xtart, yy[i], width, 1);
        run("Paste");

        // Clear image regions outside the translated row.
        if (xtart < width) {

            makeRectangle(xtart + width, yy[i], width, 1);
            run("Clear");
        }

        if (xtart >= width) {

            makeRectangle(0, yy[i], xtart, 1);
            run("Clear");
        }
    }
}


// =============================================================================
// PART 6 — HANDLE THE FIRST IMAGE ROW
// =============================================================================
//
// The first trajectory row is treated separately because its representative
// x-coordinate cannot be obtained from the preceding-row comparison used
// above.
// -----------------------------------------------------------------------------

count = 0;

for (i = 0; i < a.length-1; i++) {

    if (b[i+1] - b[i] == 0) {

        count = count + 1;
        ini1 = a[0];
        upd = 0;

    } else {

        fin1 = a[i];
        upd = 1;

        xx[count] = (fin1 + ini1) / 2;
    }

    if (upd == 1) {
        i = a.length - 1;
    }
}

selectWindow(title);

xtart = minx - xx[count] + width;

makeRectangle(0, b[0], width, 1);
run("Copy");

selectWindow("kymoshift");

makeRectangle(xtart, b[0], width, 1);
run("Paste");

if (xtart < width) {

    makeRectangle(xtart + width, b[0], width, 1);
    run("Clear");
}

if (xtart >= width) {

    makeRectangle(0, b[0], xtart, 1);
    run("Clear");
}


// =============================================================================
// PART 7 — HANDLE THE FINAL IMAGE ROW
// =============================================================================
//
// The final trajectory row is also treated separately because there is no
// subsequent row available for the coordinate comparison.
// -----------------------------------------------------------------------------

count = 0;

for (i = a.length-1; i > 0; i--) {

    if (b[i] - b[i-1] == 0) {

        count = count + 1;
        ini1 = a[a.length-1];
        upd = 0;

    } else {

        fin1 = a[i-1];
        upd = 1;

        xx[a.length-1-count] = (fin1 + ini1) / 2;
    }

    if (upd == 1) {
        i = 0;
    }
}

selectWindow(title);

xtart = minx - xx[a.length-1-count] + width;

makeRectangle(0, b[b.length-1], width, 1);
run("Copy");

selectWindow("kymoshift");

makeRectangle(xtart, b[b.length-1], width, 1);
run("Paste");

if (xtart < width) {

    makeRectangle(xtart + width, b[b.length-1], width, 1);
    run("Clear");
}

if (xtart >= width) {

    makeRectangle(0, b[b.length-1], xtart, 1);
    run("Clear");
}


selectWindow(title);
run("Select None");

run("Set... ", "zoom=100 x=300 y=0");
setLocation(-8, 0);

roiManager("Select", 0);

selectWindow("kymoshift");

// Rename according to the selected anatomical reference.
rename(Position + "_" + subtitle);


// =============================================================================
// PART 8 — EXTRACT THE INTENSITY PROFILE
// =============================================================================
//
// Extract a vertical intensity profile from the aligned kymograph.
//
// For AN alignment, the profile is positioned 20 pixels from the aligned
// anterior reference (deltaposit = 20).
//
// For DF alignment, the profile passes directly through the aligned
// determination front (deltaposit = 0).
//
// The kymograph is saved as a TIF file.
//
// The resulting intensity values are saved as a CSV file.
// -----------------------------------------------------------------------------

selectWindow(Position + "_" + subtitle + ".tif");

posit = width + minx;

setLocation(-8, heightt, width, heightt);

run("Set... ",
    "zoom=100 x=" + posit + deltaposit + " y=0");

setLocation(-8, heightt, width, heightt);

run("Set... ",
    "zoom=100 x=" + posit + deltaposit + " y=0");

// Draw the vertical line used for intensity-profile extraction.
makeLine(posit + deltaposit,
         yyy,
         posit + deltaposit,
         heightt,
         AnalyseLineWidth);

// Save the aligned kymograph.
selectWindow(Position + "_" + subtitle + ".tif");
saveAs("Tiff", input + "/" + Position + "_" + subtitle + ".tif");

// Generate the intensity profile.
run("Plot Profile");
Plot.showValues();

// Save the profile values.
selectWindow("Results");
String.copyResults();

saveAs("Results",
       input + "/" + Position + "_" + subtitle + ".csv");

close("Results");
close("Plot of " + Position + "_" + subtitle);