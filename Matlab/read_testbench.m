clc; clear; close all;

verilog_output_file = 'D:\Advanced_Topic\IIR_Filter\ecg_output.txt';
WL  = 40;          % word length (sfix40_En30)
FB  = 30;          % fractional bits (En30)
Fs  = 500;         % Hz

L = readlines(verilog_output_file);
L = strip(L);                        
L = L(L ~= "");                     
y_raw = str2double(L);               

bad = isnan(y_raw);
if any(bad)
    fprintf('Warning: Detected %d not invalid.\n', sum(bad));
    y_raw(bad) = [];                
end

if max(y_raw) > 2^(WL-1)-1
    y_signed = y_raw;
    over = y_raw >= 2^(WL-1);          
    y_signed(over) = y_raw(over) - 2^WL;
else
    y_signed = y_raw;               
end

y = double(y_signed) / 2^FB;

t = (0:numel(y)-1)/Fs;

figure;
plot(t, y, 'LineWidth', 1);
title('Output from Testbench');
xlabel('Time (s)');
ylabel('Amplitude (mV)');
grid on;

xlim([0 5]);