%% s_hsIMX490
% 

%%
ieInit;

%%  Specify the file

% Use the script s_downloadLightGroup to add more light group scenes
% to this list

imageID = '1114011756';
% 1114091636 - People on street
% 1114011756 - Vans moving away, person
% 1113094429
%

lgt = {'headlights','streetlights','otherlights','skymap'};
destPath = fullfile(isethdrsensorRootPath,'data',imageID);
clear thisScene

%% Load up the scenes from the downloaded directory

scenes = cell(numel(lgt,1));
for ll = 1:numel(lgt)
    thisFile = sprintf('%s_%s.exr',imageID,lgt{ll});
    destFile = fullfile(destPath,thisFile);
    scenes{ll} = piEXR2ISET(destFile);
end
disp('Done loading.')

%%
wgts = [0.02, 0.1, 0.02, 0.00001]; % night
scene = sceneAdd(scenes, wgts);
scene.metadata.wgts = wgts;
disp('Done adding')
%% If you want, crop out the headlight region of the scene for testing
%
% You can crop in the window, get the scene, and find the crop.  The
% rect will be attached to the scene object.
%
%   sceneHeadlight = ieGetObject('scene');
%

% {
form = [1 1 511 511];
switch imageID
    case '1114011756'
        % Focused on the person
        rect = [890   370 0 0] + form;  % 1114011756
        thisScene = sceneCrop(scene,rect);
    case '1114091636'
        % This is an example crop for the headlights on the green car.
        rect = [270   351   533   528];  % 1114091636
        thisScene = sceneCrop(scene,rect);
    otherwise
        error('Unknown imageID')
end
disp('Done cropping')
%}

%%
if ~exist('thisScene','var'), thisScene = scene; end

fprintf('Denoising ...');
thisScene = piAIdenoise(thisScene);
% sceneWindow(thisScene);

%%
[oi,wvf] = oiCreate('wvf');
[aperture, params] = wvfAperture(wvf,'nsides',3,...
    'dot mean',50, 'dot sd',20, 'dot opacity',0.5,'dot radius',5,...
    'line mean',50, 'line sd', 20, 'line opacity',0.5,'linewidth',2);

oi = oiSet(oi,'wvf zcoeffs',0,'defocus');
oi = oiCompute(oi, thisScene,'aperture',aperture,'crop',true);

% Required for the IMX490
oi = oiSpatialResample(oi,3e-6);
% oiWindow(oi);

%%
% sensor is the combined response
[sensor,metadata] = imx490Compute(oi,'method','average','exptime',1/10);

% For the HDR car scene use exptime of 0.1 sec
sArray = metadata.sensorArray;

sensorWindow(sensor);

% Note:  The ratio of electron capture makes sense.  The conversion gain,
% however, differs so when we plot w.r.t volts the ratios are not as you
% might naively expect.  The dv values follow volts.
sensorWindow(sArray{1});
sensorWindow(sArray{2});
sensorWindow(sArray{3});
sensorWindow(sArray{4});

%% Various checks.
e1 = sensorGet(sArray{1},'electrons');
e2 = sensorGet(sArray{2},'electrons');
ieNewGraphWin; plot(e1(:),e2(:),'.');
identityLine; grid on;

v1 = sensorGet(sArray{1},'volts');
v2 = sensorGet(sArray{2},'volts');
ieNewGraphWin; plot(v1(:),v2(:),'.');
identityLine; grid on;

% e3 is 1/9th the area, so 1/9th the electrons of e1
e3 = sensorGet(sArray{3},'electrons');
ieNewGraphWin; plot(e1(:),e3(:),'.');
identityLine; grid on;

dv1 = sensorGet(sArray{1},'dv');
dv2 = sensorGet(sArray{2},'dv');
ieNewGraphWin; plot(dv1(:),dv2(:),'.');
identityLine; grid on;


%% Now try with a complex image

load('HDR-02-Brian','scene');
oi = oiCreate;
oi = oiCompute(oi,scene);   % oiWindow(oi);
oi = oiCrop(oi,'border');
oi = oiSpatialResample(oi,3,'um'); % oiWindow(oi);
% oi2 = oiCompute(oi,scene,'crop',true,'pixel size',3e-6);   % oiWindow(oi2);
% oi2 = oiSpatialResample(oi2,3,'um'); % oiWindow(oi);

[sensor,metadata] = imx490Compute(oi,'method','average','exptime',1/10);

%%
sArray = metadata.sensorArray;

sensorWindow(sensor);

% Note:  The ratio of electron capture makes sense.  The conversion gain,
% however, differs so when we plot w.r.t volts the ratios are not as you
% might naively expect.  The dv values follow volts.
sensorWindow(sArray{1});
sensorWindow(sArray{2});
sensorWindow(sArray{3});
sensorWindow(sArray{4});


%% Note that the electrons match up to voltage saturation
e1 = sensorGet(sArray{1},'electrons');
e2 = sensorGet(sArray{2},'electrons');
ieNewGraphWin; plot(e1(:),e2(:),'.');
identityLine; grid on;

v1 = sensorGet(sArray{1},'volts');
v2 = sensorGet(sArray{2},'volts');
ieNewGraphWin; plot(v1(:),v2(:),'.');
identityLine; grid on;

%% Make an ideal form of the image

scene = sceneCreate('uniform',256);
oi = oiCreate;
oi = oiCompute(oi,scene);   % oiWindow(oi);
oi = oiCrop(oi,'border');
oi = oiSpatialResample(oi, 3,'um');

% Calculate the imx490 sensor
sensor = imx490Compute(oi,'method','average','noiseflag',0,'exptime',1/10);

% Could just do an oiGet(oi,'xyz')
%
% Or we can create a matched, ideal X,Y,Z sensors that can calculate
% the XYZ values at each pixel.
sensorI = sensorCreateIdeal('match xyz',sensor);
sensorI = sensorSet(sensorI,'match oi',oi);

sensorI = sensorCompute(sensorI,oi);
for ii=1:numel(sensorI)
    sensorI(ii) = sensorCompute(sensorI(ii),oi);
end

sensorWindow(sensorI(3));
sensorGet(sensorI(1),'pixel fill factor')

% The sensor data and the oi data have the same vector length.  Apart from
% maybe a pixel at one edge or the other, they should be aligned
%

%%
[sensor,metadata] = imx490Compute(oi,'method','best snr','exptime',1/3);

%%
ip = ipCreate;
ip = ipCompute(ip,sensor);
ipWindow(ip);

%% For the uniform case, these should be about 4x
uData1 = sensorPlot(sArray{1},'electrons hline',[55 1]);
sensorPlot(sArray{2},'electrons hline',[55 1]);

% These are OK.  A factor of 4.
uData2 = sensorPlot(sArray{3},'electrons hline',[150 1]);
sensorPlot(sArray{4},'electrons hline',[150 1]);