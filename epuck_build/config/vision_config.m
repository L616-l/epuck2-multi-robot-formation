function cfg = vision_config(project, names)
cfg = manage_config(project,"vision",@() collect(names),@(x) validate(x,names));
end

function cfg = collect(names)
families = squareFamilies();
disp('本平台支持的方形 AprilTag family：'); disp(families(:));
cfg.family = required_input("本组机器人使用的方形 AprilTag family：",@(x) ismember(x,families),false);
cfg.gaussianSigma = required_input("识别的高斯平滑标准差（非负）：",@nonnegative,true);
cfg.decimation = required_input("识别的图像降采样因子（正整数）：",@positiveInteger,true);
cfg.periodS = required_input("实时定位刷新间隔 (s)，须为 MATLAB timer 支持的毫秒整数倍：",@period,true);
cfg.maxPoseAgeS = required_input("允许的定位数据最大年龄 (s)，需大于刷新间隔：", ...
    @(x) positive(x) && x>cfg.periodS,true);
cfg.maxSideErrorMm = required_input("允许的 Tag 各边测量长度误差 (mm)：",@positive,true);
cfg.robotNames = names;
usedIds = NaN(1,numel(names));
for k = 1:numel(names)
    fprintf('机器人 %s 的安装参数\n',names(k));
    cfg.tags(k).id = required_input("Tag ID（不重复的非负整数）：", ...
        @(x) nonnegativeInteger(x) && ~ismember(x,usedIds),true);
    usedIds(k) = cfg.tags(k).id;
    cfg.tags(k).sizeMm = required_input("Tag 外侧黑边之间的边长 (mm)：",@positive,true);
    cfg.tags(k).heightMm = required_input("Tag 平面距地高度 (mm)：",@positive,true);
    cfg.tags(k).headingOffsetDeg = required_input("机器人车头相对 Tag 方向的逆时针角度偏移 (deg)：",@finiteScalar,true);
    xy = required_input("从 Tag 中心到机器人中心的位移 [向车头,向车左] (mm)：",@offset,true);
    cfg.tags(k).centerOffsetMm = xy(:).';
end
end

function validate(cfg,names)
assert(isequal(cfg.robotNames,names) && numel(cfg.tags)==numel(names), ...
    'epuck:InvalidConfig','视觉配置与通信配置的机器人名单或顺序不一致。请重新填写视觉配置。');
assert(isstring(cfg.family) && isscalar(cfg.family) && ismember(cfg.family,squareFamilies()) ...
    && nonnegative(cfg.gaussianSigma) && positiveInteger(cfg.decimation) ...
    && period(cfg.periodS) && positive(cfg.maxPoseAgeS) && cfg.maxPoseAgeS>cfg.periodS ...
    && positive(cfg.maxSideErrorMm) ...
    && numel(unique([cfg.tags.id]))==numel(cfg.tags), ...
    'epuck:InvalidConfig','视觉配置不完整或 Tag ID 重复。');
for tag = cfg.tags
    assert(nonnegativeInteger(tag.id) && positive(tag.sizeMm) && positive(tag.heightMm) ...
        && finiteScalar(tag.headingOffsetDeg) && offset(tag.centerOffsetMm), ...
        'epuck:InvalidConfig','Tag 安装参数不完整或无效。');
end
end

function families = squareFamilies()
families = ["tag16h5","tag25h9","tag36h11","tagCustom48h12","tagStandard41h12","tagStandard52h13"];
end

function ok = finiteScalar(x)
ok = isscalar(x) && isfinite(x);
end

function ok = nonnegative(x)
ok = finiteScalar(x) && x>=0;
end

function ok = positive(x)
ok = finiteScalar(x) && x>0;
end

function ok = nonnegativeInteger(x)
ok = nonnegative(x) && x==fix(x);
end

function ok = positiveInteger(x)
ok = positive(x) && x==fix(x);
end

function ok = offset(x)
ok = isvector(x) && numel(x)==2 && all(isfinite(x));
end

function ok = period(x)
milliseconds = x*1000;
ok = positive(x) && round(milliseconds)>=1 && abs(milliseconds-round(milliseconds))<=eps(milliseconds);
end
