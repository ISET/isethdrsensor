%%  Specify the file

% Use the script s_downloadLightGroup to add more light group scenes
% to this list

% Pick one

% imageID = '1113094429'; rect = [196 58 1239 752];
% imageID = '1114011756'; rect = [891 371 511 511];  
% imageID = '1114091636'; rect = [270  351 533 528];

%%
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
save(fname,'scenes');
fprintf('Saved file: %s \n',fname)

%% END