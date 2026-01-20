# Progress: RCS Analysis Pipeline Development

## Overview
This document tracks development progress, changes, and bug fixes for the RCS intraoperative vs. clinic comparison analysis pipeline. It includes channel naming harmonization, permutation testing implementation, FOOOF spectral parameterization, and critical bug fixes.

## Latest Updates (January 2026)

### Repository Reorganization (January 20, 2026)

**Goal:** Improve code organization by moving files into appropriate subdirectories.

**New Folder Structure:**
- `config/` - Subject configuration files (`subjects_to_analyze*.m`)
- `analysis/` - Core analysis scripts (`analyze_*.m`, `compare_*.m`)
- `verification/` - Quality control scripts (`verify_*.m`)
- `tests/` - Development test scripts
- `experimental/` - Exploratory/experimental scripts
- `deprecated/` - Obsolete debugging scripts (kept for reference)

**Files Moved:**
- 2 config files → `config/`
- 6 analysis scripts → `analysis/`
- 2 verification scripts → `verification/`
- 2 test scripts → `tests/`
- 2 experimental scripts → `experimental/`
- 7 obsolete debug scripts → `deprecated/`

**Path Compatibility:** No changes needed to `setup_rcs.m` - uses `addpath(genpath(...))` which recursively adds all subdirectories.

---

### Unilateral Data Support (January 7, 2026)

#### 1. **Added `sidesToUse` Parameter for Hemisphere Selection**
**Files Modified:** `analyze_intraop.m`, `analyze_intraop_HFO.m`

**Problem:** Unilateral (8-channel) intraoperative data was always labeled as LEFT hemisphere, causing channel matching failures for right-hemisphere-only subjects (e.g., RCS03).

**Solution:**
```matlab
% Channel labeling now uses sidesToUse parameter
if strcmp(sidesToUse,'b')
    % Bilateral: channels 1-4 → LEFT, 5-8 → RIGHT
elseif strcmp(sidesToUse,'l')
    % Left only: all channels → LEFT
elseif strcmp(sidesToUse,'r')
    % Right only: all channels → RIGHT
end
```

**Key lines:**
- `analyze_intraop.m`: Lines 37-54 (LFP), 79-96 (ECoG)
- `analyze_intraop_HFO.m`: Lines 42-59 (LFP), 84-101 (ECoG)

---

#### 2. **Fixed Hemisphere Detection in Bipolar Skip Rereferencing**
**Files Modified:** `analyze_intraop.m` (line 164), `analyze_intraop_HFO.m` (line 169)

**Problem:** Detection used `contains(label,'L')` which matched both 'LFPL' and 'LFPR'

**Solution:**
```matlab
% BEFORE (incorrect):
if contains(dataIntraop.label{1},'L')

% AFTER (correct):
if contains(dataIntraop.label{1},'LFPL') || contains(dataIntraop.label{1},'ECOGL')
```

---

#### 3. **Channel Order Preservation Fix**
**Files Modified:** `analyze_rcs.m` (lines 144, 153), `analyze_rcs_HFO.m` (lines 121, 130)

**Problem:** MATLAB's `unique()` alphabetically sorts channel labels, breaking label-data correspondence

**Solution:**
```matlab
% Use inds from unique() to restore original ordering
[labels, inds] = unique(chansStruct{index});
dataRCS.label = labelsWithPrefix(inds);  % Preserves original device order
```

---

### HFO Scripts Unilateral Data Support (January 2026)

#### 4. **Added Missing `sidesToUseCell` to HFO Configuration**
**File Modified:** `subjects_to_analyze_HFO.m` (lines 68-70)

**Problem:** HFO scripts failed with "Unrecognized function or variable 'sidesToUse'"

**Solution:**
```matlab
sidesToUseCell = {
    'b'    % RCS06 - bilateral
};
```

---

#### 5. **Added `sidesToUse` Variable to HFO Master Script**
**File Modified:** `master_script_rcs_neuroomega_HFO.m` (line 49)

**Solution:**
```matlab
sidesToUse = sidesToUseCell{subjNum};
```

---

#### 6. **Added Hemisphere Filtering to HFO Comparison Script**
**File Modified:** `compare_intraop_rcs_HFO.m` (lines 3-22)

**Problem:** HFO comparison script didn't filter channels by hemisphere

**Solution:**
```matlab
% Find all ECoG and LFP channels by hemisphere
indicesECOGintraL = find(contains(base_fre1Intraop.label,'ECOGL'));
indicesECOGintraR = find(contains(base_fre1Intraop.label,'ECOGR'));
indicesLFPintraL = find(contains(base_fre1Intraop.label,'LFPL'));
indicesLFPintraR = find(contains(base_fre1Intraop.label,'LFPR'));

% Filter by hemisphere based on sidesToUse
if strcmp(sidesToUse,'b')
    indicesECOGintra = [indicesECOGintraL indicesECOGintraR];
    indicesLFPintra = [indicesLFPintraL indicesLFPintraR];
elseif strcmp(sidesToUse,'r')
    indicesECOGintra = indicesECOGintraR;
    indicesLFPintra = indicesLFPintraR;
elseif strcmp(sidesToUse,'l')
    indicesECOGintra = indicesECOGintraL;
    indicesLFPintra = indicesLFPintraL;
end
```

---

#### 7. **Fixed HFO Plotting with `chanInt` Variable**
**File Modified:** `analyze_intraop_HFO.m` (lines 263-272)

**Problem:** Hardcoded channel index 7 and missing trial dimension handling

**Solution:**
```matlab
% BEFORE (broken):
plot(base_fre1Intraop.freq,log10(base_fre1Intraop.powspctrm(7,:)))

% AFTER (fixed):
chanInt = 7;
plot(base_fre1Intraop.freq,log10(squeeze(mean(base_fre1Intraop.powspctrm(:,chanInt,:),1))))
```

---

### FOOOF Reimplementation (January 2026)

#### 8. **Replaced `fooof_mat` with FieldTrip Native FOOOF**
**Files Modified:** All analysis scripts

**Problem:** Previous `fooof_mat` wrapper was broken

**Solution:** Uses FieldTrip's native FOOOF via Brainstorm
```matlab
cfgFooof = [];
cfgFooof.method = 'mtmfft';
cfgFooof.output = 'fooof_aperiodic';  % Get 1/f component only
cfgFooof.fooof.freq_range = [4 50];
cfgFooof.fooof.aperiodic_mode = 'fixed';
base_fre1_fooof = ft_freqanalysis(cfgFooof, dataPreProcOverlap);
```

**Key notes:**
- Output is in **LINEAR scale** (use `log10()` for visualization)
- Results stored in `.fooofparams` field
- Aperiodic params: `[offset, exponent]`

---

### Validation Results (January 2026)

**Regular Analysis:**
- RCS02 (bilateral): 8 matched channel pairs ✓
- RCS03 (right only): 4 matched channel pairs ✓
- Bonferroni correction applied correctly

**HFO Analysis:**
- sidesToUse error: FIXED ✓
- Plotting error: FIXED ✓
- Intraop HFO FOOOF completes successfully ✓

---

## Previous Updates (December 28, 2025)

### Bug Fixes

#### 1. **Fixed `rcsOrder` Cell Array Syntax**
**Files Modified:** `subjects_to_analyze.m`, `subjects_to_analyze_HFO.m`

**Problem:** Incorrect cell array syntax caused all hemisphere assignments to default to 'L'
```matlab
% BEFORE (incorrect):
rcsOrder = {
    [{'L'},{'R'}],   % Both evaluated to 'L'
    [{'R'}]
};
```

**Solution:**
```matlab
% AFTER (correct):
rcsOrder = {
    {'L','R'},   % RCS02: session 1 is Left, session 2 is Right
    {'R'}        % RCS03: session 1 is Right
};
```

**Impact:** Channel matching now works correctly with proper hemisphere assignment

---

#### 2. **Fixed RCS Channel Name Formatting ('+' Character Stripping)**
**Files Modified:** `analyze_rcs.m` (line 138), `analyze_rcs_HFO.m` (line 115)

**Problem:** RCS device channel names include '+' character (e.g., `+10-8`), but intraop labels don't (e.g., `10-8`), preventing channel matching

**Solution:**
```matlab
% Strip '+' character to match intraop naming convention
chanLabel = strrep(chanLabel, '+', '');
labelsWithPrefix{labelIdx} = [prefix chanLabel];  % e.g., "ECOGL10-8"
```

**Before:** `ECOGL+10-8` (no match)
**After:** `ECOGL10-8` (matches intraop)

**Impact:** Channel matching via `strcmp()` now succeeds, enabling proper statistical comparisons

---

#### 3. **Fixed Unguarded Significance Star Plotting**
**File Modified:** `compare_intraop_rcs.m` (lines 184, 205)

**Problem:** Significance stars plotted even when statistical tests weren't run

**Solution:**
```matlab
% BEFORE:
for index=1:5
    if statsResults.pLFP(index)<=0.05
        scatter(...);  % Would error if statsResults doesn't exist
    end
end

% AFTER:
if rankSumTest || signedRankTest
    for index=1:5
        if statsResults.pLFP(index)<=0.05
            scatter(...);
        end
    end
end
```

**Impact:** No errors when tests disabled; cleaner output

---

#### 4. **Restructured HFO Analysis Architecture**
**Files Modified:** `subjects_to_analyze_HFO.m`, `analyze_rcs_HFO.m`

**Problem:** HFO analysis script structure didn't match regular analysis, causing indexing errors

**Changes:**

**a) `subjects_to_analyze_HFO.m` - Nested rcsFiles:**
```matlab
% BEFORE (flat array):
rcsFiles = {
    path1,
    path2,
    path3,
    path4
};

% AFTER (nested cell array):
rcsFiles = {
    {path1, path2, path3, path4}  % All sessions for RCS06
};
```

**b) `analyze_rcs_HFO.m` - Added outer session loop:**
```matlab
% BEFORE: Single file processing
splitPath = strsplit(pathDataRcs,'/');
ProcessRCS(pathDataRcs, ...)
for jj = 1:length(iterations)
    % Process iterations
end

% AFTER: Multi-file session processing
for jjj = 1:length(pathDataRcs)  % NEW: Outer loop
    splitPath = strsplit(pathDataRcs{jjj},'/');
    ProcessRCS(pathDataRcs{jjj}, ...)

    index = 1;  % NEW: Reset index counter
    for jj = iterations  % Iterate through montage changes
        % Use 'index' for storage, increment at end
        index = index + 1;
    end
end
```

**c) Fixed `rcsOrder` indexing:**
```matlab
% BEFORE:
sideLabel = rcsOrder{subjNum}{jj};  % jj iterates montage changes, not sessions!

% AFTER:
sideLabel = rcsOrder{subjNum}{jjj};  % jjj iterates session files (correct)
```

**d) Renamed loop variable to avoid conflicts:**
```matlab
% BEFORE:
for index = 1:size(freqEdges,1)  % Conflicts with data storage index!
    base_fre1RCSall.averagedBins{jj}{index}(:,index) = ...
end

% AFTER:
for binIdx = 1:size(freqEdges,1)  % No conflict
    base_fre1RCSall.averagedBins{jjj}{index}(:,binIdx) = ...
end
```

**Impact:** HFO and regular analysis now use identical architecture; proper session-level hemisphere assignment

---

#### 5. **Updated stdshade Plotting for Individual Channels**
**Files Modified:** `compare_intraop_rcs.m` (lines 254, 307, 371, 423), `compare_intraop_rcs_HFO.m` (lines 179, 223), `helpers/stdshade.m`

**Problem:** Individual channel plots were not properly indexing 3D data structure (trials × channels × frequencies)

**Solution:**
```matlab
% BEFORE (incorrect 2D indexing):
line2 = stdshade(log10(base_fre1Intraop.normalizedPow(plotIdx,:)),0.5,'r');

% AFTER (correct 3D indexing with transpose):
line2 = stdshade(log10(squeeze(base_fre1Intraop.normalizedPow(:,plotIdx,:)))',0.5,'r');
```

**Explanation:**
- `base_fre1Intraop.normalizedPow` is (trials, channels, frequencies)
- Select all trials (`:`), specific channel (`plotIdx`), all frequencies (`:`)
- `squeeze()` removes singleton dimension: (trials, frequencies)
- Transpose `'` gives (frequencies, trials) for plotting
- Applied to both `normalizedPow` and `powspctrm` plots
- Applied to both 4-channel and 8-channel cases
- Applied to both regular and HFO versions

**Additional Change:** `stdshade.m` updated to plot SEM (standard error of mean) instead of SD (standard deviation)

**Impact:** Proper visualization of trial-level variability with correct error bars

---

## Original Implementation (Prior to December 28, 2025)

## Files Modified

### Regular Analysis Scripts

#### 1. `analyze_intraop.m`
**Changes:**
- Updated LFP channel numbering from counter-based to 0-3 convention
  - Left LFP: `jj-1` (channels 0-3)
  - Right LFP: `jj-5` (channels 0-3)
- Updated ECoG channel numbering to 8-11 convention
  - Left ECoG: `jj+7` (channels 8-11)
  - Right ECoG: `jj+3` (channels 8-11)
- Updated bipolar skip montage labels to match new numbering:
  - `labelold`: LFPL0-3, LFPR0-3, ECOGL8-11, ECOGR8-11
  - `labelnew`: LFPL2-0, LFPL3-1, LFPR2-0, LFPR3-1, ECOGL10-8, ECOGL11-9, ECOGR10-8, ECOGR11-9

**Key lines:** 35-42, 64-71, 104-120, 138-153

#### 2. `analyze_rcs.m`
**Changes:**
- Added region prefix logic (ECOGL/ECOGR/LFPL/LFPR) to RCS channel labels
- Uses `rcsOrder{subjNum}{index}` to determine L/R side for each session
- Detects ECoG vs LFP based on contact numbers:
  - ECoG: contains +8/+9/+10/+11 or -8/-9/-10/-11
  - LFP: contacts 0-3
- Constructs labels like: "ECOGL+8-10", "LFPR0-2", etc.

**Key lines:** 120-138

#### 3. `subjects_to_analyze.m`
**Changes:**
- Added `rcsOrder` variable to specify L/R ordering for RCS sessions
- Example: `{['L','R']}, {['R']}`
- Indexed by subject number, then session number

**Key lines:** 81-84

#### 4. `compare_intraop_rcs.m`
**Major changes:**

**a) Permutation Testing (lines 89-151):**
- Implements channel-by-channel permutation testing
- Matches RCS and intraop channels by label using `strcmp()`
- Loops through all RCS sessions and channels
- Performs 10,000 permutations per channel-frequency bin pair
- Stores results in `statsResultsPerm` structure:
  - `.p`: p-values (freqBin × channelPair)
  - `.diff`: observed differences
  - `.effect`: effect sizes
  - `.channelPairs`: matched channel labels
- Calculates Bonferroni threshold: `0.05 / (numFreqBins × numMatchedPairs)`

**b) Updated RCS Channel Detection (lines 15-16):**
- Changed from contact number detection to region prefix detection
- Now uses: `contains(base_fre1RCScollapse.label,'ECOG')` and `contains(...,'LFP')`

**c) Individual Channel Plots with Matching (lines 230-336, 347-452):**
- Added channel label matching for all subplots
- Finds matching RCS channel: `rcsIdx = find(strcmp(base_fre1RCScollapse.label, chanLabel))`
- Uses matched index for plotting RCS data
- Prevents plotting mismatched channels
- Applied to both normalized power and raw power spectrum plots
- Both 4-channel and 8-channel cases

**d) Significance Marking (throughout plotting sections):**
- Added Bonferroni-corrected significance stars on EACH subplot
- Uses `scatter()` function centered on frequency bin
- Position: `(freqEdgesPlot(freqBin,2)+freqEdgesPlot(freqBin,1))/2, maxVal-0.15`
- Only shown when `p < bonferroniThreshold`
- Each subplot checks for its own channel's significance independently

**e) Flag-Based Statistics (lines 64, 152-154):**
- Wrapped rankSum tests with `rankSumTest` flag
- Separate storage for permutation results: `statsCellPerm{subjNum}`

#### 5. `master_script_rcs_neuroomega.m`
**Changes:**
- Added comment noting rcsOrder access: `% Note: rcsOrder is accessed directly in analyze_rcs as rcsOrder{subjNum}`

**Key line:** 46

---

### HFO Analysis Scripts

#### 6. `analyze_intraop_HFO.m`
**Changes:**
- Identical channel numbering changes as regular `analyze_intraop.m`
- LFP channels: 0-3
- ECoG channels: 8-11
- Updated bipolar skip montage labels

**Key lines:** 40-47, 69-76, 108-153

#### 7. `analyze_rcs_HFO.m`
**Changes:**
- Identical region prefix logic as regular `analyze_rcs.m`
- Uses `rcsOrder{subjNum}{jj}` (note: `jj` instead of `index` due to different loop structure)
- Adds ECOGL/ECOGR/LFPL/LFPR prefixes

**Key lines:** 92-110

#### 8. `subjects_to_analyze_HFO.m`
**Changes:**
- Added `rcsOrder` variable for RCS06 sessions
- `rcsOrder = {{['R','R','R','L']}}` (four sessions: R, R, R, L)

**Key lines:** 64-66

#### 9. `compare_intraop_rcs_HFO.m`
**Major changes:**

**a) Permutation Testing (lines 18-61):**
- Identical permutation test logic as regular version
- Note: Different data structure access (`samps_rcs_cell(:,freqBin)` vs `samps_rcs_cell(:,rcsIdx,freqBin)`)
- Bonferroni correction applied

**b) Updated RCS Channel Detection (lines 15-16):**
- Uses region prefix detection: `contains(...,'ECOG')` and `contains(...,'LFP')`

**c) Individual Channel Plots (lines 120-251):**
- Completely refactored to use loop-based approach
- Added channel label matching for each subplot
- Finds matching RCS channel by label
- Bonferroni-corrected significance stars on EACH subplot
- Each subplot independently tests and displays significance for its matched channel
- Supports 4-channel and 8-channel cases
- Includes HFO frequency bin (250-350 Hz)
- Only xlabel/ylabel on first subplot

**d) Flag-Based Statistics (lines 64, 109-111, 151-153):**
- Wrapped rankSum tests with `rankSumTest` flag
- Wrapped statsCell assignment with conditional

#### 10. `master_script_rcs_neuroomega_HFO.m`
**Changes:**
- Added statistics flags:
  - `signedRankTest = 0`
  - `rankSumTest = 0`
  - `permute_test = 1`
- Added comment about rcsOrder access

**Key lines:** 32-37, 53

---

## Key Improvements

### 1. **Channel Label Harmonization**
- RCS and intraop data now use identical channel naming convention
- Enables label-based matching instead of position-based indexing
- Robust to different channel orderings and missing channels

### 2. **Channel-by-Channel Permutation Testing**
- Proper statistical comparison of matched channel pairs
- 10,000 permutations per test
- Effect size calculation
- Bonferroni correction for multiple comparisons

### 3. **Visualization Enhancements**
- Bonferroni-corrected significance stars on EACH individual channel subplot
- Channel label matching ensures correct comparisons
- Only shows xlabel/ylabel on first subplot (cleaner appearance)
- Each subplot independently checks and displays significance for its matched channel

### 4. **Code Quality**
- Refactored repetitive plotting code into loops
- Added channel matching validation
- Clear variable naming and comments
- Flag-based conditional statistics

---

## Channel Naming Convention

### Intraoperative Data
**LFP Channels:**
- Left: LFPL0, LFPL1, LFPL2, LFPL3
- Right: LFPR0, LFPR1, LFPR2, LFPR3

**ECoG Channels:**
- Left: ECOGL8, ECOGL9, ECOGL10, ECOGL11
- Right: ECOGR8, ECOGR9, ECOGR10, ECOGR11

**Bipolar Skip Rereferencing:**
- LFPL2-0, LFPL3-1 (left LFP)
- LFPR2-0, LFPR3-1 (right LFP)
- ECOGL10-8, ECOGL11-9 (left ECoG)
- ECOGR10-8, ECOGR11-9 (right ECoG)

### RCS Data
Same naming convention with original contact notation appended:
- Example ECoG: "ECOGL+8-10" (left ECoG, contacts 8 and 10)
- Example LFP: "LFPR0-2" (right LFP, contacts 0 and 2)

---

## Statistical Testing

### Permutation Test
- **Method**: Non-parametric permutation test
- **Iterations**: 10,000 per test
- **Output**: p-value, observed difference, effect size
- **Correction**: Bonferroni (alpha = 0.05 / total_tests)
- **Total tests**: numFreqBins × numMatchedPairs

### Significance Marking on Plots
**Important**: Significance stars are plotted on EACH individual channel subplot, not just the first one.

**Implementation**:
- The significance checking code is INSIDE the main plotting loop
- Each subplot iteration:
  1. Finds the matching channel label
  2. Looks up that channel's p-values in `statsResultsPerm.channelPairs`
  3. For each frequency bin, checks if `p < bonferroniThreshold`
  4. Plots asterisks centered on significant frequency bins
- Result: Each subplot shows its own channel-specific significance markers

**Example**: In a 4-channel case, subplot 1 shows significance for channel 1, subplot 2 shows significance for channel 2, etc.

**Axes Labels**: Only the first subplot (plotIdx == 1) displays xlabel and ylabel to reduce clutter

### Frequency Bins
**Regular Analysis:**
1. Theta: 4-8 Hz
2. Alpha: 8-12 Hz
3. Low Beta: 13-20 Hz
4. High Beta: 20-30 Hz
5. Broadband Gamma: 50-125 Hz

**HFO Analysis (adds):**
6. HFO: 250-350 Hz

---

## Validation Checklist

### Regular Scripts
- [x] `analyze_intraop.m`: Channel numbering updated (0-3, 8-11)
- [x] `analyze_intraop.m`: sidesToUse parameter for hemisphere selection (Jan 7, 2026)
- [x] `analyze_intraop.m`: Hemisphere detection fixed to use 'LFPL'/'ECOGL' (Jan 7, 2026)
- [x] `analyze_rcs.m`: Region prefixes added
- [x] `analyze_rcs.m`: '+' character stripping added (Dec 28, 2025)
- [x] `analyze_rcs.m`: Channel order preservation with unique() inds (Jan 7, 2026)
- [x] `subjects_to_analyze.m`: rcsOrder variable added
- [x] `subjects_to_analyze.m`: rcsOrder syntax fixed (Dec 28, 2025)
- [x] `subjects_to_analyze.m`: sidesToUseCell for hemisphere configuration (Jan 7, 2026)
- [x] `compare_intraop_rcs.m`: Permutation testing implemented
- [x] `compare_intraop_rcs.m`: Channel matching added to all plots
- [x] `compare_intraop_rcs.m`: Significance stars added
- [x] `compare_intraop_rcs.m`: Significance plotting guards added (Dec 28, 2025)
- [x] `compare_intraop_rcs.m`: stdshade calls updated with 3D indexing (Dec 28, 2025)
- [x] `compare_intraop_rcs.m`: FOOOF visualization plots added (Jan 2026)
- [x] `master_script_rcs_neuroomega.m`: Comments updated
- [x] `master_script_rcs_neuroomega.m`: sidesToUse variable extraction (Jan 7, 2026)
- [x] `helpers/stdshade.m`: Updated to plot SEM not SD (Dec 28, 2025)

### HFO Scripts
- [x] `analyze_intraop_HFO.m`: Channel numbering updated
- [x] `analyze_intraop_HFO.m`: sidesToUse parameter for hemisphere selection (Jan 7, 2026)
- [x] `analyze_intraop_HFO.m`: Hemisphere detection fixed to use 'LFPL'/'ECOGL' (Jan 7, 2026)
- [x] `analyze_intraop_HFO.m`: chanInt variable and squeeze(mean()) for plotting (Jan 2026)
- [x] `analyze_rcs_HFO.m`: Region prefixes added
- [x] `analyze_rcs_HFO.m`: '+' character stripping added (Dec 28, 2025)
- [x] `analyze_rcs_HFO.m`: Outer jjj loop added (Dec 28, 2025)
- [x] `analyze_rcs_HFO.m`: rcsOrder indexing fixed to {jjj} (Dec 28, 2025)
- [x] `analyze_rcs_HFO.m`: Loop variable renamed (binIdx) (Dec 28, 2025)
- [x] `analyze_rcs_HFO.m`: Channel order preservation with unique() inds (Jan 7, 2026)
- [x] `subjects_to_analyze_HFO.m`: rcsOrder variable added
- [x] `subjects_to_analyze_HFO.m`: rcsOrder syntax fixed (Dec 28, 2025)
- [x] `subjects_to_analyze_HFO.m`: rcsFiles nested structure (Dec 28, 2025)
- [x] `subjects_to_analyze_HFO.m`: sidesToUseCell added (Jan 2026)
- [x] `compare_intraop_rcs_HFO.m`: Permutation testing implemented
- [x] `compare_intraop_rcs_HFO.m`: Channel matching added to plots
- [x] `compare_intraop_rcs_HFO.m`: Significance stars added
- [x] `compare_intraop_rcs_HFO.m`: stdshade calls updated with 3D indexing (Dec 28, 2025)
- [x] `compare_intraop_rcs_HFO.m`: Hemisphere filtering logic added (Jan 2026)
- [x] `master_script_rcs_neuroomega_HFO.m`: Flags and comments added
- [x] `master_script_rcs_neuroomega_HFO.m`: sidesToUse variable extraction (Jan 2026)

---

## Testing Recommendations

1. **Run Regular Analysis:**
   ```matlab
   master_script_rcs_neuroomega
   ```
   - Verify channel labels match between RCS and intraop
   - Check that permutation testing completes
   - Verify Bonferroni threshold calculation
   - Confirm significance stars appear on plots

2. **Run HFO Analysis:**
   ```matlab
   master_script_rcs_neuroomega_HFO
   ```
   - Same verification as regular analysis
   - Confirm 6 frequency bins (including HFO)

3. **Check Output:**
   - Inspect `statsResultsPerm` structure
   - Verify `.channelPairs` contains expected labels
   - Check that number of matched pairs is correct
   - Confirm p-values are in [0,1] range

4. **Visual Inspection:**
   - Individual channel plots show matched data
   - Significance stars appear only when p < threshold
   - Channel labels are consistent across plots
   - No empty/blank subplots

---

## Potential Issues and Solutions

### Issue 1: No matching channels found
**Symptom**: Warning message "No matching intraop channel found for RCS channel: ..."
**Solutions** (Fixed Dec 28, 2025):
1. Verify `rcsOrder` uses correct syntax: `{'L','R'}` NOT `[{'L'},{'R'}]`
2. Confirm '+' stripping code exists: `chanLabel = strrep(chanLabel, '+', '')`
3. Check hemisphere ordering matches actual data files

### Issue 2: Too many/few significance stars
**Symptom**: Unexpected number of significant results
**Solutions**:
1. Check Bonferroni threshold calculation, verify numTests is correct
2. Ensure significance plotting is guarded by test flags (Fixed Dec 28, 2025)

### Issue 3: Misaligned channel plots
**Symptom**: RCS and intraop data don't match visually
**Solutions** (Fixed Dec 28, 2025):
1. Confirm channel matching logic uses `strcmp()` on labels
2. Check label construction includes '+' stripping in analyze_rcs.m
3. Verify RCS and intraop labels match exactly

### Issue 4: Error in permutation test loop
**Symptom**: Array indexing errors
**Solution**: Verify data dimensions match expected structure (trials × channels × freqBins)

### Issue 5: HFO analysis indexing errors (Fixed Dec 28, 2025)
**Symptom**: "Index exceeds array dimensions" or wrong hemisphere assignment in HFO scripts
**Solutions**:
1. Verify `analyze_rcs_HFO.m` has outer `for jjj` loop (line 8)
2. Check `rcsOrder` indexed with `{jjj}` not `{jj}` (line 102)
3. Confirm `rcsFiles` uses nested cell array structure in `subjects_to_analyze_HFO.m`
4. Ensure loop variable for frequency bins renamed to `binIdx` to avoid conflicts

### Issue 6: Significance stars plotted when tests disabled (Fixed Dec 28, 2025)
**Symptom**: Errors or unwanted stars when `rankSumTest = 0` and `signedRankTest = 0`
**Solution**: Significance plotting now guarded with `if rankSumTest || signedRankTest` checks

---

## Notes

- All changes maintain backward compatibility with flag-based statistics
- Original rankSum test code preserved under `rankSumTest` flag
- Channel matching is robust to missing or extra channels
- Code is well-commented for future maintenance
- Both regular and HFO versions are synchronized

---

## Summary of December 28, 2025 Session

**Critical Bug Fixes:**
1. ✅ **rcsOrder syntax** - Fixed cell array construction preventing proper hemisphere assignment
2. ✅ **Channel name matching** - Added '+' character stripping for RCS labels
3. ✅ **Significance plotting guards** - Prevented errors when tests disabled
4. ✅ **HFO architecture** - Restructured to match regular analysis with proper session-level loops
5. ✅ **stdshade 3D indexing** - Fixed individual channel plotting to properly index trials dimension

**Files Modified (Dec 28, 2025):**
- `subjects_to_analyze.m` - Fixed rcsOrder syntax (line 81-84)
- `subjects_to_analyze_HFO.m` - Fixed rcsOrder syntax and nested rcsFiles (lines 19-27, 64-66)
- `analyze_rcs.m` - Added '+' stripping (line 138)
- `analyze_rcs_HFO.m` - Added outer loop, fixed indexing, renamed variables (major restructure)
- `compare_intraop_rcs.m` - Added significance plotting guards, updated stdshade calls (lines 184, 205, 254, 307, 371, 423)
- `compare_intraop_rcs_HFO.m` - Updated stdshade calls (lines 179, 223)
- `helpers/stdshade.m` - Changed from SD to SEM plotting
- `README.md` - Updated with bug fixes and troubleshooting
- `CLAUDE.md` - Updated with bug fixes, stdshade documentation, and detailed troubleshooting
- `progress.md` - Documented all changes (this file)

**Testing Status:** All bug fixes validated and documented. Channel matching now works correctly for both regular and HFO analysis pipelines.

---

**Generated**: 2025-12-28 (Updated)
**Authors**: David Caldwell (manual edits), Claude (Anthropic)
**Purpose**: Comprehensive documentation of channel naming harmonization, permutation testing implementation, and critical bug fixes
