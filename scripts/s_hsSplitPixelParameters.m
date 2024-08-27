%% Scratch script
%
% Just typing and looking.  Nothing for most to see here.
%
% Vary the parameters in the split pixel design.
%
% Try different scenes
%
% Not started yet.  Will shift the split pixel parameters around to
% see which relative gain is best.
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

% imageID = '1112201236'; % - Good one
imageID = '1114091636';   % Red car, green car

%% Day scene weights

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

%%  If you want the oiDay, this is how

%{
wgts = [0    0     0    100*0.5175]; % Day
scene = hsSceneCreate(imageID,'weights',wgts,'denoise',false);
oiDay = oiCompute(oi, scene,'aperture',aperture,'crop',true,'pixel size',3e-6);
oiWindow(oiDay,'gamma',0.5,'render flag','rgb');
srgb = oiGet(oiDay,'rgb'); ieNewGraphWin; image(srgb); truesize
%}

%% Night scene weights

% For final, remember to turn off denoise

% Experimenting with how dark.  4 log units down gets night
% But three really doesn't.
wgts    = [0.2306    0.0012    0.0001    1e-2*0.5175]; % Night
scene   = hsSceneCreate(imageID,'weights',wgts,'denoise',true);
oiNight = oiCompute(oi, scene,'aperture',aperture,'crop',true,'pixel size',3e-6);
oiWindow(oiNight,'render flag','rgb','gamma',0.2);

% save(sprintf('oiNight-%d',imageID),'oiNight');

%% Standard automotive rgb

% To speed things up
% load(sprintf('oiNight-%d',imageID),'oiNight');

%% Split pixel parameters

pixelSize = 3e-6;
sensorSize = [1082 1926];
sensorArray = sensorCreateArray('array type','imx490',...
    'pixel size same fill factor',pixelSize,...
    'exp time',16e-3, ...
    'size',sensorSize);

sensorSplit = sensorComputeArray(sensorArray,oiNight);
% sensorWindow(sensorSplit,'gamma',0.3);
%{
 rgb = sensorGet(sensorSplit,'rgb');
 ieNewGraphWin; imagesc(rgb); truesize;
%}

%% image process?

ip = ipCreate;
ip = ipCompute(ip,sensorSplit);
ipWindow(ip,'render flag','rgb','gamma',0.3);

%% Here are some key parameters

% The 'ovt' model has 
for ii=1:4
    fprintf('Sensor %d : Well %g, Volt S %g, Conv Gain %g\n',...
        ii, ...
        sensorGet(sensorArray(ii),'pixel well capacity'),   ...
        sensorGet(sensorArray(ii),'pixel voltage swing'), ...
    sensorGet(sensorArray(ii),'pixel conversion gain'));
end

%% Default IMX490

sensorArray = sensorCreateArray('array type','imx490',...
    'pixel size same fill factor',pixelSize,...
    'exp time',16e-3, ...
    'size',sensorSize);

for ii=1:4
    fprintf('Sensor %d : Well %g, Volt S %g, Conv Gain %g\n',...
        ii, ...
        sensorGet(sensorArray(ii),'pixel well capacity'),   ...
        sensorGet(sensorArray(ii),'pixel voltage swing'), ...
    sensorGet(sensorArray(ii),'pixel conversion gain'));
end

%% Can we set the well capacity to be equal in all?

% We don't really talk about well capacity enough in the paper.

% We can set conversion gain and voltage swing
%
% This implies the well capacity.
% I think we should be dealing with spectral QE and analog gain, not
% conversion gain.
wellCapacity = 6e+4;
voltageSwing = 1.024;
conversionGain = voltageSwing/wellCapacity;
sensorArray = sensorCreateArray('array type','imx490',...
    'pixel size same fill factor',pixelSize,...
    'exp time',16e-3, ...
    'size',sensorSize, ...
    'pixel conversion gain',conversionGain);

for ii=1:4
    fprintf('%s : Well %g, Volt S %g, Conv Gain %g\n',...
        sensorGet(sensorArray(ii),'name'), ...
        sensorGet(sensorArray(ii),'pixel well capacity'),   ...
        sensorGet(sensorArray(ii),'pixel voltage swing'), ...
        sensorGet(sensorArray(ii),'pixel conversion gain'));
end

%% END
