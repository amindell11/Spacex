function [corr_up, corr_down] = matched_filter(x, mf_cfg)
    corr_up = filter(mf_cfg.up.h, 1, x);
    corr_down = filter(mf_cfg.down.h, 1, x);
end