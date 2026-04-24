function [corr_up, corr_down] = matched_filter(x, mf_cfg)
    corr_up = filter(mf_cfg.h_up, 1, x);
    corr_down = filter(mf_cfg.h_down, 1, x);
end