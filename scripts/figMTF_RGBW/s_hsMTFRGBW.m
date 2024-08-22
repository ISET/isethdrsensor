%% Get opening from s_NNDemosaicingRGBW_Evaluation
%

%% MTF comparison
%
%
%{
scene = sceneCreate('slanted bar', 500);
oi = oiCreate;
oi = oiCompute(oi, scene,'crop',true,'pixel size', 3e-6);
sensorRGB = sensorSet(sensorRGB,'match oi',oi);
sensorRGBW = sensorSet(sensorRGBW,'match oi',oi);
lux = [0.05 0. 10];
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
    ipRGBNN = ipComputeNN(thisSensorRGB, 'ar0132at-rgb');
    ipWindow(ipRGBNN); rgbNNImg = ipGet(ipRGBNN, 'srgb');
    % rgbw using restormer
    thisSensorRGBW = sensorCompute(sensorRGBW,oi);
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
    rgbNNImg = ieScale(rgbNNImg, 1);
    rgbwNNImg = ieScale(rgbwNNImg, 1);

    barImage = imcrop(rgbImg,rect);
    ret = ISO12233(barImage, dx,[],'none');
    rgbMTF50(ii) = ret;

    barImage = imcrop(rgbNNImg,rect);
    ret = ISO12233(barImage, dx,[],'none');
    rgbwMTF50(ii) = ret;

    barImage = imcrop(rgbwNNImg,rect);
    ret = ISO12233(barImage, dx);
    rgbwNNMTF50(ii) = ret;
end
%}


%%
%{
figure;
for jj = 1%[4, 7, 10]
    result =  rgbMTF50(jj);
    plot(result.freq, result.mtf(:,4), 'color', [0.0000, 0.4470, 0.7410], 'LineWidth', 2, 'LineStyle', '-');hold on;
    result =  rgbwMTF50(jj);
    plot(result.freq, result.mtf(:,4), 'color', [0.8500, 0.3250, 0.0980], 'LineWidth', 2, 'LineStyle', '--');
    result =  rgbwNNMTF50(jj);
    plot(result.freq, result.mtf(:,4), 'color', [0.4660, 0.6740, 0.1880], 'LineWidth', 2, 'LineStyle', '-.');
    hold off;
end
% legend('0.1lux','1lux','10lux');
legend('RGB','RGB-NN','RGBW-NN', 'FontSize', 14, 'Location', 'Best')
% [p,fname,e] = fileparts(ttext);
title('MTF at 0.1 lux', 'FontSize', 16);
xlabel('Spatial frequency cy/mm', 'FontSize', 16);
ylabel('Contrast reduction (SFR)', 'FontSize', 16);
ylim([0,1]);
%}