# RCS Intraoperative vs. Clinic Comparison Analysis

MATLAB codebase for analyzing and comparing intraoperative (NeuroOmega) vs. clinic-recorded (RC+S) electrophysiology data from Parkinson's disease patients. This repository implements channel-by-channel permutation testing with Bonferroni correction to statistically compare ECoG (electrocorticography) and LFP (local field potential) recordings between the two recording systems.

## Overview

This analysis pipeline processes and compares:
- **Intraoperative data**: NeuroOmega recordings during DBS surgery
- **Clinic data**: Medtronic Summit RC+S recordings from chronic implanted devices

The codebase harmonizes channel naming conventions between the two systems, performs spectral analysis across multiple frequency bands (theta, alpha, beta, gamma, HFO), and uses non-parametric permutation testing to identify statistically significant differences between recording contexts.

## Key Features

- **Harmonized Channel Naming**: RCS and intraoperative data use identical ECOGL/ECOGR/LFPL/LFPR naming conventions
- **Channel-by-Channel Permutation Testing**: 10,000 permutations per channel-frequency bin pair
- **Bonferroni Correction**: Proper multiple comparison correction across all tests
- **Automated Label Matching**: Robust channel matching using `strcmp()` instead of position-based indexing
- **Bipolar Skip Rereferencing**: Matches RC+S recording montages
- **Individual Channel Visualization**: Significance stars on each subplot for Bonferroni-corrected results
- **HFO Analysis**: High-frequency oscillation analysis (250-350 Hz) in addition to standard bands
- **FOOOF Spectral Parameterization**: FieldTrip native implementation for aperiodic (1/f) analysis

## Data Storage

All patient data files are stored in **Box cloud storage** under the following structure:

```
Box/
├── Patient In-Clinic Data/
│   ├── RCS02/
│   │   ├── v01_or_day/
│   │   │   ├── NeuroOmega/analyzed/
│   │   │   └── rcsData/
│   │   └── v02_postop/montage/
│   ├── RCS03/
│   │   └── study_visits/
│   ├── RCS04/
│   ├── RCS05/
│   ├── RCS06/
│   ├── RCS07/
│   ├── RCS08/
│   └── RCS09/
└── RCS_500_1000_hz_rest_data/
    └── for_David/
        ├── Highsr_sessions_RCSpatients_L.mat
        └── Highsr_sessions_RCSpatients_R.mat
```

**Environment Variables Required:**
- `box_dir`: Path to Box sync folder
- `onedrive_dir`: Path to OneDrive (for figure output)
- `dropbox`: Path to Dropbox (for some RCS06 HFO data)

Set these in your shell configuration (e.g., `.bashrc`, `.zshrc`) or MATLAB startup.

## Dependencies

### Required MATLAB Toolboxes and External Libraries

1. **FieldTrip Toolbox** (required)
   - Expected location: `../fieldtrip/` (sibling directory)
   - Download: https://www.fieldtriptoolbox.org/
   - Used for: Preprocessing, spectral analysis, trial segmentation, FOOOF parameterization
   - **Must have Brainstorm support** for FOOOF (included in recent versions)
   - Verify with: `ft_hastoolbox('brainstorm')`

2. **Analysis-rcs-data Repository** (required)
   - Expected location: `../Analysis-rcs-data/` (sibling directory)
   - Contains `ProcessRCS` function for reading RC+S data files
   - Repository: https://github.com/openmind-consortium/Analysis-rcs-data

3. **brewermap** (required)
   - Expected location: `../fieldtrip/external/brewermap/`
   - Used for: Color scheme generation
   - Usually included with FieldTrip

4. **fooof_mat** (NO LONGER REQUIRED)
   - Previous FOOOF wrapper implementation has been replaced
   - Now uses FieldTrip's native FOOOF support via Brainstorm

### Installation

1. Clone this repository:
   ```bash
   git clone https://github.com/[username]/rcs_code.git
   cd rcs_code
   ```

2. Clone dependencies as sibling directories:
   ```bash
   cd ..
   git clone https://github.com/fieldtrip/fieldtrip.git
   git clone https://github.com/openmind-consortium/Analysis-rcs-data.git
   ```

3. Set up environment variables in your shell:
   ```bash
   export box_dir="/path/to/Box"
   export onedrive_dir="/path/to/OneDrive"
   export dropbox="/path/to/Dropbox"
   ```

4. Update paths in `setup_rcs.m` (lines 7-9) to match your local environment:
   ```matlab
   boxPath = getenv('box_dir');
   oneDrivePath = getenv('onedrive_dir');
   dropboxPath = getenv('dropbox');
   ```

## Workflow

### Standard Analysis Pipeline

```matlab
% Run complete analysis pipeline for all subjects
master_script_rcs_neuroomega
```

**Pipeline Steps:**

1. **`setup_rcs.m`**: Configure environment
   - Resets MATLAB path
   - Sets environment variables
   - Adds paths to Analysis-rcs-data and FieldTrip

2. **`subjects_to_analyze.m`**: Define analysis parameters
   - Subject IDs and data file paths
   - Time windows and re-referencing schemes
   - Channel ordering (`rcsOrder` variable)
   - Data quality exclusions

3. **`analyze_intraop.m`**: Process intraoperative data
   - Load NeuroOmega `.mat` files
   - Apply manual artifact exclusions
   - Bipolar skip rereferencing
   - Resample to 250 Hz
   - Create 2-second trials (50% overlap)
   - Compute power spectral density (Hanning taper FFT)
   - Normalize power (percentage of 4-125 Hz total)
   - Bin into frequency bands
   - Output: `base_fre1Intraop` structure

4. **`analyze_rcs.m`**: Process RC+S data
   - Call `ProcessRCS` to read device files
   - Filter to specified time windows
   - Handle multiple recording iterations
   - Convert to FieldTrip format with region prefixes
   - **Preserve original device channel ordering** (undo alphabetical sorting from `unique()`)
   - Same spectral analysis as intraop
   - Output: `base_fre1RCSall` cell structure

5. **`compare_intraop_rcs.m`**: Statistical comparison
   - Match channels by label (strcmp)
   - Channel-by-channel permutation testing (10,000 iterations)
   - Calculate Bonferroni threshold
   - Generate comparison plots with significance stars
   - Output: `statsResultsPerm` structure

### HFO Analysis Pipeline

```matlab
% Run HFO-focused analysis (includes 250-350 Hz band)
master_script_rcs_neuroomega_HFO
```

Uses HFO-specific versions: `subjects_to_analyze_HFO.m`, `analyze_intraop_HFO.m`, `analyze_rcs_HFO.m`, `compare_intraop_rcs_HFO.m`.

### Channel Naming Convention

**Intraoperative Data:**
- LFP channels: `LFPL0`, `LFPL1`, `LFPL2`, `LFPL3` (left); `LFPR0`, `LFPR1`, `LFPR2`, `LFPR3` (right)
- ECoG channels: `ECOGL8`, `ECOGL9`, `ECOGL10`, `ECOGL11` (left); `ECOGR8`, `ECOGR9`, `ECOGR10`, `ECOGR11` (right)
- After bipolar skip rereferencing: `LFPL2-0`, `LFPL3-1`, `ECOGL10-8`, `ECOGL11-9`, etc.

**RCS Data:**
- Same naming with original contact notation appended ('+' character is automatically stripped)
- Examples: `ECOGL10-8` (left ECoG, contacts 10-8), `LFPR2-0` (right LFP, contacts 2-0)
- Raw channel names from device may include '+' but are cleaned during processing
- **Original device channel ordering is preserved** using `unique()` indices to ensure labels match data rows

### Frequency Bands

**Standard Analysis:**
1. Theta: 4-8 Hz
2. Alpha: 8-12 Hz
3. Low Beta: 13-20 Hz
4. High Beta: 20-30 Hz
5. Broadband Gamma: 50-125 Hz

**HFO Analysis (adds):**
6. HFO: 250-350 Hz

### Statistical Testing

**Permutation Test (Preferred Method):**
- Non-parametric permutation test
- 10,000 iterations per channel-frequency bin pair
- Output: p-value, observed difference, effect size
- Bonferroni correction: `alpha = 0.05 / (numFreqBins × numMatchedPairs)`
- Significance markers plotted on individual channel subplots

**Legacy Methods (disabled by default):**
- Signed rank test (`signedRankTest = 0`)
- Rank sum test (`rankSumTest = 0`)

### FOOOF Spectral Parameterization

**Purpose:**
FOOOF (Fitting Oscillations & One-Over-F) separates aperiodic (1/f) noise from periodic oscillatory peaks in power spectra. This enables quantification of neural noise characteristics beyond traditional frequency band analysis.

**Implementation:**
- Uses FieldTrip's native FOOOF via Brainstorm (no external wrapper needed)
- Runs on trial-averaged data after regular spectral analysis
- Fits 4-50 Hz range with 'fixed' aperiodic mode (offset + exponent)
- Uses `'fooof_aperiodic'` output mode to extract only the 1/f component
- **Output is in LINEAR scale** - use `log10()` for visualization
- Automatically applied in all analysis scripts (intraop, RCS, HFO)

**Output Parameters:**
- **Exponent** (typically 1-3): Steepness of 1/f falloff
  - Higher = steeper falloff = more neural noise
  - Lower = flatter spectrum = less noise-dominated
- **Offset**: Overall power level (log scale)
- **R-squared**: Fit quality (>0.8 is good)
- **Peak Parameters**: Center frequency, power, bandwidth for detected oscillations

**Visualization:**
1. **FOOOF Modeled Spectra** - Per-channel subplots showing aperiodic (1/f) component
   - Blue = RCS, Red = Intraop
   - Power normalized to 100% and plotted on log scale
   - Downward-sloping lines (steeper = larger exponent)
2. **Connected Scatter Plots** - Exponent and offset values for each matched channel pair
   - Lines connect intraop → RCS values
   - Color-coded by channel

**Statistical Comparison:**
- **Signed Rank Test** (if enabled): Paired comparison for matched channels
- **Rank Sum Test** (if enabled): Unpaired comparison across all channels
- Results plotted with p-values and error bars
- Quality verification via `verify_fooof_results.m`

**Data Structure:**
```matlab
% Intraoperative FOOOF
base_fre1Intraop.fooofparams(chanIdx).aperiodic_params  % [offset, exponent]
base_fre1Intraop.fooofparams(chanIdx).r_squared
base_fre1Intraop.fooof_powspctrm                        % Aperiodic spectrum (LINEAR scale)
base_fre1Intraop.fooof_freq                             % Frequency vector (4:0.5:50)

% RCS FOOOF (nested by session/iteration)
base_fre1RCSall.fooofparams{sessionIdx}{iterIdx}(chanIdx).aperiodic_params
base_fre1RCSall.fooof_powspctrm{sessionIdx}{iterIdx}   % Modeled power spectrum
```

**FOOOF Visualization Plots:**

Two types of summary plots are automatically generated in comparison scripts:

1. **FOOOF Modeled Power Spectrum Plots**:
   - Individual subplots per matched channel pair (2x2 for 4 channels, 4x2 for 8 channels)
   - Blue line = RCS, Red line = Intraop
   - Power normalized to 100% of total in fit range (4-50 Hz)
   - Shows log-scaled normalized power on y-axis
   - Files: `{subj}_FOOOF_spectra.png/.eps` or `{subj}_FOOOF_spectra_HFO.png/.eps`

2. **Connected Scatter Plots (Exponent/Offset)**:
   - Side-by-side subplots showing exponent (left) and offset (right)
   - Each matched channel pair connected by line (intraop → RCS)
   - Color-coded by channel using distinct colors
   - P-values from signed rank test in subplot titles
   - Files: `{subj}_FOOOF_scatter.png/.eps` or `{subj}_FOOOF_scatter_HFO.png/.eps`

**Requirements:**
- Spectrum plots require FOOOF power spectrum data
- Scatter plots require signed rank test enabled (`signedRankTest = 1`)
- Both respect `saveFigure` flag

## File Organization

```
rcs_code/
├── master_script_rcs_neuroomega.m          # Main execution script
├── master_script_rcs_neuroomega_HFO.m      # HFO execution script
├── setup_rcs.m                              # Environment setup
├── CLAUDE.md                                # AI assistant guidance
├── progress.md                              # Development progress and changelog
├── README.md                                # This file
│
├── config/                                  # Subject and data configuration
│   ├── subjects_to_analyze.m                # Subject IDs, file paths, parameters
│   └── subjects_to_analyze_HFO.m            # HFO-specific configuration
│
├── analysis/                                # Core analysis scripts
│   ├── analyze_intraop.m                    # Intraop data processing (with FOOOF)
│   ├── analyze_intraop_HFO.m                # HFO intraop processing (with FOOOF)
│   ├── analyze_rcs.m                        # RCS data processing (with FOOOF)
│   ├── analyze_rcs_HFO.m                    # HFO RCS processing (with FOOOF)
│   ├── compare_intraop_rcs.m                # Statistical comparison (with FOOOF tests)
│   └── compare_intraop_rcs_HFO.m            # HFO comparison (with FOOOF tests)
│
├── helpers/                                 # Utility functions
│   ├── stdshade.m                           # Mean ± SEM plotting
│   ├── permutationTest.m                    # Permutation test implementation
│   └── permutest.m                          # Alternative permutation test
│
├── verification/                            # Quality control scripts
│   ├── verify_fooof_results.m               # FOOOF output validation
│   └── verify_channel_matching.m            # Channel naming verification
│
├── tests/                                   # Development test scripts
│   ├── test_single_subject_fooof.m          # End-to-end FOOOF test
│   └── test_fooof_plotting.m                # Plotting code tests
│
├── experimental/                            # Exploratory scripts
│   ├── test_ft_crossfrequencyanalysis.m     # Cross-frequency coupling analysis
│   └── exploreRCSgui.m                      # Interactive data exploration GUI
│
└── deprecated/                              # Obsolete debugging scripts
    └── (7 superseded debug scripts)
```

## Usage Examples

### Run Complete Analysis
```matlab
% Run standard analysis for all subjects
master_script_rcs_neuroomega

% Run HFO analysis for all subjects
master_script_rcs_neuroomega_HFO
```

### Analyze Single Subject
```matlab
setup_rcs
subjects_to_analyze

% Select single subject
subjNum = 1;
pathDataIntraOp = intraOpFiles{subjNum};
pathDataRcs = rcsFiles{subjNum};
subj = subjsToAnalyze{subjNum};

% Run analysis pipeline
analyze_intraop
analyze_rcs
compare_intraop_rcs
```

### Access Statistical Results
```matlab
% After running master_script_rcs_neuroomega:
% statsCell contains statsResultsPerm for each subject

% Example: Get results for subject 1
subjResults = statsCell{1};

% View p-values (freqBins × channelPairs)
subjResults.p

% View channel pairs
subjResults.channelPairs

% View Bonferroni threshold
subjResults.bonferroniThreshold

% Find significant results
[sigFreqBins, sigChannels] = find(subjResults.p < subjResults.bonferroniThreshold);
```

## Troubleshooting

### Issue: No matching channels found
**Symptom:** Warning message "No matching intraop channel found for RCS channel: ..."

**Solutions:**
1. Verify `rcsOrder` is correctly defined in `subjects_to_analyze.m`:
   - Use proper cell array syntax: `{'L','R'}` NOT `[{'L'},{'R'}]`
   - Index: `rcsOrder{subjNum}{sessionNum}` should return 'L' or 'R'
2. Ensure RCS channel names have '+' character stripped (done automatically in `analyze_rcs.m` line 138)
3. Verify hemisphere ordering matches actual data files
4. **For unilateral data**: Ensure `sidesToUseCell{subjNum}` is set correctly:
   - Use `'r'` for right-hemisphere-only data
   - Use `'l'` for left-hemisphere-only data
   - Use `'b'` for bilateral data (default)
   - Example: `sidesToUseCell = {'b', 'r'}` for RCS02 (bilateral) and RCS03 (right only)

### Issue: Too many/few significance stars
**Symptom:** Unexpected number of significant results

**Solution:** Check Bonferroni threshold calculation. Verify `numTests` equals `numFreqBins × numMatchedPairs`.

### Issue: Misaligned channel plots
**Symptom:** RCS and intraop data don't match visually

**Solution:** Confirm channel matching logic in plotting sections. Check label construction in `analyze_rcs.m` region prefix code.

### Issue: Array indexing errors in permutation test
**Symptom:** MATLAB indexing errors during permutation loop

**Solution:** Verify data dimensions match expected structure: `trials × channels × freqBins`

### Issue: Significance stars appear even when tests not run
**Symptom:** Stars plotted on figures when statistical test flags are disabled

**Solution:** Fixed in `compare_intraop_rcs.m` lines 184 and 205. Significance plotting now guarded by `if rankSumTest || signedRankTest` checks.

## Recent Updates

### Channel Order Preservation Fix (January 21, 2026)

**Issue:** MATLAB's `unique()` function by default alphabetically sorts channel labels, but the original RCS device channel order needed to be preserved to ensure labels matched their corresponding data rows.

**Fix:**
- Updated `analyze_rcs.m` and `analyze_rcs_HFO.m` to use `unique()` with `'stable'` flag
- The `'stable'` flag preserves original order (first occurrence) instead of alphabetically sorting
- Simplified implementation: labels can be used directly without indexing gymnastics

**Technical Details:**
```matlab
% New approach with 'stable' flag:
[labels, inds] = unique(chansStruct{index}, 'stable');
% labels = already in original order
dataRCS.label = labelsWithPrefix;  % Direct assignment

% Previous approach (deprecated):
[labels, inds] = unique(chansStruct{index});  % Alphabetically sorted
dataRCS.label = labelsWithPrefix(inds);  % Required indexing to undo sorting
```

**Files Modified:**
- `analyze_rcs.m`: Line 118 (`unique()` with 'stable'), Lines 144, 153 (simplified assignment)
- `analyze_rcs_HFO.m`: Line 114 (`unique()` with 'stable'), Lines 121, 130 (simplified assignment)

**Impact:**
- Channel labels now correctly match their data rows automatically
- Original RCS device channel ordering is maintained via `'stable'` flag
- Robust handling of duplicate channels (selects first occurrence in original order)
- Cleaner, more readable code

### Unilateral Data Support (January 7, 2026)

**Issue:** Unilateral (single-hemisphere) intraoperative recordings always labeled as LEFT, causing channel matching failures for right-hemisphere-only subjects.

**Fix:**
- Added `sidesToUse` parameter logic to `analyze_intraop.m` and `analyze_intraop_HFO.m`
- Channel labeling now respects `sidesToUseCell` configuration ('b', 'l', or 'r')
- Fixed hemisphere detection to use `contains(label,'LFPL')` instead of `contains(label,'L')`

**Files Modified:**
- `analyze_intraop.m`: Channel labeling (lines 37-96), hemisphere detection (line 164)
- `analyze_intraop_HFO.m`: Channel labeling (lines 42-101), hemisphere detection (line 169)

**Verification:**
- RCS02 (bilateral): 8 matched channel pairs, Bonferroni α = 0.00125
- RCS03 (right only): 4 matched channel pairs, Bonferroni α = 0.00250

### HFO Scripts Unilateral Data Support (January 2026)

**Issue:** HFO analysis scripts failed with "Unrecognized function or variable 'sidesToUse'" error.

**Fix:**
- Added `sidesToUseCell` to `subjects_to_analyze_HFO.m`
- Added `sidesToUse` variable extraction to `master_script_rcs_neuroomega_HFO.m`
- Added hemisphere filtering logic to `compare_intraop_rcs_HFO.m`
- Fixed plotting in `analyze_intraop_HFO.m` to use `chanInt` variable and `squeeze(mean(...))`

**Files Modified:**
- `subjects_to_analyze_HFO.m`: Added `sidesToUseCell = {'b'}` (lines 68-70)
- `master_script_rcs_neuroomega_HFO.m`: Added `sidesToUse = sidesToUseCell{subjNum}` (line 49)
- `compare_intraop_rcs_HFO.m`: Added hemisphere filtering (lines 3-22)
- `analyze_intraop_HFO.m`: Fixed plotting with `chanInt = 7` and proper trial averaging (lines 263-272)

### FOOOF Reimplementation (January 2026)

**Major Update:** Replaced broken `fooof_mat` wrapper with FieldTrip's native FOOOF implementation

**Changes:**
- **Removed dependency**: `fooof_mat` no longer required
- **Simplified implementation**: ~20 lines per script vs ~70 lines with broken wrapper
- **FieldTrip integration**: Uses `cfg.output = 'fooof_aperiodic'` with Brainstorm backend to extract 1/f component
- **LINEAR scale output**: All FOOOF outputs are in linear power scale (use `log10()` for visualization)
- **Trial-averaged analysis**: FOOOF runs separately on averaged data
- **New data structure**: Results in `.fooofparams` with `aperiodic_params` [offset, exponent]
- **Statistical tests**: Both signed rank (paired) and rank sum (unpaired) for FOOOF parameters
- **Quality control**: `verify_fooof_results.m` for R-squared and parameter range checking
- **HFO scripts updated**: Both regular and HFO analysis have synchronized FOOOF

**Files Modified:**
- `setup_rcs.m`: Removed fooof_mat path
- `analyze_intraop.m`, `analyze_rcs.m`, `analyze_intraop_HFO.m`, `analyze_rcs_HFO.m`: Added FieldTrip FOOOF with `'fooof_aperiodic'` output
- `compare_intraop_rcs.m`, `compare_intraop_rcs_HFO.m`: Added signed rank and rank sum FOOOF tests
- `verify_fooof_results.m`: Updated for new `.fooofparams` structure

**FOOOF Visualization Added (January 8, 2026):**
- **New plots**: FOOOF aperiodic spectrum plots (per-channel) and connected scatter plots (exponent/offset trajectories)
- **Data handling**: LINEAR scale data normalized to 100%, then converted to log scale via `log10()` for visualization
- **Normalization**: Power normalized to 100% of total in fit range (4-50 Hz) for fair comparison
- **Color coding**: Channel-specific colors using brewermap 'Set1' palette
- **Automatic generation**: Plots created when FOOOF data available and `saveFigure = 1`
- **Files modified**: `compare_intraop_rcs.m` (lines 298-365), `compare_intraop_rcs_HFO.m` (lines 229-289)
- **Fix applied**: Corrected LINEAR→log scale conversion to properly display aperiodic spectra

### Channel Matching and Permutation Testing (December 2025)

See [progress.md](progress.md) for detailed changelog including:

**Bug Fixes:**
- Fixed `rcsOrder` cell array syntax in subject configuration files
- Fixed RCS channel name formatting ('+' character stripping for proper matching)
- Fixed unguarded significance star plotting in comparison scripts
- Restructured HFO analysis to match regular analysis architecture
- Fixed individual channel plotting to use proper 3D data indexing
- Updated `stdshade.m` helper function to plot SEM (standard error) instead of SD

**Features:**
- Channel naming harmonization between RCS and intraoperative data
- Channel-by-channel permutation testing (10,000 iterations)
- Bonferroni correction for multiple comparisons
- Individual channel significance marking on plots
- Label-based channel matching (robust to ordering changes)

### Comprehensive Bug Fix Pass (January 20, 2026)

**Major Update:** Systematic analysis identified and fixed **20 bugs** across critical, high, and moderate severity categories.

**Summary:**
- 47 total bugs identified via automated code exploration
- 14/14 critical bugs fixed (100%)
- 3/4 high severity bugs fixed (75%)
- 3/13 moderate severity bugs fixed (23%)
- 17 low severity issues documented (tech debt)

**Critical Bugs Fixed:**
1. **HFO Dimension Mismatches** - Fixed 2D/3D array operations in normalization and frequency binning
2. **Missing `keeptrials='yes'`** - Added to HFO scripts for proper permutation testing
3. **Uninitialized Variables** - Fixed `maxVal` causing misplaced significance markers
4. **Configuration Array Mismatches** - Fixed size inconsistencies in subject configuration
5. **Missing HFO Functionality** - Added time window filtering and iteration selection support
6. **Data Processing Errors** - Fixed data collapse and permutation test indexing in HFO comparison

**High/Moderate Bugs Fixed:**
7. **Inconsistent Statistical Tests** - Fixed LFP channels using wrong test type (ranksum vs signrank)
8. **Missing Error Guards** - Added existence checks for optional statistical test results
9. **Variable Scope Issues** - Fixed artifact exclusion regions carrying over between subjects
10. **Hardcoded Assumptions** - Made significance star loops robust to variable frequency bin counts
11. **Data Structure Completeness** - Added missing FOOOF frequency vector storage
12. **Uninitialized Cell Arrays** - Added initialization for permutation test result storage

**Files Modified (10):**
- All analysis scripts (regular and HFO versions)
- Both configuration files
- Both master scripts

**Impact:**
- ✅ HFO analysis now produces correct results
- ✅ Proper 3D data handling throughout
- ✅ Consistent statistical tests across all channels
- ✅ Robust error handling for optional configurations
- ✅ No variable carryover between subjects
- ✅ Handles variable frequency bin counts

**Documentation:**
- Complete bug analysis: `BUG_FIXES_2026-01-20.md`
- Updated development guide: `CLAUDE.md`
- Before/after code examples for all fixes
- Verification procedures and testing recommendations

**Verification:**
```matlab
% Verify fixes by running full pipeline
master_script_rcs_neuroomega      % Regular analysis
master_script_rcs_neuroomega_HFO  % HFO analysis

% Check channel matching
verification/verify_channel_matching.m

% Check FOOOF quality
verification/verify_fooof_results.m
```

## Contributing

This is a research codebase developed for specific analysis needs. For questions or collaboration inquiries, please contact the repository owner.

## Citation

If you use this code in your research, please cite:

```
pending
```

## License

BSD 3-Clause License

Copyright (c) 2025, David Caldwell, UCSF
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its
   contributors may be used to endorse or promote products derived from
   this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

## Contact

David Caldwell
University of California, San Francisco
GitHub: https://github.com/[davidjuliancaldwell]/rcs_code