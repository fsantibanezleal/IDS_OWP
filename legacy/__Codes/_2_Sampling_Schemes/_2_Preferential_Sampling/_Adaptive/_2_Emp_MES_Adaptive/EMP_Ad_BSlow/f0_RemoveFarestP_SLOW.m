function patternSearch = f0_RemoveFarestP_SLOW(patternSearch)
    Mask        = patternSearch.PM;
    [N1, N2]    = size(Mask);
    [y,x]       = find(Mask == 1);
    d           = (y-ceil(N1/2)).^2 + (x-ceil(N2/2)).^2;
    [~,idx]     = max(d);
    
    Mask(y(idx),x(idx))             = 0;

    if (( sum(Mask(1,:)) + sum(Mask(end,:)) + ...
          sum(Mask(:,1)) + sum(Mask(:,end)) ) > 0)
        patternSearch.PM                = Mask;
        patternSearch.P1(y(idx),x(idx)) = 0;
        patternSearch.P2(y(idx),x(idx)) = 0;
    else
        [y,x]       = find(Mask == 1);
        dX          = abs(x-ceil(N1/2));
        dY          = abs(y-ceil(N1/2));        
        d           = dX.^2 + dY.^2;
        [~,idx]     = max(d);
        
        dW          = max(max(dX(idx)),max(dY(idx)));
        dBorder     = (N1 - (2*dW+1))/2;
        patternSearch.PM = Mask(dBorder+1:end-dBorder,...
                                dBorder+1:end-dBorder);
        patternSearch.P1 = patternSearch.P1(...
                                dBorder+1:end-dBorder,...
                                dBorder+1:end-dBorder);
        patternSearch.P2 = patternSearch.P2(...
                                dBorder+1:end-dBorder,...
                                dBorder+1:end-dBorder);
    end
end