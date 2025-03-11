# Cellpose-JACoP
ImageJ macro to perform [Cellpose](https://github.com/MouseLand/cellpose) segmentation and subsequent [BIOP JACoP](https://github.com/BIOP/ijp-jacop-b) colocalization analysis on every cell for all images in a folder.

## Installation / Requirements
Download the [latest release of `Segment_cells_and_perform_JACoP.ijm`] (in Assets). If placed in Fiji.app\plugins\Macros the macro appears in the Fiji menu bar under `Plugins -> Macros`. Otherwise, drag & drop onto the Fiji window and click 'Run' in the Script Editor.

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
- `tsv` files with colocalization results

## Running the script
<img src="https://github.com/user-attachments/assets/01af1048-b63e-4495-8415-e4b7e42f201d" width="500">

Input image:

![image](https://github.com/user-attachments/assets/0f48d0c9-d44e-4555-affd-6cfc4a35cc0d)

Output label image:

![image](https://github.com/user-attachments/assets/237f2678-6750-4e1b-b70f-76634c6d3ea7)

Output image with thresholds indicated (as two extra channels, with the same LUT as the two input channels):

![image](https://github.com/user-attachments/assets/1a2681cc-23a2-4950-94e5-91ba3edba896)

Output results:

![results](https://github.com/user-attachments/assets/f2b96e26-af9e-4951-ab56-54dffff67c45)
