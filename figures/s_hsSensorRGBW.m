%% Illustrates how to use the network demosaic method
%
% The demosaic-denoise networks were trained on the ar0132at, both the
% 'rgbw' and 'rgb' sensor.  The network runs for scenes with a
% reasonable illumination, but not well on the HDR scenes.
%
% To run the neural networks in the demosaicing ONNX files, you must
% have the Python environment installed on your computer.  See the
% instructions for installing Conda and connecting it to Matlab in
% 
%   s_python
%
% The ipCompute command to use these networks is:
%
%   ipCompute(ip,sensorRGBW,'neural network','ar0132at-rgbw');
%
% See also
%

%%
ieInit;

imageID = '1114091636';   % Red car, green car.  
oiName = fullfile(isethdrsensorRootPath,'local',sprintf('oiDay-%s.mat',imageID));
load(oiName,'oiDay');

%% RGBW sensor

sensorRGBW = sensorCreate('ar0132at',[],'rgbw');
sensorRGBW = sensorSet(sensorRGBW,'match oi',oiDay);
sensorRGBW = sensorSet(sensorRGBW,'exp time',2e-3);
sensorRGBW = sensorCompute(sensorRGBW,oiDay);
sensorWindow(sensorRGBW,'gamma',0.5);

%% Show an image of the sensor mosaic at true size

rgbw = sensorGet(sensorRGBW,'rgb');
ieNewGraphWin; imagesc(rgbw); truesize;

%% Demosaic - pretty slow.

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

%% END