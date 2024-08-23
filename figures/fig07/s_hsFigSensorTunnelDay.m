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
oiFile = fullfile(isethdrsensorRootPath,'data','oiTunnel.mat');
if ~exist(oiFile,"file")
    % download the file from SDR
    ieWebGet('resourcetype','isethdrsensor',...
        'resource name','data/oiTunnel.mat',...
        'download dir',isethdrsensorRootPath);
end
load(oiFile,'oiInput');
%% Set parameters

% Long exposure forces saturation of the LPD
expTime   = 120e-3;   
satLevel  = .99;

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

%% The full 3-capture

% sensorArray(3) = sensorSet(sensorArray(3),'pixel fill factor',1);

[sensorSplit,sensorArraySplit] = sensorComputeArray(sensorArray,oiInput,...
    'method','saturated', ...
     'saturated',satLevel);

%% Image process the RGB and split pixel

ipLPD = ipCreate;
ipLPD = ipCompute(ipLPD,sensorArraySplit(1),'hdr white',true);
ipWindow(ipLPD,'render flag','rgb','gamma',0.3);

%{
rgb = ipGet(ipLPD,'srgb');
fname = fullfile(isethdrsensorRootPath,'local','ip-LPD.png');
imwrite(rgb,fname);
%}

ipSPD = ipCreate;
ipSPD = ipCompute(ipSPD,sensorArraySplit(3),'hdr white',true);
ipWindow(ipSPD,'render flag','rgb','gamma',0.3);

ipSplit = ipCreate;
ipSplit = ipCompute(ipSplit,sensorSplit,'hdr white',true);
ipWindow(ipSplit,'render flag','rgb','gamma',0.3);

%{
rgb = ipGet(ipSplit,'srgb');
fname = fullfile(isethdrsensorRootPath,'local','ip-split.png');
imwrite(rgb,fname);
%}

%% Show the improved spatial representation near the headlights

lineNumber = 479;
uSplit = ipPlot(ipSplit,'horizontal line luminance',[1 lineNumber],'no figure');
uLPD   = ipPlot(ipLPD,'horizontal line luminance',[1 lineNumber],'no figure');

ieNewGraphWin;
p = plot(uSplit.pos,uSplit.data,'Color',[0 0.5 1],'LineWidth',2); 
hold on;
plot(uLPD.pos,uLPD.data,'r-','LineWidth',2);
legend({'3-capture OVT','LPD-LCG'});
grid on; 
xlabel('Column'); ylabel('Relative luminance');
set(gca,'yscale','log'); grid on

%% If you would like to save a PDF, do this

%{
tmp = sprintf('split-LPD-luminance.pdf');
exportgraphics(gcf,fullfile(isethdrsensorRootPath,'local',tmp));
%}

%% END


