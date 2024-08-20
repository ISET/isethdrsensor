%% Figure 03
%
% Show the day, night and light group images
%
% Caption
%
% Figure 3: Scene light groups. The dataset consists of 2000 scenes,
% each defined by four spectral radiance maps representing
% illumination by the sky, headlights, streetlights, and other light
% sources (e.g., tail lights, bicycle lights). To simulate various
% lighting conditions, the four maps are combined with different
% weights. For example, a daytime scene (left) has a bright sky and
% headlights, while a nighttime scene (right) has a darker sky with
% prominent headlights and streetlights. Using a lens model
% incorporating aperture and scratch effects (but excluding
% inter-reflections), scene radiance is converted to sensor
% irradiance. The graph on the right illustrates the illumination
% profile across a horizontal line. Note that headlight intensity
% remains constant between day and night, while reduced skylight
% lowers image contrast in darker areas. The software includes tools
% to select the weights to achieve desired dynamic range and low-light
% conditions.(lightGroupDynamicRangeSet.m).

%% 

ieInit

%% If you need to download, use hsDownloadLightGroup
%
imageID = '1112184733';
lgt = {'headlights','streetlights','otherlights','skymap'};
destPath = fullfile(isethdrsensorRootPath,'data',imageID);

scenes = cell(numel(lgt,1));
for ll = 1:numel(lgt)
    thisFile = sprintf('%s_%s.exr',imageID,lgt{ll});
    destFile = fullfile(destPath,thisFile);
    scenes{ll} = piEXR2ISET(destFile);
end
disp('Done loading.')

%% Day

% DR = 1e3;
% % [ scene, wgts] = lightGroupDynamicRangeSet(scenes, DR);
wgts_day = [0.5019    0.0063    0.0083    100];
scene = sceneAdd(scenes, wgts_day);
dayScene = piAIdenoise(scene);

% sceneWindow(thisScene,'gamma',0.3);

%% Blur and flare
[oi,wvf] = oiCreate('wvf');
% wvf = wvfSet(wvf, 'spatial samples',512);
[aperture, params] = wvfAperture(wvf,'nsides',5,...
    'dot mean',50, 'dot sd',20, 'dot opacity',0.5,'dot radius',5,...
    'line mean',50, 'line sd', 20, 'line opacity',0.5,'linewidth',2);

oi = oiSet(oi,'wvf zcoeffs',0,'defocus');
oiDay = oiCompute(oi, dayScene,'aperture',aperture,'crop',true,'pixel size',3e-6);

% oi1 = oiAdjustIlluminance(oi1, 5e4, 'max');
udata1 = oiPlot(oiDay,'illuminance hline',[1, 595]);
set(gca,'yscale','log');

%% Create ip and sensor from the oi

[ipDay,sensorDay] = piRadiance2RGB(oiDay, 'etime', 1/200,'analoggain',1);
%{
 % Equivalent
 ip = ipCreate;
 ip = ipCompute(ip,sensorDay,'hdr white',true);
 ipWindow(ip,'gamma',0.7);
%}

ipWindow(ipDay,'gamma',0.7);

%{
srgb = ipGet(ip, 'srgb');
imwrite(srgb,'~/Desktop/day.png');
%}

%% Night

wgts_night = [0.5019    0.0063    0.0083    5e-5];
scene = sceneAdd(scenes, wgts_night);
nightScene = piAIdenoise(scene);

% sceneWindow(thisScene,'renderflag','hdr');

%% Create the OI
oiNight = oiCompute(oi, nightScene,'aperture',aperture,'crop',true,'pixel size',3e-6);
oiNight = oiAdjustIlluminance(oiNight, 5e4, 'max');
oiWindow(oiNight,'render flag','hdr');

% Plot the log luminance through the bright headlight
[udata2, g] = oiPlot(oiNight,'illuminance hline',[1, 595]);
set(gca,'yscale','log');

%% Make an IP directly from the oi. Goes through

[ipNight, sensorNight] = piRadiance2RGB(oiNight, 'etime', 1/10,'analoggain',1);
% sensorWindow(sensorNight);

ipWindow(ipNight,'gamma',0.7);

%{
srgb = ipGet(ipNight, 'srgb');
imwrite(srgb,'~/Desktop/night.png');
%}

%% Compare the oiDay and oiNight illuminance

nPoints = numel(udata1.data);
% Notice that the headlight is the same in the two cases.
ieNewGraphWin;
plot(1:nPoints,udata1.data, 'b', 'LineWidth', 2); hold on 
plot(1:nPoints,udata2.data, 'r', 'LineWidth', 2);

set(gca, 'YScale', 'log');
legend('DAY', 'NIGHT', 'FontSize', 14);
xlabel('Position (pixel)', 'FontSize', 16);
ylabel('Illuminance (lux)', 'FontSize', 16);

% Set the font size for the axes
set(gca, 'FontSize', 16);
grid on
xlim([0,nPoints]);

%% END
