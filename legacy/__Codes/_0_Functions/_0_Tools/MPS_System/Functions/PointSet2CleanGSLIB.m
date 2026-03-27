function PointSet2CleanGSLIB(fileName,image)

image      = flipud(image);
dims       = [size(image) 1];

DATA_TYPE  = 'harddata';
numb_par   = 3;% X loc, Y loc, porosity
param      = {'Xlocation';'Ylocation';'porosity'};

[Y, X]     = meshgrid(0:(dims(1)-1),0:(dims(2)-1));

% Vectorized data
vec_im     = image(:);
Y          = Y(:);
X          = X(:);

%Corrupt data en GSLIB format
I          = isnan(vec_im);
%image(I)  = -999999;

% Cleaning non measured data
vec_im(I)     = [];
Y(I)          = [];
X(I)          = [];

% data to write
todo = [Y,X,vec_im];

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