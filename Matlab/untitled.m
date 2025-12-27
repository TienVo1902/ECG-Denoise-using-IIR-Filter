clc; clear; close all;

%% =================== 1) LOAD PhysioNet + MATLAB FILTER ===================
dbDir   = 'D:\Advanced_Topic\PhysioNet\ecg-id-database-1.0.0';
person  = 'Person_01';
record  = 'rec_2';
secs    = 5;

oldDir = pwd; cd(fullfile(dbDir, person));
[ecg, Fs, tm] = rdsamp(record, [], secs*500);
cd(oldDir);

x = ecg(:,1);                        % raw (mV)
if size(ecg,2) >= 2, x_db = ecg(:,2); else, x_db = []; end

% MATLAB filters (zero-phase)
hp_fc=0.5; hp_ord=3; lp_fc=40; lp_ord=4; mains=50; notch_Q=30;
[b_hpE,a_hpE] = ellip(hp_ord,1,60,hp_fc/(Fs/2),'high');
[b_lpE,a_lpE] = ellip(lp_ord,1,60,lp_fc/(Fs/2),'low');
wo = mains/(Fs/2); bw = wo/notch_Q; [b_notch,a_notch] = iirnotch(wo,bw);
y_notch = filtfilt(b_notch,a_notch, x);
y_lp    = filtfilt(b_lpE,a_lpE,     y_notch);
y_mat   = filtfilt(b_hpE,a_hpE,     y_lp);          % “clean” tham chiếu

%% =================== 2) LOAD ILA CSV + FIXED-POINT CONVERSION ============
Fs_fpga = 500;   % nên bằng Fs trên
opts = detectImportOptions('iladata.csv');
T = readtable('iladata.csv', opts); T(1,:) = [];

% 24-bit raw từ BRAM (2’s comp), 40-bit output IIR (2’s comp)
douta = hex2dec(T.douta_wire_23_0_);                          % 0..2^24-1
douta(douta>=2^23) = douta(douta>=2^23) - 2^24;               % signed
y_fp  = hex2dec(T.filtered_ecg_wire_39_0_);
y_fp(y_fp>=2^39) = y_fp(y_fp>=2^39) - 2^40;

Q_in  = 23;                      % sfix24_En23  → đơn vị “gần V”
Q_out = 30;                      % sfix40_En30
x_fpga_raw = double(douta) / 2^Q_in;        % chưa đổi sang mV
y_fpga     = double(y_fp)   / 2^Q_out;      % chưa đổi sang mV

% (Tuỳ chọn) đổi mV để nhìn đồ thị cho quen mắt
x_mV    = x;                            % PhysioNet đã là mV
y_mat_mV= y_mat;
% Với FPGA, chưa biết hệ số ADC tuyệt đối → ta khớp biên độ bằng LS sau.

%% =================== 3) CẮT CHIỀU DÀI & CĂN CHỈNH ĐỘ TRỄ ================
L = min([length(x_mV), length(y_mat_mV), length(y_fpga), length(x_fpga_raw)]);
x_mV       = x_mV(1:L);
y_mat_mV   = y_mat_mV(1:L);
y_fpga     = y_fpga(1:L);
x_fpga_raw = x_fpga_raw(1:L);

% Ước lượng trễ (causal vs filtfilt) bằng cross-correlation
[cc,lag] = xcorr(y_fpga, y_mat_mV, 'coeff');
[~,iMax] = max(cc);
delay = lag(iMax);                 % y_fpga ≈ y_mat_mV trễ 'delay' mẫu

if delay > 0
    y_fpga_aligned = y_fpga(1+delay:end);
    y_mat_aligned  = y_mat_mV(1:end-delay);
    x_mV_aligned   = x_mV(1:end-delay);
else
    y_fpga_aligned = y_fpga(1:end+delay);
    y_mat_aligned  = y_mat_mV(1-delay:end);
    x_mV_aligned   = x_mV(1-delay:end);
end

% Ước lượng hệ số gain tối ưu để map FPGA → MATLAB (least-squares)
alpha = (y_fpga_aligned' * y_mat_aligned) / (y_fpga_aligned' * y_fpga_aligned);
y_fpga_match = alpha * y_fpga_aligned;     % cùng thang đo với y_mat_aligned

%% =================== 4) METRICS: SNR, MSE, CORR ==========================
% SNR trước (raw vs noise raw-clean_MATLAB)
noise_before = x_mV_aligned - y_mat_aligned;
SNR_before   = 10*log10( sum(y_mat_aligned.^2) / sum(noise_before.^2) );

% SNR sau (FPGA vs residual raw-FPGA)
noise_after  = x_mV_aligned - y_fpga_match;
SNR_after    = 10*log10( sum(y_fpga_match.^2) / sum(noise_after.^2) );

% MSE và hệ số tương quan giữa MATLAB vs FPGA (sau căn chỉnh)
MSE_mat_fpga = mean( (y_mat_aligned - y_fpga_match).^2 );
R_mat_fpga   = corr(y_mat_aligned, y_fpga_match);

fprintf('== EVALUATION (aligned, gain-corrected) ==\n');
fprintf('Delay (samples): %d\n', delay);
fprintf('Alpha (gain FPGA→MAT): %.6f\n', alpha);
fprintf('MSE(MAT vs FPGA): %.6e (mV^2)\n', MSE_mat_fpga);
fprintf('Corr(MAT vs FPGA): %.4f\n', R_mat_fpga);
fprintf('SNR before: %.2f dB | SNR after: %.2f dB | ΔSNR: %.2f dB\n', ...
        SNR_before, SNR_after, SNR_after - SNR_before);

%% =================== 5) PLOTS ===========================================
t = (0:length(y_mat_aligned)-1)/Fs;
figure('Color','w');
subplot(3,1,1); plot(t, x_mV_aligned, 'Color', [0.2 0.2 1]); grid on;
title('Raw ECG (mV)'); xlabel('Time (s)'); ylabel('mV');

subplot(3,1,2); plot(t, y_mat_aligned, 'g'); grid on;
title('MATLAB Filter (mV)'); xlabel('Time (s)'); ylabel('mV');

subplot(3,1,3); plot(t, y_fpga_match, 'r'); grid on;
title(sprintf('FPGA Filter (aligned, gain-corrected) | ΔSNR = %.2f dB', SNR_after - SNR_before));
xlabel('Time (s)'); ylabel('mV');

figure('Color','w');
plot(t, y_mat_aligned, 'g','LineWidth',1.2); hold on;
plot(t, y_fpga_match, 'r','LineWidth',1.0);
grid on; xlabel('Time (s)'); ylabel('mV');
legend('MATLAB','FPGA (aligned+gain)','Location','best');
title(sprintf('Overlay | MSE=%.2e, Corr=%.3f', MSE_mat_fpga, R_mat_fpga));
% dùng cùng 'y_mat_aligned', 'x_mV_aligned', 'y_fpga_match' đã có sẵn
sig = y_mat_aligned;                            % mốc “clean” chung

SNR_raw  = 10*log10( sum(sig.^2) / sum((x_mV_aligned - sig).^2) );
SNR_fpga = 10*log10( sum(sig.^2) / sum((y_fpga_match   - sig).^2) );
dSNR     = SNR_fpga - SNR_raw;

fprintf('SNR(raw vs clean)= %.2f dB | SNR(FPGA vs clean)= %.2f dB | ΔSNR= %.2f dB\n', ...
        SNR_raw, SNR_fpga, dSNR);

