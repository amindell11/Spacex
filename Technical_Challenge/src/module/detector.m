function detections = detector(corr_up, corr_down, det_cfg)
    up_detections = detect('up', corr_up, det_cfg.up.threshold, det_cfg.up.total_delay_t, det_cfg.fs_dec);
    down_detections = detect('down', corr_down, det_cfg.down.threshold, det_cfg.down.total_delay_t, det_cfg.fs_dec);
    detections = [up_detections; down_detections];
end

function detections = detect(template, corr, threshold, delay, fs)
    mag_sq = abs(corr).^2;
    above = mag_sq > threshold;

    edges = diff([0; above(:); 0]);
    starts = find(edges == +1);
    stops  = find(edges == -1) - 1 ;
    
    detections = repmat(struct('sof_time',0,'peak_mag',0,'template',''), numel(starts), 1);
    for i = 1:length(starts)
        [peak_mag, rel_idx] = max(mag_sq(starts(i):stops(i)));
        peak_idx = starts(i) + rel_idx - 1;
        
        detections(i).sof_time = (peak_idx - 1) / fs - delay;
        detections(i).peak_mag = peak_mag;
        detections(i).template = template;
    end

    
end