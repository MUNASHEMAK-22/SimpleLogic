daq.getVendors
daq.getDevices
%% FPGA FIFO Data Logger via NI USB-6002 with Real-Time Plot
% Features:
% - Reads FIFO data (4-bit) from FPGA via NI USB-6002
% - Uses NI digital outputs to send trigger signal and pulse fifo_rd
% - Real-time plot of collected data
% - Logs to file continuously for X minutes or until manually stopped
% - Appends new sessions to file (no overwrite)

clear; clc; close all;

%% User Parameters
deviceID = 'Dev1';            % Change to your NI device name
logFile = 'fpga_log.txt';     % Log file (data will be appended)
duration_minutes = 5;         % Total logging time
pulse_width_sec = 0.002;      % FIFO_RD pulse width (2 ms)
sample_delay_sec = 0.002;     % Delay after pulse before reading data

%% NI Session Setup
s = daq.createSession('ni');

% Digital Inputs: FIFO Data (4 bits) + fifo_full + fifo_empty
addDigitalChannel(s, deviceID, 'Port0/Line0:5', 'InputOnly');

% Digital Outputs: fifo_rd (Line6) + trigger_out (Line7)
addDigitalChannel(s, deviceID, 'Port0/Line6:7', 'OutputOnly');

disp('NI channels configured:');
disp(s.Channels);

%% Initialize outputs (fifo_rd=0, trigger_out=0)
outputSingleScan(s, [0 0]);

%% Open log file (append mode)
fid = fopen(logFile, 'a');
if fid == -1
    error('Cannot open log file for writing.');
end
fprintf(fid, '--- New Logging Session: %s ---\n', datestr(now));

%% Real-Time Plot Setup
figure('Name','FPGA FIFO Real-Time Plot','NumberTitle','off');
hPlot = plot(nan, nan, '-o', 'LineWidth', 1.5);
xlabel('Sample Index'); ylabel('Counter Value');
title('Real-Time FPGA Counter Data');
grid on;
xlim([0 100]); ylim([0 15]); % 4-bit counter max is 15

%% Start Logging
disp('Starting logging...');
start_time = tic;
collected_data = [];

while toc(start_time) < duration_minutes * 60
    % Send trigger HIGH (enable FPGA counting)
    outputSingleScan(s, [0 1]); % fifo_rd=0, trigger_out=1

    % Read FIFO status
    scan = inputSingleScan(s);
    fifo_empty = scan(6);  % index starts at 1, so 6th bit = P0.5

    if ~fifo_empty
        % Pulse fifo_rd
        outputSingleScan(s, [1 1]); % fifo_rd=1, trigger=1
        pause(pulse_width_sec);
        outputSingleScan(s, [0 1]); % fifo_rd=0, trigger=1

        % Wait briefly, then read FIFO data
        pause(sample_delay_sec);
        scan = inputSingleScan(s);
        data_bits = scan(1:4);
        value = bi2de(data_bits, 'right-msb');

        % Append data
        collected_data(end+1) = value; %#ok<AGROW>
        fprintf(fid, '%d\n', value);

        % Update real-time plot
        set(hPlot, 'XData', 1:length(collected_data), 'YData', collected_data);
        drawnow;

        % Auto-adjust x-axis
        if length(collected_data) > 100
            xlim([length(collected_data)-100, length(collected_data)+10]);
        end
    end

    % Small delay to reduce CPU usage
    pause(0.005);
end

% Stop FPGA counting
outputSingleScan(s, [0 0]); % fifo_rd=0, trigger=0

%% Cleanup
fclose(fid);
disp('Logging complete.');
disp(['Total samples collected: ' num2str(length(collected_data))]);

% Save data for MATLAB analysis
save('fpga_data.mat', 'collected_data');
