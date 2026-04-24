function s = set_nested(s, path, v)
    if numel(path) == 1
        s.(path{1}) = v;
    else
        s.(path{1}) = set_nested(s.(path{1}), path(2:end), v);
    end
end
