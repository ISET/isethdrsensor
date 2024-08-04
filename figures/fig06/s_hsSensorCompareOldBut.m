%% Make a figure comparing the imx363 ordinary with a split pixel version 
%
% Purpose is to show how to evaluate different photodetector designs
%
%   * Match imx363 with the split pixel design for one possibility
%   * Show just increasing well capacity?
%   * Show reduced sensitivity just on one of the green pixels?
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

%%
% imageID = '1112201236';
imageID = '1114120530';
%% Load the four light group

fname = fullfile(isethdrsensorRootPath,'data',sprintf('HDR-scenes-%s',imageID));
load(fname,'scenes');

%% Create a scene

DR = 10^7;
lowLight = 10;
scene = lightGroupDynamicRangeSet(scenes, DR,lowLight);
scene = piAIdenoise(scene);
% sceneWindow(scene);

%% Blur and flare
[oi,wvf] = oiCreate('wvf');
[aperture, params] = wvfAperture(wvf,'nsides',3,...
    'dot mean',50, 'dot sd',20, 'dot opacity',0.5,'dot radius',5,...
    'line mean',50, 'line sd', 20, 'line opacity',0.5,'linewidth',2);
oi = oiSet(oi,'wvf zcoeffs',0,'defocus');
oi = oiCompute(oi, scene,'aperture',aperture,'crop',true,'pixel size',3e-6);
oiWindow(oi);

%% First show the imx363

sensor363 = sensorCreate('imx363');
sensor363 = sensorSet(sensor363,'match oi',oi);
sensor363 = sensorSet(sensor363,'exp time',2e-3);
sensor363 = sensorCompute(sensor363,oi);
sensorWindow(sensor363);
sensorPlot(sensor363,'color filters');
set(gca,'xlim',[400 700],'ylim',[0,1]);

rgb = sensorGet(sensor363,'color filters');
wave363 = sensorGet(sensor363,'wave');

sensorAR = sensorCreate('ar0132at',[],'rgbw');
sensorAR = sensorSet(sensorAR,'match oi',oi);
sensorAR = sensorSet(sensorAR,'exp time',2e-3);
rgbw = sensorGet(sensorAR,'color filters');
waveAR = sensorGet(sensorAR,'wave');
tmp = interp1(wave363,rgb,waveAR); rgbw(:,1:3) = tmp;
sensorAR = sensorSet(sensorAR,'color filters',rgbw);
sensorPlot(sensorAR,'color filters');
set(gca,'xlim',[400 700],'ylim',[0,1]);

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