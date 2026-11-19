function state = camera_focus_readback(cam)
% USB 驱动可分别公开 FocusMode 和 Focus，两者都可能不可读。
state = struct('mode',"",'value',NaN,'locked',false);
try
    state.mode = lower(string(cam.FocusMode));
catch
    % 驱动没有公开该字段。
end
try
    value = cam.Focus;
    if isnumeric(value) && isscalar(value) && isfinite(value)
        state.value = double(value);
    end
catch
    % 驱动没有公开该字段。
end
end
