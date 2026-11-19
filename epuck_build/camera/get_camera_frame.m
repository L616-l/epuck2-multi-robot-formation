function frame = get_camera_frame(cam, expectedSize)
frame = snapshot(cam);
if nargin == 2
    assert(isequal(size(frame,[1 2]),expectedSize),'epuck:FrameSize', ...
        '实际帧尺寸与标定尺寸不一致。');
end
end
