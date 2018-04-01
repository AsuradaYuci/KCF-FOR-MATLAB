function kf = gaussian_correlation(xf, yf, sigma)
%GAUSSIAN_CORRELATION Gaussian Kernel at all shifts, i.e. kernel correlation.GAUSSIAN_CORRELATION所有移位的高斯内核，即内核相关。
%   Evaluates a Gaussian kernel with bandwidth SIGMA for all relative      针对输入图像X和Y之间的所有相对位移，
%   shifts between input images X and Y, which must both be MxN. They must 评估具有带宽SIGMA的高斯内核，其必须都是M×N。
%   also be periodic (ie., pre-processed with a cosine window). The result 它们也必须是周期性的（即，用余弦窗预处理）。
%   is an MxN map of responses.                                            结果是一个MxN响应图。
%
%   Inputs and output are all in the Fourier domain.                       输入和输出都在傅里叶域。
%
%   Joao F. Henriques, 2014
%   http://www.isr.uc.pt/~henriques/
	
	N = size(xf,1) * size(xf,2);
	xx = xf(:)' * xf(:) / N;  %squared norm of x                           x的平方规范
	yy = yf(:)' * yf(:) / N;  %squared norm of y                           y的平方规范
	
	%cross-correlation term in Fourier domain                              傅立叶域中的互相关项
	xyf = xf .* conj(yf);
	xy = sum(real(ifft2(xyf)), 3);  %to spatial domain                     转换到空间域
	
	%calculate gaussian response for all positions, then go back to the    计算所有位置的高斯响应，然后返回傅立叶域
	%Fourier domain
	kf = fft2(exp(-1 / sigma^2 * max(0, (xx + yy - 2 * xy) / numel(xf))));

end

