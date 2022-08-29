function im = openBCR_BCRF(varargin)
%%OPEN BCR or BCRF file type from SPIP
% works for ACSII type file headers
% varargin = filename or empty
%   if empty script will prompt user to choose file 
%
%----------Change Log--------------
%   8/27/21 - Written by Kristen N. Johnson, Washington State University
%   12/30/21 - Added functionality for bcrstm_unicode file format
%
%%
%%%load in file
props = {};
if nargin == 0
    [file,path] = uigetfile({'*.bcr;*.bcrf'});
    filename = fullfile(path,file);
elseif nargin == 1
     filename = varargin{1};
else
    errordlg(['Error: Incorrect input']);
    return
end

% check file name
fid=fopen(filename, 'r');
if fid < 0
    errordlg(['Cannot open "' filename ],...
        'File');
    return
end

% check file format 
line1 = fgetl(fid);
[~, param] = parseLine(line1, 13);
frewind(fid);

% set parameters based on file format
switch param
    case 'bcrstm'
        data_start = 2048;
        data = 'int16';
        vp = 32700;
    case 'bcrf'
        data_start = 2048;
        data = 'float32';
        vp = 3e+38;
    case 'bcrstm_unicode'
        data_start = 4096;
        data = 'int16';
        vp = 32700;
    otherwise
        errordlg(['Cannot open "' filename ],...
        'File');
        return
end

% get params from file
while ftell(fid)<data_start
    linha = fgetl(fid);
    [tag,param] = parseLine(linha, 8);

    switch tag   
        case 'xpixels'
            [~,param] = parseLine(linha, 10);
            props{end+1} = 'pixels_x';
            props{end+1} = str2num(param);            

        case 'ypixels'
            [~,param] = parseLine(linha, 10);
            props{end+1} = 'pixels_y';
            props{end+1} = str2num(param);

        case 'bit2nm ='
            props{end+1} = 'bit2nm';
            props{end+1} = str2num(param);
    end       
end

scan_x = getprop(props, 'pixels_x');
scan_y = getprop(props, 'pixels_y');
conv = getprop(props, 'bit2nm');
im = zeros(scan_y, scan_x);

fseek(fid,data_start,'bof');

for i=1:scan_y
    for j=1:scan_x
        im(i,j)=fread(fid,1,data);
    end
end

im = im*conv;
im(im>=vp)=min(im(:));
        
%%
function [value, param] = parseLine(line1,nc)
    numofchars = nc;
    value = strtrim(line1(1:min(numofchars, length(line1))));
    param = strtrim(line1(numofchars+1:end));

end

function value = getprop(props, prop)
    value = [];
    for i = 1:2:length(props)
        if strcmp(props{i}, prop)
            value = props{i+1};
        end
    end
end

end