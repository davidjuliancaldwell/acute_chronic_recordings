% Quick test of FOOOF spectrum plot fix
clear all
close all

fprintf('\n=== Testing FOOOF Spectrum Plot Fix ===\n\n');

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

fprintf('Running intraop analysis...\n');
evalc('analyze_intraop');
fprintf('✓ Complete\n\n');

fprintf('Running RCS analysis...\n');
evalc('analyze_rcs');
fprintf('✓ Complete\n\n');

fprintf('Running comparison (with FOOOF plots and debug output)...\n');
compare_intraop_rcs

% Check for FOOOF figures
fprintf('\nChecking for FOOOF spectrum figure...\n');
allFigs = findall(0, 'Type', 'figure');
fooofSpectrumFig = [];
for i = 1:length(allFigs)
    figName = get(allFigs(i), 'Name');
    if contains(figName, 'FOOOF Modeled Spectra')
        fooofSpectrumFig = allFigs(i);
        fprintf('  Found: "%s" (Figure %d)\n', figName, allFigs(i).Number);

        % Check axes and data
        axes_handles = findall(fooofSpectrumFig, 'Type', 'axes');
        axes_handles = axes_handles(~strcmp(get(axes_handles, 'Tag'), 'legend'));
        fprintf('  Number of subplots: %d\n', length(axes_handles));

        % Check first subplot for data
        if ~isempty(axes_handles)
            firstAx = axes_handles(end); % Last one is usually first subplot
            lines = findall(firstAx, 'Type', 'line');
            fprintf('  Subplot 1 has %d line(s)\n', length(lines));

            if ~isempty(lines)
                % Get data from first line
                xdata = get(lines(1), 'XData');
                ydata = get(lines(1), 'YData');
                fprintf('  Line 1: X range [%.1f, %.1f], Y range [%.3f, %.3f]\n', ...
                    min(xdata), max(xdata), min(ydata), max(ydata));

                % Check if data is visible
                ylims = get(firstAx, 'YLim');
                fprintf('  Y-axis limits: [%.3f, %.3f]\n', ylims(1), ylims(2));

                % Check if any data points are within visible range
                inRange = sum((ydata >= ylims(1)) & (ydata <= ylims(2)));
                fprintf('  Data points in visible range: %d/%d\n', inRange, length(ydata));

                if inRange > 0
                    fprintf('  ✓ PLOT HAS VISIBLE DATA!\n');
                else
                    fprintf('  ✗ WARNING: Data outside visible range\n');
                end
            end
        end
    end
end

if isempty(fooofSpectrumFig)
    fprintf('  ✗ FOOOF spectrum figure not found!\n');
end

fprintf('\n=== Test Complete ===\n');
quit
