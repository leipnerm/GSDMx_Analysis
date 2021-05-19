function GSDMx_reportGenerator(file,outDirPrepend,T,surfCov)

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
chapter1 = Chapter();
chapter1.Title = 'Raw AFM Image';
im1 = FormalImage();
im1.Image = [outDirPrepend,'/report_images/',file.name,'/',file.name,'_1_raw.png'];
%im1.Caption = 'Unflattened AFM Image';
add(chapter1,im1);
add(R,chapter1);

% Add Second Chapter on Flattened AFM Image
chapter2 = Chapter();
chapter2.Title = 'Flattened AFM Image';
im2 = FormalImage();
im2.Image = [outDirPrepend,'/report_images/',file.name,'/',file.name,'_2_flat.png'];
%im2.Caption = 'Flattened AFM Image';
add(chapter2,im2);
add(R,chapter2);

% Add Third Chapter on all and isolated objects
chapter3 = Chapter();
chapter3.Title = 'All and Isolated Objects';
im3 = FormalImage();
im3.Image = [outDirPrepend,'/report_images/',file.name,'/',file.name,'_3_all.png'];
im3.Caption = 'All Objects';
add(chapter3,im3);

p = Paragraph(['GSDMx coverage: ', num2str(round(surfCov.*100,2)), '%']);
add(chapter3,p);

im3 = FormalImage();
im3.Image = [outDirPrepend,'/report_images/',file.name,'/',file.name,'_4_isolated.png'];
im3.Caption = 'Isolated Objects';
add(chapter3,im3);


add(R,chapter3);

% Add Fourth Chapter on Binarized AFM Image
chapter4 = Chapter();
chapter4.Title = 'Binarized and Watershedded Image';
im4 = FormalImage();
im4.Image = [outDirPrepend,'/report_images/',file.name,'/',file.name,'_5_watershedded.png'];
add(chapter4,im4);
add(R,chapter4);

% Add Fifth Chapter on Labeled AFM Image
chapter5 = Chapter();
chapter5.Title = 'Labeled Image';
im5 = FormalImage();
im5.Image = [outDirPrepend,'/report_images/',file.name,'/',file.name,'_12_labeled.png'];
add(chapter5,im5);
add(R,chapter5);

% 2020.11.17 Add Sixth Chapter on Pore Analysis
chapter6 = Chapter();
chapter6.Title = 'Major/Minor Axis Labeled Image';
im6 = FormalImage();
im6.Image = [outDirPrepend,'/report_images/',file.name,'/',file.name,'_6_axis.png'];
add(chapter6,im6);
add(R,chapter6);


% Add Seventh Chapter on Pore Analysis
chapter7 = Chapter();
chapter7.Title = 'Individual Oligomer Analysis';

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
        if size(T,2) == 14      % Updated 2020.11.17 for added stats
            switch T{i+j,13}    %Updated 03.05.19 to change from number type to written
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
        if size(T,2) == 14
            p = Paragraph('Orig. Label');
            te = TableEntry(p);
            te.ColSpan = 1;
            append(tr0, te);
            p = Paragraph(num2str(T{i+j,14}));
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
        p = Paragraph(num2str(T{i+j,2}));   % Depth
        te = TableEntry(p);
        te.Style = {Width('1in')};
        append(tr4, te);
        p = Paragraph(num2str(T{i+j,4}));   % Height
        te = TableEntry(p);
        te.Style = {Width('1in')};
        append(tr4, te);
        p = Paragraph('XS Avg');            % For vertical labels
        p.Style = [p.Style mainHeaderTextStyle];
        te = TableEntry(p);
        te.Style = {Width('1in')};
        append(tr4, te);
        p = Paragraph(num2str(T{i+j,3}));   % Diameter
        te = TableEntry(p);
        te.Style = {Width('1.2in')};
        append(tr4, te);
        p = Paragraph('Left');              % For vertical labels
        p.Style = [p.Style mainHeaderTextStyle];
        te = TableEntry(p);
        te.Style = {Width('1in')};
        append(tr4, te);
        p = Paragraph(num2str(T{i+j,5}));   % L MW Width
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
        p = Paragraph(num2str(T{i+j,8}));   % XS Max Depth
        te = TableEntry(p);
        te.Style = {Width('1in')};
        append(tr5, te);
        p = Paragraph(num2str(T{i+j,10}));  % XS Max Height
        te = TableEntry(p);
        te.Style = {Width('1in')};
        append(tr5, te);
        p = Paragraph('Major');             % For vertical labels
        p.Style = [p.Style mainHeaderTextStyle];
        te = TableEntry(p);
        te.Style = {Width('1in')};
        append(tr5, te);
        p = Paragraph(num2str(T{i+j,11}));  % Major Axis
        te = TableEntry(p);
        te.Style = {Width('1.2in')};
        append(tr5, te);
        p = Paragraph('Right');             % For vertical labels
        p.Style = [p.Style mainHeaderTextStyle];
        te = TableEntry(p);
        te.Style = {Width('1in')};
        append(tr5, te);
        p = Paragraph(num2str(T{i+j,6}));   % L MW Width
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
        p = Paragraph(num2str(T{i+j,7}));   % Abs Depth
        te = TableEntry(p);
        te.Style = {Width('1in')};
        append(tr6, te);
        p = Paragraph(num2str(T{i+j,9}));  % Abs Height
        te = TableEntry(p);
        te.Style = {Width('1in')};
        append(tr6, te);
        p = Paragraph('Minor');            % For vertical labels
        p.Style = [p.Style mainHeaderTextStyle];
        te = TableEntry(p);
        te.Style = {Width('1in')};
        append(tr6, te);
        p = Paragraph(num2str(T{i+j,12})); % Minor Axis
        te = TableEntry(p);
        te.Style = {Width('1.2in')};
        append(tr6, te);
        p = Paragraph('Avg');              % For vertical labels
        p.Style = [p.Style mainHeaderTextStyle];
        te = TableEntry(p);
        te.Style = {Width('1in')};
        append(tr6, te);
        p = Paragraph(num2str(nanmean([T{i+j,5},T{i+j,6}])));   % Avg MW Width
        te = TableEntry(p);
        te.Style = {Width('1in')};
        append(tr6, te);
        append(table7,tr6);
        add(chapter7,table7);
    end
end

add(R,chapter7);

% Add Eight Chapter with Statistics Table Only
chapter8 = Chapter();
chapter8.Title = 'Summary Statistics';

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
    if size(T,2) == 14
        switch T{i,13}    %Updated 03.05.19 to change from number type to written
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

add(chapter8,t8);
add(R,chapter8);

% Save and open report
rptview(R);

end
