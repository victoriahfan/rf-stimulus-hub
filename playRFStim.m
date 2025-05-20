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
%   'regionOpt'         string — region code(s) e.g.:
%                           'fullscreen'     centered square of size tileSizePx
%                           'full','left','right','top','bottom'
%                           'tl','tr','bl','br'  quadrants
%                           'nw','n','ne','w','center','e','sw','s','se'  thirds
%                           or combinations like 'se+e' or 'left,top'
%   'viewingDistanceCm' scalar — viewing distance for deg→px conversion (default 20)
%   'screenNumber'      integer — Psychtoolbox screen ID (default 1)
%   'gammaTable'        numeric Px3 — gamma lookup table (loads first *NormGamTab*.mat if empty)
%
% OUTPUT:
%   Writes a CSV file named "stim_YYYYMMDD_HHMM.csv" containing five columns:
%       Position — tile index in the random sequence (1..nTiles)  
%       Row — tile row number (1 at top)  
%       Column — tile column number (1 at left)  
%       X — horizontal center of that tile, normalized [0=left … 1=right]  
%       Y — vertical center of that tile, normalized [0=top  … 1=bottom]
%
% USAGE:
%   playRFStim(rfMovie, 20, 1, 1, 4, 'regionOpt', 'sw+w+s+center', 'viewingDistanceCm', 20, 'ScreenNumber', 1)
%
% Written by Victoria Fan (08/2022); last modified 05/2025.

%% Psychtoolbox setup
PsychDefaultSetup(2);
Screen('Preference', 'SkipSyncTests', 1);
Screen('Preference', 'Verbosity', 0);

availableScreens = Screen('Screens');    % e.g. [0] on mac, [0 1] on a two‐monitor PC
defaultScreen = max(availableScreens);

%% Validators
isPosScalar    = @(x) validateattributes(x, {'numeric'}, {'scalar','positive'});
isNonNegScalar = @(x) validateattributes(x, {'numeric'}, {'scalar','nonnegative'});
isIntGE1       = @(x) validateattributes(x, {'numeric'}, {'scalar','integer','positive'});
isCharOrStr    = @(s) ischar(s)||isstring(s);

% Validator that also checks membership
isScreenNum    = @(x) assert( isnumeric(x) && isscalar(x) && any(x==availableScreens), ...
    'screenNumber must be one of [%s]', num2str(availableScreens) );
isGammaTab     = @(x) isnumeric(x)&&size(x,2)==3;

%% Parser
p = inputParser;
p.FunctionName  = mfilename;
p.CaseSensitive = false;

% Required positional
addRequired(p, 'movData', @(x) validateattributes(x, {'numeric'}, {'3d', 'nonempty'}));
addRequired(p, 'tileDeg', isPosScalar);
addRequired(p, 'durInitGray', isNonNegScalar);
addRequired(p, 'nCycle', isIntGE1);
addRequired(p, 'isi', isNonNegScalar);

% Optional name–value
addParameter(p, 'regionOpt', 'full', isCharOrStr);
addParameter(p, 'viewingDistanceCm', 20, isPosScalar);
addParameter(p, 'screenNumber', defaultScreen, isScreenNum);
addParameter(p, 'gammaTable', [], isGammaTab);

% Parse both positional + name/value
parse(p, movData, tileDeg, durInitGray, nCycle, isi, varargin{:});
R = p.Results;

%% Psychtoolbox & screen setup
[window, windowRect] = PsychImaging('OpenWindow', R.screenNumber, .5);
Priority(MaxPriority(window));
screenXpx = windowRect(3);
screenYpx = windowRect(4);

%% Calculate tile size in px & sanity check
displayMM = Screen('DisplaySize', window); % [mm]
tileSizePx = deg2px(R.tileDeg, R.viewingDistanceCm, screenXpx, displayMM(1));
if tileSizePx > screenXpx || tileSizePx > screenYpx
    error('Tile %d px too big for screen [%d×%d].', tileSizePx, screenXpx, screenYpx);
end

destRect = [0, 0, screenXpx, screenYpx];
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

%% Precalculate stuff
% Textures
nFrame = size(R.movData, 3);
movieTextures = arrayfun(@(f) Screen('MakeTexture', window, R.movData(:,:,f)), 1:nFrame);

% Region & mask rectangles
regionRect = computeRegionRect(R.regionOpt, tileSizePx, screenXpx, screenYpx);
[maskRects, intEdgeRects, extMaskRects] = ...
    computeGridRegionPx(screenXpx, screenYpx, tileSizePx, regionRect);
nTiles = size(maskRects, 2);

% "Other‐tiles" complements
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

        % Inter-stimulus gray
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

% Calculate row & col in ROW-MAJOR
rows = floor((allSeq-1)/nx) + 1; % 1 at top, increments every nx
cols = mod(allSeq-1, nx) + 1; % 1 at left, wraps every nx

% Map scanning positions → maskRects indices for accurate rectangles
mappedIdx = row2col(allSeq);

% Center‐of‐tile in pixels, then normalize to [0,1]
xCenters = (maskRects(1, mappedIdx) + maskRects(3, mappedIdx)) / 2;
yCenters = (maskRects(2, mappedIdx) + maskRects(4, mappedIdx)) / 2;
xNorm    = xCenters ./ screenXpx; % 0=left, 1=right
yNorm    = yCenters ./ screenYpx; % 0=top,  1=bottom

% Save matrix as csv
outMat = [allSeq(:), rows(:), cols(:), xNorm(:), yNorm(:)];
writematrix(outMat, fname);

fprintf('Saved %s\n', fname);
end