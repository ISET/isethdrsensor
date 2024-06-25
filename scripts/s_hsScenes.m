%% Create HDR scene from light groups
%
% Use the script s_downloadLightGroup to get more light group scenes
% on your local computer.
%
% Then convert them to the four scenes and the metadata using this
% script. The scenes are also stored in isethdrsensor/data
%
% To create a specific scene use
%
%  fname = fullfile(isethdrsensorRootPath,'data',sprintf('HDR-scenes-%s',imageID));
%  load(fname,'scenes','sceneMeta);
%
%  dynamicRange = 10^4;
%  lowLight = 10;
%  scene = lightGroupDynamicRangeSet(scenes, dynamicRange, lowLight);
%  scene = sceneSet(scene,'fov',20);   % I cropped the big scene down.
%  scene = sceneSet(scene,'depth map',sceneMeta.depthMap);
%  rmfield(sceneMeta,'depthMap');
%  metadata = sceneMeta;
%  scene = sceneSet(scene,'metadata',metadata);
%  sceneWindow(scene);
%
% See also
%   s_autoLightGroups, s_downloadLightGroup, s_hsensorRGB
%

%% See what is downloaded

lgt = {'headlights','streetlights','otherlights','skymap'};
lstDir = fullfile(isethdrsensorRootPath,'data');
lst = dir(fullfile(lstDir,'11*'));

%%
for ii=1:numel(lst)

    fname = fullfile(isethdrsensorRootPath,'data',sprintf('HDR-scenes-%s',imageID));

    if ~exist(fname,'file')
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
        fprintf('Saved file: %s \n',fname)
    else
        fprintf('%s exists\n',fname);
    end

end


%% END