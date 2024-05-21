%% Illustrate HDR with a trained network for the AR0132at RGBW sensor
%
% This script reads a group of simulated scenes from the data stored
% on acorn. The group separates the scene into four components, each
% with a different light (headlights, streetlights, other lights,
% skymap).  We call this representation the light gruop.
%
% This is the folder on acron contaning the scene groups
%   metaFolder = '/acorn/data/iset/isetauto/Ford/SceneMetadata';
%
% See also
%  s_autoLightGroups (isetauto)

% We assume you have the python miniconda environment running
% See s_python
%
% pyenv('Version','/opt/miniconda3/envs/py39/bin/python');
%
% You can check whether it is up by running
%
%   pyversion
%

%%
ieInit;

ieInit

%% Make the scene

% scene = sceneFromFile('Feng_Office-hdrs.mat','spectral');
% scene = sceneCreate('macbeth d65',37);
% scene = sceneCreate('rings rays',5,256);
% scene = sceneCreate('slanted edge',512); scene = sceneSet(scene,'fov',2);
scene = sceneCreate('hdr image','background image',false);


oi = oiCreate('wvf');
wvf    = wvfCreate('spatial samples', 1024);
[aperture, params] = wvfAperture(wvf,'nsides',8,...
    'dot mean',10, 'dot sd',5, 'dot opacity',0.5,'dot radius',5,...
    'line mean',10, 'line sd', 5, 'line opacity',0.5,'linewidth',2);

oi = oiSet(oi,'fnumber',1.7);
oi = oiSet(oi,'focal length',4.38e-3,'m');

oi = oiCompute(oi, scene,'crop',true,'pixel size',1.5e-6,'aperture',aperture);
%%

oiWindow(oi);

