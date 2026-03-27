function sizeSemiWP = f0_NextSizeAfterRemoveFarestP(patternSearch,...
                                                    stParams,...
                                                    INFO_PDF,...
                                                    deltaKill)
                                                
                                                
    sizeSemiWP  = 0;
    
    Mask        = patternSearch.PM;
    [N1, N2]    = size(Mask);
    
    Mask(1:1+deltaKill     , :                  )   = 0;
    Mask(end-deltaKill:end , :                  )   = 0;
    Mask(:                 , 1:1+deltaKill      )   = 0;
    Mask(:                 , end-deltaKill:end  )   = 0;

    [idxR,idxC] = find(Mask == 1);
    if numel(idxR) > stParams.minCompPattern
        dRow        = abs(idxR-ceil(N1/2));
        dCol        = abs(idxC-ceil(N2/2));        

        sizeSemiWP  = max(max(dRow),max(dCol));


        if sizeSemiWP < ((INFO_PDF.minSizeBlock-1)/2)
            sizeSemiWP = 0;
        end
   end
end