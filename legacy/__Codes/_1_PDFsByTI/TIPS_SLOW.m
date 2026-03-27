function stPDFbyTI = TIPS(im_T,stParams)
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
stPDFbyTI   = [];

    for idxPS = ...
            stParams.sizeMinBlockPattern: 2 : ...
            ( dim_TI(1) - stParams.minPatternTimes) 
%% For each size of valid pattern block
        centralB    = ceil(idxPS/2);
        semiB       = centralB - 1;
        numElB      = idxPS*idxPS;
        centralB1D  = ceil(numElB/2);
%% Basic structure to fill
% FOr each size of block of patterns we need info about the present
% patterns for each central node value in the alphabet of X_i (-1 and 1 
% for now)
% structurePatterns.stSize_51.pXi_0.vPatterns
% structurePatterns.stSize_51.pXi_0.vCounts
% structurePatterns.stSize_51.pXi_1.vPatterns
% structurePatterns.stSize_51.pXi_1.vCounts

        dummyPatternInfo.pXi_0.vPatterns    = [];
        dummyPatternInfo.pXi_0.vCounts      = [];
        dummyPatternInfo.pXi_1.vPatterns    = [];
        dummyPatternInfo.pXi_1.vCounts      = [];
        tic;
        for idxX = centralB:  dim_TI(1) -semiB
            for idxY = centralB:  dim_TI(2) - semiB
                dummyB = im_T(idxX-semiB:idxX+semiB,idxY-semiB:idxY+semiB);
                % Using a vectorized form of the pattern 
                %  
                patternFound = dummyB(:);
                %% Locate in the structure for central value in alphabet
                
                if(patternFound(centralB1D) == 1)
                % For central value equal 1
                % Check if current pattern was previosly found
                    %compP = conv2(...
                    %            dummyPatternInfo.pXi_1.vPatterns,...
                    %            flip(patternFound),'valid');
                    
                    if numel(dummyPatternInfo.pXi_1.vPatterns) > 0
                        compP = dummyPatternInfo.pXi_1.vPatterns .'* ...
                                                        patternFound;

                        findP = find(compP == numElB);
                    else
                        findP = [];
                    end
                    
                    if numel(findP) == 0
                        dummyPatternInfo.pXi_1.vPatterns = [ ...
                            dummyPatternInfo.pXi_1.vPatterns , ...
                            patternFound];
                        dummyPatternInfo.pXi_1.vCounts = [ ...
                            dummyPatternInfo.pXi_1.vCounts;
                            1 ];
                    else
                        dummyPatternInfo.pXi_1.vCounts(findP(1)) = ...
                            dummyPatternInfo.pXi_1.vCounts(findP(1)) + 1;
                    end
                else
                % For central value equal 0
                % Check if current pattern was previosly found
                    %compP = conv2(...
                    %            dummyPatternInfo.pXi_0.vPatterns,...
                    %            flip(patternFound),'valid');
                    %findP = find(compP == numElB);
                    
                    if numel(dummyPatternInfo.pXi_0.vPatterns) > 0
                        compP = dummyPatternInfo.pXi_0.vPatterns .'* ...
                                                        patternFound;
                        findP = find(compP == numElB);
                    else
                        findP = [];
                    end
                    
                    if numel(findP) == 0
                        dummyPatternInfo.pXi_0.vPatterns = [ ...
                            dummyPatternInfo.pXi_0.vPatterns , ...
                            patternFound];
                        dummyPatternInfo.pXi_0.vCounts = [ ...
                            dummyPatternInfo.pXi_0.vCounts;
                            1 ];
                    else
                        dummyPatternInfo.pXi_0.vCounts(findP(1)) = ...
                            dummyPatternInfo.pXi_0.vCounts(findP(1)) + 1;
                    end                    
                end
            end
        end


        
        
%% End of current block size analysis, then add substructure        
        eval(['stPDFbyTI.stSize_' num2str(idxPS) '= dummyPatternInfo;']);
        clear dummyPatternInfo
        timeUsed = toc/60;
        disp(['Ready with size : '  num2str(idxPS)...
              ' using ' num2str(timeUsed) ' minutes.']);

    end




end
