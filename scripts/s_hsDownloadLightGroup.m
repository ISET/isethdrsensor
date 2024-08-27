%% Script to download all the light groups on acorn to isethdrsensor/data
%
%              ** This script is for Wandell Lab only **  
% 
% Others use ieWebGet() methods from the Stanford Data Repository.
% See s_hsFig_LightGroups.mlx for an example.
%
%% The light group data for the wandell lab
% 
% The data are stored on orange as EXR files in two places.  One is
% the metadata:
%
%  metaFolder = '/acorn/data/iset/isetauto/Ford/SceneMetadata';
%
% The files in the metaFolder specify where the light group EXR files
% are stored on orange.
%
% If the directory for the lightgroup already exists in your
% isethdrsensor/data directory, the download is skipped.
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
%   s_hsScenes, hsDownloadLightGroup

%%  Choose a remote light gruop

%  Add to hsSceneDescriptions when you download a new scene.
lgt = {'headlights','streetlights','otherlights','skymap'};

% The metadata and the rendered images
user    = 'wandell';
host    = 'orange.stanford.edu';

% A list of the scenes I have looked at
lst = hsSceneDescriptions;

% But you could use a list of imageID values that you curate by hand.
%
%%
for ss = 1:numel(lst)
    imageID = lst(ss).id;
    % The isethdrsensor data directory location

    destPath = fullfile(isethdrsensorRootPath,'data',imageID);
    if exist(destPath,'dir')
        fprintf('Scene %s already downloaded\n',imageID);
    else
        fprintf('Downloading %s ...',imageID);
        hsDownloadLightGroup(imageID,user,host);
        mkdir(destPath);
    end
end

%% END
