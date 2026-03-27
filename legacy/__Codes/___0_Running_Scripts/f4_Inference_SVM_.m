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
try sFolderDB = sFolderDB_IN; catch, sFolderDB = ['Exp1_20160101' filesep]; end

%% Load stFolders mat file from DB folder
load(['..' filesep '..' filesep '_1_DB' filesep sFolderDB 'stFolders']);
clear sFolderDB

addpath(genpath(['..' filesep '..' filesep stFolders.Codes]));
%% For each training image for each model we precalc stats
filesModels = dir(['..' filesep '..' filesep ...
                    stFolders.OutCome stFolders.FolderNAME]);
                
stPaths.ExpFolder       = cd(cd(['..' filesep '..' filesep ...
                               stFolders.OutCome stFolders.FolderNAME]));

stPaths.ExpFolder       = [stPaths.ExpFolder filesep];
stPaths.internalFolder  = 'InternalDATA1';
mkdir([stPaths.ExpFolder stPaths.internalFolder]);

                
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
       %%strcmp(filesSamp(idxSP).name,'Sampling_Process_1.mat')


        % Load current Model
        mFile       = load(['..' filesep '..' filesep ...
                                stFolders.OutCome stFolders.FolderNAME ...
                                filesModels(idxM).name filesep ...
                                filesSamp(idxSP).name]);

        TI          = mFile.TI_1;
        im_R        = mFile.RI_1;

                            

        % Provide the name of the file to save simulations
        scriptParams.fileSimName = ['SVM_' filesSamp(idxSP).name];



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
        %for idxIterS = [1,100,nSamples]
        for idxIterS = nSamples
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
                imR = Inference_SVM(HD);
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
                imR = Inference_SVM(HD);
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
                imR = Inference_SVM(HD);
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
                imR = Inference_SVM(HD);
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
                imR = Inference_SVM(HD);
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
                imR = Inference_SVM(HD);
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
                imR = Inference_SVM(HD);
            end

        end

    end
    end
    
end
end




                
                
                
                
                
                
                
                
                
                
                
                
                

















































function imSVM = Inference_SVM(HD)

idxSelected = find(~isnan(HD(:)));

x1Grid    = zeros(numel(idxSelected),1); % XD
dataImage = zeros(numel(x1Grid) , 2);
imSVM     = nan(size(HD));
theclass  = zeros(numel(x1Grid),1);

sampleS = 0;
for idxC  = 1: numel(x1Grid)
    if sampleS
    %dataImage(idxC,:)       = [x1Grid(idxC), x2Grid(idxC)];
    %theclass(idxC)          = RI(x1Grid(idxC), x2Grid(idxC));
    %tempI(x1Grid(idxC),...
    %      x2Grid(idxC))     = theclass(idxC);  
    else      
        [I,J] = ind2sub(size(HD),idxSelected(idxC));

        dataImage(idxC,:)   = [I, J];
        theclass(idxC)      = HD(I, J);
        imSVM(I,J)          = theclass(idxC);  
    end
end

theclass(theclass == 0) = -1;
%Train the SVM Classifier
SVMModel = fitcsvm(dataImage,theclass,'KernelFunction','rbf',...
    'BoxConstraint',Inf,'ClassNames',[-1,1]);
%polynomial
%SVMModel = fitcsvm(dataImage,theclass,'KernelFunction','rbf',...
%    'Solver','L1QP','BoxConstraint',Inf,'ClassNames',[-1,1]);

% Predict scores over the grid
[x1Grid,x2Grid] = meshgrid(1:size(HD,1),1:size(HD,2));

sizeG     = size(x1Grid);
x1GridV   = x1Grid(:);
x2GridV   = x2Grid(:);
xGrid     = zeros(numel(x1Grid) , 2);
for idxC  = 1: numel(x1Grid)
    xGrid(idxC,:) = [x1GridV(idxC), x2GridV(idxC)];
end

[idxS,scores] = predict(SVMModel,xGrid);

% Plot the data and the decision boundary
figure;

%h(1:2) = gscatter(dataImage(:,2),dataImage(:,1),theclass,'rb','.');
%hold on
%h(3) = plot(dataImage(SVMModel.IsSupportVector,1),...
%            dataImage(SVMModel.IsSupportVector,2),'ko');
idxIm   = reshape(idxS,sizeG)';
peaksIm = reshape(scores(:,2),sizeG)';
%contour(x1Grid,x2Grid, peaksIm ,[0 0],'k');
%legend(h,{'-1','+1','Support Vectors'});
%axis equal
%hold off

imagesc(idxIm);
pause();
close
















