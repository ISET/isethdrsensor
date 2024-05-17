function [result, exrOutput] = isetDemosaicNN(cfa, exrInput, exrOutput)
% isetDemosaicNN - Function to demosaic an image using a neural network.
%
% Syntax:  [result, output_path] = isetDemosaicNN(cfa, input_path, output_path)
%
% Inputs:
%    cfa  - 'rgbw' or 'rgb'.  'rgb' NYI
%    exrInput  - String, path to the input image to be demosaiced.
%    exrOutput - String, path to save the demosaiced output image.
%
% Outputs:
%    result    - Result of the demosaicing process.
%    exrOutput - Path to the demosaiced image is saved.

% Example:
%{
cfa = 'rgbw';
%}

%%
% Define the path to the Python network utility
python_path = fullfile(isethdrsensorRootPath, 'utility/python');

% Check if the Python path is already in the system path
if count(py.sys.path, python_path) == 0
    % Insert the network path into the Python system path
    insert(py.sys.path, int32(0), python_path);
end

% Import the Python module for demosaicing
NNemosaic = py.importlib.import_module('Demosaic_restormer');

% Determine the path to the appropriate model based on CFA (Color Filter Array)
switch cfa
    case 'rgb'
        % Path to the RGB demosaicing model
        model_path = fullfile(isethdrsensorRootPath, 'networks', 'NNDemosaicRGB.onnx');
    case 'rgbw'
        % Path to the RGBW demosaicing model
        model_path = fullfile(isethdrsensorRootPath, 'networks', 'NNDemosaicRGBW.onnx');
    otherwise
        % Error for unsupported CFA types
        error('CFA has to be RGB or RGBW');
end

% Call the Python function for demosaicing
result = NNemosaic.demosaic(model_path, exrInput, exrOutput);

% Check if the result is not of Python NoneType, indicating an error
if ~isa(result, 'py.NoneType')
    error(result);
end

end


