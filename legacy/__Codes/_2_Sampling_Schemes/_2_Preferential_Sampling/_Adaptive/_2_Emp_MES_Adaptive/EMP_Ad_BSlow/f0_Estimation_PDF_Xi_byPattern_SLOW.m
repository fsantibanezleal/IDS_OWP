function pdfEq1 = f0_Estimation_PDF_Xi_byPattern_SLOW(...
                                                patternSearch,stParams )
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    pdfEq1  = stParams.Pm1;

    if sum(patternSearch.PM(:)) < stParams.minCompPattern 
        return;
    end


    %% ONly process CONV if enough of operations will be available
    vW = size(patternSearch.PM,1);
    
    if  ( vW <= stParams.dimIT(2) && ...
          ((stParams.dimIT(1) - vW)>= stParams.minPatternTimes) ) && ...
        ( vW <= stParams.dimIT(1) && ...
          ((stParams.dimIT(2) - vW)>= stParams.minPatternTimes) )
      
        %% Provide the verification value
        valueV  = sum(patternSearch.PM(:)) + 1;

        %% Obtain the apparitions of pattern by 
        %evaluate pixels with validation Number
        % For pattern with value 1 at center
        M1  = conv2(stParams.ImT,patternSearch.P1,'same');

        % For pattern with value -1 at center
        M2  = conv2(stParams.ImT,patternSearch.P2,'same');

        % Only keep pixels with magic number
        MM1 = (M1 == valueV);
        MM2 = (M2 == valueV);

        % Count apparitions of 1's and 0's
        p1  = sum(MM1(:));
        p2  = sum(MM2(:));

        %reals           = p1 + p2;
        if (p1 + p2) >= stParams.minPatternTimes
            pdfEq1  = p1 /(p1 + p2);    
        else
            % Backoff removing 1 conditionant (farest one)
            patternSearch   = f0_RemoveFarestP_SLOW(patternSearch);
            pdfEq1          = f0_Estimation_PDF_Xi_byPattern_SLOW(...
                                        patternSearch,stParams );    
        end
    else
            % Backoff removing 1 conditionant (farest one)
            patternSearch   = f0_ReducePattern_SLOW(patternSearch);
            pdfEq1          = f0_Estimation_PDF_Xi_byPattern_SLOW(...
                                        patternSearch,stParams );    
    end
end

