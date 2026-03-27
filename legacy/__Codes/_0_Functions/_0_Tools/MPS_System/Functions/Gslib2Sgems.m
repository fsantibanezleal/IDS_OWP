% eas2sgems : convert eas ASCII file to SGEMS binary point set
%
% EAS can be treated either as POINT files or GRID files.
%
% EAS Point-set files
% The data section starts with 'ndim' columns defining 
% the location in ndim-space, followed by N columns of DATA.
% Call :
%   O=eas2sgems(file_eas,file_sgems,ndim);
%
% Examples:
%
% -- 3d eas files with two data sets (5 cols, 3dims)
%  ndim=3
%  eas2sgems('file.eas','file.sgems',ndim)
%
% -- 2d eas files with two data sets (5 cols, 2dims)
%  ndim=2
%  eas2sgems('file.eas','file.sgems',ndim)
%
%

function O=Gslib2Sgems(file_eas,file_sgems,ndim)

[p,f,e]=fileparts(file_eas);
if isempty(p); p=pwd;end
file_sgems_ex=[p,filesep,f,'.sgems'];

if nargin<2, file_sgems=file_sgems_ex;end
if isempty(file_sgems), file_sgems=file_sgems_ex;end

Dset='point';
    
[data,header,title]=read_eas(file_eas);

if strcmp(Dset,'point');
    % POINT SET
    ncols=size(data,2);
    O.n_data=size(data,1);
    O.n_prop=ncols-ndim;
    O.xyz=zeros(O.n_data,ndim);

    for idim=1:ndim
        O.xyz(:,idim)=data(:,idim);
    end

    O.property_name=header((ndim+1):ncols);
    O.data=data(:,(idim+1):size(data,2));

    O.point_set=title;
end

O=sgemsOWP_write(file_sgems,O);


