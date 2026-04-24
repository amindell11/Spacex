function errs = compute_errors(truth, det, tol)
    errs.ma = match_detections(truth, det, tol);
end

function [ma_errs] = match_detections(truth, det, tol)
    n_truth = length(truth);
    n_det = length(det);

    truth_t = [truth.sof_time];
    det_t   = [det.sof_time];

    dt_mat = abs(det_t(:) - truth_t(:).');
    dt_mat(dt_mat > tol) = inf;

    pairs = zeros(n_truth, 1);
    for i = 1:n_truth
        [m, j] = min(dt_mat(:, i));
        if isfinite(m)
            pairs(i) = j;
            dt_mat(j, :) = inf;
        end
    end

    matched = pairs > 0;
    missed = find(~matched);
    fa = setdiff((1:n_det).', pairs(matched));
    dts = det_t(pairs(matched)) - truth_t(matched);
    dts = reshape(dts, 1, []);

    n_pairs = sum(matched);
    n_missed = numel(missed);
    n_fa = numel(fa);

    miss_rate = n_missed / n_truth;
    fa_rate   = n_fa / n_truth;

    ma_errs = struct( ...
        'miss_rate', miss_rate, 'fa_rate', fa_rate, ...
        'n_missed', n_missed, 'n_fa', n_fa,  'n_pairs', n_pairs, ...
        'n_truth', n_truth, 'n_det', n_det, ...
        'missed', missed, 'fa', fa, 'dts', dts, ...
        'tol', tol);
end
