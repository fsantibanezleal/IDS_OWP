clear all
close all
clc

%folderDrop = 'C:\Users\FelipeAndres\Dropbox\';
folderDrop = 'C:\Users\fsant_000\Dropbox\';
%folderDrop = 'C:\Users\fsant\Dropbox\';

matFileS = matfile([folderDrop '__MatlabCode\_OWP\' ...
        '_1_DB\Exp1_20160101\' ...
        'model_1.mat']);
clear folderDrop

im_R        = matFileS.model_1.RI_1;
im_T        = matFileS.model_1.TI_1;
clear folderDrop

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% params
strParamS.dataImR.im_R              = im_R;
strParamS.dataImR.im_T              = im_T;

strParamS.basics.v_LocSamples_Old   = 0 .* im_R(:);
strParamS.basics.num_Samples        = 3;

strParamS.basics.v_Hi_Samples_Old   = nan(...
                                       size(...
                                       strParamS.basics.v_LocSamples_Old));
strParamS.basics.H_Xat_Old          = [];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[v_LocSamples, ...
          stOut] = LocateSamples_AdSEMES_Binary_SLOW(strParamS);


im_Sampled = nan(size(im_R));
im_Sampled(v_LocSamples > 0) = im_R(v_LocSamples > 0);

imagesc(im_Sampled);
figure;
imagesc(im_R);