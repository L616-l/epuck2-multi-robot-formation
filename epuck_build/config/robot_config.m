function cfg = robot_config(project)
cfg = manage_config(project,"robot",@collect,@validate);
end

function cfg = collect()
cfg.baudRate = required_input("蓝牙 UART 虚拟串口的波特率：",@positiveInteger,true);
cfg.timeoutS = required_input("串口请求超时 (s)：",@positive,true);
count = required_input("机器人数量：",@positiveInteger,true);
usedNames = strings(1,count);
usedPorts = strings(1,count);
cfg.robots = repmat(struct('name',"",'port',""),1,count);
for k = 1:count
    name = required_input("第 " + k + " 台机器人唯一编号或名称：", ...
        @(x) hasText(x) && ~ismember(x,usedNames),false);
    port = upper(required_input("该机器人的蓝牙出站 UART 串口（完整 COM 名称，不能重复）：", ...
        @(x) validPort(x) && ~ismember(upper(x),usedPorts),false));
    cfg.robots(k) = struct('name',name,'port',port);
    usedNames(k) = name;
    usedPorts(k) = port;
end
end

function validate(cfg)
names = [cfg.robots.name];
ports = upper([cfg.robots.port]);
assert(positiveInteger(cfg.baudRate) && positive(cfg.timeoutS) && ~isempty(names) ...
    && all(strlength(names)>0) && numel(unique(names))==numel(names) ...
    && all(~cellfun(@isempty,regexp(cellstr(ports),'^COM[1-9][0-9]*$','once'))) && numel(unique(ports))==numel(ports), ...
    'epuck:InvalidConfig','请填写有效的串口配置，机器人名称和串口均不能重复。');
end

function ok = positive(x)
ok = isscalar(x) && isfinite(x) && x>0;
end

function ok = positiveInteger(x)
ok = positive(x) && x==fix(x);
end

function ok = hasText(x)
ok = isstring(x) && isscalar(x) && strlength(x)>0;
end

function ok = validPort(x)
ok = hasText(x) && ~isempty(regexpi(char(x),'^COM[1-9][0-9]*$','once'));
end
