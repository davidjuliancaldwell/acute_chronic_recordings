% run this after the data has been processed

for index = 1:size(base_fre1RCS.averagedBins,2)
[p,h,stats] = ranksum(base_fre1RCS.averagedBins(:,index),base_fre1Intraop.averagedBins(:,index));
statsResults.p(index)=p;
statsResults.h(index)=h;
statsResults.stats(index) = stats;
end

fig1 = figure;
line1 = stdshade(log10(base_fre1RCS.normalizedPow),0.5,'b');
hold on
line2 = stdshade(log10(base_fre1Intraop.normalizedPow),0.5,'r');
xlabel('Frequency (Hz)')
ylabel('Log Percentage of Total Power')
title('Comparison between normalized Clinic RCS and Intraoperative Neuroomega data')

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

legend([line1,line2],{'RCS','Intraoperative Neuroomega'});
