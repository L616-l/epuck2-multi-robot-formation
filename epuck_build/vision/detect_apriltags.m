function [ids,corners] = detect_apriltags(frame,cfg)
% 保留原始像素角点。去畸变在统一像素射线接口中完成。
[ids,corners] = readAprilTag(frame,cfg.family, ...
    GaussianSigma=cfg.gaussianSigma,DecimationFactor=cfg.decimation);
end
