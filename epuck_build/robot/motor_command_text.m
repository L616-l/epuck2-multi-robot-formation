function command = motor_command_text(left,right)
protocol = asercom_protocol();
limits = protocol.motorRange;
validateattributes(left,{'numeric'},{'real','scalar','finite','integer','>=',limits(1),'<=',limits(2)});
validateattributes(right,{'numeric'},{'real','scalar','finite','integer','>=',limits(1),'<=',limits(2)});
command = sprintf(protocol.motorFormat,left,right);
end
