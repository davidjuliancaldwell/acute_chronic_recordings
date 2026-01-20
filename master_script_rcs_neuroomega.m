setup_rcs


saveFigure = 1;
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

    % which statistics to do signedRank/rankSum are on group level
    signedRankTest = 1;
    rankSumTest = 0;

    %permutation vs kruskal (TO DO)
    permute_test  = 1;
   

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
    end
    % Note: rcsOrder is accessed directly in analyze_rcs as rcsOrder{subjNum}

    analyze_intraop
    analyze_rcs
    compare_intraop_rcs
   % close all

end