function platform = run_robot_control()
root = fileparts(mfilename('fullpath'));
addpath(fullfile(root,'common'));
project = initialize_project(root,"robot");
intrinsic = manage_calibration_result(project,"intrinsic");
field = manage_calibration_result(project,"field");
assert(isequal(field.intrinsicCalibratedAt,intrinsic.calibratedAt) && ...
    isequal(field.K,intrinsic.K) && isequal(field.imageSize,intrinsic.imageSize) ...
    && field.camera.name==intrinsic.camera.name && field.camera.index==intrinsic.camera.index ...
    && field.camera.resolution==intrinsic.camera.resolution ...
    && focus_matches(field.focus,intrinsic.focus) && field.focus.locked==intrinsic.focus.locked, ...
    'epuck:CalibrationPairMismatch','场地结果不对应这次内参。请运行 run_field_calibration。');
cfgCamera = camera_config(project);
robot = robot_config(project);
vision = vision_config(project,[robot.robots.name]);
cam = open_camera(cfgCamera);
focus = lock_camera_focus(cam,intrinsic.focus);
check_camera_calibration(cfgCamera,focus,intrinsic);
assert(all([vision.tags.heightMm] < (-field.R(:,3).'*field.t(:))), ...
    'epuck:TagHeight','Tag 安装高度必须低于相机光心，请检查高度和场地标定。');
tracker = create_pose_tracker(cam,intrinsic,field,vision,focus);
tracker.update();  % 先确认摄像头和识别函数可用，再连接机器人。
links = connect_robot_group(robot,project);
platform = open_robot_monitor(tracker,links,vision,project);
end
