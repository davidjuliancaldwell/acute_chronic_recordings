% run this after the data has been processed

% intraop ECoG and DBS channels
indicesECOGintra = find(contains(base_fre1Intraop.label,'ECOG'));
indicesLFPintra = find(contains(base_fre1Intraop.label,'LFP'));


% RC+S ECoG and DBS channels
base_fre1RCScollapse = {};

base_fre1RCScollapse.averagedBins = cell2mat(base_fre1RCSall.averagedBins');
base_fre1RCScollapse.label = [base_fre1RCSall.chans{:}];
base_fre1RCScollapse.normalizedPow = cell2mat(base_fre1RCSall.normalizedPow');

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
    for rcsTrial = 1:length(base_fre1RCSall.averagedBins)
        samps_rcs_cell = base_fre1RCSall.averagedBins{rcsTrial};
        rcsLabels = base_fre1RCSall.chans{rcsTrial};

        % For each RCS channel, find matching intraop channel by label
        for rcsIdx = 1:length(rcsLabels)
            rcsLabel = rcsLabels{rcsIdx};
            matchIdx = find(strcmp(base_fre1Intraop.label, rcsLabel));

            if ~isempty(matchIdx)
                matchedPairCount = matchedPairCount + 1;

                for freqBin = 1:size(base_fre1Intraop.averagedBins,2)
                    samps_rcs = squeeze(samps_rcs_cell(:,freqBin));
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

% rank sum test across channels
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
    for index=1:5
        if statsResults.pECOG(index)<=0.05
            scatter((freqEdgesPlot(index,2)+freqEdgesPlot(index,1))/2,maxVal-0.25,100,'k*'); %adds a marker
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
    for index=1:5
        if statsResults.pLFP(index)<=0.05
            scatter((freqEdgesPlot(index,2)+freqEdgesPlot(index,1))/2,maxVal-0.25,100,'k*'); %adds a marker
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
% Plot all matched channels in a loop
if length(base_fre1Intraop.label) == 4
    % 4-channel case (single hemisphere)
    figure;
    freqEdgesPlot = [4 8;8 12; 13 20;20 30;50 125;250 350];

    for plotIdx = 1:4
        subplot(2,2,plotIdx)

        % Find matching RCS channel
        chanLabel = base_fre1Intraop.label{plotIdx};

        for rcsTrial = 1:length(base_fre1RCSall.normalizedPow)
            rcsLabels = base_fre1RCSall.chans{rcsTrial}{:};
            rcsIdx = find(strcmp(rcsLabels, chanLabel));

            if ~isempty(rcsIdx)
                rcs_data_interest = base_fre1RCSall.normalizedPow{rcsTrial}{:};
                line1 = stdshade(log10(squeeze(rcs_data_interest(:,rcsIdx,:))),0.5,'b');
                hold on
                line2 = stdshade(log10(squeeze(base_fre1Intraop.normalizedPow(:,plotIdx,:))),0.5,'r');

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
                break;
            end
        end
    end

elseif length(base_fre1Intraop.label) == 8
    % 8-channel case (bilateral)
    figure;
    freqEdgesPlot = [4 8;8 12; 13 20;20 30;50 125;250 350];

    for plotIdx = 1:8
        subplot(2,4,plotIdx)

        % Find matching RCS channel
        chanLabel = base_fre1Intraop.label{plotIdx};

        for rcsTrial = 1:length(base_fre1RCSall.normalizedPow)
            rcsLabels = base_fre1RCSall.chans{rcsTrial}{:};
            rcsIdx = find(strcmp(rcsLabels, chanLabel));

            if ~isempty(rcsIdx)
                rcs_data_interest = base_fre1RCSall.normalizedPow{rcsTrial}{:};
                line1 = stdshade(log10(squeeze(rcs_data_interest(:,rcsIdx,:))),0.5,'b');
                hold on
                line2 = stdshade(log10(squeeze(base_fre1Intraop.normalizedPow(:,plotIdx,:))),0.5,'r');

                if plotIdx == 1
                    xlabel('Frequency (Hz)')
                    ylabel('Log Percentage of Total Power')
                end
                title([subj ' ' chanLabel])

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
                break;
            end
        end
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
