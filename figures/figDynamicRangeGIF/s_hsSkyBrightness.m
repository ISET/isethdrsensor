%% s_hsSkyBrightness
%
% Creating scenes and oi sweeping out the skymap brightness. This takes us
% from day to night levels.  It is used to create a GIF for presentations,
% showing how the reduction in the sky brightness changes the overall
% sensor illuminance.
% 
% The scenes have with different amounts of sky light, but otherwise the
% same.
%
% The irradiance axis levels (on the right) are set by a function at the
% end.
%
% Once the files are all written out, I used Powerpoint to make them
% into a gif
%
% See also
%   s_hsSceneCreate

%%  These are all the scenes BW processed.
% We need a different version of this, probably through Andrew's database.
%
% lst = hsSceneDescriptions('print',false);

%%
ieInit;

%% Create the optics
[oi,wvf] = oiCreate('wvf');
params = wvfApertureP;
% We should implement wvfApertureSet/Get so we do not have to remember
% the parameter names precisely.
% {
params.nsides = 3;
params.dotmean = 50;
params.dotsd = 20;
params.dotopacity =0.5;
params.dotradius = 5;
params.linemean = 50;
params.linesd = 20;
params.lineopacity = 0.5;
params.linewidth = 2;
%}

aperture = wvfAperture(wvf,params);
oi = oiSet(oi,'wvf zcoeffs',0,'defocus');

imageID = '1112201236'; % - Good one

%% First scene

% headlights, street lights, other lights, sky map
% wgts = [0.0124    0.0011    0.0010    2.396];

wgts = [0.0124    5*0.0011    3*0.0010    100*2.396];
sf = 0.25;
cnt = 1;
for ii=1:7
    fprintf('Scene %d, wgts(4) %f\n',ii, wgts(4));

    scene = hsSceneCreate(imageID,'weights',wgts,'denoise',true);

    % [scene,wgts] = hsSceneCreate(imageID,'dynamic range',10^5,'low light',10,'denoise',true);
    oi = oiCompute(oi, scene,'aperture',aperture,'crop',true, 'pixel size',3e-6);
    
    oiWindow(oi);
    if ii < 4, oi = oiSet(oi,'gamma',0.7);
    else,      oi = oiSet(oi,'gamma',0.3);
    end

    oiPlot(oi,'illuminance hline rgb',[1 564]);

    setAxisAndWrite(cnt);
    cnt = cnt + 1;
    wgts(4) = wgts(4)*sf;
end


%% -----------------------------------------
function setAxisAndWrite(cnt)
% Set up the axis

ax = gca; yyaxis right
ax.YAxis(2).Limits = [10^-4,10^4];
n = 7; yTick = logspace(-3,3,n);
yTick = yTick(1:2:n);   % Space by 2 log units
set(ax,'ytick',yTick);

fname = sprintf('test-%d.png',cnt);
fname = fullfile(isethdrsensorRootPath,'local',fname);
exportgraphics(ax,fname);

end


