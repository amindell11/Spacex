  function s = cfg_spec()
      s.fs = 100e6;
      s.prf = 1e3;
      s.T_up = 100e-6;
      s.T_down = 200e-6;
      s.f0 = 30e3;
      s.f1 = 60e3;
      s.pri_samples = s.fs / s.prf;
      s.make_chirp = @(name, fs) make_chirp(s, name, fs);
  end

  function wf = make_chirp(spec, name, fs)
      switch name
        case 'up',   T = spec.T_up;   f0 = spec.f0; f1 = spec.f1;
        case 'down', T = spec.T_down; f0 = spec.f1; f1 = spec.f0;
      end
      N = round(T * fs);
      k = (f1 - f0) / T;
      t = (0:N-1)/fs;
      iq = exp(1j*2*pi*(f0*t + 0.5*k*t.^2)).';
      wf = struct('name',name,'T',T,'N',N,'f0',f0,'f1',f1,'iq',iq);
  end