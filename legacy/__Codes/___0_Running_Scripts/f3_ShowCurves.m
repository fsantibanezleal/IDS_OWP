function stOut = f3_ShowCurves(sFolderDB_IN)
close all
clc

stOut = 0;
%% 
try sFolderDB = sFolderDB_IN; catch, sFolderDB = ['Exp1_20160101' filesep]; end

%% Load stFolders mat file from DB folder

load(['..' filesep '..' filesep '_1_DB' filesep sFolderDB 'stFolders']);
clear sFolderDB

addpath(genpath(['..' filesep '..' filesep stFolders.Codes]));
%% For each training image for each model we precalc stats

filesModels = dir(['..' filesep '..' filesep ...
                    stFolders.OutCome stFolders.FolderNAME]);
  %% For each Model                
for idxM =1:numel(filesModels)
if strfind(filesModels(idxM).name, 'model')
    filesSamp = dir(['..' filesep '..' filesep ...
                    stFolders.OutCome stFolders.FolderNAME ...
                    filesModels(idxM).name]);
    for idxSP =1:numel(filesSamp)    
    if strfind(filesSamp(idxSP).name, 'Sampling_Process_')

        % Load current Model
        mFile       = load(['..' filesep '..' filesep ...
                                stFolders.OutCome stFolders.FolderNAME ...
                                filesModels(idxM).name filesep ...
                                filesSamp(idxSP).name]);


        %% Show All measures
        figure;

        % Real and training
        subplot(3,3,1);
        imagesc(mFile.RI_1)
        title('Real Image','Interpreter','latex')   

        subplot(3,3,4);
        imagesc(mFile.TI_1)
        title('Training Image','Interpreter','latex')   

        % 1 -> Random Uniform
        subplot(3,3,2);
        imagesc(reshape(mFile.v_LocSamples_1>0,size(mFile.RI_1)))
        title('Uniform Random','Interpreter','latex')   

        % 2 -> Deterministically Structured
        subplot(3,3,3);
        imagesc(reshape(mFile.v_LocSamples_2>0,size(mFile.RI_1)))
        title('Det Structured','Interpreter','latex')   

        % 3 -> Random Stratified
        subplot(3,3,5);
        imagesc(reshape(mFile.v_LocSamples_3>0,size(mFile.RI_1)))
        title('Rand Stratified','Interpreter','latex')   

        %  4 -> Det Strat multiscale
        subplot(3,3,6);
        imagesc(reshape(mFile.v_LocSamples_4>0,size(mFile.RI_1)))
        title('Det Strat MultiScale','Interpreter','latex')   

        % 5 -> Maximum Indicator (Preferential)
        subplot(3,3,8);
        imagesc(reshape(mFile.v_LocSamples_5>0,size(mFile.RI_1)))
        title('Maximum Indicator','Interpreter','latex')   

        % 6 -> Oracle
        subplot(3,3,9);
        imagesc(reshape(mFile.v_LocSamples_6>0,size(mFile.RI_1)))
        title('Oracle Entropy','Interpreter','latex')   

        % 7 -> AdSEMES


    %imSamples = reshape(v_LocSamples>0,size(im_R));
    %imagesc(imSamples);
    %figure;

    %im_Sampled = nan(size(im_R));
    %im_Sampled(v_LocSamples > 0) = im_R(v_LocSamples > 0);

    %imagesc(im_Sampled);
    %figure;
    %imagesc(im_R); 


    end
    end
    
end
end




