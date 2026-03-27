function update_PY_Script(fileName,fileDummyName,params)
% FASL 2014...
% fsantibanez@med.uchile.cl    
    fin  = fopen(fileName,'r');
    fout = fopen(fileDummyName,'wt');    
    while true
        buffer = fgetl(fin);
        % get first word in line and remainder of line    
        [token,remain] = strtok(buffer);  
        if strcmp(token,'#MATLAB_MOD_SGEMSDATA')
            fprintf(fout,[buffer '\n']);            
            outBuffer = ['sgemsDir    = ''' params.sgemsDir ''''];
            
            dummyBB = '';
            for idx=1:size(outBuffer,2)
                if strcmp(outBuffer(idx),'\')
                    dummyBB = [dummyBB '/'];
                else
                    dummyBB = [dummyBB outBuffer(idx)];
                end
            end
            fprintf(fout,[dummyBB '\n']); 
            
            outBuffer = ['sNameTI     = ''' params.nameDataTI ''''];
            fprintf(fout,[outBuffer '\n']); 
            outBuffer = ['sNameHD     = ''' params.nameDataHD ''''];
            fprintf(fout,[outBuffer '\n']); 
            % Skip lines
            dummyB = fgetl(fin);
            dummyB = fgetl(fin);
            dummyB = fgetl(fin);
        elseif strcmp(token,'#MATLAB_MOD_NUM_REALIZATIONS')
            fprintf(fout,[buffer '\n']);
            outBuffer = ['nReals  	= ' num2str(params.numReals)];
            fprintf(fout,[outBuffer '\n']);  
            % Skip lines
            dummyB = fgetl(fin);
        elseif strcmp(token,'#MATLAB_MOD_IMAGES_DIMENSIONS')
            fprintf(fout,[buffer '\n']);
            outBuffer = ['nX      	= ' num2str(params.dims(1))];
            fprintf(fout,[outBuffer '\n']); 
            outBuffer = ['nY      	= ' num2str(params.dims(2))];
            fprintf(fout,[outBuffer '\n']);  
            % Skip lines
            dummyB = fgetl(fin);
            dummyB = fgetl(fin);
        elseif strcmp(token,'#MATLAB_MOD_IMAGES_PROPS')
            fprintf(fout,[buffer '\n']);
            dummySTR = num2str(params.props(1),'%0.4f');
            outBuffer = ['marginalCDF0 = ' dummySTR];
            fprintf(fout,[outBuffer '\n']); 
            dummyNUM = 1 - str2num(dummySTR);            
            outBuffer = ['marginalCDF1 = ' num2str(dummyNUM,'%0.4f')];
            fprintf(fout,[outBuffer '\n']);  
            % Skip lines
            dummyB = fgetl(fin);
            dummyB = fgetl(fin);
        elseif strcmp(token,'#MATLAB_MOD_OUTFOLDER')
            fprintf(fout,[buffer '\n']);
            outBuffer = ['outFolder    = ''' params.outFolder ''''];
            
            dummyBB = '';
            for idx=1:size(outBuffer,2)
                if strcmp(outBuffer(idx),'\')
                    dummyBB = [dummyBB '/'];
                else
                    dummyBB = [dummyBB outBuffer(idx)];
                end
            end
            fprintf(fout,[dummyBB '\n']);             
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