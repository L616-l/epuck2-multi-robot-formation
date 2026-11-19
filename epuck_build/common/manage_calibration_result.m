function result = manage_calibration_result(project, kind, result)
% 固定使用新项目自己的目录和数据格式。
file = fullfile(project.calibration,kind + ".mat");
if kind == "intrinsic"
    label = "相机内参";
else
    label = "场地标定";
end
if nargin == 3
    if isfile(file)
        assert(confirm_choice("覆盖本项目现有的" + label + "结果？"), ...
            'epuck:Cancelled','保留已有标定，取消保存。');
    end
    save_result(file,'result',result);
    fprintf('已保存 %s\n',file);
    return
end
entry = "run_" + kind + "_calibration";
assert(isfile(file),'epuck:MissingCalibration', ...
    '缺少本项目的%s结果。请运行 %s。',label,entry);
assert(confirm_choice("使用本项目已保存的" + label + "结果？"), ...
    'epuck:Cancelled','已退出。可运行 %s 重新标定。',entry);
try
    result = load_project_struct(file,'result','epuck:BadCalibration');
    validateResult(result,kind);
catch err
    error('epuck:BadCalibration','无法使用%s结果。请运行 %s。原因：%s',label,entry,err.message);
end
end

function validateResult(result,kind)
fields = {'kind','K','imageSize','camera','focus','calibratedAt'};
if kind == "intrinsic"
    fields{end+1} = 'cameraParams';
else
    fields = [fields,{'R','t','layout','intrinsicCalibratedAt'}];
end
assert(all(isfield(result,fields)) && isequal(result.kind,kind),'标定类型或字段不匹配。');
validateattributes(result.K,{'double'},{'size',[3 3],'real','finite'});
validateattributes(result.imageSize,{'numeric'},{'size',[1 2],'positive','integer','finite'});
validateattributes(result.calibratedAt,{'datetime'},{'scalar'});
assert(~isnat(result.calibratedAt),'标定时间无效。');
assert(isscalar(result.camera) && all(isfield(result.camera,{'name','index','resolution'})) ...
    && isscalar(result.focus) && all(isfield(result.focus,{'mode','value','locked'})), ...
    '摄像头或对焦记录不完整。');
if kind == "intrinsic"
    assert(isa(result.cameraParams,'cameraParameters') && isscalar(result.cameraParams) ...
        && isequal(result.K,result.cameraParams.Intrinsics.K) ...
        && isequal(result.imageSize,result.cameraParams.ImageSize), ...
        '内参对象与保存的矩阵或图像尺寸不一致。');
else
    validateattributes(result.R,{'double'},{'size',[3 3],'real','finite'});
    validateattributes(result.t,{'double'},{'size',[3 1],'real','finite'});
    rigidtform3d(result.R,result.t.');  % 校验 R 是合法旋转。
    assert(-result.R(:,3).'*result.t>0,'相机光心必须在场地上方。');
    validateattributes(result.intrinsicCalibratedAt,{'datetime'},{'scalar'});
    assert(~isnat(result.intrinsicCalibratedAt),'配套内参时间无效。');
    assert(isscalar(result.layout) && all(isfield(result.layout,{'lengthMm','widthMm'})), ...
        '场地尺寸记录不完整。');
    validateattributes(result.layout.lengthMm,{'numeric'},{'scalar','positive','finite'});
    validateattributes(result.layout.widthMm,{'numeric'},{'scalar','positive','finite'});
end
end
