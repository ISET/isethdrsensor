%% s_ipSaturation
%
% Evaluates the ipHDRWhite method, called through ipCompute
% 
% That method moves saturated pixels in the rendering towards white.
%

%% Might maake a smaller version of this scene for speed/testing

load('HDR-02-Brian','scene');
oi = oiCreate;
oi = oiCompute(oi,scene,'crop',true,'pixel size',3e-6);   % oiWindow(oi);

sensor = imx490Compute(oi,'method','average','exptime',1/30);

%% No call to ipHDRWhite

ip = ipCreate;
ip = ipCompute(ip,sensor);
ipWindow(ip);

%% Calls ipHDRWhite at the end

saturation = sensorGet(sensor,'max digital value');
hdrLevel = 0;
[ip2, wgts] = ipHDRWhite(ip,'hdrlevel',hdrLevel,'saturation',saturation);
ieNewGraphWin;
imagesc(wgts); axis image;

ip = ipCompute(ip,sensor,'hdrlevel',hdrLevel);
ipWindow(ip);

%%
hdrLevel = 0.015;
[ip3, wgts] = ipHDRWhite(ip,'hdrlevel',hdrLevel,'saturation',saturation);
ieNewGraphWin;
imagesc(wgts); axis image;

ip = ipCompute(ip,sensor,'hdrlevel',hdrLevel);
ipWindow(ip);

%%
% Find the input data locations that are nearly saturated
sdata = ipGet(ip,'input');

% We need a better way of finding mx
mx = max(sdata(:));

% The contribution from the 111 goes to zero five percent away from the
% max. So  mx -> 1, 0.95*mx -> 0 0] ->
wgts = (sdata/mx - 0.95)/0.05;
wgts = ieClip(wgts,0,1);
%{
ieNewGraphWin;
imagesc(wgts);
histogram(wgts(:));
%}


%% We are going to replace the 'result' with 1,1,1 (smoothly)

% The locations with a saturated pixel will get 1,1,1.  As the pixel
% approaches the saturated level, we will insert a weighted sum of 'result'
% and 1,1,1.
result = ipGet(ip,'result');

tmp = ones(size(result));

% Push towards 1,1,1 when saturated.  Leave alone when not saturated.
tmp = tmp.*wgts + result.*(1-wgts);

ieNewGraphWin;
imagesc(result);
imagesc(tmp);

