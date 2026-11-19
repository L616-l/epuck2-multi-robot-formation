function [valid, quality, review] = validate_field_calibration(fit, independent, intrinsic, field, cfg, frame)
fit3d = [fit.world,zeros(size(fit.world,1),1)];
[predicted, forwardOK] = world_to_pixel(fit3d,intrinsic,field);
[ground, inverseOK] = pixel_to_world(independent.pixel,0,intrinsic,field);
quality.reprojectionPx = vecnorm(predicted-fit.pixel,2,2);
quality.validationMm = vecnorm(ground(:,1:2)-independent.world,2,2);
[~,fitArea] = convhull(fit.world(:,1),fit.world(:,2));
quality.fitCoverage = fitArea/(cfg.lengthMm*cfg.widthMm);
quality.maxReprojectionPx = max(quality.reprojectionPx);
quality.rmsReprojectionPx = sqrt(mean(quality.reprojectionPx.^2));
quality.maxValidationMm = max(quality.validationMm);
valid = all(forwardOK) && all(inverseOK) && ...
    quality.fitCoverage>=cfg.minFitCoverage && quality.maxReprojectionPx<=cfg.maxReprojectionPx ...
    && quality.maxValidationMm<=cfg.maxValidationMm;
fprintf('拟合点凸包覆盖场地面积比例 %.4f，要求至少 %.4f。\n',quality.fitCoverage,cfg.minFitCoverage);
disp(table(independent.world,ground(:,1:2),quality.validationMm, ...
    'VariableNames',{'MeasuredXY_mm','ConvertedXY_mm','Error_mm'}));
fprintf(['拟合点最大重投影 %.4f px（上限 %g，RMS %.4f px），' ...
    '独立验证点最大误差 %.4f mm（上限 %g）。\n'], ...
    quality.maxReprojectionPx,cfg.maxReprojectionPx,quality.rmsReprojectionPx, ...
    quality.maxValidationMm,cfg.maxValidationMm);
if ~all(forwardOK) || ~all(inverseOK)
    disp('部分点无法有效投影，请核对场地轴向与像素、实测坐标的对应关系。');
end
review = [];
if nargin == 6
    review = figure('Name','场地标定重投影检查','NumberTitle','off');
    ax = axes(review);
    imshow(frame,'Parent',ax);
    hold(ax,'on');
    plot(ax,fit.pixel(:,1),fit.pixel(:,2),'g+');
    plot(ax,predicted(:,1),predicted(:,2),'rx');
    plot(ax,independent.pixel(:,1),independent.pixel(:,2),'co');
    legend(ax,'拟合点','重投影','独立验证点');
end
end
