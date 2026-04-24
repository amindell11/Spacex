function [outs, aggregates] = trial_repeat(cfgs, n_trials)
    outs = repmat(struct('wave', [], 'signal', [], 'schedule', [], 'detections', [], 'debug', [], 'errs', []), 1, n_trials);
    for i = 1:n_trials
        outs(i) = trial_run(cfgs);
    end
    aggregates = aggregate_trials(outs);
end

function aggregates = aggregate_trials(outs)
    errs_arr = [outs.errs];          
    ma_arr   = [errs_arr.ma];         
    aggregates.ma_errs = agg_match_detections(ma_arr);
end

function agg_ma_errs = agg_match_detections(ma_errs_list)
    missed_rate = mean([ma_errs_list.miss_rate]);
    missed_rate_std = std([ma_errs_list.miss_rate]);

    fa_rate = mean([ma_errs_list.fa_rate]);
    fa_rate_std = std([ma_errs_list.fa_rate]);
    total_truth = sum([ma_errs_list.n_truth]);
    total_pairs = sum([ma_errs_list.n_pairs]);
    total_missed = sum([ma_errs_list.n_missed]);
    total_fa = sum([ma_errs_list.n_fa]);
    agg_ma_errs = struct( ...
        'missed_rate', missed_rate, 'missed_rate_std', missed_rate_std, ...
        'fa_rate', fa_rate, 'fa_rate_std', fa_rate_std, 'total_truth', total_truth, ...
        'total_pairs', total_pairs, 'total_missed', total_missed, 'total_fa', total_fa );
end