function link = connect_epuck(device, cfg, openPort)
% 初始化只发 N（读传感器）。直到调用者主动发电机命令，才可能发 D。
if nargin<3
    openPort = @(name,baud,timeout) serialport(name,baud,Timeout=timeout);
end
port = openPort(device.port,cfg.baudRate,cfg.timeoutS);
protocol = asercom_protocol();
try
    configureTerminator(port,protocol.terminator);
    probe_asercom_connection(port);
catch err
    disconnect_epuck(port);
    rethrow(err)
end
possiblyMoving = false;
busy = false;
disconnectPending = false;
lastContact = datetime('now','TimeZone','local');
lastError = "";
online = true;
link = struct('send',@send,'stop',@stop,'probe',@probe, ...
    'status',@status,'disconnect',@disconnect);

    function send(left,right)
        command = motor_command_text(left,right);
        if left==0 && right==0
            stop();
            return
        end
        guard = acquire(); %#ok<NASGU> 守卫在函数退出时释放串口请求。
        % 发送失败时也可能已到达机器人，保留停车意图。
        possiblyMoving = true;
        transact(@() send_motor_command(port,command));
    end

    function stop()
        guard = acquire(); %#ok<NASGU>
        transact(@() stop_robot(port));
        possiblyMoving = false;
    end

    function ok = probe()
        if ~isvalid(port) || disconnectPending || busy
            ok = false;
            return
        end
        guard = acquire(); %#ok<NASGU>
        try
            transact(@() probe_asercom_connection(port));
            ok = true;
        catch
            ok = false;
        end
    end

    function result = status()
        result = struct('connected',isvalid(port) && online && ~disconnectPending, ...
            'portOpen',isvalid(port),'lastContact',lastContact,'message',lastError);
    end

    function disconnect()
        if ~isvalid(port) || disconnectPending
            return
        end
        % 窗口关闭可能与串口请求交错。当前请求结束后先停车，再释放串口。
        disconnectPending = true;
        if ~busy
            finishDisconnect();
        end
    end

    function finishDisconnect()
        cleanup = onCleanup(@() disconnect_epuck(port));
        if possiblyMoving
            transact(@() stop_robot(port));
            possiblyMoving = false;
        end
    end

    function guard = acquire()
        assert(isvalid(port) && ~disconnectPending,'epuck:Disconnected','串口正在关闭或已断开。');
        assert(~busy,'epuck:SerialBusy','该机器人正在处理另一条串口请求，请稍后再试。');
        busy = true;
        guard = onCleanup(@release);
    end

    function release()
        busy = false; %#ok<MOCUP> busy 由会话句柄共享，串口守卫销毁时仍有效。
        if disconnectPending
            try
                finishDisconnect();
            catch err
                warning('epuck:DisconnectFailed','当前串口请求结束后，未能确认机器人停车：%s',err.message);
            end
        end
    end

    function transact(action)
        try
            action();
            lastContact = datetime('now','TimeZone','local');
            lastError = "";
            online = true;
        catch err
            online = false;
            lastError = string(err.message);
            rethrow(err)
        end
    end
end
