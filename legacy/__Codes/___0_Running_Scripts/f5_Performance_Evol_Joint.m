function varargout = f5_Performance_Evol_Joint(varargin)
% f5_Performance_Evol_atSamp MATLAB code for f5_Performance_Evol_atSamp.fig
%      f5_Performance_Evol, by itself, creates a new f5_Performance_Evol or raises the existing
%      singleton*.
%
%      H = f5_Performance_Evol returns the handle to a new f5_Performance_Evol or the handle to
%      the existing singleton*.
%
%      f5_Performance_Evol('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in f5_Performance_Evol.M with the given input arguments.
%
%      f5_Performance_Evol('Property','Value',...) creates a new f5_Performance_Evol or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before f5_Performance_Evol_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to f5_Performance_Evol_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help f5_Performance_Evol

% Last Modified by GUIDE v2.5 20-Apr-2016 18:16:21

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @f5_Performance_Evol_OpeningFcn, ...
                   'gui_OutputFcn',  @f5_Performance_Evol_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before f5_Performance_Evol is made visible.
function f5_Performance_Evol_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to f5_Performance_Evol (see VARARGIN)

        hF1 = figure();
        handles.hSS1_Samples = axes();
        hF2 = figure();
        handles.hSS1_Mean = axes();
        hF3 = figure();
        handles.hSS1_Std = axes();
        hF4 = figure();
        handles.hSS1_Ent = axes();


%% Load stFolders mat file from DB folder
sFolderDB = ['Exp1_20160627_SOFI' filesep];
load(['..' filesep '..' filesep '_1_DB' filesep sFolderDB 'stFolders']);
clear sFolderDB

addpath(genpath(['..' filesep '..' filesep stFolders.Codes]));

%% For each training image for each model we precalc stats
handles.stFolders   = stFolders;
handles.filesModels = dir(['..' filesep '..' filesep ...
                    stFolders.OutCome stFolders.FolderNAME]);
                
handles.stPaths.ExpFolder       = cd(cd(['..' filesep '..' filesep ...
                               stFolders.OutCome stFolders.FolderNAME]));

handles.stPaths.ExpFolder       = [handles.stPaths.ExpFolder filesep];




handles.trshMin = 0.8;
handles.trshMax = 1.0;

handles.selectedModel        = 1;
handles.selectedSampledLevel = '200';


UpdateGraphics(handles)



% Choose default command line output for f5_Performance_Evol
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes f5_Performance_Evol wait for user response (see UIRESUME)
% uiwait(handles.mainS);





function UpdateGraphics(handles)


stPaths     = handles.stPaths;
stFolders   = handles.stFolders;
filesModels = handles.filesModels;
%% For each Model                
for idxM = 1:numel(filesModels)
%if strfind(filesModels(idxM).name, 'model')
validSelection = 0;
    if     ( (numel(strfind(filesModels(idxM).name, 'model_1'))>0) && (handles.selectedModel == 1) ) ...
        || ( (numel(strfind(filesModels(idxM).name, 'model_2'))>0) && (handles.selectedModel == 2) ) ...
        || ( (numel(strfind(filesModels(idxM).name, 'model_3'))>0) && (handles.selectedModel == 3) )
        validSelection = 1;
    end
    
if validSelection    
    filesSamp = dir(['..' filesep '..' filesep ...
                    stFolders.OutCome stFolders.FolderNAME ...
                    filesModels(idxM).name]);

    for idxSP =1:numel(filesSamp)    
    if (numel(strfind(filesSamp(idxSP).name, 'Sampling_Process_')) > 0) &&...
       (numel(strfind(filesSamp(idxSP).name, '.mat')) > 0) && ...
        strcmp(filesSamp(idxSP).name,'Sampling_Process_13.mat')

            for idxInit = 1:7

                eval(['dataSS' num2str(idxInit) '.evoBitError.X = [];']);
                eval(['dataSS' num2str(idxInit) '.evoBitError.Y = [];']);
                eval(['dataSS' num2str(idxInit) '.evoBitError.EL = [];']);
                eval(['dataSS' num2str(idxInit) '.evoBitError.EU = [];']);
                
                eval(['dataSS' num2str(idxInit) '.evoMean.X = [];']);
                eval(['dataSS' num2str(idxInit) '.evoMean.Y = [];']);
                eval(['dataSS' num2str(idxInit) '.evoMean.EL = [];']);
                eval(['dataSS' num2str(idxInit) '.evoMean.EU = [];']);
                
                eval(['dataSS' num2str(idxInit) '.evoStd.X = [];']);
                eval(['dataSS' num2str(idxInit) '.evoStd.Y = [];']);
                eval(['dataSS' num2str(idxInit) '.evoStd.EL = [];']);
                eval(['dataSS' num2str(idxInit) '.evoStd.EU = [];']);
                
                eval(['dataSS' num2str(idxInit) '.evoEnt.X = [];']);
                eval(['dataSS' num2str(idxInit) '.evoEnt.Y = [];']);
                eval(['dataSS' num2str(idxInit) '.evoEnt.EL = [];']);
                eval(['dataSS' num2str(idxInit) '.evoEnt.EU = [];']);
           end

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

        nSamples = max(mFile.v_LocSamples_1);
        %idxSet   = [1,(20:20:200)];
        %idxIterS = str2num(handles.selectedSampledLevel);
        %for idxIterS = [1,100,nSamples]
        for idxIterS = [1,(20:20:200),(300:100:500)]
            % 1 -> Random Uniform
            % Provide Path to oputput Folder
            scriptParams.outFolder   = [scriptParams.outFolderSS filesep 'SS_1'];
            if(idxIterS > 10)
                scriptParams.outFolder   = [scriptParams.outFolder filesep ...
                                            'CumulativeSampling_'...
                                            num2str(idxIterS)];
            else
                scriptParams.outFolder   = [scriptParams.outFolder filesep ...
                                            'CumulativeSampling_'...
                                            '1'];                
            end
            scriptParams.outFolder = [fullfile(scriptParams.outFolder) filesep];
            
            if exist([scriptParams.outFolder 'Simulations.mat']) > 0
                load([scriptParams.outFolder 'Simulations.mat']);

                HD                          = nan(size(mFile.RI_1));
                idxA                        = (mFile.v_LocSamples_1 > 0) & ...
                                              (mFile.v_LocSamples_1 <= idxIterS);
                HD(idxA)                    = im_R(idxA);            
                varSims = who('Sims_*');
                % varsSims = who('Sims_*');
                for idx = 1:numel(varSims)
                    eval(['simsM(:,:,idx) = ' varSims{idx} ' ;' ]); 
                end
                clear Sims_*

                dataSS_Point = calcData(im_R,HD,simsM,idxIterS,handles);
                
                dataSS1.evoBitError.X = [dataSS1.evoBitError.X, dataSS_Point.evoBitError.X];
                dataSS1.evoBitError.Y = [dataSS1.evoBitError.Y, dataSS_Point.evoBitError.Y];
                dataSS1.evoBitError.EL = [dataSS1.evoBitError.EL, dataSS_Point.evoBitError.EL];
                dataSS1.evoBitError.EU = [dataSS1.evoBitError.EU, dataSS_Point.evoBitError.EU];
                
                dataSS1.evoMean.X = [dataSS1.evoMean.X,dataSS_Point.evoMean.X];
                dataSS1.evoMean.Y = [dataSS1.evoMean.Y,dataSS_Point.evoMean.Y];
                dataSS1.evoMean.EL = [dataSS1.evoMean.EL,dataSS_Point.evoMean.EL];
                dataSS1.evoMean.EU = [dataSS1.evoMean.EU,dataSS_Point.evoMean.EU];
                
                dataSS1.evoStd.X = [dataSS1.evoStd.X,dataSS_Point.evoStd.X];
                dataSS1.evoStd.Y = [dataSS1.evoStd.Y,dataSS_Point.evoStd.Y];
                dataSS1.evoStd.EL = [dataSS1.evoStd.EL,dataSS_Point.evoStd.EL];
                dataSS1.evoStd.EU = [dataSS1.evoStd.EU,dataSS_Point.evoStd.EU];
                
                dataSS1.evoEnt.X = [dataSS1.evoEnt.X,dataSS_Point.evoEnt.X];
                dataSS1.evoEnt.Y = [dataSS1.evoEnt.Y,dataSS_Point.evoEnt.Y];
                dataSS1.evoEnt.EL = [dataSS1.evoEnt.EL,dataSS_Point.evoEnt.EL];
                dataSS1.evoEnt.EU = [dataSS1.evoEnt.EU,dataSS_Point.evoEnt.EU];
            end
            % 2 -> Deterministically Structured
            scriptParams.outFolder   = [scriptParams.outFolderSS filesep 'SS_2'];
            if(idxIterS > 10)
                scriptParams.outFolder   = [scriptParams.outFolder filesep ...
                                            'CumulativeSampling_'...
                                            num2str(idxIterS)];
            else
                scriptParams.outFolder   = [scriptParams.outFolder filesep ...
                                            'CumulativeSampling_'...
                                            '1'];                
            end
            scriptParams.outFolder = [fullfile(scriptParams.outFolder) filesep];
            if exist([scriptParams.outFolder 'Simulations.mat']) > 0
                load([scriptParams.outFolder 'Simulations.mat']);

                HD                          = nan(size(mFile.RI_1));
                idxA                        = (mFile.v_LocSamples_2 > 0) & ...
                                              (mFile.v_LocSamples_2 <= idxIterS);
                HD(idxA)                    = im_R(idxA);            
                varSims = who('Sims_*');
                % varsSims = who('Sims_*');
                for idx = 1:numel(varSims)
                    eval(['simsM(:,:,idx) = ' varSims{idx} ' ;' ]); 
                end

                dataSS_Point = calcData(im_R,HD,simsM,idxIterS,handles);
                
                dataSS2.evoBitError.X = [dataSS2.evoBitError.X, dataSS_Point.evoBitError.X];
                dataSS2.evoBitError.Y = [dataSS2.evoBitError.Y, dataSS_Point.evoBitError.Y];
                dataSS2.evoBitError.EL = [dataSS2.evoBitError.EL, dataSS_Point.evoBitError.EL];
                dataSS2.evoBitError.EU = [dataSS2.evoBitError.EU, dataSS_Point.evoBitError.EU];
                
                dataSS2.evoMean.X = [dataSS2.evoMean.X,dataSS_Point.evoMean.X];
                dataSS2.evoMean.Y = [dataSS2.evoMean.Y,dataSS_Point.evoMean.Y];
                dataSS2.evoMean.EL = [dataSS2.evoMean.EL,dataSS_Point.evoMean.EL];
                dataSS2.evoMean.EU = [dataSS2.evoMean.EU,dataSS_Point.evoMean.EU];
                
                dataSS2.evoStd.X = [dataSS2.evoStd.X,dataSS_Point.evoStd.X];
                dataSS2.evoStd.Y = [dataSS2.evoStd.Y,dataSS_Point.evoStd.Y];
                dataSS2.evoStd.EL = [dataSS2.evoStd.EL,dataSS_Point.evoStd.EL];
                dataSS2.evoStd.EU = [dataSS2.evoStd.EU,dataSS_Point.evoStd.EU];
                
                dataSS2.evoEnt.X = [dataSS2.evoEnt.X,dataSS_Point.evoEnt.X];
                dataSS2.evoEnt.Y = [dataSS2.evoEnt.Y,dataSS_Point.evoEnt.Y];
                dataSS2.evoEnt.EL = [dataSS2.evoEnt.EL,dataSS_Point.evoEnt.EL];
                dataSS2.evoEnt.EU = [dataSS2.evoEnt.EU,dataSS_Point.evoEnt.EU];
            end
            
            % 3 -> Random Stratified
            scriptParams.outFolder   = [scriptParams.outFolderSS filesep 'SS_3'];
            if(idxIterS > 10)
                scriptParams.outFolder   = [scriptParams.outFolder filesep ...
                                            'CumulativeSampling_'...
                                            num2str(idxIterS)];
            else
                scriptParams.outFolder   = [scriptParams.outFolder filesep ...
                                            'CumulativeSampling_'...
                                            '1'];                
            end
            scriptParams.outFolder = [fullfile(scriptParams.outFolder) filesep];
            if exist([scriptParams.outFolder 'Simulations.mat']) > 0
                load([scriptParams.outFolder 'Simulations.mat']);

                HD                          = nan(size(mFile.RI_1));
                idxA                        = (mFile.v_LocSamples_3 > 0) & ...
                                              (mFile.v_LocSamples_3 <= idxIterS);
                HD(idxA)                    = im_R(idxA);            
                varSims = who('Sims_*');
                % varsSims = who('Sims_*');
                for idx = 1:numel(varSims)
                    eval(['simsM(:,:,idx) = ' varSims{idx} ' ;' ]); 
                end

                dataSS_Point = calcData(im_R,HD,simsM,idxIterS,handles);
                
                dataSS3.evoBitError.X = [dataSS3.evoBitError.X, dataSS_Point.evoBitError.X];
                dataSS3.evoBitError.Y = [dataSS3.evoBitError.Y, dataSS_Point.evoBitError.Y];
                dataSS3.evoBitError.EL = [dataSS3.evoBitError.EL, dataSS_Point.evoBitError.EL];
                dataSS3.evoBitError.EU = [dataSS3.evoBitError.EU, dataSS_Point.evoBitError.EU];
                
                dataSS3.evoMean.X = [dataSS3.evoMean.X,dataSS_Point.evoMean.X];
                dataSS3.evoMean.Y = [dataSS3.evoMean.Y,dataSS_Point.evoMean.Y];
                dataSS3.evoMean.EL = [dataSS3.evoMean.EL,dataSS_Point.evoMean.EL];
                dataSS3.evoMean.EU = [dataSS3.evoMean.EU,dataSS_Point.evoMean.EU];
                
                dataSS3.evoStd.X = [dataSS3.evoStd.X,dataSS_Point.evoStd.X];
                dataSS3.evoStd.Y = [dataSS3.evoStd.Y,dataSS_Point.evoStd.Y];
                dataSS3.evoStd.EL = [dataSS3.evoStd.EL,dataSS_Point.evoStd.EL];
                dataSS3.evoStd.EU = [dataSS3.evoStd.EU,dataSS_Point.evoStd.EU];
                
                dataSS3.evoEnt.X = [dataSS3.evoEnt.X,dataSS_Point.evoEnt.X];
                dataSS3.evoEnt.Y = [dataSS3.evoEnt.Y,dataSS_Point.evoEnt.Y];
                dataSS3.evoEnt.EL = [dataSS3.evoEnt.EL,dataSS_Point.evoEnt.EL];
                dataSS3.evoEnt.EU = [dataSS3.evoEnt.EU,dataSS_Point.evoEnt.EU];
            end

            %  4 -> Det Strat multiscale
            scriptParams.outFolder   = [scriptParams.outFolderSS filesep 'SS_4'];
            if(idxIterS > 10)
                scriptParams.outFolder   = [scriptParams.outFolder filesep ...
                                            'CumulativeSampling_'...
                                            num2str(idxIterS)];
            else
                scriptParams.outFolder   = [scriptParams.outFolder filesep ...
                                            'CumulativeSampling_'...
                                            '1'];                
            end
            scriptParams.outFolder = [fullfile(scriptParams.outFolder) filesep];
            if exist([scriptParams.outFolder 'Simulations.mat']) > 0
                load([scriptParams.outFolder 'Simulations.mat']);

                HD                          = nan(size(mFile.RI_1));
                idxA                        = (mFile.v_LocSamples_4 > 0) & ...
                                              (mFile.v_LocSamples_4 <= idxIterS);
                HD(idxA)                    = im_R(idxA);            
                varSims = who('Sims_*');
                % varsSims = who('Sims_*');
                for idx = 1:numel(varSims)
                    eval(['simsM(:,:,idx) = ' varSims{idx} ' ;' ]); 
                end

                dataSS_Point = calcData(im_R,HD,simsM,idxIterS,handles);
                
                dataSS4.evoBitError.X = [dataSS4.evoBitError.X, dataSS_Point.evoBitError.X];
                dataSS4.evoBitError.Y = [dataSS4.evoBitError.Y, dataSS_Point.evoBitError.Y];
                dataSS4.evoBitError.EL = [dataSS4.evoBitError.EL, dataSS_Point.evoBitError.EL];
                dataSS4.evoBitError.EU = [dataSS4.evoBitError.EU, dataSS_Point.evoBitError.EU];
                
                dataSS4.evoMean.X = [dataSS4.evoMean.X,dataSS_Point.evoMean.X];
                dataSS4.evoMean.Y = [dataSS4.evoMean.Y,dataSS_Point.evoMean.Y];
                dataSS4.evoMean.EL = [dataSS4.evoMean.EL,dataSS_Point.evoMean.EL];
                dataSS4.evoMean.EU = [dataSS4.evoMean.EU,dataSS_Point.evoMean.EU];
                
                dataSS4.evoStd.X = [dataSS4.evoStd.X,dataSS_Point.evoStd.X];
                dataSS4.evoStd.Y = [dataSS4.evoStd.Y,dataSS_Point.evoStd.Y];
                dataSS4.evoStd.EL = [dataSS4.evoStd.EL,dataSS_Point.evoStd.EL];
                dataSS4.evoStd.EU = [dataSS4.evoStd.EU,dataSS_Point.evoStd.EU];
                
                dataSS4.evoEnt.X = [dataSS4.evoEnt.X,dataSS_Point.evoEnt.X];
                dataSS4.evoEnt.Y = [dataSS4.evoEnt.Y,dataSS_Point.evoEnt.Y];
                dataSS4.evoEnt.EL = [dataSS4.evoEnt.EL,dataSS_Point.evoEnt.EL];
                dataSS4.evoEnt.EU = [dataSS4.evoEnt.EU,dataSS_Point.evoEnt.EU];
            end

            % 5 -> Maximum Indicator (Preferential)
            scriptParams.outFolder   = [scriptParams.outFolderSS filesep 'SS_5'];
            if(idxIterS > 10)
                scriptParams.outFolder   = [scriptParams.outFolder filesep ...
                                            'CumulativeSampling_'...
                                            num2str(idxIterS)];
            else
                scriptParams.outFolder   = [scriptParams.outFolder filesep ...
                                            'CumulativeSampling_'...
                                            '1'];                
            end
            scriptParams.outFolder = [fullfile(scriptParams.outFolder) filesep];
            if exist([scriptParams.outFolder 'Simulations.mat']) > 0
                load([scriptParams.outFolder 'Simulations.mat']);

                HD                          = nan(size(mFile.RI_1));
                idxA                        = (mFile.v_LocSamples_5 > 0) & ...
                                              (mFile.v_LocSamples_5 <= idxIterS);
                HD(idxA)                    = im_R(idxA);            
                varSims = who('Sims_*');
                % varsSims = who('Sims_*');
                for idx = 1:numel(varSims)
                    eval(['simsM(:,:,idx) = ' varSims{idx} ' ;' ]); 
                end

                dataSS_Point = calcData(im_R,HD,simsM,idxIterS,handles);
                
                dataSS5.evoBitError.X = [dataSS5.evoBitError.X, dataSS_Point.evoBitError.X];
                dataSS5.evoBitError.Y = [dataSS5.evoBitError.Y, dataSS_Point.evoBitError.Y];
                dataSS5.evoBitError.EL = [dataSS5.evoBitError.EL, dataSS_Point.evoBitError.EL];
                dataSS5.evoBitError.EU = [dataSS5.evoBitError.EU, dataSS_Point.evoBitError.EU];
                
                dataSS5.evoMean.X = [dataSS5.evoMean.X,dataSS_Point.evoMean.X];
                dataSS5.evoMean.Y = [dataSS5.evoMean.Y,dataSS_Point.evoMean.Y];
                dataSS5.evoMean.EL = [dataSS5.evoMean.EL,dataSS_Point.evoMean.EL];
                dataSS5.evoMean.EU = [dataSS5.evoMean.EU,dataSS_Point.evoMean.EU];
                
                dataSS5.evoStd.X = [dataSS5.evoStd.X,dataSS_Point.evoStd.X];
                dataSS5.evoStd.Y = [dataSS5.evoStd.Y,dataSS_Point.evoStd.Y];
                dataSS5.evoStd.EL = [dataSS5.evoStd.EL,dataSS_Point.evoStd.EL];
                dataSS5.evoStd.EU = [dataSS5.evoStd.EU,dataSS_Point.evoStd.EU];
                
                dataSS5.evoEnt.X = [dataSS5.evoEnt.X,dataSS_Point.evoEnt.X];
                dataSS5.evoEnt.Y = [dataSS5.evoEnt.Y,dataSS_Point.evoEnt.Y];
                dataSS5.evoEnt.EL = [dataSS5.evoEnt.EL,dataSS_Point.evoEnt.EL];
                dataSS5.evoEnt.EU = [dataSS5.evoEnt.EU,dataSS_Point.evoEnt.EU];
            end

            % 6 -> Oracle
            scriptParams.outFolder   = [scriptParams.outFolderSS filesep 'SS_6'];
            if(idxIterS > 10)
                scriptParams.outFolder   = [scriptParams.outFolder filesep ...
                                            'CumulativeSampling_'...
                                            num2str(idxIterS)];
            else
                scriptParams.outFolder   = [scriptParams.outFolder filesep ...
                                            'CumulativeSampling_'...
                                            '1'];                
            end
            scriptParams.outFolder = [fullfile(scriptParams.outFolder) filesep];
            if exist([scriptParams.outFolder 'Simulations.mat']) > 0
                load([scriptParams.outFolder 'Simulations.mat']);

                HD                          = nan(size(mFile.RI_1));
                idxA                        = (mFile.v_LocSamples_6 > 0) & ...
                                              (mFile.v_LocSamples_6 <= idxIterS);
                HD(idxA)                    = im_R(idxA);            
                varSims = who('Sims_*');
                % varsSims = who('Sims_*');
                for idx = 1:numel(varSims)
                    eval(['simsM(:,:,idx) = ' varSims{idx} ' ;' ]); 
                end

                dataSS_Point = calcData(im_R,HD,simsM,idxIterS,handles);
                
                dataSS6.evoBitError.X = [dataSS6.evoBitError.X, dataSS_Point.evoBitError.X];
                dataSS6.evoBitError.Y = [dataSS6.evoBitError.Y, dataSS_Point.evoBitError.Y];
                dataSS6.evoBitError.EL = [dataSS6.evoBitError.EL, dataSS_Point.evoBitError.EL];
                dataSS6.evoBitError.EU = [dataSS6.evoBitError.EU, dataSS_Point.evoBitError.EU];
                
                dataSS6.evoMean.X = [dataSS6.evoMean.X,dataSS_Point.evoMean.X];
                dataSS6.evoMean.Y = [dataSS6.evoMean.Y,dataSS_Point.evoMean.Y];
                dataSS6.evoMean.EL = [dataSS6.evoMean.EL,dataSS_Point.evoMean.EL];
                dataSS6.evoMean.EU = [dataSS6.evoMean.EU,dataSS_Point.evoMean.EU];
                
                dataSS6.evoStd.X = [dataSS6.evoStd.X,dataSS_Point.evoStd.X];
                dataSS6.evoStd.Y = [dataSS6.evoStd.Y,dataSS_Point.evoStd.Y];
                dataSS6.evoStd.EL = [dataSS6.evoStd.EL,dataSS_Point.evoStd.EL];
                dataSS6.evoStd.EU = [dataSS6.evoStd.EU,dataSS_Point.evoStd.EU];
                
                dataSS6.evoEnt.X = [dataSS6.evoEnt.X,dataSS_Point.evoEnt.X];
                dataSS6.evoEnt.Y = [dataSS6.evoEnt.Y,dataSS_Point.evoEnt.Y];
                dataSS6.evoEnt.EL = [dataSS6.evoEnt.EL,dataSS_Point.evoEnt.EL];
                dataSS6.evoEnt.EU = [dataSS6.evoEnt.EU,dataSS_Point.evoEnt.EU];
                
            end

            % 7 -> AdSEMES
            scriptParams.outFolder   = [scriptParams.outFolderSS filesep 'SS_7'];
            if(idxIterS > 10)
                scriptParams.outFolder   = [scriptParams.outFolder filesep ...
                                            'CumulativeSampling_'...
                                            num2str(idxIterS)];
            else
                scriptParams.outFolder   = [scriptParams.outFolder filesep ...
                                            'CumulativeSampling_'...
                                            '1'];                
            end
            scriptParams.outFolder = [fullfile(scriptParams.outFolder) filesep];
            if exist([scriptParams.outFolder 'Simulations.mat']) > 0
                load([scriptParams.outFolder 'Simulations.mat']);

                HD                          = nan(size(mFile.RI_1));
                idxA                        = (mFile.v_LocSamples_7 > 0) & ...
                                              (mFile.v_LocSamples_7 <= idxIterS);
                HD(idxA)                    = im_R(idxA);            
                varSims = who('Sims_*');
                % varsSims = who('Sims_*');
                for idx = 1:numel(varSims)
                    eval(['simsM(:,:,idx) = ' varSims{idx} ' ;' ]); 
                end

                dataSS_Point = calcData(im_R,HD,simsM,idxIterS,handles);
                
                dataSS7.evoBitError.X = [dataSS7.evoBitError.X, dataSS_Point.evoBitError.X];
                dataSS7.evoBitError.Y = [dataSS7.evoBitError.Y, dataSS_Point.evoBitError.Y];
                dataSS7.evoBitError.EL = [dataSS7.evoBitError.EL, dataSS_Point.evoBitError.EL];
                dataSS7.evoBitError.EU = [dataSS7.evoBitError.EU, dataSS_Point.evoBitError.EU];
                
                dataSS7.evoMean.X = [dataSS7.evoMean.X,dataSS_Point.evoMean.X];
                dataSS7.evoMean.Y = [dataSS7.evoMean.Y,dataSS_Point.evoMean.Y];
                dataSS7.evoMean.EL = [dataSS7.evoMean.EL,dataSS_Point.evoMean.EL];
                dataSS7.evoMean.EU = [dataSS7.evoMean.EU,dataSS_Point.evoMean.EU];
                
                dataSS7.evoStd.X = [dataSS7.evoStd.X,dataSS_Point.evoStd.X];
                dataSS7.evoStd.Y = [dataSS7.evoStd.Y,dataSS_Point.evoStd.Y];
                dataSS7.evoStd.EL = [dataSS7.evoStd.EL,dataSS_Point.evoStd.EL];
                dataSS7.evoStd.EU = [dataSS7.evoStd.EU,dataSS_Point.evoStd.EU];
                
                dataSS7.evoEnt.X = [dataSS7.evoEnt.X,dataSS_Point.evoEnt.X];
                dataSS7.evoEnt.Y = [dataSS7.evoEnt.Y,dataSS_Point.evoEnt.Y];
                dataSS7.evoEnt.EL = [dataSS7.evoEnt.EL,dataSS_Point.evoEnt.EL];
                dataSS7.evoEnt.EU = [dataSS7.evoEnt.EU,dataSS_Point.evoEnt.EU];
                
            end

        end
        
        
                
        plotAxes(dataSS1,...
         handles.hSS1_Samples,handles.hSS1_Mean,...
         handles.hSS1_Std,handles.hSS1_Ent);
        
%        plotAxes(dataSS2,...
%         handles.hSS1_Samples,handles.hSS1_Mean,...
%         handles.hSS1_Std,handles.hSS1_Ent);

         plotAxes(dataSS3,...
         handles.hSS1_Samples,handles.hSS1_Mean,...
         handles.hSS1_Std,handles.hSS1_Ent);

%        plotAxes(dataSS4,...
%         handles.hSS1_Samples,handles.hSS1_Mean,...
%         handles.hSS1_Std,handles.hSS1_Ent);

        plotAxes(dataSS5,...
         handles.hSS1_Samples,handles.hSS1_Mean,...
         handles.hSS1_Std,handles.hSS1_Ent);

     %% Hiding oracle
        %plotAxes(dataSS6,...
        % handles.hSS1_Samples,handles.hSS1_Mean,...
        % handles.hSS1_Std,handles.hSS1_Ent);

        plotAxes(dataSS7,...
         handles.hSS1_Samples,handles.hSS1_Mean,...
         handles.hSS1_Std,handles.hSS1_Ent);

        limits.bitE.minV = inf;
        limits.bitE.maxV = -inf;
        
        limits.evoEnt.minV = inf;
        limits.evoEnt.maxV = -inf;
        
        limits.evoMean.minV = inf;
        limits.evoMean.maxV = -inf;

        limits.evoStd.minV = inf;
        limits.evoStd.maxV = -inf;
                
        for idxL = 1:7
            eval(['dataSS = dataSS' num2str(idxL) ';']);
            limits.bitE.maxV = max(limits.bitE.maxV,max(dataSS.evoBitError.Y + dataSS.evoBitError.EU));
            limits.bitE.minV = min(limits.bitE.minV,min(dataSS.evoBitError.Y - dataSS.evoBitError.EL));
            
            limits.evoEnt.maxV = max(limits.evoEnt.maxV,max(dataSS.evoEnt.Y + dataSS.evoEnt.EU));
            limits.evoEnt.minV = min(limits.evoEnt.minV,min(dataSS.evoEnt.Y - dataSS.evoEnt.EL));
            
            limits.evoMean.maxV = max(limits.evoMean.maxV,max(dataSS.evoMean.Y + dataSS.evoMean.EU));
            limits.evoMean.minV = min(limits.evoMean.minV,min(dataSS.evoMean.Y - dataSS.evoMean.EL));

            limits.evoStd.maxV = max(limits.evoStd.maxV,max(dataSS.evoStd.Y + dataSS.evoStd.EU));
            limits.evoStd.minV = min(limits.evoStd.minV,min(dataSS.evoStd.Y - dataSS.evoStd.EL));
            
            
        end
        updateAxisLimits(handles,limits);
% Limit for bit      
     
    end
    end
    
end
end



function dataSS_Point = calcData(im_R,HD,simsM,idxIterS,handles)

simsM = simsM(:,:,1:200);
Hbin        = @(p) -p.*log2(p) - (1-p).*log2(1-p);

p1                  = (1.0*sum(simsM,3))/size(simsM,3);
Hsims               = Hbin(p1);
Hsims(isnan(Hsims)) = 0;

Hsims = Hsims(:);
Hsims(~isnan(HD(:))) = [];

% Iso probabilities
%ImAv = ((Hsims > handles.trshMin) & (Hsims < handles.trshMax));
%ImAv = ((Hsims >= 0.5) & (Hsims <= 1.0));
%Hsims = Hsims(ImAv);


% Bit error
for idxI = 1:size(simsM,3)
    errorBit(idxI) = sum(sum(abs(simsM(:,:,idxI) - im_R)))./ sum(sum(isnan(HD)));
end
    vecMean   = mean(simsM,3);% - im_R);
    vecStd    = std(simsM,0,3);% - im_R);

    vecMean = vecMean(:);
    vecStd = vecStd(:);

    vecMean(~isnan(HD(:))) = [];
    vecStd(~isnan(HD(:))) = [];

    
dataSS_Point.evoBitError.X = idxIterS;
dataSS_Point.evoBitError.Y = mean(errorBit);
dataSS_Point.evoBitError.EL = std(errorBit-mean(errorBit));%abs( mean(errorBit) - min(errorBit));%std(errorBit);
dataSS_Point.evoBitError.EU = std(errorBit-mean(errorBit));%abs( mean(errorBit) - max(errorBit));%std(errorBit);

dataSS_Point.evoMean.X = idxIterS;
dataSS_Point.evoMean.Y = mean(vecMean);
dataSS_Point.evoMean.EL = std(vecMean-mean(vecMean));%abs( mean(vecMean(:)) - min(vecMean(:)));%std(vecMean(:));
dataSS_Point.evoMean.EU = std(vecMean-mean(vecMean));%abs( mean(vecMean(:)) - max(vecMean(:)));%std(vecMean(:));

dataSS_Point.evoStd.X = idxIterS;
dataSS_Point.evoStd.Y = mean(vecStd);
dataSS_Point.evoStd.EL = std(vecStd - mean(vecStd));%abs( mean(vecStd(:)) - min(vecStd(:)));%std(vecStd(:));
dataSS_Point.evoStd.EU = std(vecStd - mean(vecStd));%abs( mean(vecStd(:)) - max(vecStd(:)));%std(vecStd(:));

dataSS_Point.evoEnt.X = idxIterS;
dataSS_Point.evoEnt.Y = mean(Hsims);
dataSS_Point.evoEnt.EL = std(Hsims - mean(Hsims));%abs( mean(Hsims(:)) - min(Hsims(:)));%std2(Hsims);
dataSS_Point.evoEnt.EU = std(Hsims - mean(Hsims));%abs( mean(Hsims(:)) - max(Hsims(:)));%std2(Hsims);

% Iso probabilities
ImAv = ((Hsims > handles.trshMin) & (Hsims < handles.trshMax));
Hiso = Hsims(ImAv);

%dataSS_Point.evoIso.X = idxIterS;
%dataSS_Point.evoIso.Y = mean(Hiso(:));
%dataSS_Point.evoIso.E = std(Hiso(:));







function plotAxes(dataSS,hAxes_Samples,hAxes_Mean,hAxes_Std,hAxes_Ent)
% PLot mean
axes(hAxes_Samples);
hold on;
errorbar(dataSS.evoBitError.X,dataSS.evoBitError.Y,...
         dataSS.evoBitError.EL,dataSS.evoBitError.EU);
%legend('Rand','Det Strat','Rand Strat','MultiScale Strat','Max Indicator','AdSEMES Oracle','AdSEMES Exp')
%legend('Rand','Rand Strat','Max Indicator','AdSEMES Oracle','AdSEMES Exp')
legend('Rand','Rand Strat','Max Indicator','AdSEMES Exp')
title('Bit Error vs Number of Sims')
xlabel('Number of Samples')
ylabel('Bit Error')

% PLot mean
axes(hAxes_Mean);
hold on;
errorbar(dataSS.evoMean.X,dataSS.evoMean.Y,...
         dataSS.evoMean.EL,dataSS.evoMean.EU);
%legend('Rand','Det Strat','Rand Strat','MultiScale Strat','Max Indicator','AdSEMES Oracle','AdSEMES Exp')
%legend('Rand','Rand Strat','Max Indicator','AdSEMES Oracle','AdSEMES Exp')
legend('Rand','Rand Strat','Max Indicator','AdSEMES Exp')
title('Mean of Sims')
xlabel('Number of Samples')
ylabel('Mean')

% PLot Std
axes(hAxes_Std);
hold on;
errorbar(dataSS.evoStd.X,dataSS.evoStd.Y,...
         dataSS.evoStd.EL,dataSS.evoStd.EU);
%legend('Rand','Det Strat','Rand Strat','MultiScale Strat','Max Indicator','AdSEMES Oracle','AdSEMES Exp')
%legend('Rand','Rand Strat','Max Indicator','AdSEMES Oracle','AdSEMES Exp')
legend('Rand','Rand Strat','Max Indicator','AdSEMES Exp')
title('Std of Sims')
xlabel('Number of Samples')
ylabel('Std')

% PLot Entropy
axes(hAxes_Ent);
hold on;
errorbar(dataSS.evoEnt.X,dataSS.evoEnt.Y,...
         dataSS.evoEnt.EL,dataSS.evoEnt.EU);
%legend('Rand','Det Strat','Rand Strat','MultiScale Strat','Max Indicator','AdSEMES Oracle','AdSEMES Exp')
%legend('Rand','Rand Strat','Max Indicator','AdSEMES Oracle','AdSEMES Exp')
legend('Rand','Rand Strat','Max Indicator','AdSEMES Exp')
%title('Iso Entropy of Sims (>0.5 & <1.0)')
title('Entropy of Sims')
xlabel('Number of Samples')
ylabel('Entropy')


function updateAxisLimits(handles,limits)
% Limit for bit error
shift = 0.1;
for idxAxis = 1%:7
eval(['ylim(handles.hSS'  num2str(idxAxis) '_Samples, [' ...
                                        num2str(limits.bitE.minV-shift) ...
                                        ' ' ...
                                        num2str(limits.bitE.maxV+shift) ...
                                        ']);']);
eval(['ylim(handles.hSS'  num2str(idxAxis) '_Ent, [' ...
                                        num2str(limits.evoEnt.minV-shift) ...
                                        ' ' ...
                                        num2str(limits.evoEnt.maxV+shift) ...
                                        ']);']);
eval(['ylim(handles.hSS'  num2str(idxAxis) '_Mean, [' ...
                                        num2str(limits.evoMean.minV-shift) ...
                                        ' ' ...
                                        num2str(limits.evoMean.maxV+shift) ...
                                        ']);']);

eval(['ylim(handles.hSS'  num2str(idxAxis) '_Std, [' ...
                                        num2str(limits.evoStd.minV-shift) ...
                                        ' ' ...
                                        num2str(limits.evoStd.maxV+shift) ...
                                        ']);']);
                                    
                                    
end

function SaveAxesNow(handAxes,pathAxes)
    F=getframe(handAxes); %select axes in GUI
    %F=getimage(handAxes); %select axes in GUI
    figure(); %new figure
    image(F.cdata); %show selected axes in new figure
    saveas(gcf, pathAxes, 'fig'); %save figure
    saveas(gcf, pathAxes, 'png'); %save figure
    close(gcf); %and close it







% --- Outputs from this function are returned to the command line.
function varargout = f5_Performance_Evol_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on selection change in ppmModelSelection.
function ppmModelSelection_Callback(hObject, eventdata, handles)
% hObject    handle to ppmModelSelection (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns ppmModelSelection contents as cell array
%        contents{get(hObject,'Value')} returns selected item from ppmModelSelection

handles.selectedModel = get(hObject,'Value');
UpdateGraphics(handles);
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function ppmModelSelection_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ppmModelSelection (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editUpperT_Callback(hObject, eventdata, handles)

contents = cellstr(get(hObject,'String'));
handles.trshMax = min(1.0,str2num(contents{1}));
handles.trshMax = max(0.0, handles.trshMax);
UpdateGraphics(handles);
guidata(hObject, handles);



function editLowerT_Callback(hObject, eventdata, handles)

contents = cellstr(get(hObject,'String'));
handles.trshMin = min(1.0,str2num(contents{1}));
handles.trshMin = max(0.0, handles.trshMin);

UpdateGraphics(handles);

guidata(hObject, handles);







