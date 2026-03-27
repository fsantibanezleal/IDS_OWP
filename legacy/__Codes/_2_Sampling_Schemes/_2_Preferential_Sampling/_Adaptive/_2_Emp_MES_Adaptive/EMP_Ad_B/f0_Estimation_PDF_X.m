function stOut = f0_Estimation_PDF_X(stParams)


%% Local Mapping of input parameters %%
try im_R     = stParams.im_R;     catch, im_R     = eye(200);           end
try dim_im_R = stParams.dim_im_R; catch, dim_im_R = size(im_R);         end

try im_T     = stParams.im_T;     catch, im_T     = eye(200);           end
try dim_im_T = stParams.dim_im_T; catch, dim_im_T = size(im_T);         end

try v_LocSampled  = stParams.v_LocSampled; catch, v_LocSampled = 0.*im_R(:);end
try v_idx_LocFree = stParams.v_idx_LocFree; catch, v_idx_LocFree = 1:numel(im_R);end

Hbin       = @(p) -p.*log2(p) - (1-p).*log2(1-p);

%% Marginal probability for TI_i = 1;
%stParams.Pm1                 = sum(im_T(:)>0)/numel(im_T);
stParams.Pm1                 = sum(im_T(:)>0)/prod(dim_im_T);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Function operation

% Index for Nan positions
I_Sampled                   = (v_LocSampled > 0);   % Sampled Positions
I_unSampled                 = ~I_Sampled;        % Non Sampled Positions

stParams.dimIT              = size(im_T);

% Marginal Probabilities.
if numel(stParams.P_XiEQ1_prev) < 1
    P_XiEQ1                 = stParams.Pm1 .* ones(dim_im_T);
else
    P_XiEQ1                 = stParams.P_XiEQ1_prev;
end
% For sampled position entropy is zero, then a degenerated prob is present.
P_XiEQ1(I_Sampled)          = 1; % or zero... is the same  



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

stParams.ImT                = im_T * 2;
stParams.ImT                = stParams.ImT - 1;

[gridX, gridY]               = meshgrid(1:dim_im_T(1),1:dim_im_T(2));         
stParams.gridX               = gridX;
stParams.gridY               = gridY;
matFileS                    = stParams.matFileS;

stCond                      = matFileS.stCond;

INFO_PDF                    = matFileS.PDF_TI_1_INFO;

stParams.minCompPattern     = stCond.minCompPattern;
%% Cases for fast ending
if stCond.minCompPattern > sum(I_Sampled)
    % Nothing to do. No available information to define preferential sampling
else
    pdfEq1      = stParams.Pm1;    
    numPosRed   = 1;
    if numel(stParams.P_XiEQ1_prev) > 1
        % If previous entropy estimation, then only search in neighborn of
        % last selected location
        numPosFull                  = numel(v_idx_LocFree);
        [~,idx_Last]                = max(v_LocSampled);
        [idx_R_Last, idx_C_Last]    = ind2sub(dim_im_R,idx_Last);
        
        maxBlockSW = ceil(mean(dim_im_R)/3);
        
        % Reduce search space!!!!
        dummyNoSampled              = ones(dim_im_T);
        dummyNoSampled(I_Sampled)   = 0;
        
        dummyNeig                   = ones(dim_im_T);
        limR_Min                    = max(1,idx_R_Last-maxBlockSW);
        limR_Max                    = min(dim_im_R(1),idx_R_Last+maxBlockSW);
        limC_Min                    = max(1,idx_C_Last-maxBlockSW);
        limC_Max                    = min(dim_im_R(2),idx_C_Last+maxBlockSW);
        dummyNeig(1:limR_Min,:)     = 0;
        dummyNeig(limR_Max:end,:)   = 0;
        dummyNeig(:,1:limC_Min)     = 0;
        dummyNeig(:,limC_Max:end)   = 0;
        
        dummyNoSampled              = dummyNoSampled .* dummyNeig;
        v_idx_LocFree               = find(dummyNoSampled);
        numPosRed                   = numel(v_idx_LocFree)/numPosFull;
    end
    
    numIDXs = numel(v_idx_LocFree);
    %parfor idxRef = 1:numIDXs
    %    idxP = v_idx_LocFree(idxRef);
    %    patternSearch = f0_FindPattern(idxP,stParams);

    %    P_XiEQ1_Dummy(idxRef) = f0_Estimation_PDF_Xi_byPattern(...
    %                            patternSearch,stParams);
    %end

    parfor idxRef = 1:numIDXs
        idxP                    = v_idx_LocFree(idxRef);
        v_SizesSemiWP(idxRef)   = ...
            f0_FindPatternSizeRestricted(idxP,stParams,INFO_PDF);
    end
    
    P_XiEQ1_Dummy_G = pdfEq1 .* ones(size(v_idx_LocFree));
    while sum(v_SizesSemiWP > 0)
        maxSizeSemiWP           = max(v_SizesSemiWP);

        disp([ 'Remaining: ' num2str(sum(v_SizesSemiWP>0)) ...
               '     Max Size: ' num2str(maxSizeSemiWP) ...
               '   Only Updating stats for : ' num2str(100*numPosRed) ' %']);

        v_IDX_M                 = find(v_SizesSemiWP == maxSizeSemiWP);
        v_IDXFreeRel            = v_idx_LocFree(v_IDX_M);
        % Load stats for this size
        %% For the Model, for each TIPS based stats
        eval(['stPDF_DUMMY = matFileS.PDF_TI_1_stSize_'...
               num2str(2*maxSizeSemiWP+1) ';']);

        stPDF = stPDF_DUMMY;
        clear stPDF_DUMMY
        P_XiEQ1_Dummy_L = pdfEq1 .* ones(size(v_IDX_M));
        
        v_SizesSemiWP_Local = v_SizesSemiWP(v_IDX_M);
        % For each object of this size try to validate stats
        for idxRef = 1:numel(v_IDX_M)
            % Obtain pattern of selected size
            idxOrigenP      = v_IDXFreeRel(idxRef);
            patternSearch   = f0_FindPatternBySize(...
                                    idxOrigenP,stParams,maxSizeSemiWP);

            %% Provide the verification value                                
            valueV  = sum(patternSearch.PM(:)) + 1;                                
            %% Estimate Stats
            if sum(patternSearch.PM(:)) < stCond.minCompPattern
                v_SizesSemiWP_Local(idxRef) = 0;
            else
                % For pattern with value 1 at center
                M1  = stPDF.pXi_1.vPatterns .'* patternSearch.P1(:);

                % For pattern with value -1 at center
                M2  = stPDF.pXi_0.vPatterns .'* patternSearch.P2(:);

                % Only keep pixels with magic number
                MM1 = (M1 == valueV);
                MM2 = (M2 == valueV);

                % Count apparitions of 1's and 0's
                p1  = sum(stPDF.pXi_1.vCounts(MM1));
                p2  = sum(stPDF.pXi_0.vCounts(MM2));
            
                %% Validate Stats
                if (p1 + p2) >= stCond.minPatternTimes
                    P_XiEQ1_Dummy_L(idxRef) = p1 /(p1 + p2);
                    v_SizesSemiWP_Local(idxRef) = 0;
                else
                    v_SizesSemiWP_Local(idxRef) = ...
                        f0_NextSizeAfterRemoveFarestP(patternSearch,...
                                                      stParams,...
                                                      INFO_PDF,20);
                end                
            end            
        end
        
        v_SizesSemiWP(v_IDX_M)      = v_SizesSemiWP_Local;
        P_XiEQ1_Dummy_G(v_IDX_M)    = P_XiEQ1_Dummy_L;
    end
    
    P_XiEQ1(v_idx_LocFree) = P_XiEQ1_Dummy_G;    
end
% H = (H > Hprev).*Hprev + (H <= Hprev).*H; % Keep prev entropy if delta H > 0
% If estimation could be done (min patternTimes satisfied) APos = 1, H = H_i+1
% If estimation couldn't be done (min patternTimes not satisfied OR size(Pattern Mask) less than 1) APos = 0,
% H_Maximization = 0, H_Update = 1 
% If estimation wasn't necessary at this iteration, APos = 0.5, H = H_i
stOut.P_XiEQ1 = P_XiEQ1;
stOut.P_XiEQ0 = 1 - P_XiEQ1;
stOut.H_X     = Hbin(P_XiEQ1);

end

