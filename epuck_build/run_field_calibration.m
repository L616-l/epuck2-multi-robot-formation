function field = run_field_calibration()
root = fileparts(mfilename('fullpath'));
addpath(fullfile(root,'common'));
project = initialize_project(root,"field");
intrinsic = manage_calibration_result(project,"intrinsic");
cfgCamera = intrinsic.camera;
fprintf('沿用内参记录的摄像头 %d：%s，分辨率 %s。\n',cfgCamera.index,cfgCamera.name,cfgCamera.resolution);
cfg = field_config(project);
fprintf('场地 %.6g × %.6g mm。原点：%s。+X：%s。+Y：%s。\n', ...
    cfg.lengthMm,cfg.widthMm,cfg.origin,cfg.xDirection,cfg.yDirection);
cam = open_camera(cfgCamera);
focus = lock_camera_focus(cam,intrinsic.focus);
while true
    frame = preview_camera(cam,intrinsic.imageSize);
    frameFocus = camera_focus_readback(cam);
    frameFocus.locked = focus.locked && focus_matches(frameFocus,focus);
    check_camera_calibration(cfgCamera,frameFocus,intrinsic);
    [fit, independent] = collect_field_points(frame,cfg);
    valid = false;
    review = [];
    try
        field = solve_extrinsics(fit,intrinsic);
        [valid, quality, review] = validate_field_calibration(fit,independent,intrinsic,field,cfg,frame);
    catch err
        fprintf('场地外参求解或验证失败：%s\n',err.message);
    end
    if valid && confirm_choice("确认保存本次场地标定？")
        break
    end
    if isgraphics(review)
        close(review);
    end
    assert(confirm_choice("重新预览、取图并选点？"), ...
        'epuck:Cancelled','未保存外参结果。');
end
field.layout = cfg;
field.originWorldMm = [0 0 0];
field.camera = cfgCamera;
field.focus = frameFocus;
field.imageSize = intrinsic.imageSize;
field.intrinsicCalibratedAt = intrinsic.calibratedAt;
field.fit = fit;
field.independent = independent;
field.quality = quality;
field.calibratedAt = datetime('now','TimeZone','local');
manage_calibration_result(project,"field",field);
log_event(project,"已保存场地标定");
end
