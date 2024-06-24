%%  Specify the file
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

% imageID = '1113094429'; rect = [196 58 1239 752];
% imageID = '1114011756'; rect = [891 371 511 511];  
% imageID = '1114091636'; rect = [270  351 533 528];
% imageID = '1114120530'; rect = [270  351 533 528];
% imageID = '1114043928'; rect = [10  10  540  640];
% imageID = '1113165019'; rect = [256 256  768 512];
% imageID = '1113164929'; rect = [256 256  768 512];
% imageID = '1112220258'; rect = [256 256  768 512];



% 1114034742 - Motorcyle, people walking not very nice
% 1114091636 - People on street
% 1114011756 - Vans moving away, person
% 1113094429 - Truck and nice late afternoon
% 1112201236 - Open highway scene
% 1113042919 - Blue car, person, motorcyle, yellow bus
% 1112213036 - Lousy.
% 1113040557 - Lousy.  Truck and people
% 1113051533 - Hard to get light levels right
% 1112220258 - Curved road with trucks and bicycles and lights
% 1113164929 - One car, one bike, mountain in the road? 
% 1113165019 - Wide, complex highway scene.  Big sky
% 1114043928 - Man in front of the sky
% 1114120530 - Woman in front of a truck

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

%% Load it and look at it

%{
fname = fullfile(isethdrsensorRootPath,'local',sprintf('HDR-scenes-%s',imageID));
load(fname,'scenes');
%
% And then you can create a scene with a specific dynamic range and low
% light level using
%
dynamicRange = 10^6;
lowLight = 10;
scene = lightGroupDynamicRangeSet(scenes, dynamicRange, lowLight);
scene = sceneSet(scene,'fov',20);   % I cropped the big scene down.
sceneWindow(scene);
%}

%% END