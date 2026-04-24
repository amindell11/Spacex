function [detections, dbg] = run_dut(wave, cfg)
    dbg.decim = lpf_decimate(wave, cfg.lpf, cfg.dec);
    [dbg.corr_up, dbg.corr_down] = matched_filter(dbg.decim, cfg.mf);
    dets_up   = detect(dbg.corr_up,   cfg.det.up,   cfg.det.fs_dec, 'up');
    dets_down = detect(dbg.corr_down, cfg.det.down, cfg.det.fs_dec, 'down');
    detections = [dets_up; dets_down];
    detections = extract_pulses(dbg.decim, detections, cfg.ext);
end

function y = lpf_decimate(x, lpf_cfg, dec_cfg)
    y = conv(x, lpf_cfg.h);
    y = y(1:dec_cfg.D:end);
end

function [up, down] = matched_filter(x, mf_cfg)
    up   = filter(mf_cfg.up.h,   1, x);
    down = filter(mf_cfg.down.h, 1, x);
end

function detections = detect(corr, sub_cfg, fs_dec, template)
    mag_sq = abs(corr).^2;
    above = mag_sq > sub_cfg.threshold;

    edges = diff([0; above(:); 0]);
    starts = find(edges == +1);
    stops  = find(edges == -1) - 1 ;

    detections = repmat(struct('sof_idx',0,'sof_time',0,'peak_mag',0,'template','','N_tap',0), numel(starts), 1);
    for i = 1:length(starts)
        [peak_mag, rel_idx] = max(mag_sq(starts(i):stops(i)));
        peak_idx = starts(i) + rel_idx - 1;

        detections(i).sof_idx = peak_idx - sub_cfg.total_delay_n;
        detections(i).sof_time = (detections(i).sof_idx - 1) / fs_dec;
        detections(i).peak_mag = peak_mag;
        detections(i).template = template;
        detections(i).N_tap = sub_cfg.N_tap;
    end
end

function detections = extract_pulses(x, detections, ext_cfg)
    for i = 1:length(detections)
        sof_idx = detections(i).sof_idx;
        start = sof_idx - ext_cfg.K;
        stop = sof_idx + detections(i).N_tap - 1 + ext_cfg.K;
        detections(i).iq = x(start:stop);
    end
end
