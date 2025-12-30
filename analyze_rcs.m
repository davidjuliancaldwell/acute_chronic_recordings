plotRCSfuncs = 0;
interpolateNan = 0;
divideTrials = 0;

base_fre1RCSall = {};


for jjj = 1:length(pathDataRcs)

    splitPath = strsplit(pathDataRcs{jjj},'/');
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
        DetectorSettings, AdaptiveStimSettings, AdaptiveEmbeddedRuns_StimSettings] = ProcessRCS(pathDataRcs{jjj}, processFlag, shortGaps_systemTick);

    dataStreams = {timeDomainData, AccelData, PowerData, FFTData, AdaptiveData};

    [combinedDataTable] = createCombinedTable(dataStreams,unifiedDerivedTimes,metaData);

    % if we have knowledge from event table use this to trim down data
    if ~isempty('beginRCS')
        rcsBeginTime = eventLogTable.HostUnixTime(beginRCS(jjj));
        rcsEndTime = eventLogTable.HostUnixTime(endRCS(jjj));

        [valueStart,indexStart] = min(abs(rcsBeginTime-combinedDataTable.DerivedTime));
        [valueEnd,indexEnd] = min(abs(rcsEndTime-combinedDataTable.DerivedTime));

        combinedDataTable = combinedDataTable(indexStart:indexEnd,:);
    end

    %%
    if plotRCSfuncs
        rc = rcsPlotter();
        rc.addFolder(pathDataRcs);
        rc.loadData()
        %
        chanInt = 1;
        rc.plotTdChannel(chanInt)
        rc.plotTdChannelBandpass(chanInt,[10,30])
        rc.plotTdChannelPsd(chanInt,minutes(1))
    end

    %% break up combined data table into sub recorded chunks

    % if we have pre-identified montage of interest you would select it
    % here
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
        elseif ((isnumeric(tempSamplingRate)) & (tempSamplingRate >0))
            timeMatrixRCS =  repmat([0:length(structCombinedDataTable{index}.DerivedTime)-1]/tempSamplingRate,4,1);
            dataRCS.fsample = tempSamplingRate;    % sampling frequency in Hz, single number
        end
        timeRCSCell{index} = timeMatrixRCS;
        %dataRCS.label = {'1' '2' '3' '4'};     % cell-array containing strings, Nchan*1


        % account for RCS times where some of the channels are the same to
        % avoid throwing an error with the label step below


        [labels,inds]= unique(chansStruct{index});

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
        %% ensure RCS data is resampled to 250 Hz, which it usually is
        if dataRCS.fsample ~= 250
            cfgRCS = [];
            cfgRCS.resamplefs = 250;     %frequency at which the data will be resampled (default = 256 Hz)
            [dataPreProcRCS] = ft_resampledata(cfgRCS, dataPreProcRCS);
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

        %% power spectrum
        cfg1RCS = [];
        cfg1RCS.overlap = 0.5;
        cfg1RCS.length = 2;
        dataPreProcOverlapRCS = ft_redefinetrial(cfg1RCS,dataPreProcRCS);

        % exclude any trial with NaN's
        numTrials = length(dataPreProcOverlapRCS.trial);
        keepTrial = ones(1,numTrials);
        % exclude nans
        for iteration = 1:numTrials
            tempData = dataPreProcOverlapRCS.trial{iteration}(1,:); % first channel
            indsNan = isnan(tempData);
            if sum(indsNan)>0
                keepTrial(iteration)=0;
            end
        end

        keepTrial = logical(keepTrial);

        cfgKeepChannels = [];
        cfgKeepChannels.trials = keepTrial;
        dataPreProcOverlapRCS  = ft_preprocessing(cfgKeepChannels,dataPreProcOverlapRCS);

        cfg2RCS = [];
        cfg2RCS.output = 'pow';
        cfg2RCS.channel = 'all';
        cfg2RCS.method= 'mtmfft';
        cfg2RCS.taper = 'hanning';
        cfg2RCS.keeptrials='yes'; % put this to yes if want individual trials returned vs. average
        cfg2RCS.foi = [0.5:1:125];
        base_fre1RCS = ft_freqanalysis(cfg2RCS,dataPreProcOverlapRCS);

        % get mean power
        base_fre1RCS.totalPower = squeeze(sum(base_fre1RCS.powspctrm,3));
        base_fre1RCS.normalizedPow = 100*base_fre1RCS.powspctrm./repmat(base_fre1RCS.totalPower,1,1,size(base_fre1RCS.powspctrm,3));

        base_fre1RCSall.powspctrm{jjj}{index}=base_fre1RCS.powspctrm;
        base_fre1RCSall.totalPower{jjj}{index} = squeeze(sum(base_fre1RCS.powspctrm,3));
        base_fre1RCSall.normalizedPow{jjj}{index} = 100*base_fre1RCS.powspctrm./repmat(base_fre1RCS.totalPower,1,1,size(base_fre1RCS.powspctrm,3));
        base_fre1RCSall.chans{jjj}{index} = dataRCS.label;

        % average across bins
        %freqEdges = [4 8;8 12; 13 20;20 30;50 200;13 30];
        freqEdges = [4 8;8 12; 13 20;20 30;50 125];

        base_fre1RCS.averagedBins = zeros(size(base_fre1RCS.totalPower,1),size(base_fre1RCS.totalPower,2),size(freqEdges,1));

        %theta (4–8Hz),alpha(8–12Hz),lowbeta(13–20Hz), highbeta(20–30Hz),beta(13–30Hz),broadbandgamma(50–200Hz),
        for indexFreq = 1:size(freqEdges,1)
            indsInterest = (base_fre1RCS.freq <= freqEdges(indexFreq,2)) & (base_fre1RCS.freq > freqEdges(indexFreq,1));
            base_fre1RCS.averagedBins(:,:,indexFreq) = sum(base_fre1RCS.normalizedPow(:,:,indsInterest),3);
            base_fre1RCSall.averagedBins{jjj}{index}(:,:,indexFreq) = sum(base_fre1RCS.normalizedPow(:,:,indsInterest),3);
        end

        %% plot power
        chanInt = 1;

        figure
        plot(base_fre1RCS.freq,log10(squeeze(mean(base_fre1RCS.powspctrm(:,chanInt,:),1))))
        xlabel('Frequency (Hz)')
        ylabel('log Power')
        title([subject ' RCS PSD'])

        figure
        plot(base_fre1RCS.freq,log10(squeeze(mean(base_fre1RCS.normalizedPow(:,chanInt,:),1))))
        xlabel('Frequency (Hz)')
        ylabel('Log Percent of Total Power')
        title([subject ' RCS PSD'])

        figure
        plot(squeeze(mean(base_fre1RCS.averagedBins,1))')
        xlabel('Frequency bins')
        ylabel('Percent of Total Power Across Bin RCS')
    end

end

