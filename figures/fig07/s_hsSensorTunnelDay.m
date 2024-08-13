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

%%
ieInit;
load('compareDay.mat');
%% Run a standard RGB sensor

% 16e-3 is 60 h frame rate.  Used for all the captures below.
expTime = 1.2*.2e-3;   
whichLine = 859;
satLevel = .99;
pixelFillFactor = 0.1;

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
sensorArray(3) = sensorSet(sensorArray(3),'pixel fill factor',pixelFillFactor);

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

%%

% Small photodiode
sensorSPD = sensorArray(3);
sensorSPD = sensorCompute(sensorSPD,oiInput);
sensorWindow(sensorSPD);


%% The full 3-capture

% sensorArray(3) = sensorSet(sensorArray(3),'pixel fill factor',1);

[sensorSplit,sensorArraySplit] = sensorComputeArray(sensorArray,oiInput,...
    'method','saturated', ...
     'saturated',satLevel);

sensorWindow(sensorSplit,'gamma',0.7);

% We probably need to reset gamma to 1 before these sensorGet calls
rgb = sensorGet(sensorSplit,'rgb');

imName = sprintf('splitSensor.png');
imwrite(rgb,fullfile(isethdrsensorRootPath,'local',imName));

%% Image process the RGB and split pixel

ipLPD = ipCreate;
ipLPD = ipCompute(ipLPD,sensorLPD,'hdr white',false);
ipWindow(ipLPD,'render flag','rgb','gamma',0.5);
rgb = ipGet(ipLPD,'srgb');
fname = fullfile(isethdrsensorRootPath,'local','ip-LPD.png');
imwrite(rgb,fname);

ipSPD = ipCreate;
ipSPD = ipCompute(ipSPD,sensorSPD,'hdr white',false);
ipWindow(ipSPD,'render flag','rgb','gamma',0.5);

ipSplit = ipCreate;
ipSplit = ipCompute(ipSplit,sensorSplit,'hdr white',false);
ipWindow(ipSplit,'render flag','rgb','gamma',0.5);

%%
rgb = ipGet(ipSplit,'srgb');
fname = fullfile(isethdrsensorRootPath,'local','ip-split.png');
imwrite(rgb,fname);

%% Show the improved spatial representation near the headlights

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


%% END


