
function out = trial_run(spec, dut, sim, tests)
    [out.wave, out.signal, out.schedule] = generate_wave(spec, sim);
    [out.detections, out.debug] = run_dut(out.wave, dut);
    out.errs = compute_errors(out.schedule.pulses, out.detections, tests.tol);
end