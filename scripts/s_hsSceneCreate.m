% s_hsSceneCreate
%
% This will turn into a function, something like
%
% function scene = hsSceneCreate(imageID,lstDir,dynamicRange,lowLight);
%

%%  These are all the scenes BW processed.

% We need a different version of this, probably threw Andrew's database.
lst = hsSceneDescriptions('print',false);

%%
% '1112201236' - Good one

imageID = lst(5).id;
% lstDir = '/Volumes/TOSHIBA EXT/isetdata/lightgroups';  % Office disk
lstDir = '/Volumes/Wandell/Data/lightgroups';  % Home disk

fname = fullfile(lstDir,sprintf('HDR-scenes-%s',imageID));
load(fname,'scenes','sceneMeta');

%%
dynamicRange = 10^5;
lowLight = 10;
scene = lightGroupDynamicRangeSet(scenes, dynamicRange, lowLight);

%% Edit the scene by cropping and denoising

% Crop here ..

% Denoise here
scene = piAIdenoise(scene);

%% Adjust scene parameters and show in window

scene = sceneSet(scene,'fov',40);   % I cropped the big scene down.
scene = sceneSet(scene,'depth map',sceneMeta.depthMap);
metadata = rmfield(sceneMeta,'depthMap');
scene = sceneSet(scene,'metadata',metadata);
sceneWindow(scene);

%%
%{
[oi,wvf] = oiCreate('wvf');
[aperture, params] = wvfAperture(wvf,'nsides',3,...
    'dot mean',50, 'dot sd',20, 'dot opacity',0.5,'dot radius',5,...
    'line mean',50, 'line sd', 20, 'line opacity',0.5,'linewidth',2);

oi = oiSet(oi,'wvf zcoeffs',0,'defocus');
oi = oiCompute(oi, scene,'aperture',aperture,'crop',true, 'pixel size',3e-6);
%}
%{
% Plotting this scene with oi gamma set to 0.3;
% 1112201236
oiWindow(oi);
oi = oiSet(oi,'gamma',0.3);
[udata, hdl ] = oiPlot(oi,'hline illuminance',[1,564],'no figure');
rgb = oiGet(oi,'rgb');
[r,c,w] = size(rgb);
ieNewGraphWin; imagesc(rgb); axis image;
hold on;
thisL = line([1 1925],[564 564],'Color','g','LineStyle','--');
thisL.LineWidth = 0.1;
yyaxis right;
plot(1:numel(udata.data),udata.data,'w-');
ax = gca; ax.YAxis(2).Scale = 'log'; ax.YAxis(2).Limits = [10^-2,10^11];
ylabel('Log10 Illuminance');
set(gcf,'Position',[0.0070    0.3986    0.4825    0.5114]);
yTick = get(gca,'ytick');
set(gca,'ytick',yTick(1:4))
%}