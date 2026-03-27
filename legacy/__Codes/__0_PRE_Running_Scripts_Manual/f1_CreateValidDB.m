close all
clear all
clc
%% Transform your DB located at RAWDB Folder and save components to 
%  the useful DB folder

%% FILL ME. Put Name of RAW DB folder here
sFolderRAWDB = ['Exp1_20160830_500_SOFI' filesep];

%% Create Basic Structure of Folders
stFolders = f0_DefiningFolderStructure(sFolderRAWDB);
clear sFolderRAWDB

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%            HERE YOUR CODE TO ADAPT DB                   %%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Don't create aditional variables starting with "model"
% Load your data. Convert to TI and RI using this structure. For example,
% you have "X" fenomena. For each one you have "N" training images and "M"
% realizations images. Then, you need to map your data to the next objects.
% model_1 is the matfile.

% model_1.RI_1 = image_Realization_1_forMODEL_1
% model_1.RI_2 = image_Realization_2_forMODEL_1
% ...
% model_1.RI_"M" = image_Realization_M_forMODEL_1
% model_1.TI_1 = image_Realization_1_forMODEL_1
% model_1.TI_2 = image_Realization_2_forMODEL_1
% ...
% model_1.TI_"N" = image_Realization_N_forMODEL_1
%
% ...
%
% model_"X".RI_1 = image_Realization_1_forMODEL_X
% model_"X".RI_2 = image_Realization_2_forMODEL_X
% ...
% model_"X".RI_"M" = image_Realization_M_forMODEL_X
% model_"X".TI_1 = image_Realization_1_forMODEL_X
% model_"X".TI_2 = image_Realization_2_forMODEL_X
% ...
% model_"X".TI_"N" = image_Realization_N_forMODEL_X

%%%% Example 

%% Loading RAW DB SC_1
stTemp.typeDB = 'SC_1';
load(['..' filesep '..' filesep stFolders.RAWDBSUB stTemp.typeDB '.mat']);
% SC1 finding similar pattern images.
% Single : 5 10 12 15 17 244 245 270 272 352
% Single&Islands : 1 2 4 8 16 20 23 24 25 426 431 
% 

% Adapting to desired used
% Creating "models"
model_1.model_Info.name  = 'model_1';
model_1.model_Info.typeMain = 'SC_1';
model_1.model_Info.typeSub  = 'No_Island';
model_1.model_Info.typeExp  = '1';

stDummy.imDummy = r_16;
stDummy.imDummy = stDummy.imDummy  - min(stDummy.imDummy(:));
stDummy.imDummy = stDummy.imDummy ./ max(stDummy.imDummy(:));
model_1.RI_1     = stDummy.imDummy;

stDummy.imDummy = r_426;
stDummy.imDummy = stDummy.imDummy  - min(stDummy.imDummy(:));
stDummy.imDummy = stDummy.imDummy ./ max(stDummy.imDummy(:));
model_1.TI_1     = stDummy.imDummy;

%% Loading RAW DB MC_1
stTemp.typeDB = 'MC_1';
load(['..' filesep '..' filesep stFolders.RAWDBSUB stTemp.typeDB '.mat']);
% MC1 finding similar pattern images.
%1 2 3 5 6 7 9 11 12 13 15 17 18 20 21 23 26 27 29 31 32 35 36 37 38 40
% with islands : 4 8 10 14 16 19 22 24 25 28 30 33 34 39 41 42 605 759 824

% Adapting to desired used
% Creating "models"
model_2.model_Info.name  = 'model_2';
model_2.model_Info.typeMain = 'MC_1';
model_2.model_Info.typeSub  = 'No_Island';
model_2.model_Info.typeExp  = '1';

stDummy.imDummy = r_28;
stDummy.imDummy = stDummy.imDummy  - min(stDummy.imDummy(:));
stDummy.imDummy = stDummy.imDummy ./ max(stDummy.imDummy(:));
model_2.RI_1     = stDummy.imDummy;

stDummy.imDummy = r_759;
stDummy.imDummy = stDummy.imDummy  - min(stDummy.imDummy(:));
stDummy.imDummy = stDummy.imDummy ./ max(stDummy.imDummy(:));
model_2.TI_1     = stDummy.imDummy;

%% Loading RAW DB MC_2
stTemp.typeDB = 'MC_2';
load(['..' filesep '..' filesep stFolders.RAWDBSUB stTemp.typeDB '.mat']);
% MC1 finding similar pattern images.
% 2 5 6 7 8 9 10 11 12 13 14 15 16 18 20 25 28 29 32 33 37
% with islands : 1 3 4 17 19 21 22 23 24 26 27 30 31 34 35

% Adapting to desired used
% Creating "models"
model_3.model_Info.name  = 'model_3';
model_3.model_Inf.typeMain = 'MC_2';
model_3.model_Inf.typeSub  = 'No_Island';
model_3.model_Inf.typeExp  = '1';

stDummy.imDummy = r_19;
stDummy.imDummy = stDummy.imDummy  - min(stDummy.imDummy(:));
stDummy.imDummy = stDummy.imDummy ./ max(stDummy.imDummy(:));
model_3.RI_1     = stDummy.imDummy;

stDummy.imDummy = r_31;
stDummy.imDummy = stDummy.imDummy  - min(stDummy.imDummy(:));
stDummy.imDummy = stDummy.imDummy ./ max(stDummy.imDummy(:));
model_3.TI_1     = stDummy.imDummy;

clear r_* stDummy stTemp X Z
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Now all variables starting with "model" will be saved and required 
%  folders in stFolders will be created
f0_SavingDBandFolders;




%%%% END FILE ... SCRIPT FOR PERSONAL ANALYSIS OF EXAMPLE DB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%stDummy.sImR = who('r_*');
%stDummy.Out  = [stFolders.RAWDBSUB stTemp.typeDB filesep];
%mkdir(stDummy.Out);
%for idxR = 1: numel(stDummy.sImR)
%    eval(['stDummy.imDummy = ' stDummy.sImR{idxR} ';']);
%    stDummy.imDummy = stDummy.imDummy  - min(stDummy.imDummy(:));
%    stDummy.imDummy = stDummy.imDummy ./ max(stDummy.imDummy(:));
%    
%    imwrite(stDummy.imDummy,[stDummy.Out stDummy.sImR{idxR} '.png']);
%    %imagesc(stDummy.imDummy); colormap(gray);
%    %pause()
%end

%%%% SC1 finding similar pattern images.


%%%% MC1 finding similar pattern images.
%1 2 3 5 6 7 9 11 12 13 15 17 18 20 21 23 26 27 29 31 32 35 36 37 38 40

% with islands : 4 8 10 14 16 19 22 24 25 28 30 33 34 39 41 42 605 759 824

%%%% MC2 finding similar pattern images.




