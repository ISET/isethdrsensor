%% Analyzing the OVT 3-capture sensor (Day)
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
% To see how we created oiDay and oiNight, see the end of this script,
% or the end of s_hsSensorCompare.
%

%%
ieInit;

% Used in paper.
imageID = '1114091636';   % Red car, green car.  

% An option for some other time.
% imageID = '1112201236'; % - Good one

oiName = fullfile(isethdrsensorRootPath,'local',sprintf('oiDay-%s.mat',imageID));
load(oiName,'oiDay');
oiInput = oiDay;

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

%% Simulate the Omnivision (OVT) Split pixel technology.

% LPD is saturated at half a millisecond
expTime = 0.5e-3;   
satLevel = .95;
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

%% Image process the RGB and split pixel

ipLPD = ipCreate;
sensorLPD = sensorArraySplit(1);
ipLPD = ipCompute(ipLPD,sensorLPD,'hdr white',true);
ipWindow(ipLPD,'render flag','rgb','gamma',0.5);

ipLPD2 = ipCreate;
sensorLPD2 = sensorArraySplit(2);
ipLPD2 = ipCompute(ipLPD2,sensorLPD2,'hdr white',true);
ipWindow(ipLPD2,'render flag','rgb','gamma',0.5);

ipSPD = ipCreate;
sensorSPD = sensorArraySplit(3);
ipSPD = ipCompute(ipSPD,sensorSPD,'hdr white',true);
ipWindow(ipSPD,'render flag','rgb','gamma',0.5);

ipSplit = ipCreate;
ipSplit = ipCompute(ipSplit,sensorSplit,'hdr white',true);
ipWindow(ipSplit,'render flag','rgb','gamma',0.5);

%%

rgb = ipGet(ipSplit,'srgb');
fname = fullfile(isethdrsensorRootPath,'local','day-split.png');
imwrite(rgb,fname);

rgb = ipGet(ipLPD,'srgb');
fname = fullfile(isethdrsensorRootPath,'local','day-lpd.png');
imwrite(rgb,fname);

rgb = ipGet(ipLPD2,'srgb');
fname = fullfile(isethdrsensorRootPath,'local','day-lpd2.png');
imwrite(rgb,fname);

rgb = ipGet(ipSPD,'srgb');
fname = fullfile(isethdrsensorRootPath,'local','day-spd.png');
imwrite(rgb,fname);

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

%% END


%{
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

% sensorArray(3) = sensorSet(sensorArray(3),'pixel fill factor',1);

[sensorSplit,sensorArraySplit] = sensorComputeArray(sensorArray,oiInput,...
    'method','saturated', ...
    'saturated',satLevel);
%{
% Check that it is OK.
ip = ipCreate; 
ip = ipCompute(ip,sensorSplit,'hdr white',true); ipWindow(ip,'gamma',0.7);
ip = ipCompute(ip,sensorArraySplit(1),'hdr white',true); ipWindow(ip,'gamma',0.7); 
ip = ipCompute(ip,sensorArraySplit(3),'hdr white',true); ipWindow(ip,'gamma',0.7); 
%}

% sensorWindow(sensorSplit,'gamma',0.7);

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

%}