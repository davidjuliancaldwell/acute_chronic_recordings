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

base_fre1RCScollapse.averagedBins = [squeeze(mean(cell2mat(base_fre1RCSall.averagedBins{1}),1))];
base_fre1RCScollapse.label = [base_fre1RCSall.chans{1}{:}];
base_fre1RCScollapse.normalizedPow = [squeeze(mean(cell2mat(base_fre1RCSall.normalizedPow{1}),1))];
base_fre1RCScollapse.powspctrm = [squeeze(mean(cell2mat(base_fre1RCSall.powspctrm{1}),1))];

if length(base_fre1RCSall.averagedBins) > 1
    for rcsTrial = 2:length(base_fre1RCSall.averagedBins)
        base_fre1RCScollapse.averagedBins = [base_fre1RCScollapse.averagedBins;squeeze(mean(cell2mat(base_fre1RCSall.averagedBins{rcsTrial}),1))];
        base_fre1RCScollapse.label = [base_fre1RCScollapse.label base_fre1RCSall.chans{rcsTrial}{:}];
        base_fre1RCScollapse.normalizedPow = [base_fre1RCScollapse.normalizedPow; squeeze(mean(cell2mat(base_fre1RCSall.normalizedPow{rcsTrial}),1))];
        base_fre1RCScollapse.powspctrm = [base_fre1RCScollapse.powspctrm; squeeze(mean(cell2mat(base_fre1RCSall.powspctrm{rcsTrial}),1))];
    end
end

indicesECOGRCS = find(contains(base_fre1RCScollapse.label,{'+8','+9','+10','+11','-8','-9','-10','-11'}));
indicesLFPRCS = ones(length(base_fre1RCScollapse.label),1);
indicesLFPRCS(indicesECOGRCS) = 0;
indicesLFPRCS = find(indicesLFPRCS==1);

% collapse across ECoG
hobase_fre1Intraop_avg.averagedBins = squeeze(mean(base_fre1Intraop.averagedBins,1));
base_fre1Intraop_avg.normalizedPow = squeeze(mean(base_fre1Intraop.normalizedPow,1));
%%
% need to make sure that the order of the RCS being read in matches the
% ECoG, with left then right being loaded in initially in setup RCS
if signedRankTest
    % rank sum test across channels
    for index = 1:size(base_fre1RCScollapse.averagedBins,2)
        [p,h,stats] = signrank(base_fre1RCScollapse.averagedBins(indicesECOGRCS,index),base_fre1Intraop_avg.averagedBins(indicesECOGintra,index));
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
        samps_rcs_cell = cell2mat(base_fre1RCSall.averagedBins{rcsTrial});
        rcsLabels = base_fre1RCSall.chans{rcsTrial}{:};

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
if rankSumTest || signedRankTest
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
if rankSumTest || signedRankTest
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

%% do 4 x 2 plot
if length(base_fre1Intraop.label) ==4
    fig3 = figure;
    freqEdgesPlot = [4 8;8 12; 13 20;20 30;50 125];

    for plotIdx = 1:4
        subplot(2,2,plotIdx)
        % start with the chan label for each index
        chanLabel = base_fre1Intraop.label{plotIdx};

        % Find matching RCS channel by label
        for rcsTrial = 1:length(base_fre1RCSall.averagedBins)

            % extract labels for this given RCS trial
            rcsLabels = base_fre1RCSall.chans{rcsTrial}{:};

            % For each RCS channel, find matching intraop channel by label
            rcsIdx = find(strcmp(rcsLabels, chanLabel));

            if ~isempty(rcsIdx)
                % extract the data of interest for this trial 
                rcs_data_interest = base_fre1RCSall.normalizedPow{rcsTrial}{:};

                line1 = stdshade(log10(squeeze(rcs_data_interest(:,rcsIdx,:))),0.5,'b');
                hold on
                line2 = stdshade(log10(squeeze(base_fre1Intraop.normalizedPow(:,plotIdx,:))),0.5,'r');
                if plotIdx == 1
                    xlabel('Frequency (Hz)')
                    ylabel('Log Percentage of Total Power')
                end
                title([subj ' Intraop vs. RC+S ' chanLabel])
                set(gca,'fontsize',16)

                % make shaded regions of different frequency regions
                ylims = ylim;
                minVal = ylims(1);
                maxVal = ylims(2);
                colormapPatch = brewermap(size(freqEdgesPlot,1),'PuBu');
                for index = 1:size(freqEdgesPlot,1)
                    xVals = [freqEdgesPlot(index,1) freqEdgesPlot(index,2) freqEdgesPlot(index,2) freqEdgesPlot(index,1)];
                    yVals = [minVal minVal maxVal maxVal];
                    patch(xVals,yVals,colormapPatch(index,:),'FaceAlpha',0.2)
                end

                % Add Bonferroni-corrected significance stars
                if permute_test && exist('statsResultsPerm','var')
                    % Find which matched channel corresponds to this subplot
                    chanIdx = find(strcmp(statsResultsPerm.channelPairs, chanLabel));
                    if ~isempty(chanIdx)
                        for freqBin = 1:size(freqEdgesPlot,1)
                            if statsResultsPerm.p(freqBin,chanIdx) < statsResultsPerm.bonferroniThreshold
                                scatter((freqEdgesPlot(freqBin,2)+freqEdgesPlot(freqBin,1))/2, maxVal-0.15, 100, 'k*');
                            end
                        end
                    end
                end

                if plotIdx == 4
                    legend([line1,line2],{'RC+S','Intraoperative NeuroOmega'});
                end
            end
        end
    end


elseif length(base_fre1Intraop.label) ==8
    fig3 = figure;
    freqEdgesPlot = [4 8;8 12; 13 20;20 30;50 125];

    for plotIdx = 1:8
        subplot(4,2,plotIdx)
        % start with the chan label for each index
        chanLabel = base_fre1Intraop.label{plotIdx};

        % Find matching RCS channel by label
        for rcsTrial = 1:length(base_fre1RCSall.averagedBins)

            % extract labels for this given RCS trial
            rcsLabels = base_fre1RCSall.chans{rcsTrial}{:};

            % For each RCS channel, find matching intraop channel by label
            rcsIdx = find(strcmp(rcsLabels, chanLabel));

            if ~isempty(rcsIdx)
                % extract the data of interest for this trial
                rcs_data_interest = base_fre1RCSall.normalizedPow{rcsTrial}{:};

                line1 = stdshade(log10(squeeze(rcs_data_interest(:,rcsIdx,:))),0.5,'b');
                hold on
                line2 = stdshade(log10(squeeze(base_fre1Intraop.normalizedPow(:,plotIdx,:))),0.5,'r');
                if plotIdx == 1
                    xlabel('Frequency (Hz)')
                    ylabel('Log Percentage of Total Power')
                end
                title([subj ' Intraop vs. RC+S ' chanLabel])
                set(gca,'fontsize',16)

                % make shaded regions of different frequency regions
                ylims = ylim;
                minVal = ylims(1);
                maxVal = ylims(2);
                colormapPatch = brewermap(size(freqEdgesPlot,1),'PuBu');
                for index = 1:size(freqEdgesPlot,1)
                    xVals = [freqEdgesPlot(index,1) freqEdgesPlot(index,2) freqEdgesPlot(index,2) freqEdgesPlot(index,1)];
                    yVals = [minVal minVal maxVal maxVal];
                    patch(xVals,yVals,colormapPatch(index,:),'FaceAlpha',0.2)
                end

                % Add Bonferroni-corrected significance stars
                if permute_test && exist('statsResultsPerm','var')
                    % Find which matched channel corresponds to this subplot
                    chanIdx = find(strcmp(statsResultsPerm.channelPairs, chanLabel));
                    if ~isempty(chanIdx)
                        for freqBin = 1:size(freqEdgesPlot,1)
                            if statsResultsPerm.p(freqBin,chanIdx) < statsResultsPerm.bonferroniThreshold
                                scatter((freqEdgesPlot(freqBin,2)+freqEdgesPlot(freqBin,1))/2, maxVal-0.15, 100, 'k*');
                            end
                        end
                    end
                end

                if plotIdx == 8
                    legend([line1,line2],{'RC+S','Intraoperative NeuroOmega'});
                end
            end
        end
    end

end

%%
saveFigure = 1;
if saveFigure
    tempFig = gcf;
    tempFig.Position = [300 300 1800 768];
    exportgraphics(tempFig,fullfile(folderFigures,[subj 'indChans_compare_ECoG_LFP_' splitPath{10} '_' splitPath{11} '.png']),'Resolution',600)
    exportgraphics(tempFig,fullfile(folderFigures,[subj 'indChans_compare_ECoG_LFP_' splitPath{10} '_' splitPath{11} '.eps']))
end

%% do 2 x 2 plot (power spectrum - not normalized)
if length(base_fre1Intraop.label) ==4
    fig4 = figure;
    freqEdgesPlot = [4 8;8 12; 13 20;20 30;50 125];

    for plotIdx = 1:4
        subplot(2,2,plotIdx)
        % start with the chan label for each index
        chanLabel = base_fre1Intraop.label{plotIdx};

        % Find matching RCS channel by label
        for rcsTrial = 1:length(base_fre1RCSall.powspctrm)

            % extract labels for this given RCS trial
            rcsLabels = base_fre1RCSall.chans{rcsTrial}{:};

            % For each RCS channel, find matching intraop channel by label
            rcsIdx = find(strcmp(rcsLabels, chanLabel));

            if ~isempty(rcsIdx)
                % extract the data of interest for this trial
                rcs_data_interest = base_fre1RCSall.powspctrm{rcsTrial}{:};

                line1 = stdshade(log10(squeeze(rcs_data_interest(:,rcsIdx,:))),0.5,'b');
                hold on
                line2 = stdshade(log10(squeeze(base_fre1Intraop.powspctrm(:,plotIdx,:))),0.5,'r');
                if plotIdx == 1
                    xlabel('Frequency (Hz)')
                    ylabel('Log Percentage of Total Power')
                end
                title([subj ' Intraop vs. RC+S ' chanLabel])
                set(gca,'fontsize',16)

                                % Add Bonferroni-corrected significance stars
                if permute_test && exist('statsResultsPerm','var')
                    % Find which matched channel corresponds to this subplot
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
                ylims = ylim;
                minVal = ylims(1);
                maxVal = ylims(2);
                colormapPatch = brewermap(size(freqEdgesPlot,1),'PuBu');
                for index = 1:size(freqEdgesPlot,1)
                    xVals = [freqEdgesPlot(index,1) freqEdgesPlot(index,2) freqEdgesPlot(index,2) freqEdgesPlot(index,1)];
                    yVals = [minVal minVal maxVal maxVal];
                    patch(xVals,yVals,colormapPatch(index,:),'FaceAlpha',0.2)
                end



                if plotIdx == 4
                    legend([line1,line2],{'RC+S','Intraoperative NeuroOmega'});
                end
            end
        end
    end

elseif length(base_fre1Intraop.label) ==8
    fig4 = figure;
    freqEdgesPlot = [4 8;8 12; 13 20;20 30;50 125];

    for plotIdx = 1:8
        subplot(4,2,plotIdx)
        % start with the chan label for each index
        chanLabel = base_fre1Intraop.label{plotIdx};

        % Find matching RCS channel by label
        for rcsTrial = 1:length(base_fre1RCSall.powspctrm)

            % extract labels for this given RCS trial
            rcsLabels = base_fre1RCSall.chans{rcsTrial}{:};

            % For each RCS channel, find matching intraop channel by label
            rcsIdx = find(strcmp(rcsLabels, chanLabel));

            if ~isempty(rcsIdx)
                % extract the data of interest for this trial
                rcs_data_interest = base_fre1RCSall.powspctrm{rcsTrial}{:};

                line1 = stdshade(log10(squeeze(rcs_data_interest(:,rcsIdx,:))),0.5,'b');
                hold on
                line2 = stdshade(log10(squeeze(base_fre1Intraop.powspctrm(:,plotIdx,:))),0.5,'r');
                if plotIdx == 1
                    xlabel('Frequency (Hz)')
                    ylabel('Log Percentage of Total Power')
                end
                title([subj ' Intraop vs. RC+S ' chanLabel])
                set(gca,'fontsize',16)

                                % Add Bonferroni-corrected significance stars
                if permute_test && exist('statsResultsPerm','var')
                    % Find which matched channel corresponds to this subplot
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
                ylims = ylim;
                minVal = ylims(1);
                maxVal = ylims(2);
                colormapPatch = brewermap(size(freqEdgesPlot,1),'PuBu');
                for index = 1:size(freqEdgesPlot,1)
                    xVals = [freqEdgesPlot(index,1) freqEdgesPlot(index,2) freqEdgesPlot(index,2) freqEdgesPlot(index,1)];
                    yVals = [minVal minVal maxVal maxVal];
                    patch(xVals,yVals,colormapPatch(index,:),'FaceAlpha',0.2)
                end



                if plotIdx == 8
                    legend([line1,line2],{'RC+S','Intraoperative NeuroOmega'});
                end
            end
        end
    end

end

%%
saveFigure = 1;
if saveFigure
    tempFig = gcf;
    tempFig.Position = [300 300 1800 768];
    exportgraphics(tempFig,fullfile(folderFigures,[subj 'indChansNotNormalized_compare_ECoG_LFP_' splitPath{10} '_' splitPath{11} '.png']),'Resolution',600)
    exportgraphics(tempFig,fullfile(folderFigures,[subj 'indChansNotNormalized_compare_ECoG_LFP_' splitPath{10} '_' splitPath{11} '.eps']))
end




