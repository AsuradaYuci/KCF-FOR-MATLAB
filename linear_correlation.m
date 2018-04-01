function kf = linear_correlation(xf, yf)
%LINEAR_CORRELATION Linear Kernel at all shifts, i.e. correlation.         线性内核在所有位移，即相关。
%   Computes the dot-product for all relative shifts between input images  计算输入图像X和Y之间的所有相对偏移的点积，
%   X and Y, which must both be MxN. They must also be periodic (ie.,      输入图像的大小它们必须都是MxN。
%   pre-processed with a cosine window). The result is an MxN map of       它们也必须是周期性的（即，用余弦窗预处理）。
%   responses.                                                             结果是一个MxN响应图。
%
%   Inputs and output are all in the Fourier domain.                       输入和输出都在傅里叶域。
%
%   Joao F. Henriques, 2014
%   http://www.isr.uc.pt/~henriques/
	
	%cross-correlation term in Fourier domain                              傅立叶域中的互相关项
	kf = sum(xf .* conj(yf), 3) / numel(xf);                               %conj是求复数的共轭

end

