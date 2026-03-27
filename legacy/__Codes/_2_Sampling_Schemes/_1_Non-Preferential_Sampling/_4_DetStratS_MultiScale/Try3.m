clear all
close all
clc

im = zeros(200,200);
dimD1 = size(im,1);
dimD2 = size(im,2);
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

im_Samp         = zeros(size(im));
im_Levels       = zeros(size(im));

num_S           = 3000;

nElemAxis       = 5;
nElems          = 4*nElemAxis -4;

stepAxis        = 2/(nElemAxis-1);
intervalPos     = -1:stepAxis:1;

%%% Real distance to central point
divSpace        = 2;
%dD1             = ((nElemAxis-1)/2) * dimD1/nElemAxis;
%dD2             = ((nElemAxis-1)/2) * dimD2/nElemAxis;

dSepD1          = dimD1;
dSepD2          = dimD2;

dLimD1          = ((nElemAxis-1)/2) * dSepD1/nElemAxis;
dLimD2          = ((nElemAxis-1)/2) * dSepD2/nElemAxis;

%% First: Check fist level and make children


%% Search for leaves until reach num_S
bValid      = 1;
idxCurrent  = 0;

%% If previous measures, define as level 1, create level 2 positions and
% continue....
% for all previous measures.... 

%% Dummy create a full fisrt system
% Else... create one level 1 position at the center. then make the same..
%% Unique level 1 position
posD1                   = floor(dimD1/2);
posD2                   = floor(dimD2/2);
%idxCurrent              = idxCurrent + 1;
im_Levels(posD1,posD2)  = 1;
%im_Samp(posD1,posD2)    = idxCurrent;
%    imagesc(im_Samp>0);

levelCurrent = 1;

while bValid && (idxCurrent < num_S)
    %if levelCurrent == 2
    %    im_Levels(im_Levels == levelCurrent)  = levelCurrent+1;
    %end
    if (levelCurrent == 1) || (mod(nElemAxis,2) == 0)
        idxsLevel = find(im_Levels == levelCurrent);       
    else
        idxsLevel = [find(im_Levels == levelCurrent) ; ...
                     find(im_Levels == (levelCurrent -1))];
    end
    %% relative position of leaves for the next level
    %dRealD1 = floor(intervalPos .* dD1/(levelCurrent+1));
    %dRealD2 = floor(intervalPos .* dD2/(levelCurrent+1));
    dRealD1 = floor(intervalPos .* dLimD1);
    dRealD2 = floor(intervalPos .* dLimD2);

    for idxL = 1:numel(idxsLevel)
        [posD1,posD2] = ind2sub([dimD1,dimD2],idxsLevel(idxL));
        % Only iterates if current pos provide benefit
        %if im(posD1,posD2) ==1
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

                    if (posD1_Leave>0) && (posD1_Leave<=dimD1) && ...
                       (posD2_Leave>0) && (posD2_Leave<=dimD2)
                        if (idxCurrent >= num_S) ||...
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

                        imagesc(im_Samp>0);
                        pause(0.1);
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
    
    
%    dD1 = 0.5*dD1/(nElemAxis-1);
%    dD2 = 0.5*dD2/(nElemAxis-1);    
   
    dSepD1          = dSepD1/nElemAxis;
    dSepD2          = dSepD2/nElemAxis;

    dLimD1          = ((nElemAxis-1)/2) * dSepD1/nElemAxis;
    dLimD2          = ((nElemAxis-1)/2) * dSepD2/nElemAxis;
end





















