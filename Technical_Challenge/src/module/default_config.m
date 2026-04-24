function cfg = default_config()
% SPEC CONSTANTS (DO NOT CHANGE)
    fs = 100e6;
    prf = 1e3;
    T_up = 100e-6;
    T_down = 200e-6;
    f0 = 30e3;
    f1 = 60e3;

%SYSTEM PARAMS
    fs_dec = 500e3; %
    f_pass = 100e3; % passband for AA filter - set safely above the signal band at 60kHz

%Load into cfg structs
    cfg.fs = fs;
    cfg.in = in_config(fs, prf, T_up, T_down, f0, f1);
    cfg.dec = decim_config(fs, fs_dec);
    cfg.lpf = lpf_config(fs, f_pass, fs_dec);
    cfg.mf = mf_config(cfg.in, cfg.dec);
end

function in = in_config(fs, prf, T_up, T_down, f0, f1)
    in.fs = fs;
    in.prf = prf;
    in.f0 = f0;
    in.f1 = f1;
    in.T_up = T_up;
    in.T_down = T_down;

    in.pri_samples  = fs / prf;

    in.wf(1) = generate_chirp('up', T_up, f0, f1, fs);
    in.wf(2) = generate_chirp('down', T_down, f1, f0, fs);
end

function dec = decim_config(fs, fs_dec)
    dec.fs_dec = fs_dec;
    dec.D = fs / fs_dec;
end

function lpf = lpf_config(fs, f_pass, fs_dec)
    df = (fs_dec /2) - f_pass;
    lpf.fs = fs;
    lpf.df = df;
    lpf.fc = f_pass + df/2;
    lpf.N = 2 * round(1.65/(df/fs)) + 1;
    lpf.h = generate_lpf(fs, lpf.fc, lpf.N);
    lpf.group_delay = (lpf.N - 1) / 2;
end

function mf = mf_config(in, dec)
    fs_dec = dec.fs_dec;
    mf.wf_up = generate_chirp('up (decimated)', in.T_up, in.f0, in.f1, fs_dec);
    mf.wf_down = generate_chirp('down (decimated)', in.T_down, in.f1, in.f0, fs_dec);
    mf.h_up = generate_template(mf.wf_up.iq);
    mf.h_down = generate_template(mf.wf_down.iq);

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