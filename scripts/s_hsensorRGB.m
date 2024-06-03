%% Illustrate HDR with a trained network for the AR0132at RGBW sensor
%
% This script reads a group of simulated scenes from the nighttime driving
% data stored on acorn. Each group separates the scene into four
% components, each with a different light (headlights, streetlights, other
% lights, skymap).  We call this representation the light gruop.
%
% This is the folder on acron contaning the scene light groups
%
%   metaFolder = '/acorn/data/iset/isetauto/Ford/SceneMetadata';
%
% You must have the Python environment installed and the trained networks
%   (s_python, isetDemosaicNN)
%
% See also
%  s_autoLightGroups (isetauto), s_python

%%
ieInit;

%%  Specify the file

% Use the script s_downloadLightGroup to add more light group scenes
% to this list

imageID = '1114091636';
% 1114091636 - People on street
% 1114011756 - Vans moving away, person
% 1113094429
%

lgt = {'headlights','streetlights','otherlights','skymap'};
destPath = fullfile(isethdrsensorRootPath,'data',imageID);
clear thisScene

%% Load up the scenes from the downloaded directory

scenes = cell(numel(lgt,1));
for ll = 1:numel(lgt)
    thisFile = sprintf('%s_%s.exr',imageID,lgt{ll});
    destFile = fullfile(destPath,thisFile);
    scenes{ll} = piEXR2ISET(destFile);
end
disp('Done loading.')

%%  Create a merged radiance scene
% head, street, other, sky
% wgts = [0.1, 0.1, 0.02, 0.001]; % night

wgts = [0.02, 0.1, 0.02, 0.00001]; % night
scene = sceneAdd(scenes, wgts);
scene.metadata.wgts = wgts;
disp('Done adding')
%% If you want, crop out the headlight region of the scene for testing
%
% You can crop in the window, get the scene, and find the crop.  The
% rect will be attached to the scene object.
%
%   sceneHeadlight = ieGetObject('scene');
%

% {
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
disp('Done cropping')
%}

%% We could convert the scene via wvf in various ways
if ~exist('thisScene','var'), thisScene = scene; end

fprintf('Denoising ...');
thisScene = piAIdenoise(thisScene);
% sceneWindow(thisScene);

%% Blur and flare

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

%% Turn off the noise and recompute

%{
sensor = sensorSet(sensor,'noiseFlag',0);
sensor = sensorSet(sensor,'name','noise free');
sensor = sensorCompute(sensor,oi);

ip = ipCompute(ip,sensor);
ipWindow(ip);
%}

%%  Create the two sensor

sensorRGBW = sensorCreate('ar0132at',[],'rgbw');
sensorRGB = sensorCreate('ar0132at',[],'rgb');

%% For each sensor
for ss = 1:2

    if ss==1
        thisSensor = sensorRGBW;
        thisType = 'rgbw';
    elseif ss == 2
        thisSensor = sensorRGB;
        thisType = 'rgb';
    end

    thisSensor = sensorSet(thisSensor,'match oi',oi);
    thisSensor = sensorSet(thisSensor,'name',thisType);

    %{
      qe = sensorGet(thisSensor,'spectral qe');
      cond(qe)
    %}

    % Shorter durations have more noise.
    expDuration = [1/30 1/60 1/120];
    
    fname = cell(numel(expDuration),1);
    fprintf('Creating EXR ...');
    for dd = 1:numel(expDuration)
        thisSensor = sensorSet(thisSensor,'exp time',expDuration(dd));
        thisSensor = sensorCompute(thisSensor,oi);
        fname{dd}  = sprintf('%02dH%02dS-%s-%.2f.exr',uint8(HH),uint8(mm),thisType,sensorGet(thisSensor,'exp time','ms'));
        fname{dd}  = sensor2EXR(thisSensor,fullfile(exrDir,fname{dd}));
    end
    disp('done.')

    % Demosaic the RGBW using the trained Restormer network

    % Run demosaic on each of the sensor EXR files. Write them out to a
    % corresponding ipEXR file.
    ipEXR = cell(1,numel(expDuration));
    for ii=1:numel(expDuration)
        fprintf('Scene %d: ',ii);
        [p,n,ext] = fileparts(fname{ii});
        ipEXR{ii} = sprintf('%s-ip%s',fullfile(p,n),ext);
        isetDemosaicNN(thisType, fname{ii}, ipEXR{ii});
    end

    % Find the combined transform for the RGB sensors

    ip = ipCreate;

    % Create the rendering transforms
    wave     = sensorGet(thisSensor,'wave');
    sensorQE = sensorGet(thisSensor,'spectral qe');
    targetQE = ieReadSpectra('xyzQuanta',wave);
    T{1} = imageSensorTransform(sensorQE(:,1:3),targetQE,'D65',wave,'mcc');
    T{2} = eye(3,3);
    T{3} = ieInternal2Display(ip);

    ip = ipSet(ip,'demosaic method','skip');
    ip = ipSet(ip,'transforms',T);
    ip = ipSet(ip,'transform method','current');

    for ii=1:numel(ipEXR)
        img = exrread(ipEXR{ii});

        ip = ipSet(ip,'sensor space',img);

        ip = ipCompute(ip,thisSensor);
        [~,ipName] = fileparts(ipEXR{ii});
        ip = ipSet(ip','name',ipName);
        ipWindow(ip);
    end

end

%% Try some ipPlots

% Note that in the dark regions, there is more noise in the RGB thasn the
% RGBW.  Not earthshaking, but real. Mostly visible for the short duration
% cases, where there is more noise altogether.

vcSetSelectedObject('ip',7);   % RGBW
ip = ieGetObject('ip'); [uDataRGBW,hdlRGBW] = ipPlot(ip,'horizontal line', [1,470]);

vcSetSelectedObject('ip',8);   % RGB
ip = ieGetObject('ip'); [uDataRGB,hdlRGB] = ipPlot(ip,'horizontal line', [1,470]);

nChildren = 3;
for ii=1:nChildren
    set(hdlRGBW.Children(ii),'ylim',[0 10^-2]);
    set(hdlRGB.Children(ii),'ylim',[0 10^-2]);
end

%%