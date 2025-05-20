function [maskRects, internalEdgeRects, extMaskRects] = computeGridRegionPx(screenX, screenY, sq, regionRect)
%% COMPUTEGRIDREGIONPX   Calculate tile and mask rectangles for a region
% INPUTS:
%   screenX            scalar — total screen width in pixels
%   screenY            scalar — total screen height in pixels
%   sq                 scalar — tile side length in pixels
%   regionRect         1×4 vector [x1, y1, x2, y2] — bounding box of region (px)
%
% OUTPUTS:
%   maskRects          4×N array — each column is [x1; y1; x2; y2] for a tile
%   internalEdgeRects  4×M array — padding‐strip rectangles inside the region
%   extMaskRects       4×K array — rectangles masking everything outside the region
%
% USAGE:
%   [maskRects, internalEdgeRects, extMaskRects] = ...
%       computeGridRegionPx(screenX, screenY, sq, regionRect)
%
% Written by Victoria Fan (05/2025); last modified 05/2025.

% Calculate tile grid & padding inside a region
rW = regionRect(3)-regionRect(1); % region width in px
rH = regionRect(4)-regionRect(2); % region height in px
nx = floor(rW/sq); % number of tiles fitting horizontally
ny = floor(rH/sq); % number of tiles fitting vertically

% Calculate leftover pixels and half‐padding on each side
remW = rW - nx*sq; % extra width beyond whole tiles
xPad = floor(remW/2); % left/right padding in px
remH = rH - ny*sq; % extra height beyond whole tiles
yPad = floor(remH/2); % top/bottom padding in px

% Preallocate array for each tile's [x1; y1; x2; y2]
maskRects = zeros(4, nx*ny);
idx = 1;
for ix = 0:(nx-1)
    for iy = 0:(ny-1)
        % Calculate top-left corner of this tile
        x0 = regionRect(1) + xPad + ix*sq;
        y0 = regionRect(2) + yPad + iy*sq;
        % Store rectangle for this tile
        maskRects(:, idx) = [x0; y0; x0+sq; y0+sq];
        idx = idx+1;
    end
end

% Build internal padding strips to fill any leftover space inside region
internalEdgeRects = [];
if xPad > 0
    % Left strip
    internalEdgeRects(:, end+1) = [regionRect(1); regionRect(2); regionRect(1)+xPad; regionRect(4)];
end

if (remW-xPad) > 0
    % Right strip
    internalEdgeRects(:, end+1) = [regionRect(3) - (remW-xPad); regionRect(2); regionRect(3); regionRect(4)];
end

if yPad > 0
    % Bottom strip
    internalEdgeRects(:, end+1) = [regionRect(1); regionRect(2); regionRect(3); regionRect(2)+yPad];
end

if (remH-yPad) > 0
    % Top strip
    internalEdgeRects(:, end+1) = [regionRect(1); regionRect(4)-(remH-yPad); regionRect(3); regionRect(4)];
end

% Build external masks to cover everything outside the region
extMaskRects = [];
if regionRect(1) > 0
    % Left of region
    extMaskRects(:, end+1) = [0; 0; regionRect(1); screenY];
end

if regionRect(3) < screenX
    % Right of region
    extMaskRects(:, end+1) = [regionRect(3); 0; screenX; screenY];
end

if regionRect(2) > 0
    % Below region
    extMaskRects(:, end+1) = [regionRect(1); 0; regionRect(3); regionRect(2)];
end

if regionRect(4) < screenY
    % Above region
    extMaskRects(:, end+1) = [regionRect(1); regionRect(4); regionRect(3); screenY];
end
end