%% Make a figure comparing the different types of sensors
%
% For a couple of scenes, render them through some kind of optics onto the
%
% Here are the scenes.  Refresh from time to time.
%
%   hsSceneDescriptions;
%
% The light group names
%   lgt = {'headlights','streetlights','otherlights','skymap'};

%%
ieInit;

%% Create the optics
[oi,wvf] = oiCreate('wvf');
params = wvfApertureP;
% We should implement wvfApertureSet/Get so we do not have to remember
% the parameter names precisely.
% {
params.nsides = 3;
params.dotmean = 50;
params.dotsd = 20;
params.dotopacity =0.5;
params.dotradius = 5;
params.linemean = 50;
params.linesd = 20;
params.lineopacity = 0.5;
params.linewidth = 2;
%}

aperture = wvfAperture(wvf,params);
oi = oiSet(oi,'wvf zcoeffs',0,'defocus');

% imageID = '1112201236'; % - Good one
imageID = '1114091636';   % Red car, green car

%% Load the four light group

fname = fullfile(isethdrsensorRootPath,'local',sprintf('HDR-scenes-%s',imageID));
load(fname,'scenes');

%% Day

% wgts = [0.2306    0.0012    0.0001    0.5175]; % Night
wgts = [0    0     0    100*0.5175]; % Day
scene = hsSceneCreate(imageID,'weights',wgts,'denoise',false);
% sceneWindow(scene); scene = sceneSet(scene,'render flag','clip');
oiDay = oiCompute(oi, scene,'aperture',aperture,'crop',true,'pixel size',3e-6);
oiWindow(oiDay,'gamma',0.5,'render flag','rgb');
% srgb = oiGet(oiDay,'rgb'); ieNewGraphWin; image(srgb); truesize

%% Night
wgts = [0.2306    0.0012    0.0001    1e-2*0.5175]; % Day
scene = hsSceneCreate(imageID,'weights',wgts,'denoise',false);
oiNight = oiCompute(oi, scene,'aperture',aperture,'crop',true,'pixel size',3e-6);
oiWindow(oiNight,'render flag','rgb','gamma',0.2);
% srgb = oiGet(oiNight,'rgb'); ieNewGraphWin; image(srgb); truesize

%% First a standard RGB

sensorRGB = sensorCreate('ar0132at');
sensorRGB = sensorSet(sensorRGB,'match oi',oiDay);
sensorRGB = sensorSet(sensorRGB,'exp time',2e-3);
sensorRGB = sensorCompute(sensorRGB,oiDay);
sensorWindow(sensorRGB,'gamma',0.5);

sensorRGB = sensorSet(sensorRGB,'exp time',16e-3);
sensorRGB = sensorCompute(sensorRGB,oiNight);
sensorWindow(sensorRGB,'gamma',0.3);

rgb = sensorGet(sensorRGB,'rgb');
ieNewGraphWin; imagesc(rgb); truesize;

%%  Then the RGBW version
sensorRGBW = sensorCreate('ar0132at',[],'rgbw');
sensorRGBW = sensorSet(sensorRGBW,'match oi',oiNight);
sensorRGBW = sensorSet(sensorRGBW,'exp time',2e-3);
sensorRGBW = sensorCompute(sensorRGBW,oiNight);
sensorWindow(sensorRGBW,'gamma',0.3);

rgb = sensorGet(sensorRGBW,'rgb');
ieNewGraphWin; imagesc(rgb); truesize;


%% Split pixel calculation
pixelSize = sensorGet(sensorRGB,'pixel size');
sensorSize = sensorGet(sensorRGB,'size');
sensorArray = sensorCreateArray('split pixel',...
    'pixel size same fill factor',pixelSize,...
    'exp time',2e-3, ...
    'size',sensorSize);

[sensorCombined, sensorArray] = sensorComputeArray(sensorArray,oiDay);
sensorWindow(sensorCombined,'gamma',0.3);


rgb = sensorGet(sensorCombined,'rgb');
ieNewGraphWin; imagesc(rgb); truesize;

% rgbw = sensorGet(sensorAR,'color filters');
% waveAR = sensorGet(sensorAR,'wave');
% tmp = interp1(wave363,rgb,waveAR); rgbw(:,1:3) = tmp;
% sensorAR = sensorSet(sensorAR,'color filters',rgbw);
% sensorPlot(sensorAR,'color filters');
% set(gca,'xlim',[400 700],'ylim',[0,1]);

%%
sensorAR = sensorCompute(sensorAR,oi);
sensorGet(sensorAR,'exp time','ms')
sensorWindow(sensorAR);

[imx490, metadata] = imx490Compute(oi,'exp time',2e-3);
sensorGet(imx490,'exp time','ms')
sensorWindow(imx490);

sensorPlot(imx490,'dv hline',[1,150],'two lines',true)


%% Turn off the noise and recompute

%{
sensor = sensorSet(sensor,'noiseFlag',0);
sensor = sensorSet(sensor,'name','noise free');
sensor = sensorCompute(sensor,oi);

ip = ipCompute(ip,sensor);
ipWindow(ip);
%}

%% For each sensor
for ss = 1:2

    if ss==1
        thisSensor = sensorRGBW;
        thisType = 'rgbw';
    elseif ss == 2
        thisSensor = sensorRGB;
        thisType = 'rgb';
    end

    thisSensor = sensorSet(thisSensor,'match oi',oi);
    thisSensor = sensorSet(thisSensor,'name',thisType);

    %{
      qe = sensorGet(thisSensor,'spectral qe');
      cond(qe)
    %}

    % Shorter durations have more noise.
    expDuration = [1/30 1/60 1/120];
    
    fname = cell(numel(expDuration),1);
    fprintf('Creating EXR ...');
    for dd = 1:numel(expDuration)
        thisSensor = sensorSet(thisSensor,'exp time',expDuration(dd));
        thisSensor = sensorCompute(thisSensor,oi);
        fname{dd}  = sprintf('%02dH%02dS-%s-%.2f.exr',uint8(HH),uint8(mm),thisType,sensorGet(thisSensor,'exp time','ms'));
        fname{dd}  = sensor2EXR(thisSensor,fullfile(exrDir,fname{dd}));
    end
    disp('done.')

    % Demosaic the RGBW using the trained Restormer network

    % Run demosaic on each of the sensor EXR files. Write them out to a
    % corresponding ipEXR file.
    ipEXR = cell(1,numel(expDuration));
    for ii=1:numel(expDuration)
        fprintf('Scene %d: ',ii);
        [p,n,ext] = fileparts(fname{ii});
        ipEXR{ii} = sprintf('%s-ip%s',fullfile(p,n),ext);
        isetDemosaicNN(thisType, fname{ii}, ipEXR{ii});
    end

    % Find the combined transform for the RGB sensors

    ip = ipCreate;

    % Create the rendering transforms
    wave     = sensorGet(thisSensor,'wave');
    sensorQE = sensorGet(thisSensor,'spectral qe');
    targetQE = ieReadSpectra('xyzQuanta',wave);
    T{1} = imageSensorTransform(sensorQE(:,1:3),targetQE,'D65',wave,'mcc');
    T{2} = eye(3,3);
    T{3} = ieInternal2Display(ip);

    ip = ipSet(ip,'demosaic method','skip');
    ip = ipSet(ip,'transforms',T);
    ip = ipSet(ip,'transform method','current');

    for ii=1:numel(ipEXR)
        img = exrread(ipEXR{ii});

        ip = ipSet(ip,'sensor space',img);

        ip = ipCompute(ip,thisSensor);
        [~,ipName] = fileparts(ipEXR{ii});
        ip = ipSet(ip','name',ipName);
        ipWindow(ip);
    end

end

%% Try some ipPlots

% Note that in the dark regions, there is more noise in the RGB thasn the
% RGBW.  Not earthshaking, but real. Mostly visible for the short duration
% cases, where there is more noise altogether.

vcSetSelectedObject('ip',7);   % RGBW
ip = ieGetObject('ip'); [uDataRGBW,hdlRGBW] = ipPlot(ip,'horizontal line', [1,470]);

vcSetSelectedObject('ip',8);   % RGB
ip = ieGetObject('ip'); [uDataRGB,hdlRGB] = ipPlot(ip,'horizontal line', [1,470]);

nChildren = 3;
for ii=1:nChildren
    set(hdlRGBW.Children(ii),'ylim',[0 10^-2]);
    set(hdlRGB.Children(ii),'ylim',[0 10^-2]);
end

%%