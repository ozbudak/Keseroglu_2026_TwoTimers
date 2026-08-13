# Zebrafish Kymograph Analysis

ImageJ/Fiji macros for generating and spatially aligning kymographs used
to analyze tissue dynamics during zebrafish somitogenesis.

## Files

### `Lab_Frame_and_Posterior_Aligned_Kymograph.ijm`

Generates laboratory-frame (LF) and posterior-aligned (PS) kymographs
from maximum-projected YFP time-lapse images using Fiji's LOI
Interpolator.

Lines of interest (LOIs) are manually drawn along the tissue at selected
time points and added sequentially to the ROI Manager. The most recently
formed somite boundary is used as the posterior reference position. The
LOI Interpolator interpolates between successive LOIs to generate
continuous kymographs.

For the analyses described in the associated study, the LOI width was
set to 30 pixels (37.5 µm), and fluorescence intensity was averaged
across the line width.

The macro first generates a posterior-aligned (PS) kymograph and
extracts an intensity profile at a fixed position relative to the
posterior reference. It then generates a laboratory-frame (LF) kymograph
by accounting for changes in LOI length over time.

### `Anterior_and_Determination_Front_Aligned_Kymograph.ijm`

Generates spatially aligned kymographs using either the anterior
boundary (AN) or the determination front (DF) as the anatomical
reference.

The desired anatomical reference trajectory is manually defined on the
input kymograph. For each image row, the macro determines the
x-coordinate of this trajectory and horizontally shifts the row so that
the selected anatomical reference remains at a fixed spatial position
throughout the kymograph.

The `Position` parameter specifies the alignment mode:

-   `AN` --- anterior-aligned
-   `DF` --- determination-front-aligned

The `deltaposit` parameter specifies the horizontal offset of the
intensity-profile line relative to the aligned anatomical reference:

-   `AN` --- 20 pixels
-   `DF` --- 0 pixels

For the analyses described in the associated study, the
intensity-profile line width (`AnalysisLineWidth`) was set to 10 pixels.

## Requirements

-   Fiji/ImageJ
-   LOI Interpolator
-   ROI Manager

No non-standard hardware is required.

## Usage

### Laboratory-frame and posterior-aligned kymographs

1.  Open the maximum-projected YFP time-lapse image in Fiji.
2.  Set the LOI width to 30 pixels (37.5 µm).
3.  Draw LOIs along the tissue at selected time points.
4.  Add the LOIs sequentially to the ROI Manager while keeping the most
    recently formed somite boundary at the laboratory reference
    position.
5.  Ensure that each LOI retains its corresponding slice/time-point
    information.
6.  Run `Lab_Frame_and_Posterior_Aligned_Kymograph.ijm`.

The macro generates:

-   a posterior-aligned (PS) kymograph;
-   an intensity-profile CSV file from the PS-aligned kymograph;
-   the ROI set used for the analysis; and
-   a laboratory-frame (LF) kymograph.

### Anterior- and determination-front-aligned kymographs

1.  Open the kymograph to be aligned.
2.  Draw the desired anatomical reference trajectory (AN or DF) along
    the kymograph.
3.  Ensure that the reference trajectory spans the vertical extent of
    the kymograph.
4.  Set `Position` and `deltaposit` in
    `Anterior_and_Determination_Front_Aligned_Kymograph.ijm` as follows:
    -   AN alignment: `Position = "AN"` and `deltaposit = 20`
    -   DF alignment: `Position = "DF"` and `deltaposit = 0`
5.  Run `Anterior_and_Determination_Front_Aligned_Kymograph.ijm`.

The macro generates the corresponding AN- or DF-aligned kymograph and an
intensity-profile CSV file.

## Demo Dataset

An example maximum-projected YFP time-lapse `example_timelapse.tif`
image and the associated ROI files are included in this repository and
can be used to test the macros.

## Citation

If you use these macros, please cite the associated publication.

Publication details and DOI can be added here after publication.

## License

This code is released under the MIT License. See the `LICENSE` file for
details.

