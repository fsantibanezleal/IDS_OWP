function CleanGslib(filename,outFile)
    %  Open file for input
    fin  = fopen(filename,'r');
    % Create/Open  file for output
    fout = fopen(outFile,'wt');

    %  Write the header: the 4 lines of header text
    for i=1:5,
        buffer = fgetl(fin);  
        fprintf(fout,[buffer '\n']);
    end

    while true
        buffer = fgetl(fin);
        % get first word in line and remainder of line    
        [pX,remain] = strtok(buffer);        
        [pY,pI]     = strtok(remain);        
        pI_N        = str2num(pI);
        if pI_N == 0 | pI_N == 1
            fprintf(fout,[pX '     ' pY ' ' pI '\n']);
        end
        
        if size(buffer,2) < 2
            break; 
        end           
    end

    fclose('all');
end