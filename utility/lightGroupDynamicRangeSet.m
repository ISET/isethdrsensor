function [combinedScene, wgts] = lightGroupDynamicRangeSet(scenes, DR, lowlightlevel)
% Combine light groups to achieve a scene dynamic range and low light level
%
% Synopsis
%   [combinedScene, wgts] = lightGroupDynamicRangeSet(scenes, DR, [lowlightlevel])
%
% Brief:
%   When we assemble a scene from the four light groups, we would like
%   to control the final dynamic range and the low light level (median
%   luminance in the dark region).  This routine sets the weights to
%   approximate a dynamic range. The result is not perfect, but it is
%   close.
%
% Inputs:
%   scenes - A cell array containing different light scenes.
%       LightGroupScenes = {'headlights', 'streetlights', 'otherlights', 'skymap'};
%
%   DR - Desired dynamic range for the combined scene.  Specified in
%        linear units (e.g., 10^4), not in logarithmic units
%
%   lowlightlevel - Luminance in the dark region of the HDR image.
%                   Implemented by adjusting the luminance so the
%                   median is at this level.  The idea is that the
%                   bright lights are a small fraction of the image.
%
% Outputs:
%   wgts          - Weights for combining the light groups.
%   combinedScene - The final scene.  You can get its true dynamic
%                   range and median using
%                      sceneGet(scene,'dynamic range log10')
%                      sceneGet(scene,'median luminance')
% 
% Description:
%   This calculation is based on the assumption that there are visible
%   light sources in light groups. In that case, the brightest regions
%   in the scene are the light sources themselves.  And we know
%   something about the general level of those sources (see the
%   tables in the code).
%
%   If this assumption is false, so that we are seeing a part of the
%   that is illuminated by a light source, but the source itself is
%   not visible, the calculation will return but not be right.
% 
%   In the future, we might check whether there are visible light
%   sources by a threshold value.
%
% See also
%   s_autoLightGroups (isetauto)
%   s_downloadLightGroups (isethdrsensor)

%% Probably should be parser.

if notDefined('scenes'),        error('Scenes required.');        end
if notDefined('DR'),            error('Dynamic range required.'); end
if notDefined('lowlightlevel'), lowlightlevel = 10;               end  % NITS

%% Headlights

% Define luminance range for headlights
% | Headlight Type | Luminance Range (cd/m²)   |
% |----------------|---------------------------|
% | Halogen        | 20,000 - 30,000           |
% | HID (Xenon)    | 50,000 - 80,000           |
% | LED            | 40,000 - 90,000           |
% | Laser          | 100,000 - 200,000         |

% Set the maximum luminance for headlights - 1e4 x a random number
% between 2 and 20.
peakLumForHeadlight = max(rand(1) * 20, 2) * 1e4;

% Get the current luminance of the headlights scene
currentL = sceneGet(scenes{1}, 'max luminance');

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
peakLumForStreetlight = max(rand(1) * 5, 1) * 1e4;

% Get the current luminance of the streetlights scene
currentL = sceneGet(scenes{2}, 'max luminance');

% Calculate the weight for streetlights
wgts(2) = peakLumForStreetlight / currentL;

%% Other Lights (e.g., Tail Lights)

% Define luminance range for other lights (relative to headlights)
% | Light Type  | Luminance Relative to Headlights |
% |-------------|----------------------------------|
% | Tail Lights | 0.04% - 1%                         |
% | Brake Lights| 10% - 20%                        |

% Set the maximum luminance for other lights (tail lights)
peakLumForOtherlight = max(rand(1) * 100, 4) * 1e-4 * peakLumForHeadlight;

% Get the current luminance of the other lights scene
currentL = sceneGet(scenes{3}, 'max luminance');

% Calculate the weight for other lights
wgts(3) = peakLumForOtherlight / currentL;

%% Skylight

% Skylight luminance depends on the dynamic range, using mean luminance
% Dynamic range is specified in linear units, e.g., 10^4, not dB
meanLumForSkylight = peakLumForHeadlight / DR;

% Get the current luminance of the skymap scene
% currentL = sceneGet(scenes{4}, 'mean luminance');
val = sceneGet(scenes{4}, 'percentile luminance',0.1);
currentL = val.lum;

% Calculate the weight for skylight
wgts(4) = meanLumForSkylight / currentL;

%% Combine the scenes
% Combine the scenes with the calculated weights
combinedScene = sceneAdd(scenes, wgts);

combinedScene = sceneAdjustLuminance(combinedScene,'median',lowlightlevel);

% Store the weights in the metadata of the combined scene
combinedScene.metadata.wgts = wgts;

end