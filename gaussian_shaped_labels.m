function labels = gaussian_shaped_labels(sigma, sz)
%GAUSSIAN_SHAPED_LABELS
%   Gaussian-shaped labels for all shifts of a sample.                     用于样本所有位移的高斯形标签
%
%   LABELS = GAUSSIAN_SHAPED_LABELS(SIGMA, SZ)
%   Creates an array of labels (regression targets) for all shifts of a    为尺寸为SZ的样本的所有移位创建一组标签（回归目标）。
%   sample of dimensions SZ. The output will have size SZ, representing    输出的尺寸为SZ，代表每个可能的班次的一个标签。
%   one label for each possible shift. The labels will be Gaussian-shaped, 标签将为高斯形状，峰值为0移位（阵列的左上角元素），
%   with the peak at 0-shift (top-left element of the array), decaying     随距离增加而衰减，并在边界处环绕。
%   as the distance increases, and wrapping around at the borders.
%   The Gaussian function has spatial bandwidth SIGMA.                     高斯函数具有空间带宽SIGMA。
%
%   Joao F. Henriques, 2014
%   http://www.isr.uc.pt/~henriques/


% 	%as a simple example, the limit sigma = 0 would be a Dirac delta,
% 	%instead of a Gaussian:
% 	labels = zeros(sz(1:2));  %labels for all shifted samples              所有移位样本的标签
% 	labels(1,1) = magnitude;  %label for 0-shift (original sample)         0移动的标签（原始样本) 
	

	%evaluate a Gaussian with the peak at the center element               用中心元素处的峰值评估高斯
	[rs, cs] = ndgrid((1:sz(1)) - floor(sz(1)/2), (1:sz(2)) - floor(sz(2)/2));
	labels = exp(-0.5 / sigma^2 * (rs.^2 + cs.^2));

	%move the peak to the top-left, with wrap-around                       将峰顶移至左上角，并进行环绕
	labels = circshift(labels, -floor(sz(1:2) / 2) + 1);

	%sanity check: make sure it's really at top-left                       完整性检查：确保它真的在左上角
	assert(labels(1,1) == 1)

end

