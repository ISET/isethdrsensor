% s_hsSceneCreate
%
% Creating scenes for the split pixel section of the paper.

%%  These are all the scenes BW processed.

% We need a different version of this, probably threw Andrew's database.
% lst = hsSceneDescriptions('print',false);


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
<<<<<<< Updated upstream
[udata, hdl ] = oiPlot(oi,'hline illuminance',[1,564],'no figure');
rgb = oiGet(oi,'rgb');
[r,c,w] = size(rgb);
ieNewGraphWin; imagesc(rgb); axis image;
hold on;
thisL = line([1 1925],[564 564],'Color','g','LineStyle','--');
thisL.LineWidth = 0.1;
yyaxis right;
plot(1:numel(udata.data),udata.data,'w-');
ax = gca; ax.YAxis(2).Scale = 'log'; ax.YAxis(2).Limits = [10^-2,10^11];
ylabel('Log10 Illuminance');
set(gcf,'Position',[0.0070    0.3986    0.4825    0.5114]);
yTick = get(gca,'ytick');
set(gca,'ytick',yTick(1:4))
%}
=======
oiPlot(oi,'illuminance hline rgb',[1 564]);

%% This one is more night weighted (lower skymap, other stuff unchanged)

wgts(4) = wgts(4)/20;
% wgts(1) = wgts(1);
% wgts(2) = wgts(2);
% wgts(3) = wgts(3);
[scene,wgts] = hsSceneCreate(imageID,'weights',wgts,'denoise',true);
% sceneWindow(scene); scene = sceneSet(scene,'gamma',0.3);
oi = oiCompute(oi, scene,'aperture',aperture,'crop',true, 'pixel size',3e-6);
oiWindow(oi);
oi = oiSet(oi,'gamma',0.2);
oiPlot(oi,'illuminance hline rgb',[1 564]);

%% Down another factor of 20

wgts(4) = wgts(4)/20;
% wgts(1) = wgts(1);
% wgts(2) = wgts(2);
% wgts(3) = wgts(3);
[scene,wgts] = hsSceneCreate(imageID,'weights',wgts,'denoise',true);
% sceneWindow(scene); scene = sceneSet(scene,'gamma',0.3);
oi = oiCompute(oi, scene,'aperture',aperture,'crop',true, 'pixel size',3e-6);
oiWindow(oi);
oi = oiSet(oi,'gamma',0.2);
oiPlot(oi,'illuminance hline rgb',[1 564]);

%%
>>>>>>> Stashed changes
