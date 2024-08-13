imageID = '1114031438';

lgt = {'headlights','streetlights','otherlights','skymap'};
destPath = fullfile(isethdrsensorRootPath,'data',imageID);

scenes = cell(numel(lgt,1));
for ll = 1:numel(lgt)
    thisFile = sprintf('%s_%s.exr',imageID,lgt{ll});
    destFile = fullfile(destPath,thisFile);
    scenes{ll} = piEXR2ISET(destFile);
end
disp('Done loading.')
%% Night
wgts_night = [3.0114    0.0378    0.0498    0.0030];
scene = sceneAdd(scenes, wgts_night);
thisScene = piAIdenoise(scene);

[oi,wvf] = oiCreate('wvf');
wvf = wvfSet(wvf, 'spatial samples',512);
[aperture, params] = wvfAperture(wvf,'nsides',0,...
    'dot mean',0, 'dot sd',0, 'dot opacity',0.5,'dot radius',5,...
    'line mean',0, 'line sd', 0, 'line opacity',0,'linewidth',2);
oi = oiCompute(oi, thisScene,'aperture',aperture,'crop',true,'pixel size',3e-6);

sensorRGB = sensorCreate('ar0132at',[],'rgb');

sensorRGB = sensorSet(sensorRGB,'match oi',oi);
ip = ipCreate;
sensorRGB = sensorSet(sensorRGB,'exp time',0.005);
sensor = sensorCompute(sensorRGB, oi);
ip = ipCompute(ip,sensor);ipWindow(ip);
srgb = ipGet(ip, 'srgb');imwrite(srgb,'~/Desktop/expLow.png');

sensorRGB = sensorSet(sensorRGB,'exp time',0.0405);
sensor = sensorCompute(sensorRGB, oi);
ip = ipCompute(ip,sensor);ipWindow(ip);
srgb = ipGet(ip, 'srgb');imwrite(srgb,'~/Desktop/expMid.png');

sensorRGB = sensorSet(sensorRGB,'exp time',0.3242);
sensor = sensorCompute(sensorRGB, oi);
ip = ipCompute(ip,sensor);ipWindow(ip);
srgb = ipGet(ip, 'srgb');imwrite(srgb,'~/Desktop/expLong.png');

