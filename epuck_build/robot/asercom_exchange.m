function reply = asercom_exchange(port, command, expectedPattern)
% 单条 ASCII 命令和回包。只接受协议回包，串口打开不等于机器人在线。
timeout = port.Timeout;
cleanup = onCleanup(@() restoreTimeout(port,timeout));
flush(port,"input");
writeline(port,command);
started = tic;
while toc(started)<timeout
    remaining = timeout-toc(started);
    if remaining<=0
        break
    end
    port.Timeout = remaining;
    reply = readline(port);
    if isstring(reply) && isscalar(reply) && ~ismissing(reply) && ...
            ~isempty(regexp(char(strtrim(reply)),expectedPattern,'once'))
        return
    end
    if isempty(reply)
        break
    end
end
error('epuck:NoReply','串口 %s 未返回 %s 指令的有效 Asercom 回包。',port.Port,command);
end

function restoreTimeout(port,timeout)
if isvalid(port)
    port.Timeout = timeout;
end
end
