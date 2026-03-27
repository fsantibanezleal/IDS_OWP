function  patternSearch = f0_FindPatternBySize(idxP,stParams, blockSize )

% Position of required variable in row and column
[idxI,idxJ] = ind2sub(stParams.dim_im_T,idxP);

proposedWidth = blockSize;

patternSearch = [];

% take a mask Section with required mask size
% The center of the mask is the position required
widthMask        = proposedWidth;
% Pattern Mask Binary
patternSearch.PM = zeros(2*widthMask + 1);
% Pattern Mask Ternary 1
patternSearch.P1 = zeros(2*widthMask + 1);
% Pattern Mask Ternary 2
patternSearch.P2 = zeros(2*widthMask + 1);


% Provided valid positions for image MASK
limits.lbMask.min.x = max(idxI - widthMask,1);
limits.lbMask.min.y = max(idxJ - widthMask,1);

limits.lbMask.max.x = min(idxI + widthMask , stParams.dim_im_T(1));
limits.lbMask.max.y = min(idxJ + widthMask , stParams.dim_im_T(2));

% Provided valid positions for mini MASK
limits.lmMask.min.x = widthMask + 1 - (idxI - limits.lbMask.min.x);
limits.lmMask.min.y = widthMask + 1 - (idxJ - limits.lbMask.min.y);

limits.lmMask.max.x = widthMask + 1 + (limits.lbMask.max.x - idxI);
limits.lmMask.max.y = widthMask + 1 + (limits.lbMask.max.y - idxJ);

% Fill available measured positions
patternSearch.PM( limits.lmMask.min.x : limits.lmMask.max.x ,...
               limits.lmMask.min.y : limits.lmMask.max.y) = ...
             stParams.Mask( limits.lbMask.min.x : limits.lbMask.max.x ,...
                            limits.lbMask.min.y : limits.lbMask.max.y);

patternSearch.P1( limits.lmMask.min.x : limits.lmMask.max.x ,...
               limits.lmMask.min.y : limits.lmMask.max.y) = ...
             stParams.ImS( limits.lbMask.min.x : limits.lbMask.max.x ,...
                            limits.lbMask.min.y : limits.lbMask.max.y);

patternSearch.P2 = patternSearch.P1;

patternSearch.P1(widthMask + 1,widthMask + 1) =  1;
patternSearch.P2(widthMask + 1,widthMask + 1) = -1;

end

