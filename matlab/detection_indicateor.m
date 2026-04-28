load('result_file_name_out.mat');
% Extract the PassiveRecordCount
passiveRecordCount = data.passiveRecordCount;
%disp(passiveRecordCount);
first_results = passiveRecordCount{1}(:,:,end); 
disp(first_results)