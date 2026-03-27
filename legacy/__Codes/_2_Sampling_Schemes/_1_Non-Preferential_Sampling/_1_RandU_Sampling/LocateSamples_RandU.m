function v_LocSamples_New = LocateSamples_RandU(strParamS)
%% Simple uniform random sampling
%% Inputs
% v_LocSamples_Old: A vector of length equal to the available positions.
%                   Currently with previous locations of measures.
% num_Samples     : Number of required additional samples
% num_TakenSamples: Number of previosly measured positions.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Local mapping of params
v_LocSamples_Old    = strParamS.basics.v_LocSamples_Old;
num_Samples         = strParamS.basics.num_Samples;

if isfield(strParamS, 'num_TakenSamples')
    num_TakenSamples = strParamS.basics.num_TakenSamples;
else
    num_TakenSamples = max(v_LocSamples_Old);    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


    v_LocSamples_New =v_LocSamples_Old;

%% Index to the next wanted location
    if exist('num_TakenSamples')
        idxLoc = num_TakenSamples + 1;
    else
        idxLoc = max(v_LocSamples_Old) + 1;
    end

%% Non Sampled Positions
    idx_Free = find(v_LocSamples_Old == 0);

%% Uniform Randomly selected Poisitions
    if numel(idx_Free) > 0
        if numel(idx_Free) < num_Samples
            num_Samples = numel(idx_Free);
        end
        idxToTakeFromFree = randperm(numel(idx_Free),num_Samples);

        idxOrderOfSampling = idxLoc: (idxLoc + num_Samples - 1);

        v_LocSamples_New(idx_Free(idxToTakeFromFree)) = idxOrderOfSampling;
    end
end