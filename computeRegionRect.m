function regionRect = computeRegionRect(regionOpt, gridSizePx, screenXpx, screenYpx)
%% COMPUTEREGIONRECT   Calculate pixel bounding box for a named region
% INPUTS:
%   regionOpt      string — region code(s), e.g.:
%                      'fullscreen'     centered square of size gridSizePx
%                      'full','left','right','top','bottom'
%                      'tl','tr','bl','br'  quadrants
%                      'nw','n','ne','w','center','e','sw','s','se'  thirds
%                      or combinations like 'se+e' or 'left,top'
%   gridSizePx     scalar — tile side length in pixels (used for 'fullscreen')
%   screenXpx      scalar — total screen width in pixels
%   screenYpx      scalar — total screen height in pixels
%
% OUTPUT:
%   regionRect     1×4 vector [x1, y1, x2, y2] giving the pixel bounds  
%                  of the (possibly combined) region on screen  
%
% USAGE:
%   regionRect = computeRegionRect(regionOpt, gridSizePx, screenXpx, screenYpx)
%
% Written by Victoria Fan (05/2025); last modified 05/2025.

if strcmpi(regionOpt, 'fullscreen')
    % Center a single tile
    cx = floor((screenXpx-gridSizePx)/2);
    cy = floor((screenYpx-gridSizePx)/2);
    regionRect = [cx, cy, cx+gridSizePx, cy+gridSizePx];
    return
end

% Calculate thirds based on full‐screen size
thirdX = floor(screenXpx/3);
twoThirdX = ceil(2*screenXpx/3);
thirdY = floor(screenYpx/3);
twoThirdY = ceil(2*screenYpx/3);

% Split regionOpt tokens
s = lower(strrep(regionOpt, ' ', ''));
tokens = split(s, {'+', ','});

% Map each token to a rect
rects = nan(numel(tokens), 4);
for i = 1:numel(tokens)
    t = tokens{i};
    switch t
        case 'full'
            R = [0, 0, screenXpx, screenYpx];
        case 'left'
            R = [0, 0, floor(screenXpx/2), screenYpx];
        case 'right'
            R = [ceil(screenXpx/2), 0, screenXpx, screenYpx];
        case 'top'
            R = [0, 0, screenXpx, floor(screenYpx/2)];
        case 'bottom'
            R = [0, ceil(screenYpx/2), screenXpx, screenYpx];
        case {'tl','1'}
            R = [0, 0, floor(screenXpx/2), floor(screenYpx/2)];
        case {'tr','2'}
            R = [ceil(screenXpx/2), 0, screenXpx, floor(screenYpx/2)];
        case {'bl','3'}
            R = [0, ceil(screenYpx/2), floor(screenXpx/2), screenYpx];
        case {'br','4'}
            R = [ceil(screenXpx/2), ceil(screenYpx/2), screenXpx, screenYpx];
        case 'nw'
            R = [0, 0, thirdX, thirdY];
        case 'n'
            R = [thirdX, 0, twoThirdX, thirdY];
        case 'ne'
            R = [twoThirdX, 0, screenXpx, thirdY];
        case 'w'
            R = [0, thirdY, thirdX, twoThirdY];
        case 'center'
            R = [thirdX, thirdY, twoThirdX, twoThirdY];
        case 'e'
            R = [twoThirdX, thirdY, screenXpx, twoThirdY];
        case 'sw'
            R = [0, twoThirdY, thirdX, screenYpx];
        case 's'
            R = [thirdX, twoThirdY, twoThirdX, screenYpx];
        case 'se'
            R = [twoThirdX, twoThirdY, screenXpx, screenYpx];
        otherwise
            R = [0, 0, screenXpx, screenYpx];
    end
    rects(i, :) = R;
end

% Union all token‐rects into one bounding box
x1 = min(rects(:, 1));
y1 = min(rects(:, 2));
x2 = max(rects(:, 3));
y2 = max(rects(:, 4));
regionRect = [x1, y1, x2, y2];
end