function links = connect_robot_group(cfg, project)
links = cell(1,numel(cfg.robots));
for k = 1:numel(cfg.robots)
    device = cfg.robots(k);
    try
        links{k} = connect_epuck(device,cfg);
        fprintf('%s (%s) 已通过只读通信验证。\n',device.name,device.port);
        log_event(project,device.name + " 通过只读 Asercom 探测");
    catch err
        disconnect_robot_group(links,project);
        rethrow(err)
    end
end
end
