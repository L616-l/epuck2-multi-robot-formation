function [fit, independent] = collect_field_points(frame, cfg)
window = figure('Name','场地标定点采集','NumberTitle','off');
cleanup = onCleanup(@() closeWindow(window));
axesHandle = axes(window);
imshow(frame,'Parent',axesHandle);
hold(axesHandle,'on');
fprintf(['在图像里左键点击地面标志，再回到 MATLAB 命令行填写其 [X,Y]。\n' ...
    '原点为 [0,0]，+X 边的末端为 [%g,0]，+Y 边的末端为 [0,%g]，单位 mm。\n' ...
    '先选分布在场地四周的拟合点，再选其他区域内的独立验证点。\n'],cfg.lengthMm,cfg.widthMm);
coordinates = "填写地面 [X,Y] (mm)，X 范围 0–" + cfg.lengthMm + ...
    "，Y 范围 0–" + cfg.widthMm + "，坐标须唯一。直接回车重选像素，输入 cancel 退出：";
[fit.pixel,fit.world] = collect(cfg.fitCount,"拟合",'g',zeros(0,2),zeros(0,2));
[independent.pixel,independent.world] = collect(cfg.validationCount,"独立验证",'c',fit.pixel,fit.world);

    function [pixel,world] = collect(count,role,color,usedPixel,usedWorld)
        pixel = NaN(count,2);
        world = NaN(count,2);
        for k = 1:count
            label = role + "点 " + k + "/" + count;
            while true
                assert(isgraphics(window),'epuck:Cancelled','已关闭场地选点窗口。');
                figure(window); window.CurrentAxes = axesHandle;
                title(axesHandle,label + "：左键选点，Esc 或回车取消采集");
                try
                    [u,v,button] = ginput(1);
                catch err
                    assert(isgraphics(window),'epuck:Cancelled','已关闭场地选点窗口。');
                    rethrow(err)
                end
                assert(~isempty(button) && button~=27, ...
                    'epuck:Cancelled','已取消场地选点。');
                inImage = u>=1 && v>=1 && u<=size(frame,2) && v<=size(frame,1);
                if button~=1 || ~inImage || ismember([u v],usedPixel,'rows')
                    disp('请在图像内左键点击尚未选过的标志点。');
                    continue
                end
                marker = plot(axesHandle,u,v,'y+');
                title(axesHandle,label + "：回到 MATLAB 命令行填写坐标");
                fprintf('%s，选中像素 [%.1f, %.1f]。\n',label,u,v);
                xy = required_input(coordinates, ...
                    @(x) isvector(x) && numel(x)==2 && all(isfinite(x)) && ...
                    x(1)>=0 && x(1)<=cfg.lengthMm && x(2)>=0 && x(2)<=cfg.widthMm && ...
                    ~ismember(x(:).',usedWorld,'rows'),true,AllowEmpty=true);
                assert(isgraphics(window),'epuck:Cancelled','已关闭场地选点窗口。');
                if isempty(xy)
                    delete(marker);
                    continue
                end
                pixel(k,:) = [u v];
                world(k,:) = xy(:).';
                usedPixel(end+1,:) = pixel(k,:); %#ok<AGROW>
                usedWorld(end+1,:) = world(k,:); %#ok<AGROW>
                marker.Color = color;
                text(axesHandle,u,v,role + k,'Color',color);
                break
            end
        end
    end
end

function closeWindow(window)
if isgraphics(window)
    close(window);
end
end
