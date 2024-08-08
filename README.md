# ISETHDRsensor

This repository contains functions and scripts designed to evaluate High Dynamic Range (HDR) imaging sensor architectures, with a focus on nighttime driving scenes. The tools provided here are essential for researchers and engineers working on HDR imaging systems, particularly in automotive applications.

## Dependencies

The code in this repository relies on the following tools:

- [ISETCam](https://github.com/ISET/isetcam): A Matlab toolbox for simulating camera imaging systems.
- [ISETAuto](https://github.com/ISET/isetauto): A Matlab toolbox for automotive scene generation and analysis.
- [ISET3d](https://github.com/ISET/iset3d-tiny): A Matlab toolbox for creating and rendering 3D scenes.

Ensure that these dependencies are installed and configured properly before running the scripts.

## Overview

The scripts in this repository utilize HDR driving scenes to simulate the responses of various sensors modeled in ISETCam. Our primary focus is on evaluating two specific sensor architectures:

1. **RGBW Sensor**: A sensor architecture that includes red, green, blue, and white pixels to capture a broader range of brightness levels.
2. **Omnivision 3-Capture Sensor**: A sensor designed by Omnivision that uses multiple captures to extend dynamic range.

## Usage

### Running the Simulations

To run the simulations, ensure that you have the necessary dependencies installed. Then, use the provided scripts to evaluate the performance of the sensor architectures under different driving scenes. The scripts generate response data and figures that illustrate the sensor performance.

### Reproducing Figures from the Paper

The scripts in this repository were used to generate most of the figures in the paper titled "ISETHDR: A Physically Accurate Synthetic Radiance Dataset for High Dynamic Range Driving Scenes," currently in preparation. You can modify the parameters in the scripts to explore different scenarios or reproduce the figures.

## Contributing

Contributions are welcome! If you have suggestions for improvements or new features, please feel free to open an issue or submit a pull request.

## License

This project is licensed under the [MIT License](LICENSE).

## Acknowledgments

Special thanks to the developers of ISETCam, ISETAuto, and ISET3d for their invaluable tools that made this work possible.
