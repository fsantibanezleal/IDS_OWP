function stOut = f2_EvalSampling_M3(sFolderDB_IN)
stOut = 0;
%% 
try sFolderDB = sFolderDB_IN; catch, sFolderDB = ['Exp1_20160830_500' filesep]; end

%% Load stFolders mat file from DB folder

load(['..' filesep '..' filesep '_1_DB' filesep sFolderDB 'stFolders']);
clear sFolderDB

addpath(genpath(['..' filesep '..' filesep stFolders.Codes]));
%% For each training image for each model we precalc stats

filesModels = dir(['..' filesep '..' filesep ...
                    stFolders.DB stFolders.FolderNAME]);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Params --------------------------------- %%
%stParams.

mkdir(['..' filesep '..' filesep ...
stFolders.OutCome stFolders.FolderNAME]);

  %% For each Model                
for idxM =1:numel(filesModels)
if strfind(filesModels(idxM).name, 'model_3') 
    % Load current Model
    mFile       = matfile(['..' filesep '..' filesep ...
                            stFolders.DB stFolders.FolderNAME ...
                            filesModels(idxM).name],'Writable',false);                
    model_Info  = mFile.model_Info;
    fieldsM     = fieldnames(mFile);

    %% For each Training image
    locRI   = strfind(fieldsM,'RI');
    for idxRI = 1:numel(locRI)
    if (numel(locRI{idxRI}) > 0)
        stParams.nameRI     = fieldsM{idxRI};
        eval(['im_R = mFile.' stParams.nameRI ';']);
    
        %% For each Training image
        locTI   = strfind(fieldsM,'TI');
        for idxF = 1:numel(locTI)
        if (numel(locTI{idxF}) > 0) &&...
           (numel(strfind(fieldsM{idxF},'PDF')) == 0)

            mkdir([ '..' filesep '..' filesep ...
                    stFolders.OutCome stFolders.FolderNAME filesep ...
                    filesModels(idxM).name(1:end-4)]);

            clc
            stParams.nameTI     = fieldsM{idxF};
            stParams.namePDF    = ['PDF_' stParams.nameTI '_'];

            disp(['Applying Sampling for Model : ' ...
                   model_Info.name ...
                  ' and TI: ' stParams.nameTI]);

            eval(['im_T = mFile.' stParams.nameTI ';']);

            %% Parameter for the Methods 
            strParamS.matFileS                  = mFile;

            strParamS.dataImR.im_T              = im_T;
            
            strParamS.dataImR.im_R              = im_R;
            strParamS.dataImR.dim_imR           = size(im_R);

            strParamS.Spec.nElemAxis            = 3;
            strParamS.Spec.nElemAxis_4          = 3;

            strParamS.basics.num_Samples        = 500;
            strParamS.basics.b_RandStrat        = true; 

            strParamS.basics.v_Hi_Samples_Old   = nan(...
                                                   size(...
                                                    im_R(:)));
            strParamS.basics.H_Xat_Old          = [];

            for idxST = 1:1
                stOut_1 = [];
                stOut_2 = [];
                stOut_3 = [];
                stOut_4 = [];
                stOut_5 = [];
                stOut_6 = [];
                stOut_7 = [];
                
                %% Applying each sampling method
                % 1 -> Random Uniform
                strParamS.basics.v_LocSamples_Old   = 0 .* im_R(:);
                v_LocSamples_1 = LocateSamples_RandU(strParamS);
                
                stOut_1 = CallFake(strParamS,v_LocSamples_1);
                % 2 -> Deterministically Structured
                strParamS.basics.v_LocSamples_Old   = 0 .* im_R(:);
                v_LocSamples_2 = LocateSamples_DetStrat(strParamS);
                stOut_2 = CallFake(strParamS,v_LocSamples_2);

                % 3 -> Random Stratified
                strParamS.basics.v_LocSamples_Old   = 0 .* im_R(:);
                v_LocSamples_3 = LocateSamples_RandStrat(strParamS);
                stOut_3 = CallFake(strParamS,v_LocSamples_3);

                %  4 -> Det Strat multiscale
                strParamS.basics.v_LocSamples_Old   = 0 .* im_R(:);
                dummyP                      = strParamS.Spec.nElemAxis;
                strParamS.Spec.nElemAxis    = strParamS.Spec.nElemAxis_4;
                v_LocSamples_4 = LocateSamples_DetStrat_MS(strParamS);
                strParamS.Spec.nElemAxis    = dummyP;
                
                stOut_4 = CallFake(strParamS,v_LocSamples_4);
                
                % 5 -> Maximum Indicator (Preferential)
                strParamS.basics.v_LocSamples_Old   = 0 .* im_R(:);
                v_LocSamples_5 = LocateSamples_MaxIndicator(strParamS);
                stOut_5 = CallFake(strParamS,v_LocSamples_5);

                % 6 -> Oracle
                strParamS.basics.v_LocSamples_Old   = 0 .* im_R(:);
                v_LocSamples_6 = LocateSamples_Oracle_MES(strParamS);
                stOut_6 = CallFake(strParamS,v_LocSamples_6);

                % 7 -> AdSEMES
                dummyP                              = strParamS.basics.num_Samples;
                strParamS.Spec.nElemAxis            = 3;
                % Tentative free measurements
                strParamS.basics.num_Samples        = 9;
                strParamS.basics.b_RandStrat        = true; 

                strParamS.basics.v_LocSamples_Old   = ...
                                        LocateSamples_RandStrat(strParamS);

                %% Obtain remaining positions to measure
                strParamS.basics.num_Samples        = dummyP;

                [v_LocSamples_7, ...
                 stOut_7] = LocateSamples_AdSEMES_Binary_Old(strParamS);



                %% Saving Data
                eval([stParams.nameRI ' = im_R' ';']); 
                eval([stParams.nameTI ' = im_T' ';']); 

                save([ '..' filesep '..' filesep ...
                        stFolders.OutCome stFolders.FolderNAME filesep ...
                        filesModels(idxM).name(1:end-4) filesep ... 
                        'Sampling_Process_' num2str(idxST) '.mat'], ...
                      stParams.nameRI,stParams.nameTI,...
                      'v_LocSamples_1','v_LocSamples_2','v_LocSamples_3',...
                      'v_LocSamples_4','v_LocSamples_5','v_LocSamples_6',...
                      'v_LocSamples_7',...
                      '-v7.3');
                  
                save([ '..' filesep '..' filesep ...
                        stFolders.OutCome stFolders.FolderNAME filesep ...
                        filesModels(idxM).name(1:end-4) filesep ... 
                        'Sampling_Process_Adds_' num2str(idxST) '.mat'], ...
                      stParams.nameRI,stParams.nameTI,...
                      'stOut_1','stOut_2','stOut_3',...
                      'stOut_4','stOut_5','stOut_6',...
                      'stOut_7',...
                      '-v7.3');
                  
            end
        end
        end
    end
    end
end
end




