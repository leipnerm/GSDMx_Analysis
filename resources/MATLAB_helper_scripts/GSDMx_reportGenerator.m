function GSDMx_reportGenerator(file,outDirPrepend,T,Tcov,app)

%% Preface
%
% Copyright: Matthew Leipner
%
% * Original date:  04.04.2019
%
% * Updated:  11.04.2019
%   - added pore coverage area statistic
%
% Acknowledgements to
%
% CODE:
%
% * MATLAB Report Generator, https://www.youtube.com/watch?v=7r_1VRp8Rlg
%

%% Input Parameters

% Start Report Generation
import mlreportgen.report.*
import mlreportgen.dom.*
R = Report([outDirPrepend,'/reports/',file.name,'.pdf'],'pdf');
open(R);

br = PageBreak();

% Add Title Page
tp = TitlePage();
tp.Title = 'Muller Lab, BSSE';
subtitle = Paragraph(sprintf('Analysis of:\t\t%s',file.name));
subtitle.Style = {HAlign('left'),FontFamily('Arial'),...
    FontSize('12pt'),Color('black')};
tp.Subtitle = subtitle;
tp.Author = 'Matthew Leipner';
dt = datetime('now', 'TimeZone', 'Europe/Madrid');
dt.Format = 'dd.MM.uuuu';
tp.PubDate = char(dt);
tp.Image = [outDirPrepend,'/report_images/',file.name,'/',file.name,'_3_all.png'];
add(R,tp);

% Add Table of Contents
toc = TableOfContents;
toc.Title = 'Table of Contents';
add(R,toc);

% Adjust margins
% s = R.Layout;
% s.PageMargins.Left  = '.5in';
% s.PageMargins.Right = '.5in';

% Add First Chapter on Raw AFM Image
ChapterX = Chapter();
ChapterX.Title = 'Raw AFM Image';
im1 = FormalImage();
im1.Image = [outDirPrepend,'/report_images/',file.name,'/',file.name,'_1_raw.png'];
%im1.Caption = 'Unflattened AFM Image';
add(ChapterX,im1);
add(R,ChapterX);

% Add Second Chapter on Flattened AFM Image
ChapterX = Chapter();
ChapterX.Title = 'Flattened AFM Image';
im2 = FormalImage();
im2.Image = [outDirPrepend,'/report_images/',file.name,'/',file.name,'_2_flat.png'];
%im2.Caption = 'Flattened AFM Image';
add(ChapterX,im2);
add(R,ChapterX);

% Add Third Chapter on all and isolated objects
ChapterX = Chapter();
ChapterX.Title = 'All and Isolated Objects';
im3 = FormalImage();
im3.Image = [outDirPrepend,'/report_images/',file.name,'/',file.name,'_3_all.png'];
im3.Caption = 'All Objects';
add(ChapterX,im3);

im3 = FormalImage();
im3.Image = [outDirPrepend,'/report_images/',file.name,'/',file.name,'_4_isolated.png'];
im3.Caption = 'Isolated Objects';
add(ChapterX,im3);

add(R,ChapterX);

% Add Fourth Chapter on Binarized AFM Image
ChapterX = Chapter();
ChapterX.Title = 'Binarized and Watershedded Image';
im4 = FormalImage();
im4.Image = [outDirPrepend,'/report_images/',file.name,'/',file.name,'_5_watershedded.png'];
add(ChapterX,im4);
add(R,ChapterX);

% Add Fifth Chapter on Labeled AFM Image
ChapterX = Chapter();
ChapterX.Title = 'Labeled Image';
im5 = FormalImage();
im5.Image = [outDirPrepend,'/report_images/',file.name,'/',file.name,'_12_labeled.png'];
add(ChapterX,im5);
add(R,ChapterX);

% 2020.11.17 Add Sixth Chapter on Fitted Elipse
ChapterX = Chapter();
ChapterX.Title = 'Major/Minor Axis Labeled Image';
im6 = FormalImage();
im6.Image = [outDirPrepend,'/report_images/',file.name,'/',file.name,'_6_axis.png'];
add(ChapterX,im6);
add(R,ChapterX);


%% ADDED 20210511: Add Seventh Chapter on all Coverage data
% ADDED 20210511: Overall Oligomer Coverage
ChapterX = Chapter();
ChapterX.Title = 'Isolated Oligomers (within size, major axis, and height filters)';
im5 = FormalImage();
im5.Image = [outDirPrepend,'/report_images/',file.name,'/',file.name,'_7_poreCoverage.png'];
add(ChapterX,im5);
add(R,ChapterX);

% Low Coverage first
ChapterX = Chapter();
ChapterX.Title = 'Oligomer coverage filtered by Height';
im6 = FormalImage();
im6.Image = [outDirPrepend,'/report_images/',file.name,'/',file.name,'_9_lowCoverage.png'];
im6.Caption = 'Low Coverage (below oligomerMaxHeight filter)';
add(ChapterX,im6);

p = Paragraph(['GSDMx Low Coverage: ', num2str(round(Tcov{7}.*100,2)), '%']);
add(ChapterX,p);

% Then high Coverage
im7 = FormalImage();
im7.Image = [outDirPrepend,'/report_images/',file.name,'/',file.name,'_10a_highCoverage.png'];
im7.Caption = 'High Coverage (above oligoMaxHeight and below proteinMaxHeight filter)';
add(ChapterX,im7);

p = Paragraph(['GSDMx High Coverage: ', num2str(round(Tcov{8}.*100,2)), '%']);
add(ChapterX,p);

% Then aggregate Coverage
im8 = FormalImage();
im8.Image = [outDirPrepend,'/report_images/',file.name,'/',file.name,'_10b_aggregateCoverage.png'];
im8.Caption = 'Aggregate Coverage (above proteinMaxHeight filter)';
add(ChapterX,im8);

p = Paragraph(['GSDMx Aggregate Coverage: ', num2str(round(Tcov{9}.*100,2)), '%']);
add(ChapterX,p);

% Then all Coverage
im9 = FormalImage();
im9.Image = [outDirPrepend,'/report_images/',file.name,'/',file.name,'_11_allCoverage.png'];
im9.Caption = 'All Coverage (low, high, and aggregate together)';
add(ChapterX,im9);

p = Paragraph(['GSDMx All coverage: ', num2str(round(Tcov{10}.*100,2)), '%']);
add(ChapterX,p);

add(R,ChapterX);


%% Add Eighth Chapter on Pore Analysis
ChapterX = Chapter();
ChapterX.Title = 'Individual Oligomer Analysis';

% Style setup
mainHeaderRowStyle = {VAlign('middle'), InnerMargin('4pt', '4pt', '4pt', '4pt'), ...
    BackgroundColor('skyblue')};
mainHeaderTextStyle = {Bold, OuterMargin('0pt', '0pt', '0pt', '0pt'), FontFamily('Arial')};
tableHeaderTextStyle = {HAlign('center'), Bold, OuterMargin('0pt', '0pt', '0pt', '0pt'), FontFamily('Arial')};
br = {PageBreakBefore(true)};

%   get list of all images in images folder and list in order
srcDir = [outDirPrepend,'/report_images/',file.name];
srcStruc3D = dir(fullfile(srcDir,'*_3D.png'));
srcFiles3D = natsortfiles({srcStruc3D.name});
srcStruc2D = dir(fullfile(srcDir,'*_2D.png'));
srcFiles2D = natsortfiles({srcStruc2D.name});
srcStruc2D_axis = dir(fullfile(srcDir,'*_2D_axis.png'));
srcFiles2D_axis = natsortfiles({srcStruc2D_axis.name});
srcStrucProf = dir(fullfile(srcDir,'*_profile.png'));
srcFilesProf = natsortfiles({srcStrucProf.name});

for i = 1:2:numel(srcStrucProf)
    %table6.Style = {OuterMargin('-0.4in')};
    for j = 0:1
        table7 = Table(2);
        if i+j > numel(srcFiles3D)
            continue
        end
        % Create pore profile 1 rows high table entry
        im7Prof = Image(char(fullfile(srcDir,srcFilesProf(i+j))));
        im7Prof.Style = {Width('6in')};
        te7Prof = TableEntry(im7Prof);
        te7Prof.ColSpan = 7;
        te7Prof.RowSpan = 1;
        %te6Prof.Style = {Width('4.5in')};
        te7Prof.VAlign = 'top';
        % Create 3D profile table entry
        im73D = Image(char(fullfile(srcDir,srcFiles3D(i+j))));
        im73D.Style = {Height('2in')};
        te73D = TableEntry(im73D);
        te73D.ColSpan = 3;
        te73D.RowSpan = 1;
        %te63D.Style = {Width('2in')};
        % Create 2D profile table entry
        im72D = Image(char(fullfile(srcDir,srcFiles2D(i+j))));
        im72D.Style = {Height('2in')};
        te72D = TableEntry(im72D);
        te72D.ColSpan = 2;
        te72D.RowSpan = 1;
        %te62D.Style = {Width('2in')};
        % Create 2D profile with major/minor axis table entry
        im72D_axis = Image(char(fullfile(srcDir,srcFiles2D_axis(i+j))));
        im72D_axis.Style = {Height('2in')};
        te72D_axis = TableEntry(im72D_axis);
        te72D_axis.ColSpan = 2;
        te72D_axis.RowSpan = 1;
        %te62D.Style = {Width('2in')};
        
        %Table Pore Header
        if any(strcmp('poreTypes',T.Properties.VariableNames))      % Updated 2020.11.17 for added stats
            switch T.poreTypes{i+j}    %Updated 03.05.19 to change from number type to written
                case 2
                    type = 'Ring';
                case 3
                    type = 'Slit';
                case 4
                    type = 'Arc';
            end
            p = Paragraph(sprintf('Object %i, %s',i+j,type));
        else
            p = Paragraph(sprintf('Object %i',i+j));
        end
        p.Style = [p.Style mainHeaderTextStyle];
        p.Style = [p.Style {PageBreakBefore()}];
        te = TableEntry(p);
        te.ColSpan = 5;
        
        % Put table entries together by row
        tr0 = TableRow;
        if j==0 && i~=1
            tr0.Style = [tr0.Style mainHeaderRowStyle {PageBreakBefore(true)}];
        else
            tr0.Style = [tr0.Style mainHeaderRowStyle];
        end
        append(tr0, te);
        if any(strcmp('OGLabel',T.Properties.VariableNames))
            p = Paragraph('Orig. Label');
            te = TableEntry(p);
            te.ColSpan = 1;
            append(tr0, te);
            p = Paragraph(num2str(T.OGLabel{i+j}));
            te = TableEntry(p);
            te.ColSpan = 1;
            append(tr0, te);
        end
        append(table7,tr0);
        % Add figures to table
        tr1 = TableRow;
        append(tr1,te7Prof);
        append(table7,tr1);
        tr2 = TableRow;
        append(tr2,te73D);
        append(tr2,te72D);
        append(tr2,te72D_axis);
        append(table7,tr2);
        
        % Add statistic labels to table
        tr3 = TableRow;
        p = Paragraph('');              % For vertical labels
        te = TableEntry(p);
        append(tr3, te);
        p = Paragraph('Depth [nm]');
        p.Style = [p.Style mainHeaderTextStyle];
        te = TableEntry(p);
        append(tr3, te);
        p = Paragraph('Height [nm]');
        p.Style = [p.Style mainHeaderTextStyle];
        te = TableEntry(p);
        append(tr3, te);
        p = Paragraph('Diameter [nm]');
        p.Style = [p.Style tableHeaderTextStyle];
        te = TableEntry(p);
        te.ColSpan = 2;
        append(tr3, te);
        p = Paragraph('MW Width [nm]');
        p.Style = [p.Style tableHeaderTextStyle];
        te = TableEntry(p);
        te.ColSpan = 2;
        append(tr3, te);
        append(table7,tr3);
        
        % Add statistic data to table
        tr4 = TableRow;
        p = Paragraph('XS Avg');            % For vertical labels
        p.Style = [p.Style mainHeaderTextStyle];
        te = TableEntry(p);
        te.Style = {Width('1in')};
        append(tr4, te);
        p = Paragraph(num2str(T.Depth(i+j)));   % Depth
        te = TableEntry(p);
        te.Style = {Width('1in')};
        append(tr4, te);
        p = Paragraph(num2str(T.Height(i+j)));   % Height
        te = TableEntry(p);
        te.Style = {Width('1in')};
        append(tr4, te);
        p = Paragraph('XS Avg');            % For vertical labels
        p.Style = [p.Style mainHeaderTextStyle];
        te = TableEntry(p);
        te.Style = {Width('1in')};
        append(tr4, te);
        p = Paragraph(num2str(T.Diameter(i+j)));   % Diameter
        te = TableEntry(p);
        te.Style = {Width('1.2in')};
        append(tr4, te);
        p = Paragraph('Left');              % For vertical labels
        p.Style = [p.Style mainHeaderTextStyle];
        te = TableEntry(p);
        te.Style = {Width('1in')};
        append(tr4, te);
        p = Paragraph(num2str(T.MidwallWidthL(i+j)));   % L MW Width
        te = TableEntry(p);
        te.Style = {Width('1in')};
        append(tr4, te);
        append(table7,tr4);
        
        % 2020.11.17 Add expanded statistics data to table
        tr5 = TableRow;
        p = Paragraph('XS Max');            % For vertical labels
        p.Style = [p.Style mainHeaderTextStyle];
        te = TableEntry(p);
        te.Style = {Width('1in')};
        append(tr5, te);
        p = Paragraph(num2str(T.Depth3(i+j)));   % XS Max Depth
        te = TableEntry(p);
        te.Style = {Width('1in')};
        append(tr5, te);
        p = Paragraph(num2str(T.Height3(i+j)));  % XS Max Height
        te = TableEntry(p);
        te.Style = {Width('1in')};
        append(tr5, te);
        p = Paragraph('Major');             % For vertical labels
        p.Style = [p.Style mainHeaderTextStyle];
        te = TableEntry(p);
        te.Style = {Width('1in')};
        append(tr5, te);
        p = Paragraph(num2str(T.MajorAxis(i+j)));  % Major Axis
        te = TableEntry(p);
        te.Style = {Width('1.2in')};
        append(tr5, te);
        p = Paragraph('Right');             % For vertical labels
        p.Style = [p.Style mainHeaderTextStyle];
        te = TableEntry(p);
        te.Style = {Width('1in')};
        append(tr5, te);
        p = Paragraph(num2str(T.MidwallWidthR(i+j)));   % L MW Width
        te = TableEntry(p);
        te.Style = {Width('1in')};
        append(tr5, te);
        append(table7,tr5);
        
        tr6 = TableRow;
        p = Paragraph('Global Max');        % For vertical labels
        p.Style = [p.Style mainHeaderTextStyle];
        te = TableEntry(p);
        te.Style = {Width('1in')};
        append(tr6, te);
        p = Paragraph(num2str(T.DepthAbs(i+j)));   % Abs Depth
        te = TableEntry(p);
        te.Style = {Width('1in')};
        append(tr6, te);
        p = Paragraph(num2str(T.HeightAbs(i+j)));  % Abs Height
        te = TableEntry(p);
        te.Style = {Width('1in')};
        append(tr6, te);
        p = Paragraph('Minor');            % For vertical labels
        p.Style = [p.Style mainHeaderTextStyle];
        te = TableEntry(p);
        te.Style = {Width('1in')};
        append(tr6, te);
        p = Paragraph(num2str(T.MinorAxis(i+j))); % Minor Axis
        te = TableEntry(p);
        te.Style = {Width('1.2in')};
        append(tr6, te);
        p = Paragraph('Avg');              % For vertical labels
        p.Style = [p.Style mainHeaderTextStyle];
        te = TableEntry(p);
        te.Style = {Width('1in')};
        append(tr6, te);
        p = Paragraph(num2str(nanmean([T.MidwallWidthL(i+j),T.MidwallWidthR(i+j)])));   % Avg MW Width
        te = TableEntry(p);
        te.Style = {Width('1in')};
        append(tr6, te);
        append(table7,tr6);
        add(ChapterX,table7);
    end
end

add(R,ChapterX);

%% Add Ninth Chapter with Statistics Table Only
ChapterX = Chapter();
ChapterX.Title = 'Summary Statistics';

t8 = Table(6);
%t7.Style = {OuterMargin('-0.3in')};
t8.TableEntriesStyle = {FontFamily('Arial'),Width('1in')};

% Add statistic labels to table
tr = TableRow;
p = Paragraph('Label');
te = TableEntry(p);
append(tr, te);
if size(T,2) == 14
    p = Paragraph('Type');
    te = TableEntry(p);
    append(tr, te);
end
p = Paragraph('Depth');
te = TableEntry(p);
append(tr, te);
p = Paragraph('Diameter');
te = TableEntry(p);
append(tr, te);
p = Paragraph('Height');
te = TableEntry(p);
append(tr, te);
p = Paragraph('L Width');
te = TableEntry(p);
append(tr, te);
p = Paragraph('R Width');
te = TableEntry(p);
append(tr, te);
append(t8,tr);

for i = 1:size(T,1)
    % Add statistic data to table
    tr = TableRow;
    p = Paragraph(num2str(T{i,1}));
    te = TableEntry(p);
    te.Style = {Width('0.2in')};
    append(tr, te);
    if any(strcmp('poreTypes',T.Properties.VariableNames))
        switch T.poreTypes{i}    %Updated 03.05.19 to change from number type to written
            case 2
                type = 'Ring';
            case 3
                type = 'Slit';
            case 4
                type = 'Arc';
        end
        p = Paragraph(type);
        te = TableEntry(p);
        te.Style = {Width('0.2in')};
        append(tr, te);
    end
    p = Paragraph(num2str(T{i,2}));
    te = TableEntry(p);
    te.Style = {Width('0.9in')};
    append(tr, te);
    p = Paragraph(num2str(T{i,3}));
    te = TableEntry(p);
    te.Style = {Width('1in')};
    append(tr, te);
    p = Paragraph(num2str(T{i,4}));
    te = TableEntry(p);
    te.Style = {Width('1in')};
    append(tr, te);
    p = Paragraph(num2str(T{i,5}));
    te = TableEntry(p);
    te.Style = {Width('1in')};
    append(tr, te);
    p = Paragraph(num2str(T{i,6}));
    te = TableEntry(p);
    te.Style = {Width('1in')};
    append(tr, te);
    append(t8,tr);
end

add(ChapterX,t8);
add(R,ChapterX);

%% Surface Coverage Summary
% Add Tenth Chapter with Surface Coverage Statistics Table Only
chapter9 = Chapter();
chapter9.Title = 'Coverage Statistics';

t9 = Table(9);
%t7.Style = {OuterMargin('-0.3in')};
t9.TableEntriesStyle = {FontFamily('Arial'),Width('1in')};

% Add statistic labels to table
tr = TableRow;
p = Paragraph('Image');
te = TableEntry(p);
te.Style = {Width('2.5in')};
append(tr, te);
p = Paragraph(num2str(Tcov{1}));
te = TableEntry(p);
te.Style = {Width('4.5in')};
append(tr, te);
append(t9,tr);

tr = TableRow;
p = Paragraph('Group');
te = TableEntry(p);
te.Style = {Width('2.5in')};
append(tr, te);
p = Paragraph(num2str(Tcov{2}));
te = TableEntry(p);
te.Style = {Width('4.5in')};
append(tr, te);
append(t9,tr);

tr = TableRow;
p = Paragraph('Num Objects');
te = TableEntry(p);
te.Style = {Width('2.5in')};
append(tr, te);
p = Paragraph(num2str(Tcov{3}));
te = TableEntry(p);
te.Style = {Width('4.5in')};
append(tr, te);
append(t9,tr);

tr = TableRow;
p = Paragraph('Isolated Low Coverage');
te = TableEntry(p);
te.Style = {Width('2.5in')};
append(tr, te);
p = Paragraph([num2str(round(Tcov{4}.*100,2)),'%']);
te = TableEntry(p);
te.Style = {Width('4.5in')};
append(tr, te);
append(t9,tr);

tr = TableRow;
p = Paragraph('Low Coverage');
te = TableEntry(p);
te.Style = {Width('2.5in')};
append(tr, te);
p = Paragraph([num2str(round(Tcov{7}.*100,2)),'%']);
te = TableEntry(p);
te.Style = {Width('4.5in')};
append(tr, te);
append(t9,tr);

tr = TableRow;
p = Paragraph('High Coverage');
te = TableEntry(p);
te.Style = {Width('2.5in')};
append(tr, te);
p = Paragraph([num2str(round(Tcov{8}.*100,2)),'%']);
te = TableEntry(p);
te.Style = {Width('4.5in')};
append(tr, te);
append(t9,tr);

tr = TableRow;
p = Paragraph('Aggregate Coverage');
te = TableEntry(p);
te.Style = {Width('2.5in')};
append(tr, te);
p = Paragraph([num2str(round(Tcov{9}.*100,2)),'%']);
te = TableEntry(p);
te.Style = {Width('4.5in')};
append(tr, te);
append(t9,tr);

tr = TableRow;
p = Paragraph('All Coverage');
te = TableEntry(p);
te.Style = {Width('2.5in')};
append(tr, te);
p = Paragraph([num2str(round(Tcov{10}.*100,2)),'%']);
te = TableEntry(p);
te.Style = {Width('4.5in')};
append(tr, te);
append(t9,tr);

add(chapter9,t9);
add(R,chapter9);

%% Paramter Summary
if ~exist('app','var')
    % Add Final Chapter summarizing image analysis parameters
    ChapterX = Chapter();
    ChapterX.Title = 'Analysis Parameters';
    
    t9 = Table(9);
    %t7.Style = {OuterMargin('-0.3in')};
    t9.TableEntriesStyle = {FontFamily('Arial'),Width('1in')};
    
    % Add statistic labels to table
    tr = TableRow;
    p = Paragraph('Image');
    te = TableEntry(p);
    te.Style = {Width('2.5in')};
    append(tr, te);
    p = Paragraph(num2str(Tcov{1}));
    te = TableEntry(p);
    te.Style = {Width('4.5in')};
    append(tr, te);
    append(t9,tr);
    
    tr = TableRow;
    p = Paragraph('Group');
    te = TableEntry(p);
    te.Style = {Width('2.5in')};
    append(tr, te);
    p = Paragraph(num2str(Tcov{2}));
    te = TableEntry(p);
    te.Style = {Width('4.5in')};
    append(tr, te);
    append(t9,tr);
    
    tr = TableRow;
    p = Paragraph('Analysis Type');
    te = TableEntry(p);
    te.Style = {Width('2.5in')};
    append(tr, te);
    p = Paragraph(app.AnalysisType.Value);
    te = TableEntry(p);
    te.Style = {Width('4.5in')};
    append(tr, te);
    append(t9,tr);
    
    tr = TableRow;
    p = Paragraph('Oligo Max Height [nm]');
    te = TableEntry(p);
    te.Style = {Width('2.5in')};
    append(tr, te);
    p = Paragraph(num2str(app.OligoMaxHeight.Value));
    te = TableEntry(p);
    te.Style = {Width('4.5in')};
    append(tr, te);
    append(t9,tr);
    
    tr = TableRow;
    p = Paragraph('Protein Max Height [nm]');
    te = TableEntry(p);
    te.Style = {Width('2.5in')};
    append(tr, te);
    p = Paragraph(num2str(app.ProteinMaxHeight.Value));
    te = TableEntry(p);
    te.Style = {Width('4.5in')};
    append(tr, te);
    append(t9,tr);
    
    tr = TableRow;
    p = Paragraph('Small Size Filter [nm2]');
    te = TableEntry(p);
    te.Style = {Width('2.5in')};
    append(tr, te);
    p = Paragraph(num2str(app.SmallSizeFilter.Value));
    te = TableEntry(p);
    te.Style = {Width('4.5in')};
    append(tr, te);
    append(t9,tr);
    
    tr = TableRow;
    p = Paragraph('Large Size Filter [nm2]');
    te = TableEntry(p);
    te.Style = {Width('2.5in')};
    append(tr, te);
    p = Paragraph(num2str(app.LargeSizeFilter.Value));
    te = TableEntry(p);
    te.Style = {Width('4.5in')};
    append(tr, te);
    append(t9,tr);
    
    tr = TableRow;
    p = Paragraph('Max Major Axis [nm]');
    te = TableEntry(p);
    te.Style = {Width('2.5in')};
    append(tr, te);
    p = Paragraph(num2str(app.MaxMajorAxis.Value));
    te = TableEntry(p);
    te.Style = {Width('4.5in')};
    append(tr, te);
    append(t9,tr);
    
    tr = TableRow;
    p = Paragraph('Min Circularity [-]');
    te = TableEntry(p);
    te.Style = {Width('2.5in')};
    append(tr, te);
    p = Paragraph(num2str(app.MinCircularity.Value));
    te = TableEntry(p);
    te.Style = {Width('4.5in')};
    append(tr, te);
    append(t9,tr);
    
    tr = TableRow;
    p = Paragraph('Use Pore Types');
    te = TableEntry(p);
    te.Style = {Width('2.5in')};
    append(tr, te);
    p = Paragraph(num2str(app.UsePoreTypes.Value));
    te = TableEntry(p);
    te.Style = {Width('4.5in')};
    append(tr, te);
    append(t9,tr);
    
    tr = TableRow;
    p = Paragraph('Use Old Flattening');
    te = TableEntry(p);
    te.Style = {Width('2.5in')};
    append(tr, te);
    p = Paragraph(num2str(app.UseOldFlattening.Value));
    te = TableEntry(p);
    te.Style = {Width('4.5in')};
    append(tr, te);
    append(t9,tr);
    
    add(ChapterX,t9);
    add(R,ChapterX);
end

%% Save and open report
rptview(R);

end
