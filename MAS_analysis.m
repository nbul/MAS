%% Script to measure parameters of mascle attachment sites
% Files should be labelled by consequent numbers starting with 1
% Output file All.csv contains infomation about every individual
% attachment site, whereas Avarage.csv contains avarage values per embryo.
% They will be saved in the same folder as image files

clc;
clear variables;
close all;

%% Defining extension
% Default extension
fileext = '.oib';

usedefault = questdlg(strcat('Use default settings (fileext = ', fileext,'?)'),'Settings','Yes','No','Yes');
if strcmp(usedefault, 'No');
    parameters = inputdlg({'Enter file extension:'},'Parameters',1,{fileext});
    % Redefine extension 
    fileext = parameters{1};
else
    parameters{1} = fileext;
end

%% Open the file
currdir = pwd;
filedir = uigetdir();
files = dir(strcat(filedir,'/*', '.oib'));
cd(filedir);

%% assign memory
data=zeros(1000,3);
data2=zeros(numel(files)+2,3);
datacounter=0;

for k = 1:numel(files)
    
    %% read image
    Number1 = [num2str(k),'.oib'];

    I=bfopen(Number1);

    Series = I{1,1};
    seriesCount = size(Series, 1); %display size to check type of file
    Series_plane1= Series{1,1};
    averageint=0;
    averagesize=0;
    averagetotal=0;
    averageel=0;
    datacounter2=0;
    
    for q=1:seriesCount
        
        Series_plane = Series{q,1};
        %% detect edges of the image
        [junk, threshold] = edge(Series_plane, 'sobel'); %detect edges of i to estimate threshold
        fudgeFactor = 1.1; %rerun edge detector with fudgefactor
        BW = edge(Series_plane,'sobel', threshold * fudgeFactor); %do new edge detection based on fudge factor (can change to alter leeway)
        
        %% dilate the image - take each white section and make bigger
        
        se90 = strel('line', 13, 90); %structuring elements the amount we are averaging over in x direction
        se0 = strel('line', 3, 0); %as above in y direction -make each element a 3x3 box alter size of box as necessary
        BWalldil = imdilate(BW, [se90 se0]);
        BWallfill = imfill(BWalldil, 'holes');
        
        %% smooth out the edges with diamond structural element rather than the square used for the dilation. removes from image anything smaller thandiamond.
        seD = strel('diamond',1);
        BWallclean = imerode(BWalldil,seD); %did erosion once
        BWallclean = imerode(BWallclean,seD);
        BWallclean = imclearborder(BWallclean);
        BWall = bwareaopen(BWallclean, 700);
        %figure, imshow(BWall), title('segmented image');
        
        %% Background value - all except BWall
        
        BG = imcomplement(BWall);
        ccbg = bwconncomp(BG);
        sbg = regionprops(ccbg, Series_plane, 'MeanIntensity');
        
        %% Properties of all objects in
        ccall=bwconncomp(BWall);
        sall=regionprops(ccall, Series_plane, 'Area', 'MeanIntensity', 'Eccentricity', 'Orientation');
        %% selection of correct objects and recording data of each object
        for i=1:numel(sall)
            if sall(i).Eccentricity > 0.97 && sall(i).Area < 4000 && abs(sall(i).Orientation)>45 && (sall(i).MeanIntensity - mean([sbg.MeanIntensity]))>0
                
                datacounter = datacounter + 1;
                data(datacounter,1)=k;
                data(datacounter,2)=sall(i).MeanIntensity - mean([sbg.MeanIntensity]);
                data(datacounter,3)=sall(i).Area;
                data(datacounter,4)=data(datacounter,2)*data(datacounter,3)/1000;
                data(datacounter,5)=sall(i).Eccentricity;
                averageint=averageint + data(datacounter,2);
                averagesize=averagesize + sall(i).Area;
                averagetotal=averagetotal + data(datacounter,4);
                averageel=averageel + sall(i).Eccentricity;
                datacounter2 = datacounter2 + 1;
                
            end
        end
        
    end
    %% Average values
    data2(k, 1) = k;
    data2(k, 2) = averageint/datacounter2;
    data2(k, 3) = averagesize/datacounter2;
    data2(k, 4) = averagetotal/datacounter2;
    data2(k, 5) = averageel/datacounter2;
    data2(k, 6) = datacounter2;
end
%% Total average of the dataset
data2(numel(files) + 2,2) = sum(data2(1:numel(files),2))/numel(files);
data2(numel(files) + 2,3) = sum(data2(1:numel(files),3))/numel(files);
data2(numel(files) + 2,4) = sum(data2(1:numel(files),4))/numel(files);
data2(numel(files) + 2,5) = sum(data2(1:numel(files),5))/numel(files);

%% Writing output files in MATLAB/data folder

headers = {'embryo', 'Intensiry', 'Area', 'Total', 'Eccentricity','Number MAS'};
csvwrite_with_headers('Average.csv',data2, headers);
headers = {'embryo', 'Intensiry', 'Area', 'Total', 'Eccentricity'};
csvwrite_with_headers('All.csv',data, headers);

cd(currdir);
clc;
clear variables;
close all;