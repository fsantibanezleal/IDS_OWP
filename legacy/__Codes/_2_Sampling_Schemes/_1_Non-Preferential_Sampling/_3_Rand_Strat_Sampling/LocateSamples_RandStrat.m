function v_LocSamples_New = LocateSamples_RandStrat(strParamS)
% Select quadrant deterministically and then take a sample at random loc.
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
    numLocsByOrientation        = sqrt(num_Samples);

    stepD1                      = dim_imR(1)/numLocsByOrientation;
    stepD2                      = dim_imR(2)/numLocsByOrientation;
    
    stepSD1                     = 0.5*stepD1;
    stepSD2                     = 0.5*stepD2;

%    idxLocalInBox   = randperm(stepX*stepY,1);

%% Indexs to locations in X and Y
    idxLocsD1                   = stepSD1:stepD1:dim_imR(1);
    idxLocsD2                   = stepSD2:stepD2:dim_imR(2);

    % int version
    idxLocsD1                   = floor(idxLocsD1);
    idxLocsD2                   = floor(idxLocsD2);  
    stepSD1                     = floor(stepSD1);
    stepSD2                     = floor(stepSD2);
    
    dummyI                      = zeros(dim_imR);
    dummyI(idxLocsD1,idxLocsD2) = 1;
    dummyI                      = dummyI(:);

    idx_ToUse                   = find(dummyI);
    num_Samples                 = min(num_Samples,numel(idx_ToUse));
    idx_ToUse                   = idx_ToUse(1:num_Samples);
%    idx_ToUse                  = idx_ToUse(sort(randperm(numel(idx_ToUse),num_Samples)));

    [idxD1,idxD2]               = ind2sub(dim_imR,idx_ToUse);
    dD1                         = randi([-(stepSD1-1), (stepSD1)],...
                                         num_Samples,1);
    dD2                         = randi([-(stepSD2-1), (stepSD2)],...
                                         num_Samples,1);

    idxD1                       = min(idxD1 + dD1,dim_imR(1));                                     
    idxD2                       = min(idxD2 + dD2,dim_imR(2));
    
    idx_ToUse                   = sub2ind(dim_imR,idxD1,idxD2);

    idxOrderOfSampling          = idxLoc: (idxLoc + num_Samples - 1);
    
    if b_RandStrat
        idxOrderOfSampling      = idxOrderOfSampling(randperm(num_Samples));
    end    
    v_LocSamples_New(idx_ToUse) = idxOrderOfSampling;
end