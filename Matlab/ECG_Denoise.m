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

%% Time Domain
figure('Color','w');
subplot(4,1,1); plot(tm, x,'b'); grid on; title('ECG Raw');
xlabel('Time (s)'); ylabel('ECG (mV)');

subplot(4,1,2); plot(tm, y_notch,'m'); grid on; title('After Notch 50 Hz');
xlabel('Time (s)'); ylabel('mV');

subplot(4,1,3); plot(tm, y_lp,'g'); grid on; title('After LPF 40 Hz');
xlabel('Time (s)'); ylabel('mV');

subplot(4,1,4); plot(tm, y_hp,'r'); grid on; title('After HPF 0.5 Hz');
xlabel('Time (s)'); ylabel('mV');

linkaxes(findall(gcf,'Type','axes'),'x');

%% Frequency Domain
N  = length(x);
f  = (0:N-1)*(Fs/N);

X       = abs(fft(x));
Y_notch = abs(fft(y_notch));
Y_lp    = abs(fft(y_lp));
Y_hp    = abs(fft(y_hp));

ref = max(X);

XdB       = 20*log10(X/ref + eps);
YnotchdB  = 20*log10(Y_notch/ref + eps);
Ylp_dB    = 20*log10(Y_lp/ref + eps);
Yhp_dB    = 20*log10(Y_hp/ref + eps);

figure('Color','w');
subplot(4,1,1); plot(f, XdB);      xlim([0 80]); grid on; title('Raw ECG Spectrum');
xlabel('Frequency (Hz)'); ylabel('Magnitude (dB)');

subplot(4,1,2); plot(f, YnotchdB); xlim([0 80]); grid on; title('After Notch 50 Hz');
xlabel('Frequency (Hz)'); ylabel('dB');

subplot(4,1,3); plot(f, Ylp_dB);   xlim([0 80]); grid on; title('After LPF 40 Hz');
xlabel('Frequency (Hz)'); ylabel('dB');

subplot(4,1,4); plot(f, Yhp_dB);   xlim([0 1]); grid on; title('After HPF 0.5 Hz');
xlabel('Frequency (Hz)'); ylabel('dB');

%% Compare with filtered DB
if ~isempty(x_filtered_db)
    figure('Color','w');
    plot(tm, x_filtered_db,'g','LineWidth',1.2); hold on;
    plot(tm, y_hp,'r','LineWidth',1.2);
    grid on;
    xlabel('Time (s)'); ylabel('ECG (mV)');
    legend('Filter DB','Our Filter');
    title([person '/' record ' — Filter DB vs Our Filter'],'Interpreter','none');

    figure('Color','w');
    subplot(2,1,1);
    plot(tm, x_filtered_db,'g','LineWidth',1.2); hold on;
    grid on;
    xlabel('Time (s)'); ylabel('ECG (mV)');
    title([person '/' record ' — Filter DB'],'Interpreter','none');

    subplot(2,1,2);
    plot(tm, y_hp,'r','LineWidth',1.2);
    grid on;
    xlabel('Time (s)'); ylabel('ECG (mV)');
    title([person '/' record ' — Our Filter'],'Interpreter','none');

%%  MSE & SNR 
% Cắt tín hiệu cho cùng chiều dài
L = min(length(x_filtered_db), length(y_hp));
d = x_filtered_db(1:L);   
y = y_hp(1:L);           

% Mean Squared Error
MSE = mean((d - y).^2);

% Signal-to-Noise Ratio
SNR = 10*log10(sum(d.^2) / sum((d - y).^2));

fprintf('SNR, MSE of Our filter vs Filter DB \n');
fprintf('MSE = %.6f\n', MSE);
fprintf('SNR = %.2f dB\n', SNR);
end
