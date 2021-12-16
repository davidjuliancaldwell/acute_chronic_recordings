%pathInt = 'C:\Users\david\Box\Patient In-Clinic Data\RCS02\v01_or_day\rcsData\Session1557272264386\DeviceNPC700398H';
%pathInt = 'C:\Users\david\Box\Patient In-Clinic Data\RCS02\v01_or_day\rcsData\Session1557272264386\DeviceNPC700404H';
pathInt = 'C:\Users\david\Box\Patient In-Clinic Data\RCS02\v02_postop\montage\Session1557330282531\DeviceNPC700398H';
processFlag = 2;
shortGaps_systemTick = 0;

[unifiedDerivedTimes, timeDomainData, timeDomainData_onlyTimeVariables,...
    timeDomain_timeVariableNames, AccelData, AccelData_onlyTimeVariables,...
    Accel_timeVariableNames, PowerData, PowerData_onlyTimeVariables,...
    Power_timeVariableNames, FFTData, FFTData_onlyTimeVariables,...
    FFT_timeVariableNames, AdaptiveData, AdaptiveData_onlyTimeVariables, ...
    Adaptive_timeVariableNames, timeDomainSettings, powerSettings, fftSettings, ...
    eventLogTable, metaData, stimSettingsOut, stimMetaData, stimLogSettings,...
    DetectorSettings, AdaptiveStimSettings, AdaptiveEmbeddedRuns_StimSettings] = ProcessRCS(pathInt, processFlag, shortGaps_systemTick);

dataStreams = {timeDomainData, AccelData, PowerData, FFTData, AdaptiveData};

[combinedDataTable] = createCombinedTable(dataStreams,unifiedDerivedTimes,metaData);

%%
rc = rcsPlotter();
rc.addFolder(pathInt);
rc.loadData()
%%
rc.plotTdChannel(1)
rc.plotTdChannelBandpass(1,[10,30])
rc.plotTdChannelPsd(1,minutes(1))


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

dataRCSCell{1} = [structCombinedDataTable{1}.TD_key0';
    structCombinedDataTable{1}.TD_key1';
    structCombinedDataTable{1}.TD_key2';
    structCombinedDataTable{1}.TD_key3';];

timeMatrix =  repmat([0:length(structCombinedDataTable{1}.DerivedTime)-1]/timeDomainSettings.samplingRate(1),4,1);
timeRCSCell{1} = timeMatrix;
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

cfg = [];
cfg.continuous = 'yes';
dataPreProc = ft_preprocessing(cfg,dataRCS);
%%
cfg = [];
cfg.resamplefs = 1000;     %frequency at which the data will be resampled (default = 256 Hz)
[dataPreProc] = ft_resampledata(cfg, dataPreProc);

%% interpolate NaN
cfgInterp = [];
dataPreProc = ft_interpolatenan(cfgInterp, dataPreProc);
%% power spectrum
cfg1 = [];
cfg1.overlap = 0.5;
cfg1.length = 2;
dataPreProcOverlap = ft_redefinetrial(cfg1,dataPreProc);

cfg2 = [];
cfg2.output = 'pow';
cfg2.channel = 'all';
cfg2.method= 'mtmfft';
cfg2.taper = 'boxcar';
cfg2.foi = [0.5:1:300];
base_fre1 = ft_freqanalysis(cfg2,dataPreProcOverlap);

%% plot power
figure
plot(base_fre1.freq,log10(base_fre1.powspctrm(1,:)))
xlabel('Frequency (Hz)')
ylabel('log Power')

