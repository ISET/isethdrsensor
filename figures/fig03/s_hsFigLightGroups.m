% imageID = '1112234215';
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
thisScene = piAIdenoise(scene);
% sceneWindow(thisScene);

% Blur and flare

[oi,wvf] = oiCreate('wvf');
% wvf = wvfSet(wvf, 'spatial samples',512);
[aperture, params] = wvfAperture(wvf,'nsides',5,...
    'dot mean',50, 'dot sd',20, 'dot opacity',0.5,'dot radius',5,...
    'line mean',50, 'line sd', 20, 'line opacity',0.5,'linewidth',2);

oi = oiSet(oi,'wvf zcoeffs',0,'defocus');
oi1 = oiCompute(oi, thisScene,'aperture',aperture,'crop',true,'pixel size',3e-6);
% oi1 = oiAdjustIlluminance(oi1,5e4, 'max');
[udata1, g] = oiPlot(oi1,'illuminance hline',[1, 632]);

ip = piRadiance2RGB(oi1, 'etime', 1/200,'analoggain',1);
ipWindow(ip);
srgb = ipGet(ip, 'srgb');imwrite(srgb,'~/Desktop/day.png');
% Night
wgts_night = [0.5019    0.0063    0.0083    5e-5];
scene = sceneAdd(scenes, wgts_night);
thisScene = piAIdenoise(scene);
% sceneWindow(thisScene);

oi3 = oiCompute(oi, thisScene,'aperture',aperture,'crop',true,'pixel size',3e-6);
% oi3 = oiAdjustIlluminance(oi3,5e4, 'max');
[udata2, g] = oiPlot(oi3,'illuminance hline',[1, 632]);

ip = piRadiance2RGB(oi3, 'etime', 1/20,'analoggain',15);
ipWindow(ip);
srgb = ipGet(ip, 'srgb');imwrite(srgb,'~/Desktop/night.png');

% 
figure;
plot(1:1920,udata1.data, 'b', 'LineWidth', 2); hold on 
plot(1:1920,udata2.data, 'r', 'LineWidth', 2);
set(gca, 'YScale', 'log');
legend('DAY', 'NIGHT', 'FontSize', 14);

xlabel('Position (pixel)', 'FontSize', 16);
ylabel('Illuminance (lux)', 'FontSize', 16);

% Set the font size for the axes
set(gca, 'FontSize', 16);
grid on
xlim([0,1920]);
