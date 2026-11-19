classdef MockCamera < handle
    properties
        Frame
        FocusMode = "manual"
        Focus = 1
        FailCapture = false
        CaptureCount = 0
    end
    methods
        function obj = MockCamera(frame)
            obj.Frame = frame;
        end

        function image = snapshot(obj)
            obj.CaptureCount = obj.CaptureCount+1;
            assert(~obj.FailCapture,'epuck:MockCaptureFailed','模拟摄像头取帧失败。');
            image = obj.Frame;
        end
    end
end
