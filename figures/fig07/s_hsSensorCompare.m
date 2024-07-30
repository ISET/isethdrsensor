%% Make a figure comparing the different types of sensors
%
% We compare the rendering of a nighttime HDR scene with a standard
% automotive RGB sensor and a similar sensor, but with the split pixel
% design, as proposed by Omnivision.
%
% For the split pixel, we compare the pure LPD-LCG rendering with the
% rendering we get when we use the LPD-HCG and SPD-LCG.
%
% We write out the sensor images, and we also compare the noise along
% a couple of lines by plotting the response and plotting the
% simulation noise free.
%
% We also calculate the variance explained (R squared) of the noise
% free and the noisy, to illustrate that the split pixel design does
% better.
%
% The parallel script s_hsSplitPixelParameters does an analysis with
% the split pixel but varying parameters.
%
% See also
%   s_hsSplitPixelParameters

%% Notes on Scene Creation
%
% At this time, users need to get oiNight manually from us. We will find a
% way to put it in an open, downloadable, site.
%

%%  This is how we created oiDay

%{
imageID = '1114091636';   % Red car, green car.  
wgts = [0    0     0    100*0.5175]; % Day
scene = hsSceneCreate(imageID,'weights',wgts,'denoise',true);
oiDay = oiCompute(oi, scene,'aperture',aperture,'crop',true,'pixel size',3e-6);
oiWindow(oiDay,'gamma',0.5,'render flag','rgb');

oiName = fullfile(isethdrsensorRootPath,'local',sprintf('oiDay-%s.mat',imageID));
save(oiName,'oiDay','-v7.3');
%}

%% This is how we created oiNight

%{
imageID = '1114091636';   % Red car, green car.  
wgts    = [0.2306    0.0012    0.0001    1e-2*0.5175]; % Night
scene   = hsSceneCreate(imageID,'weights',wgts,'denoise',true);
oiNight = oiCompute(oi, scene,'aperture',aperture,'crop',true,'pixel size',3e-6);
oiWindow(oiNight,'render flag','rgb','gamma',0.2);

oiName = fullfile(isethdrsensorRootPath,'local',sprintf('oiNight-%s.mat',imageID));
save(oiName,'oiNight','-v7.3');
%}


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

% 16e-3 is 60 h frame rate.  Used for all the captures below.
expTime = 16e-3;   
whichLine = 859;
satLevel = .99;
% whichLine = 142; % An interesting one, also

%% Simulate the Omnivision (OVT) Split pixel technology.

% pixelSize = sensorGet(sensorRGB,'pixel size');
% sensorSize = sensorGet(sensorRGB,'size');

pixelSize = [3 3]*1e-6;
sensorSize = [1082 1926];

arrayType = 'ovt'; 

% The OVT design is a 3-capture (two large PD captures and one small PD).
sensorArray = sensorCreateArray('array type',arrayType,...
    'pixel size same fill factor',pixelSize,...
    'exp time',expTime, ...
    'quantizationmethod','analog', ...
    'size',sensorSize);

%% Use just the LPD-LCG sensor

% Base sensor
sensorLPD = sensorArray(1);
sensorLPD = sensorCompute(sensorLPD,oiInput);
sensorWindow(sensorLPD);
uDataRGB  = sensorPlot(sensorLPD,'volts hline',[1 whichLine],'no fig',true);

% We probably need to reset gamma to 1 before these sensorGet calls
rgb = sensorGet(sensorLPD,'rgb');

imName = sprintf('sensorLPD.png');
imwrite(rgb,fullfile(isethdrsensorRootPath,'local',imName));

%% Without noise

sensorLPD2 = sensorSet(sensorLPD,'noise flag',0);
sensorLPD2 = sensorCompute(sensorLPD2,oiInput);
uDataRGB2 = sensorPlot(sensorLPD2,'volts hline',[1 whichLine],'no fig',true);

% The red channel, compared
channel = 1;
x = uDataRGB.data{channel};
y = uDataRGB2.data{channel};
s  = mean(x,'all','omitnan');
s2 = mean(y,'all','omitnan');
peak = 0.98/max(x);

ieNewGraphWin; 
plot(uDataRGB.pos{1},(peak*x),'r-', ...
    uDataRGB2.pos{1},(peak*y)*(s/s2),'k-','LineWidth',2);
grid on;
xlabel('Position (um)')
ylabel('Relative volts');
title('1-capture (LPD-LCG)');
tmp = sprintf('LPD-%d-noise.pdf',whichLine);
exportgraphics(gcf,fullfile(isethdrsensorRootPath,'local',tmp));

% Assuming x and y are your data vectors
X = [ones(length(x), 1), x];  % Add a column of ones for the intercept
[b,~,~,~,stats] = regress(y, X);
fprintf('LPD-HCG R_squared" %f\n',stats(1));

%% The full 3-capture

[sensorSplit,sensorArraySplit] = sensorComputeArray(sensorArray,oiInput,...
    'method','saturated', ...
    'saturated',satLevel);
sensorWindow(sensorSplit,'gamma',0.3);

% We probably need to reset gamma to 1 before these sensorGet calls
rgb = sensorGet(sensorSplit,'rgb');

imName = sprintf('splitSensor.png');
imwrite(rgb,fullfile(isethdrsensorRootPath,'local',imName));

%{ 
sensorShowImage(sensorSplit,sensorGet(sensorSplit,'gamma'),true,ieNewGraphWin);
truesize
%}

%% Turn off the noise and compare

sensorArray = sensorCreateArray('array type',arrayType,...
    'pixel size same fill factor',pixelSize,...
    'exp time',expTime, ...
    'size',sensorSize, ...
    'quantizationmethod','analog', ...
    'noise flag',0);

[sensorSplit2, sensorArraySplit2] = sensorComputeArray(sensorArray,oiInput,...
    'method','saturated', ...
    'saturated',satLevel);

%%
uDataRGB = sensorPlot(sensorSplit,'volts hline',[1 whichLine],'no fig',true);
uDataRGB2 = sensorPlot(sensorSplit2,'volts hline',[1 whichLine],'no fig',true);

% The two sensor data sets need to be scaled because of the brittle
% way we scale the volts in the returned sensorSplit.  It is very
% sensitive to the presence of noise.  We also scale so that the
% largest voltage in the noise free is 0.98 volts

channel = 1;
x = uDataRGB.data{channel};
y = uDataRGB2.data{channel};
s  = mean(x,'all','omitnan');
s2 = mean(y,'all','omitnan');
peak = 0.98/max(x);

ieNewGraphWin;
plot(uDataRGB.pos{1},(peak*x),'r-', ...
    uDataRGB2.pos{1},(peak*y)*(s/s2),'k-','LineWidth',2);
grid on;
xlabel('Position (um)')
ylabel('Relative volts');
title('3-capture (OVT)');
tmp = sprintf('split-%d-noise.pdf',whichLine);
exportgraphics(gcf,fullfile(isethdrsensorRootPath,'local',tmp));

% Assuming x and y are your data vectors
X = [ones(length(x), 1), x];  % Add a column of ones for the intercept
[b,~,~,~,stats] = regress(y, X);
fprintf('Split R_squared" %f\n',stats(1));


% slope = b(2)
% intercept = b(1)

%% Image process the RGB and split pixel

ipSplit = ipCreate;
ipSplit = ipCompute(ipSplit,sensorSplit,'hdr white',true);
ipWindow(ipSplit,'render flag','rgb','gamma',0.25);
rgb = ipGet(ipSplit,'srgb');
fname = fullfile(isethdrsensorRootPath,'local','ip-split.png');
imwrite(rgb,fname);

ipLPD = ipCreate;
ipLPD = ipCompute(ipLPD,sensorLPD,'hdr white',true);
ipWindow(ipLPD,'render flag','rgb','gamma',0.25);
rgb = ipGet(ipLPD,'srgb');
fname = fullfile(isethdrsensorRootPath,'local','ip-LPD.png');
imwrite(rgb,fname);

%% Show the improved spatial representation near the headlights

% 626 row is bottom two lights  150 - 600
% 586 row is next lights up 250 900
% 551 row the distant cars - 1000 1200
% 296 row one of the upper lights  - 600 800
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

%% Some potential graphs

% In most places, we can average the data from the two LPD captures
% There is only a small region where 2 is captured and 1 is not.
% In the region where 1 is saturated, 2 is also saturated.  There, we use
% the SPD data.
saturated = sensorSplit.metadata.saturated;

% Two images
%   (a) 1 is saturated
%   (b) 1 is not saturated, 2 is saturated
%   (c) 2 is saturated
ieNewGraphWin([],'tall');
tiledlayout(3,1);
nexttile; imagesc(saturated(:,:,1)); axis image;
subtitle('Image 1 saturated')
nexttile; imagesc(~saturated(:,:,1) .* saturated(:,:,2)); axis image;
subtitle('Image 2 saturated (but not 1)')
nexttile; imagesc(saturated(:,:,2)); axis image
subtitle('Image 2 saturated'); axis image
drawnow;

%% END

