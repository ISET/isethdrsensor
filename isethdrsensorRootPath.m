function rootPath=isethdrsensorRootPath()
% Return the path to the isethdrsensor root iset directory
%
% This function must reside in the directory at the base of the
% ISETHdrsensor directory structure.  It is used to determine the
% location of various sub-directories.
%
% Example:
%   fullfile(isethdrsensorRootPath,'data')

rootPath=which('isethdrsensorRootPath');

rootPath = fileparts(rootPath);

end
