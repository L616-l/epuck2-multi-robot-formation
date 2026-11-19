function stop_robot(port)
send_motor_command(port,motor_command_text(0,0));
% D 的 d 回包不带序号。用不同的只读命令确认两轮速度设定值已归零。
protocol = asercom_protocol();
reply = asercom_exchange(port,protocol.readMotorSpeed,protocol.speedReply);
speed = sscanf(char(strtrim(reply)),'e,%d,%d');
assert(numel(speed)==2 && all(speed==0),'epuck:StopNotConfirmed', ...
    '串口 %s 未确认两轮速度设定值归零。读取结果：%s。',port.Port,reply);
end
