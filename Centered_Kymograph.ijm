// =============================================================================
// Centered Kymograph
// ImageJ/Fiji Macro
//
// Purpose:
// Horizontally aligns each row of a kymograph to a user-defined anatomical
// reference trajectory. The reference trajectory must be stored as ROI #0 in
// the ROI Manager. For each y-position, the macro determines the corresponding
// x-coordinate of the trajectory and shifts that image row so that the
// reference trajectory is aligned to a common x-position.
//
// Input requirements:
//   1. Open the kymograph image to be processed.
//   2. Add the reference trajectory as ROI #0 in the ROI Manager.
//      The trajectory should span the vertical extent of the kymograph.
//   3. The image title must contain "Kymograph" and end with ".tif".
//
// Alignment options:
//   Position specifies the anatomical reference used for alignment and is also
//   used as a prefix in the output image name:
//
//       "PS" = posterior-aligned
//       "AN" = anterior-aligned
//       "DF" = determination-front-aligned
//
//   deltaposittt specifies the horizontal offset of the intensity-profile line
//   relative to the alignment reference. Use:
//
//       PS: deltaposittt = 20
//       AN: deltaposittt = 20
//       DF: deltaposittt = 0
//
// Adjustable parameters:
//   Position       Anatomical alignment reference ("PS", "AN", or "DF").
//   deltaposittt   Horizontal offset of the intensity-profile line (pixels).
//   LineWidth      Width of the line used for intensity-profile extraction.
//
// Output:
//   A centered kymograph on a horizontally expanded canvas. The output image
//   is named using the selected Position prefix followed by the original
//   kymograph identifier.
//
// Note:
//   The output canvas is three times the width of the original image to provide
//   sufficient space for horizontal translation without clipping.
// =============================================================================


// ------------------------- USER-DEFINED SETTINGS -----------------------------

Position = "PS";       // "PS" = posterior, "AN" = anterior, "DF" = determination front
deltaposittt = 20;     // PS/AN = 20 pixels; DF = 0 pixels
LineWidth = 10;        // Width of the intensity-profile line (pixels)


// Get information from the currently active kymograph.
title = getTitle;
setLocation(-8, 0);
subtitle = substring(title, indexOf(title, "Kymograph"), indexOf(title, ".tif"));
getDimensions(width, height, channels, slices, frames);


// -----------------------------------------------------------------------------
// Create an expanded copy of the kymograph.
// The larger canvas provides space for horizontal translation of individual
// image rows.
// -----------------------------------------------------------------------------
selectWindow(title);
run("Duplicate...", "title=kymoshift");

str = newArray("width=", toString(width*3),
               " height=", toString(height),
               " position=Center zero");
strshift = String.join(str, "");
run("Canvas Size...", strshift);
setLocation(0, 483);


// -----------------------------------------------------------------------------
// Read and interpolate the reference trajectory stored as ROI #0.
// Interpolation generates approximately one coordinate per pixel along the
// trajectory.
// -----------------------------------------------------------------------------
roiManager("Select", 0);
roiManager("Set Line Width", 1);
run("Interpolate", "interval=1 smooth adjust");

Roi.getBounds(xxx, yyy, widthhh, heighttt);
Roi.getCoordinates(arrax, array);

Array.getStatistics(arrax, minx, maxx, meanx, stdDevx);
Array.getStatistics(array, miny, maxy, meany, stdDevy);

selectWindow(title);

minx = round(minx);


// -----------------------------------------------------------------------------
// Copy the trajectory coordinates into working arrays.
// x-coordinates are retained initially at full precision; y-coordinates are
// rounded to image-row positions.
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
// Determine one representative x-coordinate for each image row.
//
// Interpolation may generate multiple trajectory coordinates with the same
// rounded y-value. For such horizontal groups, the midpoint between the first
// and last x-coordinate is used as the representative trajectory position.
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

    // Assign the same midpoint x-coordinate to all trajectory points
    // belonging to the preceding image row.
    if (upd == 1) {
        for (j = 1; j <= count1; j++) {
            x[i-j] = (fin1 + ini1) / 2;
        }
    }
}


// -----------------------------------------------------------------------------
// Keep only one x-coordinate for each unique y-position.
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


// -----------------------------------------------------------------------------
// Shift each image row horizontally.
//
// The horizontal offset is calculated from the trajectory x-coordinate so
// that the reference trajectory is placed at a common position in the
// expanded output image.
// -----------------------------------------------------------------------------
for (i = 0; i < yy.length; i++) {

    if (yy[i] != "") {

        selectWindow(title);

        xtart = minx - xx[i] + width;

        // Copy one row from the original kymograph.
        makeRectangle(0, yy[i], width, 1);
        run("Copy");

        // Paste the row at its trajectory-dependent horizontal position.
        selectWindow("kymoshift");
        makeRectangle(xtart, yy[i], width, 1);
        run("Paste");

        // Remove portions outside the intended shifted-image region.
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


// -----------------------------------------------------------------------------
// Handle the first trajectory row separately.
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


// -----------------------------------------------------------------------------
// Handle the final trajectory row separately.
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


// -----------------------------------------------------------------------------
// Final display and output naming.
// -----------------------------------------------------------------------------
selectWindow(title);
run("Select None");
run("Set... ", "zoom=100 x=300 y=0");
setLocation(-8, 0);

roiManager("Select", 0);

selectWindow("kymoshift");
rename(Position + "*" + subtitle);


// -----------------------------------------------------------------------------
// Optional intensity-profile extraction from the centered kymograph.
// These commands can be enabled when a vertical profile through the centered
// trajectory is required.
// -----------------------------------------------------------------------------

 posit = width + minx;
 setLocation(-8, heighttt, width, heighttt);
 run("Set... ", "zoom=100 x=" + posit + deltaposittt + " y=0");
 setLocation(-8, heighttt, width, heighttt);
 run("Set... ", "zoom=100 x=" + posit + deltaposittt + " y=0");
 makeLine(posit + deltaposittt,
          yyy,
          posit + deltaposittt,
          heighttt,
          LineWidth);
 run("Plot Profile");
 selectWindow("Plot of " + Position + "*" + subtitle);
 setLocation(1200, 300);

