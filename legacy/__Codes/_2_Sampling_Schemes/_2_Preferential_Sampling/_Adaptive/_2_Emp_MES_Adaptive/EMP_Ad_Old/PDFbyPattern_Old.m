function [pdfE,availablePos,reals] = PDFbyPattern_Old( patternSearch,stParams )
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%  
availablePos = 0;
pdfE  = stParams.Pm1;
reals = NaN;

if sum(patternSearch.PM(:)) < 1 
    return;
end

%% Provide the verification value
valueV = sum(patternSearch.PM(:)) + 1;

%% Obtain the apparitions of pattern by 
%evaluate pixels with validation Number
% For pattern with value 1 at center
M1 = conv2(stParams.ImT,patternSearch.P1,'same');

% For pattern with value -1 at center
M2 = conv2(stParams.ImT,patternSearch.P2,'same');

% Only keep pixels with magic number
MM1 = (M1 == valueV);
MM2 = (M2 == valueV);

% Count apparitions of 1's and 0's
p1  = sum(MM1(:));
p2  = sum(MM2(:));
reals = p1 + p2;
if (p1 + p2) >= stParams.minPatternTimes
    availablePos = 1;
    pdfE = p1 /(p1 + p2);    
else
    %availablePos = 0;
    %pdfE = 0.0;
    % Backoff removing 1 conditionant (farest one)
    patternSearch = RemoveFarestP_Old(patternSearch);
    [pdfE,availablePos,reals] = PDFbyPattern_Old( patternSearch,stParams );    
end

end

