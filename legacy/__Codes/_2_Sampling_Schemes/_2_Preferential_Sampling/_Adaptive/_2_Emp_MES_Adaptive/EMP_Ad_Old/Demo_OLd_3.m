clear all
close all
clc

%folderDrop = 'C:\Users\FelipeAndres\Dropbox\';
%folderDrop = 'C:\Users\fsant_000\Dropbox\';
%folderDrop = 'C:\Users\fsant\Dropbox\';

fullpath = cd(cd(['..' filesep '..' filesep ... 
                 '..' filesep '..' filesep '..' filesep '..' filesep ...
                 '__Codes' filesep]));
addpath(genpath(fullpath));
%folderDrop = dropboxPath;
%folderDrop = 'C:\Users\fsant_000\Dropbox\';
folderDrop = 'C:\Users\fsant\Dropbox\';


matFileS = matfile([folderDrop '__MatlabCode\_OWP\' ...
        '_1_DB\Exp1_20160101\' ...
        'model_3.mat']);
clear folderDrop

im_R        = matFileS.RI_1;
im_T        = matFileS.TI_1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% params
strParamS.matFileS                  = matFileS;

strParamS.dataImR.im_R              = im_R;
strParamS.dataImR.im_T              = im_T;

strParamS.basics.v_LocSamples_Old   = 0 .* im_R(:);

strParamS.basics.v_Hi_Samples_Old   = nan(...
                                       size(...
                                       strParamS.basics.v_LocSamples_Old));
strParamS.basics.H_Xat_Old          = [];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Preliminary structured sampled positions
strParamS.dataImR.dim_imR           = size(im_R);
strParamS.Spec.nElemAxis            = 3;

% Tentative free measurements
strParamS.basics.num_Samples        = 9;
strParamS.basics.b_RandStrat        = true; 

strParamS.basics.v_LocSamples_Old = LocateSamples_RandStrat(strParamS);

%% Obtain remaining positions to measure
strParamS.basics.num_Samples        = 200;

[v_LocSamples, ...
          stOut] = LocateSamples_AdSEMES_Binary_Old(strParamS);



imSamples = reshape(v_LocSamples>0,size(im_R));
for idxR = 1:(strParamS.Spec.nElemAxis-1)
    imSamples(...
        :,...
        floor(...
              idxR*strParamS.dataImR.dim_imR(1)/strParamS.Spec.nElemAxis...
              )) = 1;
    imSamples(...
        floor(...
            idxR*strParamS.dataImR.dim_imR(2)/strParamS.Spec.nElemAxis...
              ),:) = 1;
end
imagesc(imSamples);
figure;

im_Sampled = nan(size(im_R));
im_Sampled(v_LocSamples > 0) = im_R(v_LocSamples > 0);

imagesc(im_Sampled);
figure;
imagesc(im_R);  