function sim = cfg_sim()
    sim.SNR_dB = 20; % for generated wave
    sim.n_intervals = 10; % number of PRI intervals to simulate
    sim.up_first = true; % whether to start schedule on an up chirp (will alternate after first)
end