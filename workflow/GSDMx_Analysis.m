%% GSDMx AFM Image Analysis

%% Preface
%{
Copyright: Matthew Leipner

Original date:  07.03.2019

Update Notes:   28.03.2019
  - notification of pore detection failure

Update Notes:   04.04.2019
  - parallel processing

Update Notes:   05.04.2019
  - New Report/Publishing

Update Notes:   10.04.2019
  - Switch cases to better automate different images sizes

Update Notes:   11.04.2019
  - Stop rescaling "detected pores" image to prevent all-black image
  - Stop scaling axes on raw AFM image (3D) to prevent no-show

Update Notes:   17.04.2019
  - Add in pore type list based on manual input from csv file

Update Notes:   22.04.2020
  - Make more robust to varing image sizes by integrating a scaling
  factor

Update Notes:   04.06.2020
  - Add boolean flag for whether to use poreTypes csv or not (for first
  round + labeling)

Update Notes:   25.09.2020
  - Changed smoothingparam from 0.01 to 0.05 near line 370

Update Notes:   12.10.2020
  - Added option for specifying output directory
  - Changed minPH from 2 to 1.2

Update Notes:   01.03.2021
  - Added OpenNano6 Integration to directly read AFM data without external
  pre-processing

Update Notes:   28.04.2021
  - Begin coding classifier for automatic classification of ologimer types
  into "Arc," "Slit," or "Ring" catgories

Acknowledgements to

CODE:

* Curve Intersection Code (InterX), by NS
        https://nl.mathworks.com/matlabcentral/fileexchange/22441-curve-intersections
* Aaron Ponti, Matlab image processing guide
* Open Nanoscope 6 AFM Images
        https://www.mathworks.com/matlabcentral/fileexchange/11515-open-nanoscope-6-afm-images


DATA ACQUISITION and EXPERIMENTAL DESIGN:

* Stefania Mari
* Daniel Muller
* Andreas Engel
%}

%% Setup

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SET THE FOLLOWING PARAMTERS       %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%     Frequently Edited        %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% MODE Selection: can choose between full analysis (every oligomer with
% height/depth/diameter details and so on) vs. only surface coverage
% analysis. Simply switch which line is commented to switch between them.

%mode = "FullAnalysis";
mode = "SurfaceCoverage";

% Circularity Filter (will remove anything with circularity less than
% this)
minCirc = 0.3;  % (default 0.3) Ratio of minor axis to major axis

% Hight Filter (removed anything with height over this amount)
maxHeight = 4;  % [nm]

% Max length of major axis (to help filter out grouped oligos/membrane
% defects)
majorAxisFilter = 137;  % [nm] Max allowable major axis length

% Set size limits for object filtering
lgSizeFilter = 10000;     % [nm2] (default: 2200 for 700nm, 9400 for 3000nm) Max area of an individual object
smSizeFilter = 350;       % [nm2] (default: 374 for 700nm, 760 for 3000nm) Min area of an individual object, anything below this is discarded

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Less Frequently Edited     %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% SET INPUT DIRECTORY
inputDir = '/Users/matt/Google_Drive/ETH_Zurich/MullerLab/MSc_Thesis/training_data/GSDMD/Control';

% SET INPUT poreTypes CSV and flag whether or not to use (leave as FALSE if pores have not yet been classified)
usePoreTypes = false;
choosePoreTypes = false;

% SET OUTPUT DIRECTORY
outDirPrepend = './../analysis';

% Choose background flattening model (old/new)
new_flat = true;

% Remove pore coverage
%if exist('./../surfCoverage_New.txt', 'file')==2
%  delete('./../surfCoverage_New.txt');
%end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    DO NOT EDIT BELOW THIS LINE    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Add path to supporting matlab files
addpath(genpath('./../resources/MATLAB_helper_scripts'));

% Get list of all raw AFM files to analyze this run (.spm suffix)
files = dir([inputDir,'/*.0*']);

% Get poreTypesCSV from same folder if present
poreTypesCSV = dir([inputDir,'/*.csv']);
poreTypesCSV = [poreTypesCSV.folder,'/',poreTypesCSV.name];

% Open pore type list
if usePoreTypes
    PT = dlmread(poreTypesCSV,',',1,3);
    fid = fopen(poreTypesCSV);
    PT_filenames = strsplit(fgetl(fid), ',');
    PT_filenames(:,1:2) = [];
    fclose(fid);
    
    outDir = fullfile(outDirPrepend,strjoin([string(datetime('now','Format','yyyyMMdd')),'_labeled'],''));
else
    PT_filenames = [''];
    PT = [];
    outDir = fullfile(outDirPrepend,strjoin([string(datetime('now','Format','yyyyMMdd')),'_pre_labeling'],''));
end
[~,~,~] = mkdir("./../analysis");
%[~,~,~] = mkdir(outDir);

% Initialize coverage file
warning('off')
delete(fullfile(outDirPrepend,'surfCoverage.csv'));
fid = fopen(fullfile(outDirPrepend,'surfCoverage.csv'), 'a') ;
headerString = 'Image,Group,NumIsolatedObjects_7,IsolatedObjCoverage_7,NumDefects_8,DefectCoverage_8,lowCoverage_9,highCoverage_10,totalCoverage_11';
fprintf(fid,'%s\n',headerString);
fclose(fid);

% Get current dir, to switch back to at end of script
oldDir = pwd;

% Create output directories
[~,~,~] = mkdir([outDirPrepend '/flattened_images']);
[~,~,~] = mkdir([outDirPrepend '/report_images']);
[~,~,~] = mkdir([outDirPrepend '/reports']);

switch mode
    case "FullAnalysis"
        [~,~,~] = mkdir([outDirPrepend '/oligomer_profiles']);
        [~,~,~] = mkdir([outDirPrepend '/summary_txt']);
end

%% Start Parallel Pool
gcp;

%% Run below code for each image
tic
for cImage = 1%:length(files)
    
    %% Raw AFM Image
    
    % Change output directory structure 2021.05.05, placed outside loop above
    %{
    % Create new directory for script outputs and change to that directory
         directory = strjoin([outDir,'/',files(cImage).name,'_REPORT'],'');
         [~] = rmdir(directory,'s');
         mkdir(directory);
         cd(directory)
    %}
    % Add folders for output images
    mkdir([outDirPrepend,'/report_images/',files(cImage).name]);
    
    
    % Clear parallel pool memory after previous iteration for later use
    parfevalOnAll(@clearvars, 0);
    
    minPH = 1.2;        % Min peak height [nm]
    minPD = 5;          % Min peak distance [nm]
    
    avgMWW = 9.5;        % Set average midwall width [nm]
    devMWW = 3.3;         % Set max deviation from avg midwall width [nm]
    
    %M = dlmread([files(cImage).folder,'/',files(cImage).name],'\t',6,0);
    [AFM_images, channelInfo] = openNano6([files(cImage).folder,'/',files(cImage).name]);
    
    M = AFM_images(:,:,1);
    
    [samplePoints, ~] = size(M);             % number of samples/line
    imSize = channelInfo(1).Width;      % scan size [nm]
    
    scaleFactor = ceil(25*sqrt(700^2/imSize^2));       % radius number of pixels to isolate single pore
    
    % Size filter conversion from [nm2] to [pixels]
    lgObj = lgSizeFilter*samplePoints^2/imSize^2*sqrt(700^2/imSize^2)*sqrt(samplePoints^2/512^2);       % [pixels] Largest pore size for filtering % Changed from 1200 20201116
    smObj = smSizeFilter*samplePoints^2/imSize^2*sqrt(700^2/imSize^2)*sqrt(samplePoints^2/512^2);       % [pixels] Smallest pore size for filtering, used for all control
    
    % Major axis conversion from nm to pixels
    maxAxisLength = majorAxisFilter*samplePoints/imSize;    % [pixels] Max length of major axis
    
    x = zeros(samplePoints) + linspace(0,imSize,samplePoints);
    y = rot90(zeros(samplePoints) + linspace(0,imSize,samplePoints));
    z = M;
    
    figure; set(gcf,'Position',[1 1 1000 1000]);
    surf(x,y,z-min(min(z)),'LineStyle','none'); %zlim([-2,20]);
    %caxis([-2,4]);
    xlabel('X [nm]','FontSize',18);
    ylabel('Y [nm]','FontSize',18);
    zlabel('Height [nm]','FontSize',18);
    %title('Raw AFM Image');
    exportgraphics(gcf,fullfile([outDirPrepend,'/report_images/',files(cImage).name,'/',files(cImage).name,'_1_raw.png']));
    
    
    %% Background Removal
    
    delete(gca); close all;
    
    % 1st Round of pore detection/masking
    if new_flat
        background = imopen(z, strel('cube', 20));
    else
        background = imopen(z, strel('line', 100,0));
    end
    z2 = z - background;
    % Blur image to help with binarization
    z3 = imfilter(z2, fspecial('average',3), 'symmetric');
    % Binarize image
    z4 = imbinarize(z3,'adaptive','Sensitivity',0.1);
    % Fill in holes to get complete pore
    z5 = imfill(z4,'holes');
    % Dilate image a bit to ensure complete pore coverage
    z6 = imdilate(z5,strel('line',11,0));
    
    %% Flattened AFM Image
    % 2nd Round of flattening and processing
    
    % Mask out pores and calculate mean height of each row
    im = z;
    im(z6) = nan;
    rowMeans = mean(im,2,'omitnan');
    
    % 20201116 Check if any full rows are NaN after dilation
    % If so, try average prior to binarized image dilation
    rowMeans_nan = isnan(rowMeans);
    if any(rowMeans_nan)
        im3 = z;
        im3(z4) = nan;
        rowMeans_z4 = mean(im3,2,'omitnan');
        
        for i = find(rowMeans_nan)
            rowMeans(i) = rowMeans_z4(i);
        end
        
        % 20210510 Lastly, check if all elements of row are nan even before dilation, in which case replace
        % with average of nearest non-nan mean rows on either side
        if any(isnan(rowMeans))
            rowMeans = fillmissing(rowMeans,'movmean',3);
        end
    end
    
    % Fill pore holes with mean row height
    for i = 1:length(rowMeans)
        im(i,z6(i,:)) = rowMeans(i);
    end
    
    % Find background from
    background2 = imopen(im, strel('line', 100,0));
    
    im2 = z-background2;
    
    % Adjust membrane to center around 0, instead of bottom out at 0
    im3 = im2;
    im3(z6) = nan;
    rowMeans2 = mean(im3,2,'omitnan');
    
    % ADDED 20210510: account for full-NA rows due to full line of detected
    % object(s)
    rowMeans2 = fillmissing(rowMeans2,'movmean',10);
    im4 = bsxfun(@minus, im2, rowMeans2);
    
    
    figure; set(gcf,'Position',[1 1 1000 1000]);
    surf(x,y,im4,'LineStyle','none'); zlim([-2,20]);
    caxis([-2,4]);
    xlabel('X [nm]','FontSize',18);
    ylabel('Y [nm]','FontSize',18);
    zlabel('Height [nm]','FontSize',18);
    savefig([outDirPrepend,'/flattened_images/',files(cImage).name,'.fig']);
    %title('Flattened AFM Image');
    exportgraphics(gcf,fullfile([outDirPrepend,'/report_images/',files(cImage).name,'/',files(cImage).name,'_2_flat.png']));
    
    
    % Watershedding
    % Use z5 for watershedding as there is better segregation (vs. z6)
    D = -bwdist(~z5);
    mask = imextendedmin(D,2);
    D2 = imimposemin(D,mask);
    Ld = watershed(D2);
    z7 = z5;
    z7(Ld == 0) = 0;
    
    % Watershedding non-filled pores
    z9 = z4;
    z9(Ld == 0) = 0;
    
    %% Isolate Pore Image
    
    delete(gca); close all;
    
    cc = bwconncomp(z7, 4);
    objSizes = cellfun('length',cc.PixelIdxList);
    singlePores = objSizes < lgObj & objSizes > smObj;
    membraneDefects = objSizes > lgObj;
    
    % Show only objects/pores detected as within the desired size range
    z8 = false(size(z7));
    z20 = false(size(z7));
    for i = find(singlePores)
        if max(im4(cc.PixelIdxList{i})) <= maxHeight
            z8(cc.PixelIdxList{i}) = true;
        else
            z20(cc.PixelIdxList{i}) = true;
        end
    end
    
    % Added 2021.02.28: Generate image of only membrane defects above size cutoff range
    for i = find(membraneDefects)
        z20(cc.PixelIdxList{i}) = true;
    end
    
    imwrite(z20,fullfile([outDirPrepend,'/report_images/',files(cImage).name,'/',files(cImage).name,'_8_membraneDefects.png']),'png');
    
    % Added 2020.11.17: size select non-filled objects
    cc_nofill = bwconncomp(z9, 4);
    cc_nofill_sizes = cellfun('length',cc_nofill.PixelIdxList);
    cc_nofill_single = cc_nofill_sizes < lgObj & cc_nofill_sizes > smObj;
    
    z11 = false(size(z7));
    for i = find(cc_nofill_single)
        z11(cc_nofill.PixelIdxList{i}) = true;
    end
    
    % Save image showing all pores (2D projection)
    figure; imshow(im4); colormap copper;
    exportgraphics(gcf,fullfile([outDirPrepend, '/report_images/',files(cImage).name,'/',files(cImage).name,'_3_all.png']));
    
    %imwrite(im4,'copper',fullfile([outDirPrepend, '/report_images/',files(cImage).name,'/',files(cImage).name,'__3_all.png']),'png');
    
    % copy im4 but remove non-single pore features for better pore isolation
    im5 = im4;
    %im5(z6 ~= z8) = 0;
    im5(z5 ~= z8) = 0;  % 07.10.2020 change to z5 to remove banding around isolated objects
    
    figure; imshow(im5); colormap copper;
    exportgraphics(gcf,fullfile([outDirPrepend, '/report_images/',files(cImage).name,'/',files(cImage).name,'_4_isolated.png']));
    
    %imwrite(im5,'copper',fullfile([outDirPrepend, '/report_images/',files(cImage).name,'/',files(cImage).name,'_/',files(cImage).name,'_4_isolated.png']),'png');
    
    %% Binarized, Watershedded Image
    
    delete(gca); close all;
    
    imwrite(z8,fullfile([outDirPrepend, '/report_images/',files(cImage).name,'/',files(cImage).name,'_5_watershedded.png']),'png');
    
    %% Characterize Objects
    
    delete(gca); close all;
    
    % Generate new indices after watershedding and size-filtering
    cc2 = bwconncomp(z8, 4);
    % Get center coordinates of pores of interest
    S = struct2cell(regionprops(cc2,'Centroid'));
    % Round center coordinates to nearest pixel
    S2 = cellfun(@round,S,'UniformOutput', false);
    
    % ADDED 2020.11.17: Get major and minor Axis Lengths
    %cc_nofill2 = bwconncomp(z11, 4);
    stats = regionprops(z8,'Centroid','MajorAxisLength','MinorAxisLength','Circularity','Orientation','Perimeter');
    
    % ADDED 2021.02.09: Filter out skinny, long defects along horizontal axis in pore isolation
    % Show only objects/pores detected as within the desired size range
    z12 = false(size(z8));
    for i = find([stats.Circularity] > minCirc & (round([stats.MajorAxisLength]'.*100.*imSize./samplePoints)./100 < maxAxisLength)')
        z12(cc2.PixelIdxList{i}) = true;
    end
    
    imwrite(z12,fullfile([outDirPrepend, '/report_images/',files(cImage).name,'/',files(cImage).name,'_7_poreCoverage.png']),'png');
    
    %% Pore classification  by saved excel table or user input
    switch mode
        case "FullAnalysis"
            
            if usePoreTypes % Saved in csv file
                PT_index = find(strcmp(PT_filenames,files(cImage).name)); % After 1st run, can list specific auto-detected pores to ignore (Make sure to put in increasing order)
                ignoredPores = find(PT(:,PT_index) == 1);
                poreTypes = PT(:,PT_index);
                poreTypes(ignoredPores) = [];
            elseif choosePoreTypes
                oligoTypes = zeros(length(S2),1);
                for i = 1:length(S2)
                    % Show oligo under consideration
                    figure;
                    imshow(rescale(im5(max(S2{i}(2)-scaleFactor,1):min(S2{i}(2)+scaleFactor,samplePoints),...
                        max(S2{i}(1)-scaleFactor,1):min(S2{i}(1)+scaleFactor,samplePoints)),0,250),copper)
                    set(gcf,'Position',[1 1 500 500]);
                    
                    % Take input and save in oligoTypes array
                    prompt = 'What is the oligomer type? (1-ignore, 2-ring, 3-slit, 4-arc)';
                    oligoTypes(i) = input(prompt);
                    
                    % Close open image
                    delete(gca); close all;
                end
                poreTypes = oligoTypes;
                ignoredPores = find(poreTypes == 1);
                poreTypes(ignoredPores) = [];
            else
                poreTypes = zeros(length(S2),1) + 2;
                ignoredPores = [];
            end
            
            poreTypes(poreTypes == 0) = [];
            
            
            %% Remove ignored objects
            % Get rid of ignored pores (starts at end to prevent frame shift deletions
            OGLabel = 1:length(S2);
            for i = flip(ignoredPores)
                S2(i) = [];
                cc2.PixelIdxList(i) = [];
                stats(i) = [];
                OGLabel(i) = [];
            end
            
            %% Perimeter and Axis Labeled Image
            % Added 2020.11.17
            
            figure; imshow(im4); colormap copper; %Use for colored image
            %figure; imshow(z8)
            hold on
            
            phi = linspace(0,2*pi,50);
            cosphi = cos(phi);
            sinphi = sin(phi);
            
            for k = 1:length(stats)
                % Ellipse
                xbar = stats(k).Centroid(1);
                ybar = stats(k).Centroid(2);
                
                a = stats(k).MajorAxisLength/2;
                b = stats(k).MinorAxisLength/2;
                
                theta = pi*stats(k).Orientation/180;
                R = [ cos(theta)   sin(theta)
                    -sin(theta)   cos(theta)];
                
                xy = [a*cosphi; b*sinphi];
                xy = R*xy;
                
                xPerim = xy(1,:) + xbar;
                yPerim = xy(2,:) + ybar;
                
                % Major Axis
                xMajor = xbar  +  [ -1 +1 ] * a*cos(pi-theta);
                yMajor = ybar  +  [ -1 +1 ] * a*sin(pi-theta);
                
                % Minor Axis
                xMinor = xbar  +  [ -1 +1 ] * b*sin(theta);
                yMinor = ybar  +  [ -1 +1 ] * b*cos(theta);
                
                % Plotting
                plot(xPerim,yPerim,'r','LineWidth',2);
                line(xMajor,yMajor,'Color','b','LineWidth',2);
                line(xMinor,yMinor,'Color','c','LineWidth',2);
            end
            
            exportgraphics(gcf,fullfile([outDirPrepend, '/report_images/',files(cImage).name,'/',files(cImage).name,'_6_axis.png']));
            hold off
            
    end
    %% Overlapping oligomer (height mask)
    highStuff = im4 >= maxHeight;
    imwrite(highStuff,fullfile([outDirPrepend, '/report_images/',files(cImage).name,'/',files(cImage).name,'_10_highStuff.png']),'png');
    
    allStuff = z12 + z20;
    imwrite(allStuff,fullfile([outDirPrepend, '/report_images/',files(cImage).name,'/',files(cImage).name,'_11_allStuff.png']),'png');
    
    lowStuff = allStuff - highStuff;
    imwrite(lowStuff,fullfile([outDirPrepend, '/report_images/',files(cImage).name,'/',files(cImage).name,'_9_lowStuff.png']),'png');
    
    %% Labeled Image
    
    switch mode
        case "FullAnalysis"
            
            % Create new image to be labeled in below loop
            im6 = im4;
            % Pre-allocate structure memory for individual, isolated pores
            pores = struct;
            pores.X = cell(1,length(S2));
            pores.Y = cell(1,length(S2));
            pores.Z = cell(1,length(S2));
            pores.CS = cell(4,length(S2));
            pores.maxDepth = zeros(1,length(S2));
            pores.maxHeight = zeros(1,length(S2));
            
            % 20200603 Pre-allocate structure memory for non-isolated pores,
            % for publication
            pubPores = struct;
            pubPores.CS = cell(4,length(S2));
            
            % Generate 101x101 pixel boxes centered around pore center coordinates
            % ADDED 2020.11.16: Additionally searches to global min inside each
            % oligomer based on z10 area -> stored in pores.maxDepth
            for i = 1:length(S2)
                
                % Isolate pore by setting all other pores temporarily to 0
                z10 = false(size(z8));
                z10(cc2.PixelIdxList{i}) = true;
                
                im7 = im5;
                im7(z8 ~= z10) = 0;
                
                % Plot matrices
                pores.X{i} = x(max(S2{i}(2)-scaleFactor,1):min(S2{i}(2)+scaleFactor,samplePoints),...
                    max(S2{i}(1)-scaleFactor,1):min(S2{i}(1)+scaleFactor,samplePoints));
                pores.Y{i} = y(max(S2{i}(2)-scaleFactor,1):min(S2{i}(2)+scaleFactor,samplePoints),...
                    max(S2{i}(1)-scaleFactor,1):min(S2{i}(1)+scaleFactor,samplePoints));
                pores.Z{i} = im7(max(S2{i}(2)-scaleFactor,1):min(S2{i}(2)+scaleFactor,samplePoints),...
                    max(S2{i}(1)-scaleFactor,1):min(S2{i}(1)+scaleFactor,samplePoints));
                
                % Cross sections (by row:
                %   x-values,
                %   cross section 1,
                %   cross section 2,
                %   cross section 3,
                %   mean of 3 cross-sections)
                pores.CS{1,i} = x(S2{i}(2),max(S2{i}(1)-scaleFactor,1):min(S2{i}(1)+scaleFactor,samplePoints));
                pores.CS{2,i} = im7(S2{i}(2)-1,max(S2{i}(1)-scaleFactor,1):min(S2{i}(1)+scaleFactor,samplePoints));
                pores.CS{3,i} = im7(S2{i}(2),max(S2{i}(1)-scaleFactor,1):min(S2{i}(1)+scaleFactor,samplePoints));
                pores.CS{4,i} = im7(S2{i}(2)+1,max(S2{i}(1)-scaleFactor,1):min(S2{i}(1)+scaleFactor,samplePoints));
                pores.CS{5,i} = (pores.CS{2,i}+pores.CS{3,i}+pores.CS{4,i})./3;
                
                % 20201116 Save max depth within detected oligomer
                pores.maxDepth(i) = min(im7(z10));
                pores.maxHeight(i) = max(im7(z10));
                
                % 20200603 save data to pubPores for later figure generation in R
                pubPores.CS{1,i} = pores.CS{1,i};
                pubPores.CS{2,i} = im4(S2{i}(2)-1,max(S2{i}(1)-scaleFactor,1):min(S2{i}(1)+scaleFactor,samplePoints));
                pubPores.CS{3,i} = im4(S2{i}(2),max(S2{i}(1)-scaleFactor,1):min(S2{i}(1)+scaleFactor,samplePoints));
                pubPores.CS{4,i} = im4(S2{i}(2)+1,max(S2{i}(1)-scaleFactor,1):min(S2{i}(1)+scaleFactor,samplePoints));
                pubPores.CS{5,i} = (pubPores.CS{2,i}+pubPores.CS{3,i}+pubPores.CS{4,i})./3;
                
                % Add pore label to image
                im6 = insertText(im6,[S2{i}(1)+15,S2{i}(2)-15],i,...
                    'FontSize',8,'Font','LucidaSansDemiBold',...
                    'BoxOpacity',0.8,'TextColor','black');
            end
            
            pubPores.X = pores.X;
            
            imwrite(im6,fullfile([outDirPrepend, '/report_images/',files(cImage).name,'/',files(cImage).name,'_12_labeled.png']),'png');
            
            %% 3D Pore Plots
            delete(gca); close all;
            
            % [3D SURF] Save individual pore surface plots
            parfor i = 1:length(S2)
                figure;
                surf(pores.X{i},pores.Y{i},pores.Z{i},'LineStyle','none');
                xlabel('X [nm]','FontSize',10);
                ylabel('Y [nm]','FontSize',10);
                zlabel('Height [nm]','FontSize',10);
                %title(sprintf('Pore %i',i));
                caxis([-2,4]);
                zlim([-2,8]);
                exportgraphics(gcf,fullfile([outDirPrepend, '/report_images/' files(cImage).name '/' files(cImage).name '_' num2str(i+12) '_3D.png']));
            end
            %% 2D Pore Plots
            
            delete(gca); close all;
            
            % CHANGE 05.04.2019: revert to individual plots to use with report
            % generator. Replaces "Get at most 32 pores per subplot (4x8)"
            parfor i = 1:length(S2)
                % [2D Depth] Plotting pores individually;
                imwrite(rescale(pores.Z{i},0,250),copper,fullfile([outDirPrepend '/report_images/' files(cImage).name '/' files(cImage).name '_' num2str(i+12+length(S2)) '_2D.png']),'png');
                
                figure; imshow(pores.Z{i}); hold on
                % Ellipse
                xbar = min([stats(i).Centroid(1),scaleFactor+1]);
                ybar = min([stats(i).Centroid(2),scaleFactor+1]);
                
                a = stats(i).MajorAxisLength/2;
                b = stats(i).MinorAxisLength/2;
                
                theta = pi*stats(i).Orientation/180;
                R = [ cos(theta)   sin(theta)
                    -sin(theta)   cos(theta)];
                
                xy = [a*cosphi; b*sinphi];
                xy = R*xy;
                
                xPerim = xy(1,:) + xbar;
                yPerim = xy(2,:) + ybar;
                
                % Major Axis
                xMajor = xbar  +  [ -1 +1 ] * a*cos(pi-theta);
                yMajor = ybar  +  [ -1 +1 ] * a*sin(pi-theta);
                
                % Minor Axis
                xMinor = xbar  +  [ -1 +1 ] * b*sin(theta);
                yMinor = ybar  +  [ -1 +1 ] * b*cos(theta);
                
                % Plotting
                plot(xPerim,yPerim,'r','LineWidth',2);
                line(xMajor,yMajor,'Color','b','LineWidth',2);
                line(xMinor,yMinor,'Color','c','LineWidth',2);
                yline(ybar,'g--','LineWidth',2);
                exportgraphics(gcf,fullfile([outDirPrepend, '/report_images/' files(cImage).name '/' files(cImage).name '_' num2str(i+12+2*length(S2)) '_2D_axis.png']));
                
            end
            
            %% Pore Cross-Sections
            
            delete(gca); close all;
            
            
            
            % Use peakfinder function of matlab
            % https://nl.mathworks.com/help/signal/ref/findpeaks.html
            
            % Initialize output arrays for table
            Label = (1:length(S2))';
            Depth = zeros(length(S2),1);
            Depth3 = zeros(length(S2),1);
            Diameter = zeros(length(S2),1);
            Height = zeros(length(S2),1);
            Height3 = zeros(length(S2),1);
            MidwallWidthL = zeros(length(S2),1);
            MidwallWidthR = zeros(length(S2),1);
            
            % Preparing subplot array
            plotsProfile = cell(1,length(S2));
            parfor i = 1:length(S2)
                % Fit minimally-smoothened curve to data for plotting and find wall heights
                % (pks)
                %       Use all three cross-sections to fit smoothened curve
                smoothFit = fit([pores.CS{1,i}';pores.CS{1,i}';pores.CS{1,i}'],...
                    [pores.CS{2,i}';pores.CS{3,i}';pores.CS{4,i}'],...
                    'smoothingspline','SmoothingParam',0.8);
                %       Use average of 3 cross-sections to determine height
                warning('off')
                [pks,loc_smooth,~] = findpeaks(pores.CS{5,i},pores.CS{1,i},...
                    'MinPeakDistance',minPD,'MinPeakHeight',minPH,'annotate','extents');
                
                % Fit extra-smoothened curve to find wall centers/pore diameter (loc)
                %       Use all three cross-sections to fit extra-smoothened curve
                centerFit = fit([pores.CS{1,i}';pores.CS{1,i}';pores.CS{1,i}'],...
                    [pores.CS{2,i}';pores.CS{3,i}';pores.CS{4,i}'],...
                    'smoothingspline','SmoothingParam',0.05); %2020.09.25 changed smoothingparam from 0.01 to 0.05
                yCenterFit = feval(centerFit,pores.CS{1,i}');
                warning('off')
                [~,loc,~] = findpeaks(yCenterFit,pores.CS{1,i},'MinPeakDistance',...
                    minPD,'MinPeakHeight',minPH*0.75);
                
                % Solution to some failure in pore detection, where detected pore walls
                % are near edge and over-smoothening results in loss of peak detection
                if length(loc) < 2 && length(loc_smooth) >=2
                    loc = loc_smooth;
                end
                
                if all([length(pks) >= 2, length(loc) >= 2])
                    % Calculate midwall width
                    ySmoothFit = feval(smoothFit,pores.CS{1,i})';
                    
                    % Find initial midwall width at exactly 1/2 height
                    yMidWall1 = zeros(1,length(pores.CS{1,i}))+pks(1)./2;
                    yMidWall2 = zeros(1,length(pores.CS{1,i}))+pks(end)./2;
                    
                    %   P1 for left peak, P2 for right peak, each calculated at respective
                    %   peak's midwall height
                    P1 = InterX([pores.CS{1,i};ySmoothFit],[pores.CS{1,i};yMidWall1]);
                    P2 = InterX([pores.CS{1,i};ySmoothFit],[pores.CS{1,i};yMidWall2]);
                    
                    % Check that complete walls were found on each side, else mark
                    % as failed pore
                    if size(P1,2)<2 | size(P2,2)<2
                        figure;
                        warning('off')
                        findpeaks(pores.CS{5,i},pores.CS{1,i},...
                            'MinPeakDistance',minPD,'MinPeakHeight',minPH,'annotate','extents')
                        hold on;
                        warning('off')
                        findpeaks(yCenterFit,pores.CS{1,i},'MinPeakDistance',...
                            minPD,'MinPeakHeight',minPH*0.75)
                        ylim([-2,4]);
                        xlim([pores.CS{1,i}(1),pores.CS{1,i}(end)]);
                        %title(sprintf('Pore %i',i));
                        failedPore = i + sum(ignoredPores < i);
                        text(mean(pores.CS{1,i})-10,1,{'Pore width calculation failed,';sprintf('please ignore pore %i',failedPore)})
                        exportgraphics(gcf,fullfile([outDirPrepend, '/report_images/' files(cImage).name '/' files(cImage).name '_' num2str(i+12+3.*length(S2)) '_profile.png']));
                        continue
                    else
                        initialMidwallWidthL = P1(1,2)-P1(1,1);
                        initialMidwallWidthR = P2(1,end)-P2(1,end-1);
                    end
                    
                    % Check if walls are outside expected mean +/- dev range
                    walls2 = [abs(initialMidwallWidthL-avgMWW) > devMWW,...
                        abs(initialMidwallWidthR-avgMWW) > devMWW];
                    
                    currentMidWallWidthL = initialMidwallWidthL;
                    currentMidWallWidthR = initialMidwallWidthR;
                    
                    if any(walls2)
                        % Check if left wall out of expected range
                        if walls2(1)
                            currentMidWallWidthL = NaN;
                            
                        end
                        
                        % Check if right wall out of expected range
                        dMidWallWidth = 0;
                        if walls2(2)
                            currentMidWallWidthR = NaN;
                        end
                    end
                    
                    
                    % Calculate pore depth as minimum value between pore walls
                    % Added 2020.11.16: Find min depth of all 3 cross sections
                    % called "Depth3"
                    [Depth(i),ind] = min(pores.CS{5,i}(pores.CS{1,i} > loc(1) & pores.CS{1,i} < loc(end)));
                    depthX = pores.CS{1,i}(find(pores.CS{1,i}==loc(1)) + ind);
                    
                    combCS = [pores.CS{2,i}(pores.CS{1,i} > loc(1) & pores.CS{1,i} < loc(end)),...
                        pores.CS{3,i}(pores.CS{1,i} > loc(1) & pores.CS{1,i} < loc(end)),...
                        pores.CS{4,i}(pores.CS{1,i} > loc(1) & pores.CS{1,i} < loc(end))]
                    Depth3(i) = min(combCS);
                    Height3(i) = max(combCS);
                    
                    %*************************%
                    %*********PLOTTING********%
                    %*************************%
                    
                    % Plot data with smoothened curve overlayed
                    figure;
                    hold on;
                    plot(smoothFit);
                    plot(pores.CS{1,i},pores.CS{2,i},'r--',...
                        pores.CS{1,i},pores.CS{3,i},'c--',...
                        pores.CS{1,i},pores.CS{4,i},'m--',...
                        pores.CS{1,i},pores.CS{5,i},'k-');
                    legend('off')
                    % Add vertical lines denoting pore wall centers
                    xline(loc(1),'r--');
                    xline(loc(end),'r--');
                    yline(0);
                    % Add horizontal lines for midwall width
                    if ~walls2(1)
                        line(P1(1,1:2),P1(2,1:2),'Color','g','LineWidth',3);
                    end
                    if ~walls2(2)
                        line(P2(1,end-1:end),P2(2,end-1:end),'Color','g','LineWidth',3);
                    end
                    % Add vertical line indicating avg wall height
                    % Fixed 29.09.2020 to be centered between only wall peaks (leftmost and rightmost detected peak)
                    errorbar(mean([loc(1),loc(end)]),0,0,mean([pks(1),pks(end)]),'b-.','LineWidth',1);
                    % Add vertical line indicating deepest point within pore
                    if Depth(i) <= 0
                        errorbar(depthX,0,Depth(i),0,'r-.','LineWidth',1);
                    else
                        errorbar(depthX,0,0,Depth(i),'r-.','LineWidth',1);
                    end
                    xlabel('X [nm]');
                    ylabel('Height [nm]');
                    %title(sprintf('Pore %i',i));
                    if Depth(i) < -2
                        ylim([floor(Depth(i)),4]);
                    else
                        ylim([-2,4]);
                    end
                    xlim([pores.CS{1,i}(1),pores.CS{1,i}(end)]);
                    
                    plotsProfile{i} = gca;
                    
                    %*************************%
                    %*DATA STORAGE FOR TABLE**%
                    %*************************%
                    Diameter(i) = loc(end)-loc(1);
                    Height(i) = mean([pks(1),pks(end)]);
                    MidwallWidthL(i) = currentMidWallWidthL;
                    MidwallWidthR(i) = currentMidWallWidthR;
                else
                    figure;
                    findpeaks(pores.CS{5,i},pores.CS{1,i},...
                        'MinPeakDistance',minPD,'MinPeakHeight',minPH,'annotate','extents')
                    hold on;
                    findpeaks(yCenterFit,pores.CS{1,i},'MinPeakDistance',...
                        minPD,'MinPeakHeight',minPH*0.75)
                    ylim([-2,4]);
                    xlim([pores.CS{1,i}(1),pores.CS{1,i}(end)]);
                    %title(sprintf('Pore %i',i));
                    failedPore = i + sum(ignoredPores < i);
                    text(mean(pores.CS{1,i})-10,1,{'Pore detection failed,';sprintf('please check input parameters for pore %i',failedPore)})
                end
                exportgraphics(gcf,fullfile([outDirPrepend, '/report_images/' files(cImage).name '/' files(cImage).name '_' num2str(i+12+3.*length(S2)) '_profile.png']));
            end
            
            % 2020.11.17
            % Correct when min depth is lower than AbsDepth (due to region selection in AbsDepth)
            % then substitutes Depth3 value into AbsDepth
            for i = 1:length(S2)
                if Depth3(i) < pores.maxDepth(i)
                    pores.maxDepth(i) = Depth3(i);
                end
            end
            
            %*************************%
            %** SAVE PORE STRUCTURE **%
            %*************************%
            save([outDirPrepend '/oligomer_profiles/' files(cImage).name '.mat'],'-struct','pubPores');
            
            DepthAbs = transpose(round(pores.maxDepth.*100)./100);
            Depth = round(Depth.*100)./100;
            Depth3 = round(Depth3.*100)./100;
            Diameter = round(Diameter.*100)./100;
            HeightAbs = transpose(round(pores.maxHeight.*100)./100);
            Height = round(Height.*100)./100;
            Height3 = round(Height3.*100)./100;
            MidwallWidthL = round(MidwallWidthL.*100)./100;
            MidwallWidthR = round(MidwallWidthR.*100)./100;
            MajorAxis = round([stats.MajorAxisLength]'.*100.*imSize./samplePoints)./100;
            MinorAxis = round([stats.MinorAxisLength]'.*100.*imSize./samplePoints)./100;
            
            %if usePoreTypes
            T = table(Label,Depth,Diameter,Height,MidwallWidthL,MidwallWidthR,DepthAbs,Depth3,HeightAbs,Height3,MajorAxis,MinorAxis,poreTypes,OGLabel');
            %else
            %    T = table(Label,Depth,Diameter,Height,MidwallWidthL,MidwallWidthR,DepthAbs,Depth3,HeightAbs,Height3,MajorAxis,MinorAxis);
            %end
            writetable(T,[outDirPrepend, '/summary_txt/', files(cImage).name,'_out.txt'],'Delimiter','\t')
            
    end
    
    % Save surface coverage to csv file
    totalCov = sum(sum(allStuff))./numel(allStuff);
    surfCov = sum(sum(z12))./numel(z12);
    analysisFolder = strsplit(files(cImage).folder,filesep);
    numDefects = sum(membraneDefects);
    defectCov = sum(sum(z20))./numel(z20);
    lowCov = sum(sum(lowStuff))./numel(lowStuff);
    highCov = sum(sum(highStuff))./numel(highStuff);
    
    
    fid = fopen([outDirPrepend '/surfCoverage.csv'], 'a');
    fprintf(fid,'%s,%s,%i,%d,%i,%d,%d,%d,%d\n',files(cImage).name,analysisFolder{end},length(S2),surfCov,...
        numDefects,defectCov,lowCov,highCov,totalCov);
    fclose(fid) ;
    
    
    
    %%
    %Cleanup
    delete(gca); close all;
    
    % Shut down parallel pool to reset memory
    %    delete(gcp('nocreate'))
    
    %% Write report
    
    switch mode
        case "FullAnalysis"
            GSDMx_reportGenerator(files(cImage),outDirPrepend,T,surfCov);
        case "SurfaceCoverage"
            GSDMx_reportGenerator_surfCov(files(cImage),outDirPrepend,T,surfCov);
    end
    mlreportgen.utils.rptviewer.closeAll()
    
    %% Update waitbar
    
    fprintf("%i/%i\n",cImage,length(files))
end
toc

%% After processing all data, run R Script to generate summary statistics with figures


%% Change back to old directory at end of script
cd(oldDir)
