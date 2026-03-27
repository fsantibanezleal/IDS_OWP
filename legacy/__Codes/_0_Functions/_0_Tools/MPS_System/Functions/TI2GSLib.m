function TI2GSLib(fileName,image)
    im     = flipud(double(image)');
    %im    = (imresize(im,0.5)>120);
    vec_im = uint8(rot90(im(:),2));
    dims   = [size(im) 1];
    name   = 'porosity';
    dlmwrite(fileName,dims,'delimiter',' ');
    dlmwrite(fileName,'1','-append');
    dlmwrite(fileName,name,'-append','delimiter','');
    dlmwrite(fileName,vec_im,'-append');
    
    fclose('all');
end