# Cellpose-JACoP
ImageJ macro to perform [Cellpose](https://github.com/MouseLand/cellpose) segmentation and subsequent [BIOP JACoP](https://github.com/BIOP/ijp-jacop-b) colocalization analysis on every cell for all images in a folder.

## Installation / Requirements
Download [`Segment_cells_and_perform_JACoP.ijm`](https://github.com/BioImaging-NKI/Cellpose-JACoP/blob/main/Segment_cells_and_perform_JACoP.ijm). If placed in Fiji.app\plugins\Macros the macro appears in the Fiji menu bar under `Plugins -> Macros`. Otherwise, drag & drop onto the Fiji window and click 'Run' in the Script Editor.

Requires the following [Fiji Update Sites](https://imagej.net/update-sites/following):
- CLIJ
- CLIJ2
- PT-BIOP
Cellpose is executed using the [BIOP Cellpose wrapper](https://github.com/BIOP/ijl-utilities-wrappers). A working Cellpose environment (venv or conda) is required.
Run the wrapper at least once to set the cellpose environment path and type.

_Input_: a folder containing multichannel 2D images. Multiseries microscopy format files (.lif, .czi etc.) are also supported.
_Output_: for each image:
- labelmap images containing Cellpose segmentations
- Analyzed images with two extra channels containing the used masks (thresholds) for colocalization.
- `tsv` files with colocalization results. These can be directly loaded in Excel/R/Prism for further processing.

## Running the script
Upon running you will see a dialog with script parameters:

<img src="https://github.com/user-attachments/assets/f20b7239-d656-46f0-a2c9-465bfbf86e32" width="500">

Most parameters are self-explaining. A few others are discussed here:
- _Nuclei channel (-1 if not used)_: Only used by Cellpose for segmentation. This channel is not required.
- _Cytoplasm channel_: Used by Cellpose for segmentation.
- _Image XY binning before analysis [1-n]_: n x n pixel binning to reduce the size of the image.
- _Gaussian blur radius (sigma) before JACoP (pixels)_: Filter the image to reduce noise.

- _flow threshold [0.0 - 1.0], default 0.4_: Cellpose segmentation parameter; incresae to accept more cells.
- _probability threshold [-6.0 - 6.0], default 0.0_: Cellpose segmentation parameter; decrease to increase segmented cell size (and accept more cells).
- _Load segmentation label images from disk instead of Cellpose?_: Load segmented labels from disk instead of running Cellpose segmentation. Label images should have the same basename as the input images, complemented with '_labelmap.tif'.
- _Threshold method_: Automatic threshold method for channel A. Select 'Use manual threshold below' to use a fixed manual threshold for every cell.

## Results
Input image:

![image](https://github.com/user-attachments/assets/0f48d0c9-d44e-4555-affd-6cfc4a35cc0d)

Output label image:

![image](https://github.com/user-attachments/assets/237f2678-6750-4e1b-b70f-76634c6d3ea7)

Output image with thresholds indicated (as two extra channels, with the same LUT as the two input channels):

![image](https://github.com/user-attachments/assets/1a2681cc-23a2-4950-94e5-91ba3edba896)

Output results:

![results](https://github.com/user-attachments/assets/f2b96e26-af9e-4951-ab56-54dffff67c45)

### Note
For every image a separate results file is saved. Use the macro [`Append_result_files.ijm`](https://github.com/BioImaging-NKI/Cellpose-JACoP/blob/main/Append_result_files.ijm) to merge all `.tsv` files in a folder. It will create a file called `Results_all_files.tsv`.
