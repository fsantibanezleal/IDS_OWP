function v_LocSamples_New = LocateSamples_DetStrat(strParamS)
%% Simple structured sampling
%% Inputs
% v_LocSamples_Old: A vector of length equal to the available positions.
%                   Currently with previous locations of measures.
% num_Samples     : Number of required additional samples
% num_TakenSamples: Number of previosly measured positions.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Local mapping of params
v_LocSamples_Old    = strParamS.basics.v_LocSamples_Old;
num_Samples         = strParamS.basics.num_Samples;
b_RandStrat         = strParamS.basics.b_RandStrat;

if isfield(strParamS, 'num_TakenSamples')
    num_TakenSamples = strParamS.basics.num_TakenSamples;
else
    num_TakenSamples = max(v_LocSamples_Old);    
end

dim_imR             = strParamS.dataImR.dim_imR;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    v_LocSamples_New =v_LocSamples_Old;

%% Index to the next wanted location
    if exist('num_TakenSamples','var')
        idxLoc = num_TakenSamples + 1;
    else
        idxLoc = max(v_LocSamples_Old) + 1;
    end

%% Structured dont considers previous selected locations
    numLocsByOrientation        = ceil(sqrt(num_Samples));

    stepX                       = ceil(dim_imR(1)/numLocsByOrientation);
    stepY                       = ceil(dim_imR(2)/numLocsByOrientation);
    
%    idxLocalInBox   = randperm(stepX*stepY,1);

%% Indexs to locations in X and Y
    idxLocsX                    = floor(0.5*stepX):stepX:dim_imR(1);
    idxLocsY                    = floor(0.5*stepY):stepY:dim_imR(2);

    dummyI                      = zeros(dim_imR);
    dummyI(idxLocsX,idxLocsY)   = 1;
    dummyI                      = dummyI(:);

    idx_ToUse                   = find(dummyI);
    num_Samples                 = min(num_Samples,numel(idx_ToUse));
    idx_ToUse                   = idx_ToUse(1:num_Samples);
%    idx_ToUse                   = idx_ToUse(sort(randperm(numel(idx_ToUse),num_Samples)));

    idxOrderOfSampling          = idxLoc: (idxLoc + num_Samples - 1);
    if b_RandStrat
        idxOrderOfSampling      = idxOrderOfSampling(randperm(num_Samples));
    end
    
    v_LocSamples_New(idx_ToUse) = idxOrderOfSampling;
end