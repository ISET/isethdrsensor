%% Demosaic with a trained Restormer network
%
% See h_sensorRGB and H-hsTestCharts

%% Set up ISET and the Python environment
ieInit;

% Each user would have this somewhere in their own compute environment
%{
In the terminal, you need to set up the environment to have the
methods that are necessary to run the PyTorch model.  The file
requirements.txt is in utility/python.

  conda activate py39
  pip install -r requirements.txt

%}

%{
 pyenv('Version','/opt/miniconda3/envs/py39/bin/python');
%}


%% We need a scene and an OI
%
scene = sceneFromFile('Feng_Office-hdrs.mat','spectral');

oi = oiCreate('wvf');
% oi = oiSet(oi,'optics model','shift invariant');

wvf    = wvfCreate('spatial samples', 1024);
[aperture, params] = wvfAperture(wvf,'nsides',8,...
    'dot mean',10, 'dot sd',5, 'dot opacity',0.5,'dot radius',5,...
    'line mean',10, 'line sd', 5, 'line opacity',0.5,'linewidth',2);

oi = oiSet(oi,'fnumber',1.7);
oi = oiSet(oi,'focal length',4.38e-3,'m');

oi = oiCompute(oi, scene,'crop',true,'pixel size',1.5e-6,'aperture',aperture);

% oiWindow(oi);

%%
[ip,sensorRGBW] = piRadiance2RGB(oi,'sensor','ar0132atSensorRGBW', ...
    'etime',1/200,'noiseflag',2, ...
    'pixelsize',1.5,'analoggain',1/20);

%% Set up the demosaicing for the RGBW path

sensorEXR_path = fullfile(isethdrsensorRootPath,'local','tmp.exr');
[fname,rgbw]   = sensor2EXR(sensor,sensorEXR_path,'data type','volts','data format','noisyrgb');
exrFile    = fullfile(isethdrsensorRootPath,'local','tmp_output.exr');
[result, exrFile] = isetDemosaicNN('rgbw', sensorEXR_path, exrFile);

%% Show the RGB version

[ip,sensorRGB] = piRadiance2RGB(oi,'sensor','ar0132atSensorRGB', ...
    'etime',1/200,'noiseflag',2, ...
    'pixelsize',1.5,'analoggain',1/20);
img = Demosaic(ip,sensor);
ipRGB = ipSet(ip,'display linear rgb',img);
ipRGB = ipSet(ipRGB,'name','rgb');
ipWindow(ipRGB);
srgb = ipGet(ipRGB,'srgb');

%% Show the rendered rgbw
data = exrread(exrFile);
ipRGBW = ipSet(ip,'display linear rgb',data);
ipRGBW = ipSet(ipRGBW,'name','rgbw');

ipWindow(ipRGBW);
srgbw = ipGet(ipRGBW,'srgb');
ieNewGraphWin; imagesc(srgb);
ieNewGraphWin; imagesc(srgbw);


%% Show the images in sRGB space

img = img/max(img(:));
img = lin2rgb(img/max(img(:)));
figure;imshow(img);

data = lin2rgb(data);
figure;imshow(data);

%%