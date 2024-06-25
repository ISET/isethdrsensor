%% Create HDR scene from light groups
%
% Use the script s_downloadLightGroup to get more light group scenes
% on your local computer.
%
% Then convert them to the four scenes using this script.
%
% When you are ready to use these files, you can load the four light group
% scenes directly, as in
%
%   fname = fullfile(isethdrsensorRootPath,'local',sprintf('HDR-scenes-%s',imageID));
%   load(fname,'scenes');
%
% And then you can create a scene with a specific dynamic range and low
% light level using
%
%  dynamicRange = 10^4;
%  lowLight = 10;
%  scene = lightGroupDynamicRangeSet(scenes, dynamicRange, lowLight);
%  scene = sceneSet(scene,'fov',20);   % I cropped the big scene down.
%  ieAddObject(scene);
%
% See also
%   s_autoLightGroups, s_downloadLightGroup, s_hsensorRGB
%

%% Pick one

lgt = {'headlights','streetlights','otherlights','skymap'};
lst = hsSceneDescriptions;

for ii=1:numel(lst)

    imageID = lst(ii).id;
    rect = lst(ii).rect;
    %% We store the names of the groups, too.

    destPath = fullfile(isethdrsensorRootPath,'data',imageID);

    %% Load up the scenes from the downloaded directory

    scenes = cell(numel(lgt,1));
    for ll = 1:numel(lgt)
        thisFile = sprintf('%s_%s.exr',imageID,lgt{ll});
        if ~exist(thisFile,'file'), error('Input file missing'); end                
        scenes{ll} = piEXR2ISET(thisFile);

        % No cropping?
        scenes{ll} = sceneCrop(scenes{ll},rect);
        % sceneWindow(scenes{ll}); sceneSet(scenes{ll},'render flag','hdr');
    end


    %% Save

    fname = fullfile(isethdrsensorRootPath,'local',sprintf('HDR-scenes-%s',imageID));
    save(fname,'scenes','lgt');
    fprintf('Saved file: %s \n',fname)

    %% Load it and look at it

    % {
    fname = fullfile(isethdrsensorRootPath,'local',sprintf('HDR-scenes-%s',imageID));
    load(fname,'scenes');
    %
    % And then you can create a scene with a specific dynamic range and low
    % light level using
    %
    dynamicRange = 10^(5 + rand(1) - 0.5);
    lowLight = 10 + 5*(rand(1) - 0.5);
    scene = lightGroupDynamicRangeSet(scenes, dynamicRange, lowLight);
    scene = piAIdenoise(scene);
    scene = sceneSet(scene,'fov',20);   % I cropped the big scene down.
    % sceneWindow(scene);
    %}

end

%% END