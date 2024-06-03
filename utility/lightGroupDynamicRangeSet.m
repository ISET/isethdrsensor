function [wgts, combinedScene] = lightGroupDynamicRangeSet(scenes, DR)
% lightGroupDynamicRangeSet Adjusts the luminance of different light groups to set the dynamic range for the final scene.
%
% Inputs:
%   scenes - A cell array containing different light scenes.
%       LightGroupScenes = {'headlights', 'streetlights', 'otherlights', 'skymap'};
%   DR - Desired dynamic range for the combined scene.
%
% Outputs:
%   wgts - Weights for adjusting the luminance of each light group.
%   combinedScene - The final combined scene with adjusted luminance.
% 
% Note:
%   This method assumes visible light sources in light groups, if the light
%   sources are not directly visible, the method may fail. We might check
%   whether there are visible light sources by a threshold value.

%% Headlights
% Define luminance range for headlights
% | Headlight Type | Luminance Range (cd/m²)   |
% |----------------|---------------------------|
% | Halogen        | 20,000 - 30,000           |
% | HID (Xenon)    | 50,000 - 80,000           |
% | LED            | 40,000 - 90,000           |
% | Laser          | 100,000 - 200,000         |

% Set the maximum luminance for headlights
peakLumForHeadlight = max(rand(1) * 20, 2) * 1e5;

% Get the current luminance of the headlights scene
luminance = sceneGet(scenes{1}, 'luminance');
currentL = max(luminance(:));
clear luminance;

% Calculate the weight for headlights
wgts(1) = peakLumForHeadlight / currentL;

%% Streetlights
% Define luminance range for streetlights
% | Streetlight Type        | Luminance Range (cd/m²) |
% |-------------------------|-------------------------|
% | High-Pressure Sodium    | 10,000 - 30,000         |
% | Metal Halide            | 20,000 - 40,000         |
% | LED                     | 25,000 - 50,000         |

% Set the maximum luminance for streetlights
peakLumForStreetlight = max(rand(1) * 5, 1) * 1e5;

% Get the current luminance of the streetlights scene
luminance = sceneGet(scenes{2}, 'luminance');
currentL = max(luminance(:));
clear luminance;

% Calculate the weight for streetlights
wgts(2) = peakLumForStreetlight / currentL;

%% Other Lights (e.g., Tail Lights)
% Define luminance range for other lights (relative to headlights)
% | Light Type  | Luminance Relative to Headlights |
% |-------------|----------------------------------|
% | Tail Lights | 0.04% - 1%                         |
% | Brake Lights| 10% - 20%                        |

% Set the maximum luminance for other lights (tail lights)
peakLumForOtherlight = max(rand(1) * 10, 4) * 1e-4 * peakLumForHeadlight;

% Get the current luminance of the other lights scene
luminance = sceneGet(scenes{3}, 'luminance');
currentL = max(luminance(:));
clear luminance;

% Calculate the weight for other lights
wgts(3) = peakLumForOtherlight / currentL;

%% Skylight
% Skylight luminance depends on the dynamic range, using mean luminance
meanLumForSkylight = peakLumForHeadlight / DR;

% Get the current luminance of the skymap scene
luminance = sceneGet(scenes{4}, 'luminance');
currentL = mean(luminance(:));
clear luminance;

% Calculate the weight for skylight
wgts(4) = 2*meanLumForSkylight / currentL;

%% Combine the scenes
% Combine the scenes with the calculated weights
combinedScene = sceneAdd(scenes, wgts);

% Store the weights in the metadata of the combined scene
combinedScene.metadata.wgts = wgts;

end