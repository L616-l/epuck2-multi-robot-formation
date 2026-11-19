function tracker = create_pose_tracker(cam, intrinsic, field, cfg, focus)
% 每次更新共用一帧图像。缺失或过期位置不返回上一帧的有效数值。
poses = estimate_robot_pose([],[],cfg,intrinsic,field,NaT('TimeZone','local'));
frameStarted = [];
active = true;
busy = false;
tracker = struct('update',@update,'getPose',@getPose,'close',@closeTracker);

    function update()
        assert(active,'epuck:ClosedSession','定位会话已关闭。');
        if busy
            return
        end
        busy = true;
        cleanup = onCleanup(@releaseUpdate);
        started = tic;
        capturedAt = datetime('now','TimeZone','local');
        try
            frame = get_camera_frame(cam,intrinsic.imageSize);
            assert(focus_matches(camera_focus_readback(cam),focus), ...
                'epuck:FocusChanged','对焦发生变化，请检查内参或重新标定。');
            [ids,corners] = detect_apriltags(frame,cfg);
            next = estimate_robot_pose(ids,corners,cfg,intrinsic,field,capturedAt);
            if active
                poses = next;
                frameStarted = started;
            end
        catch err
            if active
                poses = estimate_robot_pose([],[],cfg,intrinsic,field,capturedAt);
                for k = 1:numel(poses)
                    poses(k).reason = "visionError: " + string(err.message);
                end
            end
            rethrow(err)
        end
    end

    function pose = getPose(k)
        pose = poses(k);
        if ~active
            pose.reason = "sessionClosed";
        elseif pose.valid && toc(frameStarted)>cfg.maxPoseAgeS
            pose.reason = "stalePose";
        else
            return
        end
        pose.valid = false;
        pose.positionMm = [NaN NaN];
        pose.headingDeg = NaN;
        pose.tagCenterMm = [NaN NaN NaN];
        pose.tagHeadingDeg = NaN;
    end

    function releaseUpdate()
        busy = false; %#ok<MOCUP> busy 由追踪器句柄共享，取帧守卫销毁时仍有效。
    end

    function closeTracker()
        active = false;
        cam = [];
    end
end
