%%  Specify the file
%
% Use the script s_downloadLightGroup to get more light group scenes
% on your local computer.
%
% Then convert them to the four scenes using this script.
%
% Then load the four light group scenes directly, as in 
%
% fname = fullfile(isethdrsensorRootPath,'local',sprintf('HDR-scenes-%s',imageID));
% load(fname,'scenes');
% (The lgt group names are stored, too).
%
% See also
%   s_autoLightGroups, s_downloadLightGroup, s_hsensorRGB
%

%% Pick one

% imageID = '1113094429'; rect = [196 58 1239 752];
% imageID = '1114011756'; rect = [891 371 511 511];  
% imageID = '1114091636'; rect = [270  351 533 528];

%% We store the names of the groups, too.

lgt = {'headlights','streetlights','otherlights','skymap'};
destPath = fullfile(isethdrsensorRootPath,'data',imageID);

%% Load up the scenes from the downloaded directory

scenes = cell(numel(lgt,1));
for ll = 1:numel(lgt)
    thisFile = sprintf('%s_%s.exr',imageID,lgt{ll});
    destFile = fullfile(destPath,thisFile);
    scenes{ll} = piEXR2ISET(destFile);

    scenes{ll} = sceneCrop(scenes{ll},rect);
    scenes{ll} = piAIdenoise(scenes{ll});
    % sceneWindow(scenes{ll}); sceneSet(scenes{ll},'render flag','hdr');
end

%% Save

fname = fullfile(isethdrsensorRootPath,'local',sprintf('HDR-scenes-%s',imageID));
save(fname,'scenes','lgt');
fprintf('Saved file: %s \n',fname)

%% END