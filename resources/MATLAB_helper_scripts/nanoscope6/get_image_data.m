%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This code has been adapted from the ALEX toolbox and incorporated into this m-file. % The original free source code, which is copywritten by Claudio Rivetti and Mark Young % for ALEX is available at www.mathtools.net. % %This function/script is authorized for use in government and academic %research laboratories and non-profit institutions only. Though this %function has been tested prior to its posting, it may contain mistakes or %require improvements. In exchange for use of this free product, we %request that its use and any issues relating to it be reported to us. %Comments and suggestions are therefore welcome and should be sent to %Prof. Robert Carpick <carpick@engr.wisc.edu>, Engineering Physics %Department, UW-Madison. %Date posted: 7/8/2004 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function Data = get_image_data(file_name)

%file_name='C:\Briefcase\Parchment\AFM\Dimension\CR41\CR41.000';
scal_data = di_header_find(file_name,'\@2:Z scale: V [Sens.'); pos_spl = di_header_find(file_name,'\Samps');
pos_data = di_header_find(file_name,'\Data offset'); file_type_data = di_header_find(file_name,'Image Data:');


L = length(pos_data);

%image_position = ones(1,L);

fid = fopen(file_name,'r');
fseek(fid, pos_spl(1),-1);
line = fgets(fid);
spl = extract_num(line);
line = fgets(fid);
linno = extract_num(line);



for i = 1:L
   % figure
   fseek(fid,pos_data(i),-1);
   line = fgets(fid);
   imag_pos = extract_num(line);

   fseek(fid,scal_data(i),-1);
   line = fgets(fid);
   scaling = extract_num(line)

   fseek(fid,imag_pos,-1);
   A = fread(fid, [spl, linno],'int16');
   Data(:,:,i) = rot90(scaling*A);
   %image(Data(:,:,i));
   % fseek(fid,file_type_data(i),-1);
   % tl = fgetl(fid);
   % title(tl);
   % axis image;
end



fclose('all');




