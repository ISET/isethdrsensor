%% Illustrates how to use the network demosaic method
%
%
% This is quite similar to Fig 08/09 in figures directory.  Perhaps
% the only difference is this file uses the oiDay-1114091636.mat file.
% The oiDay file is also on the Stanford Digital Repository.
%
% To run the neural networks in the demosaicing ONNX files, you must
% have the Python environment installed on your computer.  See the
% instructions for installing Conda and connecting it to Matlab in
% 
%   https://github.com/ISET/isetcam/wiki/Related-software
%
% Or
%
%   The ISETHDRSENSOR Readme page
%
% Or
%
%   s_python
%
% You must also have the trained restormer network in
% isethdrsensor/network.  These can be downloaded using ieWebGet.
%
% The ipCompute command to use these networks, for the RGBW case, is
%
%   ipCompute(ip,sensorRGBW,'neural network','ar0132at-rgbw');
%
% The demosaic-denoise networks were trained on the ar0132at, both the
% 'rgbw' and 'rgb' sensor.  The network runs for scenes with a
% reasonable illumination, but not well on the HDR scenes.
%
% See also
%

%%
ieInit;

fname = 'oiDay-1114091636.mat';
oiFile = fullfile(isethdrsensorRootPath,'data',fname);
if ~exist(oiFile,"file")
    % Not found.  download the file from SDR
    ieWebGet('deposit name','isethdrsensor-paper',...
        'deposit file',fullfile('data',fname),...
        'download dir',fullfile(isethdrsensorRootPath,'data'),...
        'unzip',false);
end
load(fname,'oiDay');

%% RGBW sensor

sensorRGBW = sensorCreate('ar0132at',[],'rgbw');
sensorRGBW = sensorSet(sensorRGBW,'match oi',oiDay);
sensorRGBW = sensorSet(sensorRGBW,'exp time',2e-3);
sensorRGBW = sensorCompute(sensorRGBW,oiDay);
sensorWindow(sensorRGBW,'gamma',0.5);

%% Show an image of the sensor mosaic at true size

rgbw = sensorGet(sensorRGBW,'rgb');
ieNewGraphWin; imagesc(rgbw); truesize;

%% Demosaic - pretty slow because oiDay is pretty large

ipRGBW = ipCreate;
ipRGBW = ipCompute(ipRGBW,sensorRGBW,'network demosaic','ar0132at-rgbw');
ipWindow(ipRGBW,'gamma',1,'render flag','rgb');
imageShowImage(ipRGBW,ipGet(ipRGBW,'gamma'),true,ieNewGraphWin);

%%  RGB sensor 

sensorRGB = sensorCreate('ar0132at',[],'rgb');
sensorRGB = sensorSet(sensorRGB,'match oi',oiDay);
sensorRGB = sensorSet(sensorRGB,'exp time',2e-3);
sensorRGB = sensorCompute(sensorRGB,oiDay);
sensorWindow(sensorRGB,'gamma',0.5);

%% Show a true size image

rgb = sensorGet(sensorRGB,'rgb');
ieNewGraphWin; imagesc(rgb); truesize;

%% The demosaic is pretty slow.

ipRGB = ipCreate;
ipRGB = ipCompute(ipRGB,sensorRGB,'network demosaic','ar0132at-rgb');
ipWindow(ipRGB,'gamma',1,'render flag','rgb');
imageShowImage(ipRGB,ipGet(ipRGB,'gamma'),true,ieNewGraphWin);

%% 