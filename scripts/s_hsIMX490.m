%% s_hsIMX490
% 

%%
ieInit;

%%  Specify the scene 

% Use the script s_downloadLightGroup to add more light group scenes
% to this list

imageID = '1114011756';
% 1114091636 - Red/Green cars
% 1114011756 - Vans moving away, person
% 1113094429 - Cyclist in front of truck, red sky
%

lgt = {'headlights','streetlights','otherlights','skymap'};

% Cropped and denoised light group scenes
fname = fullfile(isethdrsensorRootPath,'local',sprintf('HDR-scenes-%s',imageID));
load(fname,'scenes');

%% Set the dynamic range and the level of the dark region (cd/m2 = nits)

DR = 10^6;
scene = lightGroupDynamicRangeSet(scenes, DR);
scene = sceneAdjustLuminance(scene,'median',10);

ieAddObject(scene);

%% Compute with some optics

[oi,wvf] = oiCreate('wvf');
[aperture, params] = wvfAperture(wvf,'nsides',3,...
    'dot mean',50, 'dot sd',20, 'dot opacity',0.5,'dot radius',5,...
    'line mean',50, 'line sd', 20, 'line opacity',0.5,'linewidth',2);

oi = oiSet(oi,'wvf zcoeffs',0,'defocus');
oi = oiCompute(oi, scene,'aperture',aperture,'crop',true, 'pixel size',3e-6);

%% Sensor is the combined response from the 4 pixels

% The exposure duration matters a great deal. If it is short, we have
% too few photons in the dark region of the image.

ip = ipCreate;
for eTime = [60/120 15/120,4/120,1/120]
    sensor = imx490Compute(oi,'method','average','exptime',eTime);
    sensor = sensorSet(sensor,'name',sprintf('Combined-ave-%.3f',eTime));
    % sensorWindow(sensor);
    ip = ipCompute(ip,sensor);
    % ip = ipHDRWhite(ip);
    ipWindow(ip);
end

%%
