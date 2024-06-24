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

%%  Choose a remote light gruop

% The metadata and the rendered images
user = 'wandell';
host = 'orange.stanford.edu';

%  MORE TO COME AS THE PAPER EVOLVES
% Look in the metadata directory on orange
%
% Prepare the local directory
imageID = '1113165019';
% 1114034742 - Motorcyle, people walking not very nice
% 1114091636 - People on street
% 1114011756 - Vans moving away, person
% 1113094429 - Truck and nice late afternoon
% 1112201236 - Open highway scene
% 1113042919 - Blue car, person, motorcyle, yellow bus
% 1112213036 - Lousy.
% 1113040557 - Lousy.  Truck and people
% 1113051533 - Hard to get light levels right
% 1112220258
% 1113164929
% 1113165019
% 1114043928
% 1114120530 - Lady on a motorcycle in front of a truck
%
lgt = {'headlights','streetlights','otherlights','skymap'};
destPath = fullfile(isethdrsensorRootPath,'data',imageID);

%% Download the four light group EXR files and make them into scenes

if ~exist(destPath,'dir'), mkdir(destPath); end

% First the metadata
metaFolder = '/acorn/data/iset/isetauto/Ford/SceneMetadata';
src  = fullfile(metaFolder,[imageID,'.mat']);
ieSCP(user,host,src,destPath);
load(fullfile(destPath,[imageID,'.mat']),'sceneMeta');

% The radiance EXR files in the light grup
for ll = 1:numel(lgt)
    thisFile = sprintf('%s_%s.exr',imageID,lgt{ll});
    srcFile  = fullfile(sceneMeta.datasetFolder,thisFile);
    destFile = fullfile(destPath,thisFile);
    ieSCP(user,host,srcFile,destFile);
end

%%

%% END
