% s_hsSceneCreate

imageID = '1114034742';
lstDir = '/Volumes/TOSHIBA EXT/isetdata/lightgroups';

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