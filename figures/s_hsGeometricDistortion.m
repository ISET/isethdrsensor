ieInit
load('/Users/zhenyi/git_repo/dev/isethdrsensor/local/fig06_tunnel_oi.mat','oiInput');
scene = piSceneCreate(oiInput.data.photons);

scene = piSceneCreate(oiInput.data.photons);
scene = sceneSet(scene,'fov',170);

%%
% Set up default optical image
oi = oiCreate;
% opticsFileName = fullfile(isetRootPath,'data','optics','zemaxDoubleGauss.mat');
% opticsFileName = fullfile(isetRootPath,'data','optics','zemaxCookeTriplet.mat');
% opticsFileName = fullfile(isetRootPath,'data','optics','zemaxWideAngle.mat');
opticsFileName = fullfile(isetRootPath,'data','optics','zemaxFisheye.mat');
% opticsFileName = fullfile(isetRootPath,'data','optics','zmWideAngle.mat');
load(opticsFileName,'optics');

% Set the oi with the optics loaded from the file
oi = oiSet(oi,'optics',optics);

% Retrieve it and print its name to verify and inform user
fprintf('Ray trace optics: %s\n',opticsGet(optics,'lensFile'));

%% Set up diffraction limited parameters to match the ray trace numbers

% Now, match the scene properties
oi = oiSet(oi,'wangular',sceneGet(scene,'wangular'));
oi = oiSet(oi,'wavelength',sceneGet(scene,'wavelength'));

% Match the scene distance and the rt distance.  They are both essentially
% infinite.
scene = sceneSet(scene,'distance',1);  % Two meters - essentially inf
oi    = oiSet(oi,'optics rtObjectDistance',sceneGet(scene,'distance','mm'));

%% Compute the distortion and show it in the OI

% We calculate in the order of (a) Distortion, (b) Relative
% illumination, and then (c) OTF blurring The function rtGeometry
% calculates the distortion and relative illumination at the same time.
oFOV = oiGet(oi,'optics rt fov');
sFOV = sceneGet(scene,'fov');
fprintf('Optics fov:  %f\n',oFOV);
fprintf('Scene fov:  %f\n', sFOV);
if sFOV > oFOV
    warning('Reducing scene FOV to comply.')
    scene = sceneSet(scene,'hfov',oFOV - 1);
end

% scene = sceneInterpolateW(scene,(550:100:650));  % Small wavelength sample
% oi.wAngular = 120;

oi = rtGeometry(oi,scene,6);


% 



oiWindow(oi,'render flag','hdr');

%%