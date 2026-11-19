function state = lock_camera_focus(cam, reference)
% 首次使用自动对焦读值。复用标定时尝试重现已验证的手动读值。
if nargin == 2 && reference.locked
    requested = reference.value;
else
    if nargin == 1
        try
            cam.FocusMode = 'auto';
        catch err
            fprintf('驱动未接受自动对焦设置：%s\n',err.message);
        end
        preview(cam);
        cleanup = onCleanup(@() closePreview(cam));
        assert(confirm_choice("等待画面清晰且自动对焦稳定后确认读取？"), ...
            'epuck:Cancelled','已取消对焦。');
        before = camera_focus_readback(cam);
        clear cleanup
        fprintf('驱动读回：模式 %s，对焦控制值 %g（NaN 表示不可读）。\n',before.mode,before.value);
        assert(confirm_choice("确认使用当前读值，若可用则尝试切换手动并锁定？"), ...
            'epuck:Cancelled','已取消对焦。');
        requested = before.value;
    else
        requested = NaN;
    end
end
if isfinite(requested)
    try
        cam.FocusMode = 'manual';
        cam.Focus = requested;
    catch err
        fprintf('驱动未接受锁焦设置：%s\n',err.message);
    end
end
state = camera_focus_readback(cam);
state.locked = isfinite(requested) && focus_matches(state,struct('mode',"manual",'value',requested));
if state.locked
    fprintf('驱动确认手动对焦，对焦控制值 %g。\n',state.value);
elseif nargin == 2 && reference.locked
    error('epuck:FocusChanged','无法重现标定的手动对焦值，请检查摄像头或重做内参。');
else
    warning('epuck:FocusUnverified','驱动未能确认锁焦，自动对焦变化可能影响标定。');
    preview(cam);
    cleanup = onCleanup(@() closePreview(cam));
    assert(confirm_choice("确认当前画面清晰，并继续使用未验证锁焦的设置？"), ...
        'epuck:Cancelled','已退出。');
    clear cleanup
    state = camera_focus_readback(cam);
end
if nargin == 2 && ~focus_matches(state,reference)
    error('epuck:FocusChanged','当前对焦模式或可读值和内参记录不同，请重做内参。');
end
end
