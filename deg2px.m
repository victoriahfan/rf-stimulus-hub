function tilePx = deg2px(tileDeg, viewDistCm, screenXpx, displayWidthMm)
%% deg2px   Convert visual degrees to pixel size
% USAGE:
%   tilePx = deg2px(tileDeg, viewDistCm, screenXpx, displayWidthMm)
%
% INPUTS:
%   tileDeg         scalar — size in visual degrees (°)
%   viewDistCm      scalar — viewing distance in centimeters
%   screenXpx       scalar — horizontal screen resolution in pixels
%   displayWidthMm  scalar — physical screen width in millimeters
%
% OUTPUT:
%   tilePx          scalar — corresponding side length in pixels
%
% Written by Victoria Fan (05/2025); last modified 05/2025.

screenCm  = displayWidthMm/10; % mm → cm
pxPerCm   = screenXpx/screenCm;
tileCm    = 2 * viewDistCm * tan(deg2rad(tileDeg/2));
tilePx    = round(tileCm * pxPerCm);
end