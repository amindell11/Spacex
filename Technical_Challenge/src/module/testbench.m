cfg = default_config();
[model.wave, model.signal, model.schedule] = generate_wave(cfg.in, 20);
[decim.wave] = aa_decimate(model.wave, cfg);
[mf.corr_up, mf.corr_down] = matched_filter(decim.wave, cfg.mf);

hold on; grid on;
plot_wave(model.wave, cfg.fs);
plot_wave(model.signal, cfg.fs);
plot_sof_schedule(model.schedule, cfg.fs);
hold off;

figure;
hold on;
plot_wave(model.signal, cfg.fs);
plot_wave(decim.wave, cfg.dec.fs_dec, -cfg.lpf.group_delay_t);

function plot_wave(wave, fs, t_shift)
    if nargin < 3 t_shift = 0; end
    t = ((0:length(wave)-1).')/ fs + t_shift;
    plot(t*1e3, real(wave));
    ylim([-1.5, 1.5]);
end

function plot_sof_schedule(sch, fs)
    for i = 1:numel(sch.sof)
        sof_t = (sch.sof(i) - 1) / fs * 1e3;
        xline(sof_t, 'r--');
        text(sof_t, 1.05, sch.wf(i).name, ...
            'Color','r','FontWeight','bold');
    end
end
