function [pixel, valid] = world_to_pixel(world, intrinsic, field)
% 以 Xc=R*Xw+t 变换后，投到原始、有镜头畸变的像素坐标。
validateattributes(world,{'numeric'},{'2d','ncols',3,'real','finite'});
camera = double(world)*field.R.' + field.t(:).';
valid = camera(:,3)>0;
pixel = NaN(size(world,1),2);
if any(valid)
    transform = rigidtform3d(field.R,field.t(:).');
    pixel(valid,:) = world2img(double(world(valid,:)),transform, ...
        intrinsic.cameraParams.Intrinsics,ApplyDistortion=true);
end
valid = valid & all(isfinite(pixel),2);
pixel(~valid,:) = NaN;
end
