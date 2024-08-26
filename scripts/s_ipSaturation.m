%% s_hsIPSaturation
%
% Illustrates the impact of the 'hdr white' parameter in ipCompute.  This
% was important for the final rendering of high dynamic range scenes, as
% described in the comments of ipCompute.
%
% See also
%   ipCompute
%   https://sdr.stanford.edu/works/8521

%%
ieInit;

%% Use the tunnel scene?

% When I was home, this took a very long time to download
oiFile = fullfile(isethdrsensorRootPath,'data','oiTunnel.mat');
if ~exist(oiFile,"file")
    % download the file from SDR
    ieWebGet('resourcetype','isethdrsensor',...
        'resource name','data/oiTunnel.mat',...
        'download dir',isethdrsensorRootPath);
end
load(oiFile,'oiInput');

%% Load the light group scenes

% load('HDR-scenes-1114091636.mat');  % Green and red cars

% load('HDR-scenes-1114011756.mat','scenes');  % Vans, pedestria, very red
% load('HDR-scenes-1113094429');      % Truck bicycle, dusk
% sceneWindow(scenes{4},'gamma',0.3);

% These are their lights
lgt = {'headlights','streetlights','otherlights','skymap'};

% Create a 6 log unit DR with a low level of 1 cd/m2
scene = lightGroupDynamicRangeSet(scenes,10^6,1);
scene = piAIdenoise(scene);
sceneWindow(scene,'gamma',0.2);

%% Compute OI with some flare.

[oi,wvf] = oiCreate('wvf');
nsides = 4;
[aperture, params] = wvfAperture(wvf,'nsides',nsides);
oi = oiCompute(oi, scene,'crop',true,'pixel size',3e-6,'aperture',aperture);
oiWindow(oi,'render flag','hdr');

% Show the HDR
oiPlot(oi,'hline illuminance',[1 629]);
set(gca,'yscale','log');

%% Set the exposure time to allow saturation.

sensor = sensorCreate('imx363');
sensor = sensorSet(sensor,'match oi',oiInput);
sensor = sensorSet(sensor,'exp time',1/60);
sensor = sensorCompute(sensor,oi);
sensorWindow(sensor,'gamma',0.5);

%% Process without hdr white

ip = ipCreate;
ip = ipCompute(ip,sensor,'hdr white',false);
ipWindow(ip,'gamma',0.5);

%% With hdr white
ip = ipCompute(ip,sensor,'hdr white',true);
ipWindow(ip,'gamma',0.5);

%% More blur of the HDR region
% Skipping wgt blur parameter.  It sets only the support, not the extent.

%% Change the level where we think saturation begins

mx = sensorGet(sensor,'voltage swing');
ip = ipCompute(ip,sensor,'hdr white',true,'hdr level',mx*0.1);
ipWindow(ip,'gamma',0.5);

%% End