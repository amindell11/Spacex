function plot_scenario(wave, signal, schedule, cfg, wave_dec, N_filt, D, fs_dec)
    t = (0:length(wave)-1).' / cfg.fs;
    figure('Name','Scenario debug','Color','w');

    % --- Panel 1: clean signal magnitude with pulse markers ---
    subplot(5,1,1);
    plot(t*1e3, abs(signal)); hold on; grid on;
    for i = 1:numel(schedule.sof)
        sof_t = (schedule.sof(i) - 1) / cfg.fs * 1e3;
        xline(sof_t, 'r--');
        text(sof_t, 1.05, schedule.wf(i).name, ...
            'Color','r','FontWeight','bold');
    end
    ylim([0 1.2]);
    xlabel('time (ms)'); ylabel('|signal|');
    title('Clean signal — red lines = truth SOF');

    % --- Panel 2: noisy wave magnitude ---
    subplot(5,1,2);
    plot(t*1e3, abs(wave)); grid on;
    xlabel('time (ms)'); ylabel('|wave|');
    title('Received (signal + noise)');

    % --- Panel 3: zoom to first pulse, show real part ---
    subplot(5,1,3);
    sof1 = schedule.sof(1);
    N1 = schedule.wf(1).N;
    idx = sof1 : sof1 + N1 - 1;
    plot(t(idx)*1e3, real(wave(idx)), 'b'); hold on;
    plot(t(idx)*1e3, real(signal(idx)), 'r');
    grid on; legend('wave (noisy)', 'signal (clean)');
    xlabel('time (ms)'); ylabel('real part');
    title(sprintf('Zoom on pulse 1 (%s-chirp)', schedule.wf(1).name));

    % --- Panel 4: decimated magnitude with group-delay-corrected SOF markers ---
    group_delay = (N_filt - 1) / 2;   % input samples
    t_dec = (0:length(wave_dec)-1).' / fs_dec;
    subplot(5,1,4);
    plot(t_dec*1e3, abs(wave_dec)); hold on; grid on;
    for i = 1:numel(schedule.sof)
        sof_dec_idx = (schedule.sof(i) - 1 + group_delay) / D + 1;
        sof_dec_t = (sof_dec_idx - 1) / fs_dec * 1e3;
        xline(sof_dec_t, 'r--');
    end
    xlabel('time (ms)'); ylabel('|wave\_dec|');
    title(sprintf('Decimated wave (fs = %.0f kHz) — red = group-delay-corrected truth SOF', fs_dec/1e3));

    % --- Panel 5: spectrogram of decimated wave ---
    subplot(5,1,5);
    nfft =  128;
    hop  = 64;
    [S, f_sg, t_sg] = simple_spectrogram(wave_dec, fs_dec, nfft, hop);
    imagesc(t_sg*1e3, f_sg/1e3, 20*log10(abs(S) + eps));
    axis xy; colorbar;
    xlabel('time (ms)'); ylabel('freq (kHz)');
    title('Decimated spectrogram — expect chirps sweeping 30–60 kHz');
end