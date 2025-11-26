%%'Coupling between Beta and High-Frequency Activity in the
%Human Subthalamic Nucleus May Be a Pathophysiological
%Mechanism in Parkinson's Disease'


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
counter = 1;

%run(fullfile(getenv('matlab_devel_dir'),'patient_config_files',subject, 'patient_config_file.m'))

if includeECOG
    % ecog
    % setup sampling rates
    dataECOG = dataFile.ecog.contact;
    fsECOG = dataFile.ecog.Fs(1);
    fs = fsECOG;
    for jj = 1:length(dataECOG)
        dataInt = dataECOG(jj).raw_signal;
        timeVec = [0:length(dataInt)-1]/fs;
        dataMatrixIntraop = [dataMatrixIntraop; dataInt];
        timeMatrixIntraop = [timeMatrixIntraop;timeVec];
        if jj <=4
            chanCellIntraop{jj} = ['ECOGL' sprintf('%d',counter)];
            counter = counter + 1;
        elseif jj >4
            chanCellIntraop{jj} = ['ECOGR' sprintf('%d',counter)];
            counter = counter + 1;
        end
    end
end

if includeLFP
    % lfp
    dataLFP = dataFile.lfp.contact;
    fsLFP = dataFile.lfp.Fs(1);
    if ~exist('fs','var')
        fs= fsLFP;
    end
    for jj = 1:length(dataLFP)
        dataInt = dataLFP(jj).raw_signal;
        timeVec = [0:length(dataInt)-1]/fs;
        dataMatrixIntraop = [dataMatrixIntraop; dataInt];
        timeMatrixIntraop = [timeMatrixIntraop;timeVec];
        if jj <=4
            chanCellIntraop{counter} = ['LFPL' sprintf('%d',counter)];
            counter = counter + 1;
        elseif jj >4
            chanCellIntraop{counter} = ['LFPR' sprintf('%d',counter)];
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
        'ECOGL1','ECOGL2','ECOGL3','ECOGL4',...
        'ECOGR5','ECOGR6','ECOGR7','ECOGR8',...
        'LFPL9','LFPL10','LFPL11','LFPL12',...
        'LFPR13','LFPR14','LFPR15','LFPR16'
        };

    bipolarSkip_montage.labelnew  = {
        'ECOGL2-0','ECOGL3-1',...
        'ECOGR6-4','ECOGR7-5',...
        'LFPL10-8','LFPL11-9',...
        'LFPR14-12','LFPR15-13',
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

    bipolarSkip_montage.labelnew  = {
        'ECOG2-0','ECOG3-1',...
        'LFP10-8','LFP11-9',...
        };
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
cfgIntraop.resamplefs = 1000;     %frequency at which the data will be resampled (default = 256 Hz)
[dataPreProcIntraop] = ft_resampledata(cfgIntraop, dataPreProcIntraop);
%% power spectrum
cfg1Intraop = [];
cfg1Intraop.overlap = 0.5;
cfg1Intraop.length = 2;
dataPreProcOverlapIntraop = ft_redefinetrial(cfg1Intraop,dataPreProcIntraop);

cfg2Intraop = [];
cfg2Intraop.output = 'pow';
cfg2Intraop.channel = 'all';
cfg2Intraop.method= 'mtmfft';
cfg2Intraop.taper = 'boxcar';
cfg2Intraop.keeptrials='no'; % put this to yes if want individual trials returned vs. average
cfg2Intraop.foi = [0.5:1:500];
base_fre1Intraop = ft_freqanalysis(cfg2Intraop,dataPreProcOverlapIntraop);

% get mean power
base_fre1Intraop.totalPower = sum(base_fre1Intraop.powspctrm,2);
base_fre1Intraop.normalizedPow = 100*base_fre1Intraop.powspctrm./repmat(base_fre1Intraop.totalPower,1,size(base_fre1Intraop.powspctrm,2));

% average across bins
%freqEdges = [4 8;8 12; 13 20;20 30;50 200;13 30];
freqEdges = [4 8;8 12; 13 20;20 30;50 125;250 350];
%theta (4–8Hz),alpha(8–12Hz),lowbeta(13–20Hz), highbeta(20–30Hz),beta(13–30Hz),broadbandgamma(50–200Hz),
for index = 1:size(freqEdges,1)
    indsInterest = (base_fre1Intraop.freq <= freqEdges(index,2)) & (base_fre1Intraop.freq > freqEdges(index,1));
    base_fre1Intraop.averagedBins(:,index) = sum(base_fre1Intraop.normalizedPow(:,indsInterest),2);
end

%% plot power
figure
plot(base_fre1Intraop.freq,log10(base_fre1Intraop.powspctrm(7,:)))
xlabel('Frequency (Hz)')
ylabel('log Power')
title([subject ' Intraoperative Neuroomega PSD'])

figure
plot(base_fre1Intraop.freq,log10(base_fre1Intraop.normalizedPow(7,:)))
xlabel('Frequency (Hz)')
ylabel('Log Percent of Total Power')
title([subject ' Intraoperative Neuroomega PSD'])
%%
figure
plot(base_fre1Intraop.averagedBins')
xlabel('Frequency bins')
ylabel('Percent of Total Power Across Bin Intraoperative Neuroomega')

%% working on phase amplitude coupling 

cfgCrossFreq =[];
cfgCrossFreq.method = 'mi';
cfgCrossFreq.keeptrials = 'yes';
cfgCrossFreq.freqlow = [12 30];
cfgCrossFreq.freqhigh = [250 350];

%crossfreq = ft_crossfrequencyanalysis(cfgCrossFreq,base_fre1Intraop);

% Use as
%   crossfreq = ft_crossfrequencyanalysis(cfg, freqlo, freqhi)
% where freq is frequency decomposed data structure as obtained from FT_FREQANALYSIS
% and cfg is a configuration structure that should contain
%
%   cfg.freqlow     scalar or vector, selection of frequencies for the low frequency data
%   cfg.freqhigh    scalar or vector, selection of frequencies for the high frequency data
%   cfg.chanlow     selection of channels for the low frequency, see FT_CHANNELSELECTION
%   cfg.chanhigh    selection of channels for the high frequency, see FT_CHANNELSELECTION
%   cfg.method      'plv' - phase locking value
%                   'mvl' - mean vector length
%                   'mi'  - modulaiton index
%   cfg.keeptrials  string, can be 'yes' or 'no'




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