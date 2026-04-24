cfg = default_config();
[model.wave, model.signal, model.schedule] = generate_wave(cfg.in, -20);
[decim.wave] = aa_decimate(model.wave, cfg);
[mf.corr_up, mf.corr_down] = matched_filter(decim.wave, cfg.mf);
detections = detector(mf.corr_up, mf.corr_down, cfg.det);

hold on; grid on;
plot_wave(model.wave, cfg.fs);
plot_wave(model.signal, cfg.fs);
plot_sofs(model.schedule.pulses, cfg.fs);
ylim([-1.5, 1.5]);

figure;
hold on; grid on;
plot_wave(model.signal, cfg.fs);
plot_wave(decim.wave, cfg.dec.fs_dec, -cfg.lpf.delay_t);
ylim([-1.5, 1.5]);

figure;
hold on; grid on;
plot_abs(mf.corr_up, cfg.dec.fs_dec, -cfg.lpf.delay_t - cfg.mf.up.delay_t);
plot_abs(mf.corr_down, cfg.dec.fs_dec, -cfg.lpf.delay_t - cfg.mf.down.delay_t);
plot_sofs(detections, cfg.dec.fs_dec);
plot_sofs(model.schedule.pulses, cfg.fs,'magenta--');

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
        pulses(i).sof_time
        sof_t = pulses(i).sof_time * 1e3;
        xline(sof_t, line);
        text(sof_t, 1.05, pulses(i).template, ...
            'Color','r','FontWeight','bold');
    end
end
