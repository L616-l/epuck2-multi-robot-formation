function save_result(file, variable, value)
% 先完整写入临时文件，成功后再替换目标。
folder = fileparts(file);
if ~isfolder(folder)
    mkdir(folder);
end
temporary = string(tempname(folder)) + ".mat";
cleanup = onCleanup(@() removeTemporary(temporary));
data.(variable) = value;
save(temporary,'-struct','data');
[ok,message] = movefile(temporary,file,'f');
assert(ok,'epuck:SaveFailed','保存失败：%s',message);
end

function removeTemporary(file)
if isfile(file)
    delete(file);
end
end
