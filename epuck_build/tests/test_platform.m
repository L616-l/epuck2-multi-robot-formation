function tests = test_platform
% 自动测试只使用数学样本和模拟串口。
tests = functiontests(localfunctions);
end

function setupOnce(testCase)
root = fileparts(fileparts(mfilename('fullpath')));
originalPath = path;
testCase.addTeardown(@() path(originalPath));
addpath(fullfile(root,'common'));
for mode = ["intrinsic","field","robot"]
    initialize_project(root,mode);
end
end

function testCheckerboardDetection(testCase)
tiles = mod((0:6)' + (0:7),2);
image = uint8(255*kron(tiles,ones(30)));
canvas = repmat(uint8(220),320,340);
canvas(51:260,51:290) = image;
for k = 0:3
    [corners, dims] = detectCheckerboardPoints(rot90(canvas,k),PartialDetections=false);
    verifyEqual(testCase,dims,[7 8]);
    verifySize(testCase,corners,[42 2]);
end
end

function testIntrinsicSolveAndSave(testCase)
cfg = struct('boardSquares',[7 8],'squareMm',24,'radialTerms',2, ...
    'maxRmsPx',0.1,'maxViewRmsPx',0.2);
[truth,~] = fixture();
grid = generateCheckerboardPoints(cfg.boardSquares,cfg.squareMm);
world = [grid,zeros(size(grid,1),1)];
poses = [15 10 1 -55 -50 500; -12 16 5 -70 -88 540; ...
    18 -13 15 -110 -75 580; -22 -8 -6 -80 -50 510; ...
    9 24 -9 -62 -72 620; -9 -20 13 -42 -92 560; ...
    10 4 20 -90 -55 450; -14 8 -17 -45 -90 475];
imagePoints = zeros(size(world,1),2,size(poses,1));
for k = 1:size(poses,1)
    tform = rigidtform3d(poses(k,1:3),poses(k,4:6));
    imagePoints(:,:,k) = world2img(world,tform,truth.cameraParams.Intrinsics,ApplyDistortion=true);
end
result = solve_intrinsics(imagePoints,truth.imageSize,cfg);
verifyTrue(testCase,validate_intrinsics(result,cfg));
verifyEqual(testCase,result.K,truth.K,AbsTol=0.5);
verifyEqual(testCase,result.radialDistortion,truth.cameraParams.RadialDistortion,AbsTol=0.01);
verifyEqual(testCase,result.tangentialDistortion,truth.cameraParams.TangentialDistortion,AbsTol=0.001);
folder = tempname;
mkdir(folder);
testCase.addTeardown(@() rmdir(folder,'s'));
file = fullfile(folder,'intrinsic.mat');
save_result(file,'result',result);
saved = load_project_struct(file,'result','epuck:BadCalibration');
verifyClass(testCase,saved.cameraParams,'cameraParameters');
verifyEqual(testCase,saved.K,result.K);
save_result(file,'result',42);
verifyError(testCase,@() load_project_struct(file,'result','epuck:BadCalibration'), ...
    'epuck:BadCalibration');
end

function testExtrinsicAndIndependentPoints(testCase)
[intrinsic,truth] = fixture();
fit.world = [20 20; 430 30; 420 280; 30 270; 190 140; 250 90];
fit.pixel = world_to_pixel([fit.world zeros(size(fit.world,1),1)],intrinsic,truth);
field = solve_extrinsics(fit,intrinsic);
verifyEqual(testCase,field.R,truth.R,AbsTol=0.0001);
verifyEqual(testCase,field.t,truth.t,AbsTol=0.1);
independent.world = [110 70; 310 240];
independent.pixel = world_to_pixel([independent.world zeros(size(independent.world,1),1)],intrinsic,truth);
cfg = struct('maxReprojectionPx',0.1,'maxValidationMm',0.2,'minFitCoverage',0.5, ...
    'lengthMm',450,'widthMm',300);
[valid,quality] = validate_field_calibration(fit,independent,intrinsic,field,cfg);
verifyTrue(testCase,valid);
verifyLessThan(testCase,quality.maxValidationMm,0.2);
degenerate = struct('world',[0 0;1 1;2 2;3 3],'pixel',fit.pixel(1:4,:));
verifyError(testCase,@() solve_extrinsics(degenerate,intrinsic),'epuck:DegeneratePoints');
end

function testCoordinatesAndTagHeight(testCase)
[intrinsic,field] = fixture();
world = [80 40 57; 200 100 57; 350 220 57];
[pixels, projected] = world_to_pixel(world,intrinsic,field);
verifyTrue(testCase,all(projected));
[reconstructed, ok] = pixel_to_world(pixels,57,intrinsic,field);
verifyTrue(testCase,all(ok));
verifyEqual(testCase,reconstructed,world,AbsTol=0.05);
ground = pixel_to_world(pixels,0,intrinsic,field);
verifyGreaterThan(testCase,norm(ground(:,1:2)-world(:,1:2)),1);
[~, ok] = pixel_to_world(pixels,2000,intrinsic,field);
verifyFalse(testCase,any(ok));
[~, ok] = world_to_pixel([world(:,1:2),2000*ones(3,1)],intrinsic,field);
verifyFalse(testCase,any(ok));
[emptyWorld,emptyValid] = pixel_to_world(zeros(0,2),0,intrinsic,field);
verifySize(testCase,emptyWorld,[0 3]);
verifySize(testCase,emptyValid,[0 1]);
end

function testAprilTagDetectionAndOrientation(testCase)
image = sampleTagImage();
cfg = struct('family',"tag16h5",'gaussianSigma',0,'decimation',1);
[id, corners] = detect_apriltags(image,cfg);
[idRot, rot] = detect_apriltags(rot90(image),cfg);
assertEqual(testCase,id,0);
assertEqual(testCase,idRot,id);
verifySize(testCase,corners,[4 2]);
edge = corners(2,:)-corners(1,:);
turned = rot(2,:)-rot(1,:);
verifyEqual(testCase,turned,[edge(2),-edge(1)],AbsTol=2);
end

function testProjectionMatchesCourseEquation(testCase)
% PPT (2-6) 的 3×4 内参和 4×4 外参，直接用矩阵乘法独立计算。
K = [520 0 310; 0 550 210; 0 0 1];
params = cameraParameters(K=K,ImageSize=[480 640]);
intrinsic = struct('cameraParams',params,'K',K,'imageSize',[480 640]);
field.R = [1 0 0; 0 -0.8 0.6; 0 -0.6 -0.8];
field.t = [-130;180;650];
world = [140 80 0; 200 120 48; 150 150 48];
homogeneous = [K zeros(3,1)]*[field.R field.t;0 0 0 1]*[world.';ones(1,3)];
verifyEqual(testCase,homogeneous(3,:),[602 539.6 521.6],AbsTol=1e-9);
expected = (homogeneous(1:2,:)./homogeneous(3,:)).';
[pixel, valid] = world_to_pixel(world,intrinsic,field);
verifyTrue(testCase,all(valid));
verifyEqual(testCase,pixel,expected,AbsTol=1e-9);
[reconstructed, valid] = pixel_to_world(expected(2:3,:),48,intrinsic,field);
verifyTrue(testCase,all(valid));
verifyEqual(testCase,reconstructed,world(2:3,:),AbsTol=1e-9);
end

function testPoseTrackerLifecycle(testCase)
camera = MockCamera(sampleTagImage());
focus = camera_focus_readback(camera);
K = [360 0 180; 0 360 180; 0 0 1];
params = cameraParameters(K=K,ImageSize=[360 360]);
intrinsic = struct('cameraParams',params,'K',K,'imageSize',[360 360]);
field = struct('R',diag([1 -1 -1]),'t',[-300;300;460], ...
    'layout',struct('lengthMm',600,'widthMm',600));
cfg = struct('robotNames',"A",'maxSideErrorMm',3,'family',"tag16h5", ...
    'gaussianSigma',0,'decimation',1,'maxPoseAgeS',1);
cfg.tags = struct('id',0,'sizeMm',200,'heightMm',60, ...
    'headingOffsetDeg',0,'centerOffsetMm',[0 0]);
tracker = create_pose_tracker(camera,intrinsic,field,cfg,focus);
verifyFalse(testCase,tracker.getPose(1).valid);
tracker.update();
verifyTrue(testCase,tracker.getPose(1).valid);
pause(1.05);
verifyEqual(testCase,tracker.getPose(1).reason,"stalePose");
verifyTrue(testCase,all(isnan(tracker.getPose(1).positionMm)));
tracker.update();
camera.FailCapture = true;
verifyError(testCase,tracker.update,'epuck:MockCaptureFailed');
verifyFalse(testCase,tracker.getPose(1).valid);
verifyTrue(testCase,startsWith(tracker.getPose(1).reason,"visionError:"));
camera.FailCapture = false;
camera.Focus = camera.Focus+1;
verifyError(testCase,tracker.update,'epuck:FocusChanged');
verifyFalse(testCase,tracker.getPose(1).valid);
camera.Focus = focus.value;
tracker.update();
verifyTrue(testCase,tracker.getPose(1).valid);
tracker.close();
verifyEqual(testCase,tracker.getPose(1).reason,"sessionClosed");
verifyError(testCase,tracker.update,'epuck:ClosedSession');
end

function image = sampleTagImage()
% tag16h5 ID 0 黑边与数据格，源自 AprilRobotics 的公开标记图案。
tag = [0 0 0 0 0 0; 0 0 0 1 0 0; 0 0 0 1 1 0; ...
       0 0 0 0 1 0; 0 1 0 1 1 0; 0 0 0 0 0 0];
image = repmat(uint8(255),360,360);
image(91:270,91:270) = uint8(255*kron(tag,ones(30)));
end

function testPoseAndRejections(testCase)
[intrinsic,field] = fixture();
cfg = struct('robotNames',["A" "B"],'maxSideErrorMm',0.1);
cfg.tags = [struct('id',7,'sizeMm',40,'heightMm',60,'headingOffsetDeg',90,'centerOffsetMm',[5 3]), ...
    struct('id',8,'sizeMm',40,'heightMm',60,'headingOffsetDeg',0,'centerOffsetMm',[0 0])];
world = [100 100 60;140 100 60;140 140 60;100 140 60];
pixels = world_to_pixel(world,intrinsic,field);
nowTime = datetime('now','TimeZone','local');
result = estimate_robot_pose(7,pixels,cfg,intrinsic,field,nowTime);
verifyTrue(testCase,result(1).valid);
verifyEqual(testCase,result(1).tagCenterMm,[120 120 60],AbsTol=0.05);
verifyEqual(testCase,result(1).positionMm,[117 125],AbsTol=0.05);
verifyEqual(testCase,result(1).headingDeg,90,AbsTol=0.05);
verifyEqual(testCase,result(2).reason,"tagNotFound");
duplicate = estimate_robot_pose([7 7],cat(3,pixels,pixels),cfg,intrinsic,field,nowTime);
verifyEqual(testCase,duplicate(1).reason,"duplicateTagId");
cfg.tags(1).sizeMm = 30;
wrongSize = estimate_robot_pose(7,pixels,cfg,intrinsic,field,nowTime);
verifyEqual(testCase,wrongSize(1).reason,"tagSizeMismatch");
cfg.tags(1).sizeMm = 40;
rhombus = [100 100 60;140 100 60;160 100+20*sqrt(3) 60;120 100+20*sqrt(3) 60];
pixels = world_to_pixel(rhombus,intrinsic,field);
distorted = estimate_robot_pose(7,pixels,cfg,intrinsic,field,nowTime);
verifyFalse(testCase,distorted(1).valid);
verifyEqual(testCase,distorted(1).reason,"invalidTagGeometry");
end

function testAsercomAndApi(testCase)
[port,trace,link] = openMock();
sample = struct('positionMm',[4 7],'headingDeg',30,'valid',true, ...
    'reason',"",'capturedAt',datetime('now','TimeZone','local'));
api = create_robot_api("A",link,@() sample);
verifyEqual(testCase,trace('commands'),"N");
verifyEqual(testCase,api.getPose(),sample);
verifyEqual(testCase,api.getPosition().positionMm,sample.positionMm);
verifyEqual(testCase,api.getHeading().headingDeg,sample.headingDeg);
verifyTrue(testCase,api.getStatus().communication.connected);
verifyTrue(testCase,api.isConnected());
api.sendMotorCommand(-917,903);
api.stop();
api.disconnect();
verifyFalse(testCase,isvalid(port));
verifyFalse(testCase,api.isConnected());
verifyEqual(testCase,trace('commands'),["N" "N" "D,-917,903" "D,0,0" "E"]);
end

function testAsercomCloseBehavior(testCase)
[port,trace,link] = openMock();
link.disconnect();
verifyFalse(testCase,isvalid(port));
verifyEqual(testCase,trace('commands'),"N");
[port,trace,link] = openMock();
try
    link.send(1001,0);
    verifyFail(testCase,'超出协议范围的指令被接受。');
catch err
    verifyNotEqual(testCase,err.identifier,'epuck:NoReply');
end
verifyEqual(testCase,trace('commands'),"N");
port.IgnoreMotor = true;
verifyError(testCase,@() link.send(1,-1),'epuck:NoReply');
verifyFalse(testCase,link.status().connected);
port.IgnoreMotor = false;
link.disconnect();
verifyFalse(testCase,isvalid(port));
verifyEqual(testCase,trace('commands'),["N" "D,1,-1" "D,0,0" "E"]);
end

function testDisconnectDuringSerialRequest(testCase)
[port,trace,link] = openMock();
port.BeforeRead = link.disconnect;
link.send(25,-25);
verifyFalse(testCase,isvalid(port));
verifyFalse(testCase,link.probe());
verifyEqual(testCase,trace('commands'),["N" "D,25,-25" "D,0,0" "E"]);
end

function testStopRejectsDelayedAcknowledgement(testCase)
[port,trace,link] = openMock();
link.send(100,-100);
port.DropMotorCommand = true;
% 模拟上一条 D 的 d 回包迟到，但这次 D,0,0 并未到达执行端。
verifyError(testCase,@() link.send(0,0),'epuck:StopNotConfirmed');
verifyEqual(testCase,port.Speed,[100 -100]);
port.DropMotorCommand = false;
link.disconnect();
verifyFalse(testCase,isvalid(port));
verifyEqual(testCase,trace('commands'),["N" "D,100,-100" "D,0,0" "E" "D,0,0" "E"]);
end

function testDisconnectReleasesPortAfterFailedStop(testCase)
[port,trace,link] = openMock();
link.send(100,100);
port.IgnoreMotor = true;
verifyError(testCase,link.disconnect,'epuck:NoReply');
verifyFalse(testCase,isvalid(port));
verifyEqual(testCase,trace('commands'),["N" "D,100,100" "D,0,0"]);
end

function testMonitorLifecycle(testCase)
[port,trace,link] = openMock();
capturedAt = datetime('now','TimeZone','local');
pose = struct('name',"A",'tagId',0,'positionMm',[4 7],'headingDeg',30, ...
    'tagHeadingDeg',20,'valid',true,'reason',"",'capturedAt',capturedAt);
updates = 0;
tracker = struct('update',@countUpdate,'getPose',@(~) pose,'close',@() []);
folder = tempname;
mkdir(folder);
testCase.addTeardown(@() rmdir(folder,'s'));
platform = open_robot_monitor(tracker,{link},struct('robotNames',"A",'periodS',60),struct('logs',folder));
testCase.addTeardown(platform.close);
verifyEqual(testCase,updates,0);
platform.update();
verifyEqual(testCase,updates,1);
verifyEqual(testCase,platform.robots(1).getPose(),pose);
platform.close();
verifyFalse(testCase,isvalid(port));
verifyEqual(testCase,trace('commands'),"N");

    function countUpdate()
        updates = updates+1;
    end
end

function [port,trace,link] = openMock()
trace = containers.Map('KeyType','char','ValueType','any');
trace('commands') = strings(1,0);
cfg = struct('baudRate',200,'timeoutS',0.1);
port = MockAsercomPort(trace,cfg.timeoutS);
link = connect_epuck(struct('port',"offline"),cfg,@(~,~,~) port);
end

function [intrinsic,field] = fixture()
imageSize = [720 960];
params = cameraParameters('K',[820 0 474;0 840 351;0 0 1], ...
    'ImageSize',imageSize, ...
    'RadialDistortion',[-0.10 0.015],'TangentialDistortion',[0.001 -0.002]);
intrinsic = struct('cameraParams',params,'K',params.Intrinsics.K,'imageSize',imageSize);
rotation = rigidtform3d([168 8 -11],[0 0 0]);
field.R = rotation.R;
field.t = -field.R*[220;145;710];
field.layout = struct('lengthMm',450,'widthMm',300);
end
