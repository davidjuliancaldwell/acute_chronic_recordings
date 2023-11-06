saveFigure = 0;
boxEnv = getenv('box_dir');
oneDriveEnv = getenv('onedrive_dir');
folderFigures = fullfile(oneDriveEnv,'/Research/RCS_project');

subjects_to_analyze

statsCell = {};

%of note, the intraop order must be left then right side ECoG, then left
%then right side LFP 

for subjNum = 1:length(subjsToAnalyze)

    % which re-referencing scheme to use, depends on the RC+S data for each
    % subject. bipolar reref is sequential re-referencing, whereas "skip"
    % indicates skipping adjacent channels during the re-referencing, which
    % appears to be more similar to how many of the RC+S sessions are
    % recorded. 
    bipolarReref = 0;
    bipolarSkipReref = 1;

    % which statistics to do: if there are matched channels can do signed
    % rank test otherwise need to ranksum
    signedRankTest = 1;
    rankSumTest = 0;

    pathDataIntraOp = intraOpFiles{subjNum};
    pathDataRcs = rcsFiles{subjNum};
    subj = subjsToAnalyze{subjNum};
    beginRCS = timeStampStart{subjNum};
    endRCS = timeStampStop{subjNum};
    iterationInterestSpecific = iterationInterest{subjNum};
    rerefChoice = rerefCell{subjNum};
    sidesToUse = sidesToUseCell{subjNum};

    analyze_rcs_intraop_vs_rcs
    process_rcs_data
    compare_intraop_rcs
    close all

end