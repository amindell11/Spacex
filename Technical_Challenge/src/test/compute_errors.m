function errs = compute_errors(truth, det, tol)
    errs.ma = match_detections(truth, det, tol);
end

function [ma_errs] = match_detections(truth, det, tol)
    n_truth = length(truth);
    n_det = length(det);
    n_pairs = 0;
    n_missed = 0;
    n_fa = 0;
    pairs = zeros(n_truth,2);
    missed = zeros(n_truth,1);
    fa = zeros(n_det,1);

    i=1; j=1;
    while i <= n_truth && j <= n_det
        dt = det(j).sof_time - truth(i).sof_time;
        if (abs(dt) <= tol)
            pairs(n_pairs + 1, :) = [i, j];
            i=i+1; j=j+1; n_pairs = n_pairs + 1;
        elseif dt < 0
            fa(n_fa + 1) = j;
            j=j+1; n_fa = n_fa + 1;
        else
             missed(n_missed + 1) = i;
             i=i+1; n_missed = n_missed + 1;
        end
    end
    missed(n_missed + 1:end) = [];
    fa(n_fa + 1:end) = [];
    miss_rate = sum(n_missed) / sum(n_truth);
    fa_rate = sum(n_fa) / sum(n_det);

    ma_errs = struct( ...
        'miss_rate', miss_rate, 'fa_rate', fa_rate, ...
        'n_missed', n_missed, 'n_fa', n_fa,  'n_pairs', n_pairs, ...
        'n_truth', n_truth, 'n_det', n_det, ...
        'missed', missed, 'fa', fa, ...
        'tol', tol);
end 
