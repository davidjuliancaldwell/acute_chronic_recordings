

splitPath = strsplit(pathDataRcs,'\');
subject = splitPath{6}; % only for the defined paths on David's PC!

processFlag = 2;
shortGaps_systemTick = 0;

[unifiedDerivedTimes, timeDomainData, timeDomainData_onlyTimeVariables,...
    timeDomain_timeVariableNames, AccelData, AccelData_onlyTimeVariables,...
    Accel_timeVariableNames, PowerData, PowerData_onlyTimeVariables,...
    Power_timeVariableNames, FFTData, FFTData_onlyTimeVariables,...
    FFT_timeVariableNames, AdaptiveData, AdaptiveData_onlyTimeVariables, ...
    Adaptive_timeVariableNames, timeDomainSettings, powerSettings, fftSettings, ...
    eventLogTable, metaData, stimSettingsOut, stimMetaData, stimLogSettings,...
    DetectorSettings, AdaptiveStimSettings, AdaptiveEmbeddedRuns_StimSettings] = ProcessRCS(pathDataRcs, processFlag, shortGaps_systemTick);

dataStreams = {timeDomainData, AccelData, PowerData, FFTData, AdaptiveData};

[combinedDataTable] = createCombinedTable(dataStreams,unifiedDerivedTimes,metaData);

%%
rc = rcsPlotter();
rc.addFolder(pathDataRcs);
rc.loadData()
%%
chanInt = 4;
rc.plotTdChannel(chanInt)
rc.plotTdChannelBandpass(chanInt,[10,30])
rc.plotTdChannelPsd(chanInt,minutes(1))


%% break up combined data table into sub recorded chunks
iterations = unique(timeDomainSettings.recNum);
structCombinedDataTable = {};

for jj = 1:length(iterations) 

    beginning = timeDomainSettings.timeStart(jj); 
    [~,minIndexStart] = min(abs(beginning - combinedDataTable.DerivedTime));
    ending = timeDomainSettings.timeStop(jj);
    [~,minIndexStop] = min(abs(ending  - combinedDataTable.DerivedTime));

    structCombinedDataTable{jj} = combinedDataTable(minIndexStart:minIndexStop,:);

end

%% put into fieldtrip format 
iterationInt = 2;

dataRCSCell{1} = [structCombinedDataTable{iterationInt}.TD_key0';
    structCombinedDataTable{iterationInt}.TD_key1';
    structCombinedDataTable{iterationInt}.TD_key2';
    structCombinedDataTable{iterationInt}.TD_key3';];

timeMatrixRCS =  repmat([0:length(structCombinedDataTable{iterationInt}.DerivedTime)-1]/timeDomainSettings.samplingRate(1),4,1);
timeRCSCell{1} = timeMatrixRCS;
dataRCS.label = {'1' '2' '3' '4'};     % cell-array containing strings, Nchan*1
dataRCS.fsample = timeDomainSettings.samplingRate(1);    % sampling frequency in Hz, single number
dataRCS.trial = dataRCSCell;     % cell-array containing a data matrix for each
% trial (1*Ntrial), each data matrix is a Nchan*Nsamples matrix
dataRCS.time = timeRCSCell;       % cell-array containing a time axis for each
% trial (1*Ntrial), each time axis is a 1*Nsamples vector
%data.trialinfo  % this field is optional, but can be used to store
% trial-specific information, such as condition numbers,
% reaction times, correct responses etc. The dimensionality
% is Ntrial*M, where M is an arbitrary number of columns.
%data.sampleinfo % optional array (Ntrial*2) containing the start and end
% sample of each trial
%% preprocess

cfgRCS = [];
cfgRCS.continuous = 'yes';
dataPreProcRCS = ft_preprocessing(cfgRCS,dataRCS);
%%
cfgRCS = [];
cfgRCS.resamplefs = 1000;     %frequency at which the data will be resampled (default = 256 Hz)
[dataPreProcRCS] = ft_resampledata(cfgRCS, dataPreProcRCS);

%% interpolate NaN
cfgInterp = [];
dataPreProcRCS = ft_interpolatenan(cfgInterp, dataPreProcRCS);
%% power spectrum
cfg1RCS = [];
cfg1RCS.overlap = 0.5;
cfg1RCS.length = 2;
dataPreProcOverlapRCS = ft_redefinetrial(cfg1RCS,dataPreProcRCS);

cfg2RCS = [];
cfg2RCS.output = 'pow';
cfg2RCS.channel = 'all';
cfg2RCS.method= 'mtmfft';
cfg2RCS.taper = 'boxcar';
cfg2RCS.foi = [0.5:1:125];
base_fre1RCS = ft_freqanalysis(cfg2RCS,dataPreProcOverlapRCS);

% get mean power 
base_fre1RCS.totalPower = sum(base_fre1RCS.powspctrm,2);
base_fre1RCS.normalizedPow = 100*base_fre1RCS.powspctrm./repmat(base_fre1RCS.totalPower,1,size(base_fre1RCS.powspctrm,2));

% average across bins
freqEdges = [4 8;8 12; 13 20;20 30;50 200;13 30];
%theta (4–8Hz),alpha(8–12Hz),lowbeta(13–20Hz), highbeta(20–30Hz),beta(13–30Hz),broadbandgamma(50–200Hz), 
for index = 1:size(freqEdges,1)
indsInterest = (base_fre1RCS.freq <= freqEdges(index,2)) & (base_fre1RCS.freq > freqEdges(index,1));
base_fre1RCS.averagedBins(:,index) = sum(base_fre1RCS.normalizedPow(:,indsInterest),2);
end

%% plot power
figure
plot(base_fre1RCS.freq,log10(base_fre1RCS.powspctrm(1,:)))
xlabel('Frequency (Hz)')
ylabel('log Power')
title([subject ' RCS PSD'])

figure
plot(base_fre1RCS.freq,log10(base_fre1RCS.normalizedPow(1,:)))
xlabel('Frequency (Hz)')
ylabel('Log Percent of Total Power')
title([subject ' RCS PSD'])

figure
plot(base_fre1RCS.averagedBins')
xlabel('Frequency bins')
ylabel('Percent of Total Power Across Bin RCS')

