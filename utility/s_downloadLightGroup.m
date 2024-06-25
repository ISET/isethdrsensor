%% How to download a light group
%
% The light group will be downloaded into your local directory
%
% You can use s_hsScenes to create a file with the four scenes
%
% Then load the four light group scenes directly, as in 
%
% fname = fullfile(isethdrsensorRootPath,'local',sprintf('HDR-scenes-%s',imageID));
% load(fname,'scenes');
%
% '/acorn/data/iset/isetauto/Ford/SceneMetadata'
%
% See also
%   s_hsScenes (
%

%%  Choose a remote light gruop

%  Add to hsSceneDescriptions when you download a new scene.

lgt = {'headlights','streetlights','otherlights','skymap'};

% The metadata and the rendered images
user = 'wandell';
host = 'orange.stanford.edu';
imageID = '1113165019';

% Prepare the local directory
destPath = fullfile(isethdrsensorRootPath,'data',imageID);

%% Download the four light group EXR files and make them into scenes

if ~exist(destPath,'dir'), mkdir(destPath); end

% Read the metadata file on orange.  This is saved.  It contains a
% depth map and an instance map and an objectslist
metaFolder = '/acorn/data/iset/isetauto/Ford/SceneMetadata';
src  = fullfile(metaFolder,[imageID,'.mat']);
ieSCP(user,host,src,destPath);
load(fullfile(destPath,[imageID,'.mat']),'sceneMeta');

% Copy the radiance EXR files in the light group to the destination
for ll = 1:numel(lgt)
    thisFile = sprintf('%s_%s.exr',imageID,lgt{ll});
    srcFile  = fullfile(sceneMeta.datasetFolder,thisFile);
    destFile = fullfile(destPath,thisFile);
    ieSCP(user,host,srcFile,destFile);
end

%% END
