function results = trial_sweep(cfgs, setter, values, n_trials)
    n = numel(values);
    results = repmat(struct('value', [], 'aggregates', [], 'outs', []), 1, n);
    for i = 1:n
        cfgs_i = setter(cfgs, values(i));
        [outs, agg] = trial_repeat(cfgs_i, n_trials);
        results(i).value = values(i);
        results(i).aggregates = agg;
        results(i).outs = outs;
    end
end
