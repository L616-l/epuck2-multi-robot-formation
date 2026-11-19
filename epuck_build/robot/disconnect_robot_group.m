function disconnect_robot_group(links, project)
% 即使某台设备未确认停车，也继续释放其他设备。
for k = 1:numel(links)
    if isempty(links{k})
        continue
    end
    try
        links{k}.disconnect();
    catch err
        warning('epuck:DisconnectFailed','第 %d 台机器人关闭时发生错误：%s',k,err.message);
        log_event(project,"机器人关闭错误：" + string(err.message));
    end
end
end
