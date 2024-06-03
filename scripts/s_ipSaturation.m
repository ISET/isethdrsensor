%% s_ipSaturation
%
% Build scenes with different dynamic range.  Controlled.  Starting with
% the light group scenes.
%
% Evaluates the ipHDRWhite method, called through ipCompute
% 
% That method moves saturated pixels in the rendering towards white.
%

%% Load the four scenes

% load('HDR-scenes-1114091636.mat');  % Green and red cars
% load('HDR-scenes-1114011756.mat');  % Vans, pedestria, very red
% load('HDR-scenes-1113094429');      % Truck bicycle, dusk

% sceneWindow(scenes{4});

% These are their lights
lgt = {'headlights','streetlights','otherlights','skymap'};

%%  Figure out the peak luminance of the headlights
headlightMax = sceneGet(scenes{1},'max luminance');
skymapMean = sceneGet(scenes{4},'max luminance');
skymapPRCT = sceneGet(scenes{4},'percentile luminance',[0.01 0.99]);

% Log units of dynamic range if we just add.
log10(headlightMax/skymapPRCT.lum(1))

%%
wgts = [1 0 1 1];
scenes{4} = sceneAdjustLuminance(scenes{4},'peak',1);
scene = sceneAdd(scenes, wgts);
sceneWindow(scene);

tmp = sceneGet(scene,'percentile luminance',[0.1 0.99999])

%%

maxlum = zeros(1,numel(lgt));
for ii=1:numel(lgt)
    maxlum(ii) = sceneGet(scenes{ii},'max luminance');
end
mnlum = sceneGet(scenes{4},'mean luminance');

% This is the ratio of the bright lights to the mean luminance of the
% skymap scene.  We might add the scenes together so that some desired
% ratio is preserved.
maxlum(1) / mnlum
sceneGet(scenes(1),'luminance dynamic range')


%% Might maake a smaller version of this scene for speed/testing

load('HDR-02-Brian','scene');
oi = oiCreate;
oi = oiCompute(oi,scene,'crop',true,'pixel size',3e-6);   % oiWindow(oi);

sensor = imx490Compute(oi,'method','average','exptime',1/30);

%% No call to ipHDRWhite

ip = ipCreate;
ip = ipCompute(ip,sensor);
ipWindow(ip);

%% Calls ipHDRWhite at the end

saturation = sensorGet(sensor,'max digital value');
hdrLevel = 0;
[ip2, wgts] = ipHDRWhite(ip,'hdrlevel',hdrLevel,'saturation',saturation);
ieNewGraphWin;
imagesc(wgts); axis image;

ip = ipCompute(ip,sensor,'hdrlevel',hdrLevel);
ipWindow(ip);

%%
hdrLevel = 0.015;
[ip3, wgts] = ipHDRWhite(ip,'hdrlevel',hdrLevel,'saturation',saturation);
ieNewGraphWin;
imagesc(wgts); axis image;

ip = ipCompute(ip,sensor,'hdrlevel',hdrLevel);
ipWindow(ip);

