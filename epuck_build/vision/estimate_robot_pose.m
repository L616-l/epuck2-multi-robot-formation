function pose = estimate_robot_pose(ids, pixels, cfg, intrinsic, field, capturedAt)
for k = numel(cfg.tags):-1:1
    tag = cfg.tags(k);
    pose(k) = struct('name',cfg.robotNames(k),'tagId',tag.id,'positionMm',[NaN NaN], ...
        'headingDeg',NaN,'valid',false,'reason',"tagNotFound",'capturedAt',capturedAt, ...
        'tagCenterMm',[NaN NaN NaN],'tagHeadingDeg',NaN);
    match = find(ids == tag.id);
    if numel(match)>1
        pose(k).reason = "duplicateTagId";
    elseif isscalar(match)
        pose(k) = locate(pose(k),pixels(:,:,match),tag,cfg,intrinsic,field);
    end
end
end

function pose = locate(pose,pixels,tag,cfg,intrinsic,field)
if ~all(isfinite(pixels),'all') || any(pixels(:,1)<1 | pixels(:,1)>intrinsic.imageSize(2) ...
        | pixels(:,2)<1 | pixels(:,2)>intrinsic.imageSize(1))
    pose.reason = "cornersOutsideImage";
    return
end
[corners, valid] = pixel_to_world(pixels,tag.heightMm,intrinsic,field);
pose.reason = validate_tag_geometry(corners,valid,tag,cfg);
if strlength(pose.reason)>0
    return
end
center = mean(corners,1);
% 以解码后的第 1→2 角为 Tag 正方向，用对边第 4→3 角共同估计。
axisXY = corners(2,1:2)-corners(1,1:2) + corners(3,1:2)-corners(4,1:2);
if ~any(axisXY)
    pose.reason = "invalidTagDirection";
    return
end
tagHeading = mod(atan2d(axisXY(2),axisXY(1))+180,360)-180;
heading = mod(tagHeading+tag.headingOffsetDeg+180,360)-180;
forward = [cosd(heading) sind(heading)];
left = [-forward(2) forward(1)];
xy = center(1:2) + tag.centerOffsetMm(1)*forward + tag.centerOffsetMm(2)*left;
pose.tagCenterMm = center;
pose.tagHeadingDeg = tagHeading;
if any(xy<0) || any(xy>[field.layout.lengthMm field.layout.widthMm])
    pose.reason = "centerOutsideField";
    return
end
pose.positionMm = xy;
pose.headingDeg = heading;
pose.valid = true;
end
