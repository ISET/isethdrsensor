%% How to calculate the three transforms without an ipCompute

scene = sceneCreate('macbeth d65',32);
scene = sceneSet(scene,'fov',20);
oi = oiCreate('wvf');
oi = oiCompute(oi,scene);

% We should be able to find T a simpler way and embed that into the
% 'transform method','rgbw restormer'.  Here we set the noise to zero
% because it appears that T depends on the data in some way.
sensorRGB = sensorCreate('ar0132at',[],'rgb');
sensorRGB = sensorSet(sensorRGB,'noise flag',0);
sensorRGB = sensorCompute(sensorRGB,oi);
                
ip = ipCreate;
T{1} = ieColorTransform(sensorRGB,'XYZ','D65','mcc');
T{2} = eye(3,3);
T{3} = ieInternal2Display(ip);
ip = ipSet(ip,'transforms',T);
ip = ipSet(ip,'transform method','current');

ip = ipCompute(ip,sensorRGB);  % Computes the Transforms
ipWindow(ip);

%%