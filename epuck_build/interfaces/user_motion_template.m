function result = user_motion_template(robotAPI, userConfig) %#ok<INUSD>
% 复制本文件并重命名函数后可编写运动程序。
% robotAPI 是 run_robot_control 返回的 platform.robots 中的一台。
% userConfig 由独立运动程序自己的配置函数提供。
% 待实现：读取姿态并检查 valid，再计算并显式发送电机指令。
% 后期实现运动时，应自行安排异常和退出时停车。
result = struct('implemented',false,'robotName',robotAPI.name);
end
