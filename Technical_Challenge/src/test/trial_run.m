
function out = trial_run(cfgs)
    [out.wave, out.signal, out.schedule] = generate_wave(cfgs.spec, cfgs.sim);
    [out.detections, out.debug] = run_dut(out.wave, cfgs.dut);
    out.errs = compute_errors(out.schedule.pulses, out.detections, cfgs.tests.tol);
end