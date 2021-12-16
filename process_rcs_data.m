%pathInt = 'C:\Users\david\Box\Patient In-Clinic Data\RCS02\v01_or_day\rcsData\Session1557272264386\DeviceNPC700398H';
%pathInt = 'C:\Users\david\Box\Patient In-Clinic Data\RCS02\v01_or_day\rcsData\Session1557272264386\DeviceNPC700404H';
pathInt = 'C:\Users\david\Box\Patient In-Clinic Data\RCS02\v02_postop\montage\Session1557330282531\DeviceNPC700398H';

splitPath = strsplit(pathData,'\');
subject = splitPath{6}; % only for the defined paths above!

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

%% plot power
figure
plot(base_fre1RCS.freq,log10(base_fre1RCS.powspctrm(1,:)))
xlabel('Frequency (Hz)')
ylabel('log Power')
title([subject ' RCS PSD'])

