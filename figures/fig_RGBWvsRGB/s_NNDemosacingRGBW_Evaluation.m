%% Setup
%
% Images comparing RGB and RGBW data after standard IP processing.
%
% Restormer for RGBW.  Adaptive laplacian for RGB.
%
%
% See also
%

%%
ieInit;

%% Create the two sensors and IP

sensorRGBW = sensorCreate('ar0132at',[],'rgbw');
sensorRGB  = sensorCreate('ar0132at',[],'rgb');
sensorRGB  = sensorSet(sensorRGB,'exp time',1/60);
sensorRGBW = sensorSet(sensorRGBW,'exp time',1/60);

ip = ipCreate;
ip = ipSet(ip,'demosaic method','Adaptive Laplacian'); 

%% Color test scene

scene = sceneCreate('macbeth',80);

oi = oiCreate;
oi = oiCompute(oi, scene,'crop',true,'pixel size', 3e-6);

% Match the sensor spatial parameters to the OI
sensorRGB = sensorSet(sensorRGB,'match oi',oi);
sensorRGBW = sensorSet(sensorRGBW,'match oi',oi);

idx = 1;

%% Start low, and progress to high, optical image illuminance

% lux = [0.1: 0.1:1, 2:10];   % Zhenyi's original
lux = logspace(-2,1,5);      % Five levels

for ii = 1:numel(lux)
    oi = oiAdjustIlluminance(oi, lux(ii));
    
    % rgb
    thisSensorRGB = sensorCompute(sensorRGB,oi);
    ipRGB = ipCompute(ip, thisSensorRGB);
    ipWindow(ipRGB); rgbImg = ipGet(ipRGB, 'srgb');

    % rgbw using restormer
    ipRGBNN = ipComputeNN(thisSensorRGBW, 'ar0132at-rgb');
    ipWindow(ipRGBNN); rgbNNImg = ipGet(ipRGBNN, 'srgb');
    %{
    % rgbw
    thisSensorRGBW = sensorCompute(sensorRGBW,oi);
    ipRGBW = ipCompute(ip, thisSensorRGBW, 'hdr white', true);
    ipWindow(ipRGBW); rgbwImg = ipGet(ipRGBW, 'srgb');
    %}

    % rgbw using restormer
    ipRGBWNN = ipComputeNN(thisSensorRGBW, 'ar0132at-rgbw');
    ipWindow(ipRGBWNN); rgbwNNImg = ipGet(ipRGBWNN, 'srgb');

    if ii==1
        % Make the ground truth image data the first time
        sensorI = sensorCreateIdeal('match',sensorRGB);
        sensorI = sensorCompute(sensorI,oi);
        sensorWindow(sensorI(3));
        gtImg(:,:,1) = sensorI(1).data.volts;
        gtImg(:,:,2) = sensorI(2).data.volts;
        gtImg(:,:,3) = sensorI(3).data.volts;

        ipIdeal = ipRGB;
        ipIdeal = ipSet(ipIdeal, 'demosaic method', 'skip');
        ipIdeal = ipSet(ipIdeal, 'transform method', 'current');
        % Set the sensor space image in the image processing structure
        ipIdeal = ipSet(ipIdeal, 'sensor space', gtImg);

        % Compute the final image processing
        ipIdeal = ipCompute(ipIdeal, thisSensorRGB);

        % ipWindow(ipIdeal);
        rgbGT = ipGet(ipIdeal, 'srgb');
        rgbGT = ieScale(rgbGT, 1);
    end

    rgbImg    = ieScale(rgbImg, 1);
    rgbwImg   = ieScale(rgbwImg, 1);
    rgbwNNImg = ieScale(rgbwNNImg, 1);
    
    % Calculate delta E.  Why isn't this just ii?
    dE_rgb(idx)    = mean2(imcolordiff(rgbGT, rgbImg));
    dE_rgbw(idx)   = mean2(imcolordiff(rgbGT, rgbwImg));
    dE_rgbwNN(idx) = mean2(imcolordiff(rgbGT, rgbwNNImg));
    idx=idx+1;
end

%% 

figure(1);
plot(lux, dE_rgb(1:19), 'color', [0.8500, 0.3250, 0.0980], 'LineWidth', 2); hold on  % Orange
plot(lux, dE_rgbw(1:19), 'color', [0.4660, 0.6740, 0.1880], 'LineWidth', 2);         % Green
plot(lux, dE_rgbwNN(1:19), 'color', [0.4940, 0.1840, 0.5560], 'LineWidth', 2);       % Purple
legend('RGB', 'RGBW', 'RGBW-NN');
xlabel('Log Mean Illuminance (lux)', 'FontSize', 16);
ylabel('deltaE', 'FontSize', 16);
set(gca, 'FontSize', 16);
set(gca, 'XScale', 'log');

%%

imwrite(rgbwImg,'~/Desktop/rgbw.png')
imwrite(rgbwNNImg,'~/Desktop/rgbwNN.png')
imwrite(rgbImg,'~/Desktop/rgb.png')


%% MTF comparison
scene = sceneCreate('slanted bar', 500);
oi = oiCreate;
oi = oiCompute(oi, scene,'crop',true,'pixel size', 3e-6);
sensorRGB = sensorSet(sensorRGB,'match oi',oi);
sensorRGBW = sensorSet(sensorRGBW,'match oi',oi);
lux = [0.1 1 10];
rect = [154    41   166   234];
dx = 3e-3;
clear gtImg

for ii = 1:numel(lux)
    oi = oiAdjustIlluminance(oi, lux(ii));
    
    % rgb
    thisSensorRGB = sensorCompute(sensorRGB,oi);
    ipRGB = ipCompute(ip, thisSensorRGB);
    ipWindow(ipRGB); rgbImg = ipGet(ipRGB, 'srgb');
    % rgbw
    thisSensorRGBW = sensorCompute(sensorRGBW,oi);
    ipRGBW = ipCompute(ip, thisSensorRGBW, 'hdr white', true);
    ipWindow(ipRGBW); rgbwImg = ipGet(ipRGBW, 'srgb');
    % rgbw using restormer
    ipRGBWNN = ipComputeNN(thisSensorRGBW, 'ar0132at-rgbw');
    ipWindow(ipRGBWNN); rgbwNNImg = ipGet(ipRGBWNN, 'srgb');
    if ii==1        
        sensorI = sensorCreateIdeal('match',sensorRGB);
        sensorI = sensorCompute(sensorI,oi);
        sensorWindow(sensorI(3));
        gtImg(:,:,1) = sensorI(1).data.volts;
        gtImg(:,:,2) = sensorI(2).data.volts;
        gtImg(:,:,3) = sensorI(3).data.volts;

        ipIdeal = ipRGB;
        ipIdeal = ipSet(ipIdeal, 'demosaic method', 'skip');
        ipIdeal = ipSet(ipIdeal, 'transform method', 'current');
        % Set the sensor space image in the image processing structure
        ipIdeal = ipSet(ipIdeal, 'sensor space', gtImg);

        % Compute the final image processing
        ipIdeal = ipCompute(ipIdeal, thisSensorRGB);
        % ipWindow(ipIdeal);
        rgbGT = ipGet(ipIdeal, 'srgb');

        rgbGT = ieScale(rgbGT, 1);
        barImage = imcrop(rgbGT,rect);
        ret = ISO12233(barImage, dx);
    end
    rgbImg = ieScale(rgbImg, 1);
    rgbwImg = ieScale(rgbwImg, 1);
    rgbwNNImg = ieScale(rgbwNNImg, 1);

    barImage = imcrop(rgbImg,rect);
    ret = ISO12233(barImage, dx,[],'none');
    rgbMTF50(ii) = ret;

    barImage = imcrop(rgbwImg,rect);
    ret = ISO12233(barImage, dx,[],'none');
    rgbwMTF50(ii) = ret;

    barImage = imcrop(rgbwNNImg,rect);
    ret = ISO12233(barImage, dx);
    rgbwNNMTF50(ii) = ret;
end

%%
figure;
for jj = 1:3
    result =  rgbwNNMTF50(jj);
    p = plot(result.freq, result.mtf(:,4));
    set(p,'linewidth',2);
    hold on;
end
legend('0.1lux','1lux','10lux');
% [p,fname,e] = fileparts(ttext);
title('MTF for RGBWNN');
xlabel('Spatial frequency cy/mm');
ylabel('Contrast reduction (SFR)');
ylim([0,1]);

%% Driving scene
imageID = '1114090605';

lgt = {'headlights','streetlights','otherlights','skymap'};
destPath = fullfile(isethdrsensorRootPath,'data',imageID);

scenes = cell(numel(lgt,1));
for ll = 1:numel(lgt)
    thisFile = sprintf('%s_%s.exr',imageID,lgt{ll});
    destFile = fullfile(destPath,thisFile);
    scenes{ll} = piEXR2ISET(destFile);
end
disp('Done loading.')


wgts_day = [0.5019    0.0063    0.0083    0.01];
scene = sceneAdd(scenes, wgts_day);
thisScene = piAIdenoise(scene);

[oi,wvf] = oiCreate('wvf');
% wvf = wvfSet(wvf, 'spatial samples',512);
[aperture, params] = wvfAperture(wvf,'nsides',5,...
    'dot mean',50, 'dot sd',20, 'dot opacity',0.5,'dot radius',5,...
    'line mean',50, 'line sd', 20, 'line opacity',0.5,'linewidth',2);

% oi = oiSet(oi,'wvf zcoeffs',0,'defocus');
oi = oiCompute(oi, thisScene,'aperture',aperture,'crop',true,'pixel size',3e-6);

eTime = 1/60;

sensorRGBW = sensorCreate('ar0132at',[],'rgbw');
sensorRGB = sensorCreate('ar0132at',[],'rgb');

sensorRGBW = sensorSet(sensorRGBW,'exp time',eTime);
sensorRGBW = sensorSet(sensorRGBW,'match oi',oi);

sensorRGBW = sensorSet(sensorRGBW,'analog gain', 1/10);
sensorRGBW = sensorCompute(sensorRGBW,oi);

sensorWindow(sensorRGBW);

sensorRGB = sensorSet(sensorRGB,'exp time',eTime);
sensorRGB = sensorSet(sensorRGB,'match oi',oi);

sensorRGB = sensorSet(sensorRGB,'analog gain', 1/10);
sensorRGB = sensorCompute(sensorRGB,oi);

sensorWindow(sensorRGB);
%%
ip = ipCreate;
ipRGB = ipCompute(ip, sensorRGB);
ipWindow(ipRGB);
srgb = ipGet(ipRGB,'srgb');imwrite(srgb, '~/Desktop/rgb.jpg');


ipRGBW = ipComputeNN(sensorRGBW, 'rgbw');
ipNNFile = '/Users/zhenyi/git_repo/dev/isethdrsensor/local/exr/01-Jul-2024/ISETSensor/ISET_Sensor/17H05S-rgbw-16.67.exr';
ipRGBW = ipComputeNN(sensorRGBW, 'rgbw',ipNNFile);
ipWindow(ipRGBW);
srgb = ipGet(ipRGBW,'srgb');imwrite(srgb, '~/Desktop/rgbw.jpg');
