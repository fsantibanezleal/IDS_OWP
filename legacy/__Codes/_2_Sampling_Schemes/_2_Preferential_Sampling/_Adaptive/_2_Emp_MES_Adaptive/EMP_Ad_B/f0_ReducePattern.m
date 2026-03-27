function patternSearch = f0_ReducePattern(patternSearch)
    Mask        = patternSearch.PM;
    N           = size(Mask,1);

    Mask(1,:)   = 0; 
    Mask(end,:) = 0;
    Mask(:,1)   = 0; 
    Mask(:,end) = 0;

    [y,x]       = find(Mask == 1);
    dX          = abs(x-ceil(N/2));
    dY          = abs(y-ceil(N/2));        

    dW          = max(max(dX),max(dY));
    dBorder     = (N - (2*dW+1))/2;
    patternSearch.PM = Mask(dBorder+1:end-dBorder,...
                            dBorder+1:end-dBorder);
    patternSearch.P1 = patternSearch.P1(...
                            dBorder+1:end-dBorder,...
                            dBorder+1:end-dBorder);
    patternSearch.P2 = patternSearch.P2(...
                            dBorder+1:end-dBorder,...
                            dBorder+1:end-dBorder);
end