function [detections, dbg] = run_dut(wave, cfg)
    dbg.decim = lpf_decimate(wave, cfg.lpf, cfg.dec);
    [dbg.corr_up, dbg.corr_down] = matched_filter(dbg.decim, cfg.mf);
    dets_up   = detect(dbg.corr_up,   cfg.det.up,   cfg.det.fs_dec, 'up');
    dets_down = detect(dbg.corr_down, cfg.det.down, cfg.det.fs_dec, 'down');
    detections = [dets_up; dets_down];
    [~, order] = sort([detections.sof_time]);
    detections = detections(order);
    detections = arbitrate(detections, cfg.det.arb);
    detections = extract_pulses(dbg.decim, detections, cfg.ext);
end

function dets = arbitrate(dets, arb_cfg)
    if length(dets) <= 1, return; end
    keep = true(length(dets), 1);
    for i = 1:length(dets)-1
        if ~keep(i), continue; end
        for j = i+1:length(dets)
            if ~keep(j), continue; end
            if dets(j).sof_idx - dets(i).sof_idx > arb_cfg.window, break; end
            if dets(i).peak_mag >= arb_cfg.ratio * dets(j).peak_mag
                keep(j) = false;
            elseif dets(j).peak_mag >= arb_cfg.ratio * dets(i).peak_mag
                keep(i) = false;
                break;
            end
        end
    end
    dets = dets(keep);
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
    valid_start = sub_cfg.total_delay_n + 1;
    valid_stop  = length(corr) - sub_cfg.N_tap + 1 + sub_cfg.total_delay_n;
    noise_est = median(mag_sq(valid_start:min(valid_stop, end))) / log(2);
    thresh = sub_cfg.K * noise_est;
    above = mag_sq > thresh;
    above([1:valid_start-1, valid_stop+1:end]) = false;

    edges = diff([0; above(:); 0]);
    starts = find(edges == +1);
    stops  = find(edges == -1) - 1 ;

    if numel(starts) > 1
        gaps = starts(2:end) - stops(1:end-1) - 1;
        merge = gaps <= sub_cfg.min_separation;
        starts = starts([true; ~merge]);
        stops  = stops([~merge; true]);
    end

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
        if start >= 1 && stop <= length(x)
            detections(i).iq = x(start:stop);
        else
            detections(i).iq = [];
        end
    end
end
