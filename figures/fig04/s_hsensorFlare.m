
%%
ieInit;
%% Make the scene

scene = sceneCreate('hdr image','dynamicrange',5,'patchshape','circle','npatches',5,'patchsize',10);

% create oi
oi = oiCreate('wvf');

% Set aperture
[aperture, params] = wvfAperture(wvf,'nsides',4,...
    'dot mean',10, 'dot sd',5, 'dot opacity',0.5,'dot radius',5,...
    'line mean',10, 'line sd', 5, 'line opacity',0.5,'linewidth',2);

oi = oiSet(oi,'fnumber',1.5);
oi = oiSet(oi,'focal length',4.38e-3,'m');

oi = oiCompute(oi, scene,'crop',true,'pixel size',3e-6,'aperture',aperture);
% oiWindow(oi);
oi = oiAdjustIlluminance(oi, 100);
ip = piRadiance2RGB(oi,'etime',1/30);

ipWindow(ip);

