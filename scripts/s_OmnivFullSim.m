% The goal of this script is to 
% 1. Simulate the entire digital imaging pipeline
%    stage-by-stage 
% 2. Check different sim parameters
% 
% We simulate the ISET implementation of OVT's 
% split pixel technology
% Authored by Ayush Jamdar. 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Stage 0. Setup
disp('Running Stage 0: Setup');

ieInit; % start a global vcSession which stores states. 
% runs fully locally. 

% 0. A Scene Setup
imageID = '1112184733';
lgt = {'headlights','streetlights','otherlights','skymap'};
destPath = fullfile(isethdrsensorRootPath,'data',imageID);

% Download the scene radiance files if they do not exist
scenes = cell(numel(lgt,1));
for ll = 1:numel(lgt)
    thisFile = sprintf('%s_%s.exr',imageID,lgt{ll});
    destFile = fullfile(destPath,thisFile);
    if ~exist(destFile,"file")
        ieWebGet('deposit name','isethdrsensor-paper',...
            'deposit file',fullfile('data',imageID,thisFile),...
            'download dir',fullfile(isethdrsensorRootPath,'data',imageID),...
            'unzip',false);
    end
    scenes{ll} = piEXR2ISET(destFile);
end

%% This is one way to obtain light group weights by setting the dynamic range
% DR = 1e6;
% [scene, wgts] = lightGroupDynamicRangeSet(scenes, DR);
% scene = piAIdenoise(scene);

% If you know the weights / can play with these
% Weight order: headlights, streetlights, otherlights, skymap
wgts_day = [3.0114    0.0378    0.0498    0.1];
scene = sceneAdd(scenes, wgts_day); % merge the groups into one scene
dayScene = piAIdenoise(scene); % a denoiser for pbrt-rendered EXRs

% 0. B Camera Optics Setup
[oi,wvf] = oiCreate('wvf');  % create an optical image and wavefront
wvf = wvfSet(wvf, 'spatial samples',512);
params = wvfApertureP;  % aperture parameters
params.nsides = 0;
params.dotmean = 0;  % dots simulate dust particles
params.dotsd = 0;
params.dotopacity = 0;
params.dotradius = 0;
params.linemean = 0;  % lins simulate scratches
params.linesd = 0;
params.lineopacity = 0;
params.linewidth = 0;

aperture = wvfAperture(wvf,params);
oi = oiSet(oi,'wvf zcoeffs',0,'defocus');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Stage I. Scene Radiance to Sensor Irradiance
% Pass light through the optics to get an optical image
% This OI is sensor irradiance
disp('Running Stage I: Optics');
opticalImage = oiCompute(oi, scene,'aperture',aperture,'crop', ...
    true,'pixel size',3e-6);
oiWindow(opticalImage,'render flag','hdr', 'gamma', 0.7);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Stage II. Sensor Modelling & Capture
% Uses ISETCam
disp('Running Stage II: Sensor Capture');

% hyperparameters
expTime = 342e-3; % sensor integration time
satLevel = 0.95;
pixelSize = 3e-6;  % 3 um
sensorSize = [1082 1926];  % resolution

arrayType = 'ovt';

% the split pixel tech is essentially running three sensors
% LPD-LCG, LPD-HCG, SPD 
% sensorArray is an array of these three sensors (in ORDER)
sensorArray = sensorCreateArray('array type',arrayType,...
    'pixel size same fill factor',pixelSize,...
    'exp time',expTime, ...
    'quantizationmethod','analog', ...
    'size',sensorSize);

% Sensor capture
% sensorCombined   - HDR exposure-fused image (combined SPD-LPD)
% sensorArraySplit - The individual sensor images
[sensorCombined,sensorArraySplit] = sensorComputeArray(sensorArray,opticalImage,...
    'method','saturated', ...
    'saturated',satLevel);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Stage III. Image Processing
% ISETCam follows the ISP order: 
% sensor data -> demosaicking -> color space -> white balance
% -> display color space -> HDR whitening -> gamma tonemapping
disp('Running Stage III: Image Processing');

ipLPDLCG = ipCreate;
sensorLPDLCG = sensorArraySplit(1);
% this is how you can set white balance (default: none)
% ipLPDLCG = ipSet(ipLPDLCG,'illuminant correction method','gray world');
ipLPDLCG = ipCompute(ipLPDLCG,sensorLPDLCG,'hdr white',true);
% ipWindow(ipLPDLCG,'render flag','rgb','gamma',0.3); % if GUI is available

ipLPDHCG = ipCreate;
sensorLPDHCG = sensorArraySplit(2);
% ipLPDHCG = ipSet(ipLPDHCG,'illuminant correction method','gray world');
ipLPDHCG = ipCompute(ipLPDHCG,sensorLPDHCG,'hdr white',true);
% ipWindow(ipLPDHCG,'render flag','rgb','gamma',0.3);

ipSPD = ipCreate;
sensorSPD = sensorArraySplit(3);
% ipSPD = ipSet(ipSPD,'illuminant correction method','gray world');
ipSPD = ipCompute(ipSPD,sensorSPD,'hdr white',true);
% ipWindow(ipSPD,'render flag','rgb','gamma',0.3);

ipCombined = ipCreate;
% ipCombined = ipSet(ipCombined,'illuminant correction method','gray world');
ipCombined = ipCompute(ipCombined,sensorCombined,'hdr white',true);
% ipWindow(ipCombined,'gamma',0.5);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Stage IV. Save & Display
disp('Running Stage IV: Save Outputs');

rgb = ipGet(ipCombined,'srgb');
fname = fullfile(isethdrsensorRootPath,'data', imageID,'combined.png');
imwrite(rgb,fname);

rgb = ipGet(ipLPDLCG,'srgb');
fname = fullfile(isethdrsensorRootPath,'data', imageID,'lpd-lcg.png');
imwrite(rgb,fname);

rgb = ipGet(ipLPDHCG,'srgb');
fname = fullfile(isethdrsensorRootPath,'data', imageID, 'lpd-hcg.png');
imwrite(rgb,fname);

rgb = ipGet(ipSPD,'srgb');
fname = fullfile(isethdrsensorRootPath,'data', imageID,'spd.png');
imwrite(rgb,fname);
