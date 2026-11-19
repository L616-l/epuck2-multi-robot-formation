function platform = open_robot_monitor(tracker, links, vision, project)
% 定时刷新与用户电机命令相互独立，窗口关闭时释放本次资源。
closed = false;
lastVisionError = "";
monitor = [];
clock = [];
try
    for k = numel(links):-1:1
        robots(k) = makeApi(k);
    end
    monitor = figure('Name','e-puck2 实时定位','NumberTitle','off', ...
        'MenuBar','none','ToolBar','none','CloseRequestFcn',@(~,~) closeSession(), ...
        'DeleteFcn',@(~,~) closeSession());
    display = uitable(monitor,'Units','normalized','Position',[0 0 1 1], ...
        'ColumnName',{'机器人','Tag ID','X (mm)','Y (mm)','车头角 (deg)', ...
        'Tag 角 (deg)','定位有效','串口在线*','定位说明'},'RowName',[]);
    refreshDisplay();
    clock = timer('ExecutionMode','fixedSpacing','Period',vision.periodS, ...
        'StartDelay',vision.periodS,'TimerFcn',@(~,~) update());
    start(clock);
catch err
    closeSession();
    rethrow(err)
end
platform = struct('robots',robots,'update',@update,'close',@closeSession);
log_event(project,"底层平台已启动，未发送电机指令");
fprintf('已启动实时定位。关闭监视窗口或调用 platform.close() 可结束会话。\n');

    function api = makeApi(index)
        api = create_robot_api(vision.robotNames(index),links{index},@() tracker.getPose(index));
    end

    function update()
        assert(~closed,'epuck:ClosedSession','平台会话已关闭。');
        try
            tracker.update();
            lastVisionError = "";
        catch err
            message = string(err.message);
            if message ~= lastVisionError
                log_event(project,"定位更新异常：" + message);
                lastVisionError = message;
            end
        end
        refreshDisplay();
    end

    function refreshDisplay()
        if closed || ~isgraphics(display)
            return
        end
        rows = cell(numel(robots),9);
        for n = 1:numel(robots)
            pose = robots(n).getPose();
            status = links{n}.status();
            rows(n,:) = {char(pose.name),pose.tagId,pose.positionMm(1),pose.positionMm(2), ...
                pose.headingDeg,pose.tagHeadingDeg,pose.valid,status.connected,char(pose.reason)};
        end
        display.Data = rows;
    end

    function closeSession()
        if closed
            return
        end
        closed = true;
        if ~isempty(clock) && isvalid(clock)
            stop(clock);
            delete(clock);
        end
        tracker.close();
        disconnect_robot_group(links,project);
        if isgraphics(monitor) && strcmp(monitor.BeingDeleted,'off')
            delete(monitor);
        end
        log_event(project,"底层平台会话已关闭");
    end
end
