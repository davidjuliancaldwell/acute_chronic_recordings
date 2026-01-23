% Debug script to test trial selection issue
% Run this to diagnose the ft_freqanalysis error

fprintf('Testing trial selection methods...\n');

% Create dummy data
data = [];
data.label = {'chan1'; 'chan2'};
data.trial = {rand(2,1000), rand(2,1000), rand(2,1000), rand(2,1000)};
data.time = {1:1000, 1:1000, 1:1000, 1:1000};
data.fsample = 1000;

% Method 1: Logical array (current implementation)
keepTrial = logical([1 0 1 1]);
fprintf('keepTrial (logical): '); disp(keepTrial);

cfg1 = [];
cfg1.trials = keepTrial;
try
    data1 = ft_preprocessing(cfg1, data);
    fprintf('Method 1 (logical array): SUCCESS - %d trials kept\n', length(data1.trial));
catch ME
    fprintf('Method 1 (logical array): FAILED\n');
    fprintf('Error: %s\n', ME.message);
end

% Method 2: Indices (recommended)
cfg2 = [];
cfg2.trials = find(keepTrial);
fprintf('cfg.trials (indices): '); disp(cfg2.trials);

try
    data2 = ft_preprocessing(cfg2, data);
    fprintf('Method 2 (indices): SUCCESS - %d trials kept\n', length(data2.trial));
catch ME
    fprintf('Method 2 (indices): FAILED\n');
    fprintf('Error: %s\n', ME.message);
end

% Method 3: ft_selectdata (recommended alternative)
cfg3 = [];
cfg3.trials = find(keepTrial);
try
    data3 = ft_selectdata(cfg3, data);
    fprintf('Method 3 (ft_selectdata): SUCCESS - %d trials kept\n', length(data3.trial));
catch ME
    fprintf('Method 3 (ft_selectdata): FAILED\n');
    fprintf('Error: %s\n', ME.message);
end

% Test ft_freqanalysis on each result
fprintf('\nTesting ft_freqanalysis...\n');

cfg_freq = [];
cfg_freq.method = 'mtmfft';
cfg_freq.taper = 'hanning';
cfg_freq.foi = 1:100;
cfg_freq.keeptrials = 'yes';

if exist('data2', 'var')
    try
        freq = ft_freqanalysis(cfg_freq, data2);
        fprintf('ft_freqanalysis on Method 2 data: SUCCESS\n');
    catch ME
        fprintf('ft_freqanalysis on Method 2 data: FAILED\n');
        fprintf('Error: %s\n', ME.message);
    end
end

fprintf('\nDone.\n');
