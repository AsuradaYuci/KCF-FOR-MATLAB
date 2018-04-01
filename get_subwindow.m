function out = get_subwindow(im, pos, sz)
%GET_SUBWINDOW Obtain sub-window from image, with replication-padding.     通过复制填充从图像获取子窗口。
%   Returns sub-window of image IM centered at POS ([y, x] coordinates),   返回以POS（[y，x]坐标）为中心的图像IM的子窗口，
%   with size SZ ([height, width]). If any pixels are outside of the image,大小为SZ（[height，width]）。
%   they will replicate the values at the borders.                         如果任何像素在图像之外，它们将在边界复制值。
%
%   Joao F. Henriques, 2014
%   http://www.isr.uc.pt/~henriques/

	if isscalar(sz),  %square sub-window                                   子窗口的平方
		sz = [sz, sz];
	end
	
	xs = floor(pos(2)) + (1:sz(2)) - floor(sz(2)/2);
	ys = floor(pos(1)) + (1:sz(1)) - floor(sz(1)/2);
	
	%check for out-of-bounds coordinates, and set them to the values at    检查超出边界的坐标，并将它们设置为边界值
	%the borders
	xs(xs < 1) = 1;
	ys(ys < 1) = 1;
	xs(xs > size(im,2)) = size(im,2);
	ys(ys > size(im,1)) = size(im,1);
	
	%extract image                                                         提取图像
	out = im(ys, xs, :);

end

