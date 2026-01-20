% Test script to verify FOOOF plotting would work with data
% This creates synthetic FOOOF data and tests the plotting code

fprintf('\n=== Testing FOOOF Plotting Code ===\n\n');

%% Create synthetic FOOOF data structures
fprintf('Creating synthetic FOOOF data...\n');

% Frequency vector for FOOOF (4:0.5:50 Hz)
fooofFreq = 4:0.5:50;
numFreqs = length(fooofFreq);
numChans = 4;

% Create synthetic intraop FOOOF data
base_fre1Intraop = struct();
base_fre1Intraop.label = {'LFPL2-0', 'LFPL3-1', 'ECOGL10-8', 'ECOGL11-9'};
base_fre1Intraop.fooof_freq = fooofFreq;

% Simulate aperiodic fit (1/f-like decay)
base_fre1Intraop.fooof_powspctrm = zeros(numChans, numFreqs);
for chan = 1:numChans
    offset = 2 + rand()*0.5;  % Random offset
    exponent = 1.5 + rand()*0.5;  % Random exponent
    % Create 1/f spectrum: power = 10^(offset - exponent * log10(freq))
    base_fre1Intraop.fooof_powspctrm(chan, :) = 10.^(offset - exponent * log10(fooofFreq));
end

% Create synthetic RCS FOOOF data
base_fre1RCSall = struct();
base_fre1RCSall.fooof_powspctrm{1}{1} = zeros(numChans, numFreqs);
base_fre1RCSall.chans{1}{1} = base_fre1Intraop.label;

for chan = 1:numChans
    offset = 1.8 + rand()*0.5;  % Slightly different offset
    exponent = 1.7 + rand()*0.5;  % Slightly different exponent
    base_fre1RCSall.fooof_powspctrm{1}{1}(chan, :) = 10.^(offset - exponent * log10(fooofFreq));
end

fprintf('Synthetic data created successfully.\n');
fprintf('  Intraop fooof_powspctrm size: %s\n', mat2str(size(base_fre1Intraop.fooof_powspctrm)));
fprintf('  RCS fooof_powspctrm size: %s\n', mat2str(size(base_fre1RCSall.fooof_powspctrm{1}{1})));
fprintf('  Frequency range: %.1f - %.1f Hz (%d points)\n', ...
    min(fooofFreq), max(fooofFreq), numFreqs);

%% Test the plotting code from compare_intraop_rcs.m
fprintf('\n--- Testing FOOOF Spectrum Plot ---\n');

% Determine subplot layout
if numChans == 4
    subplotRows = 2; subplotCols = 2;
elseif numChans == 8
    subplotRows = 4; subplotCols = 2;
else
    subplotRows = ceil(sqrt(numChans));
    subplotCols = ceil(numChans/subplotRows);
end

figFooofSpectrum = figure('Name', 'Test FOOOF Modeled Spectra');

plotsWithData = 0;
plotsEmpty = 0;

for plotIdx = 1:numChans
    subplot(subplotRows, subplotCols, plotIdx)
    chanLabel = base_fre1Intraop.label{plotIdx};

    % Get intraop FOOOF spectrum and normalize to 100%
    intraopSpectrum = base_fre1Intraop.fooof_powspctrm(plotIdx, :);
    intraopNorm = 100 * intraopSpectrum / sum(intraopSpectrum);

    fprintf('Channel %d (%s):\n', plotIdx, chanLabel);
    fprintf('  Intraop spectrum sum: %.2e\n', sum(intraopSpectrum));
    fprintf('  Intraop normalized sum: %.2f%%\n', sum(intraopNorm));

    % Find matching RCS channel
    foundMatch = false;
    for rcsTrial = 1:length(base_fre1RCSall.fooof_powspctrm)
        for iterIdx = 1:length(base_fre1RCSall.fooof_powspctrm{rcsTrial})
            rcsLabels = base_fre1RCSall.chans{rcsTrial}{iterIdx};
            rcsIdx = find(strcmp(rcsLabels, chanLabel));

            if ~isempty(rcsIdx)
                rcsSpectrum = base_fre1RCSall.fooof_powspctrm{rcsTrial}{iterIdx}(rcsIdx, :);
                rcsNorm = 100 * rcsSpectrum / sum(rcsSpectrum);

                fprintf('  RCS spectrum sum: %.2e\n', sum(rcsSpectrum));
                fprintf('  RCS normalized sum: %.2f%%\n', sum(rcsNorm));

                % Check if data has actual values
                if all(isnan(intraopNorm)) || all(isnan(rcsNorm)) || ...
                   all(intraopNorm == 0) || all(rcsNorm == 0)
                    fprintf('  WARNING: Empty or NaN data!\n');
                    plotsEmpty = plotsEmpty + 1;
                else
                    line1 = plot(fooofFreq, log10(rcsNorm), 'b-', 'LineWidth', 1.5);
                    hold on
                    line2 = plot(fooofFreq, log10(intraopNorm), 'r-', 'LineWidth', 1.5);
                    fprintf('  Plot generated successfully.\n');
                    plotsWithData = plotsWithData + 1;
                end

                foundMatch = true;
                break;
            end
        end
        if foundMatch, break; end
    end

    if ~foundMatch
        fprintf('  WARNING: No matching RCS channel found!\n');
    end

    if plotIdx == 1
        xlabel('Frequency (Hz)')
        ylabel('Log Normalized Power (%)')
    end
    title(chanLabel)
    set(gca, 'fontsize', 12)
    if plotIdx == numChans
        legend([line1, line2], {'RCS', 'Intraop'}, 'Location', 'best');
    end
end

sgtitle('Test: FOOOF Modeled Power Spectra (Normalized)')

fprintf('\n--- Test Results ---\n');
fprintf('Plots with data: %d/%d\n', plotsWithData, numChans);
fprintf('Empty plots: %d/%d\n', plotsEmpty, numChans);

if plotsWithData == numChans
    fprintf('\n✓ SUCCESS: All plots have data!\n');
else
    fprintf('\n✗ FAILURE: Some plots are empty!\n');
end

%% Test connected scatter plot
fprintf('\n--- Testing Connected Scatter Plot ---\n');

% Create synthetic statsResultsFooof
statsResultsFooof = struct();
statsResultsFooof.matchedChannels = base_fre1Intraop.label;
statsResultsFooof.intraopExponents = 1.5 + rand(numChans, 1) * 0.5;
statsResultsFooof.rcsExponents = 1.7 + rand(numChans, 1) * 0.5;
statsResultsFooof.intraopOffsets = 2.0 + rand(numChans, 1) * 0.3;
statsResultsFooof.rcsOffsets = 1.8 + rand(numChans, 1) * 0.3;
statsResultsFooof.exponent_p = 0.023;
statsResultsFooof.offset_p = 0.045;

matchedChannels = statsResultsFooof.matchedChannels;
numMatchedPairs = length(matchedChannels);

if numMatchedPairs > 0
    % Color scheme for channel pairs
    channelColors = brewermap(max(numMatchedPairs, 3), 'Set1');

    figFooofScatter = figure('Name', 'Test FOOOF Parameters');

    % Subplot 1: Exponent
    subplot(1,2,1)
    for pairIdx = 1:numMatchedPairs
        x = [1, 2];
        y = [statsResultsFooof.intraopExponents(pairIdx), ...
             statsResultsFooof.rcsExponents(pairIdx)];
        plot(x, y, '-o', 'Color', channelColors(pairIdx,:), ...
             'LineWidth', 1.5, 'MarkerSize', 8, ...
             'MarkerFaceColor', channelColors(pairIdx,:));
        hold on
    end
    xlim([0.5 2.5])
    set(gca, 'XTick', [1 2], 'XTickLabel', {'Intraop', 'RCS'})
    ylabel('Aperiodic Exponent')
    title(['Exponent (p=' sprintf('%.3f', statsResultsFooof.exponent_p) ')'])
    set(gca, 'fontsize', 14)

    % Subplot 2: Offset
    subplot(1,2,2)
    for pairIdx = 1:numMatchedPairs
        x = [1, 2];
        y = [statsResultsFooof.intraopOffsets(pairIdx), ...
             statsResultsFooof.rcsOffsets(pairIdx)];
        plot(x, y, '-o', 'Color', channelColors(pairIdx,:), ...
             'LineWidth', 1.5, 'MarkerSize', 8, ...
             'MarkerFaceColor', channelColors(pairIdx,:));
        hold on
    end
    xlim([0.5 2.5])
    set(gca, 'XTick', [1 2], 'XTickLabel', {'Intraop', 'RCS'})
    ylabel('Aperiodic Offset')
    title(['Offset (p=' sprintf('%.3f', statsResultsFooof.offset_p) ')'])
    legend(matchedChannels, 'Location', 'best')
    set(gca, 'fontsize', 14)

    sgtitle('Test: FOOOF Aperiodic Parameters by Channel')

    fprintf('✓ Connected scatter plot generated successfully.\n');
else
    fprintf('✗ No matched channel pairs found.\n');
end

fprintf('\n=== Test Complete ===\n');
fprintf('If both figures display data, the FOOOF plotting code is working correctly.\n');
