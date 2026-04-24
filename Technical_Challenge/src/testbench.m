spec = cfg_spec();
sim = cfg_sim();
dut = cfg_dut(spec);
tests = cfg_tests();
cfgs = struct('spec', spec, 'dut', dut, 'sim', sim, 'tests', tests);

fs = spec.fs;
fs_dec = dut.dec.fs_dec;

n_mc = 10;
n_trials_snr = 3;
n_trials_fo = 10;
n_trials_asym = 10;

fprintf('Running tests...\n');
out = trial_run(cfgs);

[outs, agg] = trial_repeat(cfgs, n_mc);
fprintf('Matched: %d / %d\n', agg.ma_errs.total_pairs, agg.ma_errs.total_truth);
fprintf('Miss rate: %.2f%%\n', agg.ma_errs.missed_rate * 100);
fprintf('False alarm rate: %.2f%%\n', agg.ma_errs.fa_rate * 100);
out = trial_run(cfgs);

fprintf('Running SNR sweep...\n');
 setter = @(c, v) set_nested(c, {'sim','SNR_dB'}, v);
 results = trial_sweep(cfgs, setter, linspace(50, -50, 20), n_trials_snr);

figure;
hold on; grid on;
miss = arrayfun(@(r) r.aggregates.ma_errs.missed_rate, results);
fa = arrayfun(@(r) r.aggregates.ma_errs.fa_rate, results);
plot([results.value], miss*100, 'o-');plot([results.value], fa*100, 's-');

xlabel('SNR (dB)');
ylabel('Error Rate (%)');
title(sprintf('Error Rates vs SNR  (n_{trials}=%d, %d PRIs/trial, f_{offset}=%d Hz)', ...
    n_trials_snr, sim.n_intervals, sim.f_offset_Hz));
legend('Missed Detections', 'False Alarms', 'Location','best');

figure;
hold on; grid on;
rms_us = arrayfun(@(r) r.aggregates.ma_errs.dt_rms, results) * 1e6;
plot([results.value], rms_us, 'o-');
xlabel('SNR (dB)');
ylabel('SOF RMS error (us)');
title(sprintf('SOF Timing RMS Error vs SNR  (n_{trials}=%d, %d PRIs/trial, f_{offset}=%d Hz, tol=%.0f us)', ...
    n_trials_snr, sim.n_intervals, sim.f_offset_Hz, tests.tol*1e6));

fprintf('Running offset sweep...\n');
 setter = @(c, v) set_nested(c, {'sim','f_offset_Hz'}, v);
 results = trial_sweep(cfgs, setter, linspace(-15e3, 15e3, 10), n_trials_fo);

figure;
hold on; grid on;
miss = arrayfun(@(r) r.aggregates.ma_errs.missed_rate, results);
fa = arrayfun(@(r) r.aggregates.ma_errs.fa_rate, results);
plot([results.value]/1e3, miss*100, 'o-');plot([results.value]/1e3, fa*100, 's-');

xlabel('Frequency Offset (kHz)');
ylabel('Error Rate (%)');
title(sprintf('Error Rates vs Frequency Offset  (n_{trials}=%d, %d PRIs/trial, SNR=%d dB)', ...
    n_trials_fo, sim.n_intervals, sim.SNR_dB));
legend('Missed Detections', 'False Alarms', 'Location','best');

figure;
hold on; grid on;
rms_us = arrayfun(@(r) r.aggregates.ma_errs.dt_rms, results) * 1e6;
plot([results.value]/1e3, rms_us, 'o-');
xlabel('Frequency Offset (kHz)');
ylabel('SOF RMS error (us)');
title(sprintf('SOF Timing RMS Error vs Frequency Offset  (n_{trials}=%d, %d PRIs/trial, SNR=%d dB, tol=%.0f us)', ...
    n_trials_fo, sim.n_intervals, sim.SNR_dB, tests.tol*1e6));

fprintf('Running amplitude-asymmetry stress illustration...\n');
stress = stress_case(spec, dut, -20, 20);

figure;
hold on; grid on;
plot_wave(stress.wave, fs);
plot_sofs(stress.pulses, fs, 'magenta--');
ylim([-1.5, 1.5]);
xlabel('Time (ms)');
ylabel('Amplitude');
title(sprintf('Stress: strong up + weak down  (\\Delta=%.0f us, weak %+d dB vs strong, SNR=%d dB)', ...
    stress.sep_us, stress.amp_weak_dB, stress.SNR_dB));
legend('Input Wave (real)', 'Truth SOFs', 'Location','best');

figure;
hold on; grid on;
plot_abs(stress.dbg.corr_up, fs_dec, -dut.lpf.delay_t - dut.mf.up.delay_t);
plot_abs(stress.dbg.corr_down, fs_dec, -dut.lpf.delay_t - dut.mf.down.delay_t);
plot_sofs(stress.dets, fs_dec);
plot_sofs(stress.pulses, fs, 'magenta--');
xlabel('Time (ms)');
ylabel('|MF output|');
title(sprintf('Stress MF Outputs  (\\Delta=%.0f us, weak %+d dB, SNR=%d dB, arb window=%.0f us)', ...
    stress.sep_us, stress.amp_weak_dB, stress.SNR_dB, dut.det.arb.window/fs_dec*1e6));
legend('Up MF', 'Down MF', 'Detections', 'Truth SOFs', 'Location','best');

fprintf('Running amplitude-asymmetry sweep...\n');
amp_dBs = 0:-5:-30;
asym_miss = zeros(size(amp_dBs));
asym_fa   = zeros(size(amp_dBs));
for i = 1:numel(amp_dBs)
    m_acc = 0; f_acc = 0;
    for j = 1:n_trials_asym
        s = stress_case(spec, dut, amp_dBs(i), 20);
        m_acc = m_acc + s.errs.ma.miss_rate;
        f_acc = f_acc + s.errs.ma.fa_rate;
    end
    asym_miss(i) = m_acc / n_trials_asym;
    asym_fa(i)   = f_acc / n_trials_asym;
end

figure;
hold on; grid on;
plot(amp_dBs, asym_miss*100, 'o-');
plot(amp_dBs, asym_fa*100, 's-');
set(gca, 'XDir', 'reverse');
xlabel('Weak-pulse amplitude vs strong (dB)');
ylabel('Error Rate (%)');
title(sprintf('Asymmetry Stress: miss/FA vs amplitude ratio  (n_{trials}=%d, SNR=%d dB, \\Delta=%.0f us)', ...
    n_trials_asym, stress.SNR_dB, stress.sep_us));
legend('Missed (of 2 truth)', 'False Alarms (of 2 truth)', 'Location','best');

figure;
hold on; grid on;
plot_wave(out.wave, fs);
plot_wave(out.signal, fs);
plot_sofs(out.schedule.pulses, fs);
ylim([-1.5, 1.5]);
xlabel('Time (ms)');
ylabel('Amplitude');
title(sprintf('Input Signal and Scheduled Pulses  (SNR=%d dB, f_{offset}=%d Hz, %d PRIs)', ...
    sim.SNR_dB, sim.f_offset_Hz, sim.n_intervals));
legend('Input Wave (real)', 'Clean Signal (real)', 'Scheduled Pulses', 'Location','best');

figure;
hold on; grid on;
plot_wave(out.signal, fs);
plot_wave(out.debug.decim, fs_dec, -dut.lpf.delay_t);
ylim([-1.5, 1.5]);
xlabel('Time (ms)');
ylabel('Amplitude');
title(sprintf('Decimated Signal (shifted by LPF group delay = %.2f us)', dut.lpf.delay_t*1e6));
legend('Clean Signal @ fs', 'Decimated (shifted -\tau_{LPF})', 'Location','best');

figure;
hold on; grid on;
plot_abs(out.debug.corr_up, fs_dec, -dut.lpf.delay_t - dut.mf.up.delay_t);
plot_abs(out.debug.corr_down, fs_dec, -dut.lpf.delay_t - dut.mf.down.delay_t);
plot_sofs(out.detections, fs_dec);
plot_sofs(out.schedule.pulses, fs,'magenta--');
xlabel('Time (ms)');
ylabel('|MF output|');
title(sprintf('Matched Filter Outputs and Detections  (SNR=%d dB, f_{offset}=%d Hz)', ...
    sim.SNR_dB, sim.f_offset_Hz));
legend('Up MF (aligned to SOF)', 'Down MF (aligned to SOF)', 'Detections', 'Scheduled Pulses', 'Location','best');

figure;
hold on; grid on;
plot_wave(out.detections(1).iq, fs_dec, -dut.ext.K / fs_dec);
plot_wave(dut.mf.up.wf.iq, fs_dec);
xlabel('Time (ms)');
ylabel('Amplitude (real)');
title(sprintf('First Detected Pulse vs Template  (template=%s)', out.detections(1).template));
legend('Detected Pulse (extracted)', 'Template IQ', 'Location','best');

function stress = stress_case(spec, dut, amp_weak_dB, SNR_dB)
    fs = spec.fs;
    tx_up = spec.make_chirp('up', fs);
    tx_down = spec.make_chirp('down', fs);

    sep_samples = round(0.5 * dut.det.arb.window * dut.dec.D);
    sof_strong = round(0.4 * spec.pri_samples);
    sof_weak = sof_strong + tx_up.N + sep_samples;
    N = 2 * spec.pri_samples;

    signal = complex(zeros(N, 1));
    signal(sof_strong:sof_strong+tx_up.N-1) = tx_up.iq;
    signal(sof_weak:sof_weak+tx_down.N-1) = 10^(amp_weak_dB/20) * tx_down.iq;

    lpf_noise_gain = sum(abs(dut.lpf.h).^2);
    noise_power = 10^(-SNR_dB/10) / lpf_noise_gain;
    noise = (randn(N,1) + 1j*randn(N,1)) * sqrt(noise_power/2);
    wave = signal + noise;

    pulses = [ ...
        struct('sof_idx', sof_strong, 'sof_time', (sof_strong-1)/fs, 'template','up'); ...
        struct('sof_idx', sof_weak,   'sof_time', (sof_weak-1)/fs,   'template','down')];

    [dets, dbg] = run_dut(wave, dut);
    tol = 10e-6;
    errs = compute_errors(pulses, dets, tol);

    stress = struct('wave', wave, 'signal', signal, 'pulses', pulses, ...
        'dets', dets, 'dbg', dbg, 'errs', errs, ...
        'sep_us', sep_samples/fs*1e6, 'amp_weak_dB', amp_weak_dB, 'SNR_dB', SNR_dB);
end

function plot_wave(wave, fs, t_shift)
    if nargin < 3
        t_shift = 0;
    end
    t = ((0:length(wave)-1).')/ fs + t_shift;
    plot(t*1e3, real(wave));
end

function plot_abs(wave, fs, t_shift)
    if nargin < 3
        t_shift = 0;
    end
    t = ((0:length(wave)-1).')/ fs + t_shift;
    plot(t*1e3, abs(wave));
end

function plot_sofs(pulses, fs, line)
    if nargin < 3
        line = 'r--';
    end
    for i = 1:numel(pulses)
        sof_t = pulses(i).sof_time * 1e3;
        xline(sof_t, line);
        text(sof_t, 1.05, pulses(i).template, ...
            'Color','r','FontWeight','bold');
    end
end
