% f0_Caller

%% Provide paths
addpath(genpath('Functions'));
addpath(genpath('mGstatReduced'));

%% Please provide TI (training image) and HD hard data (samples)
%% EXAMPLE: Load your Training Image and Sampled Image
% Training            : TI = N x N matrix, binary
% Sample (hard data)  : HD = N x N matrix , Nans in unknown pixels
% Example: 

load('EXAMPLE_TI.mat');
load('EXAMPLE_Sample_01.mat');

TI = TI;
HD = Sample;

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Providing params 
% number of realizations
scriptParams.numReals  = 5;

% path to Sgems
stPaths.SgemsExe = 'C:\SGeMS-x64-Beta';
% Provide Path to oputput Folder
scriptParams.outFolder   = 'C:\SIMS';
% Provide the name of the file with simulations
scriptParams.fileSimName = 'Simulations';


%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Running Main Script
bSaveImages = 1; % Save images as PNG 
bSaveMAT    = 1; % Save Data simulations as MAT file
SimsBySgems(TI,HD,stPaths,scriptParams,bSaveImages,bSaveMAT);

       
       
       