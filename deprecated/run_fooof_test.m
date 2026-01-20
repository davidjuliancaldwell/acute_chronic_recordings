% Test FOOOF plots after fix
clear all
close all

fprintf('\n=== Testing FOOOF Plots After Fix ===\n\n');

% Setup
setup_rcs

boxEnv = getenv('box_dir');
if isempty(boxEnv)
    error('box_dir environment variable not set');
end

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
saveFigure = 0;
folderFigures = tempdir();
splitPath = cell(1,20);
for i = 1:20, splitPath{i} = 'test'; end

fprintf('Subject: %s\n\n', subj);

fprintf('Step 1: Running intraop analysis...\n');
analyze_intraop
fprintf('✓ Complete\n\n');

fprintf('Step 2: Checking intraop FOOOF data...\n');
fprintf('  fooof_powspctrm size: %s\n', mat2str(size(base_fre1Intraop.fooof_powspctrm)));
fprintf('  Chan 1 values: min=%.3e, max=%.3e\n', min(base_fre1Intraop.fooof_powspctrm(1,:)), max(base_fre1Intraop.fooof_powspctrm(1,:)));
fprintf('  Aperiodic params (chan 1): offset=%.3f, exponent=%.3f\n', ...
    base_fre1Intraop.fooofparams(1).aperiodic_params(1), ...
    base_fre1Intraop.fooofparams(1).aperiodic_params(2));
fprintf('✓ Complete\n\n');

fprintf('Step 3: Running RCS analysis...\n');
analyze_rcs
fprintf('✓ Complete\n\n');

fprintf('Step 4: Checking RCS FOOOF data...\n');
fprintf('  fooof_powspctrm size (sess 1 iter 1): %s\n', mat2str(size(base_fre1RCSall.fooof_powspctrm{1}{1})));
fprintf('  Chan 1 values: min=%.3e, max=%.3e\n', min(base_fre1RCSall.fooof_powspctrm{1}{1}(1,:)), max(base_fre1RCSall.fooof_powspctrm{1}{1}(1,:)));
fprintf('  Aperiodic params (chan 1): offset=%.3f, exponent=%.3f\n', ...
    base_fre1RCSall.fooofparams{1}{1}(1).aperiodic_params(1), ...
    base_fre1RCSall.fooofparams{1}{1}(1).aperiodic_params(2));
fprintf('✓ Complete\n\n');

fprintf('Step 5: Running comparison (generating FOOOF plots)...\n');
compare_intraop_rcs
fprintf('✓ Complete\n\n');

fprintf('Step 6: Verifying FOOOF plots...\n');
allFigs = findall(0, 'Type', 'figure');
fooofSpectrumFig = [];
fooofParamsFig = [];

for i = 1:length(allFigs)
    figName = get(allFigs(i), 'Name');
    if contains(figName, 'FOOOF Modeled Spectra')
        fooofSpectrumFig = allFigs(i);
        fprintf('  Found spectrum figure: "%s" (Figure %d)\n', figName, allFigs(i).Number);
    elseif contains(figName, 'FOOOF Parameters')
        fooofParamsFig = allFigs(i);
        fprintf('  Found params figure: "%s" (Figure %d)\n', figName, allFigs(i).Number);
    end
end

if isempty(fooofSpectrumFig)
    fprintf('  ✗ ERROR: FOOOF spectrum figure not found!\n');
else
    % Check spectrum figure for data
    axes_handles = findall(fooofSpectrumFig, 'Type', 'axes');
    axes_handles = axes_handles(~strcmp(get(axes_handles, 'Tag'), 'legend'));
    fprintf('  Spectrum figure has %d subplot(s)\n', length(axes_handles));

    if ~isempty(axes_handles)
        firstAx = axes_handles(end);
        lines = findall(firstAx, 'Type', 'line');
        fprintf('  Subplot 1 has %d line(s)\n', length(lines));

        if length(lines) >= 2
            % Check both lines
            for lineIdx = 1:2
                xdata = get(lines(lineIdx), 'XData');
                ydata = get(lines(lineIdx), 'YData');
                fprintf('  Line %d: X=[%.1f-%.1f], Y=[%.3f-%.3f]\n', ...
                    lineIdx, min(xdata), max(xdata), min(ydata), max(ydata));

                % Check if data is in visible range
                ylims = get(firstAx, 'YLim');
                inRange = sum((ydata >= ylims(1)) & (ydata <= ylims(2)));
                fprintf('    Data points in view: %d/%d (%.0f%%)\n', inRange, length(ydata), 100*inRange/length(ydata));
            end

            if all(~isnan([lines(1).YData, lines(2).YData]))
                fprintf('  ✓ SPECTRUM PLOT HAS VISIBLE DATA!\n');
            else
                fprintf('  ✗ WARNING: Some NaN values in data\n');
            end
        end
    end
end

if ~isempty(fooofParamsFig)
    axes_handles = findall(fooofParamsFig, 'Type', 'axes');
    axes_handles = axes_handles(~strcmp(get(axes_handles, 'Tag'), 'legend'));
    fprintf('  Params figure has %d subplot(s)\n', length(axes_handles));
    fprintf('  ✓ PARAMS PLOT EXISTS\n');
end

fprintf('\n=== Test Complete ===\n');
fprintf('Summary:\n');
fprintf('  FOOOF spectrum plot: %s\n', ~isempty(fooofSpectrumFig) && length(lines) >= 2);
fprintf('  FOOOF params plot: %s\n', ~isempty(fooofParamsFig));
fprintf('\n');

quit
