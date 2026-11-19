function reason = validate_tag_geometry(corners, valid, tag, cfg)
if ~all(valid)
    reason = "rayDoesNotMeetTagPlane";
    return
end
edges = corners([2 3 4 1],1:2)-corners(:,1:2);
if any(abs(vecnorm(edges,2,2)-tag.sizeMm)>cfg.maxSideErrorMm)
    reason = "tagSizeMismatch";
    return
end
% 四个角必须构成凸四边形，避免共线、交叉或重合的退化检测。
next = edges([2 3 4 1],:);
turn = edges(:,1).*next(:,2)-edges(:,2).*next(:,1);
if ~(all(turn>0) || all(turn<0))
    reason = "invalidTagGeometry";
    return
end
% 等边的菱形也能通过边长检查。再核对两条对角线的长度。
diagonals = corners([3 4],1:2)-corners([1 2],1:2);
if any(abs(vecnorm(diagonals,2,2)-sqrt(2)*tag.sizeMm)>sqrt(2)*cfg.maxSideErrorMm)
    reason = "invalidTagGeometry";
    return
end
reason = "";
end
