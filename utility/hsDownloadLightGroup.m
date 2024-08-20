function destPath = hsDownloadLightGroup(imageID, user, host)
% Download a light group to the isethdrsensor data directory
%
% Description
%   If you have a user and host access to the light groups on acorn,
%   you can use this function to download a light group into
%   isethdrsensor.  (Most people do not have access).
%
% Inputs
%
% Optional key/val
%
% Return
%
%
% See also
%  

% Example:
%{
% The metadata and the rendered images
user    = 'wandell';
host    = 'orange.stanford.edu';
destPath = hsDownloadLightGroup(imageID, user, host);
%}

% The isethdrsensor data directory location
destPath = fullfile(isethdrsensorRootPath,'data',imageID);
lgt = {'headlights','streetlights','otherlights','skymap'};

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

