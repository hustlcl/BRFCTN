function [PSNR, RSE, SSIM] = My_ImageQualityMeasure(Xtrue, Xhat)
xSize = size(Xtrue);
PSNR = My_PSNR_RGB(Xhat, Xtrue);
RSE  = My_perfscore(Xhat, Xtrue);

SSIMArr = zeros(1,xSize(4));

for j=1:xSize(4)
    XiTrue = reshape(Xtrue(:,:,:,j),xSize(1),xSize(2),xSize(3));
    XiHat  = reshape(Xhat(:,:,:,j),xSize(1),xSize(2),xSize(3));
    SSIMArr(j) = My_ssim_index( rgb2gray(uint8(XiHat)), rgb2gray(uint8(XiTrue)));
end
SSIM = mean(SSIMArr);
end