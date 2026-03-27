filesF = what('./Rand');

for idxF =1 : numel(filesF.mat)
    fileName = filesF.mat{idxF};
    x = strsplit(fileName,'_');
    numberH(idxF) = str2num(x{4});
    load(['./Rand/' fileName]);
    hMeasure = hist(dummy(:),30);
    probH(idxF) = hMeasure(30)/sum(hMeasure);
end

plot(numberH, probH)
title('Probability of optimal selection on Random Sampling: Model 1')
xlabel('Sampling regime [Number of samples]')
ylabel('Probability')