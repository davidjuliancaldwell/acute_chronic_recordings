plotRCSfuncs = 0;
interpolateNan = 0;
divideTrials = 0;

base_fre1RCSall = {};


for jjj = 1:length(pathDataRcs)

    splitPath = strsplit(pathDataRcs{jjj},'/');
    subject = splitPath{6}; % only for the defined paths on David's PC!

    processFlag = 2;
    shortGaps_systemTick = 0;

    try
        fprintf('\n=== Processing RCS Session %d/%d ===\n', jjj, length(pathDataRcs));

        [unifiedDerivedTimes, timeDomainData, timeDomainData_onlyTimeVariables,...
            timeDomain_timeVariableNames, AccelData, AccelData_onlyTimeVariables,...
            Accel_timeVariableNames, PowerData, PowerData_onlyTimeVariables,...
            Power_timeVariableNames, FFTData, FFTData_onlyTimeVariables,...
            FFT_timeVariableNames, AdaptiveData, AdaptiveData_onlyTimeVariables, ...
            Adaptive_timeVariableNames, timeDomainSettings, powerSettings, fftSettings, ...
            eventLogTable, metaData, stimSettingsOut, stimMetaData, stimLogSettings,...
            DetectorSettings, AdaptiveStimSettings, AdaptiveEmbeddedRuns_StimSettings] = ProcessRCS(pathDataRcs{jjj}, processFlag, shortGaps_systemTick);

dataStreams = {timeDomainData, AccelData, PowerData, FFTData, AdaptiveData};

[combinedDataTable] = createCombinedTable(dataStreams,unifiedDerivedTimes,metaData);

    % if we have knowledge from event table use this to trim down data
    if ~isempty(beginRCS)
        rcsBeginTime = eventLogTable.HostUnixTime(beginRCS(jjj));
        rcsEndTime = eventLogTable.HostUnixTime(endRCS(jjj));

        [valueStart,indexStart] = min(abs(rcsBeginTime-combinedDataTable.DerivedTime));
        [valueEnd,indexEnd] = min(abs(rcsEndTime-combinedDataTable.DerivedTime));

        combinedDataTable = combinedDataTable(indexStart:indexEnd,:);
    end

    %%
    if plotRCSfuncs
        rc = rcsPlotter();
        rc.addFolder(pathDataRcs{jjj});
        rc.loadData()
        %%
        chanInt = 4;
        rc.plotTdChannel(chanInt)
        rc.plotTdChannelBandpass(chanInt,[10,30])
        rc.plotTdChannelPsd(chanInt,minutes(1))
    end

    %% break up combined data table into sub recorded chunks
    if isempty(iterationInterestSpecific)
        iterations = unique(timeDomainSettings.recNum);
        structCombinedDataTable = {};
        chansStruct = {};
        iterationsVec = 1:length(iterations);
    else
        iterationsVec = iterationInterestSpecific(jjj);
        structCombinedDataTable = {};
        chansStruct = {};

    end

    index = 1;
    for jj =  iterationsVec

    beginning = timeDomainSettings.timeStart(jj);
    [~,minIndexStart] = min(abs(beginning - combinedDataTable.DerivedTime));
    ending = timeDomainSettings.timeStop(jj);
    [~,minIndexStop] = min(abs(ending  - combinedDataTable.DerivedTime));

    tempChans= {timeDomainSettings.TDsettings{jj}(:).chanOut};
    %     for jjj = 1:length(tempChans)
    %         splits = strsplit(tempChans{jjj},{'+','-'});
    %         chan1 = splits{2};
    %         chan2 = splits{3};
    %         chansStruct{jj}{jjj}={chan1,chan2};
    %     end

        chansStruct{index}=tempChans;

        structCombinedDataTable{index} = combinedDataTable(minIndexStart:minIndexStop,:);

        %% put into fieldtrip format


        dataRCSCell{index} = [structCombinedDataTable{index}.TD_key0';
            structCombinedDataTable{index}.TD_key1';
            structCombinedDataTable{index}.TD_key2';
            structCombinedDataTable{index}.TD_key3';];
    %%

    %backup sample rate, see below - may not actually be needed, as it seems if
    %there isn't data in timeDomainSettings.samplingRate the data wont be
    %usable
    tempSamplingRate = timeDomainSettings.TDsettings{jj}.sampleRate;

        if isnumeric(timeDomainSettings.samplingRate(jj))
            timeMatrixRCS =  repmat([0:length(structCombinedDataTable{index}.DerivedTime)-1]/timeDomainSettings.samplingRate(1),4,1);
            dataRCS.fsample = timeDomainSettings.samplingRate(1);    % sampling frequency in Hz, single number
        % Bug #39 fix: Use && for logical AND (short-circuit evaluation)
        elseif ((isnumeric(tempSamplingRate)) && (tempSamplingRate >0))
            timeMatrixRCS =  repmat([0:length(structCombinedDataTable{index}.DerivedTime)-1]/tempSamplingRate,4,1);
            dataRCS.fsample = tempSamplingRate;    % sampling frequency in Hz, single number
        end
        timeRCSCell{index} = timeMatrixRCS;
        %dataRCS.label = {'1' '2' '3' '4'};     % cell-array containing strings, Nchan*1


        % account for RCS times where some of the channels are the same to
        % avoid throwing an error with the label step below


        [labels,inds]= unique(chansStruct{index}, 'stable');

        % Add region prefix to channel labels to match intraop naming convention
        % Use rcsOrder{subjNum} to determine L/R side for this RCS session
        % ECoG channels: +8/+9/+10/+11 or -8/-9/-10/-11
        % LFP channels: 0-3
        labelsWithPrefix = cell(size(labels));
        sideLabel = rcsOrder{subjNum}{jjj}; % Get L or R for this session indexed by subjNum and then session index

    for labelIdx = 1:length(labels)
        chanLabel = labels{labelIdx};
        % Determine if this is ECoG or LFP based on contact numbers
        if contains(chanLabel, {'+8','+9','+10','+11','-8','-9','-10','-11'})
            % ECoG channel
            prefix = ['ECOG' sideLabel];
        else
            % LFP channel (contacts 0-3)
            prefix = ['LFP' sideLabel];
        end
        % Strip '+' character to match intraop naming convention
        chanLabel = strrep(chanLabel, '+', '');
        labelsWithPrefix{labelIdx} = [prefix chanLabel];
    end

        % Diagnostic: Check for NaN in raw data before trial creation
        nanCount = sum(isnan(dataRCSCell{index}), 'all');
        totalElements = numel(dataRCSCell{index});
        fprintf('Session %d Iteration %d RAW DATA: %d NaN values out of %d total (%.1f%%)\n', ...
            jjj, index, nanCount, totalElements, 100*nanCount/totalElements);

        if length(inds) == 4

            dataRCS.label = labelsWithPrefix;
            dataRCS.trial = {[dataRCSCell{index}]};     % cell-array containing a data matrix for each
            dataRCS.time = {timeRCSCell{index}};       % cell-array containing a time axis for each

        else
            tempData = dataRCSCell{index};
            tempDataSub = tempData(inds,:);
            tempTime = timeRCSCell{index};
            tempTimeSub = tempTime(inds,:);
            dataRCS.label=labelsWithPrefix;
            dataRCS.trial = {tempDataSub};
            dataRCS.time = {tempTimeSub};

        end
    % trial (1*Ntrial), each data matrix is a Nchan*Nsamples matrix
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
    %% ensure RCS data is resampled to 1000 Hz
    if dataRCS.fsample ~= 1000
        cfgRCS = [];
        cfgRCS.resamplefs = 1000;     %frequency at which the data will be resampled (default = 256 Hz)
        [dataPreProcRCS] = ft_resampledata(cfgRCS, dataPreProcRCS);
        fprintf('  After resampling: %d NaN values in trial 1\n', sum(isnan(dataPreProcRCS.trial{1}), 'all'));
    end
    %% divide trials
    % if divideTrials
    %     % find Nans
    %     exampleChan = dataPreProcRCS.trial{1}(1,:)';
    %     nanExamp = isnan(exampleChan);
    % end

    %% interpolate NaN
    if interpolateNan
        cfgInterp = [];
        dataPreProcRCS = ft_interpolatenan(cfgInterp, dataPreProcRCS);
    end

    %% Exclude dead channels (entirely NaN across recording)
    continuousData = dataPreProcRCS.trial{1}; % Single continuous trial
    numChans = size(continuousData, 1);
    badChannels = false(numChans, 1);

    for chanIdx = 1:numChans
        % Check if this channel is ALL NaN
        if all(isnan(continuousData(chanIdx,:)))
            badChannels(chanIdx) = true;
        end
    end

    % Exclude bad channels if any found
    if any(badChannels)
        badChanLabels = dataPreProcRCS.label(badChannels);
        goodChanLabels = dataPreProcRCS.label(~badChannels);
        fprintf('  Excluding %d dead channel(s): %s\n', sum(badChannels), strjoin(badChanLabels', ', '));

        cfg = [];
        cfg.channel = goodChanLabels;
        dataPreProcRCS = ft_selectdata(cfg, dataPreProcRCS);

        fprintf('  Continuing with %d good channel(s): %s\n', length(goodChanLabels), strjoin(goodChanLabels', ', '));
    else
        fprintf('  All %d channels are valid (no dead channels detected)\n', numChans);
    end

    %% power spectrum
    cfg1RCS = [];
    cfg1RCS.overlap = 0.5;
    cfg1RCS.length = 2;
    dataPreProcOverlapRCS = ft_redefinetrial(cfg1RCS,dataPreProcRCS);

    % Diagnostic: Check trials after redefinition
    numTrialsCreated = length(dataPreProcOverlapRCS.trial);
    fprintf('  After ft_redefinetrial: %d trials created\n', numTrialsCreated);
    if numTrialsCreated > 0
        fprintf('  First trial: %d NaN values\n', sum(isnan(dataPreProcOverlapRCS.trial{1}), 'all'));
    end

    % exclude any trial with NaN's
    numTrials = length(dataPreProcOverlapRCS.trial);
    keepTrial = ones(1,numTrials);
    % exclude nans - check ALL channels, not just first
    for iteration = 1:numTrials
        trialData = dataPreProcOverlapRCS.trial{iteration}; % ALL channels
        % Keep trial if ANY channel is completely NaN-free
        chanHasNoNaN = ~any(isnan(trialData), 2);  % Logical per channel
        if ~any(chanHasNoNaN)
            % ALL channels have NaN, exclude trial
            keepTrial(iteration) = 0;
        end
    end

    keepTrial = logical(keepTrial);

    % Diagnostic: Check how many trials are being kept
    numKept = sum(keepTrial);
    fprintf('RCS Session %d Iteration %d: %d total trials, %d kept, %d excluded\n', jjj, index, numTrials, numKept, numTrials-numKept);

    if numKept == 0
        error('All trials contain NaN values and were excluded. Check makeNan settings or time window.');
    end

    cfgKeepChannels = [];
    cfgKeepChannels.trials = keepTrial;
    dataPreProcOverlapRCS  = ft_preprocessing(cfgKeepChannels,dataPreProcOverlapRCS);

    cfg2RCS = [];
    cfg2RCS.output = 'pow';
    cfg2RCS.channel = 'all';
    cfg2RCS.method= 'mtmfft';
    cfg2RCS.taper = 'hanning';
    cfg2RCS.keeptrials='yes'; % put this to yes if want individual trials returned vs. average
    cfg2RCS.foi = [0.5:1:500];
    base_fre1RCS = ft_freqanalysis(cfg2RCS,dataPreProcOverlapRCS);

    % get mean power
    base_fre1RCS.totalPower = squeeze(sum(base_fre1RCS.powspctrm,3));
    base_fre1RCS.normalizedPow = 100*base_fre1RCS.powspctrm./repmat(base_fre1RCS.totalPower,1,1,size(base_fre1RCS.powspctrm,3));

        base_fre1RCSall.powspctrm{jjj}{index}=base_fre1RCS.powspctrm;
        base_fre1RCSall.totalPower{jjj}{index} = squeeze(sum(base_fre1RCS.powspctrm,3));
        base_fre1RCSall.normalizedPow{jjj}{index} = 100*base_fre1RCS.powspctrm./repmat(base_fre1RCS.totalPower,1,1,size(base_fre1RCS.powspctrm,3));
        base_fre1RCSall.chans{jjj}{index} = base_fre1RCS.label;  % Use labels AFTER channel exclusion

        % average across bins
        %freqEdges = [4 8;8 12; 13 20;20 30;50 200;13 30];
        freqEdges = [4 8;8 12; 13 20;20 30;50 125;250 350];

        base_fre1RCS.averagedBins = zeros(size(base_fre1RCS.totalPower,1),size(base_fre1RCS.totalPower,2),size(freqEdges,1));

        %theta (4–8Hz),alpha(8–12Hz),lowbeta(13–20Hz), highbeta(20–30Hz),beta(13–30Hz),broadbandgamma(50–200Hz),
        for binIdx = 1:size(freqEdges,1)
            indsInterest = (base_fre1RCS.freq <= freqEdges(binIdx,2)) & (base_fre1RCS.freq > freqEdges(binIdx,1));
            base_fre1RCS.averagedBins(:,:,binIdx) = sum(base_fre1RCS.normalizedPow(:,:,indsInterest),3);
            base_fre1RCSall.averagedBins{jjj}{index}(:,:,binIdx) = sum(base_fre1RCS.normalizedPow(:,:,indsInterest),3);
        end

        %% FOOOF Spectral Parameterization
        cfgFooof = [];
        cfgFooof.method = 'mtmfft';
        cfgFooof.output = 'fooof_aperiodic';  % Get aperiodic (1/f) component only
        cfgFooof.taper = 'hanning';
        cfgFooof.foi = 4:0.5:50;
        cfgFooof.keeptrials = 'no';
        cfgFooof.fooof.freq_range = [4 50];
        cfgFooof.fooof.peak_width_limits = [1 12];
        cfgFooof.fooof.max_peaks = 6;
        cfgFooof.fooof.min_peak_height = 0.1;
        cfgFooof.fooof.aperiodic_mode = 'fixed';
        cfgFooof.fooof.peak_threshold = 2.0;

        base_fre1RCS_fooof = ft_freqanalysis(cfgFooof, dataPreProcOverlapRCS);

        % Store FOOOF parameters and aperiodic model spectrum
        base_fre1RCSall.fooofparams{jjj}{index} = base_fre1RCS_fooof.fooofparams;
        % Store FOOOF frequency vector (same for all sessions/iterations)
        if ~isfield(base_fre1RCSall, 'fooof_freq')
            base_fre1RCSall.fooof_freq = base_fre1RCS_fooof.freq;
        end
        % Try powspctrm first - it should contain the FOOOF model
        if isfield(base_fre1RCS_fooof, 'powspctrm')
            base_fre1RCSall.fooof_powspctrm{jjj}{index} = base_fre1RCS_fooof.powspctrm;
        elseif isfield(base_fre1RCS_fooof, 'fooofapcfit')
            base_fre1RCSall.fooof_powspctrm{jjj}{index} = base_fre1RCS_fooof.fooofapcfit;
        else
            warning('No FOOOF power spectrum field found for session %d iter %d', jjj, index);
            base_fre1RCSall.fooof_powspctrm{jjj}{index} = [];
        end

        fprintf('RCS HFO FOOOF session %d iter %d complete.\n', jjj, index);

        %% plot power
        figure
        % Average across trials, plot first channel
        plot(base_fre1RCS.freq,log10(squeeze(mean(base_fre1RCS.powspctrm(:,1,:),1))))
        xlabel('Frequency (Hz)')
        ylabel('log Power')
        title([subject ' RCS PSD'])

        figure
        % Average across trials, plot first channel
        plot(base_fre1RCS.freq,log10(squeeze(mean(base_fre1RCS.normalizedPow(:,1,:),1))))
        xlabel('Frequency (Hz)')
        ylabel('Log Percent of Total Power')
        title([subject ' RCS PSD'])

        figure
        % Average across trials, plot first channel
        plot(squeeze(mean(base_fre1RCS.averagedBins(:,1,:),1))')
        xlabel('Frequency bins')
        ylabel('Percent of Total Power Across Bin RCS')

        index = index + 1;
    end

    catch ME
        warning('Failed to process RCS session %d: %s', jjj, ME.message);
        fprintf('Skipping this session and continuing with next...\n');
        continue;
    end
end

