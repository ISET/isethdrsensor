%% s_hsDayNight
%
% This is how we created oiNight and oiDay from the same lightgroup
% data.  They are large, and thus we need to save them with the -v7.3
% flag.
%
%
% See also
%   s_hsSensorCompareDay, s_hsSensorCompareNight
%

%% We store the files in local

imageID = '1114091636';   % Red car, green car.  
wgts    = [0.2306    0.0012    0.0001    1e-2*0.5175]; % Night
scene   = hsSceneCreate(imageID,'weights',wgts,'denoise',true);
oiNight = oiCompute(oi, scene,'aperture',aperture,'crop',true,'pixel size',3e-6);
oiWindow(oiNight,'render flag','rgb','gamma',0.2);

oiName = fullfile(isethdrsensorRootPath,'local',sprintf('oiNight-%s.mat',imageID));
save(oiName,'oiNight','-v7.3');

%%  This is how we created oiDay

imageID = '1114091636';   % Red car, green car.  
wgts = [0    0     0    100*0.5175]; % Day
scene = hsSceneCreate(imageID,'weights',wgts,'denoise',true);
oiDay = oiCompute(oi, scene,'aperture',aperture,'crop',true,'pixel size',3e-6);
oiWindow(oiDay,'gamma',0.5,'render flag','rgb');

oiName = fullfile(isethdrsensorRootPath,'local',sprintf('oiDay-%s.mat',imageID));
save(oiName,'oiDay','-v7.3');

%% END