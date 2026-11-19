function yes = confirm_choice(prompt)
% 明确输入 y 或 n。留空不视为同意。
while true
    reply = lower(strtrim(string(input(prompt + " [y/n] ",'s'))));
    if reply == "y" || reply == "n"
        yes = reply == "y";
        return
    end
    disp('请输入 y 或 n。');
end
end
