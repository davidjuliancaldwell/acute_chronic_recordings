% run this after the data has been processed

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

% RC+S ECoG and DBS channels
base_fre1RCScollapse = {};


base_fre1RCScollapse.averagedBins = [cell2mat(base_fre1RCSall.averagedBins{1}')];
base_fre1RCScollapse.label = [base_fre1RCSall.chans{1}{:}];
base_fre1RCScollapse.normalizedPow = [cell2mat(base_fre1RCSall.normalizedPow{1}')];
base_fre1RCScollapse.powspctrm = [cell2mat(base_fre1RCSall.powspctrm{1}')];

if length(base_fre1RCSall.averagedBins) > 1
    for rcsTrial = 2:length(base_fre1RCSall.averagedBins)
        base_fre1RCScollapse.averagedBins = [base_fre1RCScollapse.averagedBins; cell2mat(base_fre1RCSall.averagedBins{rcsTrial}')];
        base_fre1RCScollapse.label = [base_fre1RCScollapse.label base_fre1RCSall.chans{rcsTrial}{:}];
        base_fre1RCScollapse.normalizedPow = [base_fre1RCScollapse.normalizedPow; cell2mat(base_fre1RCSall.normalizedPow{rcsTrial}')];
        base_fre1RCScollapse.powspctrm = [base_fre1RCScollapse.powspctrm; cell2mat(base_fre1RCSall.powspctrm{rcsTrial}')];
    end
end

indicesECOGRCS = find(contains(base_fre1RCScollapse.label,{'+8','+9','+10','+11','-8','-9','-10','-11'}));
indicesLFPRCS = ones(length(base_fre1RCScollapse.label),1);
indicesLFPRCS(indicesECOGRCS) = 0;
indicesLFPRCS = find(indicesLFPRCS==1);

if signedRankTest
    % rank sum test across channels
    for index = 1:size(base_fre1RCScollapse.averagedBins,2)
        [p,h,stats] = signrank(base_fre1RCScollapse.averagedBins(indicesECOGRCS,index),base_fre1Intraop.averagedBins(indicesECOGintra,index));
        statsResults.pECOG(index)=p;
        statsResults.hECOG(index)=h;
        statsResults.statsECOG(index) = stats;
    end

    for index = 1:size(base_fre1RCScollapse.averagedBins,2)
        [p,h,stats] = ranksum(base_fre1RCScollapse.averagedBins(indicesLFPRCS,index),base_fre1Intraop.averagedBins(indicesLFPintra,index));
        statsResults.pLFP(index)=p;
        statsResults.hLFP(index)=h;
        statsResults.statsLFP(index) = stats;
    end


elseif rankSumTest
    % rank sum test across channels
    for index = 1:size(base_fre1RCS.averagedBins,2)
        [p,h,stats] = ranksum(base_fre1RCScollapse.averagedBins(indicesECOGRCS,index),base_fre1Intraop.averagedBins(indicesECOGintra,index));
        statsResults.pECOG(index)=p;
        statsResults.hECOG(index)=h;
        statsResults.statsECOG(index) = stats;
    end

    for index = 1:size(base_fre1RCS.averagedBins,2)
        [p,h,stats] = ranksum(base_fre1RCScollapse.averagedBins(indicesLFPRCS,index),base_fre1Intraop.averagedBins(indicesLFPintra,index));
        statsResults.pLFP(index)=p;
        statsResults.hLFP(index)=h;
        statsResults.statsLFP(index) = stats;
    end
end

statsCell{subjNum} = statsResults;

% plot mean + SEM of frequency spectrum
fig1 = figure;
subplot(2,1,1)
line1 = stdshade(log10(base_fre1RCScollapse.normalizedPow(indicesECOGRCS,:)),0.5,'b');
hold on
line2 = stdshade(log10(base_fre1Intraop.normalizedPow(indicesECOGintra,:)),0.5,'r');
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

%%
% significance stars
for index=1:5
    if statsResults.pECOG(index)<=0.05
        scatter((freqEdgesPlot(index,2)+freqEdgesPlot(index,1))/2,maxVal-0.25,100,'k*'); %adds a marker
    end
end

legend([line1,line2],{'RC+S ECoG','Intraoperative NeuroOmega ECoG'});
set(gca,'fontsize',16)

subplot(2,1,2)
line1 = stdshade(log10(base_fre1RCScollapse.normalizedPow(indicesLFPRCS,:)),0.5,'b');
hold on
line2 = stdshade(log10(base_fre1Intraop.normalizedPow(indicesLFPintra,:)),0.5,'r');
xlabel('Frequency (Hz)')
ylabel('Log Percentage of Total Power')
title([subj ' Comparison between normalized RC+S and Intraoperative NeuroOmega data for LFP signals from DBS Channels'])

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

%%
% significance stars
for index=1:5
    if statsResults.pLFP(index)<=0.05
        scatter((freqEdgesPlot(index,2)+freqEdgesPlot(index,1))/2,maxVal-0.25,100,'k*'); %adds a marker
    end
end

legend([line1,line2],{'RC+S LFP','Intraoperative NeuroOmega LFP'});
set(gca,'fontsize',16)

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
    subplot(2,2,1)
    line1 = stdshade(log10(base_fre1RCScollapse.normalizedPow(1,:)),0.5,'b');
    hold on
    line2 = stdshade(log10(base_fre1Intraop.normalizedPow(1,:)),0.5,'r');
    xlabel('Frequency (Hz)')
    ylabel('Log Percentage of Total Power')
    title([subj ' Intraop vs. RC+S ECoG ' base_fre1Intraop.label{1}])

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
    set(gca,'fontsize',16)

    subplot(2,2,2)
    line1 = stdshade(log10(base_fre1RCScollapse.normalizedPow(2,:)),0.5,'b');
    hold on
    line2 = stdshade(log10(base_fre1Intraop.normalizedPow(2,:)),0.5,'r');
    title([subj 'Intraop vs. RC+S ECoG ' base_fre1Intraop.label{2}])

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
    set(gca,'fontsize',16)

    subplot(2,2,3)
    line1 = stdshade(log10(base_fre1RCScollapse.normalizedPow(3,:)),0.5,'b');
    hold on
    line2 = stdshade(log10(base_fre1Intraop.normalizedPow(3,:)),0.5,'r');
    title([subj ' Intraop vs. RC+S LFP ' base_fre1Intraop.label{3}])

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
    set(gca,'fontsize',16)

    subplot(2,2,4)
    line1 = stdshade(log10(base_fre1RCScollapse.normalizedPow(4,:)),0.5,'b');
    hold on
    line2 = stdshade(log10(base_fre1Intraop.normalizedPow(4,:)),0.5,'r');
    xlabel('Frequency (Hz)')
    ylabel('Log Percentage of Total Power')
    title([subj ' Intraop vs. RC+S LFP ' base_fre1Intraop.label{4}])

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

    legend([line1,line2],{'RC+S LFP','Intraoperative NeuroOmega LFP'});
    set(gca,'fontsize',16)

elseif length(base_fre1Intraop.label) ==8
    fig3 = figure;
    subplot(4,2,1)
    line1 = stdshade(log10(base_fre1RCScollapse.normalizedPow(1,:)),0.5,'b');
    hold on
    line2 = stdshade(log10(base_fre1Intraop.normalizedPow(1,:)),0.5,'r');
    xlabel('Frequency (Hz)')
    ylabel('Log Percentage of Total Power')
    title([subj ' Intraop vs. RC+S ' base_fre1Intraop.label{1}])

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
    set(gca,'fontsize',16)

    subplot(4,2,2)
    line1 = stdshade(log10(base_fre1RCScollapse.normalizedPow(2,:)),0.5,'b');
    hold on
    line2 = stdshade(log10(base_fre1Intraop.normalizedPow(2,:)),0.5,'r');
    title([subj ' Intraop vs. RC+S ' base_fre1Intraop.label{2}])

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
    set(gca,'fontsize',16)

    subplot(4,2,3)
    line1 = stdshade(log10(base_fre1RCScollapse.normalizedPow(3,:)),0.5,'b');
    hold on
    line2 = stdshade(log10(base_fre1Intraop.normalizedPow(3,:)),0.5,'r');
    title([subj ' Intraop vs. RC+S ' base_fre1Intraop.label{3}])

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
    set(gca,'fontsize',16)

    subplot(4,2,4)
    line1 = stdshade(log10(base_fre1RCScollapse.normalizedPow(4,:)),0.5,'b');
    hold on
    line2 = stdshade(log10(base_fre1Intraop.normalizedPow(4,:)),0.5,'r');
    title([subj ' Intraop vs. RC+S ' base_fre1Intraop.label{4}])

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
    set(gca,'fontsize',16)

    subplot(4,2,5)
    line1 = stdshade(log10(base_fre1RCScollapse.normalizedPow(5,:)),0.5,'b');
    hold on
    line2 = stdshade(log10(base_fre1Intraop.normalizedPow(5,:)),0.5,'r');
    title([subj ' Intraop vs. RC+S ' base_fre1Intraop.label{5}])

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
    set(gca,'fontsize',16)

    subplot(4,2,6)
    line1 = stdshade(log10(base_fre1RCScollapse.normalizedPow(6,:)),0.5,'b');
    hold on
    line2 = stdshade(log10(base_fre1Intraop.normalizedPow(6,:)),0.5,'r');
    title([subj ' Intraop vs. RC+S ' base_fre1Intraop.label{6}])

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
    set(gca,'fontsize',16)

    subplot(4,2,7)
    line1 = stdshade(log10(base_fre1RCScollapse.normalizedPow(7,:)),0.5,'b');
    hold on
    line2 = stdshade(log10(base_fre1Intraop.normalizedPow(7,:)),0.5,'r');
    title([subj ' Intraop vs. RC+S ' base_fre1Intraop.label{7}])

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
    set(gca,'fontsize',16)

    subplot(4,2,8)
    line1 = stdshade(log10(base_fre1RCScollapse.normalizedPow(8,:)),0.5,'b');
    hold on
    line2 = stdshade(log10(base_fre1Intraop.normalizedPow(8,:)),0.5,'r');
    title([subj ' Intraop vs. RC+S ' base_fre1Intraop.label{8}])

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

    legend([line1,line2],{'RC+S LFP','Intraoperative NeuroOmega LFP'});
    set(gca,'fontsize',16)


end

%%
saveFigure = 1;
if saveFigure
    tempFig = gcf;
    tempFig.Position = [300 300 1800 768];
    exportgraphics(tempFig,fullfile(folderFigures,[subj 'indChans_compare_ECoG_LFP_' splitPath{10} '_' splitPath{11} '.png']),'Resolution',600)
    exportgraphics(tempFig,fullfile(folderFigures,[subj 'indChans_compare_ECoG_LFP_' splitPath{10} '_' splitPath{11} '.eps']))
end

%% do 4 x 2 plot
if length(base_fre1Intraop.label) ==4
    fig3 = figure;
    subplot(2,2,1)
    line1 = stdshade(log10(base_fre1RCScollapse.powspctrm(1,:)),0.5,'b');
    hold on
    line2 = stdshade(log10(base_fre1Intraop.powspctrm(1,:)),0.5,'r');
    xlabel('Frequency (Hz)')
    ylabel('Log Percentage of Total Power')
    title([subj ' Intraop vs. RC+S ECoG ' base_fre1Intraop.label{1}])

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
    set(gca,'fontsize',16)

    subplot(2,2,2)
    line1 = stdshade(log10(base_fre1RCScollapse.powspctrm(2,:)),0.5,'b');
    hold on
    line2 = stdshade(log10(base_fre1Intraop.powspctrm(2,:)),0.5,'r');
    title([subj 'Intraop vs. RC+S ECoG ' base_fre1Intraop.label{2}])

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
    set(gca,'fontsize',16)

    subplot(2,2,3)
    line1 = stdshade(log10(base_fre1RCScollapse.powspctrm(3,:)),0.5,'b');
    hold on
    line2 = stdshade(log10(base_fre1Intraop.powspctrm(3,:)),0.5,'r');
    title([subj ' Intraop vs. RC+S LFP ' base_fre1Intraop.label{3}])

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
    set(gca,'fontsize',16)

    subplot(2,2,4)
    line1 = stdshade(log10(base_fre1RCScollapse.powspctrm(4,:)),0.5,'b');
    hold on
    line2 = stdshade(log10(base_fre1Intraop.powspctrm(4,:)),0.5,'r');
    xlabel('Frequency (Hz)')
    ylabel('Log Percentage of Total Power')
    title([subj ' Intraop vs. RC+S LFP ' base_fre1Intraop.label{4}])

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
    set(gca,'fontsize',16)

elseif length(base_fre1Intraop.label) ==8
    fig3 = figure;
    subplot(4,2,1)
    line1 = stdshade(log10(base_fre1RCScollapse.powspctrm(1,:)),0.5,'b');
    hold on
    line2 = stdshade(log10(base_fre1Intraop.powspctrm(1,:)),0.5,'r');
    xlabel('Frequency (Hz)')
    ylabel('Log Percentage of Total Power')
    title([subj ' Intraop vs. RC+S ECoG ' base_fre1Intraop.label{1}])

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
    set(gca,'fontsize',16)

    subplot(4,2,2)
    line1 = stdshade(log10(base_fre1RCScollapse.powspctrm(2,:)),0.5,'b');
    hold on
    line2 = stdshade(log10(base_fre1Intraop.powspctrm(2,:)),0.5,'r');
    title([subj ' Intraop vs. RC+S ECoG ' base_fre1Intraop.label{2}])

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
    set(gca,'fontsize',16)

    subplot(4,2,3)
    line1 = stdshade(log10(base_fre1RCScollapse.powspctrm(3,:)),0.5,'b');
    hold on
    line2 = stdshade(log10(base_fre1Intraop.powspctrm(3,:)),0.5,'r');
    title([subj ' Intraop vs. RC+S ECoG ' base_fre1Intraop.label{3}])

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
    set(gca,'fontsize',16)

    subplot(4,2,4)
    line1 = stdshade(log10(base_fre1RCScollapse.powspctrm(4,:)),0.5,'b');
    hold on
    line2 = stdshade(log10(base_fre1Intraop.powspctrm(4,:)),0.5,'r');
    title([subj ' Intraop vs. RC+S ECoG ' base_fre1Intraop.label{4}])

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
    set(gca,'fontsize',16)

    subplot(4,2,5)
    line1 = stdshade(log10(base_fre1RCScollapse.powspctrm(5,:)),0.5,'b');
    hold on
    line2 = stdshade(log10(base_fre1Intraop.powspctrm(5,:)),0.5,'r');
    title([subj ' Intraop vs. RC+S LFP ' base_fre1Intraop.label{5}])

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
    set(gca,'fontsize',16)

    subplot(4,2,6)
    line1 = stdshade(log10(base_fre1RCScollapse.powspctrm(6,:)),0.5,'b');
    hold on
    line2 = stdshade(log10(base_fre1Intraop.powspctrm(6,:)),0.5,'r');
    title([subj ' Intraop vs. RC+S LFP ' base_fre1Intraop.label{6}])

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
    set(gca,'fontsize',16)

    subplot(4,2,7)
    line1 = stdshade(log10(base_fre1RCScollapse.powspctrm(7,:)),0.5,'b');
    hold on
    line2 = stdshade(log10(base_fre1Intraop.powspctrm(7,:)),0.5,'r');
    title([subj ' Intraop vs. RC+S LFP ' base_fre1Intraop.label{7}])

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
    set(gca,'fontsize',16)

    subplot(4,2,8)
    line1 = stdshade(log10(base_fre1RCScollapse.powspctrm(8,:)),0.5,'b');
    hold on
    line2 = stdshade(log10(base_fre1Intraop.powspctrm(8,:)),0.5,'r');
    title([subj ' Intraop vs. RC+S LFP ' base_fre1Intraop.label{8}])

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
    set(gca,'fontsize',16)


end

%%
saveFigure = 1;
if saveFigure
    tempFig = gcf;
    tempFig.Position = [300 300 1800 768];
    exportgraphics(tempFig,fullfile(folderFigures,[subj 'indChansNotNormalized_compare_ECoG_LFP_' splitPath{10} '_' splitPath{11} '.png']),'Resolution',600)
    exportgraphics(tempFig,fullfile(folderFigures,[subj 'indChansNotNormalized_compare_ECoG_LFP_' splitPath{10} '_' splitPath{11} '.eps']))
end




