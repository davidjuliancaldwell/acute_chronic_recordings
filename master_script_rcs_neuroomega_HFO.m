saveFigure = 1;
folderFigures = '/Users/davidcaldwell/Library/CloudStorage/OneDrive-UCSF/Research/RCS_project';

subjects_to_analyze_HFO

statsCell = {};

for subjNum = 1:length(subjsToAnalyze)

pathDataIntraOp = intraOpFiles{subjNum};
pathDataRcs = rcsFiles{subjNum};
subj = subjsToAnalyze{subjNum};

analyze_rcs_intraop_vs_rcs_HFO
process_rcs_data_HFO
compare_intraop_rcs_HFO
close all

end