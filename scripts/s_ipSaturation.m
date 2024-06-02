%% Experiment with HDR image processing

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

