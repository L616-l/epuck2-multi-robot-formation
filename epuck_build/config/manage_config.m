function values = manage_config(project, name, collect, validate, label)
% 只在用户明确选择后读取已保存的配置。
if nargin < 5
    label = name;
end
file = fullfile(project.config,name + ".mat");
if isfile(file) && confirm_choice("读取本项目已保存的" + label + "配置？")
    try
        values = load_project_struct(file,'values','epuck:InvalidConfig');
        validate(values);
        return
    catch err
        if strcmp(err.identifier,'epuck:Cancelled')
            rethrow(err)
        end
        fprintf('已保存的%s配置无法使用：%s\n',label,err.message);
        assert(confirm_choice("重新填写该配置？"),'epuck:Cancelled','已取消配置录入。');
    end
end
values = collect();
validate(values);
if confirm_choice("保存本次" + label + "配置供下次选择？")
    save_result(file,'values',values);
end
end
