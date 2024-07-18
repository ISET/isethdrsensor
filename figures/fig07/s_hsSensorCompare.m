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
imageID = '1114091636';   % Red car, green car

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
oi = oiSet(oi,'wvf zcoeffs',0,'defocus');

%%  If you want the oiDay, this is how

%{
wgts = [0    0     0    100*0.5175]; % Day
scene = hsSceneCreate(imageID,'weights',wgts,'denoise',false);
oiDay = oiCompute(oi, scene,'aperture',aperture,'crop',true,'pixel size',3e-6);
oiWindow(oiDay,'gamma',0.5,'render flag','rgb');
srgb = oiGet(oiDay,'rgb'); ieNewGraphWin; image(srgb); truesize
%}

%% Night scene weights

% For final, remember to turn off denoise

% Experimenting with how dark.  4 log units down gets night
% But three really doesn't.
wgts    = [0.2306    0.0012    0.0001    1e-2*0.5175]; % Night
scene   = hsSceneCreate(imageID,'weights',wgts,'denoise',true);
oiNight = oiCompute(oi, scene,'aperture',aperture,'crop',true,'pixel size',3e-6);
oiWindow(oiNight,'render flag','rgb','gamma',0.2);

%% Standard automotive rgb

sensorRGB = sensorCreate('ar0132at',[],'rgb');
sensorRGB = sensorSet(sensorRGB,'match oi',oiNight);
sensorRGB = sensorSet(sensorRGB,'exp time',16e-3);
sensorRGB = sensorSet(sensorRGB,'noise flag',2);
sensorRGB = sensorCompute(sensorRGB,oiNight);
sensorWindow(sensorRGB,'gamma',0.3);

rgb = sensorGet(sensorRGB,'rgb');
ieNewGraphWin; imagesc(rgb); truesize;
imName = sprintf('rgbSensor.png');
imwrite(rgb,fullfile(isethdrsensorRootPath,'local',imName));

%% Turn off the noise and recompute

% For this scene ID:  1114091636
whichLine = 859;   
% whichLine = 142; % An interesting one, also

sensorRGB2 = sensorSet(sensorRGB,'noise flag',-1);
sensorRGB2 = sensorSet(sensorRGB2,'name','no noise');
sensorRGB2 = sensorCompute(sensorRGB2,oiNight);
sensorWindow(sensorRGB2,'gamma',0.3);

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
title('RGB pixel');
tmp = sprintf('rgb-%d-noise.pdf',whichLine);
exportgraphics(gcf,fullfile(isethdrsensorRootPath,'local',tmp));

% Assuming x and y are your data vectors
X = [ones(length(x), 1), x];  % Add a column of ones for the intercept
[b,~,~,~,stats] = regress(y, X);
fprintf('RGB R_squared" %f\n',stats(1));

%% Split pixel , night time.  Default parameters.
% See s_hsSplitPixelParameters

pixelSize = sensorGet(sensorRGB,'pixel size');
sensorSize = sensorGet(sensorRGB,'size');

% IMX490 or OVT
% I ran both.  The IMX490 does well.  The OVT design, not as well.  I think
% that is interesting.  3-capture vs. 4-capture.  The additional HCG in the
% small pixel picks up the dark region!
sensorArray = sensorCreateArray('array type','imx490',...
    'pixel size same fill factor',pixelSize,...
    'exp time',16e-3, ...
    'size',sensorSize);

sensorSplit = sensorComputeArray(sensorArray,oiNight);
sensorWindow(sensorSplit,'gamma',0.3);

% We probably need to reset gamma to 1 before these sensorGet calls
rgb = sensorGet(sensorSplit,'rgb');

% ieNewGraphWin; imagesc(rgb); truesize;
imName = sprintf('splitSensor.png');
imwrite(rgb,fullfile(isethdrsensorRootPath,'local',imName));

%% Turn off the noise and compare

sensorArray = sensorCreateArray('array type','ovt',...
    'pixel size same fill factor',pixelSize,...
    'exp time',16e-3, ...
    'size',sensorSize, ...
    'noise flag',-1);
[sensorSplit2, sensorArray] = sensorComputeArray(sensorArray,oiNight);

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
title('Split pixel');
tmp = sprintf('split-%d-noise.pdf',whichLine);
exportgraphics(gcf,fullfile(isethdrsensorRootPath,'local',tmp));

% Assuming x and y are your data vectors
X = [ones(length(x), 1), x];  % Add a column of ones for the intercept
[b,~,~,~,stats] = regress(y, X);
fprintf('Split R_squared" %f\n',stats(1));
% slope = b(2)
% intercept = b(1)


%% image process?

ip = ipCreate;
ip = ipCompute(ip,sensorSplit);
ipWindow(ip,'render flag','rgb','gamma',0.25);

ip = ipCompute(ip,sensorRGB);
ipWindow(ip,'render flag','rgb','gamma',0.25);

%%