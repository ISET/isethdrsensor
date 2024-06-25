function lst = hsSceneDescriptions
% Descriptions for light group scenes that have been processed
%
% Synopsis
%   lst = hsSceneDescriptions;
%
% See also
%   s_downloadLightGroup, hsScenes
%

lst(1).id = '1114034742';     lst(1).rect   = [196 58 1239 752]; lst(1).desc   = 'Motorcyle, people walking not very nice';
lst(end+1).id = '1114091636'; lst(end).rect = [196 58 1239 752]; lst(end).desc = 'People on street';
lst(end+1).id = '1114011756'; lst(end).rect = [196 58 1239 752]; lst(end).desc = 'Vans moving away, person';
lst(end+1).id = '1113094429'; lst(end).rect = [196 58 1239 752]; lst(end).desc = 'Truck and nice late afternoon';
lst(end+1).id = '1112201236'; lst(end).rect = [196 58 1239 752]; lst(end).desc = 'Open highway scene';
lst(end+1).id = '1113042919'; lst(end).rect = [196 58 1239 752]; lst(end).desc = 'Blue car, person, motorcyle, yellow bus';
lst(end+1).id = '1112213036'; lst(end).rect = [196 58 1239 752]; lst(end).desc = 'Lousy';
lst(end+1).id = '1113040557'; lst(end).rect = [196 58 1239 752]; lst(end).desc = 'Lousy, truck and people';
lst(end+1).id = '1113051533'; lst(end).rect = [270 351 533 528]; lst(end).desc = 'Hard to get light levels right';
lst(end+1).id ='1112220258';  lst(end).rect = [270 351 533 528]; lst(end).desc = 'Curved road with trucks and bicycles and lights';
lst(end+1).id ='1113164929';  lst(end).rect = [256 256 540 640]; lst(end).desc = 'One car, one bike, mountain in the road';
lst(end+1).id ='1113165019';  lst(end).rect = [256 256 768 512]; lst(end).desc = 'Wide, complex highway scene.  Big sky';
lst(end+1).id ='1114043928';  lst(end).rect = [256 256 768 512]; lst(end).desc = 'Man in front of the sky';
lst(end+1).id ='1114120530';  lst(end).rect = [256 256 768 512]; lst(end).desc = 'Woman in front of a truck';

for ii=1:numel(lst)
    fprintf('%s - %s\n',lst(ii).id,lst(ii).desc);
end

end

%{
% imageID = '1113094429'; rect = [196 58 1239 752];
% imageID = '1114011756'; rect = [891 371 511 511];  
% imageID = '1114091636'; rect = [270  351 533 528];
% imageID = '1114120530'; rect = [270  351 533 528];
% imageID = '1114043928'; rect = [10  10  540  640];
% imageID = '1113165019'; rect = [256 256  768 512];
% imageID = '1113164929'; rect = [256 256  768 512];
% imageID = '1112220258'; rect = [256 256  768 512];
% imageID = '1114091636'; rect = [270 351 533 528];
% imageID = '1114120530'; rect = [270 351 533 528];
% imageID = '1114043928'; rect = [256 256 540 640];
% imageID = '1113165019'; rect = [256 256 768 512];
% imageID = '1113164929'; rect = [256 256 768 512];
% imageID = '1112220258'; rect = [256 256 768 512];
%}