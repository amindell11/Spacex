function y = aa_decimate(x, cfg)
    y = lpf(x, cfg.lpf);
    y = decimate(y, cfg.dec.D);
end

function y = lpf(x, lpf_cfg)
    y = conv(x,lpf_cfg.h);
end

function y = decimate(x, D)
    y = x(1:D:end);
end


