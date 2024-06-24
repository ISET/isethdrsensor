%% Make a figure comparing the different types of sensors
%
% For a couple of scenes, render them through some kind of optics onto the
%
% Here are the scenes.  Refresh from time to time.
%
%   hsSceneDescriptions;
%
% 1114034742 - Motorcyle, people walking not very nice
% 1114091636 - People on street
% 1114011756 - Vans moving away, person
% 1113094429 - Truck and nice late afternoon
% 1112201236 - Open highway scene
% 1113042919 - Blue car, person, motorcyle, yellow bus
% 1112213036 - Lousy.
% 1113040557 - Lousy.  Truck and people
% 1113051533 - Hard to get light levels right
% 1112220258 - Curved road with trucks and bicycles and lights
% 1113164929 - One car, one bike, mountain in the road? 
% 1113165019 - Wide, complex highway scene.  Big sky
% 1114043928 - Man in front of the sky
% 1114120530 - Woman in front of a truck
%
% The light group names
%   lgt = {'headlights','streetlights','otherlights','skymap'};

%%
ieInit;

%%
imageID = '1114091636';

%% Load the four light group

fname = fullfile(isethdrsensorRootPath,'local',sprintf('HDR-scenes-%s',imageID));
load(fname,'scenes');

%% Create a scene

DR = 10^5;
lowLight = 1;
scene = lightGroupDynamicRangeSet(scenes, DR,lowLight);
sceneWindow(scene);

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
sensorGet(sensor363,'exp time','ms')

sensorAR = sensorCreate('ar0132at',[],'rgbw');
sensorAR = sensorSet(sensorAR,'match oi',oi);
sensor363 = sensorSet(sensor363,'exp time',2e-3);
sensorAR = sensorCompute(sensorAR,oi);
sensorGet(sensorAR,'exp time','ms')
sensorWindow(sensorAR);

[imx490, metadata] = imx490Compute(oi,'exp time',2e-3);
sensorGet(imx490,'exp time','ms')
sensorWindow(imx490);

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