%% verify_channel_matching.m
% Diagnostic script to validate channel naming and matching between
% RCS and intraoperative recordings.
%
% Run this AFTER running master_script_rcs_neuroomega to verify:
% 1. Correct rcsOrder assignment (L/R hemisphere labels)
% 2. Proper channel name formatting ('+' stripped, prefix applied)
% 3. Successful channel matching between RCS and intraop data
%
% Usage:
%   Run master_script_rcs_neuroomega first, then run this script.
%   Requires base_fre1Intraop, base_fre1RCSall, and rcsOrder in workspace.

fprintf('=== Channel Matching Verification ===\n \n');

%% Check required variables exist
requiredVars = {'base_fre1Intraop', 'base_fre1RCSall', 'rcsOrder', 'subjNum'};
missingVars = {};
for i = 1:length(requiredVars)
    if ~exist(requiredVars{i}, 'var')
        missingVars{end+1} = requiredVars{i};
    end
end

if ~isempty(missingVars)
    error('Missing required variables: %s\nRun master_script_rcs_neuroomega first.', strjoin(missingVars, ', '));
end

%% 1. Display Intraoperative Channel Labels
fprintf('--- Intraoperative Channels (Subject %d) ---\n', subjNum);
for i = 1:length(base_fre1Intraop.label)
    label = base_fre1Intraop.label{i};
    % Parse region and side from label
    if contains(label, 'ECOGL')
        region = 'ECoG'; side = 'Left';
    elseif contains(label, 'ECOGR')
        region = 'ECoG'; side = 'Right';
    elseif contains(label, 'LFPL')
        region = 'LFP'; side = 'Left';
    elseif contains(label, 'LFPR')
        region = 'LFP'; side = 'Right';
    else
        region = 'Unknown'; side = 'Unknown';
    end
    fprintf('  [%d] %s  (%s, %s)\n', i, label, region, side);
end
fprintf('\n');

%% 2. Display RCS Channel Labels and rcsOrder Configuration
fprintf('--- RCS Channels and rcsOrder Configuration ---\n');
fprintf('rcsOrder{%d} = ', subjNum);
rcsOrderSubj = rcsOrder{subjNum};
% Display the cell array contents
orderStr = '{';
for i = 1:length(rcsOrderSubj)
    orderStr = [orderStr '''' rcsOrderSubj{i} ''''];
    if i < length(rcsOrderSubj)
        orderStr = [orderStr ', '];
    end
end
orderStr = [orderStr '}'];
fprintf('%s\n\n', orderStr);

% Loop through each RCS session
for sessionIdx = 1:length(base_fre1RCSall.chans)
    fprintf('Session %d (rcsOrder = ''%s''):\n', sessionIdx, rcsOrderSubj{sessionIdx});
    for iterIdx = 1:length(base_fre1RCSall.chans{sessionIdx})
        sessionLabels = base_fre1RCSall.chans{sessionIdx}{iterIdx};
        fprintf('  Iteration %d:\n', iterIdx);
        for chanIdx = 1:length(sessionLabels)
            label = sessionLabels{chanIdx};
            % Check for common issues
            issues = {};
            if contains(label, '+')
                issues{end+1} = 'WARNING: Contains ''+'' (should be stripped)';
            end
            if ~contains(label, {'ECOG', 'LFP'})
                issues{end+1} = 'WARNING: Missing region prefix';
            end
            % Check side consistency
            expectedSide = rcsOrderSubj{sessionIdx};
            if contains(label, 'L') && expectedSide == 'R'
                issues{end+1} = sprintf('WARNING: Has ''L'' but rcsOrder says ''R''');
            elseif contains(label, 'R') && expectedSide == 'L'
                issues{end+1} = sprintf('WARNING: Has ''R'' but rcsOrder says ''L''');
            end

            if isempty(issues)
                fprintf('    [%d] %s  (OK)\n', chanIdx, label);
            else
                fprintf('    [%d] %s  %s\n', chanIdx, label, strjoin(issues, '; '));
            end
        end
    end
end
fprintf('\n');

%% 3. Channel Matching Analysis
fprintf('--- Channel Matching Results ---\n');
matchCount = 0;
unmatchedRCS = {};
unmatchedIntraop = base_fre1Intraop.label; % Start with all, remove as matched

for sessionIdx = 1:length(base_fre1RCSall.chans)
    for iterIdx = 1:length(base_fre1RCSall.chans{sessionIdx})
        sessionLabels = base_fre1RCSall.chans{sessionIdx}{iterIdx};
        for chanIdx = 1:length(sessionLabels)
            rcsLabel = sessionLabels{chanIdx};
            matchIdx = find(strcmp(base_fre1Intraop.label, rcsLabel));

            if ~isempty(matchIdx)
                matchCount = matchCount + 1;
                fprintf('  MATCH: RCS "%s" <-> Intraop "%s"\n', rcsLabel, base_fre1Intraop.label{matchIdx});
                % Remove from unmatched intraop list
                unmatchedIntraop = unmatchedIntraop(~strcmp(unmatchedIntraop, rcsLabel));
            else
                unmatchedRCS{end+1} = rcsLabel;
            end
        end
    end
end

fprintf('\nSummary:\n');
fprintf('  Total matches found: %d\n', matchCount);
fprintf('  Unmatched RCS channels: %d\n', length(unmatchedRCS));
fprintf('  Unmatched Intraop channels: %d\n', length(unmatchedIntraop));

if ~isempty(unmatchedRCS)
    fprintf('\nUnmatched RCS channels:\n');
    for i = 1:length(unmatchedRCS)
        fprintf('  - %s\n', unmatchedRCS{i});
    end
end

if ~isempty(unmatchedIntraop)
    fprintf('\nUnmatched Intraop channels:\n');
    for i = 1:length(unmatchedIntraop)
        fprintf('  - %s\n', unmatchedIntraop{i});
    end
end

fprintf('\n=== Verification Complete ===\n');
