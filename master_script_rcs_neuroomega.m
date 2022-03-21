subjects_to_analyze

statsCell = {};

for jj = 1:length(subjsToAnalyze)

pathDataIntraOp = intraOpFiles{jj};
pathDataRcs = rcsFiles{jj};
subj = subjsToAnalyze{jj};

analyze_rcs_intraop_vs_rcs
process_rcs_data
compare_intraop_rcs

end