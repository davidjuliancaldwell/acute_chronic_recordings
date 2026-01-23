%% load intraop data
dataFile = load(pathDataIntraOp);

%% define work place variables
splitPath = strsplit(pathDataIntraOp,'/');
subject = splitPath{6}; % only for the defined paths above!
dataCellIntraop = {};
timeCellIntraop = {};
chanCellIntraop = {};
dataMatrixIntraop = [];
timeMatrixIntraop = [];
includeLFP = true;
includeECOG = true;
counter = 0;

if includeLFP
    % lfp
    dataLFP = dataFile.lfp.contact;
    fsLFP = dataFile.lfp.Fs(1);
    fs = fsLFP;

    for jj = 1:length(dataLFP)
        dataInt = dataLFP(jj).raw_signal;
        % subselect data of interest after manual data quality check
        if ~isempty(makeNan{subjNum})
            for nanInd = 1:length(startIntraop)
                dataInt(startIntraop(nanInd):endIntraop(nanInd)) = NaN;
            end
        end
        timeVec = [0:length(dataInt)-1]/fs;
        dataMatrixIntraop = [dataMatrixIntraop; dataInt];
        timeMatrixIntraop = [timeMatrixIntraop;timeVec];
        % Number LFP channels 0-3 to match RCS convention
        % Use sidesToUse to determine hemisphere labeling
        if strcmp(sidesToUse,'b')
            % Bilateral: channels 1-4 are LEFT, 5-8 are RIGHT
            if jj <=4
                chanCellIntraop{counter+1} = ['LFPL' sprintf('%d',jj-1)];
                counter = counter + 1;
            elseif jj > 4
                chanCellIntraop{counter+1} = ['LFPR' sprintf('%d',jj-5)];
                counter = counter + 1;
            end
        elseif strcmp(sidesToUse,'l')
            % Left only: all channels are LEFT
            chanCellIntraop{counter+1} = ['LFPL' sprintf('%d',jj-1)];
            counter = counter + 1;
        elseif strcmp(sidesToUse,'r')
            % Right only: all channels are RIGHT
            chanCellIntraop{counter+1} = ['LFPR' sprintf('%d',jj-1)];
            counter = counter + 1;
        end
    end
end

if includeECOG
    % ecog
    % setup sampling rates
    dataECOG = dataFile.ecog.contact;
    fsECOG = dataFile.ecog.Fs(1);
    if ~exist('fs','var')
        fs= fsECOG;
    end
    for jj = 1:length(dataECOG)
        dataInt = dataECOG(jj).raw_signal;
        % subselect data of interest after manual data quality check
        if ~isempty(makeNan{subjNum})
            for nanInd = 1:length(startIntraop)
                dataInt(startIntraop(nanInd):endIntraop(nanInd)) = NaN;
            end
        end
        timeVec = [0:length(dataInt)-1]/fs;
        dataMatrixIntraop = [dataMatrixIntraop; dataInt];
        timeMatrixIntraop = [timeMatrixIntraop;timeVec];
        % Number ECoG channels 8-11 to match RCS convention
        % Use sidesToUse to determine hemisphere labeling
        if strcmp(sidesToUse,'b')
            % Bilateral: channels 1-4 are LEFT, 5-8 are RIGHT
            if jj <=4
                chanCellIntraop{counter+1} = ['ECOGL' sprintf('%d',jj+7)];
                counter = counter + 1;
            elseif jj >4
                chanCellIntraop{counter+1} = ['ECOGR' sprintf('%d',jj+3)];
                counter = counter + 1;
            end
        elseif strcmp(sidesToUse,'l')
            % Left only: all channels are LEFT
            chanCellIntraop{counter+1} = ['ECOGL' sprintf('%d',jj+7)];
            counter = counter + 1;
        elseif strcmp(sidesToUse,'r')
            % Right only: all channels are RIGHT
            chanCellIntraop{counter+1} = ['ECOGR' sprintf('%d',jj+7)];
            counter = counter + 1;
        end
    end
end


dataCellIntraop{1} = dataMatrixIntraop;
timeCellIntraop{1} = timeMatrixIntraop;

dataIntraop.label = chanCellIntraop;     % cell-array containing strings, Nchan*1
dataIntraop.fsample = fs;    % sampling frequency in Hz, single number
dataIntraop.trial = dataCellIntraop;     % cell-array containing a data matrix for each
% trial (1*Ntrial), each data matrix is a Nchan*Nsamples matrix
dataIntraop.time = timeCellIntraop;       % cell-array containing a time axis for each
% trial (1*Ntrial), each time axis is a 1*Nsamples vector
%data.trialinfo  % this field is optional, but can be used to store
% trial-specific information, such as condition numbers,
% reaction times, correct responses etc. The dimensionality
% is Ntrial*M, where M is an arbitrary number of columns.
%data.sampleinfo % optional array (Ntrial*2) containing the start and end
% sample of each trial
%% preprocess

% here we do the rereferencing

if strcmp(rerefChoice,'bipolarReref')
    cfgIntraop = [];
    cfgIntraop.continuous = 'yes';
    cfgIntraop.reref = 'yes';
    cfgIntraop.refmethod = 'bipolar';
    cfgIntraop.refchannel = 'all';
    cfgIntraop.groupchans = 'yes';
    dataPreProcIntraop = ft_preprocessing(cfgIntraop,dataIntraop);
elseif strcmp(rerefChoice,'bipolarSkipReref') & length(dataIntraop.label)==16

    bipolarSkip_montage.labelold  = {
        'LFPL0','LFPL1','LFPL2','LFPL3',...
        'LFPR0','LFPR1','LFPR2','LFPR3',...
        'ECOGL8','ECOGL9','ECOGL10','ECOGL11',...
        'ECOGR8','ECOGR9','ECOGR10','ECOGR11'
        };

    bipolarSkip_montage.labelnew  = {
        'LFPL2-0','LFPL3-1',...
        'LFPR2-0','LFPR3-1',...
        'ECOGL10-8','ECOGL11-9',...
        'ECOGR10-8','ECOGR11-9',
        };
    bipolarSkip_montage.tra       = [
        -1 0 +1  0  0  0  0  0  0  0  0  0  0  0  0  0
        0 -1  0 +1  0  0  0  0  0  0  0  0  0  0  0  0
        0  0  0  0 -1  0 +1  0  0  0  0  0  0  0  0  0
        0  0  0  0  0 -1  0 +1  0  0  0  0  0  0  0  0
        0  0  0  0  0  0  0  0 -1  0 +1  0  0  0  0  0
        0  0  0  0  0  0  0  0  0 -1  0 +1  0  0  0  0
        0  0  0  0  0  0  0  0  0  0  0  0 -1  0 +1  0
        0  0  0  0  0  0  0  0  0  0  0  0  0 -1  0 +1
        ];
    cfgIntraop= [];
    cfgIntraop.channel = 'all'; % this is the default
    cfgIntraop.reref = 'no'; % use the cfg.montage option instead
    cfgIntraop.montage = bipolarSkip_montage;
    dataPreProcIntraop = ft_preprocessing(cfgIntraop,dataIntraop);
elseif strcmp(rerefChoice,'bipolarSkipReref') & length(dataIntraop.label)==8

    bipolarSkip_montage.labelold  = dataIntraop.label;

    % Determine side (L or R) from the labels
    % Check for LFPL or ECOGL (not just 'L' which matches both LFPL and LFPR)
    if contains(dataIntraop.label{1},'LFPL') || contains(dataIntraop.label{1},'ECOGL')
        bipolarSkip_montage.labelnew  = {
            'LFPL2-0','LFPL3-1',...
            'ECOGL10-8','ECOGL11-9',...
            };
    else
        bipolarSkip_montage.labelnew  = {
            'LFPR2-0','LFPR3-1',...
            'ECOGR10-8','ECOGR11-9',...
            };
    end
    bipolarSkip_montage.tra       = [
        -1 0 +1  0  0  0  0  0
        0 -1  0 +1  0  0  0  0
        0  0  0  0 -1  0 +1  0
        0  0  0  0  0 -1  0 +1
        ];
    cfgIntraop= [];
    cfgIntraop.channel = 'all'; % this is the default
    cfgIntraop.reref = 'no'; % use the cfg.montage option instead
    cfgIntraop.montage = bipolarSkip_montage;
    dataPreProcIntraop = ft_preprocessing(cfgIntraop,dataIntraop);
end
%%
cfgIntraop = [];
cfgIntraop.resamplefs = 250;     %frequency at which the data will be resampled (default = 256 Hz)
[dataPreProcIntraop] = ft_resampledata(cfgIntraop, dataPreProcIntraop);

%% Exclude dead channels (entirely NaN across recording)
continuousData = dataPreProcIntraop.trial{1}; % Single continuous trial
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
    badChanLabels = dataPreProcIntraop.label(badChannels);
    goodChanLabels = dataPreProcIntraop.label(~badChannels);
    fprintf('Intraop: Excluding %d dead channel(s): %s\n', sum(badChannels), strjoin(badChanLabels', ', '));

    cfg = [];
    cfg.channel = goodChanLabels;
    dataPreProcIntraop = ft_selectdata(cfg, dataPreProcIntraop);

    fprintf('Intraop: Continuing with %d good channel(s): %s\n', length(goodChanLabels), strjoin(goodChanLabels', ', '));
else
    fprintf('Intraop: All %d channels are valid (no dead channels detected)\n', numChans);
end

%% power spectrum
cfg1Intraop = [];
cfg1Intraop.overlap = 0.5;
cfg1Intraop.length = 2;
dataPreProcOverlapIntraop = ft_redefinetrial(cfg1Intraop,dataPreProcIntraop);

% exclude any trial with NaN's
numTrials = length(dataPreProcOverlapIntraop.trial);
keepTrial = ones(1,numTrials);
% exclude nans - check ALL channels, not just first
for iteration = 1:numTrials
    trialData = dataPreProcOverlapIntraop.trial{iteration}; % ALL channels
    % Keep trial if ANY channel is completely NaN-free
    chanHasNoNaN = ~any(isnan(trialData), 2);  % Logical per channel
    if ~any(chanHasNoNaN)
        % ALL channels have NaN, exclude trial
        keepTrial(iteration) = 0;
    end
end

keepTrial = logical(keepTrial);

cfgKeepChannels = [];
cfgKeepChannels.trials = keepTrial;
dataPreProcOverlapIntraop  = ft_preprocessing(cfgKeepChannels,dataPreProcOverlapIntraop);

cfg2Intraop = [];
cfg2Intraop.output = 'pow';
cfg2Intraop.channel = 'all';
cfg2Intraop.method= 'mtmfft';
cfg2Intraop.taper = 'hanning';
cfg2Intraop.keeptrials='yes'; % put this to yes if want individual trials returned vs. average
cfg2Intraop.foi = [0.5:1:125];
base_fre1Intraop = ft_freqanalysis(cfg2Intraop,dataPreProcOverlapIntraop);

% get mean power
base_fre1Intraop.totalPower = squeeze(sum(base_fre1Intraop.powspctrm,3));
base_fre1Intraop.normalizedPow = 100*base_fre1Intraop.powspctrm./repmat(base_fre1Intraop.totalPower,1,1,size(base_fre1Intraop.powspctrm,3));

% average across bins
%freqEdges = [4 8;8 12; 13 20;20 30;50 200;13 30];
freqEdges = [4 8;8 12; 13 20;20 30;50 125];
%theta (4–8Hz),alpha(8–12Hz),lowbeta(13–20Hz), highbeta(20–30Hz),beta(13–30Hz),broadbandgamma(50–200Hz),
base_fre1Intraop.averagedBins = zeros(size(base_fre1Intraop.totalPower,1),size(base_fre1Intraop.totalPower,2),size(freqEdges,1));
for index = 1:size(freqEdges,1)
    indsInterest = (base_fre1Intraop.freq <= freqEdges(index,2)) & (base_fre1Intraop.freq > freqEdges(index,1));
    base_fre1Intraop.averagedBins(:,:,index) = sum(base_fre1Intraop.normalizedPow(:,:,indsInterest),3);
end

%% FOOOF Spectral Parameterization (using FieldTrip/Brainstorm)
% FOOOF requires trial-averaged data, so run separately
cfgFooof = [];
cfgFooof.method = 'mtmfft';
cfgFooof.output = 'fooof_aperiodic';  % Get aperiodic (1/f) component only
cfgFooof.taper = 'hanning';
cfgFooof.foi = 4:0.5:50;  % 4-50 Hz for FOOOF fitting
cfgFooof.keeptrials = 'no';  % Required for FOOOF
cfgFooof.fooof.freq_range = [4 50];
cfgFooof.fooof.peak_width_limits = [1 12];
cfgFooof.fooof.max_peaks = 6;
cfgFooof.fooof.min_peak_height = 0.1;
cfgFooof.fooof.aperiodic_mode = 'fixed';
cfgFooof.fooof.peak_threshold = 2.0;

base_fre1Intraop_fooof = ft_freqanalysis(cfgFooof, dataPreProcOverlapIntraop);

% Store FOOOF parameters and aperiodic model spectrum
base_fre1Intraop.fooofparams = base_fre1Intraop_fooof.fooofparams;
% Try powspctrm first - it should contain the FOOOF model
if isfield(base_fre1Intraop_fooof, 'powspctrm')
    base_fre1Intraop.fooof_powspctrm = base_fre1Intraop_fooof.powspctrm;
elseif isfield(base_fre1Intraop_fooof, 'fooofapcfit')
    base_fre1Intraop.fooof_powspctrm = base_fre1Intraop_fooof.fooofapcfit;
else
    warning('No FOOOF power spectrum field found');
    base_fre1Intraop.fooof_powspctrm = [];
end
base_fre1Intraop.fooof_freq = base_fre1Intraop_fooof.freq;

fprintf('Intraop FOOOF complete. Channels processed: %d\n', length(base_fre1Intraop.fooofparams));

%% plot power
chanInt = 1;

figure
plot(base_fre1Intraop.freq,log10(squeeze(mean(base_fre1Intraop.powspctrm(:,chanInt,:),1))))
xlabel('Frequency (Hz)')
ylabel('log Power')
title([subject ' Intraoperative Neuroomega PSD'])

figure
plot(base_fre1Intraop.freq,log10(squeeze(mean(base_fre1Intraop.normalizedPow(:,chanInt,:),1))))
xlabel('Frequency (Hz)')
ylabel('Log Percent of Total Power')
title([subject ' Intraoperative Neuroomega PSD'])

figure
plot(squeeze(mean(base_fre1Intraop.averagedBins,1))')
xlabel('Frequency bins')
ylabel('Percent of Total Power Across Bin Intraoperative Neuroomega')


% think about normalized power across whole contact? so it's % of power
% then bin across a given frequency band?
% rank sum + FDR correction for comparisons of power ?

%Pallidal Deep-Brain Stimulation Disrupts Pallidal Beta Oscillations and Coherence with Primary Motor Cortex in Parkinson’s Disease
%Spectral power. PSD was calculated using the Welch periodogram method (MATLAB function pwelch). For PSD calculations, we used a fast Fourier transform of 1024 points (for a frequency resolution of 0.95 Hz)and50%overlapusingaHannwindowtoreduceedgeeffects.Power was normalized as percentage of total power between 4 and 100 Hz excluding 55–65 Hz line noise (Silberstein et al., 2003). Percentage total power of the resulting normalization was averaged across the following frequency bands: theta (4–8Hz),alpha(8–12Hz),lowbeta(13–20Hz), highbeta(20–30Hz),beta(13–30Hz),broadbandgamma(50–200Hz), and high-frequency oscillations (HFO; 200–400 Hz).

% %% spectrogram
% cfg = [];
% cfg.keeptrials = 'yes';
% cfg.channel    = 'all';
% cfg.method     = 'wavelet';
% cfg.width      = 7;
% cfg.output     = 'pow';
% cfg.foi        = 1:2:500;
% cfg.toi        = 'all';
% TFRwave = ft_freqanalysis(cfg, dataPreProc);
%
% %%
% cfg = [];
% cfg.baseline     = 'no';
% cfg.maskstyle    = 'saturation';
% %cfg.zlim         = [-2.5e-27 2.5e-27];
% cfg.channel      = '1';
% figure
% ft_singleplotTFR(cfg, TFRwave);