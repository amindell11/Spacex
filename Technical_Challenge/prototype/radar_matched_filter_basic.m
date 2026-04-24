fs = 100e6; % 1 MHz
prf = 1e3;  % 1 kHz
pw_up = 100e-6;
pw_down  = 200e-6;
f_lo = 3e4;
f_hi = 6e4;
SNR_dB = 20;

% build up chirp
N_up = round(pw_up * fs);      % 10,000 samples
t_up = (0:N_up-1).' / fs;       % row vector, 0 to ~100us

k = (f_hi - f_lo) / pw_up;

df = 2000;

chirp = exp(1j * 2 * pi * (f_lo * t_up + 0.5*k*t_up.^2));
chirp_offset = chirp .* exp(1j*2*pi*df*t_up);

plot(real(chirp))
hold on;
plot(real(chirp_offset));
hold off;
figure;

f_inst = diff(unwrap(angle(chirp))) * fs / (2*pi);
f_inst_b = diff(unwrap(angle(chirp_offset))) * fs / (2*pi);

plot(f_inst);
hold on;
plot(f_inst_b)
hold off;
figure;

% build noisy single PRI
return;

N_pri = fs/prf;
pri_buffer  = complex(zeros(N_pri, 1));
truth_idx = 25000;
pri_buffer(truth_idx:truth_idx + N_up - 1) = chirp;

SNR_dB_list = 20:-2:-20;   % +20 down to -20 in 5 dB steps
N_trials = 20;
errors = zeros(length(SNR_dB_list), N_trials);

for i = 1:length(SNR_dB_list)
    fprintf('========= SNR_dB = %d ==================', SNR_dB_list(i));

    for j = 1:N_trials

        noise_power = 10^(-SNR_dB_list(i)/10);
        noise = (randn(N_pri, 1) + (1j*randn(N_pri,1) / sqrt(2))) * sqrt(noise_power);
        
        rx = pri_buffer + noise;
        plot(real(rx))
        
        % matched filter
        
        h = conj(flipud(chirp));   % if chirp is a column vector
        L = length(rx) + length(h) - 1;
        mf_out = ifft(fft(rx, L) .* fft(h, L));
        
        plot(abs(mf_out))
        
        [peak_val, peak_idx] = max(abs(mf_out));
        sof_estimate = peak_idx - N_up + 1;
        
        fprintf('\tSNR_dB = %d Trial %i: trial truth_idx = %d, sof_estimate = %d, diff = %d\n', SNR_dB_list(i), j, truth_idx, sof_estimate, sof_estimate - truth_idx);

        errors(i,j) = abs(sof_estimate - truth_idx);
    end

    fprintf('========= SNR_dB = %d mean error = %d\n', SNR_dB_list(i), mean(errors(i)));

end
figure;
plot(SNR_dB_list, mean(errors, 2))
