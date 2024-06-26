%% Create HDR scene from light groups
%
% Use the script s_downloadLightGroup to get more light group scenes
% on your local computer.
%
% Then convert them to the four scenes and the metadata using this
% script. The scenes are also stored in isethdrsensor/data
%
% To create a specific scene use s_hsSceneCreate
%
% See also
%   s_autoLightGroups, s_downloadLightGroup, s_hsensorRGB
%

%% See what is downloaded

% BW Uses:
% lstDir = '/Volumes/TOSHIBA EXT/isetdata/lightgroups';
lstDir = '/Volumes/Wandell/Data/lightgroups';

%% Others will use other directories

lgt = {'headlights','streetlights','otherlights','skymap'};
lst = dir(fullfile(lstDir,'11*'));

%%
for ii=1:numel(lst)

    imageID = lst(ii).name;
    fname = fullfile(lstDir,sprintf('HDR-scenes-%s.mat',imageID));

    if ~exist(fname,'file')
        fprintf('Creating %s ...',fname);

        imageID = lst(ii).name;
        load(fullfile(lstDir,imageID,[imageID,'.mat']),'sceneMeta');

        % We store the names of the groups, too.
        destPath = fullfile(isethdrsensorRootPath,'data',imageID);

        %% Load up the 4 scenes from the downloaded directory
        scenes = cell(numel(lgt,1));
        for ll = 1:numel(lgt)
            thisFile = sprintf('%s_%s.exr',imageID,lgt{ll});
            if ~exist(thisFile,'file'), error('Input file missing'); end
            scenes{ll} = piEXR2ISET(thisFile);
        end

        %% Save
        save(fname,'scenes','sceneMeta','lgt');
        fprintf('done.\n')
    else
        fprintf('%s exists\n',fname);
    end

end


%% END