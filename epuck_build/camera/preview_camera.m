function frame = preview_camera(cam, expectedSize)
% 在预览仍显示时取帧，返回供选点的图像。
preview(cam);
cleanup = onCleanup(@() closePreview(cam));
wait_for_capture("确认场地和各个标志点清晰可见后，在 MATLAB 命令行冻结当前画面");
frame = get_camera_frame(cam,expectedSize);
end
