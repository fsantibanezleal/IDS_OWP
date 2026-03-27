function stAdSEMES_Out = AdSEMES_Old_Fake(stParams)
%% function stParamsAdSEMAS_Out = AdSEMAS(stParamsAdSEMAS_In)

    %% Local Mapping of input parameters %%
    try im_R     = stParams.im_R;     catch, im_R     = eye(200);           end
    try dim_im_R = stParams.dim_im_R; catch, dim_im_R = size(im_R);         end

    try im_T     = stParams.im_T;     catch, im_T     = eye(200);           end
    try dim_im_T = stParams.dim_im_T; catch, dim_im_T = size(im_T);         end

    try v_LocSampled  = stParams.v_LocSampled; catch, v_LocSampled = 0.*im_R(:);end
    try v_idx_LocFree = stParams.v_idx_LocFree; catch, v_idx_LocFree = 1:numel(im_R);end
    try num_Samples   = stParams.num_Samples; catch, num_Samples = 200; end
    
    Hbin       = @(p) -p.*log2(p) - (1-p).*log2(1-p);

    
    
    
    %% Index to the next wanted location
    idxLoc = stParams.num_TakenSamples + 1;
    
    
    %% Marginal probability for TI_i = 1;
    %stParams.Pm1                 = sum(im_T(:)>0)/numel(im_T);
    stParams.Pm1                 = sum(im_T(:)>0)/prod(dim_im_T);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% Function operation

    stParams.ImT                = im_T * 2;
    stParams.ImT                = stParams.ImT - 1;

    stParams.dimIT              = size(im_T);

    
    [gridX, gridY]               = meshgrid(1:dim_im_T(1),1:dim_im_T(2));         
    stParams.gridX               = gridX;
    stParams.gridY               = gridY;
    matFileS                    = stParams.matFileS;

    stCond                      = matFileS.stCond;

    INFO_PDF                    = matFileS.PDF_TI_1_INFO;

    stParams.minCompPattern     = stCond.minCompPattern;
    stParams.sizeMinBlockPattern = 13;
    stParams.minPatternTimes     = 4;


    Hprev = ones(dim_im_R);
    vecToMeasure = [1,20:20:400];
    
    v_LocSampledReal = stParams.v_LocSampled;
    v_LocSampled     = v_LocSampledReal .* 0;
    while idxLoc <= num_Samples
        if any(idxLoc == vecToMeasure)
            disp(['Taking sample:' num2str(idxLoc)]);



            % Index for Nan positions
            I_Sampled                   = (v_LocSampled > 0);   % Sampled Positions
            I_unSampled                 = ~I_Sampled;        % Non Sampled Positions

            % Marginal Probabilities.
            if numel(stParams.P_XiEQ1_prev) < 1
                P_XiEQ1                 = stParams.Pm1 .* ones(dim_im_T);
            else
                P_XiEQ1                 = stParams.P_XiEQ1_prev;
            end
            % For sampled position entropy is zero, then a degenerated prob is present.
            P_XiEQ1(I_Sampled)          = 1; % or zero... is the same  
            Hprev(I_Sampled)            = 0;

            % A mask for available pixels
            stParams.Mask               = zeros(dim_im_T);
            stParams.Mask(I_Sampled)    = 1;
            stParams.Mask_idxA          = find(stParams.Mask == 1);

            % A ternary version of image
            stParams.ImS                = nan(dim_im_R);
            stParams.ImS(I_Sampled)     = im_R(I_Sampled);
            stParams.ImS                = im_R     * 2;
            stParams.ImS                = stParams.ImS  - 1;
            stParams.ImS(I_unSampled)   = 0;

            stParams.I_Sampled = I_Sampled;
            stParams.I_unSampled = I_unSampled;

            %% Cases for fast ending
            [P1,P0,Hnext,stParams] = PDFMatrixEstimation_Old(stParams,Hprev);

            % H = (H > Hprev).*Hprev + (H <= Hprev).*H; % Keep prev entropy if delta H > 0
            % If estimation could be done (min patternTimes satisfied) APos = 1, H = H_i+1
            % If estimation couldn't be done (min patternTimes not satisfied OR size(Pattern Mask) less than 1) APos = 0,
            % H_Maximization = 0, H_Update = 1 
            % If estimation wasn't necessary at this iteration, APos = 0.5, H = H_i
            stOut.P_XiEQ1 = P1;
            stOut.P_XiEQ0 = 1 - P_XiEQ1;
            stOut.H_X     = Hbin(P_XiEQ1);
            stOut.H_X(...
             isnan(...
             stOut.H_X)) = 0;

            %% Find Location for Measurement -----------------------

                [maxH,~]    = max(stOut.H_X(:));
                v_IDX       = find( stOut.H_X(:) == maxH);
            %% Simplest solution. Select randomly from maximum positions
                idx_MES     = v_IDX(randi(numel(v_IDX)));
            %% Outputs        
                stAdSEMES_Out.idxK_Selected     = idx_MES;
                stAdSEMES_Out.maxH_Xi(idxLoc)   = maxH;
                stAdSEMES_Out.sumH_X(idxLoc)    = sum(stOut.H_X(:));
                stAdSEMES_Out.H_X(:,:,idxLoc)   = stOut.H_X;

                stAdSEMES_Out.P_XiEQ1           = stOut.P_XiEQ1;

                Hprev                           = stAdSEMES_Out.H_X(:,:,idxLoc);

            %% Update Outputs        
            % Located posi3tion and its correlative position of sampling.
            %v_LocSampled(stAdSEMES_Out.idxK_Selected) = idxLoc;

        else
                stAdSEMES_Out.maxH_Xi(idxLoc)   = 0;
                stAdSEMES_Out.sumH_X(idxLoc)    = 0;
                stAdSEMES_Out.H_X(:,:,idxLoc)   = stOut.H_X;            
                stAdSEMES_Out.P_XiEQ1           = stOut.P_XiEQ1;

                Hprev                           = stAdSEMES_Out.H_X(:,:,idxLoc);
                
        end
            idxLoc = idxLoc + 1;
            
            v_LocSampled(v_LocSampledReal == (idxLoc-1)) = idxLoc - 1;
    end
    
    stAdSEMES_Out.v_LocSamples = v_LocSampled;
end
