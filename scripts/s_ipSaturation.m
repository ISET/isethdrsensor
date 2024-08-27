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

% If you use the oiTunnel, skip the oi sections below and go straight
% to the sensor compute and ip compute

%{
% When I was home, this took a very long time to download
oiFile = fullfile(isethdrsensorRootPath,'data','oiTunnel.mat');
if ~exist(oiFile,"file")
    % download the file from SDR
    ieWebGet('resourcetype','isethdrsensor',...
        'resource name','data/oiTunnel.mat',...
        'download dir',isethdrsensorRootPath);
end
load(oiFile,'oiInput');
oi = oiInput; clear oiInput;
%}

%% Load the light group scenes and calculate the oi

% load('HDR-scenes-1114091636.mat');  % Green and red cars
% load('HDR-scenes-1114011756.mat','scenes');  % Vans, pedestria, very red
% We could use 'oiTunnel.mat'
fname = 'HDR-scenes-1113094429.mat';
oiFile = fullfile(isethdrsensorRootPath,'data',fname);
if ~exist(oiFile,"file")
    % Not found.  download the file from SDR
    ieWebGet('resourcetype','isethdrsensor',...
        'resource name',fullfile('data',fname),...
        'download dir',isethdrsensorRootPath);
end
load(fname,'scenes');

% These are the light groups
lgt = {'headlights','streetlights','otherlights','skymap'};

% Create a 6 log unit DR with a low level of 1 cd/m2
scene = lightGroupDynamicRangeSet(scenes,10^6,1);

% Get rid of rendering noise.
scene = piAIdenoise(scene);

% Have a look
sceneWindow(scene,'gamma',0.2);
drawnow;

% Compute OI with some flare.

[oi,wvf] = oiCreate('wvf');
nsides = 5;
wvf = wvfSet(wvf,'spatial samples',1024);
[aperture, params] = wvfAperture(wvf,'nsides',nsides);

oi = oiCompute(oi, scene,'crop',true,'pixel size',3e-6,'aperture',aperture);
oiWindow(oi,'render flag','hdr');

% Show the HDR
oiPlot(oi,'hline illuminance',[1 629]);
set(gca,'yscale','log');

%% Set the exposure time to create saturation.

sensor = sensorCreate('imx363');
sensor = sensorSet(sensor,'match oi',oi);
sensor = sensorSet(sensor,'exp time',1/60);
sensor = sensorCompute(sensor,oi);
sensorWindow(sensor,'gamma',0.5);

%% Process without hdr white

ip = ipCreate;
ip = ipCompute(ip,sensor,'hdr white',false);
ipWindow(ip,'gamma',0.5);

%% Process with hdr white

ip = ipCompute(ip,sensor,'hdr white',true);
ipWindow(ip,'gamma',0.5);

%% Change the level where we saturation begins and process again

mx = sensorGet(sensor,'voltage swing');
ip = ipCompute(ip,sensor,'hdr white',true,'hdr level',mx*0.1);
ipWindow(ip,'gamma',0.5);

%% 