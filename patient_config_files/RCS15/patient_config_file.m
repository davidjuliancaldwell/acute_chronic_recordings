fs = dataFile.CECOG_1___01___Array_1___01_KHz*1000;
neuroOmegaEcogChans = 'CECOG_1___0%d___Array_1___0%d';% module 1 1-8, bilateral
neuroOmegaLfpChans = 'CECOG_4___0%d___Array_3___0%d';% module 4 1-8, bilateral 

%%

for jj = 1:8

    tempName = sprintf(neuroOmegaEcogChans,jj,jj);              
    dataInt = dataFile.(tempName);
    timeVec = [0:length(dataInt)-1]/fs;
    dataMatrix = [dataMatrix; dataInt];
    timeMatrix = [timeMatrix; timeVec];
    chanCell{counter} = sprintf('%d',counter);
    counter = counter + 1;
end
% for jj = 1:8
% 
%     tempName = sprintf('CECOG_3___0%d___Array_2___0%d',jj,jj);
%     dataInt = dataFile.(tempName);
%     timeVec = [0:length(dataInt)-1]/fs;
%     dataMatrix = [dataMatrix; dataInt];
%     timeMatrix = [timeMatrix; timeVec];
%     chanCell{counter} = sprintf('%d',counter);
%     counter = counter + 1;
% end
for jj = 1:8

    tempName = sprintf(neuroOmegaLfpChans,jj,jj);
    dataInt = dataFile.(tempName);
    timeVec = [0:length(dataInt)-1]/fs;
    dataMatrix = [dataMatrix; dataInt];
    timeMatrix = [timeMatrix; timeVec];
    chanCell{counter} = sprintf('%d',counter);
    counter = counter + 1;
end
