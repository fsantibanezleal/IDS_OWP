function v_LocSamples_New = LocateSamples_DetStrat_MS(strParamS)
% Multiscale deterministic sampling
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

dim_imR             = strParamS.dataImR.dim_imR;


nElemAxis           = strParamS.Spec.nElemAxis;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    v_LocSamples_New = v_LocSamples_Old;

%% Index to the next wanted location
    idxLoc = num_TakenSamples + 1;
%% Required Params
    
    
% Basic Pattern ...> rectangular
% nELemAxis >= 2
% nELemAxis = 4
%     X    X     X   X
%
%     X              X
%             0
%     X              X
%
%     X    X     X   X
% divSpace = 4;
% dD1 = floor(sizeD1/divSpace)
% dD2 = floor(sizeD2/divSpace)
%
% |-            sizeD2 = 22                    -|  _  
% 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0  |
% 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 
% 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 
% 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 
% 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0  sizeD1
% 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0  13
% 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 
% 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 
% 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 
% 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 
% 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 
% 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0  |
% 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0  _
    
im_Samp     = reshape(v_LocSamples_Old,dim_imR);
im_Levels   = zeros(dim_imR);
    
    
%nElems      = 4*nElemAxis -4;
stepAxis    = 2/(nElemAxis-1);
intervalPos = -1:stepAxis:1;
   
%%% Real distance to central point
dSepD1          = dim_imR(1);
dSepD2          = dim_imR(2);

dLimD1          = ((nElemAxis-1)/2) * dSepD1/nElemAxis;
dLimD2          = ((nElemAxis-1)/2) * dSepD2/nElemAxis;
    
%% Search for leaves until reach num_S
bValid      = 1;
idxCurrent  = 0;
    
%% Unique level 1 position
posD1                   = floor(dim_imR(1)/2);
posD2                   = floor(dim_imR(2)/2);
im_Levels(posD1,posD2)  = 1;

levelCurrent = 1;
while bValid && (idxCurrent < num_Samples)
    if (levelCurrent == 1) || (mod(nElemAxis,2) == 0)
        idxsLevel = find(im_Levels == levelCurrent);       
    else
        idxsLevel = [find(im_Levels == levelCurrent) ; ...
                     find(im_Levels == (levelCurrent -1))];
    end
    
    %% relative position of leaves for the next level
    dRealD1 = floor(intervalPos .* dLimD1);
    dRealD2 = floor(intervalPos .* dLimD2);

    
    if strParamS.basics.b_RandStrat
        vec_Elem = randperm(numel(idxsLevel));
    else
        vec_Elem = 1:numel(idxsLevel);
    end
    
    for idxL = vec_Elem
        [posD1,posD2] = ind2sub([dim_imR(1),dim_imR(2)],idxsLevel(idxL));
        % Only iterates if current pos provide benefit
        %if (im(posD1,posD2) ==1) || (levelCurrent == 1)
            for idxD1 = 1:nElemAxis
                for idxD2 = 1:nElemAxis
                    %if (((idxD1 > 1) && (idxD1 < nElemAxis)) && ...
                    %    ((idxD2 > 1) && (idxD2 < nElemAxis)) )  && ...
                    %    ( (idxD1 ~= ceil(nElemAxis/2)) && ...
                    %      (idxD2 ~= ceil(nElemAxis/2)))
                    %    continue;
                    %end
                    posD1_Leave = posD1 + dRealD1(idxD1);
                    posD2_Leave = posD2 + dRealD2(idxD2);

                    if (posD1_Leave>0) && (posD1_Leave<=dim_imR(1)) && ...
                       (posD2_Leave>0) && (posD2_Leave<=dim_imR(2))
                        if (idxCurrent >= num_Samples) ||...
                           (im_Samp(posD1_Leave,posD2_Leave)>0)
                            continue;
                        end
                        im_Levels(...
                            posD1_Leave,...
                            posD2_Leave) = levelCurrent + 1;
                        idxCurrent = idxCurrent + 1;
                        im_Samp(...
                                posD1_Leave,...
                                posD2_Leave)   = idxCurrent;

                        %imagesc(im_Samp>0);
                        %pause(0.1);
                        %imD = uint8(255.*(im_Samp>0));
                        %imRGB(:,:,1) = imD.*0;
                        %imRGB(:,:,2) = imD;
                        %imRGB(:,:,3) = imD.*0 + 255;
                        %imwrite(imRGB, ...
                        %       ['Sampled_' num2str(idxCurrent) '.png']);
                    end                    
                end
            end
        %end
    end
    
    levelCurrent = levelCurrent + 1;
   
    dSepD1          = dSepD1/nElemAxis;
    dSepD2          = dSepD2/nElemAxis;

    dLimD1          = ((nElemAxis-1)/2) * dSepD1/nElemAxis;
    dLimD2          = ((nElemAxis-1)/2) * dSepD2/nElemAxis;
end

v_LocSamples_New = im_Samp(:);





