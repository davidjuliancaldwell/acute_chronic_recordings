% Test script to run analysis on a single subject and verify FOOOF plots
% This runs the full pipeline for one subject to test FOOOF functionality

clear all
close all

fprintf('\n========================================\n');
fprintf('Testing FOOOF Analysis and Plotting\n');
fprintf('========================================\n\n');

%% Setup environment
fprintf('Step 1: Setting up environment...\n');
try
    setup_rcs
    fprintf('✓ Environment setup complete\n\n');
catch ME
    fprintf('✗ Error during setup: %s\n', ME.message);
    return;
end

%% Load subject configuration
fprintf('Step 2: Loading subject configuration...\n');
try
    % Define environment variables needed by subjects_to_analyze
    boxEnv = getenv('box_dir');
    oneDriveEnv = getenv('onedrive_dir');
    dropboxEnv = getenv('dropbox');

    if isempty(boxEnv)
        fprintf('✗ Error: box_dir environment variable not set\n');
        return;
    end

    subjects_to_analyze
    fprintf('✓ Subject configuration loaded\n');
    fprintf('  Number of subjects: %d\n\n', length(subjsToAnalyze));
catch ME
    fprintf('✗ Error loading subjects: %s\n', ME.message);
    return;
end

%% Select first subject and set up variables (from master_script)
subjNum = 1;
subj = subjsToAnalyze{subjNum};
pathDataIntraOp = intraOpFiles{subjNum};
pathDataRcs = rcsFiles{subjNum};

% Set up rereferencing flags
bipolarReref = 0;
bipolarSkipReref = 1;

% Set up statistical test flags
signedRankTest = 1;  % Enable to populate statsResultsFooof
rankSumTest = 0;
permute_test = 0;

% Set up subject-specific variables
beginRCS = timeStampStart{subjNum};
endRCS = timeStampStop{subjNum};
if exist('iterationInterest', 'var')
    iterationInterestSpecific = iterationInterest{subjNum};
else
    iterationInterestSpecific = [];
end
rerefChoice = rerefCell{subjNum};
sidesToUse = sidesToUseCell{subjNum};
if ~isempty(makeNan{subjNum})
    startIntraop = makeNan{subjNum}{1};
    endIntraop = makeNan{subjNum}{2};
end

% Figure saving flag and folder
saveFigure = 0;  % Don't save to avoid cluttering
folderFigures = tempdir();  % Use temp dir in case save is attempted
splitPath = cell(1,20);  % Dummy splitPath in case it's needed
for i = 1:20, splitPath{i} = 'test'; end

fprintf('Testing subject: %s\n', subj);
fprintf('  Intraop file: %s\n', pathDataIntraOp);
fprintf('  RCS files: %d sessions\n', length(pathDataRcs));
fprintf('  Reref: bipolarSkip=%d\n', bipolarSkipReref);
fprintf('  SidesToUse: %s\n\n', sidesToUse);

%% Run intraoperative analysis
fprintf('Step 3: Running intraoperative analysis...\n');
tic;
try
    analyze_intraop
    elapsed = toc;
    fprintf('✓ Intraop analysis complete (%.1f seconds)\n\n', elapsed);
catch ME
    fprintf('✗ Error during intraop analysis: %s\n', ME.message);
    fprintf('  Stack trace:\n');
    for i = 1:length(ME.stack)
        fprintf('    %s (line %d)\n', ME.stack(i).name, ME.stack(i).line);
    end
    return;
end

%% Check intraop FOOOF data
fprintf('Step 4: Checking intraop FOOOF data...\n');
if ~exist('base_fre1Intraop', 'var')
    fprintf('✗ ERROR: base_fre1Intraop not in workspace!\n');
    return;
end

if ~isfield(base_fre1Intraop, 'fooof_powspctrm')
    fprintf('✗ ERROR: fooof_powspctrm field missing!\n');
    return;
end

if isempty(base_fre1Intraop.fooof_powspctrm)
    fprintf('✗ ERROR: fooof_powspctrm is empty!\n');
    return;
end

fprintf('✓ Intraop FOOOF data populated\n');
fprintf('  Size: %s\n', mat2str(size(base_fre1Intraop.fooof_powspctrm)));
fprintf('  Frequency range: %.1f - %.1f Hz\n', ...
    min(base_fre1Intraop.fooof_freq), max(base_fre1Intraop.fooof_freq));
fprintf('  Sample values (chan 1): %s\n', ...
    mat2str(base_fre1Intraop.fooof_powspctrm(1,1:5)));
fprintf('  Data check: ');
if all(isnan(base_fre1Intraop.fooof_powspctrm(:)))
    fprintf('✗ All NaN\n');
    return;
elseif all(base_fre1Intraop.fooof_powspctrm(:) == 0)
    fprintf('✗ All zeros\n');
    return;
else
    fprintf('✓ Valid data\n\n');
end

%% Run RCS analysis
fprintf('Step 5: Running RCS analysis...\n');
tic;
try
    analyze_rcs
    elapsed = toc;
    fprintf('✓ RCS analysis complete (%.1f seconds)\n\n', elapsed);
catch ME
    fprintf('✗ Error during RCS analysis: %s\n', ME.message);
    fprintf('  Stack trace:\n');
    for i = 1:length(ME.stack)
        fprintf('    %s (line %d)\n', ME.stack(i).name, ME.stack(i).line);
    end
    return;
end

%% Check RCS FOOOF data
fprintf('Step 6: Checking RCS FOOOF data...\n');
if ~exist('base_fre1RCSall', 'var')
    fprintf('✗ ERROR: base_fre1RCSall not in workspace!\n');
    return;
end

if ~isfield(base_fre1RCSall, 'fooof_powspctrm')
    fprintf('✗ ERROR: fooof_powspctrm field missing!\n');
    return;
end

if isempty(base_fre1RCSall.fooof_powspctrm)
    fprintf('✗ ERROR: fooof_powspctrm is empty!\n');
    return;
end

fprintf('✓ RCS FOOOF data populated\n');
fprintf('  Sessions: %d\n', length(base_fre1RCSall.fooof_powspctrm));
fprintf('  Session 1 iterations: %d\n', length(base_fre1RCSall.fooof_powspctrm{1}));
fprintf('  Session 1, Iter 1 size: %s\n', ...
    mat2str(size(base_fre1RCSall.fooof_powspctrm{1}{1})));
fprintf('  Sample values (chan 1): %s\n', ...
    mat2str(base_fre1RCSall.fooof_powspctrm{1}{1}(1,1:5)));
fprintf('  Data check: ');
if all(isnan(base_fre1RCSall.fooof_powspctrm{1}{1}(:)))
    fprintf('✗ All NaN\n');
    return;
elseif all(base_fre1RCSall.fooof_powspctrm{1}{1}(:) == 0)
    fprintf('✗ All zeros\n');
    return;
else
    fprintf('✓ Valid data\n\n');
end

%% Run comparison and generate FOOOF plots
fprintf('Step 7: Running comparison script (with FOOOF plots)...\n');

% Flags already set in subject setup above

tic;
try
    compare_intraop_rcs
    elapsed = toc;
    fprintf('✓ Comparison complete (%.1f seconds)\n\n', elapsed);
catch ME
    fprintf('✗ Error during comparison: %s\n', ME.message);
    fprintf('  Stack trace:\n');
    for i = 1:length(ME.stack)
        fprintf('    %s (line %d)\n', ME.stack(i).name, ME.stack(i).line);
    end
    return;
end

%% Verify FOOOF plots were generated
fprintf('Step 8: Verifying FOOOF plots...\n');

% Find figures with FOOOF in the name
allFigs = findall(0, 'Type', 'figure');
fooofFigs = [];
for i = 1:length(allFigs)
    figName = get(allFigs(i), 'Name');
    if contains(figName, 'FOOOF')
        fooofFigs = [fooofFigs; allFigs(i)];
        fprintf('  Found figure: "%s" (Figure %d)\n', figName, allFigs(i).Number);
    end
end

if isempty(fooofFigs)
    fprintf('✗ WARNING: No FOOOF figures found!\n');
    fprintf('  This could mean the plotting code didn''t execute.\n');
else
    fprintf('✓ Found %d FOOOF figure(s)\n', length(fooofFigs));

    % Check if figures have children (axes with data)
    for i = 1:length(fooofFigs)
        figHandle = fooofFigs(i);
        axes_handles = findall(figHandle, 'Type', 'axes');

        % Exclude legends from count
        axes_handles = axes_handles(~strcmp(get(axes_handles, 'Tag'), 'legend'));

        fprintf('  Figure %d has %d subplot(s)\n', figHandle.Number, length(axes_handles));

        % Check if axes have line objects (data)
        hasData = false;
        for j = 1:length(axes_handles)
            lines = findall(axes_handles(j), 'Type', 'line');
            if ~isempty(lines)
                hasData = true;
                break;
            end
        end

        if hasData
            fprintf('    ✓ Has plotted data\n');
        else
            fprintf('    ✗ WARNING: No plotted data found\n');
        end
    end
end

%% Summary
fprintf('\n========================================\n');
fprintf('Test Summary\n');
fprintf('========================================\n');
fprintf('Subject: %s\n', subj);
fprintf('Intraop FOOOF data: ✓\n');
fprintf('RCS FOOOF data: ✓\n');
fprintf('Comparison executed: ✓\n');
fprintf('FOOOF figures generated: %d\n', length(fooofFigs));
fprintf('\n');

if length(fooofFigs) >= 2
    fprintf('✓✓✓ SUCCESS! FOOOF plots are working! ✓✓✓\n');
    fprintf('\nYou should see two figures:\n');
    fprintf('  1. FOOOF Modeled Power Spectra (per-channel subplots)\n');
    fprintf('  2. FOOOF Aperiodic Parameters (connected scatter plots)\n');
    fprintf('\nIf plots look empty, check the axes - data might be outside view range.\n');
else
    fprintf('⚠ PARTIAL SUCCESS: Analysis ran but fewer figures than expected.\n');
    fprintf('Check console output above for any warnings.\n');
end

fprintf('\n========================================\n\n');
