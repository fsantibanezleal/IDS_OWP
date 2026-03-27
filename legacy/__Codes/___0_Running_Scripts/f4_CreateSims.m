function stOut = f4_CreateSims(sFolderDB_IN)
close all
clc

stOut = 0;

    %% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Providing params 
    % number of realizations
    scriptParams.numReals  = 500;

    % path to Sgems
    stPaths.SgemsExe = 'C:\SGeMS-x64-Beta';

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%% Running Main Script
    bSaveImages = 1; % Save images as PNG 
    bSaveMAT    = 1; % Save Data simulations as MAT file
                


%% 
try sFolderDB = sFolderDB_IN; catch, sFolderDB = ['Exp1_20160627_SOFI' filesep]; end

%% Load stFolders mat file from DB folder
load(['..' filesep '..' filesep '_1_DB' filesep sFolderDB 'stFolders']);


addpath(genpath(['..' filesep '..' filesep stFolders.Codes]));
%% For each training image for each model we precalc stats
filesModels = dir(['..' filesep '..' filesep ...
                    stFolders.OutCome stFolders.FolderNAME]);
stFolders.FolderNAME = sFolderDB;

stPaths.ExpFolder       = cd(cd(['..' filesep '..' filesep ...
                               stFolders.OutCome stFolders.FolderNAME]));

stPaths.ExpFolder       = [stPaths.ExpFolder filesep];
stPaths.internalFolder  = 'InternalDATA1';
mkdir([stPaths.ExpFolder stPaths.internalFolder]);
clear sFolderDB
                
%% For each Model                
for idxM = 1:numel(filesModels)
if strfind(filesModels(idxM).name, 'model')
%if strfind(filesModels(idxM).name, 'model_1')

    filesSamp = dir(['..' filesep '..' filesep ...
                    stFolders.OutCome stFolders.FolderNAME ...
                    filesModels(idxM).name]);
    for idxSP =1:numel(filesSamp)    
    if (numel(strfind(filesSamp(idxSP).name, 'Sampling_Process_')) > 0) &&...
       (numel(strfind(filesSamp(idxSP).name, '.mat')) > 0) %%&& ...
       strcmp(filesSamp(idxSP).name,'Sampling_Process_1.mat')


        % Load current Model
        mFile       = load(['..' filesep '..' filesep ...
                                stFolders.OutCome stFolders.FolderNAME ...
                                filesModels(idxM).name filesep ...
                                filesSamp(idxSP).name]);

        TI          = mFile.TI_1;
        im_R        = mFile.RI_1;

                            

        % Provide the name of the file to save simulations
        scriptParams.fileSimName = ['Simulations_' filesSamp(idxSP).name];



        % Training            : TI = N x N matrix, binary
        % Sample (hard data)  : HD = N x N matrix , Nans in unknown pixels
        % Example: 

        % Provide Path to oputput Folder
        scriptParams.outFolderM   = [stPaths.ExpFolder ...
                                    filesModels(idxM).name];
        % Sub folder for specific sampling process
        scriptParams.outFolderSS   = [scriptParams.outFolderM filesep...
                                      filesSamp(idxSP).name(1:end-4)];
        mkdir(scriptParams.outFolderSS);

        nSamples = max(mFile.v_LocSamples_1);
        %for idxIterS = [1,(2:4:18) ,(20:20:nSamples)]
        for idxIterS = [1,(2:4:18) ,(20:20:180), (200:100:nSamples)]
        %for idxIterS = [1,100,nSamples]
        %for idxIterS = nSamples
            % 1 -> Random Uniform
            % Provide Path to oputput Folder
            if(isfield(mFile,'v_LocSamples_1'))
                scriptParams.outFolder   = [scriptParams.outFolderSS filesep 'SS_1'];
                mkdir(scriptParams.outFolder);
                scriptParams.outFolder   = [scriptParams.outFolder filesep ...
                                            'CumulativeSampling_'...
                                            num2str(idxIterS)];
                mkdir(scriptParams.outFolder);

                HD                          = nan(size(mFile.RI_1));
                idxA                        = (mFile.v_LocSamples_1 > 0) & ...
                                              (mFile.v_LocSamples_1 <= idxIterS);
                HD(idxA)                    = im_R(idxA);
                SimsBySgems(TI,HD,stPaths,scriptParams,bSaveImages,bSaveMAT);
            end
            % 2 -> Deterministically Structured
            if(isfield(mFile,'v_LocSamples_2'))

                scriptParams.outFolder   = [scriptParams.outFolderSS filesep 'SS_2'];
                mkdir(scriptParams.outFolder);
                scriptParams.outFolder   = [scriptParams.outFolder filesep ...
                                            'CumulativeSampling_'...
                                            num2str(idxIterS)];
                mkdir(scriptParams.outFolder);

                HD                          = nan(size(mFile.RI_1));
                idxA                        = (mFile.v_LocSamples_2 > 0) & ...
                                              (mFile.v_LocSamples_2 <= idxIterS);
                HD(idxA)                    = im_R(idxA);
                SimsBySgems(TI,HD,stPaths,scriptParams,bSaveImages,bSaveMAT);
            end
            % 3 -> Random Stratified
            if(isfield(mFile,'v_LocSamples_3'))

                scriptParams.outFolder   = [scriptParams.outFolderSS filesep 'SS_3'];
                mkdir(scriptParams.outFolder);
                scriptParams.outFolder   = [scriptParams.outFolder filesep ...
                                            'CumulativeSampling_'...
                                            num2str(idxIterS)];
                mkdir(scriptParams.outFolder);

                HD                          = nan(size(mFile.RI_1));
                idxA                        = (mFile.v_LocSamples_3 > 0) & ...
                                              (mFile.v_LocSamples_3 <= idxIterS);
                HD(idxA)                    = im_R(idxA);
                SimsBySgems(TI,HD,stPaths,scriptParams,bSaveImages,bSaveMAT);
            end
            %  4 -> Det Strat multiscale
            if(isfield(mFile,'v_LocSamples_4'))
                scriptParams.outFolder   = [scriptParams.outFolderSS filesep 'SS_4'];
                mkdir(scriptParams.outFolder);
                scriptParams.outFolder   = [scriptParams.outFolder filesep ...
                                            'CumulativeSampling_'...
                                            num2str(idxIterS)];
                mkdir(scriptParams.outFolder);

                HD                          = nan(size(mFile.RI_1));
                idxA                        = (mFile.v_LocSamples_4 > 0) & ...
                                              (mFile.v_LocSamples_4 <= idxIterS);
                HD(idxA)                    = im_R(idxA);
                SimsBySgems(TI,HD,stPaths,scriptParams,bSaveImages,bSaveMAT);
            end
            % 5 -> Maximum Indicator (Preferential)
            if(isfield(mFile,'v_LocSamples_5'))
                scriptParams.outFolder   = [scriptParams.outFolderSS filesep 'SS_5'];
                mkdir(scriptParams.outFolder);
                scriptParams.outFolder   = [scriptParams.outFolder filesep ...
                                            'CumulativeSampling_'...
                                            num2str(idxIterS)];
                mkdir(scriptParams.outFolder);

                HD                          = nan(size(mFile.RI_1));
                idxA                        = (mFile.v_LocSamples_5 > 0) & ...
                                              (mFile.v_LocSamples_5 <= idxIterS);
                HD(idxA)                    = im_R(idxA);
                SimsBySgems(TI,HD,stPaths,scriptParams,bSaveImages,bSaveMAT);
            end
            % 6 -> Oracle
            if(isfield(mFile,'v_LocSamples_6'))
                scriptParams.outFolder   = [scriptParams.outFolderSS filesep 'SS_6'];
                mkdir(scriptParams.outFolder);
                scriptParams.outFolder   = [scriptParams.outFolder filesep ...
                                            'CumulativeSampling_'...
                                            num2str(idxIterS)];
                mkdir(scriptParams.outFolder);

                HD                          = nan(size(mFile.RI_1));
                idxA                        = (mFile.v_LocSamples_6 > 0) & ...
                                              (mFile.v_LocSamples_6 <= idxIterS);
                HD(idxA)                    = im_R(idxA);
                SimsBySgems(TI,HD,stPaths,scriptParams,bSaveImages,bSaveMAT);
            end
            % 7 -> AdSEMES
            if(isfield(mFile,'v_LocSamples_7'))

                scriptParams.outFolder   = [scriptParams.outFolderSS filesep 'SS_7'];
                mkdir(scriptParams.outFolder);
                scriptParams.outFolder   = [scriptParams.outFolder filesep ...
                                            'CumulativeSampling_'...
                                            num2str(idxIterS)];
                mkdir(scriptParams.outFolder);

                HD                          = nan(size(mFile.RI_1));
                idxA                        = (mFile.v_LocSamples_7 > 0) & ...
                                              (mFile.v_LocSamples_7 <= idxIterS);
                HD(idxA)                    = im_R(idxA);
                SimsBySgems(TI,HD,stPaths,scriptParams,bSaveImages,bSaveMAT);
            end

        end

    end
    end
    
end
end




                
                
                
                
                
                
                
                
                
                
                
                
                


















