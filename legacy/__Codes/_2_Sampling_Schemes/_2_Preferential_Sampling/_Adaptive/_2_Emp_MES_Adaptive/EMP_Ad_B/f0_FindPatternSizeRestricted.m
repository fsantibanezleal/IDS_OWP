function  sizeSemiWP = ...
            f0_FindPatternSizeRestricted(idxP,stParams,INFO_PDF )

sizeSemiWP = 0;

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

if numel(idxA) > stParams.minCompPattern

    % dX and dY
    dX = abs(idxI - gridX(idxA));
    dY = abs(idxJ - gridY(idxA));

    sizeSemiWP = max(max(dX),max(dY));

    maxBlockSW = ceil(mean(size(gridX))/3);
    %if sizeSemiWP > ((INFO_PDF.maxSizeBlock-1)/2)
    if sizeSemiWP > maxBlockSW
        %sizeSemiWP = ((INFO_PDF.maxSizeBlock-1)/2);
        sizeSemiWP = maxBlockSW;
    elseif sizeSemiWP < ((INFO_PDF.minSizeBlock-1)/2)
        sizeSemiWP = 0;
    end
end

end

