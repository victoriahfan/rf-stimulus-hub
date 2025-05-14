function playRFStim(movData, tileDeg, durInitGray, nCycle, isi, varargin)
%% PLAYRFSTIM   Receptive-field mapping stimulus presentation
%   Press ESC to abort early (no CSV saved).
%
% INPUTS:
%   movData            m×n×d array of grayscale frames (0–1)
%   tileDeg            scalar >0 — tile size in visual degrees
%   durInitGray        scalar ≥0 — initial gray‐screen duration (s)
%   nCycle             integer ≥1 — number of random tile cycles
%   isi                scalar ≥0 — inter‐stimulus gray interval (s)
%
% Name–Value Pairs:
%   'regionOpt'         char — region specifier (default 'full'; e.g. 'tl','se+e')
%   'viewingDistanceCm' scalar — viewing distance for deg→px conversion (default 20)
%   'screenNumber'      integer — Psychtoolbox screen ID (default 1)
%   'gammaTable'        numeric Px3 — gamma lookup table (loads first *NormGamTab*.mat if empty)
%
% OUTPUT:
%   None (writes “stim_YYYYMMDD_HHMM.csv” listing the random tile order)
% 
% USAGE:
%   playRFStim2(movData, tileDeg, durInitGray, nCycle, isi, Name,Value,…)
%
% Written by Victoria Fan (08/2022); last modified 05/2025.

%% Parse & validate inputs
isPosScalar    = @(x) validateattributes(x, {'numeric'}, {'scalar', '>', 0});
isNonNegScalar = @(x) validateattributes(x, {'numeric'}, {'scalar', '>=', 0});
isCharOrStr    = @(s) ischar(s) || isstring(s);
isScreenNum    = @(x) validateattributes(x, {'numeric'}, {'scalar', 'integer', '>=', 1});
isGammaTab     = @(x) isnumeric(x) && size(x,2)==3;

p = inputParser;
p.FunctionName  = mfilename;
p.CaseSensitive = false;

% Required
addRequired(p, 'movData', @(x) validateattributes(x, {'numeric'}, {'3d', 'nonempty'}));
addRequired(p, 'tileDeg', isPosScalar);
addRequired(p, 'durInitGray', isNonNegScalar);
addRequired(p, 'nCycle', @(x) validateattributes(x, {'numeric'}, {'scalar', 'integer', '>=', 1}));
addRequired(p, 'isi', isNonNegScalar);

% Name/value pairs
addParameter(p, 'regionOpt', 'full', isCharOrStr);
addParameter(p, 'viewingDistanceCm', 20, isPosScalar);
addParameter(p, 'screenNumber', 1, isScreenNum);
addParameter(p, 'gammaTable', [], isGammaTab);

parse(p, movData, tileDeg, durInitGray, nCycle, isi, varargin{:});
R = p.Results; 

%% Psychtoolbox & screen setup
PsychDefaultSetup(2);
Screen('Preference', 'SkipSyncTests', 1);
Screen('Preference', 'Verbosity', 0);

[window, windowRect] = PsychImaging('OpenWindow', R.screenNumber, .5);
Priority(MaxPriority(window));
screenXpx = windowRect(3);
screenYpx = windowRect(4);

%% Calculate tile size in px & sanity check
displayMM = Screen('DisplaySize', window); % [mm]
gridSizePx = deg2px(R.tileDeg, R.viewingDistanceCm, screenXpx, displayMM(1));
if gridSizePx > screenXpx || gridSizePx > screenYpx
    error('Tile %d px too big for screen [%d×%d].', gridSizePx, screenXpx, screenYpx);
end

destRect = [0,0,screenXpx,screenYpx];
indRect = [screenXpx-200, screenYpx-200, screenXpx, screenYpx];

%% Gamma table (cached)
persistent defaultGamTab
[origGam, ~] = Screen('ReadNormalizedGammaTable', R.screenNumber);
cleanupObj = onCleanup(@() Screen('LoadNormalizedGammaTable', R.screenNumber, origGam));

if ~isempty(R.gammaTable)
    Screen('LoadNormalizedGammaTable', R.screenNumber, R.gammaTable);
else
    if isempty(defaultGamTab)
        folder = fileparts(which(mfilename));
        D = dir(fullfile(folder, '*NormGamTab*.mat'));
        if isempty(D)
            error('No default gamma file found.'); 
        end
        tmp = load(fullfile(folder,D(1).name));
        defaultGamTab = tmp.NormGamTab;
    end
    Screen('LoadNormalizedGammaTable', R.screenNumber, defaultGamTab);
end
Screen('BlendFunction', window, 'GL_SRC_ALPHA','GL_ONE_MINUS_SRC_ALPHA');

%% Precalculate everything outside the trial loop
% Textures
nFrame = size(R.movData, 3);
movieTextures = arrayfun(@(f) Screen('MakeTexture', window,R.movData(:,:,f)), 1:nFrame);

% Region & mask rectangles
regionRect = computeRegionRect(R.regionOpt, gridSizePx, screenXpx, screenYpx);
[maskRects, intEdgeRects, extMaskRects] = ...
    computeGridRegionPx(screenXpx, screenYpx, gridSizePx, regionRect);
nTiles = size(maskRects, 2);

% Precalculate "other‐tiles" complements
allIdx = 1:nTiles;
complements = arrayfun(@(i) allIdx(allIdx~=i), 1:nTiles, 'UniformOutput', false);

% Row→col mapping
x1 = maskRects(1, :); y1 = maskRects(2, :);
nx = numel(unique(x1)); ny = numel(unique(y1));
colIdx = reshape(1:nTiles, ny, nx).';  % transpose in one step
row2col = colIdx(:);

%% Main stimulus loop
exitNow = false;

nTrials = R.nCycle * nTiles;
allSeq = zeros(1,nTrials);
ptr = 1;

for cyc = 1:R.nCycle
    rm = randperm(nTiles);
    order = row2col(rm);

    for k = 1:nTiles
        fprintf('Cycle %d/%d -- Tile %d/%d -- Position %d -- Trial %d/%d\n', ...
            cyc, R.nCycle, k, nTiles, rm(k), (cyc-1)*nTiles + k, nTrials);

        for f = 1:nFrame
            if checkEscape() % poll ESC
                exitNow = true;
                break; % break out of frame loop
            end
            Screen('DrawTexture', window, movieTextures(f), [], destRect);

            % Single FillRect for "all masks”
            allMasks = [extMaskRects, maskRects(:, complements{order(k)})];
            Screen('FillRect', window, .5, allMasks);
            if ~isempty(intEdgeRects)
                Screen('FillRect', window, .5, intEdgeRects);
            end

            % Photodiode
            Screen('FillRect', window, 0, indRect);
            Screen('Flip', window);
        end

        if exitNow, break; end % break out of tile loop

        % inter-stimulus gray
        Screen('FillRect', window, .5);
        Screen('Flip', window);
        WaitSecs(R.isi);
    end

    if exitNow, break; end % break out of cycle loop

    allSeq(ptr:ptr+nTiles-1) = rm;
    ptr = ptr + nTiles;
end

%% Cleanup & return
Screen('Close', movieTextures);
Priority(0);
sca;

if exitNow
    fprintf('playRFStim: I shtawped the run (ESC pressed).\n');
    return;
end

%% Save sequence if completed
fname = sprintf('stim_%s.csv', char(datetime('now', 'Format', 'yyyyMMdd_HHmm')));
writematrix(allSeq', fname);
fprintf('Saved %s\n', fname);
end