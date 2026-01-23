%% verify_fooof_results.m
% Diagnostic script to validate FOOOF spectral parameterization results
% for both intraoperative and RCS data.
%
% Run this AFTER running master_script_rcs_neuroomega with FOOOF enabled.
% Requires base_fre1Intraop and base_fre1RCSall with .fooofparams fields.
%
% This script checks:
% 1. FOOOF fit quality (R-squared values)
% 2. Aperiodic exponent ranges (should be ~1-3 for neural data)
% 3. Channel-by-channel fit statistics
% 4. Identifies poor fits that may need attention
%
% Updated for FieldTrip native FOOOF structure:
%   - base_fre1Intraop.fooofparams(chanIdx).aperiodic_params  [offset, exponent]
%   - base_fre1Intraop.fooofparams(chanIdx).r_squared
%   - base_fre1Intraop.fooofparams(chanIdx).error

fprintf('=== FOOOF Results Verification ===\n\n');

%% Check required variables exist
if ~exist('base_fre1Intraop', 'var')
    error('base_fre1Intraop not found in workspace. Run master_script_rcs_neuroomega first.');
end

if ~exist('base_fre1RCSall', 'var')
    error('base_fre1RCSall not found in workspace. Run master_script_rcs_neuroomega first.');
end

%% 1. Intraoperative FOOOF Results
if isfield(base_fre1Intraop, 'fooofparams')
    fprintf('--- Intraoperative FOOOF Results ---\n');
    fprintf('Channels: %d\n', length(base_fre1Intraop.fooofparams));

    % Extract parameters from fooofparams structure
    r2_vals = zeros(1, length(base_fre1Intraop.fooofparams));
    exp_vals = zeros(1, length(base_fre1Intraop.fooofparams));
    off_vals = zeros(1, length(base_fre1Intraop.fooofparams));

    for chanIdx = 1:length(base_fre1Intraop.fooofparams)
        r2_vals(chanIdx) = base_fre1Intraop.fooofparams(chanIdx).r_squared;
        exp_vals(chanIdx) = base_fre1Intraop.fooofparams(chanIdx).aperiodic_params(2);  % Exponent
        off_vals(chanIdx) = base_fre1Intraop.fooofparams(chanIdx).aperiodic_params(1);  % Offset
    end

    fprintf('\nFit Quality:\n');
    fprintf('  Mean R-squared: %.3f\n', nanmean(r2_vals));
    fprintf('  R-squared range: %.3f - %.3f\n', min(r2_vals), max(r2_vals));

    fprintf('\nAperiodic Parameters:\n');
    fprintf('  Mean Exponent: %.3f\n', nanmean(exp_vals));
    fprintf('  Exponent range: %.3f - %.3f\n', min(exp_vals), max(exp_vals));
    fprintf('  Mean Offset: %.3f\n', nanmean(off_vals));
    fprintf('  Offset range: %.3f - %.3f\n', min(off_vals), max(off_vals));

    % Per-channel breakdown
    fprintf('\nPer-Channel Results:\n');
    % Bug #24 fix: Use length(fooofparams) to match array sizes
    for chanIdx = 1:length(base_fre1Intraop.fooofparams)
        % Ensure label index exists
        if chanIdx <= length(base_fre1Intraop.label)
            label = base_fre1Intraop.label{chanIdx};
        else
            label = sprintf('Channel_%d', chanIdx);
        end
        r2 = r2_vals(chanIdx);
        exp = exp_vals(chanIdx);
        off = off_vals(chanIdx);

        % Flag quality issues
        flags = {};
        if r2 < 0.8
            flags{end+1} = 'LOW R2';
        end
        if exp < 0.5 || exp > 4.0
            flags{end+1} = 'UNUSUAL EXPONENT';
        end

        if isempty(flags)
            fprintf('  %s: R2=%.3f, Exp=%.3f, Off=%.3f\n', label, r2, exp, off);
        else
            fprintf('  %s: R2=%.3f, Exp=%.3f, Off=%.3f [%s]\n', label, r2, exp, off, strjoin(flags, ', '));
        end
    end

    % Check for poor fits
    poorFits = find(r2_vals < 0.8);
    if ~isempty(poorFits)
        fprintf('\nWARNING: %d channel(s) with R-squared < 0.8:\n', length(poorFits));
        for i = poorFits
            fprintf('  %s: R2 = %.3f\n', base_fre1Intraop.label{i}, r2_vals(i));
        end
        fprintf('Consider inspecting these channels manually or adjusting FOOOF settings.\n');
    else
        fprintf('\nAll channels have good fits (R-squared >= 0.8).\n');
    end
else
    fprintf('--- Intraoperative FOOOF Results ---\n');
    fprintf('FOOOF data not found. Was FOOOF analysis run?\n');
end

fprintf('\n');

%% 2. RCS FOOOF Results
if isfield(base_fre1RCSall, 'fooofparams') && ~isempty(base_fre1RCSall.fooofparams)
    fprintf('--- RCS FOOOF Results ---\n');

    totalSessions = 0;
    allR2 = [];
    allExp = [];
    allOff = [];

    for sessionIdx = 1:length(base_fre1RCSall.fooofparams)
        for iterIdx = 1:length(base_fre1RCSall.fooofparams{sessionIdx})
            totalSessions = totalSessions + 1;
            fooofParams = base_fre1RCSall.fooofparams{sessionIdx}{iterIdx};

            % Extract parameters from this session
            sessionR2 = zeros(1, length(fooofParams));
            sessionExp = zeros(1, length(fooofParams));
            sessionOff = zeros(1, length(fooofParams));

            for chanIdx = 1:length(fooofParams)
                sessionR2(chanIdx) = fooofParams(chanIdx).r_squared;
                sessionExp(chanIdx) = fooofParams(chanIdx).aperiodic_params(2);  % Exponent
                sessionOff(chanIdx) = fooofParams(chanIdx).aperiodic_params(1);  % Offset
            end

            fprintf('\nSession %d, Iteration %d:\n', sessionIdx, iterIdx);
            fprintf('  Channels: %d\n', length(fooofParams));
            fprintf('  Mean R-squared: %.3f (range: %.3f - %.3f)\n', ...
                nanmean(sessionR2), min(sessionR2), max(sessionR2));
            fprintf('  Mean Exponent: %.3f (range: %.3f - %.3f)\n', ...
                nanmean(sessionExp), min(sessionExp), max(sessionExp));

            % Collect for aggregate stats
            allR2 = [allR2, sessionR2];
            allExp = [allExp, sessionExp];
            allOff = [allOff, sessionOff];

            % Per-channel breakdown for this session
            fprintf('  Channels:\n');
            % Get labels if available
            if isfield(base_fre1RCSall, 'chans') && length(base_fre1RCSall.chans) >= sessionIdx && ...
                    length(base_fre1RCSall.chans{sessionIdx}) >= iterIdx
                labels = base_fre1RCSall.chans{sessionIdx}{iterIdx};
            else
                labels = {};
                for i = 1:length(fooofParams)
                    labels{i} = sprintf('Ch%d', i);
                end
            end

            for chanIdx = 1:length(fooofParams)
                if chanIdx <= length(labels)
                    label = labels{chanIdx};
                else
                    label = sprintf('Ch%d', chanIdx);
                end
                r2 = sessionR2(chanIdx);
                exp = sessionExp(chanIdx);
                off = sessionOff(chanIdx);

                % Flag quality issues
                flags = {};
                if r2 < 0.8
                    flags{end+1} = 'LOW R2';
                end
                if exp < 0.5 || exp > 4.0
                    flags{end+1} = 'UNUSUAL EXPONENT';
                end

                if isempty(flags)
                    fprintf('    %s: R2=%.3f, Exp=%.3f, Off=%.3f\n', label, r2, exp, off);
                else
                    fprintf('    %s: R2=%.3f, Exp=%.3f, Off=%.3f [%s]\n', label, r2, exp, off, strjoin(flags, ', '));
                end
            end

            % Check for poor fits in this session
            poorFits = sum(sessionR2 < 0.8);
            if poorFits > 0
                fprintf('  WARNING: %d channel(s) with R-squared < 0.8\n', poorFits);
            end
        end
    end

    % Overall RCS statistics
    fprintf('\n--- Overall RCS Statistics (All Sessions) ---\n');
    fprintf('Total sessions/iterations: %d\n', totalSessions);
    fprintf('Mean R-squared: %.3f (range: %.3f - %.3f)\n', ...
        nanmean(allR2), min(allR2), max(allR2));
    fprintf('Mean Exponent: %.3f (range: %.3f - %.3f)\n', ...
        nanmean(allExp), min(allExp), max(allExp));
    fprintf('Mean Offset: %.3f (range: %.3f - %.3f)\n', ...
        nanmean(allOff), min(allOff), max(allOff));

    poorFitsTotal = sum(allR2 < 0.8);
    if poorFitsTotal > 0
        fprintf('\nWARNING: %d total channel measurement(s) with R-squared < 0.8\n', poorFitsTotal);
    else
        fprintf('\nAll RCS channels have good fits (R-squared >= 0.8).\n');
    end
else
    fprintf('--- RCS FOOOF Results ---\n');
    fprintf('FOOOF data not found. Was FOOOF analysis run?\n');
end

fprintf('\n=== FOOOF Verification Complete ===\n');
fprintf('\nInterpretation Guidelines:\n');
fprintf('- R-squared > 0.9: Excellent fit\n');
fprintf('- R-squared 0.8-0.9: Good fit\n');
fprintf('- R-squared < 0.8: Poor fit (investigate further)\n');
fprintf('- Typical exponent range for neural data: 1-3\n');
fprintf('- Higher exponent = steeper 1/f falloff\n');
