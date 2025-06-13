function aborted = showGray(window, duration)
%% SHOWGRAY   Show a gray screen for a specified duration with ESC to abort
% OUTPUT:
%   aborted   logical scalar — true if the ESCAPE key was pressed during the gray period
%
% USAGE:
%   aborted = showGray(window, duration)
%
% Written by Victoria Fan (08/2022); last modified 05/2025.

Screen('FillRect', window, .5);
Screen('Flip', window);
t0 = GetSecs;
aborted = false;
while GetSecs - t0 < duration
    if checkEscape()
        aborted = true;
        return;
    end
    WaitSecs(0.01);
end
end
