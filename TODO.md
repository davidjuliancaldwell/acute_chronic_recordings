# TODO List

## Channel Mapping and Analysis Improvements

### Pending Tasks

1. **Double check channel mapping between RCS and intraoperative data**
   - Verify `rcsOrder` assignments in `subjects_to_analyze.m` correctly specify L/R hemispheres
   - Confirm channel labels match between intraop (LFPL2-0, ECOGL10-8, etc.) and RCS (after '+' stripping)
   - Add diagnostic prints in `compare_intraop_rcs.m` to show matched channel pairs

2. **Research aperiodic slope analysis methods for different frequency bands**
   - Investigate FOOOF/specparam (Python library) - fits aperiodic component + peaks
   - Explore IRASA (Irregular Resampling Auto-Spectral Analysis) - separates periodic from aperiodic
   - Determine methods to quantify differences in aperiodic slope between intraop vs RCS

3. **Implement aperiodic slope calculation in analysis pipeline**
   - Integrate chosen method into existing MATLAB pipeline
   - Calculate slopes across frequency bands for both intraop and RCS data
   - Store results in comparable format

4. **Research peak beta oscillation detection methods**
   - Methods to identify peak frequency and power in beta band (13-30 Hz)
   - Techniques to separate true oscillatory peaks from aperiodic background
   - Consider FOOOF or similar approaches

5. **Implement peak beta oscillation analysis**
   - Add peak detection to analysis scripts
   - Compare peak location and height between conditions
   - Generate visualizations

6. **Compare new metrics with permutation testing results**
   - Statistical comparison of aperiodic slope differences
   - Statistical comparison of peak beta oscillation differences
   - Evaluate sensitivity of new metrics vs current frequency bin permutation tests
