function cam = open_camera(cfg)
devices = string(webcamlist);
assert(isscalar(cfg.index) && ismember(cfg.index,1:numel(devices)) ...
    && devices(cfg.index) == cfg.name,'epuck:CameraChanged', ...
    '摄像头编号或名称与记录不符。请核对设备列表；场地标定须使用内参记录的相机。');
if nnz(devices == cfg.name) > 1
    assert(confirm_choice("存在同名设备。请核对编号 " + cfg.index + " 对应的实物，确认继续？"), ...
        'epuck:Cancelled','已取消摄像头选择。');
end
cam = webcam(cfg.index);
assert(string(cam.Name) == cfg.name,'epuck:CameraChanged','打开的摄像头名称与记录不符。');
assert(ismember(cfg.resolution,string(cam.AvailableResolutions)),'epuck:CameraChanged', ...
    '摄像头已不支持记录的分辨率 %s。请在内参标定中重新选择分辨率。',cfg.resolution);
cam.Resolution = char(cfg.resolution);
assert(string(cam.Resolution) == cfg.resolution,'epuck:CameraChanged','分辨率设置失败。');
end
