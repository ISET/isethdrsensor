% s_hsSceneCreate
%
% This will turn into a function, something like
%
% function scene = hsSceneCreate(imageID,lstDir,dynamicRange,lowLight);
%

lst = hsSceneDescriptions('print',false);

imageID = lst(7).id;
% lstDir = '/Volumes/TOSHIBA EXT/isetdata/lightgroups';
lstDir = '/Volumes/Wandell/Data/lightgroups';

fname = fullfile(lstDir,sprintf('HDR-scenes-%s',imageID));
load(fname,'scenes','sceneMeta');

dynamicRange = 10^5;
lowLight = 10;
scene = lightGroupDynamicRangeSet(scenes, dynamicRange, lowLight);

% Crop here ..

% Denoise here
scene = piAIdenoise(scene);

scene = sceneSet(scene,'fov',40);   % I cropped the big scene down.
scene = sceneSet(scene,'depth map',sceneMeta.depthMap);
metadata = rmfield(sceneMeta,'depthMap');
scene = sceneSet(scene,'metadata',metadata);
sceneWindow(scene);

%%