%% load intraop data
%dataFile = load('C:\Users\david\Box\Patient In-Clinic Data\RCS02\v01_or_day\NeuroOmega\maria_analysis\RCS02_bilatM1_bilatlfp_rest_postlead.mat');
dataFile = load('C:\Users\david\Box\Patient In-Clinic Data\RCS03\study_visits\OR_2ndside\analyzed\RCS03_04_Recog_Rlfp_rest_raw_ecog.mat');
%dataFile = load('C:\Users\david\Box\Patient In-Clinic Data\RCS03\study_visits\OR_2ndside\maria_analysis\RCS03_02_Recog_rest_raw_ecog.mat');


%% define work place variables 
subject = 'RCS02';
dataCell = {};
timeCell = {};
chanCell = {};
dataMatrix = [];
timeMatrix = [];
counter = 1;

run(fullfile(getenv('matlab_devel_dir'),'patient_config_files',subject, 'patient_config_file.m'))

dataCell{1} = dataMatrix;
timeCell{1} = timeMatrix;

data.label = chanCell;     % cell-array containing strings, Nchan*1
data.fsample = fs;    % sampling frequency in Hz, single number
data.trial = dataCell;     % cell-array containing a data matrix for each
% trial (1*Ntrial), each data matrix is a Nchan*Nsamples matrix
data.time = timeCell;       % cell-array containing a time axis for each
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
dataPreProc = ft_preprocessing(cfg,data);
%%
cfg = [];
cfg.resamplefs = 1000;     %frequency at which the data will be resampled (default = 256 Hz)
[dataPreProc] = ft_resampledata(cfg, dataPreProc);
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