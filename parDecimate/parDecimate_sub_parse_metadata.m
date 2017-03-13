%% Reads radar metadata from excel file
function [RadarInfo,valid_indeces]=parDecimate_sub_parse_metadata(File_Name)
% Import data from spreadsheet
% Script for importing data from the following spreadsheet:
%
%    Workbook: D:\Spectrum-Share\NASCTN 3.5 GHz San Diego Release\File_Parameters.xlsx
%    Worksheet: Sheet1
%
% To extend the code for use with different selected data or a different
% spreadsheet, generate a function instead of a script.

% Auto-generated by MATLAB on 2016/11/07 17:09:25
% call
% files_path='D:\Spectrum-Share\NASCTN 3.5 GHz San Diego Release\';
% Radar_info_file='File_Parameters.xlsx';
% RadarInfo=read_xsl_info_f([files_path,Radar_info_file]);

% Modified by Raied Caromi & John Mink
% Version: 1.0
% Date: 24 Feb 2017
%% Import the data

[~, ~, raw] = xlsread(File_Name,'Sheet1','','basic');
raw = raw(2:end,:);
raw(cellfun(@(x) ~isempty(x) && isnumeric(x) && isnan(x),raw)) = {''};
cellVectors = raw(:,[1,2,3,6]);
raw = raw(:,[4,5]);

%% Replace non-numeric cells with NaN
R = cellfun(@(x) ~isnumeric(x) && ~islogical(x),raw); % Find non-numeric cells
raw(R) = {NaN}; % Replace non-numeric cells

%% Create output variable
data = reshape([raw{:}],size(raw));

%% Allocate imported array to column variable names
RadarInfo_full.Filename = cellVectors(:,1);
RadarInfo_full.Antenna = cellVectors(:,2);
RadarInfo_full.Comments = cellVectors(:,3);
RadarInfo_full.RFcenterfrequencyHz = data(:,1);
RadarInfo_full.ADCscalefactorFADC = data(:,2);
%RadarInfo.SHA1Hash = cellVectors(:,4);

%% This is a hack, it SHOULD be part of the initial "read-in conditional"
%Reassign VALID metadata to new variable
valid_indeces=find(strcmp(RadarInfo_full.Filename,'')==0); %valid if NOT empty

RadarInfo.Filename=RadarInfo_full.Filename(valid_indeces);
RadarInfo.Antenna=RadarInfo_full.Antenna(valid_indeces);
RadarInfo.Comments=RadarInfo_full.Comments(valid_indeces);
RadarInfo.RFcenterfrequencyHz=RadarInfo_full.RFcenterfrequencyHz(valid_indeces);
RadarInfo.ADCscalefactorFADC=RadarInfo_full.ADCscalefactorFADC(valid_indeces);


%% Clear temporary variables
clearvars data raw cellVectors R RadarInfo_full;
end