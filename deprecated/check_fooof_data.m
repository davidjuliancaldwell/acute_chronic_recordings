% Quick check if FOOOF data is populated
% Run this after analyze_intraop and analyze_rcs to verify data exists

fprintf('\n=== Checking FOOOF Data ===\n\n');

%% Check intraop data
fprintf('--- Intraop FOOOF Data ---\n');
if ~exist('base_fre1Intraop', 'var')
    fprintf('ERROR: base_fre1Intraop does not exist in workspace!\n');
    fprintf('       Run analyze_intraop first.\n');
else
    fprintf('✓ base_fre1Intraop exists\n');

    % Check fooof_powspctrm
    if isfield(base_fre1Intraop, 'fooof_powspctrm')
        fprintf('✓ fooof_powspctrm field exists\n');

        if isempty(base_fre1Intraop.fooof_powspctrm)
            fprintf('✗ ERROR: fooof_powspctrm is EMPTY!\n');
        else
            fprintf('✓ fooof_powspctrm has data\n');
            fprintf('  Size: %s\n', mat2str(size(base_fre1Intraop.fooof_powspctrm)));
            fprintf('  Sample values (chan 1, first 5 freqs): %s\n', ...
                mat2str(base_fre1Intraop.fooof_powspctrm(1,1:min(5,end))));

            % Check for NaN or zeros
            if all(isnan(base_fre1Intraop.fooof_powspctrm(:)))
                fprintf('✗ ERROR: All values are NaN!\n');
            elseif all(base_fre1Intraop.fooof_powspctrm(:) == 0)
                fprintf('✗ ERROR: All values are zero!\n');
            else
                fprintf('✓ Data looks valid (non-zero, non-NaN)\n');
            end
        end
    else
        fprintf('✗ ERROR: fooof_powspctrm field does NOT exist!\n');
    end

    % Check fooof_freq
    if isfield(base_fre1Intraop, 'fooof_freq')
        fprintf('✓ fooof_freq field exists\n');
        fprintf('  Range: %.1f - %.1f Hz (%d points)\n', ...
            min(base_fre1Intraop.fooof_freq), ...
            max(base_fre1Intraop.fooof_freq), ...
            length(base_fre1Intraop.fooof_freq));
    else
        fprintf('✗ ERROR: fooof_freq field does NOT exist!\n');
    end
end

%% Check RCS data
fprintf('\n--- RCS FOOOF Data ---\n');
if ~exist('base_fre1RCSall', 'var')
    fprintf('ERROR: base_fre1RCSall does not exist in workspace!\n');
    fprintf('       Run analyze_rcs first.\n');
else
    fprintf('✓ base_fre1RCSall exists\n');

    % Check fooof_powspctrm
    if isfield(base_fre1RCSall, 'fooof_powspctrm')
        fprintf('✓ fooof_powspctrm field exists\n');

        if isempty(base_fre1RCSall.fooof_powspctrm)
            fprintf('✗ ERROR: fooof_powspctrm is EMPTY!\n');
        else
            fprintf('✓ fooof_powspctrm has data\n');
            fprintf('  Number of sessions: %d\n', length(base_fre1RCSall.fooof_powspctrm));

            if length(base_fre1RCSall.fooof_powspctrm) > 0
                fprintf('  Session 1 iterations: %d\n', length(base_fre1RCSall.fooof_powspctrm{1}));

                if length(base_fre1RCSall.fooof_powspctrm{1}) > 0
                    fprintf('  Session 1, Iter 1 size: %s\n', ...
                        mat2str(size(base_fre1RCSall.fooof_powspctrm{1}{1})));

                    if ~isempty(base_fre1RCSall.fooof_powspctrm{1}{1})
                        fprintf('  Sample values (chan 1, first 5 freqs): %s\n', ...
                            mat2str(base_fre1RCSall.fooof_powspctrm{1}{1}(1,1:min(5,end))));

                        % Check for NaN or zeros
                        if all(isnan(base_fre1RCSall.fooof_powspctrm{1}{1}(:)))
                            fprintf('✗ ERROR: All values are NaN!\n');
                        elseif all(base_fre1RCSall.fooof_powspctrm{1}{1}(:) == 0)
                            fprintf('✗ ERROR: All values are zero!\n');
                        else
                            fprintf('✓ Data looks valid (non-zero, non-NaN)\n');
                        end
                    else
                        fprintf('✗ ERROR: Session 1, Iter 1 is EMPTY!\n');
                    end
                end
            end
        end
    else
        fprintf('✗ ERROR: fooof_powspctrm field does NOT exist!\n');
    end
end

%% Summary
fprintf('\n=== Summary ===\n');
fprintf('If both intraop and RCS fooof_powspctrm fields exist with valid data,\n');
fprintf('the FOOOF plots should display correctly.\n');
fprintf('\nIf data is missing or empty, you need to re-run the analysis scripts\n');
fprintf('with the updated FOOOF configuration (cfg.output = ''fooof'').\n');
