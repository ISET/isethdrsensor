%% Calibrate the LPD and SPD sensors in the OVT 3-capture
ieInit;

%% Calibration scene
scene = sceneCreate('uniform d65',512);
scene = sceneSet(scene,'fov',2);

%% Create the optics
oi = oiCreate('wvf');
oi = oiSet(oi,'optics off axis method','cos4th');
oi = oiCompute(oi,scene,'crop',true,'pixel size',3e-6);

%% Run a standard RGB sensor

% 16e-3 is 60 h frame rate.  Used for all the captures below.
expTime = 16e-3;   
whichLine = 859;
satLevel = .99;
% whichLine = 142; % An interesting one, also

%% Simulate the Omnivision (OVT) Split pixel technology.

pixelSize = [3 3]*1e-6;
sensorSize = [1082 1926];
arrayType = 'ovt'; 

sensorArray = sensorCreateArray('array type',arrayType,...
    'pixel size same fill factor',pixelSize,...
    'exp time',expTime, ...
    'quantizationmethod','analog', ...
    'noise flag',0,...
    'size',sensorSize);

[sensorCombined,sensorArray] = sensorComputeArray(sensorArray,oi);
for ii=1:3
    v = sensorGet(sensorArray(ii),'volts');
    if ii==1
        fprintf('Voltage mean:  %.3f\n',mean(v(:)));
    elseif ii==2
        fprintf('Voltage mean:  %.3f\n',mean(v(:))*sensorGet(sensorArray(ii),'analog gain'));
    elseif ii==3
        fprintf('Voltage mean:  %.3f\n',mean(v(:))/sensorGet(sensorArray(ii),'pixel fill factor'));
    end
end

%%

pixelSize = [3 3]*1e-6;
sensorSize = [1082 1926];

arrayType = 'ovt'; 

% The OVT design is a 3-capture (two large PD captures and one small PD).
sensorArray = sensorCreateArray('array type',arrayType,...
    'pixel size same fill factor',pixelSize,...
    'exp time',expTime, ...
    'quantizationmethod','analog', ...
    'size',sensorSize);

sensorArray(3) = sensorSet(sensorArray(3),'pixel fill factor',.1);

[sensorSplit,sensorArraySplit] = sensorComputeArray(sensorArray,oi,...
    'method','saturated', ...
    'saturated',satLevel);
%{
% Check that it is OK.
ip = ipCreate; 
ip = ipCompute(ip,sensorSplit,'hdr white',true); ipWindow(ip,'gamma',0.7);
ip = ipCompute(ip,sensorArraySplit(1),'hdr white',true); ipWindow(ip,'gamma',0.7); 
ip = ipCompute(ip,sensorArraySplit(3),'hdr white',true); ipWindow(ip,'gamma',0.7); 
%}

