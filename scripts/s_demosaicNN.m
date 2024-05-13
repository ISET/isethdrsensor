
oi = oiCreate('wvf');
% oi = oiSet(oi,'optics model','shift invariant');

wvf    = wvfCreate('spatial samples', 1024);
[aperture, params] = wvfAperture(wvf,'nsides',8,...
    'dot mean',10, 'dot sd',5, 'dot opacity',0.5,'dot radius',5,...
    'line mean',10, 'line sd', 5, 'line opacity',0.5,'linewidth',2);

oi = oiSet(oi,'fnumber',1.7);
oi = oiSet(oi,'focal length',4.38e-3,'m');
oi = oiCompute(oi, scene,'crop',true,'pixel size',1.5e-6,'aperture',aperture);
[ip,sensor] = piRadiance2RGB(oi,'sensor','ar0132atSensorRGBW', ...
    'etime',1/200,'noiseflag',2, ...
    'pixelsize',1.5,'analoggain',1/20);

sensorEXR_path = fullfile(isethdrsensorRootPath,'local','tmp.exr');

[fname,rgbw] = sensor2EXR(sensor,sensorEXR_path,'data type','volts','data format','noisyrgb','noise level',0.01);
%%
output_path = fullfile(isethdrsensorRootPath,'local','tmp_output.exr');

[result, output_path] = isetDemosaicNN('rgbw', sensorEXR_path, output_path);
%%
[ip,sensor] = piRadiance2RGB(oi,'sensor','ar0132atSensorRGB', ...
    'etime',1/200,'noiseflag',2, ...
    'pixelsize',1.5,'analoggain',1/20);
img = Demosaic(ip,sensor);
ip = ipSet(ip,'display linear rgb',img);

ipWindow(ip);
%% rgbw
data = exrread(output_path);
ip = ipSet(ip,'display linear rgb',data);
ipWindow(ip);
ip = ipCreate;
ip = ipCompute(ip,sensor);
ipWindow(ip)
img = img/max(img(:));
img = lin2rgb(img/max(img(:)));figure;imshow(img);
data = lin2rgb(data);figure;imshow(data);