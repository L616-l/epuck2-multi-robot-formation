function [valid, review] = validate_intrinsics(result, cfg, frame)
disp('内参矩阵 K（焦距单位为像素）');
disp(result.K);
disp('径向畸变'); disp(result.radialDistortion);
disp('切向畸变'); disp(result.tangentialDistortion);
fprintf(['平均重投影误差 %.4f px。整体 RMS %.4f px（上限 %g），' ...
    '最大单幅 RMS %.4f px（上限 %g）。\n'], ...
    result.meanReprojectionErrorPx,result.rmsPx,cfg.maxRmsPx,max(result.viewRmsPx),cfg.maxViewRmsPx);
exceeded = find(result.viewRmsPx > cfg.maxViewRmsPx);
if ~isempty(exceeded)
    fprintf('单幅误差超限的图像编号：%s。\n',strjoin(string(exceeded),', '));
end
valid = isfinite(result.rmsPx) && result.rmsPx <= cfg.maxRmsPx ...
    && all(result.viewRmsPx <= cfg.maxViewRmsPx) ...
    && all(isfinite(result.K(:))) && result.fx>0 && result.fy>0;
review = [];
if ~valid
    disp('内参未通过质量检查，请检查采集角度、清晰度和上述误差。');
end
if nargin == 3 && valid
    corrected = undistortImage(frame,result.cameraParams);
    review = figure('Name','内参标定与去畸变对比','NumberTitle','off');
    layout = tiledlayout(review,1,2);
    rawAxes = nexttile(layout);
    imshow(frame,'Parent',rawAxes);
    title(rawAxes,'原始图像');
    correctedAxes = nexttile(layout);
    imshow(corrected,'Parent',correctedAxes);
    title(correctedAxes,'去畸变图像');
end
end
