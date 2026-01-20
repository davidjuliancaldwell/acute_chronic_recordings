% Diagnostic script to check FOOOF data structures
% Run this after analyze_intraop and analyze_rcs have been executed

fprintf('\n=== FOOOF Data Structure Diagnostics ===\n\n');

% Check intraop FOOOF data
fprintf('--- Intraop FOOOF Data ---\n');
if exist('base_fre1Intraop', 'var')
    fprintf('base_fre1Intraop exists: YES\n');

    if isfield(base_fre1Intraop, 'fooofparams')
        fprintf('base_fre1Intraop.fooofparams exists: YES\n');
        fprintf('Number of channels: %d\n', length(base_fre1Intraop.fooofparams));
    else
        fprintf('base_fre1Intraop.fooofparams exists: NO\n');
    end

    if isfield(base_fre1Intraop, 'fooof_powspctrm')
        fprintf('base_fre1Intraop.fooof_powspctrm exists: YES\n');
        fprintf('Size: %s\n', mat2str(size(base_fre1Intraop.fooof_powspctrm)));
        fprintf('Is empty: %s\n', mat2str(isempty(base_fre1Intraop.fooof_powspctrm)));
        if ~isempty(base_fre1Intraop.fooof_powspctrm)
            fprintf('Sample values (first 5): %s\n', mat2str(base_fre1Intraop.fooof_powspctrm(1,1:min(5,size(base_fre1Intraop.fooof_powspctrm,2)))));
        end
    else
        fprintf('base_fre1Intraop.fooof_powspctrm exists: NO\n');
    end

    if isfield(base_fre1Intraop, 'fooof_freq')
        fprintf('base_fre1Intraop.fooof_freq exists: YES\n');
        fprintf('Length: %d\n', length(base_fre1Intraop.fooof_freq));
        fprintf('Range: %.1f - %.1f Hz\n', min(base_fre1Intraop.fooof_freq), max(base_fre1Intraop.fooof_freq));
    else
        fprintf('base_fre1Intraop.fooof_freq exists: NO\n');
    end
else
    fprintf('base_fre1Intraop does not exist\n');
end

fprintf('\n--- RCS FOOOF Data ---\n');
if exist('base_fre1RCSall', 'var')
    fprintf('base_fre1RCSall exists: YES\n');

    if isfield(base_fre1RCSall, 'fooofparams')
        fprintf('base_fre1RCSall.fooofparams exists: YES\n');
        fprintf('Number of sessions: %d\n', length(base_fre1RCSall.fooofparams));
        if length(base_fre1RCSall.fooofparams) > 0
            fprintf('Number of iterations in session 1: %d\n', length(base_fre1RCSall.fooofparams{1}));
        end
    else
        fprintf('base_fre1RCSall.fooofparams exists: NO\n');
    end

    if isfield(base_fre1RCSall, 'fooof_powspctrm')
        fprintf('base_fre1RCSall.fooof_powspctrm exists: YES\n');
        fprintf('Number of sessions: %d\n', length(base_fre1RCSall.fooof_powspctrm));
        if length(base_fre1RCSall.fooof_powspctrm) > 0 && length(base_fre1RCSall.fooof_powspctrm{1}) > 0
            fprintf('Session 1, Iteration 1 size: %s\n', mat2str(size(base_fre1RCSall.fooof_powspctrm{1}{1})));
            fprintf('Is empty: %s\n', mat2str(isempty(base_fre1RCSall.fooof_powspctrm{1}{1})));
            if ~isempty(base_fre1RCSall.fooof_powspctrm{1}{1})
                fprintf('Sample values (first 5): %s\n', mat2str(base_fre1RCSall.fooof_powspctrm{1}{1}(1,1:min(5,size(base_fre1RCSall.fooof_powspctrm{1}{1},2)))));
            end
        end
    else
        fprintf('base_fre1RCSall.fooof_powspctrm exists: NO\n');
    end
else
    fprintf('base_fre1RCSall does not exist\n');
end

fprintf('\n=== End Diagnostics ===\n');
