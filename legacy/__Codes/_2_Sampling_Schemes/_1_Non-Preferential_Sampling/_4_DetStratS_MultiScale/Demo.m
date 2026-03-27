clear all
close all
clc

%folderDrop = 'C:\Users\FelipeAndres\Dropbox\';
%folderDrop = 'C:\Users\fsant_000\Dropbox\';
%folderDrop = 'C:\Users\fsant\Dropbox\';

fullpath = cd(cd([ ... 
                 '..' filesep '..' filesep '..' filesep '..' filesep ...
                 '__Codes' filesep]));
addpath(genpath(fullpath));
folderDrop = dropboxPath;

matFileS = matfile([folderDrop '__MatlabCode\_OWP\' ...
        '_1_DB\Exp1_20160101\' ...
        'model_1.mat']);
clear folderDrop

im_R        = matFileS.RI_1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% params
strParamS.dataImR.im_R              = im_R;
strParamS.dataImR.dim_imR           = size(im_R);

strParamS.Spec.nElemAxis            = 5;

strParamS.basics.v_LocSamples_Old   = 0 .* im_R(:);
strParamS.basics.num_Samples        = 1000;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

v_LocSamples = LocateSamples_DetStrat_MS(strParamS);


imSamples = reshape(v_LocSamples>0,size(im_R));
imagesc(imSamples);
figure;

im_Sampled = nan(size(im_R));
im_Sampled(v_LocSamples > 0) = im_R(v_LocSamples > 0);

imagesc(im_Sampled);
figure;
imagesc(im_R);  