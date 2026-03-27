%% Make Folders

mkdir(['..' filesep '..' filesep stFolders.DB stFolders.FolderNAME]);
mkdir(['..' filesep '..' filesep stFolders.OutCome stFolders.FolderNAME]);
mkdir(['..' filesep '..' filesep stFolders.Analysis stFolders.FolderNAME]);

%% Save models in DB folder
stDummy = who('model_*');
for idxM = 1:numel(stDummy)
    %eval(['dummyModel = ' stDummy{idxM} ';']);
    save(['..' filesep '..' filesep stFolders.DB stFolders.FolderNAME ...
          stDummy{idxM} '.mat'], '-struct', stDummy{idxM}, '-v7.3');
end

%% Save StFolder variable in DB Folder
save(['..' filesep '..' filesep stFolders.DB stFolders.FolderNAME...
      'stFolders' '.mat'], 'stFolders','-v7.3');

clear stDummy idx*