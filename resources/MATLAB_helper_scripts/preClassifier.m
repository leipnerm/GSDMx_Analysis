function statsTable = preClassifier(stats)

% A function to pre-process the stats structure for feeding into the
% classifier



%% Find non-square regions and cut to square
nonSquareMask = ~cellfun(@(x) ~diff(size(x)), {stats.X}); %Run this code if region matrix is square

for i = find(nonSquareMask)
    % Find dimensions of trimmed side
    [r,c] = size(stats(i).X);
    minDimension = min([r,c]);
    
    cut = (max(r,c)-minDimension);
    extractedDim = [ceil(cut/2)+1:max(r,c)-floor(cut/2)];
    
    % Extract trimmed square
    if r > c    %trim rows
        X_temp = stats(i).X(extractedDim,:);
        Y_temp = stats(i).Y(extractedDim,:);
        Z_temp = stats(i).Z(extractedDim,:);
    else        %trim columns
        X_temp = stats(i).X(:,extractedDim);
        Y_temp = stats(i).Y(:,extractedDim);
        Z_temp = stats(i).Z(:,extractedDim);
    end
    
    % Plot for comparison
    %     figure;
    %     subplot(1,2,1); imshow(stats(j).Z)
    %     subplot(1,2,2); imshow(Z_temp)
    
    % Save trimmed square in place of original
    stats(i).X = X_temp;
    stats(i).Y = Y_temp;
    stats(i).Z = Z_temp;
    
    clear X_temp Y_temp Z_temp cut extractedDim minDimension r c
end

names = fieldnames(stats);

% Rescale region extracts
stats = cell2struct([struct2cell(stats);...
    %cellfun(@(x) imresize(x,[50,50]),{stats.X},'un',0);...
    %cellfun(@(x) imresize(x,[50,50]),{stats.Y},'un',0);...
    cellfun(@(x) imresize(x,[50,50]),{stats.Z},'un',0)],[names;{'ZScale'}],1); %'XScale';'YScale';

names = fieldnames(stats);

%% Add bwskel estimate
stats = cell2struct([struct2cell(stats);...
    cellfun(@(x) bwskel(x>min(0.5*max(max(x)),2.0),'MinBranchLength',3),{stats.ZScale},'un',0)],...
    [names;{'Zskel'}],1);

names = fieldnames(stats);

%% Linearize rescaled region extracts
stats = cell2struct([struct2cell(stats);...
    %cellfun(@(x) reshape(x,1,[]),{stats.XScale},'un',0);...
    %cellfun(@(x) reshape(x,1,[]),{stats.YScale},'un',0);...
    %cellfun(@(x) reshape(x,1,[]),{stats.ZScale},'un',0)], [names;{'ZScaleLin'}], 1); %'XScaleLin';'YScaleLin';
    cellfun(@(x) reshape(x,1,[]),{stats.Zskel},'un',0)], [names;{'ZskelLin'}], 1);

%% Find ridge

parfor oligoNum = 1:length(stats)
    
    % Actual
    X = stats(oligoNum).X;
    Y = stats(oligoNum).Y;
    Z = stats(oligoNum).Z;
    
    % set parameters
    imSize = stats(oligoNum).imSize;
    scaleFactor = floor(10*sqrt(700^2/imSize^2));   % Accounts for different image scan sizes-sample point ratios (ie. 512 sample points is different for a 400x400nm vs 700x700nm image)
    boxRegion = 1;
    
    % First do a round of filtering to smooth oligo ridge slightly
    Z_filt = imgaussfilt(Z,1);
    
    %% bwskel method - an approximation as the final result does not exactly follow the ridge, but is close
    if max(max(Z)) < 4
        Z_high = Z_filt>min(0.5*max(max(Z_filt)),2.0);
    else
        Z_high = Z_filt>1.5;
    end
    
    % Find ridge
    ridge = bwskel(Z_high,'MinBranchLength',scaleFactor);
    
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
    
    %% Rescale to a length 100 vector (100 measurement units + original length)
    
    D_scale = linspace(0,D_unique(end),100);
    
    if length(Z_path) > 2
        Z_path_scale = interp1(D_unique,Z_path_unique,D_scale);
    else
        Z_path_scale = repmat(Z_path_unique,1,100);
    end
    
    %% Save ridge profile and length to oligomer data
    stats(oligoNum).ridgeProfile = Z_path_scale;
    stats(oligoNum).ridgeLength = D_unique(end);
    stats(oligoNum).ridgeObjects = length(ridgeRegions);
    
end

%% Convert to Table and remove unecessary fields for classification
statsTable = struct2table(stats);

% removeFields = {'Centroid';'Label';'OGLabel';'X';'Y';'Z';'ZScale'}; %'XScale';'XScaleLin';'YScale';'YScaleLin';
% statsTable = removevars(statsTable,removeFields);



end