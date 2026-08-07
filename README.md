# Zebrafish Kymograph Analysis

ImageJ/Fiji macros for generating and aligning kymographs used to analyze tissue dynamics during zebrafish somitogenesis.

## Files

### `Lab_Frame_Kymograph.ijm`

Generates lab-frame kymographs from maximum-projected YFP time-lapse images using Fiji's LOI Interpolator.

Lines of interest (LOIs) are manually drawn along the tissue at selected time points and added sequentially to the ROI Manager while keeping the most recently formed somite boundary at a fixed reference position. The LOI Interpolator interpolates between successive LOIs to generate a continuous kymograph.

For the analyses described in the associated study, the LOI width was set to 30 pixels (37.5 µm), and fluorescence intensity was averaged across the line width.

The macro uses changes in the measured lengths of sequential LOIs to reconstruct the kymograph in the laboratory reference frame.

### `Centered_Kymograph.ijm`

Horizontally aligns the rows of a kymograph to a user-defined anatomical reference trajectory.

The `Position` parameter specifies the anatomical reference used for alignment:

- `PS` — posterior-aligned
- `AN` — anterior-aligned
- `DF` — determination-front-aligned

## Requirements

- Fiji/ImageJ
- LOI Interpolator
- ROI Manager

## Usage

### Lab-frame kymograph

1. Open the maximum-projected YFP time-lapse image in Fiji.
2. Draw LOIs along the tissue at selected time points.
3. Add the LOIs sequentially to the ROI Manager while keeping the most recently formed somite boundary at the reference position.
4. Set the LOI width to 30 pixels (37.5 µm).
5. Run `Lab_Frame_Kymograph.ijm`.

### Centered kymograph

1. Open the kymograph to be aligned.
2. Add the desired anatomical reference trajectory as ROI #0 in the ROI Manager.
3. Select the appropriate alignment reference (`PS`, `AN`, or `DF`) in the macro.
4. Run `Centered_Kymograph.ijm`.

## Citation

If you use these macros, please cite the associated publication.

Publication details and DOI can be added here after publication.
