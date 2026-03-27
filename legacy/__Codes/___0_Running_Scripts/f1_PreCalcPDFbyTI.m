function stOut = f1_PreCalcPDFbyTI(sFolderDB_IN)
stOut = 0;
%% 
try sFolderDB = sFolderDB_IN; catch, sFolderDB = ['Exp1_20160830_500_SOFI' filesep]; end

%% Load stFolders mat file from DB folder

load(['..' filesep '..' filesep '_1_DB' filesep sFolderDB 'stFolders']);
clear sFolderDB

addpath(genpath(['..' filesep '..' filesep stFolders.Codes]));
%% For each training image for each model we precalc stats

filesModels = dir(['..' filesep '..' filesep ...
                    stFolders.DB stFolders.FolderNAME]);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Params --------------------------------- %%
% Minimum number of realizations for current pattern
stParams.minPatternTimes     = 6;                                         
% Minimum number of conditionals neccesary for current pattern 
stParams.minCompPattern      = 3;
% Minimum size for current pattern
stParams.sizeMinBlockPattern = 7; % always odd
                
  %% For each Model                
for idxM =1:numel(filesModels)
    if strfind(filesModels(idxM).name, 'model')
        % Load current Model
        mFile       = matfile(['..' filesep '..' filesep ...
                                stFolders.DB stFolders.FolderNAME ...
                                filesModels(idxM).name],'Writable',true);                
        model_Info  = mFile.model_Info;
        fieldsM     = fieldnames(mFile);
        
        %% For each Training image
        locTI   = strfind(fieldsM,'TI');
        for idxF = 1:numel(locTI)
            if (numel(locTI{idxF}) > 0) &&...
               (numel(strfind(fieldsM{idxF},'PDF')) == 0)
                % Create Mat File for model and blockSize
                BaseName = ['..' filesep '..' filesep ...
                                stFolders.DB stFolders.FolderNAME ...
                                'PDFforM' model_Info.name(6:end)];
           
           
                stCond.minPatternTimes      = stParams.minPatternTimes;                                         
                stCond.minCompPattern       = stParams.minCompPattern;
                stCond.sizeMinBlockPattern  = stParams.sizeMinBlockPattern;
                mFile.stCond                = stCond;
                clc
                stParams.nameTI     = fieldsM{idxF};
                stParams.namePDF    = ['PDF_' stParams.nameTI '_'];
                
                disp(['Estimating Stats for model : ' ...
                       model_Info.name ...
                      ' and TI: ' stParams.nameTI]);
                  
                eval(['im_T = mFile.' stParams.nameTI ';']);
                TIPS_PreCalc(im_T,stParams,mFile,BaseName);
                %eval(['PDF_' nameTI(4:end)...
                %                        ' = stPDFbyTI;']);                
                %clear stPDFbyTI;

                
                %save(['..' filesep '..' filesep ...
                %        stFolders.DB stFolders.FolderNAME ...
                %        filesModels(idxM).name], ...
                %      ['PDF_' nameTI(4:end)],...
                %      '-v7.3','-append');
                
                %eval(['mFile.' modelName '.PDF_' nameTI(4:end)...
                %                        ' = stPDFbyTI;']);
                %eval([modelName '.PDF_' nameTI(4:end)...
                %                        ' = stPDFbyTI;']);                
                %clear stPDFbyTI;
                %save(['..' filesep '..' filesep ...
                %    stFolders.DB stFolders.FolderNAME ...
                %    filesModels(idxM).name],modelName,'-v7.3');
                %clear modelName
                %whos('-file','myFile.mat')
                
            end
        end
    end
end




