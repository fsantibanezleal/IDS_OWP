function stOut = f0_Estimation_PDF_X_SLOW(stParams)


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
%% Params --------------------------------- %%
% Minimum number of realizations for current pattern
stParams.minPatternTimes     = 6;                                         
% Minimum number of conditionals neccesary for current pattern 
stParams.minCompPattern      = 3;
stParams.minCompPattern      = 3;
% Minimum size for current pattern
stParams.sizeMinBlockPattern = 20;                                        
[gridX, gridY]               = meshgrid(1:dim_im_T(1),1:dim_im_T(2));         
stParams.gridX               = gridX;
stParams.gridY               = gridY;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Function operation

% Index for Nan positions
I_Sampled                   = (v_LocSampled > 0);   % Sampled Positions
I_unSampled                 = ~I_Sampled;        % Non Sampled Positions

stParams.dimIT              = size(im_T);

% Marginal Probabilities.
P_XiEQ1                     = stParams.Pm1 .* ones(dim_im_T);
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

%% Cases for fast ending
if stParams.minCompPattern > sum(I_Sampled)
    % Nothing to do. No available information to define sampling
else
    numIDXs = numel(v_idx_LocFree);
    parfor idxRef = 1:numIDXs
        idxP = v_idx_LocFree(idxRef);
        patternSearch = f0_FindPattern_SLOW(idxP,stParams);

        P_XiEQ1_Dummy(idxRef) = f0_Estimation_PDF_Xi_byPattern_SLOW(...
                                patternSearch,stParams);
    end

    P_XiEQ1(v_idx_LocFree) = P_XiEQ1_Dummy;    
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

