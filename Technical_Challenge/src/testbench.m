spec = cfg_spec();
sim = cfg_sim();
dut = cfg_dut(spec);
tests = cfg_tests();

fs = spec.fs;
fs_dec = dut.dec.fs_dec;

fprintf('Running tests...\n');
[outs, agg] = trial_repeat(spec, dut, sim, tests, 10);
fprintf('Matched: %d / %d\n', agg.ma_errs.total_pairs, agg.ma_errs.total_truth);
fprintf('Miss rate: %.2f%%\n', agg.ma_errs.missed_rate * 100);
fprintf('False alarm rate: %.2f%%\n', agg.ma_errs.fa_rate * 100);
out = outs(1);

figure;
hold on; grid on;
plot_wave(out.wave, fs);
plot_wave(out.signal, fs);
plot_sofs(out.schedule.pulses, fs);
ylim([-1.5, 1.5]);

figure;
hold on; grid on;
plot_wave(out.signal, fs);
plot_wave(out.debug.decim, fs_dec, -dut.lpf.delay_t);
ylim([-1.5, 1.5]);

figure;
hold on; grid on;
plot_abs(out.debug.corr_up, fs_dec, -dut.lpf.delay_t - dut.mf.up.delay_t);
plot_abs(out.debug.corr_down, fs_dec, -dut.lpf.delay_t - dut.mf.down.delay_t);
plot_sofs(out.detections, fs_dec);
plot_sofs(out.schedule.pulses, fs,'magenta--');

figure;
hold on; grid on;
plot_wave(out.detections(1).iq, fs_dec, -dut.ext.K / fs_dec);
plot_wave(dut.mf.up.wf.iq, fs_dec);

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
