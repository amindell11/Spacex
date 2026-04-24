function cfg = default_config()
% SPEC CONSTANTS (DO NOT CHANGE)
    fs = 100e6;
    prf = 1e3;
    T_up = 100e-6;
    T_down = 200e-6;
    f0 = 30e3;
    f1 = 60e3;

%SYSTEM PARAMS
    fs_dec = 500e3; % decimated sample rate
    f_pass = 100e3; % passband for AA filter - set safely above the signal band at 60kHz
    threshold_up = 40; % detector threshold for up sweeps
    threshold_down = 40; % detector threshold for up sweeps
    min_separation = 0; % for region grouping
    K = 0; % samples padding before / after extracted pulses

%Load into cfg structs
    cfg.fs = fs;
    cfg.spec = build_spec();
    cfg.lpf = build_lpf();
    cfg.dec = build_dec();
    cfg.mf = build_mf();
    cfg.det = build_det();
    cfg.ext = build_ext();

    function spec = build_spec()
        spec.fs = fs;
        spec.prf = prf;
        spec.f0 = f0;
        spec.f1 = f1;
        spec.T_up = T_up;
        spec.T_down = T_down;

        spec.pri_samples  = fs / prf;

        spec.wf(1) = generate_chirp('up', T_up, f0, f1, fs);
        spec.wf(2) = generate_chirp('down', T_down, f1, f0, fs);
    end

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

        mf.up.wf = generate_chirp('up (decimated)', T_up, f0, f1, fs_dec);
        mf.up.h = generate_template(mf.up.wf.iq);
        mf.up.M = mf.up.wf.N;
        mf.up.delay_n = (mf.up.M - 1);
        mf.up.delay_t = mf.up.delay_n / fs_dec;

        mf.down.wf = generate_chirp('down (decimated)', T_down, f1, f0, fs_dec);
        mf.down.h = generate_template(mf.down.wf.iq);
        mf.down.M = mf.down.wf.N;
        mf.down.delay_n = (mf.down.M - 1);
        mf.down.delay_t = mf.down.delay_n / fs_dec;
    end

    function det = build_det()
        det.fs_dec = fs_dec;
        det.min_separation = min_separation;

        det.up.threshold = threshold_up;
        det.up.total_delay_n = cfg.mf.up.delay_n + cfg.lpf.delay_n / cfg.dec.D;
        det.up.total_delay_t = cfg.mf.up.delay_t + cfg.lpf.delay_t;
        det.up.N_tap = cfg.mf.up.M;

        det.down.threshold = threshold_down;
        det.down.total_delay_n = cfg.mf.down.delay_n + cfg.lpf.delay_n / cfg.dec.D;
        det.down.total_delay_t = cfg.mf.down.delay_t + cfg.lpf.delay_t;
        det.down.N_tap = cfg.mf.down.M;

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

function wf = generate_chirp(name, T, f0, f1, fs)
    N = round(T * fs);
    k = (f1 - f0) / T;
    t = (0:N-1)/fs;
    c = exp(1j*2*pi*(f0*t + 0.5*k*t.^2));
    iq = c.';
    wf = struct('name',name,'T',T,'N',N,'f0',f0,'f1',f1,'iq',iq);
end

function h = generate_template(iq)
    h = conj(flip(iq));
    h = h / sqrt(sum(abs(h).^2));
end
