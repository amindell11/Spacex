function dut = cfg_dut(spec)
    %SYSTEM PARAMS
    fs = spec.fs;
    fs_dec = 500e3; % decimated sample rate
    f_pass = 100e3; % passband for AA filter - set safely above the signal band at 60kHz
    P_fa = 1e-4; % target false-alarm probability per PRI
    K = 0; % samples padding before / after extracted pulses
    f_offsets = -10e3:2.5e3:10e3; % doppler bins for MF bank
    
    lpf = build_lpf();
    dec = build_dec();
    mf = build_mf();
    det = build_det();
    ext = build_ext();


    dut = struct('spec', spec, 'lpf', lpf, 'dec', dec, 'mf', mf, 'det', det, 'ext', ext);

    function lpf = build_lpf()
        df = (fs_dec /2) - f_pass;
        lpf.fs = fs;
        lpf.df = df;
        lpf.fc = f_pass + df/2;
        lpf.N = 2 * round(1.65/(df/fs)) + 1;
        lpf.h = generate_lpf(fs, lpf.fc, lpf.N);
        lpf.delay_n = (lpf.N - 1) / 2;
        lpf.delay_t = lpf.delay_n / fs;
    end

    function dec = build_dec()
        dec.fs_dec = fs_dec;
        dec.D = fs / fs_dec;
    end

    function mf = build_mf()
        mf.fs_dec = fs_dec;
        mf.up   = make_template(spec, 'up',   fs_dec, f_offsets);
        mf.down = make_template(spec, 'down', fs_dec, f_offsets);
    end

    function det = build_det()
        det.fs_dec = fs_dec;
        samples_per_PRI_dec = spec.pri_samples / dec.D;
        K_up = size(mf.up.h, 2);
        K_down = size(mf.down.h, 2);

        det.up.K = -log(P_fa / (samples_per_PRI_dec * K_up));
        det.up.K_bins = K_up;
        det.up.total_delay_n = mf.up.delay_n + round(lpf.delay_n / dec.D);
        det.up.total_delay_t = mf.up.delay_t + lpf.delay_t;
        det.up.N_tap = mf.up.N_tap;
        det.up.min_separation = round(0.5 * samples_per_PRI_dec);

        det.down.K = -log(P_fa / (samples_per_PRI_dec * K_down));
        det.down.K_bins = K_down;
        det.down.total_delay_n = mf.down.delay_n + round(lpf.delay_n / dec.D);
        det.down.total_delay_t = mf.down.delay_t + lpf.delay_t;
        det.down.N_tap = mf.down.N_tap;
        det.down.min_separation = round(0.5 * samples_per_PRI_dec);

        det.arb.window = max(mf.up.N_tap, mf.down.N_tap);
        det.arb.ratio = 2;
    end

    function ext = build_ext()
        ext.K = K;
    end

end

function h = generate_lpf(fs, fc, N)
    M = (N-1) / 2;
    n = (0:N-1).';
    h_ideal = 2 * fc/fs * sinc(2 * fc/fs * (n-M));
    w = 0.54-0.46 * cos(2*pi*n/(N-1));
    h = h_ideal .* w;
    h = h / sum(h);
end

function tp = make_template(spec, name, fs_dec, f_offsets)
    wf = spec.make_chirp(name, fs_dec);
    tp.wf = wf;
    t = (0:wf.N-1).' / fs_dec;
    tp.h = zeros(wf.N, numel(f_offsets));
    for k = 1:numel(f_offsets)
        tp.h(:,k) = conj(flip(wf.iq .* exp(1j*2*pi*f_offsets(k)*t)));
    end
    tp.h = tp.h / sqrt(sum(abs(tp.h(:,1)).^2));
    tp.f_offsets = f_offsets;
    tp.delay_n = (wf.N - 1);
    tp.delay_t = tp.delay_n / fs_dec;
    tp.N_tap = wf.N;
end
