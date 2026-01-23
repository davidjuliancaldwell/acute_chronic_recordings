% run this after the data has been processed

% note - you  must check/confirm channel order since the left/right side
% impacts the processing order
% this assumes the data channel order is the same for the RCS and intraop

% intraop ECoG and DBS channels
indicesECOGintra = find(contains(base_fre1Intraop.label,'ECOG'));
indicesLFPintra = find(contains(base_fre1Intraop.label,'LFP'));

indicesECOGintraR = find(contains(base_fre1Intraop.label,'ECOGR'));
indicesECOGintraL = find(contains(base_fre1Intraop.label,'ECOGL'));
indicesLFPintraR = find(contains(base_fre1Intraop.label,'LFPR'));
indicesLFPintraL = find(contains(base_fre1Intraop.label,'LFPL'));

% pick sides to use from intraOp ECoG in case you only have one RC+S side
if strcmp(sidesToUse,'r')
    indicesECOGintra = indicesECOGintraR;
    indicesLFPintra = indicesLFPintraR;

elseif strcmp(sidesToUse,'l')
    indicesECOGintra = indicesECOGintraL;
    indicesLFPintra = indicesLFPintraL;

end

% RC+S ECoG and DBS channels - collapse and average for channel wise
% statistics , permutation later
base_fre1RCScollapse = {};

% Bug #29 fix: Add empty cell guard
if ~isempty(base_fre1RCSall.chans) && ~isempty(base_fre1RCSall.chans{1})
    base_fre1RCScollapse.averagedBins = [squeeze(mean(cell2mat(base_fre1RCSall.averagedBins{1}),1))];
    % Bug #22 fix: Wrap {:} expansion to properly concatenate all iterations
    base_fre1RCScollapse.label = [base_fre1RCSall.chans{1}{:}];
    base_fre1RCScollapse.normalizedPow = [squeeze(mean(cell2mat(base_fre1RCSall.normalizedPow{1}),1))];
    base_fre1RCScollapse.powspctrm = [squeeze(mean(cell2mat(base_fre1RCSall.powspctrm{1}),1))];

    if length(base_fre1RCSall.averagedBins) > 1
        for rcsTrial = 2:length(base_fre1RCSall.averagedBins)
            base_fre1RCScollapse.averagedBins = [base_fre1RCScollapse.averagedBins;squeeze(mean(cell2mat(base_fre1RCSall.averagedBins{rcsTrial}),1))];
            % Bug #22 fix: Wrap {:} expansion
            base_fre1RCScollapse.label = [base_fre1RCScollapse.label [base_fre1RCSall.chans{rcsTrial}{:}]];
            base_fre1RCScollapse.normalizedPow = [base_fre1RCScollapse.normalizedPow; squeeze(mean(cell2mat(base_fre1RCSall.normalizedPow{rcsTrial}),1))];
            base_fre1RCScollapse.powspctrm = [base_fre1RCScollapse.powspctrm; squeeze(mean(cell2mat(base_fre1RCSall.powspctrm{rcsTrial}),1))];
        end
    end
else
    warning('No RCS data available in base_fre1RCSall.chans');
end

% Use region prefix detection (consistent with how intraop channels are identified)
% '+' characters are stripped in analyze_rcs.m, so use 'ECOG' prefix instead
indicesECOGRCS = find(contains(base_fre1RCScollapse.label, 'ECOG'));
indicesLFPRCS = find(contains(base_fre1RCScollapse.label, 'LFP'));

% collapse across ECoG
base_fre1Intraop_avg.averagedBins = squeeze(mean(base_fre1Intraop.averagedBins,1));
base_fre1Intraop_avg.normalizedPow = squeeze(mean(base_fre1Intraop.normalizedPow,1));
%%
% need to make sure that the order of the RCS being read in matches the
% ECoG, with left then right being loaded in initially in setup RCS
if signedRankTest
    fprintf('Running signed rank test with label-matched channels...\n');

    % Match ECoG channels by label
    rcsECOGLabels = base_fre1RCScollapse.label(indicesECOGRCS);
    matchedECOGIndicesRCS = [];
    matchedECOGIndicesIntra = [];

    for i = 1:length(rcsECOGLabels)
        matchIdx = find(strcmp(base_fre1Intraop_avg.label, rcsECOGLabels{i}));
        if ~isempty(matchIdx)
            matchedECOGIndicesRCS(end+1) = indicesECOGRCS(i);
            matchedECOGIndicesIntra(end+1) = matchIdx;
        end
    end

    % Match LFP channels by label
    rcsLFPLabels = base_fre1RCScollapse.label(indicesLFPRCS);
    matchedLFPIndicesRCS = [];
    matchedLFPIndicesIntra = [];

    for i = 1:length(rcsLFPLabels)
        matchIdx = find(strcmp(base_fre1Intraop_avg.label, rcsLFPLabels{i}));
        if ~isempty(matchIdx)
            matchedLFPIndicesRCS(end+1) = indicesLFPRCS(i);
            matchedLFPIndicesIntra(end+1) = matchIdx;
        end
    end

    fprintf('  Matched %d ECoG channels, %d LFP channels\n', length(matchedECOGIndicesRCS), length(matchedLFPIndicesRCS));

    % Signed rank test for matched ECoG channels
    if ~isempty(matchedECOGIndicesRCS)
        for index = 1:size(base_fre1RCScollapse.averagedBins,2)
            [p,h,stats] = signrank(base_fre1RCScollapse.averagedBins(matchedECOGIndicesRCS,index), ...
                                    base_fre1Intraop_avg.averagedBins(matchedECOGIndicesIntra,index));
            statsResults.pECOG(index)=p;
            statsResults.hECOG(index)=h;
            statsResults.statsECOG(index) = stats;
        end
    else
        warning('No matched ECoG channels for signed rank test');
    end

    % Signed rank test for matched LFP channels
    if ~isempty(matchedLFPIndicesRCS)
        for index = 1:size(base_fre1RCScollapse.averagedBins,2)
            [p,h,stats] = signrank(base_fre1RCScollapse.averagedBins(matchedLFPIndicesRCS,index), ...
                                    base_fre1Intraop_avg.averagedBins(matchedLFPIndicesIntra,index));
            statsResults.pLFP(index)=p;
            statsResults.hLFP(index)=h;
            statsResults.statsLFP(index) = stats;
        end
    else
        warning('No matched LFP channels for signed rank test');
    end

elseif rankSumTest
    % rank sum test across channels
    for index = 1:size(base_fre1RCScollapse.averagedBins,2)
        [p,h,stats] = ranksum(base_fre1RCScollapse.averagedBins(indicesECOGRCS,index),base_fre1Intraop_avg.averagedBins(indicesECOGintra,index));
        statsResults.pECOG(index)=p;
        statsResults.hECOG(index)=h;
        statsResults.statsECOG(index) = stats;
    end

    for index = 1:size(base_fre1RCScollapse.averagedBins,2)
        [p,h,stats] = ranksum(base_fre1RCScollapse.averagedBins(indicesLFPRCS,index),base_fre1Intraop_avg.averagedBins(indicesLFPintra,index));
        statsResults.pLFP(index)=p;
        statsResults.hLFP(index)=h;
        statsResults.statsLFP(index) = stats;
    end
end

if permute_test
    % Match channels by label between intraop and RCS data
    % Iterate through all RCS sessions and match with corresponding intraop channels

    % Initialize storage for matched channel results
    statsResultsPerm.p = [];
    statsResultsPerm.diff = [];
    statsResultsPerm.effect = [];
    statsResultsPerm.channelPairs = {}; % Store matched channel labels
    statsResultsPerm.rcsLabels = {};
    statsResultsPerm.intraopLabels = {};

    matchedPairCount = 0;

    % Loop through all RCS sessions
    for rcsTrial = 1:length(base_fre1RCSall.averagedBins)
        % Skip empty sessions (failed to process)
        if isempty(base_fre1RCSall.averagedBins{rcsTrial}) || ...
           isempty(base_fre1RCSall.chans{rcsTrial})
            fprintf('Skipping RCS session %d (no data - processing likely failed)\n', rcsTrial);
            continue;
        end

        samps_rcs_cell = cell2mat(base_fre1RCSall.averagedBins{rcsTrial});
        % Bug #22 fix: Wrap {:} expansion to properly concatenate iterations
        rcsLabels = [base_fre1RCSall.chans{rcsTrial}{:}];

        % For each RCS channel, find matching intraop channel by label
        for rcsIdx = 1:length(rcsLabels)
            rcsLabel = rcsLabels{rcsIdx};

            % Find matching intraop channel (should have same label after our naming changes)
            matchIdx = find(strcmp(base_fre1Intraop.label, rcsLabel));

            if ~isempty(matchIdx)
                % Found a match! Perform permutation test for each frequency bin
                matchedPairCount = matchedPairCount + 1;

                for freqBin = 1:size(base_fre1Intraop.averagedBins,3)
                    samps_rcs = squeeze(samps_rcs_cell(:,rcsIdx,freqBin));
                    samps_intra = squeeze(base_fre1Intraop.averagedBins(:,matchIdx,freqBin));
                    [p_val,observed_diff,effect_size] = permutationTest(samps_rcs,samps_intra, 10000);

                    statsResultsPerm.p(freqBin,matchedPairCount) = p_val;
                    statsResultsPerm.diff(freqBin,matchedPairCount) = observed_diff;
                    statsResultsPerm.effect(freqBin,matchedPairCount) = effect_size;
                end

                % Store the channel pair information
                statsResultsPerm.channelPairs{matchedPairCount} = rcsLabel;
                statsResultsPerm.rcsLabels{matchedPairCount} = rcsLabel;
                statsResultsPerm.intraopLabels{matchedPairCount} = base_fre1Intraop.label{matchIdx};
            else
                warning(['No matching intraop channel found for RCS channel: ' rcsLabel]);
            end
        end
    end

    % Calculate Bonferroni correction threshold
    % Total number of tests = number of frequency bins × number of matched channel pairs
    numTests = size(statsResultsPerm.p,1) * size(statsResultsPerm.p,2);
    statsResultsPerm.bonferroniThreshold = 0.05 / numTests;
    statsResultsPerm.numTests = numTests;
    statsResultsPerm.numMatchedPairs = matchedPairCount;

    fprintf('Permutation testing completed:\n');
    fprintf('  Number of matched channel pairs: %d\n', matchedPairCount);
    fprintf('  Number of frequency bins: %d\n', size(statsResultsPerm.p,1));
    fprintf('  Total tests performed: %d\n', numTests);
    fprintf('  Bonferroni-corrected alpha: %.6f\n', statsResultsPerm.bonferroniThreshold);
end

%% FOOOF Parameter Comparison (Signed Rank - Paired)
if signedRankTest && isfield(base_fre1Intraop, 'fooofparams') && isfield(base_fre1RCSall, 'fooofparams')
    fprintf('\n--- FOOOF Parameter Comparison (Signed Rank) ---\n');

    % Match channels between intraop and RCS by label for paired test
    intraopExponents = [];
    intraopOffsets = [];
    rcsExponents = [];
    rcsOffsets = [];
    matchedChannels = {};

    % Loop through RCS sessions and match with intraop
    for rcsTrial = 1:length(base_fre1RCSall.fooofparams)
        for iterIdx = 1:length(base_fre1RCSall.fooofparams{rcsTrial})
            rcsParams = base_fre1RCSall.fooofparams{rcsTrial}{iterIdx};
            rcsLabels = base_fre1RCSall.chans{rcsTrial}{iterIdx};

            for rcsIdx = 1:length(rcsParams)
                rcsLabel = rcsLabels{rcsIdx};

                % Find matching intraop channel by label
                intraopIdx = find(strcmp(base_fre1Intraop.label, rcsLabel));

                if ~isempty(intraopIdx)
                    % Found a match - collect both parameters for paired comparison
                    rcsExponents(end+1) = rcsParams(rcsIdx).aperiodic_params(2);
                    rcsOffsets(end+1) = rcsParams(rcsIdx).aperiodic_params(1);
                    intraopExponents(end+1) = base_fre1Intraop.fooofparams(intraopIdx).aperiodic_params(2);
                    intraopOffsets(end+1) = base_fre1Intraop.fooofparams(intraopIdx).aperiodic_params(1);
                    matchedChannels{end+1} = rcsLabel;
                end
            end
        end
    end

    fprintf('Matched %d channel pairs for FOOOF comparison\n', length(matchedChannels));

    if length(matchedChannels) > 0
        % Signed rank test for paired samples (matched channels)
        [p_exp, ~] = signrank(intraopExponents, rcsExponents);
        fprintf('Exponent: Intraop mean=%.3f, RCS mean=%.3f, p=%.4f\n', ...
            mean(intraopExponents), mean(rcsExponents), p_exp);

        [p_off, ~] = signrank(intraopOffsets, rcsOffsets);
        fprintf('Offset: Intraop mean=%.3f, RCS mean=%.3f, p=%.4f\n', ...
            mean(intraopOffsets), mean(rcsOffsets), p_off);

        % Store results
        statsResultsFooof.exponent_p = p_exp;
        statsResultsFooof.offset_p = p_off;
        statsResultsFooof.intraopExponents = intraopExponents;
        statsResultsFooof.rcsExponents = rcsExponents;
        statsResultsFooof.intraopOffsets = intraopOffsets;
        statsResultsFooof.rcsOffsets = rcsOffsets;
        statsResultsFooof.matchedChannels = matchedChannels;

        % Create FOOOF Parameter Plots
        figure('Name', 'FOOOF Parameters (Signed Rank)');

        subplot(1,2,1)
        bar([mean(intraopExponents), mean(rcsExponents)])
        hold on
        errorbar([1 2], [mean(intraopExponents), mean(rcsExponents)], ...
            [std(intraopExponents)/sqrt(length(intraopExponents)), ...
             std(rcsExponents)/sqrt(length(rcsExponents))], 'k.')
        set(gca, 'XTickLabel', {'Intraop', 'RCS'})
        ylabel('Aperiodic Exponent')
        title([subj ' Exponent (p=' sprintf('%.3f', statsResultsFooof.exponent_p) ')'])

        subplot(1,2,2)
        bar([mean(intraopOffsets), mean(rcsOffsets)])
        hold on
        errorbar([1 2], [mean(intraopOffsets), mean(rcsOffsets)], ...
            [std(intraopOffsets)/sqrt(length(intraopOffsets)), ...
             std(rcsOffsets)/sqrt(length(rcsOffsets))], 'k.')
        set(gca, 'XTickLabel', {'Intraop', 'RCS'})
        ylabel('Aperiodic Offset')
        title([subj ' Offset (p=' sprintf('%.3f', statsResultsFooof.offset_p) ')'])
    end
end

%% FOOOF Parameter Comparison (Rank Sum - Unpaired)
if rankSumTest && isfield(base_fre1Intraop, 'fooofparams') && isfield(base_fre1RCSall, 'fooofparams')
    fprintf('\n--- FOOOF Parameter Comparison (Rank Sum - Unpaired) ---\n');

    % Collect all channels without matching
    allIntraopExponents = [];
    allIntraopOffsets = [];
    for chanIdx = 1:length(base_fre1Intraop.fooofparams)
        allIntraopExponents(chanIdx) = base_fre1Intraop.fooofparams(chanIdx).aperiodic_params(2);
        allIntraopOffsets(chanIdx) = base_fre1Intraop.fooofparams(chanIdx).aperiodic_params(1);
    end

    allRcsExponents = [];
    allRcsOffsets = [];
    for rcsTrial = 1:length(base_fre1RCSall.fooofparams)
        for iterIdx = 1:length(base_fre1RCSall.fooofparams{rcsTrial})
            params = base_fre1RCSall.fooofparams{rcsTrial}{iterIdx};
            for chanIdx = 1:length(params)
                allRcsExponents(end+1) = params(chanIdx).aperiodic_params(2);
                allRcsOffsets(end+1) = params(chanIdx).aperiodic_params(1);
            end
        end
    end

    [p_exp_ranksum, ~] = ranksum(allIntraopExponents, allRcsExponents);
    fprintf('Exponent: Intraop mean=%.3f, RCS mean=%.3f, p=%.4f\n', ...
        mean(allIntraopExponents), mean(allRcsExponents), p_exp_ranksum);

    [p_off_ranksum, ~] = ranksum(allIntraopOffsets, allRcsOffsets);
    fprintf('Offset: Intraop mean=%.3f, RCS mean=%.3f, p=%.4f\n', ...
        mean(allIntraopOffsets), mean(allRcsOffsets), p_off_ranksum);

    % Store results
    statsResultsFooof.exponent_p_ranksum = p_exp_ranksum;
    statsResultsFooof.offset_p_ranksum = p_off_ranksum;
    statsResultsFooof.intraopExponentsAll = allIntraopExponents;
    statsResultsFooof.rcsExponentsAll = allRcsExponents;
    statsResultsFooof.intraopOffsetsAll = allIntraopOffsets;
    statsResultsFooof.rcsOffsetsAll = allRcsOffsets;

    % Create FOOOF Parameter Plots for unpaired
    figure('Name', 'FOOOF Parameters (Rank Sum)');

    subplot(1,2,1)
    bar([mean(allIntraopExponents), mean(allRcsExponents)])
    hold on
    errorbar([1 2], [mean(allIntraopExponents), mean(allRcsExponents)], ...
        [std(allIntraopExponents)/sqrt(length(allIntraopExponents)), ...
         std(allRcsExponents)/sqrt(length(allRcsExponents))], 'k.')
    set(gca, 'XTickLabel', {'Intraop', 'RCS'})
    ylabel('Aperiodic Exponent')
    title([subj ' Exponent (p=' sprintf('%.3f', statsResultsFooof.exponent_p_ranksum) ')'])

    subplot(1,2,2)
    bar([mean(allIntraopOffsets), mean(allRcsOffsets)])
    hold on
    errorbar([1 2], [mean(allIntraopOffsets), mean(allRcsOffsets)], ...
        [std(allIntraopOffsets)/sqrt(length(allIntraopOffsets)), ...
         std(allRcsOffsets)/sqrt(length(allRcsOffsets))], 'k.')
    set(gca, 'XTickLabel', {'Intraop', 'RCS'})
    ylabel('Aperiodic Offset')
    title([subj ' Offset (p=' sprintf('%.3f', statsResultsFooof.offset_p_ranksum) ')'])
end

%% FOOOF Modeled Power Spectrum Plots (Per-Channel)
if isfield(base_fre1Intraop, 'fooof_powspctrm') && isfield(base_fre1RCSall, 'fooof_powspctrm')

    % Frequency vector for FOOOF
    fooofFreq = base_fre1Intraop.fooof_freq;

    % Determine subplot layout
    numChans = length(base_fre1Intraop.label);
    if numChans == 4
        subplotRows = 2; subplotCols = 2;
    elseif numChans == 8
        subplotRows = 4; subplotCols = 2;
    else
        subplotRows = ceil(sqrt(numChans));
        subplotCols = ceil(numChans/subplotRows);
    end

    figFooofSpectrum = figure('Name', [subj ' FOOOF Modeled Spectra']);

    for plotIdx = 1:numChans
        subplot(subplotRows, subplotCols, plotIdx)
        chanLabel = base_fre1Intraop.label{plotIdx};

        % Get intraop FOOOF spectrum and normalize to 100%
        intraopSpectrum = base_fre1Intraop.fooof_powspctrm(plotIdx, :);
        intraopSum = nansum(intraopSpectrum);
        intraopNorm = 100 * intraopSpectrum / intraopSum;

        % Find matching RCS channel
        foundMatch = false;
        for rcsTrial = 1:length(base_fre1RCSall.fooof_powspctrm)
            for iterIdx = 1:length(base_fre1RCSall.fooof_powspctrm{rcsTrial})
                rcsLabels = base_fre1RCSall.chans{rcsTrial}{iterIdx};
                rcsIdx = find(strcmp(rcsLabels, chanLabel));

                if ~isempty(rcsIdx)
                    rcsSpectrum = base_fre1RCSall.fooof_powspctrm{rcsTrial}{iterIdx}(rcsIdx, :);
                    rcsSum = nansum(rcsSpectrum);
                    rcsNorm = 100 * rcsSpectrum / rcsSum;

                    % Plot log of normalized power (data is in LINEAR scale)
                    line1 = plot(fooofFreq, log10(rcsNorm), 'b-', 'LineWidth', 1.5);
                    hold on
                    line2 = plot(fooofFreq, log10(intraopNorm), 'r-', 'LineWidth', 1.5);
                    grid on
                    foundMatch = true;
                    break;
                end
            end
            if foundMatch, break; end
        end

        if plotIdx == 1
            xlabel('Frequency (Hz)')
            ylabel('Log_{10} Normalized Power (%)')
        end
        title(chanLabel)
        set(gca, 'fontsize', 12)
        if plotIdx == numChans && foundMatch
            legend([line1, line2], {'RCS', 'Intraop'}, 'Location', 'best');
        end
    end

    sgtitle([subj ' FOOOF Modeled Power Spectra (Normalized)'])

    if saveFigure
        tempFig = gcf;
        tempFig.Position = [300 300 1200 800];
        exportgraphics(tempFig, fullfile(folderFigures, [subj '_FOOOF_spectra.png']), 'Resolution', 600)
        exportgraphics(tempFig, fullfile(folderFigures, [subj '_FOOOF_spectra.eps']))
    end
end

%% FOOOF Exponent/Offset Connected Scatter Plots
if exist('statsResultsFooof', 'var') && isfield(statsResultsFooof, 'matchedChannels')

    matchedChannels = statsResultsFooof.matchedChannels;
    numMatchedPairs = length(matchedChannels);

    if numMatchedPairs > 0
        % Color scheme for channel pairs
        channelColors = brewermap(max(numMatchedPairs, 3), 'Set1');

        figFooofScatter = figure('Name', [subj ' FOOOF Parameters']);

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

        sgtitle([subj ' FOOOF Aperiodic Parameters by Channel'])

        if saveFigure
            tempFig = gcf;
            tempFig.Position = [300 300 1000 500];
            exportgraphics(tempFig, fullfile(folderFigures, [subj '_FOOOF_scatter.png']), 'Resolution', 600)
            exportgraphics(tempFig, fullfile(folderFigures, [subj '_FOOOF_scatter.eps']))
        end
    end
end

if rankSumTest
    statsCell{subjNum} = statsResults;
end

if permute_test
    statsCellPerm{subjNum} = statsResultsPerm;
end
%%
% plot mean + SEM of frequency spectrum
fig1 = figure;
subplot(2,1,1)
line1 = stdshade(log10(base_fre1RCScollapse.normalizedPow(indicesECOGRCS,:)),0.5,'b');
hold on
line2 = stdshade(log10(base_fre1Intraop_avg.normalizedPow(indicesECOGintra,:)),0.5,'r');
xlabel('Frequency (Hz)')
ylabel('Log Percentage of Total Power')
title([subj ' Comparison between normalized RC+S and Intraoperative NeuroOmega data for ECoG Channels'])

% make shaded regions of different frequency regions
freqEdgesPlot = [4 8;8 12; 13 20;20 30;50 125];
ylims = ylim;
minVal = ylims(1);
maxVal = ylims(2);
colormapPatch = brewermap(size(freqEdgesPlot,1),'PuBu');
for index = 1:size(freqEdgesPlot,1)
    xVals = [freqEdgesPlot(index,1) freqEdgesPlot(index,2) freqEdgesPlot(index,2) freqEdgesPlot(index,1)];
    yVals = [minVal minVal maxVal maxVal];
    patch(xVals,yVals,colormapPatch(index,:),'FaceAlpha',0.2)
end

%
if (rankSumTest || signedRankTest) && exist('statsResults','var')
    % significance stars
    for index=1:5
        if statsResults.pECOG(index)<=0.05
            scatter((freqEdgesPlot(index,2)+freqEdgesPlot(index,1))/2,maxVal-0.25,100,'k*'); %adds a marker
        end
    end
end

legend([line1,line2],{'RC+S','Intraoperative NeuroOmega'});
set(gca,'fontsize',16)

subplot(2,1,2)
line1 = stdshade(log10(base_fre1RCScollapse.normalizedPow(indicesLFPRCS,:)),0.5,'b');
hold on
line2 = stdshade(log10(base_fre1Intraop_avg.normalizedPow(indicesLFPintra,:)),0.5,'r');
xlabel('Frequency (Hz)')
ylabel('Log Percentage of Total Power')
title([subj ' Comparison between normalized RC+S and Intraoperative NeuroOmega data for LFP signals from DBS Channels'])

%
if (rankSumTest || signedRankTest) && exist('statsResults','var')
    % significance stars
    for index=1:5
        if statsResults.pLFP(index)<=0.05
            scatter((freqEdgesPlot(index,2)+freqEdgesPlot(index,1))/2,maxVal-0.25,100,'k*'); %adds a marker
        end
    end
end

set(gca,'fontsize',16)

% make shaded regions of different frequency regions
freqEdgesPlot = [4 8;8 12; 13 20;20 30;50 125];
ylims = ylim;
minVal = ylims(1);
maxVal = ylims(2);
colormapPatch = brewermap(size(freqEdgesPlot,1),'PuBu');
for index = 1:size(freqEdgesPlot,1)

    xVals = [freqEdgesPlot(index,1) freqEdgesPlot(index,2) freqEdgesPlot(index,2) freqEdgesPlot(index,1)];
    yVals = [minVal minVal maxVal maxVal];
    patch(xVals,yVals,colormapPatch(index,:),'FaceAlpha',0.2)
end

legend([line1,line2],{'RC+S','Intraoperative NeuroOmega'});

%%
if saveFigure
    tempFig = gcf;
    tempFig.Position = [305 249 1009 768];
    exportgraphics(tempFig,fullfile(folderFigures,[subj '_compare_ECoG_LFP_' splitPath{10} '_' splitPath{11} '.png']),'Resolution',600)
    exportgraphics(tempFig,fullfile(folderFigures,[subj '_compare_ECoG_LFP_' splitPath{10} '_' splitPath{11} '.eps']))
end

%% Individual channel plots with significance marking
% First find all matched channels
matchedChannelsPlot = {};
matchedIntraopIdxPlot = [];
matchedRCSDataPlot = {};

for intraopIdx = 1:length(base_fre1Intraop.label)
    chanLabel = base_fre1Intraop.label{intraopIdx};

    % Find matching RCS channel
    foundMatch = false;
    for rcsTrial = 1:length(base_fre1RCSall.normalizedPow)
        if isempty(base_fre1RCSall.normalizedPow{rcsTrial}), continue; end

        % Bug #22 fix: Wrap {:} expansion to properly concatenate iterations
        rcsLabels = [base_fre1RCSall.chans{rcsTrial}{:}];
        rcsIdx = find(strcmp(rcsLabels, chanLabel));

        if ~isempty(rcsIdx)
            matchedChannelsPlot{end+1} = chanLabel;
            matchedIntraopIdxPlot(end+1) = intraopIdx;
            matchedRCSDataPlot{end+1} = struct('rcsTrial', rcsTrial, 'rcsIdx', rcsIdx);
            foundMatch = true;
            break;
        end
    end
end

numMatchedPlot = length(matchedChannelsPlot);
fprintf('Individual channel plots: Found %d matched channels\n', numMatchedPlot);

if numMatchedPlot > 0
    % Determine subplot layout based on matched channels
    if numMatchedPlot == 1
        subplotRows = 1; subplotCols = 1;
    elseif numMatchedPlot == 2
        subplotRows = 1; subplotCols = 2;
    elseif numMatchedPlot <= 4
        subplotRows = 2; subplotCols = 2;
    elseif numMatchedPlot <= 8
        subplotRows = 2; subplotCols = 4;
    else
        subplotRows = ceil(sqrt(numMatchedPlot));
        subplotCols = ceil(numMatchedPlot/subplotRows);
    end

    fig3 = figure;
    freqEdgesPlot = [4 8;8 12; 13 20;20 30;50 125];

    for plotIdx = 1:numMatchedPlot
        subplot(subplotRows, subplotCols, plotIdx)

        chanLabel = matchedChannelsPlot{plotIdx};
        intraopIdx = matchedIntraopIdxPlot(plotIdx);
        rcsData = matchedRCSDataPlot{plotIdx};

        % Use pre-matched RCS data directly
        rcsTrial = rcsData.rcsTrial;
        rcsIdx = rcsData.rcsIdx;
        rcs_data_interest = base_fre1RCSall.normalizedPow{rcsTrial}{:};

        line1 = stdshade(log10(squeeze(rcs_data_interest(:,rcsIdx,:))),0.5,'b');
        hold on
        line2 = stdshade(log10(squeeze(base_fre1Intraop.normalizedPow(:,intraopIdx,:))),0.5,'r');

        if plotIdx == 1
            xlabel('Frequency (Hz)')
            ylabel('Log Percentage of Total Power')
        end
        title([subj ' Intraop vs. RC+S ' chanLabel])

        % Get ylim values first for significance stars and patches
        ylims = ylim;
        minVal = ylims(1);
        maxVal = ylims(2);

        % Add Bonferroni-corrected significance stars
        if permute_test && exist('statsResultsPerm','var')
            chanIdx = find(strcmp(statsResultsPerm.channelPairs, chanLabel));
            if ~isempty(chanIdx)
                for freqBin = 1:size(freqEdgesPlot,1)
                    if statsResultsPerm.p(freqBin,chanIdx) < statsResultsPerm.bonferroniThreshold
                        scatter((freqEdgesPlot(freqBin,2)+freqEdgesPlot(freqBin,1))/2, maxVal-0.15, 100, 'k*');
                    end
                end
            end
        end

        % make shaded regions of different frequency regions
        colormapPatch = brewermap(size(freqEdgesPlot,1),'PuBu');
        for index = 1:size(freqEdgesPlot,1)
            xVals = [freqEdgesPlot(index,1) freqEdgesPlot(index,2) freqEdgesPlot(index,2) freqEdgesPlot(index,1)];
            yVals = [minVal minVal maxVal maxVal];
            patch(xVals,yVals,colormapPatch(index,:),'FaceAlpha',0.2)
        end

        if plotIdx == 1
            legend([line1,line2],{'RC+S','Intraoperative NeuroOmega'});
        end
        set(gca,'fontsize',16)
    end
end

%%
% Bug #37 fix: Remove hardcoded saveFigure override - respect value from master script
if saveFigure
    tempFig = gcf;
    tempFig.Position = [300 300 1800 768];
    exportgraphics(tempFig,fullfile(folderFigures,[subj 'indChans_compare_ECoG_LFP_' splitPath{10} '_' splitPath{11} '.png']),'Resolution',600)
    exportgraphics(tempFig,fullfile(folderFigures,[subj 'indChans_compare_ECoG_LFP_' splitPath{10} '_' splitPath{11} '.eps']))
end


%%
% Bug #37 fix: Remove hardcoded saveFigure override
if saveFigure
    tempFig = gcf;
    tempFig.Position = [300 300 1800 768];
    exportgraphics(tempFig,fullfile(folderFigures,[subj 'indChansNotNormalized_compare_ECoG_LFP_' splitPath{10} '_' splitPath{11} '.png']),'Resolution',600)
    exportgraphics(tempFig,fullfile(folderFigures,[subj 'indChansNotNormalized_compare_ECoG_LFP_' splitPath{10} '_' splitPath{11} '.eps']))
end




