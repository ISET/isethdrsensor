%% s_hsIMX490
% 
% Not up to date.  But useful to start the split pixel simulation for
% the paper.
%
%

%%
ieInit;

%%  Specify the scene 

% Use the script s_downloadLightGroup to add more light group scenes
% to this list.  It is OK to make reasonably large versions, IMHO.

imageID = '1112201236';
% 1112201236
% 1114091636 - Red/Green cars - Should expand image
% 1114011756 - Vans moving away, person crossing with purse
% 1113094429 - Cyclist in front of truck, red sky.  Works well.
%

lgt = {'headlights','streetlights','otherlights','skymap'};

% Cropped and denoised light group scenes
fname = fullfile(isethdrsensorRootPath,'data',sprintf('HDR-scenes-%s',imageID));
load(fname,'scenes');

%% Set the dynamic range and the level of the dark region (cd/m2 = nits)

dynamicRange = 10^4;
lowLight = 10;
scene = lightGroupDynamicRangeSet(scenes, dynamicRange, lowLight);
scene = sceneSet(scene,'fov',20);   % I cropped the big scene down.
ieAddObject(scene);

%% Compute with some optics

[oi,wvf] = oiCreate('wvf');
[aperture, params] = wvfAperture(wvf,'nsides',3,...
    'dot mean',50, 'dot sd',20, 'dot opacity',0.5,'dot radius',5,...
    'line mean',50, 'line sd', 20, 'line opacity',0.5,'linewidth',2);

oi = oiSet(oi,'wvf zcoeffs',0,'defocus');
oi = oiCompute(oi, scene,'aperture',aperture,'crop',true, 'pixel size',3e-6);

%% Sony sensor 

sensor = sensorCreate('imx363');
sensor = sensorSet(sensor,'match oi',oi);

% The exposure duration matters a great deal. If it is short, we have
% too few photons in the dark region of the image.

%%
autoTime  = autoExposure(oi,sensor,0.95,'luminance');
wgtBlur = 2;
saturation = sensorGet(sensor,'max digital');

ip = ipCreate;

for eTime = autoTime*logspace(-0.5,1,5)
    sensor = sensorSet(sensor,'exp time',eTime);
    sensor = sensorCompute(sensor,oi);
    sensor = sensorSet(sensor,'name',sprintf('Combined-ave-%.3f',eTime));
    ip = ipCompute(ip,sensor,'hdr white', true, 'saturation', saturation,'wgt blur', wgtBlur);
    ipWindow(ip);
end

%% Sensor is the combined response from the 4 pixels

% The exposure duration matters a great deal. If it is short, we have
% too few photons in the dark region of the image.

autoTime  = autoExposure(oi,sensor,0.95,'luminance');


for eTime = autoTime*logspace(-0.5,1,5)

    % I wish this could be a sensorCompute call, somehow.
    sensor = imx490Compute(oi,'method','average','exptime',eTime);
    
    sensor = sensorSet(sensor,'name',sprintf('Combined-ave-%.3f',eTime));
    % sensorWindow(sensor);
    ip = ipCompute(ip,sensor);
    % ip = ipHDRWhite(ip);
    ipWindow(ip);
end

%%