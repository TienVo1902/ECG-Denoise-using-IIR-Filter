clc; clear; close all;

Fs = 500;               
Ts = 1/Fs;           

%% Read ILA
opts = detectImportOptions('iladata.csv');
T = readtable('iladata.csv', opts);
T(1,:) = [];            

%% HEX to Signed DEC
% douta (24-bit)
douta_int = hex2dec(T.douta_wire_23_0_);
douta_int(douta_int >= 2^23) = douta_int(douta_int >= 2^23) - 2^24;

% filtered_ecg (40-bit)
filtered_int = hex2dec(T.filtered_ecg_wire_39_0_);
filtered_int(filtered_int >= 2^39) = filtered_int(filtered_int >= 2^39) - 2^40;

%% Fixed Point 
Q_in  = 23;   % sfix24_En23
Q_out = 30;   % sfix40_En30

douta_v    = double(douta_int) / (2^Q_in);
filtered_v = double(filtered_int) / (2^Q_out);

target_peak = 2e-3;  
scale_raw = target_peak / max(abs(douta_v));
scale_flt = target_peak / max(abs(filtered_v));

douta_mv    = douta_v * scale_raw * 1000;   
filtered_mv = filtered_v * scale_flt * 1000;  

N = length(douta_mv);
t = (0:N-1) * Ts;

figure('Name','ECG IIR Filter Result','NumberTitle','off');

subplot(2,1,1);
plot(t, douta_mv, 'b', 'LineWidth', 1.1);
xlabel('Time (s)');
ylabel('Amplitude (mV)');
title('ECG Raw');
grid on;
axis tight;

subplot(2,1,2);
plot(t, filtered_mv, 'r', 'LineWidth', 1.1);
xlabel('Time (s)');
ylabel('Amplitude (mV)');
title('Filtered ECG Signal (IIR Output)');
grid on;
axis tight;

title('ECG Filtered');
