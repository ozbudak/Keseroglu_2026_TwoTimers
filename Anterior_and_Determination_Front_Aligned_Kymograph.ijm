// =============================================================================
// Anterior- and Determination-Front-Aligned Kymograph Analysis
// ImageJ/Fiji Macro
//
// Purpose:
// Generates either an anterior-aligned (AN) or determination-front-aligned
// (DF) kymograph from an input kymograph.
//
// The user selects the alignment type and intensity-profile line width at the
// start of the macro. The default line width is set to 10 pixels, as used in
// the analyses reported in the associated study.
//
// A reference trajectory is then manually drawn on the input kymograph and
// used to align each image row to the selected anatomical reference.
//
// The macro generates the aligned kymograph and extracts a vertical intensity
// profile at a fixed position relative to the aligned reference.
//
// Output:
//   <Position>_<kymograph>.roi    Reference trajectory
//   <Position>_<kymograph>.tif    Aligned kymograph
//   <Position>_<kymograph>.csv    Intensity profile
//
// =============================================================================


// =============================================================================
// SELECT ALIGNMENT TYPE AND ANALYSIS WIDTH
// =============================================================================

Dialog.create("Kymograph Type");

Dialog.addChoice("Select kymograph type:", 
    newArray("Anterior-aligned", "Determination-front-aligned"), 
    "Anterior-aligned");

Dialog.addNumber("Analyze width (pixels):", 10);

Dialog.show();

type = Dialog.getChoice();
AnalysisLineWidth = Dialog.getNumber();

// Define the output prefix according to the selected alignment type.
if (type == "Anterior-aligned") {
    Position = "AN";
} else if (type == "Determination-front-aligned") {
    Position = "DF";
}


// =============================================================================
// PART 1 — DEFINE THE REFERENCE TRAJECTORY
// =============================================================================
//
// Set the position of the intensity-profile line relative to the aligned
// anatomical reference. The profile is offset by 20 pixels for AN alignment
// and placed directly at the reference position for DF alignment.
// =============================================================================

if (Position == "AN") {
	deltaposit = 20;
} else if (Position == "DF") {
    deltaposit = 0;
} else {
	showMessage("Select Position: AN or DF");
}


// Read the input directory and kymograph title.
input = getInfo("image.Directory");
title = getTitle;

subtitle = substring(title,
                     indexOf(title, "Kymograph"),
                     indexOf(title, ".tif"));


// Set the line width to 1 pixel and allow the user to draw the anatomical
// reference trajectory on the input kymograph.
setTool(5);run("Line Width...", "line=1");
waitForUser("Add line", "Add line for " + type + " kymograpgh");


// Replace any existing ROI Manager and store the newly drawn reference
// trajectory as ROI #0.
if (isOpen("ROI Manager")) {
    selectWindow("ROI Manager");
    run("Close");
    roiManager("Add");
} else {
    roiManager("Add");
}


// Save the reference trajectory.
roiManager("Save", input + Position + "_" + subtitle + ".roi");

getDimensions(width, height, channels, slices, frames);


// =============================================================================
// PART 2 — CREATE THE OUTPUT CANVAS
// =============================================================================
//
// Duplicate the input kymograph and expand the canvas horizontally to provide
// sufficient space for translation of individual image rows.
// =============================================================================

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
// PART 3 — INTERPOLATE THE REFERENCE TRAJECTORY
// =============================================================================
//
// Interpolate the manually drawn reference trajectory at approximately
// one-pixel intervals and obtain its x- and y-coordinates.
// =============================================================================

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
// Convert the interpolated trajectory into one representative horizontal
// reference position for each image row.
// =============================================================================

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
// Multiple interpolated coordinates can fall within the same image row.
// For these coordinates, calculate a single representative x-position.
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

    // Assign the representative x-position to coordinates belonging to the
    // preceding image row.
    if (upd == 1) {

        for (j = 1; j <= count1; j++) {
            x[i-j] = (fin1 + ini1) / 2;
        }
    }
}


// -----------------------------------------------------------------------------
// Retain one reference x-coordinate for each image row.
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
// Copy each image row from the original kymograph and reposition it
// horizontally according to the reference trajectory. This aligns the
// selected anatomical reference to a fixed horizontal position.
// =============================================================================

for (i = 0; i < yy.length; i++) {

    if (yy[i] != "") {

        selectWindow(title);

        // Calculate the horizontal destination of the current image row.
        xtart = minx - xx[i] + width;

        // Copy the corresponding row from the original kymograph.
        makeRectangle(0, yy[i], width, 1);
        run("Copy");

        // Paste the row into the aligned kymograph.
        selectWindow("kymoshift");
        makeRectangle(xtart, yy[i], width, 1);
        run("Paste");

        // Clear image regions outside the repositioned row.
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
// PART 6 — ALIGN THE FIRST IMAGE ROW
// =============================================================================
//
// Determine the representative reference position for the first image row
// separately and place the row at the corresponding aligned position.
// =============================================================================

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
// PART 7 — ALIGN THE FINAL IMAGE ROW
// =============================================================================
//
// Determine the representative reference position for the final image row
// separately and place the row at the corresponding aligned position.
// =============================================================================

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

// Rename the aligned kymograph according to the selected anatomical reference.
rename(Position + "_" + subtitle);


// =============================================================================
// PART 8 — EXTRACT THE INTENSITY PROFILE
// =============================================================================
//
// Extract a vertical intensity profile from the aligned kymograph.
//
// For anterior alignment, the profile is positioned 20 pixels from the aligned
// anterior reference. For determination-front alignment, the profile is
// positioned directly at the aligned determination front.
//
// The width of the profile line is defined by AnalysisLineWidth.
// =============================================================================

selectWindow(Position + "_" + subtitle);

// Determine the fixed horizontal position of the aligned reference.
posit = width + minx;

setLocation(-8, heightt+50, width, heightt+60);

run("Set... ",
    "zoom=100 x=" + posit + deltaposit + " y=0");

setLocation(-8, heightt+50, width, heightt+60);

run("Set... ",
    "zoom=100 x=" + posit + deltaposit + " y=0");


// Draw the vertical line used for intensity-profile extraction.
makeLine(posit + deltaposit,
         yyy,
         posit + deltaposit,
         heightt-1,
         AnalysisLineWidth);


// Save the aligned kymograph.
selectWindow(Position + "_" + subtitle);
saveAs("Tiff", input + "/" + Position + "_" + subtitle + ".tif");


// Generate the intensity profile.
run("Plot Profile");
Plot.showValues();


// Save the intensity-profile values.
selectWindow("Results");
String.copyResults();

saveAs("Results",
       input + "/" + Position + "_" + subtitle + ".csv");


// Close analysis windows.
close("Results");
close("Plot of " + Position + "_" + subtitle);
close(Position + "_" + subtitle + ".tif");
close("ROI Manager");
