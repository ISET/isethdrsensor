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
%   data dir -  Directory with the HDR-scenes-* files.  default: 'isethdrsensorRootPath/data'
%   dynamic range:   Scene dynamic range:          Default: 10^4
%   low light -      Dimmest region of the image:  Default: 10 cd/m2
%   denoise -        Denoise after combining:      Default: true
%   rect -           Crop the scene [r,c,height,width] Default: [] (no crop)
%   fov -            Scene horizontal field of view:   Default: 40 deg
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
scene = hsSceneCreate(imageID,'dynamic range',10^5,'low light',10,'denoise',false);
sceneWindow(scene); scene = sceneSet(scene,'gamma',0.3);
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
    error('Light group ID %s not found.\n',imageID);
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

