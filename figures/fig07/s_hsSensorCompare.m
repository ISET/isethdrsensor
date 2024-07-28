%% Make a figure comparing the different types of sensors
%
% We compare the rendering of a nighttime HDR scene with a standard
% automotive RGB sensor and a similar sensor, but with the split pixel
% design, as proposed by Omnivision.
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
% the split pixel and varying parameters.
%
% See also
%   s_hsSplitPixelParameters

%% Notes on Scene Creation
%
% At this time, people need to get oiNight manually for this to work. We
% will find a way to put it in an open, downloadable, site.
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

% Here is the standard sensor
sensorRGB = sensorCreate('ar0132at',[],'rgb');
sensorRGB = sensorSet(sensorRGB,'match oi',oiInput);
sensorRGB = sensorSet(sensorRGB,'exp time',expTime);
sensorRGB = sensorSet(sensorRGB,'noise flag',2);
sensorRGB = sensorCompute(sensorRGB,oiInput);

sensorWindow(sensorRGB,'gamma',0.3);

% Save out the RGB image
rgb = sensorGet(sensorRGB,'rgb');
imName = sprintf('ar0132atSensor.png');
imwrite(rgb,fullfile(isethdrsensorRootPath,'local',imName));

%{
% Have a close look, if you want.
sensorShowImage(sensorRGB,sensorGet(sensorRGB,'gamma'),true,ieNewGraphWin);
truesize
%}

%% Turn off the noise, recompute, and show the noise.

whichLine = 859;   
% whichLine = 142; % An interesting one, also

% No noise.
sensorRGB2 = sensorSet(sensorRGB,'noise flag',0);
sensorRGB2 = sensorSet(sensorRGB2,'name','no noise');
sensorRGB2 = sensorCompute(sensorRGB2,oiInput);
% sensorWindow(sensorRGB2,'gamma',0.3);

uDataRGB  = sensorPlot(sensorRGB,'volts hline',[1 whichLine],'no fig',true);
uDataRGB2 = sensorPlot(sensorRGB2,'volts hline',[1 whichLine],'no fig',true);

% The red channel
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
title('1-capture (ar0132at)');
tmp = sprintf('rgb-%d-noise.pdf',whichLine);
exportgraphics(gcf,fullfile(isethdrsensorRootPath,'local',tmp));

%% Calculate how closely the measurements track the no noise values

% Assuming x and y are your data vectors
X = [ones(length(x), 1), x];  % Add a column of ones for the intercept
[b,~,~,~,stats] = regress(y, X);
fprintf('RGB R_squared" %f\n',stats(1));

%% Now the Omnivision (OVT) Split pixel technology.

pixelSize = sensorGet(sensorRGB,'pixel size');
sensorSize = sensorGet(sensorRGB,'size');
arrayType = 'ovt'; 

% The OVT design is a 3-capture (two large PD captures and one small PD).
sensorArray = sensorCreateArray('array type',arrayType,...
    'pixel size same fill factor',pixelSize,...
    'exp time',expTime, ...
    'quantizationmethod','analog', ...
    'size',sensorSize);

[sensorSplit,sensorArraySplit] = sensorComputeArray(sensorArray,oiInput,'method','saturated');
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
[sensorSplit2, sensorArraySplit2] = sensorComputeArray(sensorArray,oiInput,'method','saturated');

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

ipRGB = ipCreate;
ipRGB = ipCompute(ipRGB,sensorRGB);
ipWindow(ipRGB,'render flag','rgb','gamma',0.25);
rgb = ipGet(ipRGB,'srgb');
fname = fullfile(isethdrsensorRootPath,'local','ip-ar0132at.png');
imwrite(rgb,fname);

ipSplit = ipCreate;
ipSplit = ipCompute(ipSplit,sensorSplit,'hdr white',true);
ipWindow(ipSplit,'render flag','rgb','gamma',0.25);
rgb = ipGet(ipSplit,'srgb');
fname = fullfile(isethdrsensorRootPath,'local','ip-split.png');
imwrite(rgb,fname);

%% Show the improved spatial representation near the headlights

% 626 row is bottom two lights  150 - 600
% 586 row is next lights up 250 900
% 551 row the distant cars - 1000 1200
% 296 row one of the upper lights  - 600 800
uSplit = ipPlot(ipSplit,'horizontal line luminance',[1 626],'no figure');
uRGB   = ipPlot(ipRGB,'horizontal line luminance',[1 626],'no figure');

ieNewGraphWin([],'wide');
plot(uSplit.pos,ieScale(uSplit.data,1),'k-',...
    uRGB.pos,ieScale(uRGB.data,1),'ko:','LineWidth',2);
legend({'split','rgb'});
grid on; set(gca,'xlim',[150 600]); 
xlabel('Column'); ylabel('Relative luminance');

tmp = sprintf('split-ar0132at-luminance.pdf');
exportgraphics(gcf,fullfile(isethdrsensorRootPath,'local',tmp));

%%  Look at the individual captures

gam = 0.3; scaleMax = 1;
for ii=1:numel(sensorArraySplit)
    img = sensorShowImage(sensorArraySplit(ii),gam,scaleMax,0);
    tmp = sprintf('%s.png',sensorGet(sensorArraySplit(ii),'name'));
    imwrite(img,fullfile(isethdrsensorRootPath,'local',tmp));
    sensorWindow(sensorArraySplit(ii));
end

img = sensorShowImage(sensorSplit,gam,scaleMax,0);
tmp = sprintf('%s.png',sensorGet(sensorSplit,'name'));
imwrite(img,fullfile(isethdrsensorRootPath,'local',tmp));

%% Some potential graphs

% In most places, we can average the data from the two LPD captures
% There is only a small region where 2 is captured and 1 is not.
% In the region where 1 is saturated, 2 is also saturated.  There, we use
% the SPD data.
saturated = sensorSplit.metadata.saturated;

% Where is (a) 1 and 2 are saturated
%          (b) 1 is not saturated, but 2 is saturated
ieNewGraphWin;
tiledlayout(2,1);
nexttile; imagesc(saturated(:,:,1) .* saturated(:,:,2)); axis image;
subtitle('Image 1 and 2 are saturated')
nexttile; imagesc(~saturated(:,:,1) .* saturated(:,:,2)); axis image;
subtitle('Image 2 saturated (but not 1)')

%% END