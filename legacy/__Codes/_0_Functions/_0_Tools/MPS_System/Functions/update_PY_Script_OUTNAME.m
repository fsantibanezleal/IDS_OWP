function update_PY_Script_OUTNAME(fileName,subName,fileDummyName)
% FASL 2014...
% fsantibanez@med.uchile.cl    
    fin  = fopen(fileName,'r');
    fout = fopen(fileDummyName,'wt');    
    
    while true
        buffer = fgetl(fin);
        % get first word in line and remainder of line    
        [token,remain] = strtok(buffer);  
        if strcmp(token,'#MATLAB_MOD_OUTSUBNAME')
            fprintf(fout,[buffer '\n']);
            
            outBuffer = ['outSubName   = ''' subName '.gslib' ''''];
            fprintf(fout,[outBuffer '\n']);
            % Skip lines
            dummyB = fgetl(fin);            
        elseif strcmp(token,'#MATLAB_MOD_ENDFILE')
            fprintf(fout,[buffer '\n']);  
            break;
        else
            %just copy buffer to outfile
            fprintf(fout,[buffer '\n']);              
        end  
    end
    
%% Close all files
    fclose('all');
%% Copy data to required file
    copyfile(fileDummyName, fileName);    
end