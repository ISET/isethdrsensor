function [result, exrOutput] = isetDemosaicNN(networkName, exrInput, exrOutput)
% isetDemosaicNN - Function to demosaic an image using a neural network.
%
% Synopsis:
%  [result, output_path] = isetDemosaicNN(networkName, input_path, output_path)
%
% Brief:
%   Requires a Python environment in Matlab and the ONNX files that Zhenyi
%   Liu trained.  See s_python for installation instructions.
%
%   June 2, 2024: The ONNX files are on
%
%    /acorn/data/iset/zhenyi/ISETSensor/Restormer 
%      * NNDemosaicRGB.onnx
%      * NNDemosaicRGBW.onnx
%
%    The onnx files should be placed by the user in
%    isethdrsensor/networks/. Because they are big, we do not keep
%    them in the repository.
%
% Inputs:
%   networkName  - Name of the trained network.  ar0132at-rgbw or
%                  ar0132at-rgb as of July, 2024.
%   exrInput  - String, path to the input image to be demosaiced.
%   exrOutput - String, path to save the demosaiced output image.
%
% Outputs:
%   result    - Result of the demosaicing process.
%   exrOutput - Path to the demosaiced image is saved.
%
% Description:
%   ZL trained neural networks to demosaic some high dynamic range (HDR)
%   sensor data.  The networks were trained for the 'ar0132at' model, both
%   the 'rgb' and 'rgbw' case.  
%
%   This function uses Matlab's ability to execute Python to read in and
%   execute the trained networks. The networks are stored as ONNX files.
%
%   To run this, you must have a python environment imported into Matlab.
%   For instructions on how to do this, see the s_python script.
%
% See also
%   s_python, s_hsSensorRGBW, ipCompute


%%
% Define the path to the Python network utility
python_path = fullfile(isethdrsensorRootPath, 'utility/python');

% Check if the Python path is already in the system path
if count(py.sys.path, python_path) == 0
    % Insert the network path into the Python system path
    insert(py.sys.path, int32(0), python_path);
end

% Import the Python module for demosaicing
NNDemosaic = py.importlib.import_module('Demosaic_restormer');
NNDemosaic = py.importlib.reload(NNDemosaic);

% Determine the path to the appropriate model based on CFA (Color
% Filter Array).  The name space can get larger over time, in
% principle.
switch networkName
    case 'ar0132at-rgb'
        % Path to the RGB demosaicing model
        model_path = fullfile(isethdrsensorRootPath, 'networks', 'NNDemosaicRGB.onnx');
    case 'ar0132at-rgbw'
        % Path to the RGBW demosaicing model
        model_path = fullfile(isethdrsensorRootPath, 'networks', 'NNDemosaicRGBW.onnx');
    otherwise
        % Error for unsupported CFA types
        error('Trained network name not known:  %s',networkName);
end

% Call the Python function for demosaicing
result = NNDemosaic.demosaic(model_path, exrInput, exrOutput);

% Check if the result is not of Python NoneType, indicating an error
if ~isa(result, 'py.NoneType')
    error(result);
end

end


