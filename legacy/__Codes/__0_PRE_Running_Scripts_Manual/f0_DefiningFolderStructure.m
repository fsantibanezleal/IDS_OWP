function stFolders = f0_DefiningFolderStructure(sFolderRAWDB)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% FILLME WITH SPECIFIC FOLDER %% EXAMPLE
% The folder with your DB, that need to be located in "_0_RawDB" folder
try 
    stFolders.FolderNAME = sFolderRAWDB;
catch
    stFolders.FolderNAME = ['Exp1_20160613' filesep];
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Folder of Codes
stFolders.Codes = ['__Codes' filesep];
% Folder of Creation of DB. Current Folder
stFolders.DBCreation = [stFolders.Codes...
                        '__0_PRE_Running_Scripts_Manual' filesep];

%% Folder RAW DABATASE (Put Your files in some folder inside here)
stFolders.RAWDB     = ['_0_RawDB' filesep];
% Specific folder with RAW DB
stFolders.RAWDBSUB  = [stFolders.RAWDB  stFolders.FolderNAME];

%% All outcomes will be created in the next folder using folder name 
%  provided in RAWDBSUB
% Data base Folder
stFolders.DB = ['_1_DB' filesep];
% Outcomes Folder
stFolders.OutCome = ['_2_OutComes' filesep];
% Analysis Folder
stFolders.Analysis = ['_3_Analysis' filesep];

%% addpath(genpath(SFOLDERCODE))

end
