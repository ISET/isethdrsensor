%% Illustrates how to use the network demosaic method
%
% The network we have was trained on the ar0132at, both the
% 'rgbw' and 'rgb' sensor.  It runs for scenes with a reasonable
% illumination, but not well on the HDR scenes.
%
% The ipCompute command is implemented like this
%
%   ipCompute(ip,sensorRGBW,'neural network','ar0132at-rgbw');
%
% See also
%

%
% This worked for Wandell on July 16, 3pm
%

%%
ieInit;

% I tried with both of these scenes.  Both looked good.
% imageID = '1112201236'; % - Good one
imageID = '1114091636';   % Red car, green car

%% Day scene weights

wgts = [0    0     0    100*0.5175]; % Day
scene = hsSceneCreate(imageID,'weights',wgts,'denoise',false);
% sceneWindow(scene,'render flag','clip');

%% Create the optics
[oi,wvf] = oiCreate('wvf');
params = wvfApertureP;
% We should implement wvfApertureSet/Get so we do not have to remember
% the parameter names precisely.
% {
params.nsides = 3;
params.dotmean = 50;
params.dotsd = 20;
params.dotopacity =0.5;
params.dotradius = 5;
params.linemean = 50;
params.linesd = 20;
params.lineopacity = 0.5;
params.linewidth = 2;
%}

aperture = wvfAperture(wvf,params);
oi = oiSet(oi,'wvf zcoeffs',0,'defocus');

%%
oiDay = oiCompute(oi, scene,'aperture',aperture,'crop',true,'pixel size',3e-6);
oiWindow(oiDay,'gamma',0.5,'render flag','rgb');


%% RGBW and network demosaic.

sensorRGBW = sensorCreate('ar0132at',[],'rgbw');
sensorRGBW = sensorSet(sensorRGBW,'match oi',oiDay);
sensorRGBW = sensorSet(sensorRGBW,'exp time',2e-3);
sensorRGBW = sensorCompute(sensorRGBW,oiDay);
sensorWindow(sensorRGBW,'gamma',0.5);
% rgb = sensorGet(sensorRGBW,'rgb');
% ieNewGraphWin; imagesc(rgb); truesize;

% The demosaic is pretty slow.
ipRGBW = ipCreate;
ipRGBW = ipCompute(ipRGBW,sensorRGBW,'network demosaic','ar0132at-rgbw');
ipWindow(ipRGBW,'gamma',1,'render flag','rgb');

%%
sensorRGB = sensorCreate('ar0132at',[],'rgb');
sensorRGB = sensorSet(sensorRGB,'match oi',oiDay);
sensorRGB = sensorSet(sensorRGB,'exp time',2e-3);
sensorRGB = sensorCompute(sensorRGB,oiDay);

sensorWindow(sensorRGB,'gamma',0.5);
% rgb = sensorGet(sensorRGB,'rgb');
% ieNewGraphWin; imagesc(rgb); truesize;

% The demosaic is pretty slow.
ipRGB = ipCreate;
ipRGB = ipCompute(ipRGB,sensorRGB,'network demosaic','ar0132at-rgb');
ipWindow(ipRGB,'gamma',1,'render flag','rgb');

%% END