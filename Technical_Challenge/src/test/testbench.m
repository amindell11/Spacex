spec = cfg_spec();
sim = cfg_sim();
dut = cfg_dut(spec);
fs = spec.fs;
fs_dec = dut.dec.fs_dec;

[model.wave, model.signal, model.schedule] = run_sim(spec, sim);
[detections, dbg] = run_dut(model.wave, dut);


hold on; grid on;
plot_wave(model.wave, fs);
plot_wave(model.signal, fs);
plot_sofs(model.schedule.pulses, fs);
ylim([-1.5, 1.5]);

figure;
hold on; grid on;
plot_wave(model.signal, fs);
plot_wave(dbg.decim, fs_dec, -dut.lpf.delay_t);
ylim([-1.5, 1.5]);

figure;
hold on; grid on;
plot_abs(dbg.corr_up, fs_dec, -dut.lpf.delay_t - dut.mf.up.delay_t);
plot_abs(dbg.corr_down, fs_dec, -dut.lpf.delay_t - dut.mf.down.delay_t);
plot_sofs(detections, fs_dec);
plot_sofs(model.schedule.pulses, fs,'magenta--');

figure;
hold on; grid on;
plot_wave(detections(1).iq, fs_dec, -dut.ext.K / fs_dec);
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
