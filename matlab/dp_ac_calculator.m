load('result_file_name_out.mat');

% Extract the PassiveRecordCount
passiveRecordCount = data.passiveRecordCount;

% Extract the final snapshot (end of simulation) for all repeats
final_results = passiveRecordCount{1}(:,:,end);

% Define total number of repeats and biomarkers
num_repeats = size(final_results, 1);   % Number of rows = number of repeats
num_biomarkers = 3;                     % Total biomarkers per repeat

%% --- Detection Probability ---
num_detected = final_results(:, 3);
detection_probability = num_detected ./ num_biomarkers;
average_detection_probability = mean(detection_probability);

fprintf('✅ Average Detection Probability: %.2f%%\n', average_detection_probability * 100);

%% --- Activation Coverage ---
num_unhitted = final_results(:, 2);
num_hitted   = final_results(:, 3);
num_gossiped = final_results(:, 4);

num_activated = num_hitted + num_gossiped;
num_total_nanomachines = num_unhitted + num_hitted + num_gossiped;
activation_coverage = num_activated ./ num_total_nanomachines;
average_activation_coverage = mean(activation_coverage);

fprintf('✅ Average Activation Coverage: %.2f%%\n', average_activation_coverage * 100);

%% --- Plots ---

% Detection probability plot
figure;
plot(1:num_repeats, detection_probability, 'b-', 'LineWidth', 2);
xlabel('Repeat Number');
ylabel('Detection Probability');
title('Detection Probability per Repeat');
grid on;
xlim([1 num_repeats]);
ylim([0 1]);

% Add annotation for average value
text(num_repeats*0.7, 0.9, ...
    sprintf('Avg Pd = %.2f%%', average_detection_probability*100), ...
    'FontSize', 10, 'Color', 'b', 'FontWeight', 'bold');

% Activation coverage plot
figure;
plot(1:num_repeats, activation_coverage, 'r-', 'LineWidth', 2);
xlabel('Repeat Number');
ylabel('Activation Coverage');
title('Activation Coverage per Repeat');
grid on;
xlim([1 num_repeats]);
ylim([0 1]);

% Add annotation for average value
text(num_repeats*0.7, 0.9, ...
    sprintf('Avg Coverage = %.2f%%', average_activation_coverage*100), ...
    'FontSize', 10, 'Color', 'r', 'FontWeight', 'bold');
