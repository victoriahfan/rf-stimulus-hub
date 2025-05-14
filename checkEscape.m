function shouldExit = checkEscape()
%% CHECKESCAPE 
% OUTPUT:
%   shouldExit   logical scalar — true when the ESCAPE key is down
%
% USAGE:
%   shouldExit = checkEscape()
%
% Written by Victoria Fan (08/2022); last modified 05/2025.

persistent escKey
if isempty(escKey)
    escKey = KbName('ESCAPE');
end
[~, ~, kb] = KbCheck;
shouldExit = kb(escKey);
end