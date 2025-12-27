clc; clear; close all;

%% Setup
dbDir   = 'D:\Advanced_Topic\PhysioNet\ecg-id-database-1.0.0';  
person  = 'Person_01';
record  = 'rec_2';     
secs    = 5;           

%% Filter params 
hp_fc   = 0.5;         % HPF baseline wander
hp_ord  = 3;
mains   = 50;          % Notch 50Hz
notch_Q = 30;
lp_fc   = 40;          % LPF 40Hz
lp_ord  = 4;

%% Read file
oldDir = pwd;
cd(fullfile(dbDir, person));
[ecg, Fs, tm] = rdsamp(record, [], secs*500); 
x = ecg(:,1);   
ecg_in = [tm, x];   

%% Export ECG Input
fileID = fopen('ecg_input.txt', 'w');
if fileID == -1
    error('Cant create file!');
else
    disp('File created successfully!');
end
% Scale fixed-point
x_scaled = x / max(abs(x));       
x_fixed = round(x_scaled * 2^22); 

for i = 1:length(x_fixed)
    fprintf(fileID, '%d\n', x_fixed(i));  
end

fclose(fileID);

%% Export Block Memory
WIDTH = 24;                    % độ rộng dữ liệu cho BRAM
FRAC  = 23;                    % số bit phần phân số của Q1.23
COE_FILE = 'ecg_input_24b.coe';

x_scaled = x / max(abs(x)+eps);       
max_pos  =  2^(WIDTH-1) - 1;         
min_neg  = -2^(WIDTH-1);               

x_fixed  = round(x_scaled * max_pos);  % Q1.23
x_fixed  = min(max(x_fixed, min_neg), max_pos);

u = uint32(mod(double(x_fixed), 2^WIDTH));

%% Write .coe
fid = fopen(COE_FILE,'w');
assert(fid~=-1, 'Không mở được file COE để ghi.');

fprintf(fid, 'memory_initialization_radix=16;\n');
fprintf(fid, 'memory_initialization_vector=\n');

N = numel(u);
for k = 1:N
    if k < N
        fprintf(fid, '%06X,\n', u(k));
    else
        fprintf(fid, '%06X;\n', u(k));  
    end
end
fclose(fid);

fprintf('Created %s with %d samples (24-bit HEX, Q1.%d).\n', COE_FILE, N, FRAC);


% DB Filtered
if size(ecg,2) >= 2
    x_filtered_db = ecg(:,2);
else
    x_filtered_db = [];
end
cd(oldDir);

%% IIR Filter
[b_hpE, a_hpE] = ellip(hp_ord, 1, 60, hp_fc/(Fs/2), 'high'); 
[b_lpE, a_lpE] = ellip(lp_ord, 1, 60, lp_fc/(Fs/2), 'low');

%% Notch filter (50 Hz)
wo = mains/(Fs/2); bw = wo/notch_Q;
[b_notch, a_notch] = iirnotch(wo, bw);

%% STEP BY STEP FILTERING 
y_notch = filtfilt(b_notch, a_notch, x);     
y_lp    = filtfilt(b_lpE, a_lpE, y_notch);   
y_hp    = filtfilt(b_hpE, a_hpE, y_lp);      


%%  MSE & SNR 
L = min(length(x_filtered_db), length(y_hp));
d = x_filtered_db(1:L);   
y = y_hp(1:L);           

% Mean Squared Error
MSE = mean((d - y).^2);

% Signal-to-Noise Ratio
SNR = 10*log10(sum(d.^2) / sum((d - y).^2));

fprintf('SNR, MSE of My filter vs Filter DB \n');
fprintf('MSE = %.6f\n', MSE);
fprintf('SNR = %.2f dB\n', SNR);
%% Cascade form - SOS

% === High-Pass Filter ===
[sos_hp, G_hp] = tf2sos(b_hpE, a_hpE);
sos_hp(1,1:3) = sos_hp(1,1:3) * G_hp;   
T_hp = array2table(sos_hp, ...
    'VariableNames', {'b0','b1','b2','a0','a1','a2'});
writetable(T_hp, 'hp_coeff.csv');

% === Low-Pass Filter ===
[sos_lp, G_lp] = tf2sos(b_lpE, a_lpE);
sos_lp(1,1:3) = sos_lp(1,1:3) * G_lp; 
T_lp = array2table(sos_lp, ...
    'VariableNames', {'b0','b1','b2','a0','a1','a2'});
writetable(T_lp, 'lp_coeff.csv');

% === Notch Filter (bậc 2, chỉ 1 biquad) ===
[sos_notch, G_notch] = tf2sos(b_notch, a_notch);
sos_notch(1,1:3) = sos_notch(1,1:3) * G_notch;   
T_notch = array2table(sos_notch, ...
    'VariableNames', {'b0','b1','b2','a0','a1','a2'});
writetable(T_notch, 'notch_coeff.csv');




