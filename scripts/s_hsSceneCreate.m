% s_hsSceneCreate
%
% This will turn into a function, something like
%
% function scene = hsSceneCreate(imageID,lstDir,dynamicRange,lowLight);
%
% See also
%   How to render at the end
%   s_hsScenes;
%   s_downloadLightGroup
%

lst = hsSceneDescriptions('print',false);

%%
imageID = lst(4).id;
% lstDir = '/Volumes/TOSHIBA EXT/isetdata/lightgroups';
lstDir = '/Volumes/Wandell/Data/lightgroups';

fname = fullfile(lstDir,sprintf('HDR-scenes-%s',imageID));
load(fname,'scenes','sceneMeta');

%%
dynamicRange = 10^5;
lowLight = 10;
scene = lightGroupDynamicRangeSet(scenes, dynamicRange, lowLight);

% Crop here ..

% Denoise here
scene = piAIdenoise(scene);

scene = sceneSet(scene,'fov',40);   % Adjust if you crop
scene = sceneSet(scene,'depth map',sceneMeta.depthMap);
metadata = rmfield(sceneMeta,'depthMap');
scene = sceneSet(scene,'metadata',metadata);

% ieReplaceObject(scene); sceneWindow;
sceneWindow(scene);

%% Go through to sensor and ip

%{
[oi,wvf] = oiCreate('wvf');
[aperture, params] = wvfAperture(wvf,'nsides',3,...
    'dot mean',50, 'dot sd',20, 'dot opacity',0.5,'dot radius',5,...
    'line mean',50, 'line sd', 20, 'line opacity',0.5,'linewidth',2);

oi = oiSet(oi,'wvf zcoeffs',0.1,'defocus');
oi = oiCompute(oi, scene,'aperture',aperture,'crop',true, 'pixel size',3e-6);
oiWindow(oi);
% ieReplaceObject(oi); oiWindow;
%}

%{
sensor = sensorCreate('imx363');
sensor = sensorSet(sensor,'match oi',oi);
sensor = sensorCompute(sensor,oi);
sensorWindow(sensor);
%}

%{
ip = ipCreate;
ip = ipCompute(ip,sensor);
ipWindow(ip);
% ieReplaceObject(ip); ipWindow;
%}