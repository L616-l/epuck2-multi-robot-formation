function result = run_intrinsic_calibration()
% 单独运行内参标定。成功保存后也可接收本次结果。
root = fileparts(mfilename('fullpath'));
addpath(fullfile(root,'common'));
project = initialize_project(root,"intrinsic");
cfgCamera = camera_config(project);
cfg = intrinsic_config(project);
cam = open_camera(cfgCamera);
focus = lock_camera_focus(cam);
while true
    [points, frame, imageSize] = collect_intrinsic_images(cam,cfg,focus);
    valid = false;
    review = [];
    try
        result = solve_intrinsics(points,imageSize,cfg);
        [valid, review] = validate_intrinsics(result,cfg,frame);
    catch err
        fprintf('内参求解或验证失败：%s\n',err.message);
    end
    accepted = valid && confirm_choice("检查去畸变图像后确认接受本次结果？");
    if accepted
        break
    end
    if isgraphics(review)
        close(review);
    end
    assert(confirm_choice("本次结果未通过或未接受。重新采集？"), ...
        'epuck:Cancelled','未保存内参结果。');
end
result.camera = cfgCamera;
result.focus = focus;
result.config = cfg;
result.imagePoints = points;
result.calibratedAt = datetime('now','TimeZone','local');
manage_calibration_result(project,"intrinsic",result);
log_event(project,"已保存内参标定");
end
