%% RGBW evaluation with test charts with the trained network
%
% See also
%   s_hthisSensor
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
%{
sceneWindow(scene);
%}
%{
background = sceneSet(background,'fov',10);
background = sceneFromFile('FruitMCC_6500.tif','rgb',1,displayCreate,400:10:700);
background = sceneFromFile('Feng_Office-hdrs.mat','spectral',1,displayCreate,400:50:700);
background = sceneCreate('uniformee',512);
background = sceneAdjustLuminance(background,1);
scene = sceneCreate('hdr lights');
scene = sceneSet(scene,'resize',sceneGet(background,'size'));
scene = sceneAdd(scene,background);
%}

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
ieNewGraphWin; imagesc(imagecell{2}); axis image; axis off; truesize;
ieNewGraphWin; montage(imagecell);

% ieNewGraphWin; montage(imagecell(1:3:end));

%%
%{
    % GIF generation
    if dd == 1
        imagesc(srgb); axis image; axis off; truesize;
        fname = sprintf('dynamicRange-%02d-%02d.gif',HH,mm);
        gif(fname);
        gif('DelayTime',3/15);
        gif('LoopCount',1000);        
    else
        imagesc(srgb); axis image; axis off; truesize;
    end
    gif;
    %}
% web(fname);

%% 0----------

[oi,wvf] = oiCreate('wvf');
oi = oiSet(oi,'fnumber',1.7);
oi = oiSet(oi,'focal length',4.38e-3,'m');
wvf = wvfSet(wvf,'spatial samples',1024);

%{
params = 

  struct with fields:

         nsides: 5
        dotmean: 10
          dotsd: 5
     dotopacity: 0.5000
      dotradius: 5
       linemean: 10
         linesd: 5
    lineopacity: 0.5000
      linewidth: 2
%}
params = wvfApertureP;

% sensor = sensorCreate('imx363');
sensor = sensorCreate('ar0132at',[],'rgb');
sensor = sensorSet(sensor,'match oi',oi);
ip = ipCreate;

%%
ieInit;

params = wvfApertureP;
params.lineopacity = .5;
params.linemean = 0; params.linesd = 0;
params.dotmean = 100; params.dotsd = 0;

for dotopacity = 0:0.1:1
    params.dotopacity = dotopacity;

    aperture = wvfAperture(wvf,params);
    ieNewGraphWin; imagesc(aperture);

    oi = oiCompute(oi, scene,'crop',true,'pixel size',1.5e-6,'aperture',aperture);
    % oiWindow(oi);

    eTime  = autoExposure(oi,sensor,0.95,'luminance');
    sensor = sensorSet(sensor,'exp time',eTime*1000);
    sensor = sensorCompute(sensor,oi);
    ip = ipCompute(ip,sensor);
    ipWindow(ip); drawnow;

end

%% NSIDES

ieInit;

params = wvfApertureP;

[oi,wvf] = oiCreate('wvf');
wvf = wvfSet(wvf,'spatial samples',1024);
aperture = wvfAperture(wvf,params);

oi = oiSet(oi,'fnumber',1.7);
oi = oiSet(oi,'focal length',4.38e-3,'m');
oi = oiCompute(oi, scene,'crop',true,'pixel size',1.5e-6,'aperture',aperture);

for nsides = (3:1:20)
    params.nsides = nsides;

    aperture = wvfAperture(wvf,params);
    % ieNewGraphWin; imagesc(aperture);

    oi = oiCompute(oi, scene,'crop',true,'pixel size',1.5e-6,'aperture',aperture);
    % oiWindow(oi);

    eTime  = autoExposure(oi,sensor,0.95,'luminance');
    sensor = sensorSet(sensor,'exp time',eTime*1000);
    sensor = sensorCompute(sensor,oi);
    ip = ipCompute(ip,sensor);
    srgb = ipGet(ip,'srgb');
    imagesc(srgb); axis image; axis off; truesize;
    if nsides == 3
        gif('clear');
        gif('nsides.gif');
        gif('DelayTime',8/15,'LoopCount',1000);
    end
    gif;

    % ipWindow(ip); drawnow;
end

%%
web('nsides.gif');

%%
%{

%% Try some ipPlots

vcSetSelectedObject('ip',3);   % RGBW
ip = ieGetObject('ip'); [uDataRGBW,hdlRGBW] = ipPlot(ip,'horizontal line', [1,470]);

vcSetSelectedObject('ip',6);   % RGB
ip = ieGetObject('ip'); [uDataRGB,hdlRGB] = ipPlot(ip,'horizontal line', [1,470]);

nChildren = 3;
for ii=1:nChildren
    set(hdlRGBW.Children(ii),'ylim',[0 10^-2]);
    set(hdlRGB.Children(ii),'ylim',[0 10^-2]);
end
%}

%{
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
%}
%% END