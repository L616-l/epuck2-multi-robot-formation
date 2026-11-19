function [world, valid] = pixel_to_world(pixel, planeZMm, intrinsic, field)
% 原始像素去畸变后生成射线，与世界平面 Z=planeZMm 求交。
validateattributes(pixel,{'numeric'},{'2d','ncols',2,'real','finite'});
validateattributes(planeZMm,{'numeric'},{'scalar','real','finite'});
if isempty(pixel)
    world = zeros(0,3);
    valid = false(0,1);
    return
end
ideal = undistortPoints(double(pixel),intrinsic.cameraParams.Intrinsics);
raysCamera = (intrinsic.K \ [ideal,ones(size(ideal,1),1)].').';
origin = (-field.R.' * field.t(:)).';
raysWorld = raysCamera * field.R;
scale = (planeZMm-origin(3))./raysWorld(:,3);
world = origin + scale.*raysWorld;
valid = scale>0 & all(isfinite(world),2);
world(valid,3) = planeZMm;
world(~valid,:) = NaN;
end
