% s_hsSceneCreate

imageID = '1112201236';

fname = fullfile(isethdrsensorRootPath,'data',sprintf('HDR-scenes-%s',imageID));
load(fname,'scenes','sceneMeta');

dynamicRange = 10^4;
lowLight = 10;
scene = lightGroupDynamicRangeSet(scenes, dynamicRange, lowLight);

scene = sceneSet(scene,'fov',40);   % I cropped the big scene down.
scene = sceneSet(scene,'depth map',sceneMeta.depthMap);
metadata = rmfield(sceneMeta,'depthMap');
scene = sceneSet(scene,'metadata',metadata);
sceneWindow(scene);

%%