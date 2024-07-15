%% RGBW evaluation with test charts with the trained network
%
% See also
%

%%
ieInit

%% Make the scene

% scene = sceneCreate('point array',512,128);
% scene = sceneFromFile('Feng_Office-hdrs.mat','spectral');
% scene = sceneCreate('macbeth d65',37);
% scene = sceneCreate('rings rays',5,256);
% scene = sceneCreate('slanted edge',512); scene = sceneSet(scene,'fov',2);
% scene = sceneCreate('hdr lights');
% woodDuck.png, FruitMCC_6500.tif, cameraman.tif

scene = sceneCreate('hdr image',...
    'npatches',1,...
    'dynamic range',4,...
    'background','FruitMCC_6500.tif',...
    'patch shape','circle', ...
    'patch size',10);

% scene = sceneFromFile('Feng_Office-hdrs.mat','spectral');
scene = sceneSet(scene,'fov',20);

sceneRGB = sceneGet(scene,'srgb');

sceneWindow(scene,'gamma',0.25,'render flag','rgb','show',true);
scenePlot(scene,'luminance hline',[1 474]);
set(gca,'yscale','log');

%%
[oi,wvf] = oiCreate('wvf');
wvf = wvfSet(wvf,'spatial samples',1024);

params = wvfApertureP;
params.nsides = 5;
params.linemean = 5;
aperture = wvfAperture(wvf,params);

oi = oiSet(oi,'fnumber',1.7);
oi = oiSet(oi,'focal length',4.38e-3,'m');

oi = oiCompute(oi, scene,'crop',true,'pixel size',1.5e-6,'aperture',aperture);
% oiWindow(oi);

%% Create the RGBW and RGB sensors

ip = ipCreate;

% sensor = sensorCreate('imx363');
sensor = sensorCreate('ar0132at',[],'rgb');
sensor = sensorSet(sensor,'match oi',oi);
sensor = sensorSet(sensor,'pixel voltage swing',1);

eTime  = autoExposure(oi,sensor,0.95,'luminance');

% [HH,mm] = hms(datetime('now'));

%% Dynamic range
expDuration = logspace(log10(eTime)+1.5,log10(eTime)+3.5,9);
imagecell = cell(numel(expDuration),1);

for dd = 1:numel(expDuration)
    sensor = sensorSet(sensor,'exp time',expDuration(dd));
    sensor = sensorCompute(sensor,oi);
    ip = ipCompute(ip,sensor);
    imagecell{dd} = ipGet(ip,'srgb');         
end

%% Make some comparison images

ieNewGraphWin; imagesc(sceneRGB); axis image; axis off; truesize;

% One of the dark images
ieNewGraphWin; imagesc(imagecell{2}); axis image; axis off; truesize;

% The same scene, but different exposure durations
ieNewGraphWin; montage(imagecell);

%% END