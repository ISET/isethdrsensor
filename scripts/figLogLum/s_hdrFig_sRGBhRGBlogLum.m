%% HDR pseudocolor
%
% This is a simple demonstration script that shows how to calculate and
% render an HDR image with the light groups.  It results in a display that
% compares an sRGB, HDR, and pseudocolor rendering of the original scene
% image.
%
% This script requires the lightgroup
%    imageID '1113094429'.  
% 
% We will put the HDR-scenes-1113094429 into the SDR
%
% See Also
%

ieInit;

%%  Specify the scene 

% Use the script s_downloadLightGroup to add more light group scenes
% to this list.  It is OK to make reasonably large versions, IMHO.

imageID = '1113094429';
% 1114091636 - Red/Green cars - Should expand image
% 1114011756 - Vans moving away, person crossing with purse
% 1113094429 - Cyclist in front of truck, red sky.  Works well for
% HDR.
%

lgt = {'headlights','streetlights','otherlights','skymap'};

% Cropped and denoised light group scenes
fname = fullfile(isethdrsensorRootPath,'data',sprintf('HDR-scenes-%s',imageID));
load(fname,'scenes');

%% Set the dynamic range and the level of the dark region (cd/m2 = nits)

dynamicRange = 10^4;
lowLight = 10;
scene = lightGroupDynamicRangeSet(scenes, dynamicRange, lowLight);
scene = sceneSet(scene,'fov',20);   % I cropped the big scene down.
sceneWindow(scene);

%% Sequence of images

scene = sceneSet(scene,'render flag','rgb');
sRGB = sceneGet(scene,'srgb');
sceneSet(scene,'render flag','hdr');
hRGB  = sceneGet(scene,'srgb');
lum = sceneGet(scene,'luminance');
logLum = log10(lum);
logLum = logLum - min(logLum(:));

%% Make a sequence
ieNewGraphWin([],'wide');
tiledlayout(1,3)
nexttile;
imagesc(sRGB); axis image; axis off; subtitle('srgb rendering')
nexttile;
imagesc(hRGB); axis image; axis off; subtitle('HDR rendering')
nexttile;
imagesc(logLum); colormap("parula"); colorbar; axis image; axis off; subtitle('pseudocolor rendering')

%%



