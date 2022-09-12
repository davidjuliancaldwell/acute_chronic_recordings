subjsToAnalyze = {'RCS2','RCS3','RCS4','RCS5','RCS8','RCS9'};
%subjsToAnalyze = {'RCS8'),'RCS9'};
%subjsToAnalyze = {'RCS5'};
subjsToanalyze = {'RCS3'}; % try RCS6 for HFO

%subjsToAnalyze = {'RCS6'),'RCS7'),'RCS8'),'RCS9'};
% subj 6, no working RCS data that I can find, subj 7, one weird data file


intraOpFiles = {
    %fullfile(boxEnv,'/Patient In-Clinic Data/RCS02/v01_or_day/NeuroOmega/analyzed/RCS02_bilatM1_bilatlfp_rest_postlead_raw_ecog.mat'),
    fullfile(boxEnv,'/Patient In-Clinic Data/RCS03/study_visits/OR_2ndside/analyzed/RCS03_04_Recog_Rlfp_rest_raw_ecog.mat'),
    fullfile(boxEnv,'/Patient In-Clinic Data/RCS04/v01_or_day/analyzed/RCS04_10_M1bi_lfpbi_rest_raw_ecog.mat'),
    fullfile(boxEnv,'/Patient In-Clinic Data/RCS05/Intraop/analyzed/RCS05_bi_06_LRecogLRlfp_rest_raw_ecog.mat'),
    fullfile(boxEnv,'/Patient In-Clinic Data/RCS06/intraop/analyzed/RCS06_06_bi_ecog_lfp_rest_postlead_raw_ecog.mat'),
    %fullfile(boxEnv,'/Patient In-Clinic Data/RCS07/Intraop/analyzed/RCS07_05_biEcog_bilfp_rest_raw_ecog.mat'),
    fullfile(boxEnv,'/Patient In-Clinic Data/RCS08/analyzed/RCS08_biecog_bilfp_rest_raw_ecog.mat'),
    fullfile(boxEnv,'/Patient In-Clinic Data/RCS09/Intraop/Data/analyzed/RCS09_07_biecogbilfp_rest_raw_ecog.mat');
    };
rcsFiles = {
 %   fullfile(boxEnv,'/Patient In-Clinic Data/RCS02/v02_postop/montage/Session1557330282531/DeviceNPC700398H'),
 %{fullfile(boxEnv,'/Patient In-Clinic Data/RCS02/v07_3_week/data_from_session/RCS02L/Session1558633065979/DeviceNPC700398H/'), fullfile(boxEnv,'/Patient In-Clinic Data/RCS02/v07_3_week/data_from_session/RCS02R/Session1558633075921/DeviceNPC700404H')},
    %fullfile(boxEnv,'/Patient In-Clinic Data/RCS03/study_visits/1 Month (2nd Side)/RCS Data/RCS03L/Session1581614954437/DeviceNPC700411H'),
    {fullfile(boxEnv,'Patient In-Clinic Data/RCS03/study_visits/3 Week (2nd Side)/RCS03R/off_med/montage/Session1581097044255/DeviceNPC700447H')},
    fullfile(boxEnv,'/Patient In-Clinic Data/RCS04/RCS04_PRESTIM_HOME/RCS04HR/Session1563047449370/DeviceNPC700412H'),
    fullfile(boxEnv,'/Patient In-Clinic Data/RCS05/At-Home Tests/24 Recording Session/RCS05L/Session1579801040075/DeviceNPC700414H'),
    %fullfile(boxEnv,'/Patient In-Clinic Data/RCS06/At-Home Tests/24 Hour Recording Session/RCS06L/Session1580453054562/DeviceNPC700424H'),
    %fullfile(boxEnv,'/Patient In-Clinic Data/RCS07/Adaptive Visit 1/RCS Data/RCS07L/Session1582324683533/DeviceNPC700419H'), % 1st right side file before this had strange power spectrum, may include if want evidence of time RCS doesnt do well? % 3rd one has samplingRate issue - maybe make check to see if SR is at another part of timeDOmainSettings and valid across all channels?
    fullfile(boxEnv,'/Patient In-Clinic Data/RCS08/At-Home Tests/3 Day Sprint (3rd Attempt)/RCS08L/Session1583373664473/DeviceNPC700444H'),
    fullfile(boxEnv,'/Patient In-Clinic Data/RCS09/Fast Adaptive Session 3.12.2021/RCS09R/Session1615585294490/DeviceNPC700449H');
    };

%pathInt = fullfile(boxEnv,'/Patient In-Clinic Data/RCS02/v01_or_day/rcsData/Session1557272264386/DeviceNPC700398H';
%pathInt = fullfile(boxEnv,'/Patient In-Clinic Data/RCS02/v01_or_day/rcsData/Session1557272264386/DeviceNPC700404H';

iterationInterest = {
%[],
[2]
};

timeStampStart ={
 %  [5,5],
   [6],
};

timeStampStop = {
  %  [6,6],
    [7],
    };

% new double files
%RCS02 - 3 week clinic visit 



%%
% RCS02 - 1 day after
% RCS03 - 13-Feb from 14-Jan
% RCS04 - 13-July from ??? 11-Oct was 4 month visit, so July 11 was 1 month
% visit ?
% RCS05 - Jan 23 2020, 7/16/2019
% RCS08 - 04March2020, 3/20/2020 was 3 week visit ,so OR was beginnning of
% march ?
% RCS09  - clinic was 12-march-2021, surgery was 4/1/2020