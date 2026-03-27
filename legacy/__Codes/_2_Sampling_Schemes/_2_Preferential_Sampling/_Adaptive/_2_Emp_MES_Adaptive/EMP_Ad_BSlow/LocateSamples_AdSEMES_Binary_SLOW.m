function [v_LocSamples_New, ...
          stOut] = LocateSamples_AdSEMES_Binary_SLOW(strParamS)
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


    v_LocSamples_New    = v_LocSamples_Old;
    stOut.H_Xi          = v_Hi_Samples_Old;
    stOut.H_Xat         = H_Xat_Old;
    
%% Index to the next wanted location
    if exist('num_TakenSamples')
        idxLoc = num_TakenSamples + 1;
    else
        idxLoc = max(v_LocSamples_Old) + 1;
    end

%% Non Sampled Positions
    v_idx_Free = find(v_LocSamples_Old == 0);

%% Find AdSEMES positions one by one
stParamsAdSEMES.im_R        = im_R;
stParamsAdSEMES.dim_im_R    = size(im_R);

stParamsAdSEMES.im_T        = im_T;
stParamsAdSEMES.dim_im_T    = size(im_T);

stParamsAdSEMES.v_LocSampled    = v_LocSamples_Old > 0;
stParamsAdSEMES.v_idx_LocFree   = v_idx_Free;

% Delta Entropy and Entropy Statistics evolution ------
% H(X^fi|X_fi) - H(X^fi+1|X_fi+1), H(X^f|X_f) =(iid hyp.) sum_{j in f} ( H(X_j|X_Cj) ) mirar esto    
    while idxLoc <= num_Samples
        disp(['Taking sample:' num2str(idxLoc)]);
        stParamsAdSEMES_Out = AdSEMES_SLOW(stParamsAdSEMES);

        % Update Params
        stParamsAdSEMES.v_LocSampled( ...
            stParamsAdSEMES_Out.idxK_Selected) = 1;
        stParamsAdSEMES.v_idx_LocFree( ...
            stParamsAdSEMES.v_idx_LocFree == ...
            stParamsAdSEMES_Out.idxK_Selected)   = [];
        
        %% Update Outputs        
        % Located posi3tion and its correlative position of sampling.
        v_LocSamples_New(stParamsAdSEMES_Out.idxK_Selected) = idxLoc;

        stOut.H_Xi(...
            stParamsAdSEMES_Out.idxK_Selected) =...
                            stParamsAdSEMES_Out.maxH_Xi;        
        stOut.H_XforXi(...
            stParamsAdSEMES_Out.idxK_Selected) = ...
                            stParamsAdSEMES_Out.sumH_X;        
        stOut.H_Xat(...
            idxLoc,:,:) = ...
                            stParamsAdSEMES_Out.H_X;        

        % provide next position to search
        idxLoc = idxLoc + 1;        
    end
end

