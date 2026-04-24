rng(42)
spec = cfg_spec();
sim = cfg_sim();
dut = cfg_dut(spec);
tests = cfg_tests();
cfgs = struct('spec', spec, 'dut', dut, 'sim', sim, 'tests', tests);
mkdir('runs')

fprintf('Running SNR sweep...\n');
setter = @(c,v) set_nested(c,{'sim','SNR_dB'},v);
results = trial_sweep(cfgs, setter, linspace(-10,20,16), 20);
save('runs/snr.mat','results','cfgs')

fprintf('Running sweep...\n');
setter = @(c,v) set_nested(c,{'sim','f_offset_Hz'},v);
results = trial_sweep(cfgs, setter, linspace(-15e3,15e3,10), 20);
save('runs/foffset.mat','results','cfgs')
