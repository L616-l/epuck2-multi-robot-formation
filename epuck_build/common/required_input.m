function value = required_input(label, check, numeric, options)
% 数值输入采用 JSON 语法，避免将输入当作 MATLAB 代码执行。
arguments
    label
    check
    numeric
    options.AllowEmpty (1,1) logical = false
end
while true
    raw = strtrim(input(label + " ",'s'));
    if strcmpi(raw,'取消') || strcmpi(raw,'cancel')
        error('epuck:Cancelled','已取消本次操作。');
    end
    if isempty(raw)
        if options.AllowEmpty
            value = [];
            return
        end
        disp('缺少必要参数，请填写，或输入 cancel 取消。');
        continue
    end
    value = string(raw);
    if numeric
        try
            value = jsondecode(raw);
        catch
            disp('数值格式错误。向量用方括号，元素用逗号分隔。');
            continue
        end
        if ~isa(value,'double')
            disp('请输入数值。');
            continue
        end
    end
    if check(value)
        return
    end
    disp('不符合要求，请按上方的范围和输入格式重新填写。');
end
end
