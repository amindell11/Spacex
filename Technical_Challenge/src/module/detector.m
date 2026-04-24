function detections = detector(corr_up, corr_down, det_cfg)
    up_detections = detect('up', corr_up, det_cfg.up.threshold, det_cfg.up.M);
    down_detections = detect('down', corr_down, det_cfg.down.threshold, det_cfg.down.M);
    detections = [up_detections; down_detections];
end

function detections = detect(template, corr, threshold, sof_offset)
    mag_sq = abs(corr).^2;
    above = mag_sq > threshold;

    edges = diff([0; above(:); 0]);
    starts = find(edges == +1);
    stops  = find(edges == -1) - 1 ;
    
    detections = [];

    for i = 1:length(starts)
        [peak_mag, rel_idx] = max(mag_sq(starts(i):stops(i)));
        peak_idx = starts(i) + rel_idx - 1;
        
        detection.sof_sample = peak_idx - sof_offset;
        detection.peak_mag = peak_mag;
        detection.template = template;
        detections(end+1) = detection;
    end

    
end