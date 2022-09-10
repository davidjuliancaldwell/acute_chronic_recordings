saveFigure = 0;
boxEnv = getenv('box_dir');
oneDriveEnv = getenv('onedrive_dir');
folderFigures = fullfile(oneDriveEnv,'/Research/RCS_project');

subjects_to_analyze

statsCell = {};

for subjNum = 1:length(subjsToAnalyze)

pathDataIntraOp = intraOpFiles{subjNum};
pathDataRcs = rcsFiles{subjNum};
subj = subjsToAnalyze{subjNum};

%analyze_rcs_intraop_vs_rcs
process_rcs_data
compare_intraop_rcs
close all

end