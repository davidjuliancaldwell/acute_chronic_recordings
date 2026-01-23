setup_rcs

% for RCS06 data files on dropbox, bipolarSkipReref because that is how the
% chronc files are (intraop to match)
% also - be cautious re: labelling of electrodes in compare_intra_op script
%

saveFigure = 0;
boxEnv = getenv('box_dir');
oneDriveEnv = getenv('onedrive_dir');
folderFigures = fullfile(oneDriveEnv,'/Research/RCS_project');
dropboxEnv = getenv('dropbox');

load(fullfile(boxEnv,'RCS_500_1000_hz_rest_data/for_David/Highsr_sessions_RCSpatients_R.mat'))
load(fullfile(boxEnv,'RCS_500_1000_hz_rest_data/for_David/Highsr_sessions_RCSpatients_L.mat'))


subjects_to_analyze_HFO

statsCell = {};
statsCellPerm = {};

for subjNum = 1:length(subjsToAnalyze)

    % which re-referencing scheme to use, depends on the RC+S data for each
    % subject. bipolar reref is sequential re-referencing, whereas "skip"
    % indicates skipping adjacent channels during the re-referencing, which
    % appears to be more similar to how many of the RC+S sessions are
    % recorded.
    bipolarReref = 0;
    bipolarSkipReref = 1;

    % which statistics to do signedRank/rankSum are on group level
    signedRankTest = 1;
    rankSumTest = 0;

    % permutation test (preferred method)
    permute_test = 1;

    pathDataIntraOp = intraOpFiles{subjNum};
    pathDataRcs = rcsFiles{subjNum};
    subj = subjsToAnalyze{subjNum};
    beginRCS = timeStampStart{subjNum};
    endRCS = timeStampStop{subjNum};
    iterationInterestSpecific = iterationInterest{subjNum};
    rerefChoice = rerefCell{subjNum};
    sidesToUse = sidesToUseCell{subjNum};
    if ~isempty(makeNan{subjNum})
        startIntraop = makeNan{subjNum}{1};
        endIntraop = makeNan{subjNum}{2};
    else
        startIntraop = [];
        endIntraop = [];
    end
    % Note: rcsOrder is accessed directly in analyze_rcs_HFO as rcsOrder{subjNum}

    analyze_intraop_HFO
    analyze_rcs_HFO
    compare_intraop_rcs_HFO
    % close all

end