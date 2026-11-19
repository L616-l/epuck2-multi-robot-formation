function cfg = field_config(project)
cfg = manage_config(project,"field",@collect,@validate,"场地标定");
end

function cfg = collect()
disp('先确定场地原点和轴向。沿两条相邻边测量，长度和坐标统一用毫米。');
cfg.origin = required_input("用实物位置描述原点角，例如 靠门且靠窗的角：",@hasText,false);
cfg.xDirection = required_input("描述 +X 从原点沿哪条边指向场内，例如 沿窗边朝讲台：",@hasText,false);
cfg.yDirection = required_input("描述 +Y 从原点沿哪条垂直边指向场内，例如 沿门侧边朝白板：",@hasText,false);
cfg.zDirection = "垂直地面向上";
assert(confirm_choice("从场地上方看，+X 朝 +Y 逆时针转 90°。确认坐标轴满足这个方向？"), ...
    'epuck:Cancelled','请重新选择坐标轴。');
cfg.lengthMm = required_input("沿 +X 实测的场地长度 (mm)，须为正数，例如 2000：",@positive,true);
cfg.widthMm = required_input("沿 +Y 实测的场地宽度 (mm)，须为正数，例如 1500：",@positive,true);
cfg.fitCount = required_input("拟合点数，至少 4 个，均匀分布且尽量靠近四周，例如 6：", ...
    @(x) count(x,4),true);
cfg.validationCount = required_input("独立验证点数，至少 2 个，使用不同于拟合点的标志，例如 4：", ...
    @(x) count(x,2),true);
cfg.minFitCoverage = required_input("拟合点凸包最少覆盖场地的比例，大于 0 且不超过 1，例如 0.6 表示 60%：",@coverage,true);
cfg.maxReprojectionPx = required_input("拟合点最大重投影误差上限 (px)，须为正数，例如 2：",@positive,true);
cfg.maxValidationMm = required_input("验证点换算坐标与实测坐标的最大距离上限 (mm)，须为正数，例如 5：",@positive,true);
end

function validate(cfg)
assert(positive(cfg.lengthMm) && positive(cfg.widthMm) && hasText(cfg.origin) ...
    && hasText(cfg.xDirection) && hasText(cfg.yDirection) ...
    && cfg.zDirection=="垂直地面向上" && count(cfg.fitCount,4) ...
    && count(cfg.validationCount,2) && coverage(cfg.minFitCoverage) && positive(cfg.maxReprojectionPx) ...
    && positive(cfg.maxValidationMm),'epuck:InvalidConfig','场地配置不完整或无效，请重新填写。');
end

function ok = positive(x)
ok = isscalar(x) && isfinite(x) && x>0;
end

function ok = count(x,minimum)
ok = positive(x) && x==fix(x) && x>=minimum;
end

function ok = coverage(x)
ok = positive(x) && x<=1;
end

function ok = hasText(x)
ok = isstring(x) && isscalar(x) && strlength(x)>0;
end
