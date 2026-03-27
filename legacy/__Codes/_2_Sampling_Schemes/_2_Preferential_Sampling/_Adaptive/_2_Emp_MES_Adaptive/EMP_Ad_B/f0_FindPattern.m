function  patternSearch = f0_FindPattern(idxP,stParams )

% New approach. Obtain a direct estimation for required Block size
% these matrixs would be saved before start all
% stParams.gridX and stParams.gridY

%[gridX, gridY] = meshgrid(1:stParams.dimIT(1),1:stParams.dimIT(2));
gridX = stParams.gridX;
gridY = stParams.gridY;

% Position of required variable in row and column
[idxI,idxJ] = ind2sub(stParams.dim_im_T,idxP);
% Available Measured positions
% idxA = find(stParams.Mask == 1);
idxA = stParams.Mask_idxA;

% dX and dY
dX = idxI - gridX(idxA);
dY = idxJ - gridY(idxA);
% squared Distances Map
[~,idxM] = sort(dX.^2 + dY.^2);

%proposedWidth = 1;
%if numel(dM) > 0
%    if numel(dM) <= stParams.minCompPattern
%        proposedWidth = ceil(sqrt(dM(end)));
%    else
%        proposedWidth = ceil(sqrt(dM(stParams.minCompPattern)));
%        proposedWidth = max(proposedWidth,stParams.sizeMinBlockPattern);
%    end
%end
proposedWidth = max(abs(dX(idxM(end))),abs(dY(idxM(end))));

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

