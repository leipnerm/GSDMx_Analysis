function GSDMx_reportGenerator_surfCov(file,outDirPrepend,Tcov)

%% Preface
%
% Copyright: Matthew Leipner
%
% * Original date:  2019.04.04
%
% * Last Updated:  2021.05.19
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

% p = Paragraph(['GSDMx coverage: ', num2str(round(Tcov{4}.*100,2)), '%']);
% add(chapter3,p);
% 
% im3 = FormalImage();
% im3.Image = [outDirPrepend,'/report_images/',file.name,'/',file.name,'_4_isolated.png'];
% im3.Caption = 'Isolated Objects';
% add(chapter3,im3);


add(R,chapter3);

% % Add Fourth Chapter on Binarized AFM Image
% chapter4 = Chapter();
% chapter4.Title = 'Binarized and Watershedded Image';
% im4 = FormalImage();
% im4.Image = [outDirPrepend,'/report_images/',file.name,'/',file.name,'_5_watershedded.png'];
% add(chapter4,im4);
% add(R,chapter4);

% ADDED 20210511: Add Fifth Chapter on overall Oligomer Coverage
chapter5 = Chapter();
chapter5.Title = 'Isolated Oligomers (within size, major axis, and height filters)';
im5 = FormalImage();
im5.Image = [outDirPrepend,'/report_images/',file.name,'/',file.name,'_7_poreCoverage.png'];
add(chapter5,im5);
add(R,chapter5);

% % ADDED 20210511: Add Sixth Chapter on Defect Coverage
% chapter6 = Chapter();
% chapter6.Title = 'Defect coverage (outside of size, major axis, and height filters)';
% im6 = FormalImage();
% im6.Image = [outDirPrepend,'/report_images/',file.name,'/',file.name,'_8_membraneDefects.png'];
% add(chapter6,im6);
% add(R,chapter6);

% ADDED 20210511: Add Seventh Chapter on all "Low Coverage" and "High Coverage" Coverage
% Low Coverage first
chapter6 = Chapter();
chapter6.Title = 'Oligomer coverage filtered by Height';
im6 = FormalImage();
im6.Image = [outDirPrepend,'/report_images/',file.name,'/',file.name,'_9_lowCoverage.png'];
im6.Caption = 'Low Coverage (below oligomerMaxHeight filter; currently 4nm)';
add(chapter6,im6);

p = Paragraph(['GSDMx Low Coverage: ', num2str(round(Tcov{7}.*100,2)), '%']);
add(chapter6,p);

% Then high Coverage
im7 = FormalImage();
im7.Image = [outDirPrepend,'/report_images/',file.name,'/',file.name,'_10a_highCoverage.png'];
im7.Caption = 'High Coverage (above oligoMaxHeight and below proteinMaxHeight filter; currently between 4-9nm)';
add(chapter6,im7);

p = Paragraph(['GSDMx High Coverage: ', num2str(round(Tcov{8}.*100,2)), '%']);
add(chapter6,p);

% Then aggregate Coverage
im8 = FormalImage();
im8.Image = [outDirPrepend,'/report_images/',file.name,'/',file.name,'_10b_aggregateCoverage.png'];
im8.Caption = 'Aggregate Coverage (above proteinMaxHeight filter; currently above 9nm)';
add(chapter6,im8);

p = Paragraph(['GSDMx Aggregate Coverage: ', num2str(round(Tcov{9}.*100,2)), '%']);
add(chapter6,p);

% Then all Coverage
im9 = FormalImage();
im9.Image = [outDirPrepend,'/report_images/',file.name,'/',file.name,'_11_allCoverage.png'];
im9.Caption = 'All Coverage (low, high, and aggregate together)';
add(chapter6,im9);

p = Paragraph(['GSDMx All coverage: ', num2str(round(Tcov{10}.*100,2)), '%']);
add(chapter6,p);

add(R,chapter6);

% Add Eight Chapter with Surface Coverage Statistics Table Only
chapter8 = Chapter();
chapter8.Title = 'Summary Statistics';

t8 = Table(9);
%t7.Style = {OuterMargin('-0.3in')};
t8.TableEntriesStyle = {FontFamily('Arial'),Width('1in')};

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
append(t8,tr);

tr = TableRow;
p = Paragraph('Group');
te = TableEntry(p);
te.Style = {Width('2.5in')};
append(tr, te);
p = Paragraph(num2str(Tcov{2}));
te = TableEntry(p);
te.Style = {Width('4.5in')};
append(tr, te);
append(t8,tr);

tr = TableRow;
p = Paragraph('Num Objects');
te = TableEntry(p);
te.Style = {Width('2.5in')};
append(tr, te);
p = Paragraph(num2str(Tcov{3}));
te = TableEntry(p);
te.Style = {Width('4.5in')};
append(tr, te);
append(t8,tr);

tr = TableRow;
p = Paragraph('Isolated Low Coverage');
te = TableEntry(p);
te.Style = {Width('2.5in')};
append(tr, te);
p = Paragraph([num2str(round(Tcov{4}.*100,2)),'%']);
te = TableEntry(p);
te.Style = {Width('4.5in')};
append(tr, te);
append(t8,tr);

% tr = TableRow;
% p = Paragraph('Num Defects');
% te = TableEntry(p);
% te.Style = {Width('2.5in')};
% append(tr, te);
% p = Paragraph(num2str(Tcov{5}));
% te = TableEntry(p);
% te.Style = {Width('4.5in')};
% append(tr, te);
% append(t8,tr);

% tr = TableRow;
% p = Paragraph('Defect Coverage');
% te = TableEntry(p);
% te.Style = {Width('2.5in')};
% append(tr, te);
% p = Paragraph([num2str(round(Tcov{6}.*100,2)),'%']);
% te = TableEntry(p);
% te.Style = {Width('4.5in')};
% append(tr, te);
% append(t8,tr);

tr = TableRow;
p = Paragraph('Low Coverage');
te = TableEntry(p);
te.Style = {Width('2.5in')};
append(tr, te);
p = Paragraph([num2str(round(Tcov{7}.*100,2)),'%']);
te = TableEntry(p);
te.Style = {Width('4.5in')};
append(tr, te);
append(t8,tr);

tr = TableRow;
p = Paragraph('High Coverage');
te = TableEntry(p);
te.Style = {Width('2.5in')};
append(tr, te);
p = Paragraph([num2str(round(Tcov{8}.*100,2)),'%']);
te = TableEntry(p);
te.Style = {Width('4.5in')};
append(tr, te);
append(t8,tr);

tr = TableRow;
p = Paragraph('Aggregate Coverage');
te = TableEntry(p);
te.Style = {Width('2.5in')};
append(tr, te);
p = Paragraph([num2str(round(Tcov{9}.*100,2)),'%']);
te = TableEntry(p);
te.Style = {Width('4.5in')};
append(tr, te);
append(t8,tr);

tr = TableRow;
p = Paragraph('All Coverage');
te = TableEntry(p);
te.Style = {Width('2.5in')};
append(tr, te);
p = Paragraph([num2str(round(Tcov{10}.*100,2)),'%']);
te = TableEntry(p);
te.Style = {Width('4.5in')};
append(tr, te);
append(t8,tr);

% for i = 1:size(Tcov,1)
%     % Add statistic data to table
%     tr = TableRow;
%     p = Paragraph(num2str(Tcov{1}));
%     te = TableEntry(p);
%     te.Style = {Width('1in')};
%     append(tr, te);
%     p = Paragraph(num2str(Tcov{2}));
%     te = TableEntry(p);
%     te.Style = {Width('0.9in')};
%     append(tr, te);
%     p = Paragraph(num2str(Tcov{3}));
%     te = TableEntry(p);
%     te.Style = {Width('0.2in')};
%     append(tr, te);
%     p = Paragraph(num2str(round(Tcov{4}.*100,2)));
%     te = TableEntry(p);
%     te.Style = {Width('0.5in')};
%     append(tr, te);
%     p = Paragraph(num2str(Tcov{5}));
%     te = TableEntry(p);
%     te.Style = {Width('1in')};
%     append(tr, te);
%     p = Paragraph(num2str(round(Tcov{6}.*100,2)));
%     te = TableEntry(p);
%     te.Style = {Width('1in')};
%     append(tr, te);
%     p = Paragraph(num2str(round(Tcov{7}.*100,2)));
%     te = TableEntry(p);
%     te.Style = {Width('1in')};
%     append(tr, te);
%     p = Paragraph(num2str(round(Tcov{8}.*100,2)));
%     te = TableEntry(p);
%     te.Style = {Width('1in')};
%     append(tr, te);
%     p = Paragraph(num2str(round(Tcov{9}.*100,2)));
%     te = TableEntry(p);
%     te.Style = {Width('1in')};
%     append(tr, te);
%     append(t8,tr);
% end

add(chapter8,t8);
add(R,chapter8);

% Save and open report
rptview(R);

end
