function log_event(project, message)
try
    if ~isfolder(project.logs)
        mkdir(project.logs);
    end
    file = fopen(fullfile(project.logs,'platform.log'),'a','n','UTF-8');
    assert(file >= 0,'无法打开日志文件。');
    cleanup = onCleanup(@() fclose(file));
    fprintf(file,'%s  %s\n',string(datetime('now','TimeZone','local')),message);
catch err
    warning('epuck:LogUnavailable','无法记录日志：%s',err.message);
end
end
