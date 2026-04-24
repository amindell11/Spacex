% Build a full input waveform to specifications for MF testing
% cfg: system config
% SNR_dB: for added channel noise
% returns generated wave, clean signal, and pulse schedule for debugging
function [wave, signal, schedule] = run_sim(spec, sim)
    tx_up = spec.make_chirp('up', spec.fs);
    tx_down = spec.make_chirp('down', spec.fs);
    wf = [tx_up, tx_down];
    schedule = build_pri_schedule(spec, wf, sim.up_first, sim.n_intervals);
    signal = generate_signal(schedule);
    wave = channel(signal, length(signal), sim.SNR_dB);
end

% Build a schedule of pulses at configured PRF
% n_intervals: schedule length in PRI's
% wf_up: whether to start on an up pulse (will alternate after first)
% returns schedule struct with .pulse(i) AoS and total sample length
function schedule = build_pri_schedule(spec, wf, up_first, n_intervals)
    pulses = repmat(empty_pulse(wf(1)), n_intervals, 1);
    for i = 1 : n_intervals
        pulse = wf(mod(i + up_first, 2) + 1);
        pulses(i).wf = pulse;
        pulses(i).template = pulse.name;
        pulses(i).sof_idx = randi(spec.pri_samples - pulse.N + 1) + (i-1) * spec.pri_samples;
        pulses(i).sof_time = (pulses(i).sof_idx - 1) / spec.fs;
    end

    schedule.pulses = pulses;
    schedule.N_samples = spec.pri_samples * n_intervals;
end

% Generate a clean rx signal from a specified pulse schedule
% schedule: see build_pri_schedule
% returns clean signal vector
function signal = generate_signal(schedule)
    signal = complex(zeros(schedule.N_samples, 1));

    for i = 1 : numel(schedule.pulses)
        sof = schedule.pulses(i).sof_idx;
        wf_iq = schedule.pulses(i).wf.iq;
        pw = length(wf_iq);
        signal(sof : sof + pw - 1) = signal(sof : sof + pw - 1) + wf_iq;
    end

    assert(length(signal) == schedule.N_samples);
end

% Simulate a channel by adding complex gaussian noise to input signal
% assumes unity signal has unity gain
% N: redundant signal length for convenience
% returns noisy rx signal vector
function rx = channel(signal, N, SNR_dB)
    noise_power = 10 ^ (-SNR_dB/10);
    noise = (randn(N, 1) + 1j * randn(N,1)) * sqrt(noise_power/2);
    rx = signal + noise;

    assert(isequal(size(rx), size(signal)));
end

function p = empty_pulse(wf_template)
    p = struct('sof_idx', 0, 'template', '', 'wf', wf_template);
end
