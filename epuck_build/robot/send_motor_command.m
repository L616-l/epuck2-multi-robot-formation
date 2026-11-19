function send_motor_command(port, encodedCommand)
% encodedCommand 只能由 motor_command_text 生成。
protocol = asercom_protocol();
asercom_exchange(port,encodedCommand,protocol.motorReply);
end
