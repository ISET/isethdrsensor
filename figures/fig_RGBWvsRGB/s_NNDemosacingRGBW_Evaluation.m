%% Setup
sensorRGBW = sensorCreate('ar0132at',[],'rgbw');
sensorRGB = sensorCreate('ar0132at',[],'rgb');
sensorRGB = sensorSet(sensorRGB,'exp time',1/30);
sensorRGBW = sensorSet(sensorRGBW,'exp time',1/30);
ip = ipCreate;
ip = ipSet(ip,'demosaic method','Adaptive Laplacian'); 
%% 
scene = sceneCreate('macbeth',80);
oi = oiCreate;
oi = oiCompute(oi, scene,'crop',true,'pixel size', 3e-6);
idx = 1;
sensorRGB = sensorSet(sensorRGB,'match oi',oi);
sensorRGBW = sensorSet(sensorRGBW,'match oi',oi);
%%
lux = [0.1:0.1:1, 2:10];
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
    ipRGBWNN = ipComputeNN(thisSensorRGBW, 'rgbw');
    ipWindow(ipRGBWNN); rgbwNNImg = ipGet(ipRGBWNN, 'srgb');
    if ii==1
        % gt
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
    rgbImg = ieScale(rgbImg, 1);
    rgbwImg = ieScale(rgbwImg, 1);
    rgbwNNImg = ieScale(rgbwNNImg, 1);
    
    dE_rgb(idx) = mean2(imcolordiff(rgbGT, rgbImg));
    dE_rgbw(idx) = mean2(imcolordiff(rgbGT, rgbwImg));
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
% imwrite(rgbwImg,'~/Desktop/rgbw.png')
% imwrite(rgbwNNImg,'~/Desktop/rgbwNN.png')
% imwrite(rgbImg,'~/Desktop/rgb.png')
