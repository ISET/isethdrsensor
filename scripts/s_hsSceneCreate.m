% s_hsSceneCreate
%
% Creating scenes and oi that will be run through the split pixel section
% of the paper. These are scenes with different amounts of sky light, but
% otherwise the same.
%
% See also
%   

%%  These are all the scenes BW processed.
% We need a different version of this, probably threw Andrew's database.
% lst = hsSceneDescriptions('print',false);

%%
ieInit;

cnt = 1;

%% Create the optics
[oi,wvf] = oiCreate('wvf');
params = wvfApertureP;
% We should implement wvfApertureSet/Get so we do not have to remember
% the parameter names precisely.
% {
params.nsides = 3;
params.dotmean = 50;
params.dotSd = 20;
params.dotOpacity =0.5;
params.dotRadius = 5;
params.lineMean = 50;
params.lineSD = 20;
params.lineOpacity = 0.5;
params.lineWidth = 2;
%}

aperture = wvfAperture(wvf,params);
oi = oiSet(oi,'wvf zcoeffs',0,'defocus');

imageID = '1112201236'; % - Good one

%% First scene
[scene,wgts] = hsSceneCreate(imageID,'dynamic range',10^5,'low light',10,'denoise',true);
% sceneWindow(scene); scene = sceneSet(scene,'gamma',0.3);

oi = oiCompute(oi, scene,'aperture',aperture,'crop',true, 'pixel size',3e-6);
oiWindow(oi);
oi = oiSet(oi,'gamma',0.3);
oiPlot(oi,'illuminance hline rgb',[1 564]);

setAxisAndWrite(cnt);
cnt = cnt + 1;
%% This one is more night weighted (lower skymap, other stuff unchanged)

wgts(4) = wgts(4)/20;
[scene,wgts] = hsSceneCreate(imageID,'weights',wgts,'denoise',true);
oi = oiCompute(oi, scene,'aperture',aperture,'crop',true, 'pixel size',3e-6);
oiWindow(oi);
oi = oiSet(oi,'gamma',0.2);
oiPlot(oi,'illuminance hline rgb',[1 564]);
setAxisAndWrite(cnt);
cnt = cnt + 1;

%% Down another factor of 20

wgts(4) = wgts(4)/20;
[scene,wgts] = hsSceneCreate(imageID,'weights',wgts,'denoise',true);
% sceneWindow(scene); scene = sceneSet(scene,'gamma',0.3);
oi = oiCompute(oi, scene,'aperture',aperture,'crop',true, 'pixel size',3e-6);
oiWindow(oi);
oi = oiSet(oi,'gamma',0.2);
oiPlot(oi,'illuminance hline rgb',[1 564]);

setAxisAndWrite(cnt);
cnt = cnt + 1;

%% Brighten the sky

wgts(4) = wgts(4)*20*20*10;
[scene,wgts] = hsSceneCreate(imageID,'weights',wgts,'denoise',true);
oi = oiCompute(oi, scene,'aperture',aperture,'crop',true, 'pixel size',3e-6);
oiWindow(oi);
oi = oiSet(oi,'gamma',0.5);
oiPlot(oi,'illuminance hline rgb',[1 564]);
setAxisAndWrite(cnt);
cnt = cnt + 1;

%%
wgts(4) = wgts(4)*10;
[scene,wgts] = hsSceneCreate(imageID,'weights',wgts,'denoise',true);
oi = oiCompute(oi, scene,'aperture',aperture,'crop',true, 'pixel size',3e-6);
oiWindow(oi);
oi = oiSet(oi,'gamma',0.5);
oiPlot(oi,'illuminance hline rgb',[1 564]);
setAxisAndWrite(cnt);
cnt = cnt + 1;

%%
wgts(4) = wgts(4)*3;
[scene,wgts] = hsSceneCreate(imageID,'weights',wgts,'denoise',true);
oi = oiCompute(oi, scene,'aperture',aperture,'crop',true, 'pixel size',3e-6);
oiWindow(oi);
oi = oiSet(oi,'gamma',0.5);
oiPlot(oi,'illuminance hline rgb',[1 564]);
setAxisAndWrite(cnt);
cnt = cnt + 1;

%%

function setAxisAndWrite(cnt)
ax = gca; yyaxis right
ax.YAxis(2).Limits = [10^-4,10^4];
n = 7; yTick = logspace(-3,3,n);
yTick = yTick(1:2:n);   % Space by 2 log units
set(ax,'ytick',yTick);

fname = sprintf('test-%d.png',cnt);
fname = fullfile(isethdrsensorRootPath,'local',fname);
exportgraphics(ax,fname);
end
