function api = create_robot_api(name, link, readPose)
% API 与串口实现分离。各读取接口都返回有效标志和采集时间。
api = struct('name',name,'getPose',readPose,'getPosition',@getPosition, ...
    'getHeading',@getHeading,'getStatus',@getStatus,'sendMotorCommand',link.send, ...
    'stop',link.stop,'isConnected',@isConnected,'disconnect',link.disconnect);

    function position = getPosition()
        pose = readPose();
        position = struct('positionMm',pose.positionMm,'valid',pose.valid, ...
            'capturedAt',pose.capturedAt,'reason',pose.reason);
    end

    function heading = getHeading()
        pose = readPose();
        heading = struct('headingDeg',pose.headingDeg,'valid',pose.valid, ...
            'capturedAt',pose.capturedAt,'reason',pose.reason);
    end

    function status = getStatus()
        pose = readPose();
        status = struct('name',name,'communication',link.status(), ...
            'poseValid',pose.valid,'poseReason',pose.reason,'poseCapturedAt',pose.capturedAt);
    end

    function ok = isConnected()
        ok = link.probe();
    end
end
