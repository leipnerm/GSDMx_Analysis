%Author: Matthew Brukman, Engineering Physics Department, University of
%Wisconsin-Madison, 1500 Engineering Dr., Madison, WI 53706.
%This function/script is authorized for use in government and academic
%research laboratories and non-profit institutions only. Though this
%function has been tested prior to its posting, it may contain mistakes or
%require improvements. In exchange for use of this free product, we 
%request that its use and any issues that may arise be reported to us. 
%Comments and suggestions are therefore welcome and should be sent to 
%Prof. Robert Carpick &lt;carpick@engr.wisc.edu&gt;, Engineering Physics 
%Department, UW-Madison.
%Date posted: April 7, 2005
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function Data = getfd(file_name)

%These commands find the line numbers in the header file that contain
%the following info: # of pixels for each line,
% -- positions of the 1st pixel of data for each line,
% -- vertical scale factor of PSDvolts/bit,
% -- horizontal scale factor of nm/piezo volt,
% -- and size of piezo ramp in V. 

pos_spl = di_header_find(file_name,'\Samps/line');
pos_data = di_header_find(file_name,'\Data offset');
scal_data = di_header_find(file_name,'\@2:Z scale: V [Sens.');              % Updated 10.05.2021: old: '\@4:Z scale: V [Sens.'
%pos_senszscan =  di_header_find(file_name,'\@Sens. Zscan');
pos_ramp = di_header_find(file_name,'Ramp size Zsweep');
%pos_sensdef = di_header_find(file_name,'Sens. Deflection');

%Open the DI file, move to the various line numbers, and read the numbers
%therein to extact the values mentioned above.

fid = fopen(file_name,'r');
fseek( fid , pos_spl(2), -1 );
line = fgets(fid);
spl = extract_num(line);
line = fgets(fid);
linno = extract_num(line);
%fseek(fid, pos_senszscan, -1);
%line = fgets(fid);
senszscan = extract_num( line );
fseek(fid, pos_ramp, -1);
line = fgets(fid);
ramp = extract_num( line );
fseek(fid,pos_data(1),-1);
line = fgets(fid);
imag_pos = extract_num(line);   
fseek(fid,scal_data(1),-1);
line = fgets(fid);
scaling = extract_num(line);   

hscale = senszscan*ramp*2^16/spl;

% Go to 1st pixel data and start reading
fseek(fid,imag_pos,-1);
% Convert to PSD (normal force) volts
A = scaling*fread(fid,[1 2*spl] ,'int16');

%Split extend/retract data and convert to nm  
va = A(1:spl);
vr = A(spl+1:2*spl);
B = hscale*[1:spl]; 

%Define pulloff voltage as the difference between the minimum PSD voltage
%and the PSD signal a number of pixels later -- after transients have decayed
%Here number of pixels is chosen to be 1/75 of the total number of data points.
%If pulloff is close to the edge of the window, you may need a bigger
%number than 75. 

[minv, i] = min(vr);
Vpo = vr(i+round(spl/75))-minv;

%Create empty vector with same length as the ext/ret data
M = zeros(spl,1);
%Fit line to the contact region of retract trace
p= -polyfit( B(1:i), vr(1:i), 1);
%Put slope of line and pulloff voltage in zeros matrix
M(spl)= p(1);
M(spl-1)=Vpo;

%Create matrix with position [nm], Normal force/extending piezo [V], 
%Normal force/retracting piezo [V], slope [V/nm], and pulloff [V] data.
%Slope (the inverse of sens deflection) is the 1st element of column 4.
%Pulloff voltage is the 2nd.
Data = [B; va; vr; M'];
Data = rot90(Data);


