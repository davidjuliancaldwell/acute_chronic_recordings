% Quick check of FOOOF output fields
clear all
close all

% Setup
setup_rcs

% Define environment variables
boxEnv = getenv('box_dir');
if isempty(boxEnv)
    error('box_dir environment variable not set');
end

subjects_to_analyze

subjNum = 1;
subj = subjsToAnalyze{subjNum};
pathDataIntraOp = intraOpFiles{subjNum};

% Set required variables
bipolarReref = 0;
bipolarSkipReref = 1;
rerefChoice = rerefCell{subjNum};
sidesToUse = sidesToUseCell{subjNum};
if ~isempty(makeNan{subjNum})
    startIntraop = makeNan{subjNum}{1};
    endIntraop = makeNan{subjNum}{2};
end

% Run just the intraop analysis
fprintf('Running intraop analysis...\n');
analyze_intraop

fprintf('\n=== FOOOF Output Fields ===\n');
fprintf('All fields in base_fre1Intraop_fooof:\n');
if exist('base_fre1Intraop_fooof', 'var')
    fields_list = fieldnames(base_fre1Intraop_fooof);
    for i = 1:length(fields_list)
        fprintf('  %s\n', fields_list{i});
    end

    fprintf('\n=== Field Details ===\n');
    if isfield(base_fre1Intraop_fooof, 'powspctrm')
        fprintf('powspctrm exists: size = %s\n', mat2str(size(base_fre1Intraop_fooof.powspctrm)));
        fprintf('  Sample values (chan 1, first 5): %s\n', mat2str(base_fre1Intraop_fooof.powspctrm(1,1:5)));
    end

    if isfield(base_fre1Intraop_fooof, 'fooofapcfit')
        fprintf('fooofapcfit exists: size = %s\n', mat2str(size(base_fre1Intraop_fooof.fooofapcfit)));
        fprintf('  Sample values (chan 1, first 5): %s\n', mat2str(base_fre1Intraop_fooof.fooofapcfit(1,1:5)));
    end

    if isfield(base_fre1Intraop_fooof, 'foooffit')
        fprintf('foooffit exists: size = %s\n', mat2str(size(base_fre1Intraop_fooof.foooffit)));
        fprintf('  Sample values (chan 1, first 5): %s\n', mat2str(base_fre1Intraop_fooof.foooffit(1,1:5)));
    end

    if isfield(base_fre1Intraop_fooof, 'freq')
        fprintf('freq exists: size = %s\n', mat2str(size(base_fre1Intraop_fooof.freq)));
        fprintf('  Range: %.1f - %.1f Hz\n', min(base_fre1Intraop_fooof.freq), max(base_fre1Intraop_fooof.freq));
    end

    if isfield(base_fre1Intraop_fooof, 'fooofparams')
        fprintf('fooofparams exists\n');
        fprintf('  Channel 1 aperiodic_params: %s\n', mat2str(base_fre1Intraop_fooof.fooofparams(1).aperiodic_params));
    end
else
    fprintf('base_fre1Intraop_fooof does not exist!\n');
end

fprintf('\n=== What Got Stored ===\n');
fprintf('base_fre1Intraop.fooof_powspctrm exists: %d\n', isfield(base_fre1Intraop, 'fooof_powspctrm'));
if isfield(base_fre1Intraop, 'fooof_powspctrm')
    fprintf('  Size: %s\n', mat2str(size(base_fre1Intraop.fooof_powspctrm)));
    fprintf('  Sample values (chan 1, first 5): %s\n', mat2str(base_fre1Intraop.fooof_powspctrm(1,1:5)));
end

quit
