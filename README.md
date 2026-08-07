# Zebrafish Kymograph Analysis

ImageJ/Fiji macros for generating and aligning kymographs used to analyze tissue dynamics during zebrafish somitogenesis.

## Files

### `Lab_Frame_Kymograph.ijm`

Generates lab-frame kymographs from maximum-projected YFP time-lapse images using Fiji's LOI Interpolator.

Lines of interest (LOIs) are manually drawn along the tissue at selected time points and added sequentially to the ROI Manager while keeping the most recently formed somite boundary at a fixed reference position. The LOI Interpolator interpolates between successive LOIs to generate a continuous kymograph.

For the analyses described in the associated study, the LOI width was set to 30 pixels (37.5 µm), and fluorescence intensity was averaged across the line width.

The macro uses changes in the measured lengths of sequential LOIs to reconstruct the kymograph in the laboratory reference frame.

### `Centered_Kymograph.ijm`

Horizontally aligns each row of a kymograph to a user-defined anatomical reference trajectory. The reference trajectory must be stored as ROI #0 in the ROI Manager.

For each y-position, the macro determines the corresponding x-coordinate of the reference trajectory and horizontally shifts the image row so that the trajectory is aligned to a common position.

The `Position` parameter specifies the anatomical reference used for alignment:

- `PS` — posterior-aligned
- `AN` — anterior-aligned
- `DF` — determination-front-aligned

The `deltaposittt` parameter specifies the horizontal offset of the intensity-profile line relative to the alignment reference:

- `PS` — 20 pixels
- `AN` — 20 pixels
- `DF` — 0 pixels

## Requirements

- Fiji/ImageJ
- LOI Interpolator
- ROI Manager

No non-standard hardware is required.

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
3. Set `Position` to the desired alignment reference (`PS`, `AN`, or `DF`).
4. Set `deltaposittt` to 20 pixels for `PS` or `AN`, or 0 pixels for `DF`.
5. Run `Centered_Kymograph.ijm`.

## Demo

Example datasets are provided in the `demo/` directory to test the macros.

### Lab-frame kymograph demo

The `demo/` directory contains an example maximum-projected YFP time-lapse image and the corresponding LOIs used to generate a laboratory-frame kymograph.

1. Open `example_timelapse.tif` in Fiji.
2. Open the ROI Manager and load `example_LOIs.zip`.
3. Run `Lab_Frame_Kymograph.ijm`.

The macro generates a laboratory-frame kymograph from the supplied time-lapse image and LOIs.

Expected runtime: less than 1 minute on a standard desktop computer.

### Centered kymograph demo

An example kymograph and anatomical reference trajectory are provided for testing the alignment macro.

1. Open `example_kymograph.tif` in Fiji.
2. Open the ROI Manager and load `example_alignment_ROI.zip`.
3. Confirm that the anatomical reference trajectory is ROI #0.
4. Set `Position` and `deltaposittt` to the appropriate values in `Centered_Kymograph.ijm`.
5. Run `Centered_Kymograph.ijm`.

The macro generates a horizontally aligned kymograph in which the selected anatomical reference trajectory is positioned at a common x-coordinate.

Expected runtime: less than 1 minute on a standard desktop computer.

## Citation

If you use these macros, please cite the associated publication.

Publication details and DOI can be added here after publication.

## License

This code is released under the MIT License. See the `LICENSE` file for details.
