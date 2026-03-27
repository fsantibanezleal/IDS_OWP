function stAdSEMAS_Out = AdSEMES_SLOW(stParams)
%% function stParamsAdSEMAS_Out = AdSEMAS(stParamsAdSEMAS_In)

    stParamsOut = f0_Estimation_PDF_X_SLOW(stParams);

%% Find Location for Measurement -----------------------

    [maxH,~]    = max(stParamsOut.H_X(:));
    v_IDX       = find( stParamsOut.H_X(:) == maxH);
%% Simplest solution. Select randomly from maximum positions
    idx_MES         = v_IDX(randi(numel(v_IDX)));
%% Outputs        
    stAdSEMAS_Out.idxK_Selected     = idx_MES;
    stAdSEMAS_Out.maxH_Xi           = maxH;
    stAdSEMAS_Out.sumH_X            = sum(stParamsOut.H_X(:));
    stAdSEMAS_Out.H_X               = stParamsOut.H_X;
end
