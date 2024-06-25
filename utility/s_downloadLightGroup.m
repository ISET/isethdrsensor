%% Script to download a light group
%
% If the directory for the lightgroup already exists in your
% isethdrsensor/data directory, the download will be skipped.
%
% The light group will be downloaded into your local directory
%
% Use s_hsScenes to create a mat-file with the four scenes that can,
% in turn be used to create a scene.
%
% Then load the four light group scenes directly, as in
%
% fname = fullfile(isethdrsensorRootPath,'local',sprintf('HDR-scenes-%s',imageID));
% load(fname,'scenes');
%
% The lightgroup metadata are here on the NAS
%
%   '/acorn/data/iset/isetauto/Ford/SceneMetadata'
%
% See also
%   s_hsScenes (isethdrsensor)
%

%%  Choose a remote light gruop

%  Add to hsSceneDescriptions when you download a new scene.
lgt = {'headlights','streetlights','otherlights','skymap'};

% The metadata and the rendered images
user    = 'wandell';
host    = 'orange.stanford.edu';

% A list of the scenes I have looked at
lst = hsSceneDescriptions;

%%
for ss = 1:numel(lst)
    imageID = lst(ss).id;

    % The isethdrsensor data directory location

    destPath = fullfile(isethdrsensorRootPath,'data',imageID);
    if exist(destPath,'dir')
        fprintf('Scene %s already downloaded\n',imageID);
    else
        fprintf('Downloading %s ...',imageID);
        mkdir(destPath);

        % Read the metadata file.  This is saved.  It contains a depth
        % map and an instance map and an objectslist
        metaFolder = '/acorn/data/iset/isetauto/Ford/SceneMetadata';
        src  = fullfile(metaFolder,[imageID,'.mat']);
        ieSCP(user,host,src,destPath);
        load(fullfile(destPath,[imageID,'.mat']),'sceneMeta');

        % Use the metadata information to locate and then copy the
        % radiance EXR files in the light group to the destination 
        for ll = 1:numel(lgt)
            thisFile = sprintf('%s_%s.exr',imageID,lgt{ll});
            srcFile  = fullfile(sceneMeta.datasetFolder,thisFile);
            destFile = fullfile(destPath,thisFile);
            ieSCP(user,host,srcFile,destFile);
        end

        fprintf('Done.\n');
    end
end

%% END
