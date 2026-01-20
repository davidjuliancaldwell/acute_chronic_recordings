% Diagnostic script to check FOOOF spectrum data
clear all
close all

fprintf('\n=== FOOOF Spectrum Data Diagnostics ===\n\n');

% Setup and load data
setup_rcs
subjects_to_analyze

subjNum = 1;
subj = subjsToAnalyze{subjNum};
pathDataIntraOp = intraOpFiles{subjNum};
pathDataRcs = rcsFiles{subjNum};

% Set required variables
bipolarReref = 0;
bipolarSkipReref = 1;
signedRankTest = 1;
rankSumTest = 0;
permute_test = 0;
beginRCS = timeStampStart{subjNum};
endRCS = timeStampStop{subjNum};
if exist('iterationInterest', 'var')
    iterationInterestSpecific = iterationInterest{subjNum};
else
    iterationInterestSpecific = [];
end
rerefChoice = rerefCell{subjNum};
sidesToUse = sidesToUseCell{subjNum};
if ~isempty(makeNan{subjNum})
    startIntraop = makeNan{subjNum}{1};
    endIntraop = makeNan{subjNum}{2};
end

% Run analyses (suppress output)
fprintf('Running intraop analysis...\n');
evalc('analyze_intraop');

fprintf('Running RCS analysis...\n');
evalc('analyze_rcs');

fprintf('\n--- INTRAOP FOOOF DATA ---\n');
fprintf('fooof_powspctrm field exists: %d\n', isfield(base_fre1Intraop, 'fooof_powspctrm'));
fprintf('fooof_freq field exists: %d\n', isfield(base_fre1Intraop, 'fooof_freq'));

if isfield(base_fre1Intraop, 'fooof_powspctrm')
    fprintf('fooof_powspctrm size: %s\n', mat2str(size(base_fre1Intraop.fooof_powspctrm)));
    fprintf('fooof_freq size: %s\n', mat2str(size(base_fre1Intraop.fooof_freq)));
    fprintf('fooof_freq range: %.1f - %.1f Hz\n', min(base_fre1Intraop.fooof_freq), max(base_fre1Intraop.fooof_freq));
    fprintf('\nChannel 1 spectrum values:\n');
    fprintf('  First 5: %s\n', mat2str(base_fre1Intraop.fooof_powspctrm(1,1:5)));
    fprintf('  Min: %.6f, Max: %.6f, Mean: %.6f\n', ...
        min(base_fre1Intraop.fooof_powspctrm(1,:)), ...
        max(base_fre1Intraop.fooof_powspctrm(1,:)), ...
        mean(base_fre1Intraop.fooof_powspctrm(1,:)));
    fprintf('  Sum: %.6f\n', sum(base_fre1Intraop.fooof_powspctrm(1,:)));

    % Check if values are all zeros or NaNs
    if all(base_fre1Intraop.fooof_powspctrm(:) == 0)
        fprintf('  WARNING: All zeros!\n');
    elseif all(isnan(base_fre1Intraop.fooof_powspctrm(:)))
        fprintf('  WARNING: All NaNs!\n');
    else
        fprintf('  Data appears valid\n');
    end
end

fprintf('\n--- RCS FOOOF DATA ---\n');
fprintf('fooof_powspctrm field exists: %d\n', isfield(base_fre1RCSall, 'fooof_powspctrm'));

if isfield(base_fre1RCSall, 'fooof_powspctrm')
    fprintf('Sessions: %d\n', length(base_fre1RCSall.fooof_powspctrm));
    fprintf('Session 1 iterations: %d\n', length(base_fre1RCSall.fooof_powspctrm{1}));

    rcsSpectrum = base_fre1RCSall.fooof_powspctrm{1}{1};
    fprintf('Session 1, Iter 1 size: %s\n', mat2str(size(rcsSpectrum)));
    fprintf('\nChannel 1 spectrum values:\n');
    fprintf('  First 5: %s\n', mat2str(rcsSpectrum(1,1:5)));
    fprintf('  Min: %.6e, Max: %.6e, Mean: %.6e\n', ...
        min(rcsSpectrum(1,:)), max(rcsSpectrum(1,:)), mean(rcsSpectrum(1,:)));
    fprintf('  Sum: %.6e\n', sum(rcsSpectrum(1,:)));

    % Check if values are all zeros or NaNs
    if all(rcsSpectrum(:) == 0)
        fprintf('  WARNING: All zeros!\n');
    elseif all(isnan(rcsSpectrum(:)))
        fprintf('  WARNING: All NaNs!\n');
    else
        fprintf('  Data appears valid\n');
    end
end

fprintf('\n--- TESTING NORMALIZATION ---\n');
if isfield(base_fre1Intraop, 'fooof_powspctrm')
    intraopSpectrum = base_fre1Intraop.fooof_powspctrm(1, :);
    intraopNorm = 100 * intraopSpectrum / sum(intraopSpectrum);
    fprintf('Intraop channel 1 after normalization:\n');
    fprintf('  First 5: %s\n', mat2str(intraopNorm(1:5)));
    fprintf('  Min: %.6f, Max: %.6f, Sum: %.6f\n', ...
        min(intraopNorm), max(intraopNorm), sum(intraopNorm));
    fprintf('  log10 first 5: %s\n', mat2str(log10(intraopNorm(1:5))));
    fprintf('  log10 range: %.3f to %.3f\n', min(log10(intraopNorm)), max(log10(intraopNorm)));
end

if isfield(base_fre1RCSall, 'fooof_powspctrm')
    rcsSpectrum = base_fre1RCSall.fooof_powspctrm{1}{1}(1, :);
    rcsNorm = 100 * rcsSpectrum / sum(rcsSpectrum);
    fprintf('\nRCS session 1 iter 1 channel 1 after normalization:\n');
    fprintf('  First 5: %s\n', mat2str(rcsNorm(1:5)));
    fprintf('  Min: %.6f, Max: %.6f, Sum: %.6f\n', ...
        min(rcsNorm), max(rcsNorm), sum(rcsNorm));
    fprintf('  log10 first 5: %s\n', mat2str(log10(rcsNorm(1:5))));
    fprintf('  log10 range: %.3f to %.3f\n', min(log10(rcsNorm)), max(log10(rcsNorm)));
end

fprintf('\n=== END DIAGNOSTICS ===\n');
