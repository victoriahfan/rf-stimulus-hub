# RF Stimulus Hub

A MATLAB App for receptive field mapping of neural populations. It subdivides the visual field into user-defined quadrants, and presents dense noise or other visual stimuli in specified region(s). Includes interactive quadrant and grid preview with mouse-based region selection.

## Requirements

* **MATLAB R2023a** (created and tested). Older versions may have compatibility issues. Will be compiled into standalone app in the future.
* **Psychtoolbox** (for reliable stimulus timing and graphics)
* **Image Processing Toolbox** (for handling movie frames)
* **App Designer**

## Installation

1. Clone the repo:

   ```bash
   git clone https://github.com/victoriahfan/rf-stimulus-hub.git
   ```
2. Make sure Psychtoolbox is installed in MATLAB:

   ```matlab
   DownloadPsychtoolbox;
   ```

## File Structure

```
RFStimulusMapper/        # Repository root
├─ RFStimGUI.mlapp       # App Designer GUI
├─ playRFStim.m          # Core stimulus-presentation function
├─ deg2px.m              # Converts visual degrees to screen pixels
├─ computeRegionRect.m   # Defines screen-region rectangles
├─ computeGridRegionPx.m # Computes tile and mask pixel regions
├─ checkEscape.m         # Polls for ESC key press
└─ README.md             # This file
```

## Usage

### Launching the GUI

In MATLAB:

```matlab
RFStimGUI
```

1. **Load Movie**: Click **Load Movie** and select a `.mat` file containing `rfMovie` or custom movie (m×n×frames).
2. **Set Parameters**:

   * Viewing distance (cm)
   * Tile size (deg)
   * Grid dimensions (select or custom)
   * Initial gray duration (s)
   * Stimulus duration (s)
   * ISI (s)
   * Number of cycles
3. **Preview**: Click on the grid preview to verify subdivisions.
4. **Start**: Click **Start** to run the RF mapping stimulus. Press **Esc** to abort.

### Command-Line Invocation

Bypass the GUI:

```matlab
movData = load('rfMovie.mat');
playRFStim(rfMovie, ...
   'tileDeg', 20, ...
   'durInitGray', 10, ...
   'nCycle', 10, ...
   'isi', 4, ...
   'regionOpt', 'full', ...
   'viewingDistanceCm', 20, ...
   'screenNumber', 1);
```

## Function Reference

* **playRFStim.m**: Main loop that displays movie frames, unmasks tiles, and enforces timing.
* **deg2px.m**: `pixels = deg2px(deg, distCm, screenPxlWidth, screenCmWidth)`
* **computeRegionRect.m**: Returns \[x y width height] for named regions (e.g., 'full', 'tl', 'br').
* **computeGridRegionPx.m**: Calculates pixel coordinates for each tile and mask within a region.
* **checkEscape.m**: Non-blocking check for ESC key to stop stimulus.

---

*© 2025, Victoria Fan, Higley Lab, Yale School of Medicine*
