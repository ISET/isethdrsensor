%% Calibrate the LPD and SPD sensors in the OVT 3-capture
%
% Script just to verify that we got the OVT model right
%

%%
ieInit;

%% Calibration scene - uniform, large

scene = sceneCreate('uniform d65',512);
scene = sceneSet(scene,'fov',2);

%% Create the optics
oi = oiCreate('wvf');
oi = oiSet(oi,'optics off axis method','cos4th');
oi = oiCompute(oi,scene,'crop',true,'pixel size',3e-6);

%% Run a standard RGB sensor

expTime = 16e-3;   
whichLine = 859;
satLevel = .99;

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
        % The LPD
        fprintf('Voltage mean:  %.3f\n',mean(v(:)));
    elseif ii==2
        % Should match the LPD because gain is the only difference
        fprintf('Voltage mean:  %.3f\n',mean(v(:))*sensorGet(sensorArray(ii),'analog gain'));
    elseif ii==3
        % Should match the LPD because fill factor is the only
        % difference
        fprintf('Voltage mean:  %.3f\n',mean(v(:))/sensorGet(sensorArray(ii),'pixel fill factor'));
    end
end

%% END