%% RGBW evaluation with test charts with the trained network
%
% See also
%   s_hthisSensor
%

%%
ieInit

%% Make the scene

% scene = sceneFromFile('Feng_Office-hdrs.mat','spectral');
scene = sceneCreate('macbeth d65',37);
% scene = sceneCreate('rings rays',5,256);

oi = oiCreate('wvf');
wvf    = wvfCreate('spatial samples', 1024);
[aperture, params] = wvfAperture(wvf,'nsides',8,...
    'dot mean',10, 'dot sd',5, 'dot opacity',0.5,'dot radius',5,...
    'line mean',10, 'line sd', 5, 'line opacity',0.5,'linewidth',2);

oi = oiSet(oi,'fnumber',1.7);
oi = oiSet(oi,'focal length',4.38e-3,'m');

oi = oiCompute(oi, scene,'crop',true,'pixel size',1.5e-6,'aperture',aperture);
% oiWindow(oi);

%% Create the RGBW sensor

sensorRGBW = sensorCreate('ar0132at',[],'rgbw');
thisSensor = sensorRGBW;

thisSensor = sensorSet(thisSensor,'match oi',oi);
thisSensor = sensorSet(thisSensor,'name','rgbw');

%{
% Check the condition number of the spectra
qe = sensorGet(thisSensor,'spectral qe');
cond(qe)
%}

%% Prepare the exr directory

exrDir = fullfile(isethdrsensorRootPath,'local','exr',string(datetime('today')));
if ~exist(exrDir,'dir'), mkdir(exrDir); end

%% Compute with RGBW and save EXR files

% Note the hour and time for this run.
[HH,mm] = hms(datetime('now')); 

% expDuration = [1/15, 1/30, 1/60];
expDuration = 1/15;
fname = cell(numel(expDuration),1);

for dd = 1:numel(expDuration)
    thisSensor = sensorSet(thisSensor,'exp time',expDuration(dd));
    thisSensor = sensorCompute(thisSensor,oi);    
    fname{dd}  = sprintf('%02dH%02dS-RGBW-%.2f.exr',uint8(HH),uint8(mm),sensorGet(thisSensor,'exp time','ms'));
    fname{dd}  = sensor2EXR(thisSensor,fullfile(exrDir,fname{dd}));
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
    fprintf('Demosaicking %d ... ',ii);
    [p,n,ext] = fileparts(fname{ii});
    ipEXR{ii} = sprintf('%s-ip%s',fullfile(p,n),ext);
    isetDemosaicNN('rgbw', fname{ii}, ipEXR{ii});
end

%% Find the combined transform for the RGB sensors

ip = ipCreate;


% These match!  So write a routine to get the transforms based on the
% RGB of the RGBW sensor.  No need to create the RGB and run an
% ipCompute to calculate the transforms.
wave     = sensorGet(thisSensor,'wave');
sensorQE = sensorGet(thisSensor,'spectral qe');
targetQE = ieReadSpectra('xyzQuanta',wave);
T{1} = imageSensorTransform(sensorQE(:,1:3),targetQE,'D65',wave,'mcc');
% T{1} = ieColorTransform(thisSensor,'XYZ','D65','mcc');
T{2} = eye(3,3);
T{3} = ieInternal2Display(ip);
ip = ipSet(ip,'transforms',T);
ip = ipSet(ip,'transform method','current');

ip = ipSet(ip,'demosaic method','skip');

% ip = ipSet(ip,'transform method','rgbwrestormer');
for ii=1:numel(ipEXR)
    img = exrread(ipEXR{ii});

    ip = ipSet(ip,'sensor space',img);

    ip = ipCompute(ip,thisSensor);
    [~,ipName] = fileparts(ipEXR{ii});
    ip = ipSet(ip','name',ipName);

    ipWindow(ip);
end

%%  Now use the RGB version %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

sensorRGB = sensorCreate('ar0132at',[],'rgb');
thisSensor = sensorRGB;

thisSensor = sensorSet(thisSensor,'match oi',oi);
thisSensor = sensorSet(thisSensor,'name','rgb');

%{
% Check the condition number of the spectra
qe = sensorGet(thisSensor,'spectral qe');
cond(qe)
%}

%% Prepare the exr directory

exrDir = fullfile(isethdrsensorRootPath,'local','exr',string(datetime('today')));
if ~exist(exrDir,'dir'), mkdir(exrDir); end

%% Compute with RGBW and save EXR files

% Note the hour and time for this run.
[HH,mm] = hms(datetime('now')); 

% expDuration = [1/15, 1/30, 1/60];
expDuration = [1/15];
fname = cell(numel(expDuration),1);

for dd = 1:numel(expDuration)
    thisSensor = sensorSet(thisSensor,'exp time',expDuration(dd));
    thisSensor = sensorCompute(thisSensor,oi);    
    fname{dd}  = sprintf('%02dH%02dS-RGB-%.2f.exr',uint8(HH),uint8(mm),sensorGet(thisSensor,'exp time','ms'));
    fname{dd}  = sensor2EXR(thisSensor,fullfile(exrDir,fname{dd}));
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
    fprintf('Demosaicking %d ... ',ii);
    [p,n,ext] = fileparts(fname{ii});
    ipEXR{ii} = sprintf('%s-ip%s',fullfile(p,n),ext);
    isetDemosaicNN('rgb', fname{ii}, ipEXR{ii});
end

%% Find the combined transform for the RGB sensors

ip = ipCreate;


% These match!  So write a routine to get the transforms based on the
% RGB of the RGBW sensor.  No need to create the RGB and run an
% ipCompute to calculate the transforms.
wave     = sensorGet(thisSensor,'wave');
sensorQE = sensorGet(thisSensor,'spectral qe');
targetQE = ieReadSpectra('xyzQuanta',wave);
T{1} = imageSensorTransform(sensorQE(:,1:3),targetQE,'D65',wave,'mcc');
% T{1} = ieColorTransform(thisSensor,'XYZ','D65','mcc');
T{2} = eye(3,3);
T{3} = ieInternal2Display(ip);
ip = ipSet(ip,'transforms',T);
ip = ipSet(ip,'transform method','current');

ip = ipSet(ip,'demosaic method','skip');

% ip = ipSet(ip,'transform method','rgbwrestormer');
for ii=1:numel(ipEXR)
    img = exrread(ipEXR{ii});

    ip = ipSet(ip,'sensor space',img);

    ip = ipCompute(ip,thisSensor);
    [~,ipName] = fileparts(ipEXR{ii});
    ip = ipSet(ip','name',ipName);

    ipWindow(ip);
end

%% END