# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a MATLAB codebase for analyzing and comparing intraoperative vs. clinic-recorded RCS (Responsive Cortical Stimulation) data from Parkinson's disease patients. The analysis compares ECoG (electrocorticography) and LFP (local field potential) recordings from NeuroOmega (intraoperative) and RC+S devices (clinic).

## Environment Setup

Before running any analysis:

```matlab
% Run this to set up paths and environment
setup_rcs
```

This script:
- Resets MATLAB path
- Sets environment variables for Box, OneDrive, and Dropbox directories
- Adds paths to this repository, Analysis-rcs-data (sibling directory), and FieldTrip toolbox
- **Note**: `setup_rcs.m` contains hardcoded paths specific to David's machine. You'll need to modify lines 7-9 to match your local environment.

## Required Dependencies

- **FieldTrip toolbox**: Expected at `../fieldtrip/` (sibling directory to this repo)
  - Must have Brainstorm support for FOOOF (included in recent FieldTrip versions)
  - Verify with: `ft_hastoolbox('brainstorm')`
- **Analysis-rcs-data**: Expected at `../Analysis-rcs-data/` - contains the `ProcessRCS` function for reading RC+S data files
- **brewermap**: Color scheme library, expected at `../fieldtrip/external/brewermap/`
- **fooof_mat**: NO LONGER REQUIRED - Previous wrapper implementation replaced by FieldTrip native FOOOF

## Running Analyses

### Main Analysis Pipeline

```matlab
% Run the complete analysis pipeline
master_script_rcs_neuroomega
```

This master script:
1. Calls `setup_rcs` to configure environment
2. Calls `subjects_to_analyze` to define which subjects and data files to process
3. Iterates through subjects, calling three analysis scripts for each:
   - `analyze_intraop` - processes NeuroOmega intraoperative data
   - `analyze_rcs` - processes RC+S clinic data
   - `compare_intraop_rcs` - statistical comparison and visualization

### HFO (High-Frequency Oscillation) Analysis

```matlab
% Run HFO-focused analysis (200-400 Hz band)
master_script_rcs_neuroomega_HFO
```

Uses `subjects_to_analyze_HFO`, `analyze_intraop_HFO`, `analyze_rcs_HFO`, and `compare_intraop_rcs_HFO`.

## Code Architecture

### Data Flow

1. **Subject Configuration** (`subjects_to_analyze.m`):
   - Defines subject IDs, file paths (Box directory structure)
   - Specifies time windows, re-referencing schemes, and data quality exclusions
   - **`sidesToUseCell`**: Specifies hemisphere(s) in intraoperative data ('b' = bilateral, 'l' = left only, 'r' = right only)
   - **`rcsOrder`**: Specifies L/R hemisphere ordering for each RCS session
   - Returns cell arrays: `subjsToAnalyze`, `intraOpFiles`, `rcsFiles`, `timeStampStart/Stop`, `rerefCell`, `sidesToUseCell`, `makeNan`, `rcsOrder`

2. **Intraoperative Data Processing** (`analyze_intraop.m`):
   - Loads `.mat` files with `ecog.contact` and `lfp.contact` structures
   - Applies manual data quality exclusions (NaN-ing bad segments via `makeNan` ranges)
   - **Channel labeling using `sidesToUse` parameter**:
     - Bilateral ('b'): channels 1-4 → LFPL0-3/ECOGL8-11, channels 5-8 → LFPR0-3/ECOGR8-11
     - Left only ('l'): all channels → LFPL0-3/ECOGL8-11
     - Right only ('r'): all channels → LFPR0-3/ECOGR8-11
   - Re-references using either bipolar or bipolar-skip montages
     - **Bipolar skip montage labels**: LFPL2-0, LFPL3-1, ECOGL10-8, ECOGL11-9 (and R equivalents)
     - For unilateral data, hemisphere detection uses `contains(label,'LFPL')` or `contains(label,'ECOGL')` (not just 'L')
   - Resamples to 250 Hz
   - Creates overlapping 2-second trials (50% overlap) via FieldTrip
   - Computes power spectral density using Hanning taper FFT
   - Normalizes power as percentage of total (4-125 Hz)
   - Bins into frequency bands: theta (4-8 Hz), alpha (8-12 Hz), low beta (13-20 Hz), high beta (20-30 Hz), broadband gamma (50-125 Hz)
   - Output: `base_fre1Intraop` structure with fields `powspctrm`, `normalizedPow`, `averagedBins`, `label`

3. **RC+S Data Processing** (`analyze_rcs.m`):
   - Calls `ProcessRCS` from Analysis-rcs-data to read RC+S session files
   - Creates `combinedDataTable` merging all data streams
   - Filters to specified time windows using event log timestamps
   - Handles multiple recording iterations (montage changes) via `timeDomainSettings.recNum`
   - **NEW**: Adds region prefixes to channel labels to match intraop naming:
     - Uses `rcsOrder{subjNum}{index}` to determine L/R hemisphere for each session
     - Detects ECoG vs LFP based on contact numbers (+8/+9/+10/+11 = ECoG, 0-3 = LFP)
     - Prepends ECOGL/ECOGR/LFPL/LFPR to create labels like "ECOGL+8-10", "LFPR0-2"
   - Converts to FieldTrip format with proper channel labels
   - **Handles duplicate channels while preserving original device order:**
     - Uses `[labels, inds] = unique(chansStruct{index})` to identify unique channels
     - Applies `labelsWithPrefix(inds)` to restore original RCS device ordering (undoes alphabetical sorting)
     - Selects `tempData(inds,:)` for first occurrence of each unique channel in original order
     - Ensures channel labels always match their corresponding data rows
   - Resamples to 250 Hz if needed
   - Excludes trials with NaN values
   - Same spectral analysis pipeline as intraop
   - Output: `base_fre1RCSall` cell structure with `averagedBins`, `normalizedPow`, `chans` (supports multiple RC+S sessions)

4. **Statistical Comparison** (`compare_intraop_rcs.m`):
   - Collapses multiple RC+S sessions into single structure
   - **NEW**: Identifies ECoG vs LFP channels by region prefix (contains 'ECOG' or 'LFP')
   - Supports three statistical tests (controlled by flags in master script):
     - Signed rank test (`signedRankTest = 1`)
     - Rank sum test (`rankSumTest = 1`)
     - **Permutation test** (`permute_test = 1`) - currently preferred method
   - **NEW**: Channel-by-channel permutation testing:
     - Matches RCS and intraop channels by label using `strcmp()`
     - Loops through all RCS sessions and finds matching intraop channels
     - Performs 10,000 permutations per channel-frequency bin pair
     - Calculates Bonferroni correction: `alpha = 0.05 / (numFreqBins × numMatchedPairs)`
     - Stores p-values, effect sizes, and observed differences in `statsResultsPerm`
   - **NEW**: Individual channel plots with significance marking:
     - Plots each matched channel pair in separate subplots
     - Finds matching RCS channel by label for each subplot
     - Adds Bonferroni-corrected significance stars on EACH subplot
     - Stars centered on frequency bins where `p < bonferroniThreshold`
     - Only xlabel/ylabel shown on first subplot
   - Generates comparison plots with shaded SEM bands (red = intraop, blue = RCS)
   - Saves figures to OneDrive Research folder if `saveFigure = 1`

### Channel Naming Convention (UPDATED)

**Critical**: Channel labels now follow a standardized naming convention that enables label-based matching:

**Intraoperative Channels:**
- Before rereferencing: LFPL0-3, LFPR0-3, ECOGL8-11, ECOGR8-11
- After bipolar skip rereferencing: LFPL2-0, LFPL3-1, LFPR2-0, LFPR3-1, ECOGL10-8, ECOGL11-9, ECOGR10-8, ECOGR11-9

**RCS Channels:**
- Labeled with region prefix + original contact notation ('+' character stripped)
- Examples: "ECOGL10-8", "LFPR2-0", "ECOGR10-8"
- Hemisphere (L/R) determined by `rcsOrder{subjNum}{sessionIndex}`
- Region (ECOG/LFP) determined by contact numbers
- **IMPORTANT**: '+' characters automatically removed via `strrep(chanLabel, '+', '')` to match intraop format
- **Channel order preservation**: Original RCS device channel ordering is preserved using `unique()` indices to undo alphabetical sorting

**Channel Matching:**
- Comparison scripts use `strcmp()` to match channels by label
- No longer relies on position-based indexing
- Robust to different channel orderings and missing channels
- RCS channels matched to intraop channels with identical labels
- Channel labels always correspond to their data rows (order-preserving mapping via `inds` from `unique()`)

### Re-referencing Options

Two schemes available (set in `rerefCell`):
- `bipolarReref`: Sequential bipolar (channel N - channel N+1)
- `bipolarSkipReref`: Skip bipolar (channel N - channel N+2) - **preferred for matching RC+S recording montages**

### Data Quality

- Manual artifact exclusion via `makeNan` cell array in `subjects_to_analyze.m`
- Trials with any NaN values are excluded from spectral analysis
- **Recent work**: "manual inspection to ignore NaN parts", "working on saving individual power trials for perm test"

### FOOOF Spectral Parameterization (UPDATED January 2026)

**Overview:**
FOOOF (Fitting Oscillations & One-Over-F) separates the aperiodic (1/f) component from periodic peaks in power spectra. This enables comparison of neural noise characteristics between intraoperative and clinic recordings.

**Implementation:**
- Uses FieldTrip's native FOOOF support (via Brainstorm internally)
- Replaces previous broken `fooof_mat` wrapper implementation
- Runs on **trial-averaged data only** (FOOOF requirement)

**Configuration:**
```matlab
cfgFooof = [];
cfgFooof.method = 'mtmfft';
cfgFooof.output = 'fooof_aperiodic';  % Get aperiodic (1/f) component only
cfgFooof.taper = 'hanning';
cfgFooof.foi = 4:0.5:50;              % 4-50 Hz for fitting
cfgFooof.keeptrials = 'no';           % REQUIRED for FOOOF
cfgFooof.fooof.freq_range = [4 50];
cfgFooof.fooof.peak_width_limits = [1 12];
cfgFooof.fooof.max_peaks = 6;
cfgFooof.fooof.min_peak_height = 0.1;
cfgFooof.fooof.aperiodic_mode = 'fixed';  % offset + exponent model
cfgFooof.fooof.peak_threshold = 2.0;

base_fre1_fooof = ft_freqanalysis(cfgFooof, dataPreProcOverlap);

% Store FOOOF parameters and aperiodic spectrum
base_fre1Intraop.fooofparams = base_fre1_fooof.fooofparams;
base_fre1Intraop.fooof_powspctrm = base_fre1_fooof.powspctrm;  % Aperiodic spectrum (LINEAR scale)
base_fre1Intraop.fooof_freq = base_fre1_fooof.freq;
```

**Output Modes:**
- `'fooof'`: Full model (aperiodic + peaks combined)
- `'fooof_aperiodic'`: Aperiodic (1/f) component only ← **Currently used**
- `'fooof_peaks'`: Peak components with aperiodic removed

**Important:** All FOOOF outputs are in **LINEAR scale** (power, not log10). Use `log10()` for visualization.

**Data Structure:**
```matlab
% Intraoperative FOOOF results
base_fre1Intraop.fooofparams(chanIdx).aperiodic_params  % [offset, exponent]
base_fre1Intraop.fooofparams(chanIdx).r_squared         % Fit quality
base_fre1Intraop.fooofparams(chanIdx).error             % Fit error
base_fre1Intraop.fooofparams(chanIdx).peak_params       % [CF, PW, BW] for each peak

% RCS FOOOF results (nested by session/iteration)
base_fre1RCSall.fooofparams{sessionIdx}{iterIdx}(chanIdx).aperiodic_params
base_fre1RCSall.fooofparams{sessionIdx}{iterIdx}(chanIdx).r_squared
```

**Statistical Comparison:**
Both signed rank (paired) and rank sum (unpaired) tests are supported:

1. **Signed Rank Test** (`signedRankTest = 1`):
   - Matches channels by label between intraop and RCS
   - Paired comparison for matched channels only
   - More sensitive when channels correspond

2. **Rank Sum Test** (`rankSumTest = 1`):
   - Compares all intraop vs all RCS channels
   - Unpaired comparison (no channel matching required)
   - More robust to missing channels

**Interpretation:**
- **Exponent** (typically 1-3): Steepness of 1/f falloff
  - Higher = steeper falloff = more neural noise
  - Lower = flatter spectrum = less noise-dominated
- **Offset**: Overall power level (log scale)
- **R-squared** > 0.8: Good fit quality
- **R-squared** < 0.8: Poor fit, may need parameter adjustment

**Quality Control:**
Use `verify_fooof_results.m` to check:
- Fit quality (R-squared values)
- Parameter ranges (exponents should be ~1-3)
- Per-channel statistics
- Identification of poor fits

**Where FOOOF is Applied:**
- `analyze_intraop.m`: After frequency binning (line ~218)
- `analyze_rcs.m`: Inside iteration loop (line ~218)
- `analyze_intraop_HFO.m`: After frequency binning (line ~218)
- `analyze_rcs_HFO.m`: Inside iteration loop (line ~218)
- `compare_intraop_rcs.m`: Signed rank and rank sum comparisons (lines ~153, ~234)
- `compare_intraop_rcs_HFO.m`: Both test types with plotting (lines ~63, ~123)

**Important Notes:**
- FOOOF runs AFTER regular spectral analysis (with `keeptrials='yes'`)
- Regular analysis keeps trials for permutation testing
- FOOOF requires separate call with `keeptrials='no'` for trial averaging
- Results stored separately in `.fooofparams` field
- Comparison scripts automatically detect which test was run and plot accordingly

**FOOOF Visualization (January 2026):**

Two types of FOOOF summary plots are generated in comparison scripts:

1. **FOOOF Modeled Power Spectrum Plots** (lines ~298-365 in `compare_intraop_rcs.m`):
   - Individual subplots per matched channel pair (2x2 for 4 channels, 4x2 for 8 channels)
   - Shows FOOOF aperiodic (1/f) component (blue = RCS, red = intraop)
   - **Data flow:**
     - `fooof_powspctrm` contains aperiodic fit in **LINEAR scale**
     - Normalize: `norm = 100 * spectrum / nansum(spectrum)` (uses `nansum()` to handle NaN values)
     - Plot: `log10(norm)` for log-scale visualization
   - Y-axis: Log₁₀ normalized power (%), typically ranges -1 to 1
   - Downward-sloping lines (steeper = larger exponent)
   - Output files: `{subj}_FOOOF_spectra.png/.eps` (regular), `{subj}_FOOOF_spectra_HFO.png/.eps` (HFO)

2. **Connected Scatter Plots for Exponent/Offset** (lines ~367-423 in `compare_intraop_rcs.m`):
   - Side-by-side subplots (exponent left, offset right)
   - Each matched channel pair shown as connected points (intraop → RCS)
   - Color-coded by channel using brewermap 'Set1' palette
   - P-values from signed rank test displayed in subplot titles
   - Output files: `{subj}_FOOOF_scatter.png/.eps` (regular), `{subj}_FOOOF_scatter_HFO.png/.eps` (HFO)

**Conditional Generation:**
- Spectrum plots require `base_fre1Intraop.fooof_powspctrm` and `base_fre1RCSall.fooof_powspctrm`
- Scatter plots require `statsResultsFooof.matchedChannels` (created when `signedRankTest = 1`)
- Both respect `saveFigure` flag for export

**Plotting Details:**
```matlab
% Data is in LINEAR scale from FieldTrip
intraopSpectrum = base_fre1Intraop.fooof_powspctrm(chanIdx, :);
% Normalize to 100% (using nansum to handle NaN values)
intraopNorm = 100 * intraopSpectrum / nansum(intraopSpectrum);
% Plot on log scale
plot(freq, log10(intraopNorm), 'r-');
ylabel('Log_{10} Normalized Power (%)');
```

## Helper Functions

- `stdshade.m`: Plots mean ± shaded SEM (standard error of mean) region
  - **Updated**: Now plots SEM instead of SD (standard deviation)
  - Called with transposed data: `stdshade(log10(squeeze(data(:,channelIdx,:)))', alpha, color)`
- `permutationTest.m`: Implements permutation testing with effect size calculation
- `permutest.m`: Alternative permutation test implementation

## Recent Development Focus

### Unilateral Data Support (January 2026)

**Problem:**
Unilateral (8-channel) intraoperative data was always labeled as LEFT hemisphere, causing channel matching failures for right-hemisphere-only subjects (e.g., RCS03).

**Solution (January 7, 2026):**
- ✅ Added `sidesToUse` parameter logic to channel labeling in `analyze_intraop.m` and `analyze_intraop_HFO.m`
- ✅ Channel labels now respect `sidesToUseCell` configuration:
  - 'b' (bilateral): channels 1-4 → LEFT, channels 5-8 → RIGHT
  - 'l' (left only): all channels → LEFT
  - 'r' (right only): all channels → RIGHT
- ✅ Fixed hemisphere detection in bipolar skip rereferencing to use `contains(label,'LFPL')` instead of `contains(label,'L')` (which incorrectly matched both LFPL and LFPR)

**Files Modified:**
- `analyze_intraop.m`: Lines 37-54 (LFP labeling), 79-96 (ECoG labeling), 164 (hemisphere detection)
- `analyze_intraop_HFO.m`: Lines 42-59 (LFP labeling), 84-101 (ECoG labeling), 169 (hemisphere detection)

**Result:**
- RCS02 (bilateral): 8 matched channel pairs ✓
- RCS03 (unilateral right): 4 matched channel pairs ✓

### HFO Scripts Unilateral Data Support (January 2026)

**Problem:**
HFO analysis scripts failed with "Unrecognized function or variable 'sidesToUse'" error because they were missing the unilateral data support added to regular scripts.

**Solution:**
- ✅ Added `sidesToUseCell` variable to `subjects_to_analyze_HFO.m` (lines 68-70)
- ✅ Added `sidesToUse = sidesToUseCell{subjNum}` to `master_script_rcs_neuroomega_HFO.m` (line 49)
- ✅ Added hemisphere filtering logic to `compare_intraop_rcs_HFO.m` (lines 3-22)
- ✅ Fixed plotting in `analyze_intraop_HFO.m` to use `chanInt` variable and `squeeze(mean(...))` (lines 263-272)

**Files Modified:**
- `subjects_to_analyze_HFO.m`: Added `sidesToUseCell = {'b'}` for RCS06
- `master_script_rcs_neuroomega_HFO.m`: Added `sidesToUse` variable extraction (line 49)
- `compare_intraop_rcs_HFO.m`: Added hemisphere filtering (lines 3-22), matches regular script logic
- `analyze_intraop_HFO.m`: Fixed plotting to use `chanInt = 7` and proper trial averaging (lines 263-272)

**Result:**
- HFO scripts now have full unilateral data support
- Plotting uses flexible `chanInt` variable instead of hardcoded indices
- Intraop HFO FOOOF completes successfully

### FOOOF Reimplementation (January 2026)

**Completed:**
- ✅ Replaced broken `fooof_mat` wrapper with FieldTrip native FOOOF
- ✅ Implemented trial-averaged FOOOF analysis for both intraop and RCS data
- ✅ Added signed rank (paired) and rank sum (unpaired) statistical tests for FOOOF parameters
- ✅ Created FOOOF parameter comparison plots with automatic test detection
- ✅ Extended FOOOF to HFO analysis scripts (analyze_intraop_HFO.m, analyze_rcs_HFO.m)
- ✅ Updated verification script (verify_fooof_results.m) for new data structure
- ✅ Simplified implementation: ~20 lines per script vs ~70 lines with broken fooof_mat

**Key Changes:**
- FOOOF uses `cfg.output = 'fooof_aperiodic'` to get 1/f component only
- Output is in **LINEAR scale** (not log), requires `log10()` for visualization
- Results stored in `.fooofparams` field with structure: `fooofparams(chanIdx).aperiodic_params`
- Aperiodic params order: `[offset, exponent]`
- Signed rank test for matched channels (by label), rank sum for all channels
- Both regular and HFO scripts have synchronized FOOOF implementation
- Quality control via R-squared values and parameter range checking

**FOOOF Visualization Added (January 8, 2026):**
- ✅ Added normalized FOOOF power spectrum plots (per-channel subplots)
- ✅ Added connected scatter plots showing exponent/offset trajectories for matched channel pairs
- ✅ Power normalized to 100% of total in fit range (4-50 Hz) for fair comparison
- ✅ Channel-specific color coding using brewermap 'Set1' palette
- ✅ Automatic generation when FOOOF data available
- ✅ **Fixed plotting (January 8, 2026):** Changed to `'fooof_aperiodic'` output mode and corrected LINEAR→log scale conversion
- ✅ **Fixed NaN handling (January 8, 2026):** Changed `sum()` to `nansum()` in normalization to handle NaN values in FOOOF spectra

**NaN Handling in FOOOF Plots:**
When FOOOF fails to fit certain frequency bins, `fooof_powspctrm` can contain NaN values. Using `sum()` on an array with NaN values returns NaN, which propagates through the normalization calculation and prevents plots from displaying. The fix uses `nansum()` instead, which excludes NaN values from the sum, allowing the normalization to work correctly on the valid frequency bins.

```matlab
% Before (causes all-NaN normalized spectrum if any NaN present):
intraopSum = sum(intraopSpectrum);
intraopNorm = 100 * intraopSpectrum / intraopSum;

% After (robust to NaN values):
intraopSum = nansum(intraopSpectrum);
intraopNorm = 100 * intraopSpectrum / intraopSum;
```

**Files Modified:**
- `analyze_intraop.m`, `analyze_rcs.m`, `analyze_intraop_HFO.m`, `analyze_rcs_HFO.m`: Changed to `'fooof_aperiodic'` output
- `compare_intraop_rcs.m`: Added ~128 lines of FOOOF visualization code (lines 298-365) with correct log scaling and NaN-robust normalization (lines 323, 335)
- `compare_intraop_rcs_HFO.m`: Added ~128 lines of FOOOF visualization code (lines 229-289) with correct log scaling and NaN-robust normalization (lines 254, 266)

### Channel Order Preservation Fix (January 2026)

**Problem:**
MATLAB's `unique()` function by default alphabetically sorts channel labels, but the original RCS device channel order needed to be preserved to ensure labels matched their corresponding data rows in the `dataRCSCell` matrix.

**Solution (Updated January 21, 2026):**
- ✅ Fixed channel label assignment in `analyze_rcs.m` and `analyze_rcs_HFO.m`
- ✅ Now using `unique()` with `'stable'` flag to preserve original order
- ✅ Simplified implementation: no indexing gymnastics required

**Technical Details:**
```matlab
% Use 'stable' flag to preserve original order
[labels, inds] = unique(chansStruct{index}, 'stable');
% labels = unique channel labels in ORIGINAL order (first occurrence)
% inds = indices into original array where each unique label first appears

labelsWithPrefix = [add ECOG/LFP + L/R prefixes to labels];

% No duplicates case (length(inds) == 4):
% Labels are already in correct order, use directly
dataRCS.label = labelsWithPrefix;

% Duplicates case (length(inds) ~= 4):
% Use inds to select first occurrence of each unique channel
tempData = dataRCSCell{index};
tempDataSub = tempData(inds,:);  % Select data rows for unique channels only
dataRCS.label = labelsWithPrefix;
dataRCS.trial = {tempDataSub};
```

**Previous Approach (Deprecated):**
```matlab
[labels, inds] = unique(chansStruct{index});  % Without 'stable'
% labels = alphabetically sorted
% Required: dataRCS.label = labelsWithPrefix(inds) to undo sorting
```

**Why This Matters:**
1. **Preserves original ordering**: `'stable'` flag returns labels in order of first occurrence, not alphabetically
   - Original RCS order: ('1-3', '0-2', '10-8', '11-9') → preserved as-is
   - Without 'stable': ('0-2', '1-3', '10-8', '11-9') → alphabetically sorted
2. **Ensures label-data correspondence**: `dataRCSCell{index}` rows are in original device order, and labels now match automatically
3. **Handles duplicates correctly**: When some channels are duplicates (e.g., same bipolar pair recorded twice), `inds` selects the first occurrence while maintaining order
4. **Simpler code**: No need for `labelsWithPrefix(inds)` indexing trick

**Files Modified:**
- `analyze_rcs.m`: Line 118 (`unique()` with 'stable'), Lines 144, 153 (simplified label assignment)
- `analyze_rcs_HFO.m`: Line 114 (`unique()` with 'stable'), Lines 121, 130 (simplified label assignment)

**Result:**
- Channel labels now correctly correspond to their data rows
- Original RCS device channel ordering is preserved automatically via `'stable'` flag
- Duplicate channel handling is robust and consistent
- Cleaner, more readable code

### Channel Matching and Permutation Testing (December 2025)

**Completed:**
- ✅ Implemented channel naming harmonization between RCS and intraoperative data
- ✅ Transitioned to channel-by-channel permutation testing (10,000 iterations)
- ✅ Implemented Bonferroni correction for multiple comparisons
- ✅ Added significance markers on individual channel plots
- ✅ Label-based channel matching (robust to ordering changes)
- ✅ Computing channel-wise effect sizes
- ✅ Region prefix detection for ECoG/LFP identification

**Bug Fixes (Dec 28, 2025):**
- ✅ Fixed `rcsOrder` cell array syntax: `{'L','R'}` instead of `[{'L'},{'R'}]`
- ✅ Fixed RCS channel name formatting: strip '+' character for proper matching
- ✅ Fixed unguarded significance star plotting in comparison scripts
- ✅ Restructured `analyze_rcs_HFO.m` to match regular analysis architecture (outer `jjj` loop)
- ✅ Fixed `rcsOrder` indexing in HFO scripts: `{jjj}` instead of `{jj}`

**Key Implementation Details:**
- `rcsOrder` variable in `subjects_to_analyze.m` specifies hemisphere ordering (proper syntax critical!)
- Channel labels follow LFPL/LFPR/ECOGL/ECOGR + contact number format
- '+' characters automatically stripped from RCS labels for matching
- Permutation test preferred over rank sum/signed rank tests for frequency bins
- Signed rank (paired) vs rank sum (unpaired) used for FOOOF parameters
- Individual channel plots with per-channel significance testing
- Both regular and HFO analysis scripts synchronized

### Comprehensive Bug Fix Pass (January 20, 2026)

**Overview:**
Systematic codebase analysis identified and fixed 47 bugs across critical, high, and moderate severity categories. See `BUG_FIXES_2026-01-20.md` for complete details.

**Critical Bugs Fixed (14):**
1. ✅ **HFO Dimension Mismatches** - Fixed 2D/3D array operations in `analyze_intraop_HFO.m` and `analyze_rcs_HFO.m`
2. ✅ **Missing `keeptrials='yes'`** - Added to HFO scripts for permutation testing
3. ✅ **Uninitialized `maxVal`** - Fixed significance marker positioning in `compare_intraop_rcs.m`
4. ✅ **Configuration Array Mismatches** - Fixed size inconsistencies in `subjects_to_analyze.m`
5. ✅ **Missing HFO Variables** - Added required variables to `subjects_to_analyze_HFO.m`
6. ✅ **RCS07 Path Error** - Fixed embedded absolute path
7. ✅ **String vs Variable Check** - Fixed `~isempty('beginRCS')` in `analyze_rcs.m`
8. ✅ **Missing Time Window Filtering** - Added to `analyze_rcs_HFO.m`
9. ✅ **Missing Iteration Selection** - Added `iterationInterestSpecific` support to HFO scripts
10. ✅ **Incorrect Data Collapse** - Fixed trial averaging in `compare_intraop_rcs_HFO.m`
11. ✅ **Permutation Test Indexing** - Fixed 3D indexing in HFO comparison
12. ✅ **Missing Variable Extractions** - Added to `master_script_rcs_neuroomega_HFO.m`

**High Severity Bugs Fixed (3):**
13. ✅ **Inconsistent Statistical Tests** - Fixed LFP using `ranksum()` instead of `signrank()` in signed rank test block
14. ✅ **Missing Error Guards** - Added `exist('statsResults','var')` checks
15. ✅ **makeNan Variable Scope** - Added `else` clause to clear variables between subjects

**Moderate Severity Bugs Fixed (3):**
16. ✅ **Unguarded Significance Star Loops** - Added bounds checking and existence guards in HFO comparison
17. ✅ **Missing FOOOF Frequency Storage** - Added `base_fre1RCSall.fooof_freq` in RCS scripts
18. ✅ **Uninitialized `statsCellPerm`** - Added initialization in master scripts

**Files Modified (10):**
- `analysis/analyze_intraop_HFO.m` - Dimension fixes
- `analysis/analyze_rcs_HFO.m` - Dimension fixes, missing functionality
- `analysis/analyze_rcs.m` - String check, FOOOF storage
- `analysis/compare_intraop_rcs.m` - maxVal, guards, consistent tests
- `analysis/compare_intraop_rcs_HFO.m` - Data collapse, indexing, guards
- `config/subjects_to_analyze.m` - Array mismatches, path error
- `config/subjects_to_analyze_HFO.m` - Missing variables
- `master_script_rcs_neuroomega.m` - makeNan scope, initialization
- `master_script_rcs_neuroomega_HFO.m` - Variable extractions, scope, initialization

**Impact:**
- ✅ HFO scripts properly handle 3D trial data
- ✅ Correct power normalization across frequencies
- ✅ Time window filtering and iteration selection work in HFO
- ✅ Significance markers display at correct positions
- ✅ No index-out-of-bounds errors
- ✅ Consistent statistical tests across ECoG and LFP
- ✅ Proper error guards for optional configurations
- ✅ No variable carryover between subjects
- ✅ Robust to variable frequency bin counts

**Detection Method:**
Systematic code exploration via specialized agents analyzing:
- Main analysis scripts (regular and HFO)
- Configuration files
- Helper functions
- Master scripts

**Remaining Issues After Session 1:**
- 1 high severity (permutest.m cell error - deferred)
- 10 moderate severity (validation, error handling)
- 17 low severity (tech debt, deprecated functions, cosmetic)

### Comprehensive Bug Fix Session 2 (January 23, 2026)

**Overview:**
Following the initial bug fix pass, a comprehensive cleanup session addressed the remaining 27 moderate and low severity bugs.

**Completed:**
- ✅ Updated TODO.md to mark channel mapping task #1 as COMPLETE
- ✅ Fixed all 10 remaining moderate severity bugs
- ✅ Fixed 11 of 17 low severity bugs
- ✅ Removed 270 lines of deprecated code
- ✅ Improved code robustness and maintainability

**Moderate Severity Bugs Fixed (10/10):**

1. **Nested Cell Array Expansion** - `compare_intraop_rcs.m`, `compare_intraop_rcs_HFO.m`
   - Fixed `{:}` expansion by wrapping in brackets for proper concatenation
   - Impact: Prevents errors when accessing nested cell arrays

2. **Channel Side Check** - `verification/verify_channel_matching.m`
   - Changed from generic `contains(label, 'L')` to specific `contains(label, {'ECOGL', 'LFPL'})`
   - Impact: Accurate hemisphere validation without false positives

3. **Index Mismatch in FOOOF Verification** - `verification/verify_fooof_results.m`
   - Fixed loop bound to use `length(fooofparams)` instead of `length(label)`
   - Impact: No index-out-of-bounds errors

4. **Missing Empty Session Validation** - `compare_intraop_rcs_HFO.m`
   - Added `iscell()` checks before cell array expansion
   - Impact: Robust handling of failed/empty sessions

5. **3D Array Indexing in Signed Rank Test** - `compare_intraop_rcs_HFO.m`
   - Created trial-averaged `base_fre1Intraop_avg` to match RCS data format
   - Impact: Correct statistical comparisons with proper dimensions

6. **Undefined Variable in Rank Sum Test** - `compare_intraop_rcs_HFO.m`
   - Changed `base_fre1RCS` to `base_fre1RCScollapse`
   - Impact: Rank sum test now functional

7. **Missing Bounds Check for P-Value Matrix** - `compare_intraop_rcs_HFO.m`
   - Added `chanIdx <= size(p, 2)` check and `min()` for loop bounds
   - Impact: No index errors when channel counts differ

8. **Empty Cell Access Error** - `compare_intraop_rcs.m`
   - Added `~isempty()` guards with warning message
   - Impact: Graceful handling of missing session data

9. **Missing FOOOF Field Check** - `compare_intraop_rcs_HFO.m`
   - Added `isfield()` checks for FOOOF parameters
   - Impact: Robust when FOOOF analysis fails

10. **Cell Array Type Error** - `helpers/permutest.m`
    - Added `iscell()` check before cell indexing
    - Impact: Correct behavior for single cluster case

**Low Severity Bugs Fixed (11/17):**

- Missing fprintf newline in `setup_rcs.m`
- Deprecated `addParamValue` → `addParameter` in `permutationTest.m`
- Division by zero protection in `stdshade.m`
- Robust path parsing in `analyze_rcs.m`
- Removed hardcoded `saveFigure` overrides in `compare_intraop_rcs.m`
- Removed unused variables in `analyze_rcs.m`
- Fixed single `&` → `&&` in `analyze_rcs_HFO.m`
- Removed 270 lines of deprecated `if false` code blocks
- Updated `stdshade.m` documentation (SEM not STD)
- Removed duplicate `freqEdgesPlot` definition in `compare_intraop_rcs_HFO.m`

**Files Modified (11):**
- `TODO.md` - Marked task #1 complete
- `analysis/compare_intraop_rcs.m` - 6 bug fixes + 270 lines removed
- `analysis/compare_intraop_rcs_HFO.m` - 6 bug fixes
- `verification/verify_channel_matching.m` - Fixed hemisphere check
- `verification/verify_fooof_results.m` - Fixed index mismatch
- `helpers/permutest.m` - Fixed cell array error
- `setup_rcs.m` - Added newline to fprintf
- `helpers/permutationTest.m` - Updated deprecated function
- `helpers/stdshade.m` - Added division protection, updated docs
- `analysis/analyze_rcs.m` - Robust path parsing, removed unused vars
- `analysis/analyze_rcs_HFO.m` - Fixed logical operator

**Remaining Low Severity Issues (6):**
- Hardcoded paths in `setup_rcs.m` (intentional - user configuration)
- Duplicate subplot layout code (requires refactoring)
- Magic number constants (requires centralization)
- Inconsistent error handling patterns
- Commented-out code cleanup
- Mixed naming conventions

**Combined Bug Fix Summary:**
- Session 1 (Jan 20): 20 bugs fixed (14 critical, 3 high, 3 moderate)
- Session 2 (Jan 23): 21 bugs fixed (10 moderate, 11 low)
- **Total: 41 of 47 bugs fixed (87%)**

## File Organization

**Root Directory:**
- `master_script_*.m`: Top-level entry points
- `setup_rcs.m`: Environment configuration

**Subdirectories:**
- `config/`: Subject configuration files (`subjects_to_analyze*.m`)
- `analysis/`: Core analysis scripts (`analyze_*.m`, `compare_*.m`)
- `helpers/`: Utility functions (`stdshade.m`, `permutationTest.m`, `permutest.m`)
- `verification/`: Quality control scripts (`verify_fooof_results.m`, `verify_channel_matching.m`)
- `tests/`: Development test scripts
- `experimental/`: Exploratory/experimental scripts
- `deprecated/`: Obsolete debugging scripts (kept for reference)

## Notes

- All data files are stored in Box cloud storage with subject folders under "Patient In-Clinic Data"
- Figures saved to OneDrive Research/RCS_project folder
- FieldTrip is used extensively for preprocessing and spectral analysis
- Analysis resamples all data to 250 Hz for consistency (1000 Hz for HFO scripts)
- Uses 2-second windows with 50% overlap for spectral estimation

## Important Implementation Details

### Permutation Testing
- Tests are performed channel-by-channel across all frequency bins
- Total tests = number of frequency bins × number of matched channel pairs
- Bonferroni threshold = 0.05 / total tests
- Results stored in `statsResultsPerm` structure with fields:
  - `.p`: p-values matrix (freqBins × channelPairs)
  - `.diff`: observed differences
  - `.effect`: effect sizes
  - `.channelPairs`: matched channel labels
  - `.bonferroniThreshold`: corrected alpha level

### Significance Marking on Plots
- **Critical**: Significance stars appear on EACH subplot independently
- Each subplot checks its own channel's p-values
- Stars centered on frequency bins: `(freqBin_start + freqBin_end) / 2`
- Only displayed when `p < bonferroniThreshold`
- Position: `maxVal - 0.15` (near top of plot)

### Channel Label Construction
**Intraoperative (analyze_intraop.m):**
```matlab
% LFP channels
chanCellIntraop{counter+1} = ['LFPL' sprintf('%d',jj-1)];  % Left: LFPL0-3
chanCellIntraop{counter+1} = ['LFPR' sprintf('%d',jj-5)];  % Right: LFPR0-3

% ECoG channels
chanCellIntraop{counter+1} = ['ECOGL' sprintf('%d',jj+7)]; % Left: ECOGL8-11
chanCellIntraop{counter+1} = ['ECOGR' sprintf('%d',jj+3)]; % Right: ECOGR8-11
```

**RCS (analyze_rcs.m):**
```matlab
sideLabel = rcsOrder{subjNum}{jjj};  % Get 'L' or 'R' (jjj = session file index)
if contains(chanLabel, {'+8','+9','+10','+11','-8','-9','-10','-11'})
    prefix = ['ECOG' sideLabel];  % ECOGL or ECOGR
else
    prefix = ['LFP' sideLabel];   % LFPL or LFPR
end
% Strip '+' character to match intraop naming convention
chanLabel = strrep(chanLabel, '+', '');
labelsWithPrefix{labelIdx} = [prefix chanLabel];  % e.g., "ECOGL10-8"
```

### rcsOrder Variable
**CRITICAL SYNTAX:**
```matlab
rcsOrder = {
    {'L','R'},   % Subject 1: Two sessions (L, then R)
    {'R'}        % Subject 2: One session (R only)
};
```

**INCORRECT SYNTAX (will cause both to be 'L'):**
```matlab
rcsOrder = {
    [{'L'},{'R'}],   % WRONG! Square brackets cause issues
    [{'R'}]          % WRONG!
};
```

**Details:**
- Cell array indexed by subject number, then session number
- Each entry must be a single character: 'L' or 'R'
- `rcsOrder{1}{1}` returns `'L'`, `rcsOrder{1}{2}` returns `'R'`
- Must be defined in both `subjects_to_analyze.m` and `subjects_to_analyze_HFO.m`

## Troubleshooting

### "No matching intraop channel found"
**Causes:**
1. Incorrect `rcsOrder` syntax (using `[{'L'},{'R'}]` instead of `{'L','R'}`)
2. Wrong hemisphere ordering (L/R swapped)
3. '+' character not being stripped from RCS labels
4. Incorrect `sidesToUseCell` value for unilateral data

**Solutions:**
- Verify `rcsOrder` uses correct syntax: `{'L','R'}` NOT `[{'L'},{'R'}]`
- Check `rcsOrder{subjNum}{sessionNum}` returns single char 'L' or 'R'
- Confirm '+' stripping code exists: `chanLabel = strrep(chanLabel, '+', '')` (line 138 in analyze_rcs.m)
- **For unilateral data**: Set `sidesToUseCell{subjNum}` to 'l' or 'r' (not 'b')
  - Example: RCS03 has right-only data, so `sidesToUseCell{2} = 'r'`
- Verify bipolar skip rereferencing produces expected labels (LFPL2-0, ECOGL10-8, etc.)

### Unexpected significance results
- Verify Bonferroni threshold calculation: `0.05 / (numFreqBins × numChannelPairs)`
- Check that channel matching found expected number of pairs
- Confirm permutation test ran for all matched channels
- Ensure significance plotting is guarded by test flags (`if permute_test`, `if rankSumTest || signedRankTest`)

### Misaligned plots
- Ensure channel matching used `strcmp()` on labels, not position indexing
- Verify RCS and intraop labels match exactly (case-sensitive)
- Check that `find(strcmp(...))` returned non-empty indices
- Confirm '+' character was stripped from RCS labels

### HFO analysis errors
**Symptom:** Index errors or mismatched rcsOrder indexing
**Causes:**
- `analyze_rcs_HFO.m` not using outer `jjj` loop
- `rcsOrder` indexed with wrong variable (`{jj}` instead of `{jjj}`)
- `rcsFiles` not using nested cell array structure

**Solutions:**
- Verify `analyze_rcs_HFO.m` has `for jjj = 1:length(pathDataRcs)` at line 8
- Confirm `rcsOrder` accessed as `rcsOrder{subjNum}{jjj}` (line 102)
- Check `rcsFiles` uses nested structure: `{{path1, path2, ...}}`
