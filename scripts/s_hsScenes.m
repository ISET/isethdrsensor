%% Create HDR scene from light groups
%
%   ** Wandell lab script only **
%
%% Create an HDR-Scenes file for your convenience
%
% Use the script s_downloadLightGroup to get light group EXR files on
% your local computer. The specifications of the light group EXR files
% is based on a numeric string, we call the imageID. 
%
% This script uses the metadata to find the specific files.  It
% downloads the EXR files and converts them to the four scenes, saving
% them and the metadata. The scenes are stored in your local directory
% as a file within isethdrsensor/data with a name created as
%
%   lstDir = fullfile(isethdrsensorRootPath,'data');
%   fname = fullfile(lstDir,sprintf('HDR-scenes-%s.mat',imageID));
%
% See also
%   s_autoLightGroups, s_downloadLightGroup, s_hsensorRGB
%

%% See what is downloaded

% BW also uses the data on the TOSHIBA drive:
% lstDir = '/Volumes/TOSHIBA EXT/isetdata/lightgroups';
% There should be data available through mount of orange.
lstDir = fullfile(isethdrsensorRootPath,'data');
% Others will use other directories

lgt = {'headlights','streetlights','otherlights','skymap'};
lst = dir(fullfile(lstDir,'11*'));

%%
for ii=1:numel(lst)

    imageID = lst(ii).name;
    fname = fullfile(lstDir,sprintf('HDR-scenes-%s.mat',imageID));
    rect = [270 270 512 512];

    if ~exist(fname,'file')
        fprintf('Creating %s ...',fname);

        % imageID = lst(ii).name;
        load(fullfile(lstDir,imageID,[imageID,'.mat']),'sceneMeta');

        % We store the names of the groups, too.
        destPath = fullfile(isethdrsensorRootPath,'data',imageID);

        %% Load up the 4 scenes from the downloaded directory
        scenes = cell(numel(lgt,1));
        for ll = 1:numel(lgt)
            thisFile = sprintf('%s_%s.exr',imageID,lgt{ll});
            if ~exist(thisFile,'file'), error('Input file missing'); end
            scenes{ll} = piEXR2ISET(thisFile);
            if ~isempty(rect)
                scenes{ll} = sceneCrop(scenes{ll},rect);
            end
        end

        %% Save
        save(fname,'scenes','sceneMeta','lgt');
        fprintf('done.\n')
    else
        fprintf('%s exists\n',fname);
    end

end


%% END