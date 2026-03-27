function varargout = f5_PerformanceEntropy_atSamp(varargin)
% f5_PerformanceEntropy_atSamp_atSamp MATLAB code for f5_PerformanceEntropy_atSamp_atSamp.fig
%      f5_PerformanceEntropy_atSamp, by itself, creates a new f5_PerformanceEntropy_atSamp or raises the existing
%      singleton*.
%
%      H = f5_PerformanceEntropy_atSamp returns the handle to a new f5_PerformanceEntropy_atSamp or the handle to
%      the existing singleton*.
%
%      f5_PerformanceEntropy_atSamp('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in f5_PerformanceEntropy_atSamp.M with the given input arguments.
%
%      f5_PerformanceEntropy_atSamp('Property','Value',...) creates a new f5_PerformanceEntropy_atSamp or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before f5_PerformanceEntropy_atSamp_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to f5_PerformanceEntropy_atSamp_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help f5_PerformanceEntropy_atSamp

% Last Modified by GUIDE v2.5 20-Apr-2016 18:16:21

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @f5_PerformanceEntropy_atSamp_OpeningFcn, ...
                   'gui_OutputFcn',  @f5_PerformanceEntropy_atSamp_OutputFcn, ...
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


% --- Executes just before f5_PerformanceEntropy_atSamp is made visible.
function f5_PerformanceEntropy_atSamp_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to f5_PerformanceEntropy_atSamp (see VARARGIN)


%% Load stFolders mat file from DB folder
% VAlid Experiment with maximum distance criteria for choose from several
% maxima
%sFolderDB = ['Exp1_20160627_SOFI' filesep];
% VAlid Experiment with random selection from several
% maxima
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


handles.idxReal = 13;

handles.trshMin = 0.8;
handles.trshMax = 1.0;

handles.selectedModel        = 1;
handles.selectedSampledLevel = '200';

handles.edgeWidth = 0;

UpdateGraphics(hObject,handles)



% Choose default command line output for f5_PerformanceEntropy_atSamp
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes f5_PerformanceEntropy_atSamp wait for user response (see UIRESUME)
% uiwait(handles.mainS);





function UpdateGraphics(hObject,handles)


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


    % Update handles structure
    if exist(['..' filesep '..' filesep ...
                                stFolders.OutCome stFolders.FolderNAME ...
                                filesModels(idxM).name filesep ...
                                'Sampling_Process_' ...
                                num2str(handles.idxReal) '.mat'] ...
                ) == 0
        handles.idxReal = 1;
        guidata(hObject, handles);
    end        
                
    for idxSP =1:numel(filesSamp)    
    if (numel(strfind(filesSamp(idxSP).name, 'Sampling_Process_')) > 0) &&...
       (numel(strfind(filesSamp(idxSP).name, '.mat')) > 0) && ...
        strcmp(filesSamp(idxSP).name,['Sampling_Process_' num2str(handles.idxReal) '.mat'])

        % Load current Model
        mFile       = load(['..' filesep '..' filesep ...
                                stFolders.OutCome stFolders.FolderNAME ...
                                filesModels(idxM).name filesep ...
                                filesSamp(idxSP).name]);

        TI          = mFile.TI_1;
        im_R        = mFile.RI_1;

        imReal      = im_R;
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
        idxIterS = str2num(handles.selectedSampledLevel);
        %for idxIterS = [1,100,nSamples]
        %for idxIterS = nSamples
            % 1 -> Random Uniform
            % Provide Path to oputput Folder
            scriptParams.outFolder   = [scriptParams.outFolderSS filesep 'SS_1'];
            if(idxIterS > 10)
                scriptParams.outFolder   = [scriptParams.outFolder filesep ...
                                            'CumulativeSampling_'...
                                            num2str(idxIterS)];
                                      
                                       levelS = num2str(idxIterS);
            else
                scriptParams.outFolder   = [scriptParams.outFolder filesep ...
                                            'CumulativeSampling_'...
                                            '1'];                
                                        levelS = '1';
            end
            scriptParams.outFolder = [fullfile(scriptParams.outFolder) filesep];

            % Update handles structure
            if exist([scriptParams.outFolder 'Simulations.mat']) == 0
                handles.selectedSampledLevel = '1';
                idxIterS = 1;
                
                scriptParams.outFolder   = [scriptParams.outFolderSS filesep 'SS_1'];                
                scriptParams.outFolder   = [scriptParams.outFolder filesep ...
                                            'CumulativeSampling_'...
                                            '1'];  
                levelS = '1';                                        
                
                scriptParams.outFolder = [...
                                fullfile(scriptParams.outFolder) filesep];
                            
                set(handles.myLevelofSamplesMenu,'Value',1);
                           
                            
                guidata(hObject, handles);
                
                
            end     
            
            load([scriptParams.outFolder 'Simulations.mat']);

            HD                          = nan(size(mFile.RI_1));
            idxA                        = (mFile.v_LocSamples_1 > 0) & ...
                                          (mFile.v_LocSamples_1 <= idxIterS);
            HD(idxA)                    = im_R(idxA);    
            
            HD(isnan(HD)) = 0.5;

            varSims = who('Sims_*');
            % varsSims = who('Sims_*');
            for idx = 1:numel(varSims)
                eval(['simsM(:,:,idx) = ' varSims{idx} ' ;' ]); 
            end
            
            plotAxes(imReal,HD,simsM,...
                     handles.hSS1_Samples,handles.hSS1_Mean,...
                     handles.hSS1_Ent,...
                     handles.hSS1_Iso,...
                     handles,...
                     filesModels(idxM).name,'Rand',levelS);
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
            load([scriptParams.outFolder 'Simulations.mat']);

            HD                          = nan(size(mFile.RI_1));
            idxA                        = (mFile.v_LocSamples_2 > 0) & ...
                                          (mFile.v_LocSamples_2 <= idxIterS);
            HD(idxA)                    = im_R(idxA);   
            
            HD(isnan(HD)) = 0.5;

            varSims = who('Sims_*');
            % varsSims = who('Sims_*');
            for idx = 1:numel(varSims)
                eval(['simsM(:,:,idx) = ' varSims{idx} ' ;' ]); 
            end
            
            plotAxes(imReal,HD,simsM,...
                     handles.hSS2_Samples,handles.hSS2_Mean,...
                     handles.hSS2_Ent,...
                     handles.hSS2_Iso,...
                     handles,...
                     filesModels(idxM).name,'Det_Strat',levelS);
            
            % 3 -> Random Stratified

            %  4 -> Det Strat multiscale
 

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
            load([scriptParams.outFolder 'Simulations.mat']);
            HD                          = nan(size(mFile.RI_1));
            idxA                        = (mFile.v_LocSamples_5 > 0) & ...
                                          (mFile.v_LocSamples_5 <= idxIterS);
            HD(idxA)                    = im_R(idxA);            
            
            HD(isnan(HD)) = 0.5;

            varSims = who('Sims_*');
            
            
            % varsSims = who('Sims_*');
            for idx = 1:numel(varSims)
                eval(['simsM(:,:,idx) = ' varSims{idx} ' ;' ]); 
            end
            
            plotAxes(imReal,HD,simsM,...
                     handles.hSS5_Samples,handles.hSS5_Mean,...
                     handles.hSS5_Ent,...
                     handles.hSS5_Iso,...
                     handles,...
                     filesModels(idxM).name,'Max_Indicator',levelS);

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
            load([scriptParams.outFolder 'Simulations.mat']);
            HD                          = nan(size(mFile.RI_1));
            idxA                        = (mFile.v_LocSamples_6 > 0) & ...
                                          (mFile.v_LocSamples_6 <= idxIterS);
            HD(idxA)                    = im_R(idxA);            
            
            
            
            HD(isnan(HD)) = 0.5;


            
            varSims = who('Sims_*');
            % varsSims = who('Sims_*');
            for idx = 1:numel(varSims)
                eval(['simsM(:,:,idx) = ' varSims{idx} ' ;' ]); 
            end
            
            plotAxes(imReal,HD,simsM,...
                     handles.hSS6_Samples,handles.hSS6_Mean,...
                     handles.hSS6_Ent,...
                     handles.hSS6_Iso,...
                     handles,...
                     filesModels(idxM).name,'AdSEMES_Oracle',levelS);

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
            load([scriptParams.outFolder 'Simulations.mat']);
            HD                          = nan(size(mFile.RI_1));
            idxA                        = (mFile.v_LocSamples_7 > 0) & ...
                                          (mFile.v_LocSamples_7 <= idxIterS);
            HD(idxA)                    = im_R(idxA);            
            
            
            
            HD(isnan(HD)) = 0.5;
            
            varSims = who('Sims_*');
            % varsSims = who('Sims_*');
            for idx = 1:numel(varSims)
                eval(['simsM(:,:,idx) = ' varSims{idx} ' ;' ]); 
            end
            
            plotAxes(imReal,HD,simsM,...
                     handles.hSS7_Samples,handles.hSS7_Mean,...
                     handles.hSS7_Ent,...
                     handles.hSS7_Iso,...
                     handles,...
                     filesModels(idxM).name,'AdSEMES_Exp',levelS);


        %end

    end
    end
    
end
end







function plotAxes(imReal,imSampled,simsM,hAxes_Samples,hAxes_Mean,hAxes_Ent,hAxes_Iso,handles, modelS,SamplingScheme,levelS)
% PLot mean
axes(hAxes_Samples);
axis off;
imagesc(imSampled);
axis off;

%imwrite(imSampled,[modelS '_' SamplingScheme '_' levelS '_Samples.png'])

% PLot mean
axes(hAxes_Mean);
axis off;
imagesc(mean(simsM,3));
axis off;

dummy = mean(simsM,3);
%imwrite(dummy,[modelS '_' SamplingScheme '_' levelS '_Mean_IMG.png'])
f = figure();
hist(dummy(:),30)
%saveas(f,[modelS '_' SamplingScheme '_' levelS '_Mean_HIST.png'] );
close

dummy = std(simsM,1,3);
%imwrite(dummy,[modelS '_' SamplingScheme '_' levelS '_Std_IMG.png'])
f = figure();
hist(dummy(:),30)
%saveas(f,[modelS '_' SamplingScheme '_' levelS '_Std_HIST.png'] );
close


% PLot Entropy
Hbin        = @(p) -p.*log2(p) - (1-p).*log2(1-p);

p1                  = sum(simsM,3)/size(simsM,3);
Hsims               = Hbin(p1);
Hsims(isnan(Hsims)) = 0;
axes(hAxes_Ent);
axis off;
imagesc(Hsims);
axis off;

dummy = Hsims;
%imwrite(dummy,[modelS '_' SamplingScheme '_' levelS '_Ent_IMG.png'])
f = figure();
hist(dummy(:),30)
save([modelS '_' SamplingScheme '_' levelS '_Ent_HIST.mat'],'dummy');
%saveas(f,[modelS '_' SamplingScheme '_' levelS '_Ent_HIST.png'] );
close





% Iso probabilities
%axes(hAxes_Iso);
%axis off;
%imagesc(Hsims .* ((Hsims > handles.trshMin) & (Hsims < handles.trshMax)))
%axis off;

%dummy = Hsims .* ((Hsims > handles.trshMin) & (Hsims < handles.trshMax));
%imwrite(dummy,[modelS '_' SamplingScheme '_' levelS '_Iso_IMG.png'])
%f = figure();
%hist(dummy(:),30)
%saveas(f,[modelS '_' SamplingScheme '_' levelS '_Iso_HIST.png'] );
%close

% Now plot entropies close to real data
axes(hAxes_Iso);
axis off;
handles.edgeWidth
imagesc(imReal)
%imagesc(Hsims .* ((Hsims > handles.trshMin) & (Hsims < handles.trshMax)))
axis off;








% --- Outputs from this function are returned to the command line.
function varargout = f5_PerformanceEntropy_atSamp_OutputFcn(hObject, eventdata, handles) 
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
UpdateGraphics(hObject,handles);
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


% --- Executes on selection change in ppmCumSamples.
function ppmCumSamples_Callback(hObject, eventdata, handles)
% hObject    handle to ppmCumSamples (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns ppmCumSamples contents as cell array
%        contents{get(hObject,'Value')} returns selected item from ppmCumSamples

handles.myLevelofSamplesMenu = hObject;
contents = cellstr(get(hObject,'String'));
handles.selectedSampledLevel = contents{get(hObject,'Value')};
UpdateGraphics(hObject,handles);
% Update handles structure
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function ppmCumSamples_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ppmCumSamples (see GCBO)
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
UpdateGraphics(hObject,handles);
guidata(hObject, handles);



function editLowerT_Callback(hObject, eventdata, handles)

contents = cellstr(get(hObject,'String'));
handles.trshMin = min(1.0,str2num(contents{1}));
handles.trshMin = max(0.0, handles.trshMin);

UpdateGraphics(hObject,handles);

guidata(hObject, handles);


function editWidth_Callback(hObject, eventdata, handles)

contents = cellstr(get(hObject,'String'));

numWidth = ceil(str2num(contents{1}));

handles.edgeWidth = min(100.0,numWidth);
handles.edgeWidth = max(0.0, handles.edgeWidth);

set(hObject,'String',num2str(handles.edgeWidth))

UpdateGraphics(hObject,handles);
guidata(hObject, handles);





