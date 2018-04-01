function kf = polynomial_correlation(xf, yf, a, b)
%POLYNOMIAL_CORRELATION Polynomial Kernel at all shifts, i.e. kernel correlation.多项式内核在所有移位，即内核相关。
%   Evaluates a polynomial kernel with constant A and exponent B, for all  对于输入图像XF和YF之间的所有相对位移，
%   relative shifts between input images XF and YF, which must both be MxN.计算一个常数为A和指数为B的多项式核，它们必须都是M×N。
%   They must also be periodic (ie., pre-processed with a cosine window).  它们也必须是周期性的（即，用余弦窗预处理）。
%   The result is an MxN map of responses.                                 结果是一个MxN响应图。
%
%   Inputs and output are all in the Fourier domain.
%
%   Joao F. Henriques, 2014
%   http://www.isr.uc.pt/~henriques/
	
	%cross-correlation term in Fourier domain                              傅立叶域中的互相关项
	xyf = xf .* conj(yf);
	xy = sum(real(ifft2(xyf)), 3);  %to spatial domain                     转到空间域
	
	%calculate polynomial response for all positions, then go back to the  计算所有位置的多项式响应，然后返回到傅立叶域
	%Fourier domain
	kf = fft2((xy / numel(xf) + a) .^ b);

end

