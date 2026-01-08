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
- Fits 1-50 Hz range with 'fixed' aperiodic mode (offset + exponent)
- Automatically applied in all analysis scripts (intraop, RCS, HFO)

**Output Parameters:**
- **Exponent** (typically 1-3): Steepness of 1/f falloff
  - Higher = steeper falloff = more neural noise
  - Lower = flatter spectrum = less noise-dominated
- **Offset**: Overall power level (log scale)
- **R-squared**: Fit quality (>0.8 is good)
- **Peak Parameters**: Center frequency, power, bandwidth for detected oscillations

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

% RCS FOOOF (nested by session/iteration)
base_fre1RCSall.fooofparams{sessionIdx}{iterIdx}(chanIdx).aperiodic_params
```

## File Organization

```
rcs_code/
├── master_script_rcs_neuroomega.m          # Main execution script
├── master_script_rcs_neuroomega_HFO.m      # HFO execution script
├── subjects_to_analyze.m                    # Data file configuration
├── subjects_to_analyze_HFO.m                # HFO configuration
├── analyze_intraop.m                        # Intraop data processing (with FOOOF)
├── analyze_intraop_HFO.m                    # HFO intraop processing (with FOOOF)
├── analyze_rcs.m                            # RCS data processing (with FOOOF)
├── analyze_rcs_HFO.m                        # HFO RCS processing (with FOOOF)
├── compare_intraop_rcs.m                    # Statistical comparison (with FOOOF tests)
├── compare_intraop_rcs_HFO.m                # HFO comparison (with FOOOF tests)
├── verify_fooof_results.m                   # FOOOF quality control diagnostic
├── verify_channel_matching.m                # Channel naming diagnostic
├── setup_rcs.m                              # Environment setup
├── helpers/
│   ├── stdshade.m                           # Mean ± SEM plotting (updated to plot SEM not SD)
│   ├── permutationTest.m                    # Permutation test implementation
│   └── permutest.m                          # Alternative permutation test
├── patient_config_files/
│   └── RCS##/patient_config_file.m          # Per-subject configs
├── CLAUDE.md                                # AI assistant guidance
├── CHANGES_SUMMARY.md                       # Detailed changelog
└── README.md                                # This file
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

### Channel Order Preservation Fix (January 7, 2026)

**Issue:** MATLAB's `unique()` function alphabetically sorts channel labels, but the original RCS device channel order needed to be preserved to ensure labels matched their corresponding data rows.

**Fix:**
- Updated `analyze_rcs.m` and `analyze_rcs_HFO.m` to use `labelsWithPrefix(inds)` instead of `labelsWithPrefix`
- The `inds` output from `unique()` restores original (pre-sorted) channel ordering
- Ensures channel labels always correspond to their data rows in the FieldTrip structure

**Files Modified:**
- `analyze_rcs.m`: Lines 144, 153 (channel label assignment)
- `analyze_rcs_HFO.m`: Lines 121, 130 (channel label assignment)

**Impact:**
- Channel labels now correctly match their data rows
- Original RCS device channel ordering is maintained
- Robust handling of duplicate channels (selects first occurrence in original order)

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

### FOOOF Reimplementation (January 2026)

**Major Update:** Replaced broken `fooof_mat` wrapper with FieldTrip's native FOOOF implementation

**Changes:**
- **Removed dependency**: `fooof_mat` no longer required
- **Simplified implementation**: ~20 lines per script vs ~70 lines with broken wrapper
- **FieldTrip integration**: Uses `cfg.output = 'fooof_aperiodic'` with Brainstorm backend
- **Trial-averaged analysis**: FOOOF runs separately on averaged data
- **New data structure**: Results in `.fooofparams` with `aperiodic_params` [offset, exponent]
- **Statistical tests**: Both signed rank (paired) and rank sum (unpaired) for FOOOF parameters
- **Quality control**: `verify_fooof_results.m` for R-squared and parameter range checking
- **HFO scripts updated**: Both regular and HFO analysis have synchronized FOOOF

**Files Modified:**
- `setup_rcs.m`: Removed fooof_mat path
- `analyze_intraop.m`, `analyze_rcs.m`: Added FieldTrip FOOOF
- `analyze_intraop_HFO.m`, `analyze_rcs_HFO.m`: Added FieldTrip FOOOF
- `compare_intraop_rcs.m`, `compare_intraop_rcs_HFO.m`: Added signed rank and rank sum FOOOF tests
- `verify_fooof_results.m`: Updated for new `.fooofparams` structure

### Channel Matching and Permutation Testing (December 2025)

See [CHANGES_SUMMARY.md](CHANGES_SUMMARY.md) for detailed changelog including:

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