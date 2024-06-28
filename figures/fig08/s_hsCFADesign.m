%% Make a figure RGBW and RGB to
%
%  Shows how to use the data to compare different CFA architectures.
%
%   * Match imx363 with the split pixel design for one possibility
%   * Show just increasing well capacity?
%   * Show reduced sensitivity just on one of the green pixels?
%
% For a couple of scenes, render them through some kind of optics onto the
%
% Here are the scenes.  Refresh from time to time.
%
%   hsSceneDescriptions;
%
% The light group names
%   lgt = {'headlights','streetlights','otherlights','skymap'};

%%
ieInit;

%%
% imageID = '1112201236';
imageID = '1114120530';
%% Load the four light group

fname = fullfile(isethdrsensorRootPath,'data',sprintf('HDR-scenes-%s',imageID));
load(fname,'scenes');
