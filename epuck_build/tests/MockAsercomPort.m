classdef MockAsercomPort < handle
    properties
        Port = "offline"
        Timeout
        Terminator
        Trace
        IgnoreMotor = false
        Reply = ""
        BeforeRead = []
        DropMotorCommand = false
        Speed = [0 0]
    end
    methods
        function obj = MockAsercomPort(trace, timeout)
            obj.Trace = trace;
            obj.Timeout = timeout;
        end

        function configureTerminator(obj, mode)
            obj.Terminator = mode;
        end

        function flush(obj, ~)
            obj.Reply = "";
        end

        function writeline(obj, value)
            value = string(value);
            obj.Trace('commands') = [obj.Trace('commands'),value];
            if value == "N"
                obj.Reply = "n,1,2,3,4,5,6,7,8";
            elseif startsWith(value,"D,")
                if ~obj.DropMotorCommand
                    obj.Speed = sscanf(char(value),'D,%d,%d').';
                end
                if ~obj.IgnoreMotor
                    obj.Reply = "d";
                end
            elseif value == "E"
                obj.Reply = string(sprintf('e,%d,%d',obj.Speed));
            end
        end

        function value = readline(obj)
            if ~isempty(obj.BeforeRead)
                callback = obj.BeforeRead;
                obj.BeforeRead = [];
                callback();
            end
            value = obj.Reply;
            obj.Reply = "";
            if value == ""
                value = [];
            end
        end
    end
end
