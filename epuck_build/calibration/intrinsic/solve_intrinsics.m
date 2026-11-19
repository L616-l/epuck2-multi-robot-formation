function result = solve_intrinsics(points, imageSize, cfg)
world = generateCheckerboardPoints(cfg.boardSquares(:).',cfg.squareMm);
[params, used] = estimateCameraParameters(points,world, ...
    ImageSize=imageSize,WorldUnits='mm',EstimateSkew=false, ...
    EstimateTangentialDistortion=true,NumRadialDistortionCoefficients=cfg.radialTerms);
assert(all(used),'epuck:BadIntrinsics','部分标定图像未参与求解，请重新采集。');
result = struct('kind',"intrinsic",'cameraParams',params,'K',params.Intrinsics.K, ...
    'imageSize',imageSize,'radialDistortion',params.RadialDistortion, ...
    'tangentialDistortion',params.TangentialDistortion);
result.fx = result.K(1,1);
result.fy = result.K(2,2);
result.u0 = result.K(1,3);
result.v0 = result.K(2,3);
squared = sum(params.ReprojectionErrors.^2,2);
result.viewRmsPx = reshape(sqrt(mean(squared,1)),[],1);
result.rmsPx = sqrt(mean(squared(:)));
result.meanReprojectionErrorPx = params.MeanReprojectionError;
end
