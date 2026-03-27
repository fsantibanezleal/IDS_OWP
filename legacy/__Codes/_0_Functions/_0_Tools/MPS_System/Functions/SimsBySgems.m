function SimsBySgems(TI,HD,stPaths,scriptParams,bSaveImages,bSaveMAT)
%% Script for MP simulation 
% Simplified version 
% Felipe Andrés Santibáñez Leal, 2016
% fsantibanezleal@ug.uchile.cl

%% Check and transform data
TI = TI  - min(TI(:));
TI = TI ./ max(TI(:));

vecHD_U = unique(HD(~isnan(HD(:))));
if numel(vecHD_U) > 1    
    HD = HD  - min(HD(:));
    HD = HD ./ max(HD(:));
elseif numel(vecHD_U) > 0
    if vecHD_U ~= 0
        HD(HD == vecHD_U) = 1;
    end
end
    
dimTI = size(TI);


%% Save data in GSLib format
% training image
TI2GSLib([stPaths.ExpFolder stPaths.internalFolder filesep 'TI.gslib'],TI);
% sampled image
PointSet2CleanGSLIB([stPaths.ExpFolder stPaths.internalFolder filesep 'HD.gslib'],HD);

% Save as Sgems
eas2sgems([stPaths.ExpFolder stPaths.internalFolder filesep 'HD.gslib'],...
          [stPaths.ExpFolder stPaths.internalFolder filesep 'HD.sgems'],2);   

eas2sgems([stPaths.ExpFolder stPaths.internalFolder filesep 'TI.gslib'],...
          [stPaths.ExpFolder stPaths.internalFolder filesep 'TI.sgems'],...
          dimTI(1),dimTI(2),1,1,1,1,0,0,0,...
          'TI');    


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
stPaths.SgemsExe      = [fullfile(stPaths.SgemsExe) filesep];
stPaths.Script        = [stPaths.ExpFolder stPaths.internalFolder filesep 'script_Sgems.py'];
stPaths.fileDummyName = [stPaths.ExpFolder stPaths.internalFolder filesep 'dummy.py'];


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Provide Training Image for all sims
copyfile([stPaths.ExpFolder stPaths.internalFolder filesep 'TI.sgems'],...
            [stPaths.SgemsExe 'TI.sgems']);
copyfile([stPaths.ExpFolder stPaths.internalFolder filesep 'HD.sgems'],...
            [stPaths.SgemsExe 'HD.sgems']); 
     
     
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Providing params 
% Dir Sgems and name data
scriptParams.sgemsDir   = stPaths.SgemsExe;
scriptParams.nameDataTI = 'TI';
scriptParams.nameDataHD = 'harddata';
% Load TI data and update .Py script

% Dimensions
scriptParams.dims      = size(TI);
% Statistics from TI: Proportions zeros and ones.
myH = hist(TI(:),2);
scriptParams.props     = myH./sum(myH);
mkdir(scriptParams.outFolder);
scriptParams.outFolder = [fullfile(scriptParams.outFolder) filesep];

update_PY_Script(stPaths.Script,stPaths.fileDummyName,scriptParams);

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Running Sgems simulations
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Go to Sgems path
update_PY_Script_OUTNAME(stPaths.Script,scriptParams.fileSimName,...
                         stPaths.fileDummyName);
copyfile(stPaths.Script,...
         [stPaths.SgemsExe 'scriptSIM.py']);            

stPaths.Code = cd(stPaths.SgemsExe);     
eval(['!' 'Sgems-x64.exe' ' -s ' ...
     'scriptSIM.py']);           

cd(stPaths.Code);
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Convert data from SGEMS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%% Save as PNG images
if bSaveImages,
    stPaths.folderIM = [scriptParams.outFolder 'Images' filesep];
    mkdir(stPaths.folderIM);
    Sims2PNG([scriptParams.outFolder...
                 scriptParams.fileSimName '.gslib'],...
                 stPaths.folderIM,scriptParams.numReals,dimTI);
end

%%%%%% Save simulations as a .mat
if bSaveMAT
    Sims2MAT([scriptParams.outFolder scriptParams.fileSimName '.gslib'],...
              scriptParams.outFolder,scriptParams.numReals,dimTI);
    delete([scriptParams.outFolder scriptParams.fileSimName '.gslib']);
end