%% Apply geometric distortion
%
% The script illustrates how to use rtGeometry to apply a geometric
% distortion to a scene.
%
% Conceptually, we first blur the scene with a wavefront
% (shift-invariant) optics and relative illumination.  We then apply
% the geometric distortion. The geometric transform changes the point
% spread function (as you will see).
%
% In the Zemax calculations for ray trace, we were getting the point
% spread that already had the geometric distortion built into it.  So
% in that case, we did not apply a shift-invariant transform first.
%
% The script uses both zmWideAngle and zemaxFishEye
%
% See also
%  

%%
ieInit

%% Create a point array scene

% The points are 10 pixels on a side.
scene = sceneCreate('point array',1024,128,'',10);
scene = sceneSet(scene,'fov',100);
sceneWindow(scene);

%% First run the shift-invariant wavefront without any distortion

[oi,wvf] = oiCreate('wvf');
wvf = wvfSet(wvf,'zcoeffs',60,'defocus');
oi = oiSet(oi,'optics wvf',wvf);
oi = oiCompute(oi,scene,'crop',true);
% oiWindow(oi);

%%  We apply the fisheye geometric distortion file
%
% We should have others available at some point.
% zemaxDoubleGauss.mat, zemaxWideAngle.mat zemaxFisheye.mat
opticsName = 'zmWideAngle.mat';

% Set up default optical image
% oi = oiCreate;
opticsFileName = fullfile(isetRootPath,'data','optics',opticsName);
load(opticsFileName,'optics');

% Set the oi with the optics loaded from the file
oi = oiSet(oi,'optics',optics);

% Retrieve it and print its name to verify and inform user
fprintf('Ray trace optics: %s\n',opticsGet(optics,'lensFile'));

%% Set up diffraction limited parameters to match the ray trace numbers

% Now, match the scene properties
% oi = oiSet(oi,'wangular',sceneGet(scene,'wangular'));
% oi = oiSet(oi,'wavelength',sceneGet(scene,'wavelength'));

% Match the scene distance and the rt distance.  They are both essentially
% infinite.
scene = sceneSet(scene,'distance',2);  % Two meters - essentially inf
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

%% You can see the point spread change at different field heights

% They started out as shift invariant, but they are now different
% shapes, subject to the distortion
oiGeometry = rtGeometry(oi,scene,6);
oiWindow(oiGeometry,'gamma',1);

%% Now show an image

scene = sceneCreate('macbeth',128);
scene = sceneSet(scene,'fov',100);
% sceneWindow(scene);

% Apply the wavefront/blur
[oi,wvf] = oiCreate('wvf');
wvf = wvfSet(wvf,'zcoeffs',60,'defocus');
oi = oiSet(oi,'optics wvf',wvf);
oi = oiCompute(oi,scene,'crop',true);

% Put the ray trace geometry in place
opticsName = 'zemaxFisheye.mat';
opticsFileName = fullfile(isetRootPath,'data','optics',opticsName);
load(opticsFileName,'optics');
oi = oiSet(oi,'optics',optics);

%% Set up diffraction limited parameters to match the ray trace numbers

scene = sceneSet(scene,'distance',2);  % Two meters - essentially inf
oi    = oiSet(oi,'optics rtObjectDistance',sceneGet(scene,'distance','mm'));

oFOV = oiGet(oi,'optics rt fov');
sFOV = sceneGet(scene,'fov');
fprintf('Optics fov:  %f\n',oFOV);
fprintf('Scene fov:  %f\n', sFOV);
if sFOV > oFOV
    warning('Reducing scene FOV to comply.')
    scene = sceneSet(scene,'hfov',oFOV - 1);
end

%% You can see the point spread change at different field heights

% They started out as shift invariant, but they are now different
% shapes, subject to the distortion
oiGeometry = rtGeometry(oi,scene,6);
oiWindow(oiGeometry,'gamma',1);

% oiGeometry = oiCrop(oiGeometry,'border');

%% End