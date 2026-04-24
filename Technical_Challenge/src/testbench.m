spec = cfg_spec();
sim = cfg_sim();
dut = cfg_dut(spec);
tests = cfg_tests();
cfgs = struct('spec', spec, 'dut', dut, 'sim', sim, 'tests', tests);

fs = spec.fs;
fs_dec = dut.dec.fs_dec;

fprintf('Running tests...\n');
out = trial_run(cfgs);

[outs, agg] = trial_repeat(cfgs, 10);
fprintf('Matched: %d / %d\n', agg.ma_errs.total_pairs, agg.ma_errs.total_truth);
fprintf('Miss rate: %.2f%%\n', agg.ma_errs.missed_rate * 100);
fprintf('False alarm rate: %.2f%%\n', agg.ma_errs.fa_rate * 100);
out = trial_run(cfgs);

fprintf('Running sweep...\n');
 setter = @(c, v) set_nested(c, {'sim','SNR_dB'}, v);
 results = trial_sweep(cfgs, setter, linspace(50, -50, 20), 3);

hold on; grid on;
miss = arrayfun(@(r) r.aggregates.ma_errs.missed_rate, results);
fa = arrayfun(@(r) r.aggregates.ma_errs.fa_rate, results);
plot([results.value], miss*100, 'o-');plot([results.value], fa*100, 's-');

xlabel('SNR (dB)');
ylabel('Error Rate (%)');
title('Error Rates vs SNR');
legend('Missed Detections', 'False Alarms');

fprintf('Running offset sweep...\n');
 setter = @(c, v) set_nested(c, {'sim','f_offset_Hz'}, v);
 results = trial_sweep(cfgs, setter, linspace(-15e3, 15e3, 10), 10);

figure;
hold on; grid on;
miss = arrayfun(@(r) r.aggregates.ma_errs.missed_rate, results);
fa = arrayfun(@(r) r.aggregates.ma_errs.fa_rate, results);
plot([results.value]/1e3, miss*100, 'o-');plot([results.value]/1e3, fa*100, 's-');

xlabel('Frequency Offset (kHz)');
ylabel('Error Rate (%)');
title('Error Rates vs Frequency Offset');
legend('Missed Detections', 'False Alarms');

figure;
hold on; grid on;
plot_wave(out.wave, fs);
plot_wave(out.signal, fs);
plot_sofs(out.schedule.pulses, fs);
ylim([-1.5, 1.5]);
xlabel('Time (ms)');
ylabel('Amplitude');
title('Input Signal and Scheduled Pulses');
legend('Input Wave', 'Original Signal', 'Scheduled Pulses');

figure;
hold on; grid on;
plot_wave(out.signal, fs);
plot_wave(out.debug.decim, fs_dec, -dut.lpf.delay_t);
ylim([-1.5, 1.5]);
xlabel('Time (ms)');
ylabel('Amplitude');
title('Decimated Signal and LPF Delay');
legend('Original Signal', 'Decimated Signal (Shifted)');

figure;
hold on; grid on;
plot_abs(out.debug.corr_up, fs_dec, -dut.lpf.delay_t - dut.mf.up.delay_t);
plot_abs(out.debug.corr_down, fs_dec, -dut.lpf.delay_t - dut.mf.down.delay_t);
plot_sofs(out.detections, fs_dec);
plot_sofs(out.schedule.pulses, fs,'magenta--');
xlabel('Time (ms)');
ylabel('Correlation Magnitude');
title('Matched Filter Outputs and Detections');
legend('Up Sweep Correlation', 'Down Sweep Correlation', 'Detections', 'Scheduled Pulses');

figure;
hold on; grid on;
plot_wave(out.detections(1).iq, fs_dec, -dut.ext.K / fs_dec);
plot_wave(dut.mf.up.wf.iq, fs_dec);
xlabel('Time (ms)');
ylabel('Amplitude');
title('First Detected Pulse vs Input');
legend('Detected Pulse', 'Input Pulse');

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
