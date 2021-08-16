function stats = oligomerRidge(stats)

% %% Set standard paramters
% minPathLength = 10;
% 
% %% Combine all .mat files into one for use in the classification learner
% matFiles = dir('/Users/matt/Google_Drive/ETH_Zurich/MullerLab/MSc_Thesis/training_data/GSDMA/oligomer_data_nofill/*.mat');
% matFilesXYZ = dir('/Users/matt/Google_Drive/ETH_Zurich/MullerLab/MSc_Thesis/training_data/GSDMA/oligomer_data_filled/*.mat');
% 
% data = load(fullfile(matFiles(1).folder,matFiles(1).name));
% dataXYZ = load(fullfile(matFilesXYZ(1).folder,matFiles(1).name));
% 
% names = [fieldnames(data.stats2);{'X';'Y';'Z'}];
% 
% stats = cell2struct([struct2cell(data.stats2); {dataXYZ.stats2.X};{dataXYZ.stats2.Y};{dataXYZ.stats2.Z}], names, 1); %
% %stats = data.stats2;
% clear data dataXYZ
% 
% for i = 2:length(matFiles)
%     data = load(fullfile(matFiles(i).folder,matFiles(i).name));
%     dataXYZ = load(fullfile(matFilesXYZ(i).folder,matFiles(i).name));
%     
%     stats2 = cell2struct([struct2cell(data.stats2); {dataXYZ.stats2.X};{dataXYZ.stats2.Y};{dataXYZ.stats2.Z}], names, 1); %
%     
%     stats = [stats; stats2];
%     clear data dataXYZ stats2
% end
% clear i matFiles matFilesXYZ names


%% Calculate Ridge Data
set(0,'DefaultFigureVisible','off')

parfor oligoNum = 1:length(stats)
    delete(gca); close all;
    % For debugging
    %         X = oligomer.X{oligoNum};
    %         Y = oligomer.Y{oligoNum};
    %         Z = oligomer.Z{oligoNum};
    
    % Actual
    X = stats(oligoNum).X;
    Y = stats(oligoNum).Y;
    Z = stats(oligoNum).Z;
    %set(0,'DefaultFigureVisible','off')
    
    % set parameters
    imSize = stats(oligoNum).imSize;
    scaleFactor = floor(10*sqrt(700^2/imSize^2));   % Accounts for different image scan sizes-sample point ratios (ie. 512 sample points is different for a 400x400nm vs 700x700nm image)
    boxRegion = 1;
    
    % First do a round of filtering to smooth oligo ridge slightly
    Z_filt = imgaussfilt(Z,1);
    
    % Plot original + gaussian filtered surfaces
    % figure; surf(X,Y,Z,'LineStyle','none');
    % figure; surf(X,Y,Z_filt,'LineStyle','none');
    
%          figure; hold on; set(gcf,'Position',[1 1 1000 800]); surf(X,Y,Z,'LineStyle','none'); view( -20,70)
%          exportgraphics(gcf,fullfile(['/Users/matt/Google_Drive/ETH_Zurich/MullerLab/MSc_Thesis/training_data/GSDMA/ridge_figures/','ridgeDetection_raw_',num2str(oligoNum),'.png']));
%     
%          figure; hold on; set(gcf,'Position',[1 1 1000 800]); surf(X,Y,Z_filt,'LineStyle','none'); view( -20,70)
%          exportgraphics(gcf,fullfile(['/Users/matt/Google_Drive/ETH_Zurich/MullerLab/MSc_Thesis/training_data/GSDMA/ridge_figures/','ridgeDetection_filtered_',num2str(oligoNum),'.png']));
%     
    %% bwskel method - an approximation as the final result does not exactly follow the ridge, but is close
    if max(max(Z)) < 4
        Z_high = Z_filt>min(0.5*max(max(Z_filt)),2.0);
    else
        Z_high = Z_filt>1.5;
    end
    %[r,c] = size(Z);
    
    % Find ridge
    ridge = bwskel(Z_high,'MinBranchLength',scaleFactor);
    %figure; imshow(labeloverlay(Z,ridge,'Transparency',0));
    
    % Get index of first true value in ridge mask
%     [ixd_r,idx_c] = find(ridge, 1, 'first');
%     ridgeRegions = bwtraceboundary(ridge,[ixd_r,idx_c],'E');
%     ridgeLength = length(ridgeRegions);
    
    [ridgeRegions,~,~,~] = bwboundaries(ridge,'noholes');
    if numel(ridgeRegions) > 1
        lengths = cellfun(@height,ridgeRegions);
        [~,b] = sort(lengths,'descend');
        selectedRidge = b(1);   % Always selects the second longest ridge, as the longest should be the outermost measure while the second largest should be the inner, actual ridge.
    else
        selectedRidge = 1;
    end
    ridgeLength = length(ridgeRegions{selectedRidge});
    
    % Extract X,Y,Z_filt values based on path
    X_path = zeros(1,ridgeLength);
    Y_path = zeros(1,ridgeLength);
    Z_path = zeros(1,ridgeLength);
    for i=1:ridgeLength
        X_path(i) = X(ridgeRegions{selectedRidge}(i,1),ridgeRegions{selectedRidge}(i,2));
        Y_path(i) = Y(ridgeRegions{selectedRidge}(i,1),ridgeRegions{selectedRidge}(i,2));
        Z_path(i) = Z_filt(ridgeRegions{selectedRidge}(i,1),ridgeRegions{selectedRidge}(i,2));
    end
    
    %     % Plot
    %     figure; hold on;
    %     surf(X,Y,Z_filt,'LineStyle','none');
    %     plot3(X_path,Y_path,Z_path);
    
%         figure; hold on; set(gcf,'Position',[1 1 1000 800]); surf(X,Y,Z_filt,'LineStyle','none'); plot3(X_path,Y_path,Z_path,'LineWidth',3,'Color','r'); view( -20,70)
%         exportgraphics(gcf,fullfile(['/Users/matt/Google_Drive/ETH_Zurich/MullerLab/MSc_Thesis/training_data/GSDMA/ridge_figures/','ridgeDetection_path_',num2str(oligoNum),'.png']));
    
    
    %% Coordinate system change from (X,Y) to D
    % FIRST FOR UNADJUSTED PATH
    % Shift array circularly to start at highest point
    [~,idx] = max(Z_path);
    X_path = circshift(X_path,-idx+1);
    Y_path = circshift(Y_path,-idx+1);
    Z_path = circshift(Z_path,-idx+1);
    
    D = sqrt((X_path(2:end)-X_path(1:end-1)).^2 + (Y_path(2:end)-Y_path(1:end-1)).^2);
    D = [0, D];
    for i=2:ridgeLength
        D(i) = D(i-1)+D(i);
    end
    
    % Remove non-unique values (artifact of circular shift)
    [D_unique,IA,~] = unique(D,'stable');
    Z_path_unique = Z_path(IA);
    
    % Plot ridge profile on top of surface plot
%     figure; hold on;
%     surf(X,Y,Z_filt,'LineStyle','none');
%     plot3(X_path,Y_path,Z_path);
    
    % Plot ridge profile
%     figure; set(gcf,'Position',[1 1 1000 600]);
%     plot(D_unique,Z_path_unique); ylim([0,4]);
    
    %% Rescale to a length 100 vector (100 measurement units + original length)
    
    D_scale = linspace(0,D_unique(end),100);
    
    if length(Z_path) > 2
        Z_path_scale = interp1(D_unique,Z_path_unique,D_scale);
    else
        Z_path_scale = repmat(Z_path_unique,1,100);
    end
    
%     % Plot ridge profile
%     figure; set(gcf,'Position',[1 1 500 400]);
%     plot(D_scale,Z_path_scale,'LineWidth',3,'Color','r'); ylim([0,4]); 
%     if D_scale(end) ~= 0
%         xlim([0,D_scale(end)]);
%     else
%         xlim([0,10]);
%         text(4,2,{'Ridge detection failed'})
%     end
%     ylabel('Height [nm]','FontSize',18); xlabel('Distance along Ridge [nm]','FontSize',18);
%     exportgraphics(gcf,fullfile(['/Users/matt/Google_Drive/ETH_Zurich/MullerLab/MSc_Thesis/training_data/GSDMA/ridge_figures/','ridgeDetection_path_flat_',num2str(oligoNum),'.png']));
    
    %% Save ridge profile and length to oligomer data
    stats(oligoNum).ridgeProfile = Z_path_scale;
    stats(oligoNum).ridgeLength = D_unique(end);
    stats(oligoNum).ridgeObjects = length(ridgeRegions);
    
end

%% Convert to usable form for Classification Learner
set(0,'DefaultFigureVisible','on')

% statsTable = struct2table(stats);
% 
% removeFields = {'Centroid';'Label';'OGLabel'};%;'X';'XScale';'XScaleLin';'Y';'YScale';'YScaleLin';'Z';'ZScale'};
% statsTable = removevars(statsTable,removeFields);

end


%{
%% Old code

ridge = bwmorph(Z_filt>2,'skel','clean');
ridgeLength = sum(ridge,[1 2]);

Get index of highest value
[ixd_r,idx_c] = ind2sub(size(Z),idx);

ridgeRegions = regionprops(ridge,'PixelList');

% numerical method - attempt to follow ridge exactly
% Find max point along oligo ridge to start calculations at
[zMax,idx] = max(Z_filt,[],[1 2],'linear');

% Get paired index of highest value
[ixd_r,idx_c] = ind2sub(size(Z),idx);

stopCond = false;
while ~stopCond



end

%% Adapted from https://ch.mathworks.com/matlabcentral/answers/337864-valley-ridge-tracing-in-n-d-data

eventdata = [];
handles = [];

mydata=struct('area',{},'max',{},'mean',{},'median',{},'integral',{});


[sx sy sz]=size(Z_filt);

I2 = Z_high;

boundaries=bwboundaries(I2,'holes');
[bx by]=size(boundaries);
k=0;
sxmin=100;
for i=1:bx b=boundaries{i};
    [sx sy]=size(b);
    if sx>sxmin k=k+1;
        pboundaries{k}=boundaries{i};
    end
end
% bdetails=boundaries_details(boundaries,Z_filt);
% size(bdetails)
handles.boundaries=boundaries;
handles.bwimage=I2;
immin=min(min(Z_filt));
immax=max(max(Z_filt));

h1=imshow(double(Z_filt),[immin immax]);

if strcmp(mybutton,'normal')==1
    fprintf(1,'\nLEFT BUTTON PRESSED\n');
    update_flag=1;
end
if strcmp(mybutton,'alt')==1
    fprintf(1,'\nRIGHT BUTTON PRESSED\n');
    axpos=get(gca,'position');
    fig2=figure('visible','on','position',axpos);
    newax = copyobj(handles.axes1,fig2);
    colormap(handles.colormap);
    update_flag=0;
end
if update_flag==1
    if handles.count>1
        lastx=handles.lastx;
        lasty=handles.lasty;
    end
    fprintf(1,'\nAxes1_SpotButtondownFcn called');
        hold on;
    px=plot(1:sx,1,'b');
    py=plot(1,1:sy,'r');
end
drawnow;

mm=get(gca,'currentpoint'); myx=mm(1,1); myy=mm(1,2); [sx,sy]=size(boundaries);
save bdetails bdetails save pboundaries pboundaries
[px,py]=size(pboundaries);
for i=1:2:py
    b=pboundaries{i};
    plot(b(:,2),b(:,1),'g','linewidth',2);
    c=pboundaries{i+1};
    plot(c(:,2),c(:,1),'b','linewidth',2);
    drawnow; % Now find the curve running on the ridge between the outer and inner boundary
    [bx,by]=size(b);
    [cx,cy]=size(c);
    for j=1:bx
        for k=1:cx
            bdist(k)=sqrt((c(k,1)-b(j,1))^2+(c(k,2)-b(j,2))^2);
        end
        [bdmin bloc]=min(bdist);
        xr=b(j,1)+(c(bloc,1)-b(j,1))/2;
        yr=b(j,2)+(c(bloc,2)-b(j,2))/2;
        ridge(j,1)=xr; ridge(j,2)=yr;
    end
    plot(ridge(:,2),ridge(:,1),'r','linewidth',2);

%Now extract the image intensity values from the original image and plot them in axes2
    [rx ry]=size(ridge);
    hz=1;
    for i=1:rx
        xc=int16(ridge(i,1));
        yc=int16(ridge(i,2));
        myval=mean(mean(Z_filt(xc-hz:xc+hz,yc-hz:yc+hz)));
        myvector(i)=myval;
    end

end
axes(handles.axes2);
cla; plot(1:rx,myvector,'b');
set(gca,'Ydir','normal');
title('Plasmid Ridge Walk');
axes(handles.axes3); cla;

mylen=length(myvector);
myrange=floor(mylen/2);
Y = xcorr(myvector,myrange,'unbiased');
title('Autocorrelation of Plasmid Ridge Walk')
xlabel('pixel dist');
axes(handles.axes4);
cla; title('');
axes(handles.axes5);
cla; title('');
guidata(handles.figure1, handles);

%% Fit approximate equation for classifier
    
    mode = 'custom';
    %mode = 'smoothspline';
    
    switch mode
        case 'custom'
            % 'a*(x-b)^2+c*sin(x)+d'
            fo = fitoptions('Method','NonlinearLeastSquares',...
                'Lower',[-0.01,-200, 0],...
                'Upper',[0.01 200 5],...
                'StartPoint',[0.0001 45 2.4],...
                'normalize','off',...
                'robust','on');
            %ft = fittype('a*(x-b)^2+c*sin(x)+d','options',fo);
            ft = fittype('a*(x-b)^4+c','options',fo);
            [curve, goodness, output] = fit(D',Z_path',ft);
        case 'smoothspline'
            % smoothingspline
            [curve, goodness, output] = fit(D',Z_path','smoothingspline','smoothingparam',0.2);
    end
    
    figure;
    plot(curve,D',Z_path');

%{
    % THEN FOR GRADIENT ADJUSTED PATH
    % Shift array circularly to start at highest point
    [~,idx] = max(Z_path_adj);
    X_path_adj = circshift(X_path_adj,-idx+1);
    Y_path_adj = circshift(Y_path_adj,-idx+1);
    Z_path_adj = circshift(Z_path_adj,-idx+1);
    
    D = sqrt((X_path_adj(2:end)-X_path_adj(1:end-1)).^2 + (Y_path_adj(2:end)-Y_path_adj(1:end-1)).^2);
    D = [0, D];
    for i=2:ridgeLength
        D(i) = D(i-1)+D(i);
    end
    
    % Plot ridge profile
    figure; plot(D,Z_path_adj);
    
    % Plot ridge profile on top of surface plot
    figure; hold on;
    surf(X,Y,Z_filt,'LineStyle','none');
    plot3(X_path_adj,Y_path_adj,Z_path_adj);
%}
%% Fit logarithmic spiral
    
    
    %% Snap estimated path to highest local values
%{
    % Z_filt_high = Z_filt;
    % Z_filt_high(~Z_high) = nan;
    
    % Calculate Gradient
    [Gmag,Gdir] = imgradient(Z_filt,'sobel');
    Gmag(~Z_high) = nan;
    Gdir(~Z_high) = nan;
    
    % Initialize new vectors
    adjRidgeRegions = ridgeRegions;
    X_path_adj = X_path;
    Y_path_adj = Y_path;
    Z_path_adj = Z_path;
    for i=1:ridgeLength
        xCoord = max(adjRidgeRegions(i,2)-boxRegion,1):min(adjRidgeRegions(i,2)+boxRegion,c);
        yCoord = max(adjRidgeRegions(i,1)-boxRegion,1):min(adjRidgeRegions(i,1)+boxRegion,r);
        
        X_region = X(yCoord,xCoord);
        Y_region = Y(yCoord,xCoord);
        Z_region = Z_filt(yCoord,xCoord);
        Gmag_region = Gmag(yCoord,xCoord);
        
        [~, idx] = min(Gmag_region,[],[1 2],'linear');
        [idx_r,idx_c] = ind2sub(size(Z_region),idx);
        
        % Find original coord from full Z_filt_high in order to set new value
        % to nan so it is not reselected in next step
        ogCoord = [yCoord(1)+idx_r-1,xCoord(1)+idx_c-1];
        adjRidgeRegions(i,:) = ogCoord;
        %Z_filt_high(ogCoord(1),ogCoord(2)) = nan;
        Gmag(ogCoord(1),ogCoord(2)) = nan;
        
        % Adjust X_path,Y_path, and Z_path accordingly
        X_path_adj(i) = X(ogCoord(1),ogCoord(2));
        Y_path_adj(i) = Y(ogCoord(1),ogCoord(2));
        Z_path_adj(i) = Z_filt(ogCoord(1),ogCoord(2));
    end
    
    %ridgeRegions = bwtraceboundary(ridge,[ixd_r,idx_c],'E');
    
    % Plot
    figure; hold on;
    surf(X,Y,Z_filt,'LineStyle','none');
    plot3(X_path_adj,Y_path_adj,Z_path_adj);
    
    
    
    %% 20210629 Attempt to follow minimum gradient following shortest path
    
%Calculate Gradient
[Gmag,Gdir] = imgradient(Z_filt,'sobel');
Gmag(~Z_high) = nan;
Gdir(~Z_high) = nan;

% Find start point
ogCoord = zeros(1,2);
[Gmag_min, idx] = min(Gmag,[],[1 2],'linear');
[ogCoord(1),ogCoord(2)] = ind2sub(size(Z_filt),idx);

% Walk along "shortest path"
endCond = false;
ridgeWalk = [ogCoord(1),ogCoord(2)];

X_path_adj = [X(idx)];
Y_path_adj = [Y(idx)];
Z_path_adj = [Z_filt(idx)];

i = 1;
while ~endCond
    i = i+1;
    
    % Extract region from Gmag
    xCoord = max(ogCoord(1)-boxRegion,1):min(ogCoord(1)+boxRegion,c);
    yCoord = max(ogCoord(2)-boxRegion,1):min(ogCoord(2)+boxRegion,r);
    
    %Gmag_region = Gmag(yCoord,xCoord);
    %Gmag_region = abs(Gmag(yCoord,xCoord)-Gmag_min);
    Gmag_region = Gmag(yCoord,xCoord);
    
    [Gmag_min, idx] = min(Gmag_region,[],[1 2],'linear');
    [idx_r,idx_c] = ind2sub(size(Gmag_region),idx);
    
    % Add nearest step to walk
    ogCoord = [yCoord(1)+idx_r-1,xCoord(1)+idx_c-1];
    ridgeWalk(i,:) = ogCoord;

    Gmag(ogCoord(1),ogCoord(2)) = nan;
    
    % Adjust X_path,Y_path, and Z_path accordingly
    X_path_adj(i,:) = X(ogCoord(1),ogCoord(2));
    Y_path_adj(i,:) = Y(ogCoord(1),ogCoord(2));
    Z_path_adj(i,:) = Z_filt(ogCoord(1),ogCoord(2));
    
    % Check for end condition
    if i > 100
        endCond = true;
    end
end

% Plot
figure; hold on;
surf(X,Y,Z_filt,'LineStyle','none');
plot3(X_path_adj,Y_path_adj,Z_path_adj);

%}
    
%{
%% Boundary at Z=2.0 nm
Z_bound = bwboundaries(Z_high);

% Extract X,Y,Z_filt values based on path
X_path = cell(2,1);
Y_path = cell(2,1);

figure; hold on;
for i = 1:2
    for j=1:length(Z_bound{i})
        X_path{i}(j) = X(Z_bound{i,1}(j,1),Z_bound{i,1}(j,2));
        Y_path{i}(j) = Y(Z_bound{i,1}(j,1),Z_bound{i,1}(j,2));
    end
    plot(X_path{i},Y_path{i});
end

%}
%}
