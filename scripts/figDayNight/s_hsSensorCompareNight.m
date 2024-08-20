%% Analyzing the OVT 3-capture sensor (Night)
%
% For the split pixel, we compare the pure LPD-LCG rendering with the
% rendering we get when we use the LPD-HCG and SPD-LCG.
%
% We write out the IP images.
% 
% We also compare the resolution and noise along a line through the
% headlights. 
%
% We also calculate the variance explained (R squared) of the noise
% free and the noisy, to illustrate that the split pixel design does
% better.
%
% The parallel script s_hsSplitPixelParameters does an analysis with
% the split pixel but varying parameters.
%
% Scene Creation
%
%  At this time, users need to get oiNight manually from us. We will
%  find a way to put it in an open, downloadable, site.
%
%  To see how we created oiDay and oiNight, s_hsDayNight
%
% See also
%   s_hsSplitPixelParameters, s_hsDayNight


%%
ieInit;

% Used in paper.
imageID = '1114091636';   % Red car, green car.  

% An option for some other time.
% imageID = '1112201236'; % - Good one

oiName = fullfile(isethdrsensorRootPath,'local',sprintf('oiNight-%s.mat',imageID));
load(oiName,'oiNight');
oiInput = oiNight;

%% Create the optics
[oi,wvf] = oiCreate('wvf');

% Choose some aperture properties.  These determine the flare and blur.
params = wvfApertureP;
params.nsides = 3;
params.dotmean = 50;
params.dotsd = 20;
params.dotopacity =0.5;
params.dotradius = 5;
params.linemean = 50;
params.linesd = 20;
params.lineopacity = 0.5;
params.linewidth = 2;

% Create the aperture
aperture = wvfAperture(wvf,params);

% Slight defocus.  Just a choice.
oi = oiSet(oi,'wvf zcoeffs',0.1,'defocus');   

%% Run a standard RGB sensor

% 626 row is bottom two lights  150 - 600
% 586 row is next lights up 250 900
% 551 row the distant cars - 1000 1200
% 296 row one of the upper lights  - 600 800
% 859 row, through the two white lines
% 142; % An interesting one, also

% 16e-3 is 60 h frame rate.  Used for all the captures below.
expTime   = 16e-3;   
whichLine = 626;   % Through the headlights
satLevel  = .99;

%% Simulate the Omnivision (OVT) Split pixel technology.

pixelSize = [3 3]*1e-6;
sensorSize = [1082 1926];

arrayType = 'ovt'; 

% The OVT design is a 3-capture (two large PD captures and one small PD).
sensorArray = sensorCreateArray('array type',arrayType,...
    'pixel size same fill factor',pixelSize,...
    'exp time',expTime, ...
    'quantizationmethod','analog', ...
    'size',sensorSize);

[sensorSplit,sensorArraySplit] = sensorComputeArray(sensorArray,oiInput,...
    'method','saturated', ...
    'saturated',satLevel);

%% Base vs Combined signals

% Base sensor
sensorLPD = sensorArraySplit(1);
uDataLPD  = sensorPlot(sensorLPD,'volts hline',[1 whichLine],'no fig',true);

% Now the combined
uDataSplit = sensorPlot(sensorSplit,'volts hline',[1 whichLine],'no fig',true);

ieNewGraphWin;
plot(uDataLPD.pos{1},uDataLPD.data{1},'k-','LineWidth',2);
hold on;
plot(uDataSplit.pos{1},uDataSplit.data{1},'b:','LineWidth',2);
grid on;
xlabel('Position (um)'); ylabel('Relative volts');
title('3-capture (OVT)'); 
set(gca,'yscale','log');

tmp = sprintf('split-%d-noise.pdf',whichLine);
exportgraphics(gcf,fullfile(isethdrsensorRootPath,'local',tmp));

%% Image process the RGB and split pixel

% The gamma value impacts the rendering quite a bit.
% The curves tell the story.

ipLPD = ipCreate;
sensorLPD = sensorArraySplit(1);
ipLPD = ipCompute(ipLPD,sensorLPD,'hdr white',true);
ipWindow(ipLPD,'render flag','rgb','gamma',0.25);

ipLPD2 = ipCreate;
sensorLPD2 = sensorArraySplit(2);
ipLPD2 = ipCompute(ipLPD2,sensorLPD2,'hdr white',true);
ipWindow(ipLPD2,'render flag','rgb','gamma',0.25);

ipSPD = ipCreate;
sensorSPD = sensorArraySplit(3);
ipSPD = ipCompute(ipSPD,sensorSPD,'hdr white',true);
ipWindow(ipSPD,'render flag','rgb','gamma',0.25);

% This one looks better either clipped or rendered with a very small
% (0.15) gamma.
ipSplit = ipCreate;
ipSplit = ipCompute(ipSplit,sensorSplit,'hdr white',true);
ipWindow(ipSplit,'render flag','rgb','gamma',0.25);

%%  Write out the IP images

rgb = ipGet(ipSplit,'srgb');
fname = fullfile(isethdrsensorRootPath,'local','night-split.png');
imwrite(rgb,fname);

rgb = ipGet(ipLPD,'srgb');
fname = fullfile(isethdrsensorRootPath,'local','night-lpd.png');
imwrite(rgb,fname);

rgb = ipGet(ipLPD2,'srgb');
fname = fullfile(isethdrsensorRootPath,'local','night-lpd2.png');
imwrite(rgb,fname);

rgb = ipGet(ipSPD,'srgb');
fname = fullfile(isethdrsensorRootPath,'local','night-spd.png');
imwrite(rgb,fname);

%% END


%% Some potential graphs
%{
% The pixels where we replace the LPD data with the SPD data should be
% relatively large, continuous blocks. But the way this happens is a
% bit odd, because the pixels near vSwing have noise added (a lot of
% shot noise) and this can drive their values down below the vSwing.
% Those values are incorrect.
%
% We should not add shot noise after clipping at voltage swing.  It
% must be added PRIOR to clipping. Reread the noise calculation to
% see what is going on.  In that case, when the intensity is very
% high, the saturated regions should not have any holes.
%

saturated = sensorSplit.metadata.saturated;

% Two images
%   (a) 1 is saturated
%   (b) 1 is not saturated, 2 is saturated
%   (c) 2 is saturated
ieNewGraphWin; imagesc(saturated(:,:,1)); axis image; title('Image 1 saturated')
ieNewGraphWin; imagesc(~saturated(:,:,1) .* saturated(:,:,2)); axis image; title('Image 2 saturated (but not 1)')
ieNewGraphWin; imagesc(saturated(:,:,2)); axis image; title('Image 2 saturated'); 
%}


%% Turn off the noise to compare
%{
sensorArrayNN = sensorCreateArray('array type',arrayType,...
    'pixel size same fill factor',pixelSize,...
    'exp time',expTime, ...
    'size',sensorSize, ...
    'quantizationmethod','analog', ...
    'noise flag',0);

[sensorSplitNN, sensorArraySplitNN] = sensorComputeArray(sensorArrayNN,oiInput,...
    'method','saturated', ...
    'saturated',satLevel);

%}

%% Older regression calculations

%{
% sensorLPDNN = sensorArraySplitNN(1);
% uDataLPDNN = sensorPlot(sensorLPDNN,'volts hline',[1 whichLine],'no fig',true);

% The red channel, compared
% channel = 1;
% x = uDataLPD.data{channel};
% y = uDataLPDNN.data{channel};
% s  = mean(x,'all','omitnan');
% s2 = mean(y,'all','omitnan');
% peak = 0.98/max(x);

ieNewGraphWin; 
plot(uDataLPD.pos{1},uDataLPD.data{1},'k-','LineWidth',2);
grid on;
xlabel('Position (um)')
ylabel('Relative volts');
title('1-capture (LPD-LCG)');
set(gca,'yscale','log');

tmp = sprintf('LPD-%d-noise.pdf',whichLine);
exportgraphics(gcf,fullfile(isethdrsensorRootPath,'local',tmp));

% Assuming x and y are your data vectors
X = [ones(length(x), 1), x];  % Add a column of ones for the intercept
[b,~,~,~,stats] = regress(y, X);
fprintf('LPD-HCG R_squared" %f\n',stats(1));
%}

% Assuming x and y are your data vectors
% X = [ones(length(x), 1), x];  % Add a column of ones for the intercept
% [b,~,~,~,stats] = regress(y, X);
% fprintf('Split R_squared" %f\n',stats(1));

% slope = b(2)
% intercept = b(1)

%%
%{
%% The noise and the improved spatial representation near the headlights

uSplit = ipPlot(ipSplit,'horizontal line luminance',[1 626],'no figure');
uLPD   = ipPlot(ipLPD,'horizontal line luminance',[1 626],'no figure');

ieNewGraphWin([],'wide');
plot(uSplit.pos,ieScale(uSplit.data,1),'k-',...
    uLPD.pos,ieScale(uLPD.data,1),'ko:','LineWidth',2);
legend({'3-capture OVT','LPD-LCG'});
grid on; set(gca,'xlim',[150 600]); 
xlabel('Column'); ylabel('Relative luminance');

tmp = sprintf('split-LPD-luminance.pdf');
exportgraphics(gcf,fullfile(isethdrsensorRootPath,'local',tmp));


%}
%% END

