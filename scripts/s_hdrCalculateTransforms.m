%% Calculate the three ip transforms in different ways
%
% We want to be able to calculate these without calling the full
% ipCompute() method. These three approaches all return the same full
% transforms.
%
% See also
%   s_hsTestCharts.m

%% We need a small scene and oi
scene = sceneCreate('macbeth d65',32);
scene = sceneSet(scene,'fov',20);
oi = oiCreate('wvf');
oi = oiCompute(oi,scene);

ip = ipCreate;

%% This is how it is computed within ipCompute 

sensorRGB = sensorCreate('ar0132at',[],'rgb');
sensorRGB = sensorSet(sensorRGB,'noise flag',0);
sensorRGB = sensorCompute(sensorRGB,oi);
ip = ipCompute(ip,sensorRGB);  % Computes the Transforms
T1 = ipGet(ip,'prodT');

%% Avoids ipCompute. But uses the whole sensor

sensorRGB = sensorCreate('ar0132at',[],'rgb');
T{1} = ieColorTransform(sensorRGB,'XYZ','D65','mcc');
T{2} = eye(3,3);
T{3} = ieInternal2Display(ip);
ip = ipSet(ip,'transforms',T);
T2 = ipGet(ip,'prodT');

assert( max(abs((T1(:) - T2(:)))) < 1e-6)

%% Uses only the three color filters from a sensor

% These match!  So write a routine to get the transforms based on the
% RGB of the RGBW sensor.  No need to create the RGB and run an
% ipCompute to calculate the transforms.
sensorRGBW = sensorCreate('ar0132at',[],'rgbw');
wave     = sensorGet(sensorRGBW,'wave');
sensorQE = sensorGet(sensorRGBW,'spectral qe');
targetQE = ieReadSpectra('xyzQuanta',wave);
T{1} = imageSensorTransform(sensorQE(:,1:3),targetQE,'D65',wave,'mcc');
T{2} = eye(3,3);
T{3} = ieInternal2Display(ip);
ip = ipSet(ip,'transforms',T);
T3 = ipGet(ip,'prodT');

assert( max(abs((T1(:) - T3(:)))) < 1e-6)

%% End