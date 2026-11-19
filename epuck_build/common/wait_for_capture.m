function wait_for_capture(prompt)
while true
    reply = lower(strtrim(string(input(prompt + "。按回车拍照，或输入 cancel 取消： ",'s'))));
    if reply == ""
        return
    end
    if any(reply == ["cancel","取消"])
        error('epuck:Cancelled','已取消图像采集。');
    end
    disp('请直接按回车拍照，或输入 cancel 取消。');
end
end
