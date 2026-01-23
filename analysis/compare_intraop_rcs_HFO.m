% run this after the data has been processed

% intraop ECoG and DBS channels - find all, then filter by hemisphere
indicesECOGintraL = find(contains(base_fre1Intraop.label,'ECOGL'));
indicesECOGintraR = find(contains(base_fre1Intraop.label,'ECOGR'));
indicesLFPintraL = find(contains(base_fre1Intraop.label,'LFPL'));
indicesLFPintraR = find(contains(base_fre1Intraop.label,'LFPR'));

% Filter by hemisphere if unilateral data
if strcmp(sidesToUse,'b')
    % Bilateral - use all channels
    indicesECOGintra = [indicesECOGintraL indicesECOGintraR];
    indicesLFPintra = [indicesLFPintraL indicesLFPintraR];
elseif strcmp(sidesToUse,'r')
    % Right hemisphere only
    indicesECOGintra = indicesECOGintraR;
    indicesLFPintra = indicesLFPintraR;
elseif strcmp(sidesToUse,'l')
    % Left hemisphere only
    indicesECOGintra = indicesECOGintraL;
    indicesLFPintra = indicesLFPintraL;
end


% RC+S ECoG and DBS channels - collapse and average for channel wise
% statistics, permutation later
base_fre1RCScollapse = {};

base_fre1RCScollapse.averagedBins = [squeeze(mean(cell2mat(base_fre1RCSall.averagedBins{1}),1))];
base_fre1RCScollapse.label = [base_fre1RCSall.chans{1}{:}];
base_fre1RCScollapse.normalizedPow = [squeeze(mean(cell2mat(base_fre1RCSall.normalizedPow{1}),1))];
if isfield(base_fre1RCSall,'powspctrm')
    base_fre1RCScollapse.powspctrm = [squeeze(mean(cell2mat(base_fre1RCSall.powspctrm{1}),1))];
end

if length(base_fre1RCSall.averagedBins) > 1
    for rcsTrial = 2:length(base_fre1RCSall.averagedBins)
        base_fre1RCScollapse.averagedBins = [base_fre1RCScollapse.averagedBins;squeeze(mean(cell2mat(base_fre1RCSall.averagedBins{rcsTrial}),1))];
        base_fre1RCScollapse.label = [base_fre1RCScollapse.label base_fre1RCSall.chans{rcsTrial}{:}];
        base_fre1RCScollapse.normalizedPow = [base_fre1RCScollapse.normalizedPow; squeeze(mean(cell2mat(base_fre1RCSall.normalizedPow{rcsTrial}),1))];
        if isfield(base_fre1RCSall,'powspctrm')
            base_fre1RCScollapse.powspctrm = [base_fre1RCScollapse.powspctrm; squeeze(mean(cell2mat(base_fre1RCSall.powspctrm{rcsTrial}),1))];
        end
    end
end

indicesECOGRCS = find(contains(base_fre1RCScollapse.label,'ECOG'));
indicesLFPRCS = find(contains(base_fre1RCScollapse.label,'LFP'));

% Channel-by-channel permutation test
if permute_test
    % Match channels by label between intraop and RCS data
    statsResultsPerm.p = [];
    statsResultsPerm.diff = [];
    statsResultsPerm.effect = [];
    statsResultsPerm.channelPairs = {};

    matchedPairCount = 0;

    % Loop through all RCS sessions
    numSessions = length(base_fre1RCSall.averagedBins);
    fprintf('Found %d RCS sessions to process\n', numSessions);

    for rcsTrial = 1:numSessions
        % Skip empty or undefined sessions (failed to process)
        if rcsTrial > length(base_fre1RCSall.averagedBins) || ...
           isempty(base_fre1RCSall.averagedBins{rcsTrial}) || ...
           rcsTrial > length(base_fre1RCSall.chans) || ...
           isempty(base_fre1RCSall.chans{rcsTrial})
            fprintf('  Session %d: Skipping (no data - processing likely failed)\n', rcsTrial);
            continue;
        end

        fprintf('  Session %d: Processing...\n', rcsTrial);
        samps_rcs_cell = cell2mat(base_fre1RCSall.averagedBins{rcsTrial});
        rcsLabels = base_fre1RCSall.chans{rcsTrial}{:};
        fprintf('    Found %d channels, data dimensions: [%s]\n', length(rcsLabels), num2str(size(samps_rcs_cell)));

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

                statsResultsPerm.channelPairs{matchedPairCount} = rcsLabel;
            end
        end
    end

    % Calculate Bonferroni correction
    numTests = size(statsResultsPerm.p,1) * size(statsResultsPerm.p,2);
    statsResultsPerm.bonferroniThreshold = 0.05 / numTests;

    statsCell{subjNum} = statsResultsPerm;
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
    else
        fprintf('No matched channels found for paired FOOOF comparison.\n');
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
end

%% FOOOF Parameter Plots
if exist('statsResultsFooof', 'var')
    % Determine which test was run and use appropriate field
    if isfield(statsResultsFooof, 'exponent_p')
        % Signed rank (paired) results
        pExp = statsResultsFooof.exponent_p;
        pOff = statsResultsFooof.offset_p;
        expIntraop = statsResultsFooof.intraopExponents;
        expRCS = statsResultsFooof.rcsExponents;
        offIntraop = statsResultsFooof.intraopOffsets;
        offRCS = statsResultsFooof.rcsOffsets;
        titleSuffix = 'Signed Rank';
    elseif isfield(statsResultsFooof, 'exponent_p_ranksum')
        % Rank sum (unpaired) results
        pExp = statsResultsFooof.exponent_p_ranksum;
        pOff = statsResultsFooof.offset_p_ranksum;
        expIntraop = statsResultsFooof.intraopExponentsAll;
        expRCS = statsResultsFooof.rcsExponentsAll;
        offIntraop = statsResultsFooof.intraopOffsetsAll;
        offRCS = statsResultsFooof.rcsOffsetsAll;
        titleSuffix = 'Rank Sum';
    else
        return;  % No results to plot
    end

    figure('Name', ['FOOOF Parameters HFO - ' titleSuffix]);

    subplot(1,2,1)
    bar([mean(expIntraop), mean(expRCS)])
    hold on
    errorbar([1 2], [mean(expIntraop), mean(expRCS)], ...
        [std(expIntraop)/sqrt(length(expIntraop)), ...
         std(expRCS)/sqrt(length(expRCS))], 'k.')
    set(gca, 'XTickLabel', {'Intraop', 'RCS'})
    ylabel('Aperiodic Exponent')
    title([subj ' Exponent (p=' sprintf('%.3f', pExp) ')'])

    subplot(1,2,2)
    bar([mean(offIntraop), mean(offRCS)])
    hold on
    errorbar([1 2], [mean(offIntraop), mean(offRCS)], ...
        [std(offIntraop)/sqrt(length(offIntraop)), ...
         std(offRCS)/sqrt(length(offRCS))], 'k.')
    set(gca, 'XTickLabel', {'Intraop', 'RCS'})
    ylabel('Aperiodic Offset')
    title([subj ' Offset (p=' sprintf('%.3f', pOff) ')'])
end

%% FOOOF Modeled Power Spectrum Plots (Per-Channel)
if isfield(base_fre1Intraop, 'fooof_powspctrm') && isfield(base_fre1RCSall, 'fooof_powspctrm')

    % Frequency vector for FOOOF (reconstruct since not stored in RCS HFO)
    fooofFreq = 4:0.5:50;

    % First, find all channels that exist in BOTH intraop and RCS
    matchedChannels = {};
    matchedIntraopIdx = [];
    matchedRCSData = {};

    for intraopIdx = 1:length(base_fre1Intraop.label)
        chanLabel = base_fre1Intraop.label{intraopIdx};

        % Find matching RCS channel
        foundMatch = false;
        for rcsTrial = 1:length(base_fre1RCSall.fooof_powspctrm)
            if isempty(base_fre1RCSall.fooof_powspctrm{rcsTrial}), continue; end

            for iterIdx = 1:length(base_fre1RCSall.fooof_powspctrm{rcsTrial})
                if isempty(base_fre1RCSall.chans{rcsTrial}) || isempty(base_fre1RCSall.chans{rcsTrial}{iterIdx})
                    continue;
                end

                rcsLabels = base_fre1RCSall.chans{rcsTrial}{iterIdx};
                rcsIdx = find(strcmp(rcsLabels, chanLabel));

                if ~isempty(rcsIdx)
                    % Found a match!
                    matchedChannels{end+1} = chanLabel;
                    matchedIntraopIdx(end+1) = intraopIdx;
                    matchedRCSData{end+1} = struct('rcsTrial', rcsTrial, 'iterIdx', iterIdx, 'rcsIdx', rcsIdx);
                    foundMatch = true;
                    break;
                end
            end
            if foundMatch, break; end
        end
    end

    numMatchedChans = length(matchedChannels);
    fprintf('FOOOF Plotting: Found %d matched channels\n', numMatchedChans);

    if numMatchedChans == 0
        warning('No matched channels for FOOOF plotting');
    else
        % Determine subplot layout based on MATCHED channels only
        if numMatchedChans == 4
            subplotRows = 2; subplotCols = 2;
        elseif numMatchedChans == 8
            subplotRows = 4; subplotCols = 2;
        else
            subplotRows = ceil(sqrt(numMatchedChans));
            subplotCols = ceil(numMatchedChans/subplotRows);
        end

        figFooofSpectrum = figure('Name', [subj ' FOOOF Modeled Spectra HFO']);

        for plotIdx = 1:numMatchedChans
            subplot(subplotRows, subplotCols, plotIdx)
            chanLabel = matchedChannels{plotIdx};
            intraopIdx = matchedIntraopIdx(plotIdx);
            rcsData = matchedRCSData{plotIdx};

            % Get intraop FOOOF spectrum and normalize to 100%
            intraopSpectrum = base_fre1Intraop.fooof_powspctrm(intraopIdx, :);
            intraopSum = nansum(intraopSpectrum);
            intraopNorm = 100 * intraopSpectrum / intraopSum;

            % Get RCS FOOOF spectrum and normalize to 100%
            rcsSpectrum = base_fre1RCSall.fooof_powspctrm{rcsData.rcsTrial}{rcsData.iterIdx}(rcsData.rcsIdx, :);
            rcsSum = nansum(rcsSpectrum);
            rcsNorm = 100 * rcsSpectrum / rcsSum;

            % Plot log of normalized power (data is in LINEAR scale)
            line1 = plot(fooofFreq, log10(rcsNorm), 'b-', 'LineWidth', 1.5);
            hold on
            line2 = plot(fooofFreq, log10(intraopNorm), 'r-', 'LineWidth', 1.5);
            grid on

            if plotIdx == 1
                xlabel('Frequency (Hz)')
                ylabel('Log_{10} Normalized Power (%)')
            end
            title(chanLabel)
            set(gca, 'fontsize', 12)
            if plotIdx == numMatchedChans
                legend([line1, line2], {'RCS', 'Intraop'}, 'Location', 'best');
            end
        end

        sgtitle([subj ' FOOOF Modeled Power Spectra (Normalized) - HFO'])

        if saveFigure
            tempFig = gcf;
            tempFig.Position = [300 300 1200 800];
            exportgraphics(tempFig, fullfile(folderFigures, [subj '_FOOOF_spectra_HFO.png']), 'Resolution', 600)
            exportgraphics(tempFig, fullfile(folderFigures, [subj '_FOOOF_spectra_HFO.eps']))
        end
    end  % End of else block
end  % End of FOOOF plotting if block

%% FOOOF Exponent/Offset Connected Scatter Plots
if exist('statsResultsFooof', 'var') && isfield(statsResultsFooof, 'matchedChannels')

    matchedChannels = statsResultsFooof.matchedChannels;
    numMatchedPairs = length(matchedChannels);

    if numMatchedPairs > 0
        % Color scheme for channel pairs
        channelColors = brewermap(max(numMatchedPairs, 3), 'Set1');

        figFooofScatter = figure('Name', [subj ' FOOOF Parameters HFO']);

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

        sgtitle([subj ' FOOOF Aperiodic Parameters by Channel - HFO'])

        if saveFigure
            tempFig = gcf;
            tempFig.Position = [300 300 1000 500];
            exportgraphics(tempFig, fullfile(folderFigures, [subj '_FOOOF_scatter_HFO.png']), 'Resolution', 600)
            exportgraphics(tempFig, fullfile(folderFigures, [subj '_FOOOF_scatter_HFO.eps']))
        end
    end
end

%% Signed rank test for matching channels (match by label first)
if signedRankTest
    fprintf('Running signed rank test with label-matched channels...\n');

    % Match ECoG channels by label
    rcsECOGLabels = base_fre1RCScollapse.label(indicesECOGRCS);
    matchedECOGIndicesRCS = [];
    matchedECOGIndicesIntra = [];

    for i = 1:length(rcsECOGLabels)
        matchIdx = find(strcmp(base_fre1Intraop.label, rcsECOGLabels{i}));
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
        matchIdx = find(strcmp(base_fre1Intraop.label, rcsLFPLabels{i}));
        if ~isempty(matchIdx)
            matchedLFPIndicesRCS(end+1) = indicesLFPRCS(i);
            matchedLFPIndicesIntra(end+1) = matchIdx;
        end
    end

    fprintf('  Matched %d ECoG channels, %d LFP channels\n', length(matchedECOGIndicesRCS), length(matchedLFPIndicesRCS));

    % Signed rank test for matched ECoG channels (paired test across channels)
    if ~isempty(matchedECOGIndicesRCS)
        for index = 1:size(base_fre1RCScollapse.averagedBins,2)
            [p,h,stats] = signrank(base_fre1RCScollapse.averagedBins(matchedECOGIndicesRCS,index), ...
                                    base_fre1Intraop.averagedBins(matchedECOGIndicesIntra,index));
            statsResults.pECOG(index)=p;
            statsResults.hECOG(index)=h;
            statsResults.statsECOG(index) = stats;
        end
    else
        warning('No matched ECoG channels for signed rank test');
    end

    % Signed rank test for matched LFP channels (paired test across channels)
    if ~isempty(matchedLFPIndicesRCS)
        for index = 1:size(base_fre1RCScollapse.averagedBins,2)
            [p,h,stats] = signrank(base_fre1RCScollapse.averagedBins(matchedLFPIndicesRCS,index), ...
                                    base_fre1Intraop.averagedBins(matchedLFPIndicesIntra,index));
            statsResults.pLFP(index)=p;
            statsResults.hLFP(index)=h;
            statsResults.statsLFP(index) = stats;
        end
    else
        warning('No matched LFP channels for signed rank test');
    end
end

%% Rank sum test across channels
if rankSumTest && ~isnan(base_fre1RCScollapse.averagedBins(indicesECOGRCS,index))

    for index = 1:size(base_fre1RCS.averagedBins,2)
        [p,h,stats] = ranksum(base_fre1RCScollapse.averagedBins(indicesECOGRCS,index),base_fre1Intraop.averagedBins(indicesECOGintra,index));
        statsResults.pECOG(index)=p;
        statsResults.hECOG(index)=h;
        statsResults.statsECOG(index) = stats;
    end


    % plot mean + SEM of frequency spectrum
    figure
    line1 = stdshade(log10(base_fre1RCScollapse.normalizedPow(indicesECOGRCS,:)),0.5,'b');
    hold on
    line2 = stdshade(log10(base_fre1Intraop.normalizedPow(indicesECOGintra,:)),0.5,'r');
    xlabel('Frequency (Hz)')
    ylabel('Log Percentage of Total Power')
    title([subj ' Comparison between normalized RCS and Intraoperative NeuroOmega data for ECoG Channels'])

    % make shaded regions of different frequency regions
    %freqEdgesPlot = [4 8;8 12; 13 20;20 30;50 125];
    freqEdgesPlot = [4 8;8 12; 13 20;20 30;50 125;250 350];

    ylims = ylim;
    minVal = ylims(1);
    maxVal = ylims(2);
    colormapPatch = brewermap(size(freqEdgesPlot,1),'PuBu');
    for index = 1:size(freqEdgesPlot,1)
        xVals = [freqEdgesPlot(index,1) freqEdgesPlot(index,2) freqEdgesPlot(index,2) freqEdgesPlot(index,1)];
        yVals = [minVal minVal maxVal maxVal];
        patch(xVals,yVals,colormapPatch(index,:),'FaceAlpha',0.2)
    end

    %%
    % significance stars
    if exist('statsResults','var') && isfield(statsResults,'pECOG')
        for index=1:min(length(statsResults.pECOG), size(freqEdgesPlot,1))
            if statsResults.pECOG(index)<=0.05
                scatter((freqEdgesPlot(index,2)+freqEdgesPlot(index,1))/2,maxVal-0.25,100,'k*'); %adds a marker
            end
        end
    end

    legend([line1,line2],{'RCS ECoG','Intraoperative NeuroOmega ECoG'});

end

if rankSumTest && ~isnan(base_fre1RCScollapse.averagedBins(indicesLFPRCS,index))

    for index = 1:size(base_fre1RCS.averagedBins,2)
        [p,h,stats] = ranksum(base_fre1RCScollapse.averagedBins(indicesLFPRCS,index),base_fre1Intraop.averagedBins(indicesLFPintra,index));
        statsResults.pLFP(index)=p;
        statsResults.hLFP(index)=h;
        statsResults.statsLFP(index) = stats;
    end

    figure
    line1 = stdshade(log10(base_fre1RCScollapse.normalizedPow(indicesLFPRCS,:)),0.5,'b');
    hold on
    line2 = stdshade(log10(base_fre1Intraop.normalizedPow(indicesLFPintra,:)),0.5,'r');
    xlabel('Frequency (Hz)')
    ylabel('Log Percentage of Total Power')
    title([subj ' Comparison between normalized RCS and Intraoperative NeuroOmega data for LFP signals from DBS Channels'])

    % make shaded regions of different frequency regions
    freqEdgesPlot = [4 8;8 12; 13 20;20 30;50 125;250 350];
    ylims = ylim;
    minVal = ylims(1);
    maxVal = ylims(2);
    colormapPatch = brewermap(size(freqEdgesPlot,1),'PuBu');
    for index = 1:size(freqEdgesPlot,1)

        xVals = [freqEdgesPlot(index,1) freqEdgesPlot(index,2) freqEdgesPlot(index,2) freqEdgesPlot(index,1)];
        yVals = [minVal minVal maxVal maxVal];
        patch(xVals,yVals,colormapPatch(index,:),'FaceAlpha',0.2)
    end

    %%
    % significance stars
    if exist('statsResults','var') && isfield(statsResults,'pLFP')
        for index=1:min(length(statsResults.pLFP), size(freqEdgesPlot,1))
            if statsResults.pLFP(index)<=0.05
                scatter((freqEdgesPlot(index,2)+freqEdgesPlot(index,1))/2,maxVal-0.25,100,'k*'); %adds a marker
            end
        end
    end

    legend([line1,line2],{'RCS LFP','Intraoperative NeuroOmega LFP'});

end

if rankSumTest
    statsCell{subjNum} = statsResults;
end

if saveFigure
    tempFig = gcf;
    tempFig.Position = [305 249 1009 768];
    exportgraphics(tempFig,fullfile(folderFigures,[subj '_compare_ECoG_LFP_HFO.png']),'Resolution',600)
    exportgraphics(tempFig,fullfile(folderFigures,[subj '_compare_ECoG_LFP_HFO.eps']))
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

        rcsLabels = base_fre1RCSall.chans{rcsTrial}{:};
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

    figure;
    freqEdgesPlot = [4 8;8 12; 13 20;20 30;50 125;250 350];

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

        % Add Bonferroni-corrected significance stars
        if permute_test && exist('statsResultsPerm','var')
            chanIdx = find(strcmp(statsResultsPerm.channelPairs, chanLabel));
            if ~isempty(chanIdx)
                ylims = ylim;
                maxVal = ylims(2);
                for freqBin = 1:size(freqEdgesPlot,1)
                    if statsResultsPerm.p(freqBin,chanIdx) < statsResultsPerm.bonferroniThreshold
                        scatter((freqEdgesPlot(freqBin,2)+freqEdgesPlot(freqBin,1))/2, maxVal-0.15, 100, 'k*');
                    end
                end
            end
        end

        % make shaded regions of different frequency regions
        freqEdgesPlot = [4 8;8 12; 13 20;20 30;50 125;250 350];
        ylims = ylim;
        minVal = ylims(1);
        maxVal = ylims(2);
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
if saveFigure
    tempFig = gcf;
    tempFig.Position = [300 300 1800 768];
    set(gca,'fontsize',16)
    exportgraphics(tempFig,fullfile(folderFigures,[subj 'high_SR_LFP_' splitPath{10} '_' splitPath{11} '.png']),'Resolution',600)
    exportgraphics(tempFig,fullfile(folderFigures,[subj 'high_SR_LFP' splitPath{10} '_' splitPath{11} '.eps']))
end
