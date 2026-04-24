function [outs, aggregates] = trial_repeat(spec, dut, sim,tests, n_trials, n_waves)
    outs = repmat(struct('wave', [], 'signal', [], 'schedule', [], 'detections', [], 'debug', [], 'errs', []), 1, n_trials);
    for i = 1:n_trials
        outs(i) = trial_run(spec, dut, sim, tests);
    end
    aggregates = aggregate_trials(outs);
end
