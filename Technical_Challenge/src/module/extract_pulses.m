function detections = extract_pulses(x, detections, ext_cfg)
    for i=(1:length(detections))
        sof_idx = detections(i).sof_idx;
        start = sof_idx - ext_cfg.K;
        stop = sof_idx + detections(i).N_tap - 1 + ext_cfg.K;
        detections(i).iq = x(start:stop);
    end
end
