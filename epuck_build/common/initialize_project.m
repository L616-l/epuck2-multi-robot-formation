function project = initialize_project(root, mode)
% 每个入口只加入本次需要的模块。目录以入口文件的位置为准。
folders = ["config", "camera"];
switch mode
    case "intrinsic"
        folders(end+1) = fullfile("calibration","intrinsic");
    case "field"
        folders = [folders, fullfile("calibration","extrinsic"), "coordinates"];
    case "robot"
        folders = [folders, "coordinates", "vision", "robot", "interfaces", "monitor"];
end
for folder = folders
    addpath(fullfile(root,folder));
end
project.config = fullfile(root,'data','configuration');
project.calibration = fullfile(root,'data','calibration');
project.logs = fullfile(root,'logs');
end
