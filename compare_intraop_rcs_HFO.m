% run this after the data has been processed

% intraop ECoG and DBS channels
indicesECOGintra = find(contains(base_fre1Intraop.label,'ECOG'));
indicesLFPintra = find(contains(base_fre1Intraop.label,'LFP'));


% RC+S ECoG and DBS channels
base_fre1RCScollapse = {};

base_fre1RCScollapse.averagedBins = cell2mat(base_fre1RCSall.averagedBins');
base_fre1RCScollapse.label = [base_fre1RCSall.chans{:}];
base_fre1RCScollapse.normalizedPow = cell2mat(base_fre1RCSall.normalizedPow');

indicesECOGRCS = find(contains(base_fre1RCScollapse.label,{'+8','+9','+10','+11','-8','-9','-10','-11'}));
indicesLFPRCS = ones(length(base_fre1RCScollapse.label),1);
indicesLFPRCS(indicesECOGRCS) = 0;
indicesLFPRCS = find(indicesLFPRCS==1);


% rank sum test across channels
if ~isnan(base_fre1RCScollapse.averagedBins(indicesECOGRCS,index))

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

if ~isnan(base_fre1RCScollapse.averagedBins(indicesLFPRCS,index))

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

statsCell{subjNum} = statsResults;

if saveFigure
    tempFig = gcf;
    tempFig.Position = [305 249 1009 768];
    exportgraphics(tempFig,fullfile(folderFigures,[subj '_compare_ECoG_LFP_HFO.png']),'Resolution',600)
    exportgraphics(tempFig,fullfile(folderFigures,[subj '_compare_ECoG_LFP_HFO.eps']))
end

%%

figure;
subplot(1,2,1)
line1 = stdshade(log10(base_fre1RCScollapse.normalizedPow(1,:)),0.5,'b');
hold on
line2 = stdshade(log10(base_fre1Intraop.normalizedPow(7,:)),0.5,'r');
title([subj ' Intraop vs. RC+S ' base_fre1Intraop.label{7}])

% make shaded regions of different frequency regions
% freqEdgesPlot = [4 8;8 12; 13 20;20 30;50 125];
% ylims = ylim;
% minVal = ylims(1);
% maxVal = ylims(2);
% colormapPatch = brewermap(size(freqEdgesPlot,1),'PuBu');
% for index = 1:size(freqEdgesPlot,1)
%     xVals = [freqEdgesPlot(index,1) freqEdgesPlot(index,2) freqEdgesPlot(index,2) freqEdgesPlot(index,1)];
%     yVals = [minVal minVal maxVal maxVal];
%     patch(xVals,yVals,colormapPatch(index,:),'FaceAlpha',0.2)
% end
xlabel('Frequency (Hz)')
ylabel('Log Percentage of Total Power')
    set(gca,'fontsize',16)


subplot(1,2,2)
line1 = stdshade(log10(base_fre1RCScollapse.normalizedPow(2,:)),0.5,'b');
hold on
line2 = stdshade(log10(base_fre1Intraop.normalizedPow(8,:)),0.5,'r');

title([subj ' Intraop vs. RC+S ' base_fre1Intraop.label{8}])

% make shaded regions of different frequency regions
% freqEdgesPlot = [4 8;8 12; 13 20;20 30;50 125];
% ylims = ylim;
% minVal = ylims(1);
% maxVal = ylims(2);
% colormapPatch = brewermap(size(freqEdgesPlot,1),'PuBu');
% for index = 1:size(freqEdgesPlot,1)
%     xVals = [freqEdgesPlot(index,1) freqEdgesPlot(index,2) freqEdgesPlot(index,2) freqEdgesPlot(index,1)];
%     yVals = [minVal minVal maxVal maxVal];
%     patch(xVals,yVals,colormapPatch(index,:),'FaceAlpha',0.2)
% end

legend([line1,line2],{'RC+S LFP','Intraoperative NeuroOmega LFP'});
    set(gca,'fontsize',16)

%%
if saveFigure
    tempFig = gcf;
    tempFig.Position = [300 300 1800 768];
    set(gca,'fontsize',16)
    exportgraphics(tempFig,fullfile(folderFigures,[subj 'high_SR_LFP_' splitPath{10} '_' splitPath{11} '.png']),'Resolution',600)
    exportgraphics(tempFig,fullfile(folderFigures,[subj 'high_SR_LFP' splitPath{10} '_' splitPath{11} '.eps']))
end
