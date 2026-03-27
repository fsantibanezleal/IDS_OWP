clear all
close all
clc



%folderDrop = 'C:\Users\FelipeAndres\Dropbox\';
folderDrop = 'C:\Users\fsant_000\Dropbox\';
%folderDrop = 'C:\Users\fsant\Dropbox\';

load([folderDrop '__MatlabCode\_OWP\' ...
        '_1_DB\Exp1_20160101\' ...
        'model_1.mat']);
clear folderDrop

im_T    = model_1.TI_1;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% params
strParamS.dataImR.im_T      = im_T;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Params --------------------------------- %%
% Minimum number of realizations for current pattern
stParams.minPatternTimes     = 6;                                         
% Minimum number of conditionals neccesary for current pattern 
stParams.minCompPattern      = 3;
stParams.minCompPattern      = 3;
% Minimum size for current pattern
stParams.sizeMinBlockPattern = 21; % always odd

tic;
stPDFbyTI = TIPS(im_T,stParams);
finalTime = toc/60;
disp(['Time For count patterns : ' num2str(finalTime) ' minutes.']);
%    save('model.mat','stPDFbyTI','-v7.3','-append')
%m = matfile('myfile.mat','Writable',true);
%m.y(end+1,1) = m.y(end,1)