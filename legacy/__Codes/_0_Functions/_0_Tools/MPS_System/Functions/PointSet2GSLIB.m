function PointSet2GSLIB(fileName,image)

image      = flipud(image);
dims       = [size(image) 1];

%Corrupt data en GSLIB format
I          = isnan(image);
image(I)   = -999999;

DATA_TYPE  = 'harddata';
numb_par   = 3;% X loc, Y loc, porosity
param      = {'Xlocation';'Ylocation';'porosity'};

[Y, X]     = meshgrid(0:(dims(1)-1),0:(dims(2)-1));

vec_im     = image(:);

todo = [Y(:),X(:),vec_im];

%dlmwrite(fileName,DATA_TYPE,'-append','delimiter','');
dlmwrite(fileName,DATA_TYPE,'delimiter','');
dlmwrite(fileName,numb_par,'-append','delimiter',' ');
dlmwrite(fileName,param{1},'-append','precision','%.6f','delimiter','');
dlmwrite(fileName,param{2},'-append','precision','%.6f','delimiter','');
dlmwrite(fileName,param{3},'-append','precision','%.6f','delimiter','');
dlmwrite(fileName,num2str(todo),...
                  '-append','precision','%.6f','delimiter','')

fclose('all');
end