function run_tests(truth, det, tol)
    % Run all tests and report results
    fprintf('Running tests...\n');
    [pairs, missed, fa] = match_detections(truth, det, tol);
    fprintf('Matched pairs: %d\n', size(pairs, 1));
    fprintf('Missed detections: %d\n', length(missed));
    fprintf('False alarms: %d\n', length(fa));
end

function [pairs, missed, fa] = match_detections(truth, det, tol)
    % Match detections to truth within a tolerance
    N_truth = length(truth);
    N_det = length(det);
    n_pairs = 0;
    n_missed = 0;
    n_fa = 0;
    pairs = zeros(N_truth,2);
    missed = zeros(N_truth,1);
    fa = zeros(N_det,1);

    i=1; j=1;
    while i <= N_truth && j <= N_det
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
    pairs(n_pairs + 1:end, :) = [];
    missed(n_missed + 1:end) = [];
    fa(n_fa + 1:end) = [];
end

