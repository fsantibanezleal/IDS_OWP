function [P1,P0,Hnext,stParams] = PDFMatrixEstimation_Old(stParams,Hprev)
% Square block to search for patterns
%stParams.sizeBlockPattern = 10;
% minimun of realizations for current pattern
%stParams.minPatternTimes  = 10;
APos = [];
tic;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Function operation

% Index for Nan positions
I_NA = stParams.I_unSampled;            % Non Sampled Positions
I_A  =  stParams.I_Sampled;     % Sampled Positions

P1 = 0.5*ones(stParams.dimIT);
P1(I_A) = 0;                        % Hay que definirlo en funci�n de las muestras.


[valEntropy,idxMaxEntropy] = sort(Hprev(:),'descend');
idxMaxEntropy(valEntropy < 0.3*max(valEntropy)) = [];                        % Only re-estimate entropy on locations with sufficient remanent entropy from prev. iteration
for i = 1:length(I_A), idxMaxEntropy(idxMaxEntropy == I_A(i)) = []; end      % Remove alredy sampled locations

APos = 0.5*ones(stParams.dimIT);
R = zeros(stParams.dimIT);
C = zeros(stParams.dimIT);
for idxP = idxMaxEntropy'
%for idxP = 1:5:numP
    
    % fprintf(repmat('\b',1,nM));
    % msgC = ['Iterating position : ' num2str(idxP) ' of ' num2str(numP)];     
    % disp(msgC);
    % nM   = numel(msgC) + 1;

    % patternSearch  = FindPattern(I_NA(idxP),stParams);    
    % P1(I_NA(idxP)) = PDFbyPattern(patternSearch,stParams);
    
    if sum(idxP == I_A)>0,
        disp(['problems -> ' num2str(sum(idxP == I_A))]);
        pause
    else
        
        patternSearch  = FindPattern_Old(idxP,stParams);
        %while avaibable
        [P1(idxP), availablePos,reals] = PDFbyPattern_Old(patternSearch,stParams);
        
        
        APos(idxP) = availablePos;
        R(idxP) = reals;
        C(idxP) = sum(patternSearch.PM(:));
    end  
end

P0               = 1 - P1;
H                = - P1 .* log2(P1) - P0 .* log2(P0);
H(isnan(H))      = 0;

% H = (H > Hprev).*Hprev + (H <= Hprev).*H; % Keep prev entropy if delta H > 0
% If estimation could be done (min patternTimes satisfied) APos = 1, H = H_i+1
% If estimation couldn't be done (min patternTimes not satisfied OR size(Pattern Mask) less than 1) APos = 0,
% H_Maximization = 0, H_Update = 1 
% If estimation wasn't necessary at this iteration, APos = 0.5, H = H_i

stParams.info.wedPval       = numel(find(APos == 0)) / numel(APos);

Hnext                           = Hprev;
Hnext(APos == 1)                = H(APos == 1);
Hnext(APos == 0)                = H(APos == 0);

% H_M                         = Hprev; 
% H_U                         = Hprev;
% H_M(APos == 1)              = H(APos == 1);
% H_U(APos == 1)              = H(APos == 1);
% H_M(APos == 0)              = 0;
% H_U(APos == 0)              = max(Hprev(:));

delta_H                     = (sum(Hprev(:)) - sum(Hnext(:)))/numel(Hprev);

 % if this quantity is less than wedP (defined before) then this estimation can be considered a good estimation
stParams.info.delta_H       = delta_H;
stParams.info.APos          = APos;
stParams.info.idxMaxEntropy = idxMaxEntropy;
stParams.info.valEntropy    = valEntropy;
stParams.info.R             = R;
stParams.info.C             = C;
stParams.TOC                = toc/60;

end

