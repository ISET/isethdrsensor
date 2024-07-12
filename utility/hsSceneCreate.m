function scene = hsSceneCreate(imageID,varargin)
% Create a scene from an HDR light group 
%
% Synopsis
%   scene = hsSceneCreate(imageID,varargin);
%
% Input
%   imageID
%  
% Optional key/val pairs
%   data dir - 'isethdrsensorRootPath/data'
%   dynamic range 10^4
%   low light - 10 cd/m2
%   denoise - true
%   rect - [] (no crop)
%   fov -  40 deg default
%
% Return
%    scene
%
% See also
%  s_downloadLightGroup, s_hsSceneCreate, s_hsScenes
%  s_autoLightGroups (isetauto), 

% Example:
%{
imageID = '1112201236'; % - Good one
scene = hsSceneCreate(imageID,'dynamic range',10^5,'low light',10);
sceneWindow(scene);
%}

%% Inputs

varargin = ieParamFormat(varargin);
p = inputParser;
p.addRequired('imageID',@ischar);
p.addParameter('dynamicrange',10^4,@isscalar);
p.addParameter('lowlight',10,@isscalar);
p.addParameter('datadir',fullfile(isethdrsensorRootPath,'data'),@(x)(exist(x,'dir')));
p.addParameter('rect',[],@isvector);
p.addParameter('denoise',true,@islogical);
p.addParameter('fov',40,@isscalar);

p.parse(imageID,varargin{:});

%% Load the light group scenes

fname = fullfile(p.Results.datadir,sprintf('HDR-scenes-%s.mat',imageID));
if exist(fname,'file')
    load(fname,'scenes','sceneMeta');
else
    error('%s not found\n');
end

%%  Combine them
scene = lightGroupDynamicRangeSet(scenes, p.Results.dynamicrange, p.Results.lowlight);

%% Edit the scene by cropping and denoising

% Crop here ..
if ~isempty(p.Results.rect)
    scene = sceneCrop(scene,p.Results.rect);
end

% Denoise here
if p.Results.denoise
    fprintf('Denoising ...');
    scene = piAIdenoise(scene);
    fprintf('\n');
end

%% Adjust scene parameters and show in window

scene = sceneSet(scene,'fov',p.Results.fov);   % I cropped the big scene down.
scene = sceneSet(scene,'depth map',sceneMeta.depthMap);
metadata = rmfield(sceneMeta,'depthMap');
scene = sceneSet(scene,'metadata',metadata);

end

