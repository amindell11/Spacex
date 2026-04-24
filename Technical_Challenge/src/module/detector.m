function detections = detector(corr_up, corr_down, det_cfg)
    up_detections = detect('up', corr_up, det_cfg.up, det_cfg.fs_dec);
    down_detections = detect('down', corr_down, det_cfg.down, det_cfg.fs_dec);
    detections = [up_detections; down_detections];
end

function detections = detect(template, corr, sub_cfg, fs_dec)
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
