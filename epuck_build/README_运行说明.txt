e-puck2 多智能体编队实验平台
MATLAB R2026a

一、从这里开始

在 MATLAB 的“当前文件夹”中打开本 epuck_build 目录。需要 Computer Vision Toolbox、
Image Processing Toolbox 和 MATLAB Support Package for USB Webcams。
蓝牙使用 Windows 配对后建立的出站 UART 虚拟 COM 串口，由 MATLAB serialport 访问。
三个入口各自运行。已有本项目结果时，可以单独运行后两项，并逐份确认是否使用。

  run_intrinsic_calibration
  run_field_calibration
  platform = run_robot_control

命令行会逐项提示输入格式、单位、范围或示例。标有 [y/n] 的选项用 y 确认、n 拒绝。
拍照直接按回车。必填参数留空会重新提示，输入 cancel 可取消。向量用方括号和逗号输入。
提示中的示例只演示写法，请按实物测量和实验要求填写。
参数填写后可选择保存。下次选择不读取该配置，即可重新填写相应模块的参数。
配置保存到 data/configuration，标定保存到 data/calibration，运行日志保存到 logs。
这些目录按需创建。运行说明和接口说明都是 UTF-8。

二、内参标定

1. 运行 run_intrinsic_calibration。按列表输入摄像头编号，再输入分辨率编号，例如 2。
2. 按提示填写棋盘短边和长边的黑白方格数、单格实测边长、有效图像数、径向畸变系数个数，
   以及整体和单幅重投影均方根误差的上限。棋盘两边均至少四格，方格数一奇一偶。
3. 在实时预览中检查画面。程序尝试设置自动对焦。等画面清晰且稳定后，确认读取
   对焦模式和驱动控制值，再确认尝试手动锁定。只有模式和值都读回匹配才显示锁定。
   驱动无法锁焦或读回时，界面会提示，并由你决定是否继续。
4. 移动并倾斜棋盘，覆盖画面中心和四周，同时改变距离和倾角。每张图在 MATLAB 命令行
   直接按回车拍摄，识别到完整且规格匹配的棋盘才计入进度。程序会提示重拍完全重复的图像，
   并在每次取帧时核对对焦读值。输入 cancel 可退出采集。
5. 查看 K、径向和切向畸变、重投影误差和去畸变对比。质量不达标时可重新采集。
6. 确认合格并保存。intrinsic.mat 保存 K、像素焦距 fx/fy、主点 u0/v0、畸变、
   cameraParams 对象、设备与图像尺寸、驱动读回的对焦状态、时间和误差。
   镜头标称焦距、驱动对焦控制值和 fx/fy 各有独立含义。

三、外参及场地标定

1. 固定相机与场地。运行 run_field_calibration，明确选择读取本项目的内参。
   程序沿用内参记录的摄像头及分辨率，并尝试恢复已锁定的对焦值。
2. 确定原点角和两轴沿哪条边指向场内，填写沿 +X、+Y 实测的场地长宽。地面 Z=0，
   从场地上方看，+X 朝 +Y 逆时针转 90°。按提示填写两组点数、拟合面积覆盖比例、
   最大重投影误差和最大实地验证误差。
3. 检查实时预览。标志清晰可见后，在 MATLAB 命令行按回车冻结画面。在图像窗口左键选取
   地面标志，回到命令行输入实测 [X,Y] (mm)，命令行会显示当前场地的坐标范围。
   先选四周的拟合点，再选其他区域的独立验证点。两组分别至少四个和两个，每个标志只选一次。
   点错时在坐标提示处直接回车重选当前点。在命令行输入 cancel，或在等待图像点击时
   按键盘的 Esc 或回车，可取消整次选点。
4. 查看拟合点与重投影位置，再查看独立点的实测与换算误差和拟合点面积覆盖。
   通过并确认后保存 field.mat。它记录 K、R、t、场地、原点与轴向、拟合与验证
   数据、质量指标、相机与对焦信息，以及与其配对的内参时间。
5. 换设备、分辨率或改变对焦后，应重做内参及外参。移动相机或更改场地坐标系
   后，应重做外参。重新保存内参后，控制入口会要求使用与该内参配套的外参。

与课件《第2章 视觉传感器》第 2.6 节的对应关系

课件第 52 至 57 页给出世界坐标到像素的投影关系。式（2-6）的 3×4 内参写成
[K 0]，其中 K 为程序保存的 3×3 矩阵。4×4 外参的前三行为 [R t]，最后一行
为 [0 0 0 1]。两矩阵相乘为 K[R t]，得到 Zc*[u;v;1] = K[R t]*[Xw;Yw;Zw;1]。
u、v 是去畸变像素，Zc 是相机坐标深度。程序使用 MATLAB 的像素坐标，
左上像素中心为 (1,1)。场地坐标和 t 统一用 mm，R 无量纲，焦距和主点以像素计。

课件第 58 至 68 页说明多视角棋盘标定。内参入口用每张图的棋盘内角点及实测
格长调用 estimateCameraParameters，由闭式初值继续优化内参、各图的外参和
镜头畸变。fx=f/dx、fy=f/dy 以像素为单位直接估计，模型按式（2-6）采用零斜切。
内参采集时各图对应的棋盘外参与最终的场地外参基于不同的参考坐标系。

第 69 至 74 页的示例用棋盘建立车载相机外参，并用鸟瞰图验证。项目用场地
地面上已知 XY 的点建立外参，用独立点的坐标误差及原图重投影来验证。
场地求解先去畸变，再用 estimateExtrinsics 从共面对应点得到世界到相机的
R、t。对于地面 Z=0，理想像素满足 H ∝ K[r1 r2 t]，对应课件的平面单应关系。
相机在场地中的光心为 C=-R'*t，离地高度是 C(3)。

world_to_pixel 先做 Pc=R*Pw+t，再投影并应用畸变。pixel_to_world 先去畸变，
再从 C 出发沿反投影射线与指定 Z 平面求交。地面用 Z=0，AprilTag 使用各自的
实测安装高度。R 使用 rigidtform3d 的前乘约定，t 保存为三元素列向量。

四、机器人底层控制

1. 在 Windows 中配对机器人，核对每台机器人的出站 UART COM 端口与固件模式。
   本平台使用 GCtronic 的 Asercom 蓝牙 UART 通道，工厂固件的蓝牙模式为选择器 3。
2. 执行 platform = run_robot_control。分别明确选择读取内参和场地标定。
   输入或明确选用相机、机器人通信及视觉配置。初始化摄像头和识别后才连接串口。
3. 通信启动探测只读接近传感器。定位窗口实时显示每台机器人是否有有效位置。
   表格的“串口在线*”代表最近通信结果，主动重新探测可调用 isConnected()。
4. Tag 的四个角分别投到其实际安装高度，再求中心和方向。Tag 方向取解码后的
   第 1→2 角边，并与对边平均。安装偏移用世界 +Z 逆时针为正，机器人中心偏移
   用车体前、左方向表示。读取首次显示的 Tag 角，再用量得的车头角减去 Tag 角，
   可得到安装角偏移。需要修改时重开底层程序并重新填写视觉配置。
5. 关闭窗口或调用 platform.close() 结束会话。若本会话曾发出且尚未确认停止的
   非零指令，关闭时会尝试发送零速，并在未确认时报告错误。关闭时已有串口
   请求的，等当前请求结束后再执行停车和释放串口。
6. 需要验证真实电机时，请先把机器人架空，再由你在命令行明确填写左右轮命令并
   调用 sendMotorCommand，随后手动调用 stop。程序在零速命令回包后用只读 E
   核对两轮速度设定值。操作者还需观察车轮是否停稳。自动测试使用模拟串口。

五、参数和数据位置

camera_config.m       设备编号、名称和设备报告的分辨率。对焦值由驱动读取。
intrinsic_config.m    棋盘方格数与方格边长 mm、采集张数、径向项数、重投影阈值 px。
field_config.m        场地长宽 mm、原点与轴向、拟合与验证点数、覆盖比例、两种误差阈值。
                      各对应点的实测 XY 在选点时录入，随 field.mat 保存。
robot_config.m        各机器人唯一名称和 UART COM，公用波特率和串口超时 s。
vision_config.m       全组共用的方形 Tag family、平滑标准差、降采样因子、刷新周期 s、
                      位姿最大年龄 s、Tag 边长误差 mm（对角线容差按平方根 2 同比例换算）。每台另有 ID、Tag 边长 mm、
                      Tag 高度 mm、安装角偏移 deg、中心偏移 mm。
                      新增机器人时，重新填写机器人名单与对应 Tag 参数。
asercom_protocol.m    GCtronic 文档规定的 ASCII 命令、回包和 D 命令整数范围。
                      指令单位为电机 steps/s。越界或非整数时报错，发送值原样保留。
                      https://www.gctronic.com/doc/index.php?title=Advanced_sercom_protocol

六、调用关系和后期扩展

内参入口 → 摄像头、对焦 → 采集棋盘角点 → 内参求解、质量检查 → intrinsic.mat。
场地入口 → 用户确认读取 intrinsic.mat → 相机匹配 → 采集像素与世界点 → 求 R/t
         → 双向坐标转换与独立点验证 → field.mat。
控制入口 → 用户确认两份标定并核验配对 → 定位追踪器与蓝牙连接 → 实时监视窗口
         → 为每台机器人构建独立函数句柄 API。

接口细节和后期扩展见 interfaces/robot_api_description.txt。可从
interfaces/user_motion_template.m 复制接口模板，改名后在独立的扩展目录里编写具体运动，
并为该运动单独创建参数配置文件。底层启动流程不会调用模板。

七、最终文件树

epuck_build/
  run_intrinsic_calibration.m  内参入口
  run_field_calibration.m  场地入口
  run_robot_control.m  底层平台入口
  README_运行说明.txt  操作、参数和交付记录
  calibration/intrinsic/
    collect_intrinsic_images.m  采集与识别棋盘角点
    solve_intrinsics.m  求解内参与畸变
    validate_intrinsics.m  检查误差与去畸变效果
  calibration/extrinsic/
    collect_field_points.m  采集场地拟合点与验证点
    solve_extrinsics.m  求解世界到相机的 R 和 t
    validate_field_calibration.m  核对覆盖率与实测误差
  camera/
    camera_focus_readback.m  读取驱动对焦信息
    check_camera_calibration.m  验证相机与标定匹配
    focus_matches.m  比较两份对焦状态
    get_camera_frame.m  取帧并核对尺寸
    lock_camera_focus.m  尝试锁焦与验证读回
    open_camera.m  按配置连接相机
    preview_camera.m  场地实时预览与回车取帧
  common/
    manage_calibration_result.m  确认保存或读取，并校验本项目标定
    confirm_choice.m  处理确认输入
    initialize_project.m  添加模块路径并初始化
    load_project_struct.m  读取并验证本项目 MAT 文件的结构体
    log_event.m  记录运行事件
    required_input.m  读取必填数据
    save_result.m  保存标定结果
    wait_for_capture.m  处理回车拍照和取消
  config/
    camera_config.m  设备和分辨率配置
    field_config.m  场地尺寸、坐标系与验收参数
    intrinsic_config.m  棋盘、采集与误差参数
    manage_config.m  配置录入、读取与保存流程
    robot_config.m  机器人列表与串口参数
    vision_config.m  定位与各 Tag 安装参数
  coordinates/
    pixel_to_world.m  像素射线与指定世界平面求交
    world_to_pixel.m  带畸变的世界点投影
  interfaces/
    create_robot_api.m  封装每台机器人的 API
    robot_api_description.txt  接口说明
    user_motion_template.m  预留运动程序签名
  monitor/
    open_robot_monitor.m  管理实时窗口及会话生命周期
  robot/
    asercom_exchange.m  发送协议命令并校验回包
    asercom_protocol.m  集中定义协议常量
    probe_asercom_connection.m  只读通信探测
    connect_epuck.m  建立单台连接，管理读写、停车和关闭流程
    connect_robot_group.m  连接一组机器人
    disconnect_epuck.m  释放单台串口对象
    disconnect_robot_group.m  释放整组连接
    motor_command_text.m  校验并格式化左右轮指令
    send_motor_command.m  发送底层电机指令
    stop_robot.m  发送零速指令并读取两轮设定值
  tests/
    MockAsercomPort.m  模拟串口及回包
    MockCamera.m  模拟取帧、焦距变化和摄像头异常
    test_platform.m  离线回归测试
  vision/
    create_pose_tracker.m  共享取帧和位姿更新
    detect_apriltags.m  识别 Tag 与角点
    estimate_robot_pose.m  高度补偿及车体位姿换算
    validate_tag_geometry.m  校验 Tag 几何和场地条件

八、验证和清理记录

2026-11-10 审查使用 MATLAB R2026a Update 2。三个入口已通过依赖检查，
51 个 MATLAB 源文件已运行 Code Analyzer。14 项离线测试全部通过，
可在项目目录执行 runtests('tests') 复测。新增覆盖课件式（2-6）的独立矩阵计算、
位姿过期、断帧、对焦变化、串口进行中关闭、迟到回包和停车失败后的资源释放。

三个入口均用模拟相机、模拟串口和隔离的合成标定数据走通。
棋盘采集跳过了空白及重复帧，合成标定整体 RMS 为 0.0483 px。
场地入口拒绝了共线拟合点，重采后完成保存。底层入口拒绝了不配对的内外参，
在匹配标定下成功取位姿。启动仅发只读探测，关闭时模拟串口确认归零。
随机测试覆盖 100 组带像素噪声的外参拟合、每组 20 个验证点，
本次合成数据的最大地面误差为 1.057 mm。六车乱序映射通过 600 组模拟位姿验证。
持续测试分两轮使用六条模拟串口，交替检查正常画面、标签缺失、取帧异常和对焦变化。
首轮检查 216 次、取帧 2,104 次后为更新程序主动结束。新版检查 243 次、取帧 2,381 次，
随后监视会话关闭，持续测试提前结束。结束后确认模拟串口已释放，定时器和监视窗口均为零。

合成图像的 AprilTag 识别中位耗时（不含相机取帧和串口）
640×360，降采样因子 1 和 2 分别约 2.80 ms、1.45 ms。
1280×720，降采样因子 1 和 2 分别约 7.49 ms、3.10 ms。
这些数值只描述本机处理合成图像的表现。

实验摄像头尚未接入。电脑当前枚举到的另一台 USB2.0 HD UVC WebCam 成功取帧，
它的焦距读值和图像结果仅属于该设备。实验摄像头接上后需现场验证预览、锁焦、
棋盘内参、场地外参及实际定位精度。e-puck2 蓝牙、电机及实物停车仍需现场验证。
真实电机测试由操作者明确发起。

旧入口、旧控制模块和旧配置已经退出项目，原标定未迁入新格式。收尾移除了旧的
空目录 calibration/camera、calibration/field、calibration_data/slot1、
calibration_data、control 和 data/camera_images_20261101_200118_751。
临时 QA 日志 epuck_qa_capture.txt、epuck_qa_capture2.txt、epuck_qa_dependencies.txt
已汇总到本说明并移除。data/ 和 logs/ 下的运行目录由程序按需创建。
