function patternSearch = RemoveFarestP_Old(patternSearch)
    Mask = patternSearch.PM;
    [N1, N2] = size(Mask);
    [y,x] = find(Mask == 1);
    d = (y-ceil(N1/2)).^2 + (x-ceil(N2/2)).^2;
    [~,idx] = max(d);
    Mask(y(idx),x(idx)) = 0;
    patternSearch.PM = Mask;
    patternSearch.P1(y(idx),x(idx)) = 0;
    patternSearch.P2(y(idx),x(idx)) = 0;
end