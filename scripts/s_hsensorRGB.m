%% Illustrate HDR imaging problems
%
% This script reads a group of simulated scenes from the data stored
% on acorn. The group separates the scene into four components, each
% with a different light (headlights, streetlights, other lights,
% skymap).  We call this representation the light gruop.
%
% This is the folder on acron contaning the scene groups
%   metaFolder = '/acorn/data/iset/isetauto/Ford/SceneMetadata';
%
% See also
%  s_autoLightGroups (isetauto)

%%
ieInit;

%%  Specify the file


% Use the script s_downloadLightGroup to add to this list

imageID = '1114011756';
% 1114091636 - People on street
% 1114011756 - Vans moving away, person
% 1113094429
%

lgt = {'headlights','streetlights','otherlights','skymap'};
destPath = fullfile(isethdrsensorRootPath,'data',imageID);

%% Load up the scenes from the downloaded directory

scenes = cell(numel(lgt,1));
for ll = 1:numel(lgt)
    thisFile = sprintf('%s_%s.exr',imageID,lgt{ll});
    destFile = fullfile(destPath,thisFile);
    scenes{ll} = piEXR2ISET(destFile);
end

%%  Create a merged radiance scene
% head, street, other, sky
% wgts = [0.1, 0.1, 0.02, 0.001]; % night

wgts = [0.02, 0.1, 0.02, 0.00001]; % night
scene = sceneAdd(scenes, wgts);
scene.metadata.wgts = wgts;

%% Denoise and show
%{
 sceneWindow(scene);
 scene = sceneSet(scene,'render flag','hdr');
 scene = sceneSet(scene,'gamma',1);
%}

%{
 lum = sceneGet(scene,'luminance');
 ieNewGraphWin; mesh(log10(lum));
%}

%% If you want, crop out the headlight region of the scene for testing
%
% You can do this in the window, get the scene, and find the crop
%
% sceneHeadlight = ieGetObject('scene'); 
%
% TODO:  Add crop to the scene window pull down.
%

form = [1 1 511 511];
switch imageID
    case '1114011756'
        % Focused on the person
        rect = [890   370 0 0] + form;  % 1114011756
        thisScene = sceneCrop(scene,rect);
    case '1114091636'
        % This is an example crop for the headlights on the green car.
        rect = [270   351   533   528];  % 1114091636
        thisScene = sceneCrop(scene,rect);
    otherwise
        error('Unknown imageID')
end

%% We could convert the scene via wvf in various ways
if ~exist('thisScene','var'), thisScene = scene; end

thisScene = piAIdenoise(thisScene);
ieAddObject(thisScene);
sceneWindow(thisScene);

%%
[oi,wvf] = oiCreate('wvf');
[aperture, params] = wvfAperture(wvf,'nsides',3,...
    'dot mean',50, 'dot sd',20, 'dot opacity',0.5,'dot radius',5,...
    'line mean',50, 'line sd', 20, 'line opacity',0.5,'linewidth',2);

oi = oiSet(oi,'wvf zcoeffs',0,'defocus');
oi = oiCompute(oi, thisScene,'aperture',aperture,'crop',true);
%{
oiWindow(oi);
oi = oiSet(oi,'render flag','hdr');
oi = oiSet(oi,'gamma',1);
%}

%%  Create the ip and the default ISETAuto sensor

exrDir = fullfile(isethdrsensorRootPath,'local','exr',string(datetime('today')));
if ~exist(exrDir,'dir'), mkdir(exrDir); end

% Note the hour and time
[HH,mm] = hms(datetime('now')); 

[ip, sensor] = piRadiance2RGB(oi,'etime',1/60,'analoggain',1/10,'quantization','12bit');
ipWindow(ip);

%% Save sensor data in EXR file
rgbName = sprintf('%02dH%02dS-RGB-%.2f.exr',uint8(HH),uint8(mm),sensorGet(sensor,'exp time','ms'));
sensor2EXR(sensor,fullfile(exrDir,rgbName))

%% Turn off the noise and recompute

sensor = sensorSet(sensor,'noiseFlag',0);
sensor = sensorSet(sensor,'name','noise free');
sensor = sensorCompute(sensor,oi);

ip = ipCompute(ip,sensor);
ipWindow(ip);

%%
rgbName = sprintf('%02dH%02dS-RGB-NoNoise-%.2f.exr',uint8(HH),uint8(mm),sensorGet(sensor,'exp time','ms'));
sensor2EXR(sensor,fullfile(exrDir,rgbName))

%%  Use the RGBW sensor

sensorRGBW = sensorCreate('rgbw');
sensorRGBW = sensorSet(sensorRGBW,'match oi',oi);
sensorRGBW = sensorSet(sensorRGBW,'name','rgbw');

%{
qe = sensorGet(sensorRGBW,'spectral qe');
cond(qe)
%}

expDuration = [1/15, 1/30, 1/60];
fname = cell(numel(expDuration),1);

for dd = 1:numel(expDuration)
    sensorRGBW = sensorSet(sensorRGBW,'exp time',expDuration(dd));
    sensorRGBW = sensorCompute(sensorRGBW,oi);    
    fname{dd} = sprintf('%02dH%02dS-RGBW-%.2f.exr',uint8(HH),uint8(mm),sensorGet(sensorRGBW,'exp time','ms'));
    fname = sensor2EXR(sensorRGBW,fullfile(exrDir,fname{dd}));

    ip = ipCompute(ip,sensorRGBW);  % It would be nice to not have to run the whole thing
    ip = ipSet(ip,'transform method','adaptive');
    ip = ipSet(ip,'demosaic method','bilinear');
    illE = sceneGet(scene,'illuminant energy');
    ip = ipSet(ip,'render whitept',illE, sensorRGBW);
    ip = ipCompute(ip,sensorRGBW);
    ip = ipSet(ip,'name',sprintf('RGBW-%.3f',expDuration(dd)));
    ipWindow(ip);
end

%%
