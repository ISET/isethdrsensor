function [result, output_path] = isetDemosaicNN(cfa, input_path, output_path)
% isetDemosaicNN - Function to demosaic an image using a neural network.
%
% Syntax:  [result, output_path] = isetDemosaicNN(input_path, output_path)
%
% Inputs:
%    input_path - String, path to the input image to be demosaiced.
%    output_path - String, path to save the demosaiced output image.
%
% Outputs:
%    result - Result of the demosaicing process.
%    output_path - Path where the demosaiced image is saved.


%%
% Define the path to the Python network utility
network_path = fullfile(isethdrsensorRootPath, 'utility/python');

% Check if the Python path is already in the system path
if count(py.sys.path, network_path) == 0
    % Insert the network path into the Python system path
    insert(py.sys.path, int32(0), network_path);
end

% Import the Python module for demosaicing
NNemosaic = py.importlib.import_module('rgbw_demosaic');

% Determine the path to the appropriate model based on CFA (Color Filter Array)
switch cfa
    case 'rgb'
        % Path to the RGB demosaicing model
        model_path = fullfile(isethdrsensorRootPath, 'data/networks', 'NNDemosaicRGB.onnx');
    case 'rgbw'
        % Path to the RGBW demosaicing model
        model_path = fullfile(isethdrsensorRootPath, 'data/networks', 'NNDemosaicRGBW.onnx');
    otherwise
        % Error for unsupported CFA types
        error('CFA has to be RGB or RGBW');
end

% Call the Python function for demosaicing
result = NNemosaic.rgbw_demosaic(model_path, input_path, output_path);

% Check if the result is not of Python NoneType, indicating an error
if ~isa(result, 'py.NoneType')
    error(result);
end

end

