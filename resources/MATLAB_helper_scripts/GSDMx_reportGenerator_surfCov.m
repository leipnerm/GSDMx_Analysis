function GSDMx_reportGenerator_surfCov(file,outDirPrepend,Tcov)

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
tp.Subtitle = sprintf('Analysis of %s',file.name);
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

p = Paragraph(['GSDMx coverage: ', num2str(round(Tcov{4}.*100,2)), '%']);
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

% ADDED 20210511: Add Fifth Chapter on overall Oligomer Coverage
chapter5 = Chapter();
chapter5.Title = 'Individual Oligomers (within size, major axis, and height filters)';
im5 = FormalImage();
im5.Image = [outDirPrepend,'/report_images/',file.name,'/',file.name,'_7_poreCoverage.png'];
add(chapter5,im5);
add(R,chapter5);

% ADDED 20210511: Add Sixth Chapter on Defect Coverage
chapter6 = Chapter();
chapter6.Title = 'Defect coverage (outside of size, major axis, and height filters)';
im6 = FormalImage();
im6.Image = [outDirPrepend,'/report_images/',file.name,'/',file.name,'_8_membraneDefects.png'];
add(chapter6,im6);
add(R,chapter6);

% ADDED 20210511: Add Seventh Chapter on all "Low Stuff" and "High Stuff" Coverage
% Low stuff first
chapter6 = Chapter();
chapter6.Title = 'Oligomer coverage filtered by Height';
im6 = FormalImage();
im6.Image = [outDirPrepend,'/report_images/',file.name,'/',file.name,'_9_lowStuff.png'];
im6.Caption = 'Low stuff coverage (below height filter)';
add(chapter6,im6);

p = Paragraph(['GSDMx Low Stuff coverage: ', num2str(round(Tcov{7}.*100,2)), '%']);
add(chapter6,p);

% Then high stuff
im7 = FormalImage();
im7.Image = [outDirPrepend,'/report_images/',file.name,'/',file.name,'_10_highStuff.png'];
im7.Caption = 'High stuff coverage (above height filter)';
add(chapter6,im7);

p = Paragraph(['GSDMx High Stuff coverage: ', num2str(round(Tcov{8}.*100,2)), '%']);
add(chapter6,p);

% Then all stuff
im8 = FormalImage();
im8.Image = [outDirPrepend,'/report_images/',file.name,'/',file.name,'_11_allStuff.png'];
im8.Caption = 'All stuff coverage (high and low together)';
add(chapter6,im8);

p = Paragraph(['GSDMx All coverage: ', num2str(round(Tcov{9}.*100,2)), '%']);
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
p = Paragraph('Isolated Surface Coverage');
te = TableEntry(p);
te.Style = {Width('2.5in')};
append(tr, te);
p = Paragraph([num2str(round(Tcov{4}.*100,2)),'%']);
te = TableEntry(p);
te.Style = {Width('4.5in')};
append(tr, te);
append(t8,tr);

tr = TableRow;
p = Paragraph('Num Defects');
te = TableEntry(p);
te.Style = {Width('2.5in')};
append(tr, te);
p = Paragraph(num2str(Tcov{5}));
te = TableEntry(p);
te.Style = {Width('4.5in')};
append(tr, te);
append(t8,tr);

tr = TableRow;
p = Paragraph('Defect Coverage');
te = TableEntry(p);
te.Style = {Width('2.5in')};
append(tr, te);
p = Paragraph([num2str(round(Tcov{6}.*100,2)),'%']);
te = TableEntry(p);
te.Style = {Width('4.5in')};
append(tr, te);
append(t8,tr);

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
p = Paragraph('All Coverage');
te = TableEntry(p);
te.Style = {Width('2.5in')};
append(tr, te);
p = Paragraph([num2str(round(Tcov{9}.*100,2)),'%']);
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
