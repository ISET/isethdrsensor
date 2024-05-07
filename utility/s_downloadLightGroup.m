%% How to download a light group
%
% The light group will be downloaded into

%%  Choose a remote light gruop

% The metadata and the rendered images
user = 'wandell';
host = 'orange.stanford.edu';

% Look in the metadata directory on orang
% Prepare the local directory
imageID = '1114011756';
% 1114091636 - People on street
% 1114011756 - Vans moving away, person
% 1113094429

lgt = {'headlights','streetlights','otherlights','skymap'};
destPath = fullfile(isethdrsensorRootPath,'data',imageID);

%% Download the four light group EXR files and make them into scenes

if ~exist(destPath,'dir'), mkdir(destPath); end

% First the metadata
metaFolder = '/acorn/data/iset/isetauto/Ford/SceneMetadata';
src  = fullfile(metaFolder,[imageID,'.mat']);
ieSCP(user,host,src,destPath);
load(fullfile(destPath,[imageID,'.mat']),'sceneMeta');

% The the radiance EXR files
for ll = 1:numel(lgt)
    thisFile = sprintf('%s_%s.exr',imageID,lgt{ll});
    srcFile  = fullfile(sceneMeta.datasetFolder,thisFile);
    destFile = fullfile(destPath,thisFile);
    ieSCP(user,host,srcFile,destFile);
end

%%
