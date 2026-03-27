function [v_LocSamples_New, ...
          stOut] = LocateSamples_AdSEMES_Binary(strParamS)
%% Inputs
% v_LocSamples_Old: A vector of length equal to the available positions.
%                   Currently with previous locations of measures.
% num_Samples     : Number of required additional samples
% num_TakenSamples: Number of previosly measured positions.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Local mapping of params
v_LocSamples_Old    = strParamS.basics.v_LocSamples_Old;
v_Hi_Samples_Old    = strParamS.basics.v_Hi_Samples_Old;
H_Xat_Old           = strParamS.basics.H_Xat_Old;

num_Samples         = strParamS.basics.num_Samples;

if isfield(strParamS, 'num_TakenSamples')
    num_TakenSamples = strParamS.basics.num_TakenSamples;
else
    num_TakenSamples = max(v_LocSamples_Old);    
end

im_R    = strParamS.dataImR.im_R;

im_T    = strParamS.dataImR.im_T;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
stParamsAdSEMES.num_Samples      = strParamS.basics.num_Samples;
stParamsAdSEMES.num_TakenSamples = num_TakenSamples;


%% Non Sampled Positions
    v_idx_Free = find(v_LocSamples_Old == 0);

%% Find AdSEMES positions one by one
stParamsAdSEMES.im_R        = im_R;
stParamsAdSEMES.dim_im_R    = size(im_R);

stParamsAdSEMES.im_T        = im_T;
stParamsAdSEMES.dim_im_T    = size(im_T);

stParamsAdSEMES.v_LocSampled    = v_LocSamples_Old;
stParamsAdSEMES.v_idx_LocFree   = v_idx_Free;

stParamsAdSEMES.matFileS        = strParamS.matFileS;
% Delta Entropy and Entropy Statistics evolution ------
% H(X^fi|X_fi) - H(X^fi+1|X_fi+1), H(X^f|X_f) =(iid hyp.) sum_{j in f} ( H(X_j|X_Cj) ) mirar esto    
    stParamsAdSEMES.P_XiEQ1_prev = [];

    stParamsAdSEMES_Out = AdSEMES(stParamsAdSEMES);

    v_LocSamples_New    = stParamsAdSEMES_Out.v_LocSamples;
    stOut.H_Xi          = stParamsAdSEMES_Out.maxH_Xi;        
    stOut.H_XforXi      = stParamsAdSEMES_Out.sumH_X;        
    stOut.H_Xat         = stParamsAdSEMES_Out.H_X;
end

