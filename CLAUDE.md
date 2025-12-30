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
- **Analysis-rcs-data**: Expected at `../Analysis-rcs-data/` - contains the `ProcessRCS` function for reading RC+S data files
- **brewermap**: Color scheme library, expected at `../fieldtrip/external/brewermap/`

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
   - **NEW**: `rcsOrder` variable specifies L/R hemisphere ordering for each RCS session
   - Returns cell arrays: `subjsToAnalyze`, `intraOpFiles`, `rcsFiles`, `timeStampStart/Stop`, `rerefCell`, `sidesToUseCell`, `makeNan`, `rcsOrder`

2. **Intraoperative Data Processing** (`analyze_intraop.m`):
   - Loads `.mat` files with `ecog.contact` and `lfp.contact` structures
   - Applies manual data quality exclusions (NaN-ing bad segments via `makeNan` ranges)
   - **NEW**: Labels channels with standardized naming:
     - LFP: LFPL0-3, LFPR0-3 (numbered 0-3 to match RCS convention)
     - ECoG: ECOGL8-11, ECOGR8-11 (numbered 8-11 to match RCS convention)
   - Re-references using either bipolar or bipolar-skip montages
     - **Bipolar skip montage labels**: LFPL2-0, LFPL3-1, ECOGL10-8, ECOGL11-9 (and R equivalents)
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
   - Handles duplicate channels (keeps unique ones only)
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

**Channel Matching:**
- Comparison scripts use `strcmp()` to match channels by label
- No longer relies on position-based indexing
- Robust to different channel orderings and missing channels
- RCS channels matched to intraop channels with identical labels

### Re-referencing Options

Two schemes available (set in `rerefCell`):
- `bipolarReref`: Sequential bipolar (channel N - channel N+1)
- `bipolarSkipReref`: Skip bipolar (channel N - channel N+2) - **preferred for matching RC+S recording montages**

### Data Quality

- Manual artifact exclusion via `makeNan` cell array in `subjects_to_analyze.m`
- Trials with any NaN values are excluded from spectral analysis
- **Recent work**: "manual inspection to ignore NaN parts", "working on saving individual power trials for perm test"

## Patient Configuration Files

Located in `patient_config_files/RCS##/patient_config_file.m`. Currently minimal - mostly empty except for basic sampling rate extraction. Previously used for channel definitions but now largely unused.

## Helper Functions

- `stdshade.m`: Plots mean ± shaded SEM (standard error of mean) region
  - **Updated**: Now plots SEM instead of SD (standard deviation)
  - Called with transposed data: `stdshade(log10(squeeze(data(:,channelIdx,:)))', alpha, color)`
- `permutationTest.m`: Implements permutation testing with effect size calculation
- `permutest.m`: Alternative permutation test implementation

## Recent Development Focus (UPDATED December 28, 2025)

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

**Key Changes:**
- `rcsOrder` variable in `subjects_to_analyze.m` specifies hemisphere ordering (proper syntax critical!)
- Channel labels follow LFPL/LFPR/ECOGL/ECOGR + contact number format
- '+' characters automatically stripped from RCS labels for matching
- Permutation test preferred over rank sum/signed rank tests
- Individual channel plots with per-channel significance testing
- Both regular and HFO analysis scripts synchronized

## File Organization

- `master_script_*.m`: Top-level entry points
- `subjects_to_analyze*.m`: Data file and parameter configuration
- `analyze_*.m`: Data processing pipelines
- `compare_*.m`: Statistical analysis and plotting
- `setup_rcs.m`: Environment configuration
- `patient_config_files/`: Per-subject configurations
- `helpers/`: Utility functions

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

**Solutions:**
- Verify `rcsOrder` uses correct syntax: `{'L','R'}` NOT `[{'L'},{'R'}]`
- Check `rcsOrder{subjNum}{sessionNum}` returns single char 'L' or 'R'
- Confirm '+' stripping code exists: `chanLabel = strrep(chanLabel, '+', '')` (line 138 in analyze_rcs.m)
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
