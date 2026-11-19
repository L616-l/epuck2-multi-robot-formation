function value = load_project_struct(file, variable, errorId)
% 验证本项目 MAT 文件中的单个结构体，统一损坏文件的报错。
try
    data = load(file,variable);
catch err
    error(errorId,'无法读取 %s：%s',file,err.message);
end
assert(isfield(data,variable) && isstruct(data.(variable)) && isscalar(data.(variable)), ...
    errorId,'文件 %s 缺少有效的 %s 结构体。',file,variable);
value = data.(variable);
end
