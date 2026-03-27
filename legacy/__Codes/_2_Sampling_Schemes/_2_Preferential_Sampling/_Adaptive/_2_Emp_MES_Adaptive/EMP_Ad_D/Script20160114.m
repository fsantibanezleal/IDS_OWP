close all
clear all
clc
load(['C:\Users\FelipeAndres\Dropbox\' ...
      '__AcademicDevelopment\Semester_VI\' ...
      '_OWP\_DB\_Texts_20160114\VisTex' filesep 'textures.mat']);
  
vNameV = who('Foo*');

for idxN = 1:numel(vNameV)
    eval(['imT = ' vNameV{idxN} ';']);
    imG(idxN,:,:) = rgb2gray(imT);
    imB(idxN,:,:) = imG(idxN,:,:) > 128;
end

clear Foo* idxN vNameV imT













