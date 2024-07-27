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

%%
ieInit;

% imageID = '1112201236'; % - Good one
imageID = '1114091636';   % Red car, green car.  Used in paper.

%% Day scene weights

% sceneWindow(scene,'render flag','clip');

%% Create the optics
[oi,wvf] = oiCreate('wvf');
params = wvfApertureP;
% We should implement wvfApertureSet/Get so we do not have to remember
% the parameter names precisely.
% {
params.nsides = 3;
params.dotmean = 50;
params.dotsd = 20;
params.dotopacity =0.5;
params.dotradius = 5;
params.linemean = 50;
params.linesd = 20;
params.lineopacity = 0.5;
params.linewidth = 2;
%}

aperture = wvfAperture(wvf,params);
oi = oiSet(oi,'wvf zcoeffs',0.1,'defocus');   % Slight defocus.  Not sure why.

%%  If you want the oiDay, this is how

%{
wgts = [0    0     0    100*0.5175]; % Day
scene = hsSceneCreate(imageID,'weights',wgts,'denoise',true);
oiDay = oiCompute(oi, scene,'aperture',aperture,'crop',true,'pixel size',3e-6);
oiWindow(oiDay,'gamma',0.5,'render flag','rgb');

oiName = fullfile(isethdrsensorRootPath,'local',sprintf('oiDay-%s.mat',imageID));
save(oiName,'oiDay','-v7.3');

%}

%% Night scene weights

% For final, remember to turn off denoise

% Experimenting with how dark.  4 log units down gets night
% But three really doesn't.

%{
wgts    = [0.2306    0.0012    0.0001    1e-2*0.5175]; % Night
scene   = hsSceneCreate(imageID,'weights',wgts,'denoise',true);
oiNight = oiCompute(oi, scene,'aperture',aperture,'crop',true,'pixel size',3e-6);
oiWindow(oiNight,'render flag','rgb','gamma',0.2);

oiName = fullfile(isethdrsensorRootPath,'local',sprintf('oiNight-%s.mat',imageID));
save(oiName,'oiNight','-v7.3');
%}

%% Standard automotive rgb

% To speed things up
% {
 oiName = fullfile(isethdrsensorRootPath,'local',sprintf('oiNight-%s.mat',imageID));
 load(oiName,'oiNight');
 oiInput = oiNight;
%}
%{
 oiName = fullfile(isethdrsensorRootPath,'local',sprintf('oiDay-%s.mat',imageID));
 load(oiName,'oiDay');
 oiInput = oiDay;
%}

%%
expTime = 16e-3;   % 16e-3 is 60 hz.
sensorRGB = sensorCreate('ar0132at',[],'rgb');
sensorRGB = sensorSet(sensorRGB,'match oi',oiInput);
sensorRGB = sensorSet(sensorRGB,'exp time',expTime);
sensorRGB = sensorSet(sensorRGB,'noise flag',2);
sensorRGB = sensorCompute(sensorRGB,oiInput);
sensorWindow(sensorRGB,'gamma',0.3);

rgb = sensorGet(sensorRGB,'rgb');
imName = sprintf('ar0132atSensor.png');
imwrite(rgb,fullfile(isethdrsensorRootPath,'local',imName));

%{ 
sensorShowImage(sensorRGB,sensorGet(sensorRGB,'gamma'),true,ieNewGraphWin);
truesize
%}

%% Turn off the noise and recompute

% For this scene ID:  1114091636
whichLine = 859;   

% whichLine = 142; % An interesting one, also

sensorRGB2 = sensorSet(sensorRGB,'noise flag',0);
sensorRGB2 = sensorSet(sensorRGB2,'name','no noise');
sensorRGB2 = sensorCompute(sensorRGB2,oiInput);
% sensorWindow(sensorRGB2,'gamma',0.3);

% sensorPlot(sensorRGB2,'volts hline',[1 whichLine], 'two lines',true);
% sensorPlot(sensorRGB,'volts hline',[1 whichLine], 'two lines',true);
uDataRGB = sensorPlot(sensorRGB,'volts hline',[1 whichLine],'no fig',true);
uDataRGB2 = sensorPlot(sensorRGB2,'volts hline',[1 whichLine],'no fig',true);
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

% Assuming x and y are your data vectors
X = [ones(length(x), 1), x];  % Add a column of ones for the intercept
[b,~,~,~,stats] = regress(y, X);
fprintf('RGB R_squared" %f\n',stats(1));

%% Split pixel , night time.  Default parameters.

pixelSize = sensorGet(sensorRGB,'pixel size');
sensorSize = sensorGet(sensorRGB,'size');

arrayType = 'ovt'; % imx490 ovt

% IMX490 or OVT
% I ran both.  The IMX490 does well.  The OVT design, not as well.  I think
% that is interesting.  3-capture vs. 4-capture.  The additional HCG in the
% small pixel picks up the dark region!
sensorArray = sensorCreateArray('array type',arrayType,...
    'pixel size same fill factor',pixelSize,...
    'exp time',expTime, ...
    'quantizationmethod','analog', ...
    'size',sensorSize);

[sensorSplit,sensorArraySplit] = sensorComputeArray(sensorArray,oiInput,'method','saturated');
sensorWindow(sensorSplit,'gamma',0.3);

% We probably need to reset gamma to 1 before these sensorGet calls
rgb = sensorGet(sensorSplit,'rgb');

%{ 
sensorShowImage(sensorSplit,sensorGet(sensorSplit,'gamma'),true,ieNewGraphWin);
truesize
%}
imName = sprintf('splitSensor.png');
imwrite(rgb,fullfile(isethdrsensorRootPath,'local',imName));

%% Turn off the noise and compare

sensorArray = sensorCreateArray('array type',arrayType,...
    'pixel size same fill factor',pixelSize,...
    'exp time',expTime, ...
    'size',sensorSize, ...
    'quantizationmethod','analog', ...
    'noise flag',0);
[sensorSplit2, sensorArraySplit2] = sensorComputeArray(sensorArray,oiInput,'method','saturated');

% sensorPlot(sensorSplit2,'volts hline',[1 whichLine], 'two lines',true);
% sensorPlot(sensorSplit,'volts hline',[1 whichLine], 'two lines',true);
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

%% image process?

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

%% Show the narrowing around the lights

% 626 row is bottom two lights  150 - 600
% 586 row is next lights up 250 900
% 551 row the distant cars - 1000 1200
% 296 row one of the upper lights  - 600 800
uSplit = ipPlot(ipSplit,'horizontal line luminance',[1 626],'no figure');
uRGB = ipPlot(ipRGB,'horizontal line luminance',[1 626],'no figure');

ieNewGraphWin([],'wide');
plot(uSplit.pos,ieScale(uSplit.data,1),'k-',uRGB.pos,ieScale(uRGB.data,1),'ko:','LineWidth',2);
legend({'split','rgb'});
grid on;
set(gca,'xlim',[150 600])
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

%%
%{
ieNewGraphWin; imagesc(sensorSplit.metadata.bestPixel);
colormap([1,0,0; 0,1,0; 0,0,1]);

histogram(sensorSplit.metadata.bestPixel(:));
%}
%{
saturated = sensorSplit.metadata.saturated;

% Where is (a) 1 is saturated, and 
%          (b) 1 is not saturated, but 2 is saturated
ieNewGraphWin;
tiledlayout(2,1);
nexttile; imagesc(saturated(:,:,1));
nexttile; imagesc(~saturated(:,:,1) .* saturated(:,:,2));
%}