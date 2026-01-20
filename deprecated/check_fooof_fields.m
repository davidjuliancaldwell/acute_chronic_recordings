% Quick script to check what fields FOOOF returns
% Run this after the FOOOF analysis has run

if exist('base_fre1Intraop_fooof', 'var')
    fprintf('FOOOF output fields:\n');
    fields = fieldnames(base_fre1Intraop_fooof);
    for i = 1:length(fields)
        fprintf('  %s\n', fields{i});
    end

    % Check for aperiodic-related fields
    fprintf('\nLooking for aperiodic fit data...\n');
    if isfield(base_fre1Intraop_fooof, 'fooofapcfit')
        fprintf('  ✓ fooofapcfit found\n');
    end
    if isfield(base_fre1Intraop_fooof, 'powspctrm')
        fprintf('  ✓ powspctrm found (size: %s)\n', mat2str(size(base_fre1Intraop_fooof.powspctrm)));
    end
    if isfield(base_fre1Intraop_fooof, 'fooofspctrm')
        fprintf('  ✓ fooofspctrm found\n');
    end
    if isfield(base_fre1Intraop_fooof, 'fooofmodel')
        fprintf('  ✓ fooofmodel found\n');
    end
else
    fprintf('base_fre1Intraop_fooof not in workspace\n');
end
