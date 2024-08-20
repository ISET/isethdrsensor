%% Downloading from the SDR
%
%
% In searchworks, we find the Deriving the Cone Fundamentals data using
% with this URL 
https://searchworks.stanford.edu/view/jz111ct9401

% It appears that the files all have a common prefix:
%   https://stacks.stanford.edu/file/druid:jz111ct9401
% followed by literally the directory and file name.
%
thisURL = 'https://stacks.stanford.edu/file/druid:jz111ct9401/cone_fundamentals/grabit/DeutanCMFBluex5.mat'
https://stacks.stanford.edu/file/druid:jz111ct9401/cone_fundamentals/grabit/foveaTritanRed.mat
https://stacks.stanford.edu/file/druid:jz111ct9401/cone_fundamentals/grabit/DeutanCMFRed.mat
websave('tmp.mat',thisURL);

% The maxwell directory
https://stacks.stanford.edu/file/druid:jz111ct9401/cone_fundamentals/maxwell/maxwellCMF_obsJ.mat

% The thomsonwright directory
https://stacks.stanford.edu/file/druid:jz111ct9401/cone_fundamentals/thomsonwright/Thomson_Wright_53_TabulatedFundamentals.xlsx

% WDW directory
https://stacks.stanford.edu/file/druid:jz111ct9401/cone_fundamentals/wdw/cmfDeutan.mat