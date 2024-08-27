%% What is the impact of the NN demosaic network on the MTF
%
%
% It's really pretty good.
%

%%
ieInit;

%%
sensorRGBW = sensorCreate('ar0132at',[],'rgbw');
sensorRGB  = sensorCreate('ar0132at',[],'rgb');
sensorRGB  = sensorSet(sensorRGB,'exp time',1/60);
sensorRGBW = sensorSet(sensorRGBW,'exp time',1/60);

sensorRGB  = sensorSet(sensorRGB,'pixel size constant fill factor',4e-6);
sensorRGB  = sensorSet(sensorRGB, 'sensor size', [512, 512]);
sensorRGBW = sensorSet(sensorRGBW,'pixel size constant fill factor',4e-6);
sensorRGBW = sensorSet(sensorRGBW, 'sensor size', [512, 512]);

%% Slanted bar for the MTF
%
scene = sceneCreate('slanted bar', 500);
oi = oiCreate;
oi = oiCompute(oi, scene,'crop',true,'pixel size', 3e-6);

sensorRGB = sensorSet(sensorRGB,'match oi',oi);
sensorRGBW = sensorSet(sensorRGBW,'match oi',oi);

% Bright to dim
lux = logspace(-.8,0,3);
mtfPlot = 'none';
%%
ip = ipCreate;
for ii = 1:numel(lux)
    oi = oiAdjustIlluminance(oi, lux(ii));

    % rgb
    thisSensorRGB = sensorCompute(sensorRGB,oi);
    ipRGB = ipCompute(ip, thisSensorRGB);
    mtfRGB = ieISO12233(ipRGB,thisSensorRGB);

    if ~isempty(mtfRGB)

        %ipWindow(ipRGB); rgbImg = ipGet(ipRGB, 'srgb');

        % rgb
        ipRGBNN = ipCompute(ip, thisSensorRGB, 'network demosaic','ar0132at-rgb');
        mtfRGBNN = ieISO12233(ipRGBNN,thisSensorRGB,mtfPlot);
        % ipWindow(ipRGBNN); rgbNNImg = ipGet(ipRGBNN, 'srgb');

        % rgbw using restormer
        thisSensorRGBW = sensorCompute(sensorRGBW,oi);
        ipRGBWNN = ipCompute(ip,thisSensorRGBW, 'network demosaic','ar0132at-rgbw');
        mtfRGBWNN = ieISO12233(ipRGBWNN,thisSensorRGBW,mtfPlot);

        if ii==1
            % Process for the brightest case
            sensorI = sensorCreateIdeal('match',sensorRGB);
            sensorI = sensorCompute(sensorI,oi);
            
            gtImg(:,:,1) = sensorI(1).data.volts;
            gtImg(:,:,2) = sensorI(2).data.volts;
            gtImg(:,:,3) = sensorI(3).data.volts;

            ipIdeal = ipRGB;
            ipIdeal = ipSet(ipIdeal, 'demosaic method', 'skip');
            ipIdeal = ipSet(ipIdeal, 'transform method', 'current');
            ipIdeal = ipSet(ipIdeal, 'sensor space', gtImg);

            % Compute the final image processing
            ipIdeal = ipCompute(ipIdeal, thisSensorRGB);
            mtfIdeal = ieISO12233(ipIdeal,thisSensorRGB,mtfPlot);
        end

        %% Plot

        ieNewGraphWin;
        plot(mtfIdeal.freq,mtfIdeal.mtf(:,4),'k-'); hold on;
        plot(mtfRGBWNN.freq,mtfRGBWNN.mtf(:,4),'ro'); hold on;
        plot(mtfRGBNN.freq,mtfRGBNN.mtf(:,4),'gs'); hold on;
        plot(mtfRGB.freq,mtfRGB.mtf(:,4),'b--'); hold on;
        grid on;
        xlabel('Spatial frequency (cyc/mm)'); ylabel('SFR');
        legend({'ideal','rgbw-nn','rgb-nn','rgb'});

        title(sprintf('MTF at lux %.1f',lux(ii)));

        %% Line spread!

        ieNewGraphWin;

        plot(mtfIdeal.lsfx*1e3,mtfIdeal.lsf); hold on;
        plot(mtfRGBWNN.lsfx*1e3,mtfRGBWNN.lsf); hold on;
        plot(mtfRGBNN.lsfx*1e3,mtfRGBNN.lsf); hold on;
        plot(mtfRGB.lsfx*1e3,mtfRGB.lsf); hold on;
        set(gca,'xlim',[-30 30]);

        grid on;
        xlabel('Position (microns)'); ylabel('Estimated intensity')
        title('Edge spreads and LSF');
        set(gca,'xtick',-80:10:80)
        hold on;
        legend({'ideal','rgbw-nn','rgb-nn','rgb'});
    end

end

%%