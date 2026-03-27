function stDummy = TIPS_PreCalcFake(im_T,stParams,mfile)
%% For simplicity for square training images
%% function stPatterns = TIPS(im_T)
%% Params --------------------------------- %%
% Minimum number of realizations for current pattern
%stParams.minPatternTimes     = 6;                                         
% Minimum number of conditionals neccesary for current pattern 
%stParams.minCompPattern      = 3;
%stParams.minCompPattern      = 3;
% Minimum size for current pattern
%stParams.sizeMinBlockPattern = 21; % always odd
%[gridX, gridY]               = meshgrid(1:dim_im_T(1),1:dim_im_T(2));         
%stParams.gridX               = gridX;
%stParams.gridY               = gridY;

%dim_TI                       = size(im_T);

%% Using +1  and -1 for TI binary image
im_T        = im_T -  min(im_T(:));
im_T        = im_T ./ max(im_T(:));
im_T        = 2.*im_T - 1;

dim_TI      = size(im_T);
stDummy   = [];

    minBlock = stParams.sizeMinBlockPattern;
    maxBlock = ( dim_TI(1) - ceil(sqrt(stParams.minPatternTimes)));
    %maxBlock = 1 + 2*( dim_TI(1)-1 - ceil(sqrt(stParams.minPatternTimes)));
    
    INFO.minSizeBlock = minBlock;
    INFO.maxSizeBlock = maxBlock;
    
    eval(['mfile.' ...
           stParams.namePDF 'INFO = INFO;']);
       
%    for idxPS = minBlock : 2 : maxBlock
             
%% For each size of valid pattern block
%        centralB    = ceil(idxPS/2);
%        semiB       = centralB - 1;
%        numElB      = idxPS*idxPS;
%        centralB1D  = ceil(numElB/2);
%% Basic structure to fill
% FOr each size of block of patterns we need info about the present
% patterns for each central node value in the alphabet of X_i (-1 and 1 
% for now)
% structurePatterns.stSize_51.pXi_0.vPatterns
% structurePatterns.stSize_51.pXi_0.vCounts
% structurePatterns.stSize_51.pXi_1.vPatterns
% structurePatterns.stSize_51.pXi_1.vCounts

%        dummyPatternInfo.pXi_0.vPatterns    = [];
%        dummyPatternInfo.pXi_0.vCounts      = [];
%        dummyPatternInfo.pXi_1.vPatterns    = [];
%        dummyPatternInfo.pXi_1.vCounts      = [];
        
%        dummyP_Xi_0                         = [];
%        dummyP_Xi_1                         = [];        
%        tic;
%        for idxX = centralB:  dim_TI(1) -semiB
%            for idxY = centralB:  dim_TI(2) - semiB
        %for idxX =1:  dim_TI(1)
            % Provided valid positions for image MASK
            %minX_TI = max(idxX - semiB,1);
            %maxX_TI = min(idxX + semiB , dim_TI(1));
            % Provided valid positions for mini MASK
            %minX_P = semiB + 1 - (idxX - minX_TI);
            %maxX_P = semiB + 1 + (maxX_TI - idxX);

            %for idxY = 1:  dim_TI(2)
                % Provided valid positions for image MASK
                %minY_TI = max(idxY - semiB,1);
                %maxY_TI = min(idxY + semiB , dim_TI(2));       

                % Provided valid positions for mini MASK
                %minY_P = semiB + 1 - (idxY - minY_TI);
                %maxY_P = semiB + 1 + (maxY_TI - idxY);

                % Fill available measured positions
%                dummyB = im_T(idxX-semiB:idxX+semiB,idxY-semiB:idxY+semiB);
                %dummyB = zeros(idxPS);
                %dummyB(...
                %    minX_P:maxX_P,...
                %    minY_P:maxY_P) = ...
                %                im_T(minX_TI:maxX_TI,minY_TI:maxY_TI);
                % Using a vectorized form of the pattern 
                %  
%                patternFound = dummyB(:);
                
                %% Locate in the structure for central value in alphabet
%                if(patternFound(centralB1D) == 1)
                % For central value equal 1
%                    dummyP_Xi_1 = [dummyP_Xi_1, patternFound];
%                else
                % For central value equal 0
%                    dummyP_Xi_0 = [dummyP_Xi_0, patternFound];
%                end
%            end
%        end

%% Now count and iteratively delete
%    [C,~,v_idxC] = unique(dummyP_Xi_0','rows');
%    dummyPatternInfo.pXi_0.vPatterns = C';

%    for idxA = 1:size(C,1)
%        dummyPatternInfo.pXi_0.vCounts(idxA) = ...
%            numel(find(v_idxC == idxA));
%    end
                
%    [C,~,v_idxC] = unique(dummyP_Xi_1','rows');
%    dummyPatternInfo.pXi_1.vPatterns = C';

%    for idxA = 1:size(C,1)
%        dummyPatternInfo.pXi_1.vCounts(idxA) = ...
%            numel(find(v_idxC == idxA));
%    end
        
%% End of current block size analysis, then add substructure 
%        eval(['mfile.' ...
%               stParams.namePDF 'stSize_' num2str(idxPS) ...
%               '= dummyPatternInfo;']);
        %eval(['stPDFbyTI.stSize_' num2str(idxPS) '= dummyPatternInfo;']);
%        clear dummyPatternInfo
%        timeUsed = toc;
%        disp(['Ready with size : '  num2str(idxPS)...
%              ' using ' num2str(timeUsed) ' seconds.']);

%    end




end
