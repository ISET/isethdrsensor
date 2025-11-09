# ISETHDRsensor
![Introduction Figure](figures/OpenFig.jpg)
This repository contains functions and scripts designed to evaluate High Dynamic Range (HDR) imaging sensor architectures, with a focus on nighttime driving scenes. The tools provided here are for researchers and engineers working on HDR imaging systems, particularly in automotive applications.

### Citations
Z. Liu, D. Shah and B. A. Wandell, "ISETHDR: A Physics-based Synthetic Radiance Dataset for High Dynamic Range Driving Scenes," in IEEE Sensors Journal, doi: 10.1109/JSEN.2025.3550455. 
[URL](https://ieeexplore.ieee.org/abstract/document/10930435)

keywords: {Sensors;Light sources;Lighting;Software;Image sensors;Intelligent sensors;High dynamic range;Training;Roads;Accuracy;Image system engineering;high dynamic range;digital twins;open source dataset;automotive imaging;nighttime driving},

Look at this [repository's Wiki](https://github.com/ISET/isethdrsensor/wiki) for scripts that create the images in that paper.

The data for this paper is [shared on Stanford's Digital Repository](https://purl.stanford.edu/bt316kj3589)

## Dependencies

### Other ISET repositories
The code in this repository relies on the following tools:

- [ISETCam](https://github.com/ISET/isetcam): A Matlab toolbox for simulating camera imaging systems.
```
git clone https://github.com/ISET/isetcam
```
- [ISET3D-tiny](https://github.com/ISET/iset3d-tiny): A Matlab toolbox for rendering scenes.
```
git clone https://github.com/ISET/iset3d-tiny
```

To run the neural network for denoising and demosaicing, you will also need to have a Matlab Python environment.  See the instructions for creating a Python environment on the [ISETCam wiki pages]()

### Python libraries for RGBW rendering

To run the demosaicing code, we need to install an [ISETCam Python environment within Matlab](https://github.com/ISET/isetcam/wiki/Related-software), and then add in the Python libraries specified in the file (isethdrsensor/utility/python/requirements.txt).  These libraries are used by the neural network code that performs the demosaicing and denoising here.

To install the requirements, you can use
```
cd isethdrsensor/utility/python
pip install -r requirements.txt
```
## Overview

The scripts in this repository utilize HDR driving scenes to simulate the responses of various sensors modeled in ISETCam. Our primary focus is on evaluating two specific sensor architectures:

1. **RGBW Sensor**: A sensor architecture that includes red, green, blue, and white pixels to capture a broader range of brightness levels.
2. **Omnivision 3-Capture Sensor**: A sensor designed by Omnivision that uses multiple captures to extend dynamic range.

A second contribution is a set of scenes that are rendered into light groups (see the paper for details).  A light group can be used to create an ISETCam scene spectral radiance, either for day, dusk or night conditions. 

The light group data sets, which include labeled data, are shared freely through the Stanford Digital Repository.  The data organization is described below.

### At Stanford

In the lab, to browse the light groups we use fiftyone.  It can be installed and then run this way
```   
pip install fiftyone
```
And then this command will bring up a viewer to see what is in the scenes
```   
fiftyone app connect --destination mux.stanford.edu
```
(August, 2024:  We are still working out the privileges of the program and mux.stanford.edu to enable secure access for viewing the data.)

## Usage

### Running the Simulations

To run the simulations, ensure that you have the necessary dependencies installed. Then, use the provided scripts to evaluate the performance of the sensor architectures under different driving scenes. The scripts generate response data and figures that illustrate the sensor performance.

### Reproducing Figures from the Paper

The scripts in this repository were used to generate most of the figures in the paper titled "ISETHDR: A Physically Accurate Synthetic Radiance Dataset for High Dynamic Range Driving Scenes," currently in preparation. You can modify the parameters in the scripts to explore different scenarios or reproduce the figures.

## Stanford Digital Repository Data
The data required for the /figures and /scripts directories is stored in the [Stanford Digital Repository (SDR)](https://searchworks.stanford.edu/view/bt316kj3589) Feel free to check it in your web browser.

The corresponding data from SDR will be automatically pulled for the scripts. A data folder will be created for the scene data, and a networks folder will be created for the pretrained ONNX network used for demosaicing and denoising, as described in the Experiments/RGBW Sensor section of the paper.

The link to the complete dataset: https://searchworks.stanford.edu/view/zg292rq7608

An example of a script that downloads the data from the repository is s_hsSkyBrightness.mlx.  This is the key part that uses ieWebGet() to download the files.

```
ieInit;    % Generic ISET initialization

imageID = '1112201236'; % - Good one to download
lgt = {'headlights','streetlights','otherlights','skymap'};

% Stick it there, which is .gitignored.
destPath = fullfile(isethdrsensorRootPath,'data',imageID);

% Download each one of the files from the light grup
scenes = cell(numel(lgt,1));
for ll = 1:numel(lgt)
    thisFile = sprintf('%s_%s.exr',imageID,lgt{ll});
    destFile = fullfile(destPath,thisFile);

    % Only get it if you didn't already get it!  I forget all the time.
    if ~exist(destFile,"file")
        ieWebGet('deposit name','isethdrsensor-paper',...
            'deposit file',fullfile('data',imageID,thisFile),...
            'download dir',fullfile(isethdrsensorRootPath,'data',imageID),...
            'unzip',false);
    end

    % Read it into a 'scene'.  It is stored as an EXR file.
    scenes{ll} = piEXR2ISET(destFile);
end
```

### Data Organization

All rendered scenes are accompanied by metadata files stored in a separate folder. Each scene includes multiple `.exr` layers and a corresponding `.mat` file, all sharing the same numeric prefix (e.g., `1112153442`). This prefix serves as the unique identifier for each scene.

- `*_headlights.exr`: Light contribution from headlights
- `*_otherlights.exr`: Contributions from nearby cars or ambient sources
- `*_streetlights.exr`: Light from fixed streetlights
- `*_skymap.exr`: Sky and global illumination
- `*_instanceID.exr`: Encodes object instance IDs for segmentation

The associated `.mat` file stores metadata such as depth map, segmentation map and a list of object names.

## Contributing

Contributions are welcome! If you have suggestions for improvements or new features, please feel free to open an issue or submit a pull request.

## License

This project is licensed under the [MIT License](LICENSE).

## Acknowledgments

Special thanks to the developers of ISETCam, ISETAuto, and ISET3d for their invaluable tools that made this work possible.

## Octave Support
- July 14, 2025: Ayush Jamdar.
- We've modified EXR handling and other scripts in `isetcam` and `iset3d-tiny` that can read the light groups using OpenEXR and simulate the complete pipeline in GNU Octave. 
- We have tested `isethdrsensor/scripts/fullSimulation.m` on examples from the ISET HDR dataset using Octave 6.4.0.
- Refer to `isetcam/README.md` for Octave and Conda environment packages.
