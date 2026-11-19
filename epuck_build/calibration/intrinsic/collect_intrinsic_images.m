function [points, sample, imageSize] = collect_intrinsic_images(cam, cfg, focus)
preview(cam);
cleanup = onCleanup(@() closePreview(cam));
fprintf(['移动棋盘，在画面各区域采集不同距离和倾角的清晰图像。\n' ...
    '每张图都需包含完整棋盘。请在 MATLAB 命令行按回车取帧。\n']);
imageSize = [];
for k = 1:cfg.imageCount
    while true
        wait_for_capture("采集第 " + k + "/" + cfg.imageCount + " 张有效棋盘图像");
        frame = get_camera_frame(cam);
        frameSize = size(frame,[1 2]);
        if isempty(imageSize)
            imageSize = frameSize;
        end
        assert(isequal(frameSize,imageSize),'epuck:FrameSize','图像尺寸发生变化，请检查相机分辨率。');
        assert(focus_matches(camera_focus_readback(cam),focus), ...
            'epuck:FocusChanged','采集时对焦读值发生变化，请检查锁焦后重新标定。');
        [corners, board] = detectCheckerboardPoints(frame,PartialDetections=false);
        if isempty(corners)
            disp('未识别到完整棋盘，请检查清晰度，确保棋盘四边都在画面内。');
            continue
        end
        if ~isequal(board(:),cfg.boardSquares(:))
            fprintf('识别到 %d × %d 格，设定为 %d × %d 格。请检查方格数或调整棋盘后重拍。\n', ...
                board(1),board(2),cfg.boardSquares(1),cfg.boardSquares(2));
            continue
        end
        if k == 1
            points = NaN(size(corners,1),2,cfg.imageCount);
            sample = frame;
        end
        if k>1 && any(all(points(:,:,1:k-1)==corners,[1 2]))
            disp('棋盘角点与已采集图像完全相同，请移动并倾斜棋盘后再拍。');
            continue
        end
        points(:,:,k) = corners;
        fprintf('已采集 %d/%d 张有效图像，本张识别到 %d 个内角点。\n',k,cfg.imageCount,size(corners,1));
        break
    end
end
end
