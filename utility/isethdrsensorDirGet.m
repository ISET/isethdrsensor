function resourceDir = isethdrsensorDirGet(resourceType)
% Returns default directory of a resource type.
%
% Synopsis
%   resourceDir = iaDirGet(resourceType)
%
% Input
%   resourceType - One of
%     {'data','local'}
%
% Output
%   resourceDir
%
% Description:
%   Most of these resources are in directories within isetauto.
%
%
% Example:
%{
  isethdrsensorDirGet('local')
%}

%% Parse
valid = {'data','local'};

if isequal(resourceType,'help')
    disp(valid);
    return;
end

if isempty(resourceType) || ~ischar(resourceType) || ~ismember(resourceType,valid)
    fprintf('Valid resources are\n\n');
    disp(valid);
    error("%s is not a valid resource type",resourceType);
end

%% Set these resource directories once, here, in case we ever need to change them

ourRoot = isethdrsensorRootPath();
ourData = fullfile(ourRoot,'data');

% Now we can locate specific types of resources
switch (resourceType)
    case 'data'
        resourceDir = ourData;
    case 'local'
        resourceDir = fullfile(ourRoot,'local');
        if ~isfolder(resourceDir)
            mkdir(resourceDir)
        end
end


end