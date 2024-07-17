%% Make a figure comparing the different types of sensors
%
% For a couple of scenes, render them through some kind of optics onto the
%
% Here are the scenes.  Refresh from time to time.
%
%   hsSceneDescriptions;
%
% The light group names
%   lgt = {'headlights','streetlights','otherlights','skymap'};

%%
ieInit;

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

% imageID = '1112201236'; % - Good one
imageID = '1114091636';   % Red car, green car

%% Load the four light group

fname = fullfile(isethdrsensorRootPath,'data',sprintf('HDR-scenes-%s',imageID));
load(fname,'scenes');

%% Day

wgts = [0    0     0    100*0.5175]; % Day
scene = hsSceneCreate(imageID,'weights',wgts,'denoise',false);
% sceneWindow(scene,'render flag','clip');
oiDay = oiCompute(oi, scene,'aperture',aperture,'crop',true,'pixel size',3e-6);
oiWindow(oiDay,'gamma',0.5,'render flag','rgb');
% srgb = oiGet(oiDay,'rgb'); ieNewGraphWin; image(srgb); truesize

%% First a standard RGB

sensorRGB = sensorCreate('ar0132at');
sensorRGB = sensorSet(sensorRGB,'match oi',oiDay);
sensorRGB = sensorSet(sensorRGB,'exp time',2e-3);
sensorRGB = sensorCompute(sensorRGB,oiDay);
sensorWindow(sensorRGB,'gamma',0.5);
rgb = sensorGet(sensorRGB,'rgb');
ieNewGraphWin; imagesc(rgb); truesize;

%% Night

% Experimenting with how dark.  4 log units down gets night
% But three really doesn't.
wgts    = [0.2306    0.0012    0.0001    1e-2*0.5175]; % Night
scene   = hsSceneCreate(imageID,'weights',wgts,'denoise',false);
oiNight = oiCompute(oi, scene,'aperture',aperture,'crop',true,'pixel size',3e-6);
oiWindow(oiNight,'render flag','rgb','gamma',0.2);

%% Night time
sensorRGB = sensorSet(sensorRGB,'exp time',16e-3);
sensorRGB = sensorSet(sensorRGB,'noise flag',2);
sensorRGB = sensorCompute(sensorRGB,oiNight);
sensorWindow(sensorRGB,'gamma',0.3);

rgb = sensorGet(sensorRGB,'rgb');
ieNewGraphWin; imagesc(rgb); truesize;
imName = sprintf('rgbSensor.png');
imwrite(rgb,fullfile(isethdrsensorRootPath,'local',imName));

sensorRGB2 = sensorSet(sensorRGB,'noise flag',-1);
sensorRGB2 = sensorSet(sensorRGB2,'name','no noise');
sensorRGB2 = sensorCompute(sensorRGB2,oiNight);
sensorWindow(sensorRGB2,'gamma',0.3);

% We probably need to reset gamma to 1 before these sensorGet calls
rgbNoisefree = sensorGet(sensorRGB2,'rgb');

rmse(rgb(:),rgbNoisefree(:))

% sensorPlot(sensorRGB2,'volts hline',[1 859], 'two lines',true);
% sensorPlot(sensorRGB,'volts hline',[1 859], 'two lines',true);
sensorPlot(sensorRGB,'volts hline',[1 859]);
sensorPlot(sensorRGB2,'volts hline',[1 859]);

%% Split pixel calculation

pixelSize = sensorGet(sensorRGB,'pixel size');
sensorSize = sensorGet(sensorRGB,'size');
sensorArray = sensorCreateArray('array type','ovt',...
    'pixel size same fill factor',pixelSize,...
    'exp time',16e-3, ...
    'size',sensorSize);

sensorSplit = sensorComputeArray(sensorArray,oiNight);
sensorWindow(sensorSplit,'gamma',0.3);

% We probably need to reset gamma to 1 before these sensorGet calls
rgb = sensorGet(sensorSplit,'rgb');
ieNewGraphWin; imagesc(rgb); truesize;
imName = sprintf('splitSensor.png');
imwrite(rgb,fullfile(isethdrsensorRootPath,'local',imName));

sensorArray = sensorCreateArray('array type','ovt',...
    'pixel size same fill factor',pixelSize,...
    'exp time',16e-3, ...
    'size',sensorSize, ...
    'noise flag',-1);
[sensorSplit2, sensorArray] = sensorComputeArray(sensorArray,oiNight);
rgbNoisefree = sensorGet(sensorSplit,'rgb');

rmse(rgb(:),rgbNoisefree(:))

% sensorPlot(sensorSplit2,'volts hline',[1 859], 'two lines',true);
% sensorPlot(sensorSplit,'volts hline',[1 859], 'two lines',true);
sensorPlot(sensorSplit2,'volts hline',[1 859]);
sensorPlot(sensorSplit,'volts hline',[1 859]);

%{
ieNewGraphWin; 
imagesc(sensorSplit.metadata.npixels); colormap(jet(4)); truesize;
colorbar;
%}

%% image process?

ip = ipCreate;
ip = ipCompute(ip,sensorSplit);
ipWindow(ip);

ip = ipCompute(ip,sensorRGB);
ipWindow(ip,'render flag','rgb','gamma',0.3);

%% Now the RGBW, which will become a function

% Not working yet.  I think the network is trained on the ar0132at
% 'rgbw' sensor, so that part is OK.  But maybe I need to update the
% network on my local machine?  Asking Zhenyi.
%
% The ipCompute command should become something like
%
%   ipCompute(ip,sensorRGBW,'neural network','ar0132at-rgbw');
%
% Then we switch to the calculation below inside of ipCompute() 
%

