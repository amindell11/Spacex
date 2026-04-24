function sim = cfg_sim()
    sim.SNR_dB = 5; % for generated wave
    sim.f_offset_Hz = 0; % carrier freq offset applied to rx signal
    sim.n_intervals = 10; % number of PRI intervals to simulate
    sim.up_first = true; % whether to start schedule on an up chirp (will alternate after first)
end