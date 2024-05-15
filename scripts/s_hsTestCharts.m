%% Test charts with the trained network
%
%

%%
ieInit

%%

% scene = sceneFromFile('Feng_Office-hdrs.mat','spectral');
scene = sceneCreate('macbeth d65',64);
sceneGet(scene,'size')
% scene = sceneSet(scene,'resize',[512 512]);


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

sensorRGBW = sensorCreate('ar0132at',[],'rgbw');
sensorRGBW = sensorSet(sensorRGBW,'match oi',oi);
sensorRGBW = sensorSet(sensorRGBW,'name','rgbw');

%{
qe = sensorGet(sensorRGBW,'spectral qe');
cond(qe)
%}

sensor = sensorCompute(sensorRGBW,oi);
sensorWindow(sensor);

%{
sensorRGB = sensorCreate('ar0132at',[],'rgb');
sensorRGB = sensorSet(sensorRGB,'match oi',oi);
sensorRGB = sensorSet(sensorRGB,'name','rgb');
sensorRGB = sensorCompute(sensorRGB,oi);
sensorWindow(sensorRGB);
ip = ipCreate;
ip = ipCompute(ip,sensorRGB);
ipWindow(ip);
T = ipGet(ip,'transforms');
%}

%% Prepare the exr directory

exrDir = fullfile(isethdrsensorRootPath,'local','exr',string(datetime('today')));
if ~exist(exrDir,'dir'), mkdir(exrDir); end

%% Compute with RGBW and save EXR files

% Note the hour and time for this run.
[HH,mm] = hms(datetime('now')); 

expDuration = [1/15, 1/30, 1/60];
fname = cell(numel(expDuration),1);

for dd = 1:numel(expDuration)
    sensorRGBW = sensorSet(sensorRGBW,'exp time',expDuration(dd));
    sensorRGBW = sensorCompute(sensorRGBW,oi);    
    fname{dd}  = sprintf('%02dH%02dS-RGBW-%.2f.exr',uint8(HH),uint8(mm),sensorGet(sensorRGBW,'exp time','ms'));
    fname{dd}  = sensor2EXR(sensorRGBW,fullfile(exrDir,fname{dd}));
end

%% Demosaic the RGBW using the trained Restormer network

% We assume you have the python miniconda environment running
% See s_python
%
% pyenv('Version','/opt/miniconda3/envs/py39/bin/python');
%
% You can check whether it is up by running
%
%   pyversion
%

% Run demosaic on each of the sensor EXR files. Write them out to a
% corresponding ipEXR file.
ipEXR = cell(1,numel(expDuration));
for ii=1:numel(expDuration)
    [p,n,ext] = fileparts(fname{ii});
    ipEXR{ii} = sprintf('%s-ip%s',fullfile(p,n),ext);
    isetDemosaicNN('rgbw', fname{ii}, ipEXR{ii});
end

%% Show the results

ip = ipCreate;
for ii=1:numel(ipEXR)
    img = exrread(ipEXR{ii});

    ip = ipSet(ip,'sensor space',img);
    ip = ipSet(ip','name',ipEXR{ii});
    ip = ipSet(ip,'transforms',T);
    ip = ipCompute(ip,sensor);
    ipWindow(ip);

    % img = img/max(img(:));
    % img = lin2rgb(img/max(img(:)));
    % ieNewGraphWin; imshow(img);
end

%%