function cfg = intrinsic_config(project)
cfg = manage_config(project,"intrinsic",@collect,@validate,"内参标定");
end

function cfg = collect()
disp('填写棋盘规格、采集计划和验收阈值。括号内的数值是输入示例。');
cfg.boardSquares = required_input("棋盘 [短边方格数,长边方格数]，数黑白方格。两边至少 4 格且一奇一偶，例如 [7,8]：",@board,true);
cfg.squareMm = required_input("实测单格边长 (mm)，须为正数，例如 24.5：",@positive,true);
cfg.imageCount = required_input("计划采集的有效图像数，至少 3 张，例如 15：",@imageCount,true);
cfg.radialTerms = required_input("径向畸变系数个数，输入 2 或 3。常用 2，需要拟合更高阶畸变时用 3：", ...
    @(x) isscalar(x) && ismember(x,[2 3]),true);
cfg.maxRmsPx = required_input("所有角点的重投影均方根误差上限 (px)，须为正数，例如 0.5：",@positive,true);
cfg.maxViewRmsPx = required_input("单张图像的重投影均方根误差上限 (px)，须为正数，例如 1：",@positive,true);
end

function validate(cfg)
assert(board(cfg.boardSquares) && positive(cfg.squareMm) && imageCount(cfg.imageCount) ...
    && isscalar(cfg.radialTerms) && ismember(cfg.radialTerms,[2 3]) ...
    && positive(cfg.maxRmsPx) && positive(cfg.maxViewRmsPx), ...
    'epuck:InvalidConfig','内参配置不完整或无效，请重新填写。');
end

function ok = board(x)
ok = isvector(x) && numel(x)==2 && all(isfinite(x)) && all(x==fix(x)) ...
    && all(x>=4) && x(1)<x(2) && mod(x(1),2)~=mod(x(2),2);
end

function ok = imageCount(x)
ok = positive(x) && x==fix(x) && x>=3;
end

function ok = positive(x)
ok = isscalar(x) && isfinite(x) && x>0;
end
