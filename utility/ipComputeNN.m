function ip = ipComputeNN(inputSensor, type)
% ipComputeNN Computes the image processing pipeline using a neural network for demosaicing.
%
% Syntax:
%   ip = ipComputeNN(sensor, type)
%
% Description:
%   This function performs image processing on the input sensor data using a neural network
%   for demosaicing. The function saves the intermediate data as EXR files, applies necessary
%   transforms, and returns the final image processing structure.
%
% Inputs:
%   sensor - The sensor data structure containing image information.
%   type   - The type of neural network to use for demosaicing.
%
% Outputs:
%   ip     - The final image processing structure after applying the neural network demosaicing
%            and other necessary transformations.
%
% Example:
%   sensor = sensorCreate;
%   type = 'rgbw'; % or 'rgb'
%   ip = ipComputeNN(sensor, type);

% Start timing the function execution
tic;

% Get the current hour and minute
[HH, mm] = hms(datetime('now'));

% Define the directory for storing EXR files
exrDir = fullfile(isethdrsensorRootPath, 'local', 'exr', string(datetime('today')));

% Create the directory if it does not exist
if ~exist(exrDir, 'dir')
    mkdir(exrDir); 
end

% Generate the filename for the EXR file
fname = sprintf('%02dH%02dS-%s-%.2f.exr', uint8(HH), uint8(mm), type, sensorGet(inputSensor, 'exp time', 'ms'));

% Save the sensor data as an EXR file
fname = sensor2EXR(inputSensor, fullfile(exrDir, fname));

% Split the file path into parts
[p, n, ext] = fileparts(fname);

% Define the output EXR filename for the demosaiced image
ipEXR = sprintf('%s-ip%s', fullfile(p, n), ext);

disp('INFO: Demosaicing started ...')
% Perform neural network-based demosaicing
isetDemosaicNN(type, fname, ipEXR);

% Create an image processing structure
ip = ipCreate;

% Create the rendering transforms
wave = sensorGet(inputSensor, 'wave');
sensorQE = sensorGet(inputSensor, 'spectral qe');
targetQE = ieReadSpectra('xyzQuanta', wave);
T{1} = imageSensorTransform(sensorQE(:,1:3), targetQE, 'D65', wave, 'mcc');
T{2} = eye(3,3);
T{3} = ieInternal2Display(ip);

% Set the demosaicing method to skip (since we have already demosaiced)
ip = ipSet(ip, 'demosaic method', 'skip');

% Set the transforms for the image processing structure
ip = ipSet(ip, 'transforms', T);
ip = ipSet(ip, 'transform method', 'current');

% Read the demosaiced image from the EXR file
img = exrread(ipEXR);

% Set the sensor space image in the image processing structure
ip = ipSet(ip, 'sensor space', img);

% Compute the final image processing
ip = ipCompute(ip, inputSensor);

% Set the name of the image processing structure to the filename
[~, ipName] = fileparts(ipEXR);
ip = ipSet(ip, 'name', ipName);

% End timing the function execution and display the elapsed time
elapsedTime = toc;
fprintf('Elapsed time for ipComputeNN function: %.2f seconds\n', elapsedTime);
end