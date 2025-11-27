% code to setup rcs environment and data paths
restoredefaultpath

currentPath = pwd;
parentPath = fileparts(currentPath);

setenv('box_dir','/Users/davidcaldwell/Box')
setenv('onedrive_dir', '/Users/davidcaldwell/OneDrive - UCSF');
setenv('dropbox', '/Users/davidcaldwell/Starr Lab Dropbox/');

addpath(genpath(fullfile(currentPath)));
addpath(genpath(fullfile(parentPath,'Analysis-rcs-data')));
addpath(fullfile(parentPath,'fieldtrip'));
addpath(fullfile(parentPath,'fieldtrip','external/brewermap'));
ft_defaults;

fprintf('Path set')