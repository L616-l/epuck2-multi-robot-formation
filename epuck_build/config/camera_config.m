function cfg = camera_config(project)
cfg = manage_config(project,"camera",@collect,@validate,"摄像头");
fprintf('使用摄像头 %d：%s，分辨率 %s。\n',cfg.index,cfg.name,cfg.resolution);
end

function cfg = collect()
devices = string(webcamlist);
assert(~isempty(devices),'epuck:NoCamera','没有检测到摄像头。');
disp('检测到的摄像头：');
cfg.index = selectIndex(devices,"摄像头");
cfg.name = devices(cfg.index);
temporary = webcam(cfg.index);
available = string(temporary.AvailableResolutions);
clear temporary
assert(~isempty(available),'epuck:CameraChanged','所选摄像头没有报告可用分辨率。');
disp('可用分辨率（宽 × 高，单位 px）：');
cfg.resolution = available(selectIndex(available,"分辨率"));
end

function index = selectIndex(items,label)
for k = 1:numel(items)
    fprintf('  %d. %s\n',k,items(k));
end
index = required_input("输入" + label + "编号（1–" + numel(items) + "）：", ...
    @(x) isscalar(x) && ismember(x,1:numel(items)),true);
end

function validate(cfg)
devices = string(webcamlist);
assert(isscalar(cfg.index) && ismember(cfg.index,1:numel(devices)) ...
    && devices(cfg.index) == cfg.name, ...
    'epuck:CameraChanged','设备列表已变化，请重新填写摄像头配置。');
assert(isstring(cfg.resolution) && isscalar(cfg.resolution) && strlength(cfg.resolution)>0, ...
    'epuck:InvalidConfig','摄像头分辨率配置无效，请重新选择。');
end
