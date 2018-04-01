function [positions, time] = tracker(video_path, img_files, pos, target_sz, ...
	padding, kernel, lambda, output_sigma_factor, interp_factor, cell_size, ...
	features, show_visualization)
%TRACKER Kernelized/Dual Correlation Filter (KCF/DCF) tracking.
%                                                                          跟踪器内核/双相关滤波器（KCF / DCF）跟踪。
%   This function implements the pipeline for tracking with the KCF (by
%   choosing a non-linear kernel) and DCF (by choosing a linear kernel).
%                                                          该函数实现了跟踪KCF（通过选择非线性内核）和DCF（通过选择线性内核）的流水线。
%   It is meant to be called by the interface function RUN_TRACKER, which
%   sets up the parameters and loads the video information.
%                                                                          它意味着由接口函数RUN_TRACKER调用，该函数设置参数并加载视频信息。
%   Parameters:                                                             参数
%     VIDEO_PATH is the location of the image files (must end with a slash
%      '/' or '\').                                                        VIDEO_PATH是图像文件的位置
%     IMG_FILES is a cell array of image file names.                       IMG_FILES是图像文件名称的单元阵列。
%     POS and TARGET_SZ are the initial position and size of the target
%      (both in format [rows, columns]).                                   POS和TARGET_SZ是目标的初始位置和大小（格式[行，列]）
%     PADDING is the additional tracked region, for context, relative to 
%      the target size.                                                    PADDING是相对于目标尺寸而言的上下文附加跟踪区域。
%     KERNEL is a struct describing the kernel. The field TYPE must be one   KERNEL是描述内核的结构。
%      of 'gaussian', 'polynomial' or 'linear'. The optional fields SIGMA,   字段TYPE必须是'高斯'，'多项式'或'线性'之一。
%      POLY_A and POLY_B are the parameters for the Gaussian and Polynomial  可选字段SIGMA，POLY_A和POLY_B是高斯和多项式内核的参数。
%      kernels.
%     OUTPUT_SIGMA_FACTOR is the spatial bandwidth of the regression
%      target, relative to the target size.                                 OUTPUT_SIGMA_FACTOR是回归目标相对于目标大小的空间带宽。
%     INTERP_FACTOR is the adaptation rate of the tracker.                  INTERP_FACTOR是跟踪器的自适应速率。
%     CELL_SIZE is the number of pixels per cell (must be 1 if using raw
%      pixels).                                                             CELL_SIZE是每个单元格的像素数量（如果使用原始像素，则必须为1）。
%     FEATURES is a struct describing the used features (see GET_FEATURES). FEATURES是描述使用特征的结构（请参阅GET_FEATURES）。
%     SHOW_VISUALIZATION will show an interactive video if set to true.     如果设置为true，SHOW_VISUALIZATION将显示一个交互式视频。
%
%   Outputs:                                                                输出                                                               
%    POSITIONS is an Nx2 matrix of target positions over time (in the
%     format [rows, columns]).                                              POSITIONS是随时间变化的目标位置的N×2矩阵（格式为[行，列]）。
%    TIME is the tracker execution time, without video loading/rendering.   TIME是追踪器的执行时间，没有视频加载/渲染。
%
%   Joao F. Henriques, 2014


	%if the target is large, lower the resolution, we don't need that much
	%detail                                                                如果目标很大，降低分辨率，我们不需要太多细节
	resize_image = (sqrt(prod(target_sz)) >= 100);  %diagonal size >= threshold    对角线大小> =阈值
	if resize_image,
		pos = floor(pos / 2);                                              %目标尺寸过大就将其缩小1/2
		target_sz = floor(target_sz / 2);                                   %除了显示是用的target_sz，用于计算的都是window_sz
	end


	%window size, taking padding into account                              窗口大小，考虑填充
	window_sz = floor(target_sz * (1 + padding));                          %floor向下取整，目标框向外扩展1.5倍作为window_sz
	                                                                       %后面所有的处理都用window_sz，即包含目标和背景
% 	%we could choose a size that is a power of two, for better FFT          我们可以选择2的次幂的大小，以获得更好的FFT
% 	%performance. in practice it is slower, due to the larger window size.  但是在实际中反而更慢，由于尺寸太大 
% 	
% 	window_sz = 2 .^ nextpow2(window_sz);

	
	%create regression labels, gaussian shaped, with a bandwidth
	%创建回归标签，高斯形状，其带宽和目标的尺寸成比例（目标尺寸越大，带宽越宽）
	%proportional to target size
	output_sigma = sqrt(prod(target_sz)) * output_sigma_factor / cell_size;%prod计算数组元素的连乘积
    %output_sigma 为带宽delta；  cell_size每一个细胞中像素的数量（HOG),若不用HOG则为1
	yf = fft2(gaussian_shaped_labels(output_sigma, floor(window_sz / cell_size)));%fft2 2维离散傅里叶变换，yf是频域上的回归值

	%store pre-computed cosine window                                      存储预先计算的余弦窗口
	cos_window = hann(size(yf,1)) * hann(size(yf,2))';	                   %hann汉宁窗，使用yf的尺寸来生成相应的余弦窗
	%主体余弦窗，size(yf,1)返回行数，size(yf,2)返回列数
	
	if show_visualization,  %create video interface                        创建视频交互界面（处理过程的可视化）
		update_visualization = show_video(img_files, video_path, resize_image);
	end
	
	
	%note: variables ending with 'f' are in the Fourier domain.
	%带f的都是频域上的

	time = 0;  %to calculate FPS                                            为了计算FPS
	positions = zeros(numel(img_files), 2);  %to calculate precision       初始化n行2列的矩阵用来存放每一帧计算出的位置
                     %numel(img_files)视频的帧数
	for frame = 1:numel(img_files),
		%load image                                                         读图像
		im = imread([video_path img_files{frame}]);                        %读取一帧图像
		if size(im,3) > 1,
			im = rgb2gray(im);                                             %把彩色图转换为灰度图
		end
		if resize_image,
			im = imresize(im, 0.5);                                        %若目标过大，把整幅图变为原来的1/2大小
		end

		tic()                                                              %开始计时，和toc（）配合使用

        if frame > 1,
			%obtain a subwindow for detection at the position from last    从最后一帧的位置获得用于检测的子窗口，
			%frame, and convert to Fourier domain (its size is unchanged)  并转换到傅里叶域（其大小不变）
			patch = get_subwindow(im, pos, window_sz);
			zf = fft2(get_features(patch, features, cell_size, cos_window));%zf是测试样本
			
			%calculate response of the classifier at all shifts
			%计算分类器对于所有循环位移后的样本的响应
			switch kernel.type                                             %选择核的类型
			case 'gaussian',
				kzf = gaussian_correlation(zf, model_xf, kernel.sigma);    %通过对测试样本的核变换后得到kzf
			case 'polynomial',
				kzf = polynomial_correlation(zf, model_xf, kernel.poly_a, kernel.poly_b);
			case 'linear',
				kzf = linear_correlation(zf, model_xf);
			end
			response = real(ifft2(model_alphaf .* kzf));  %equation for fast detection计算响应
%real->返回实部（虚数），ifft2->反傅里叶变换，model_alphaf->模型，* ->元素点乘

			%target location is at the maximum response. we must take into    目标位置处于最大响应(这些响应周而复始)。
			%account the fact that, if the target doesn't move, the peak      我们必须考虑到这样一个事实，
			%will appear at the top-left corner, not at the center (this is   如果目标没有移动，
			%discussed in the paper). the responses wrap around cyclically.   峰值将出现在左上角，而不是中心（这在文章中讨论过）。
			[vert_delta, horiz_delta] = find(response == max(response(:)), 1);%找到响应最大的位置
			if vert_delta > size(zf,1) / 2,  %wrap around to negative half-space of vertical axis  绕到纵轴的负半空间
				vert_delta = vert_delta - size(zf,1);
			end
			if horiz_delta > size(zf,2) / 2,  %same for horizontal axis       与横轴相同
				horiz_delta = horiz_delta - size(zf,2);
			end
			pos = pos + cell_size * [vert_delta - 1, horiz_delta - 1];     %更新出目标的新位置
        end
%if frame>1  的结尾在这
        
		%obtain a subwindow for training at newly estimated target position在新估计的目标位置获得一个用于训练的子窗口
		patch = get_subwindow(im, pos, window_sz);                         %获取目标的位置和窗口大小
		xf = fft2(get_features(patch, features, cell_size, cos_window));   %用新的结果重新训练分类器

		%Kernel Ridge Regression, calculate alphas (in Fourier domain)
		%内核岭回归，（在傅里叶域）计算alphas(权值)
		switch kernel.type
		case 'gaussian',
			kf = gaussian_correlation(xf, xf, kernel.sigma);
		case 'polynomial',
			kf = polynomial_correlation(xf, xf, kernel.poly_a, kernel.poly_b);
		case 'linear',
			kf = linear_correlation(xf, xf);
		end
		alphaf = yf ./ (kf + lambda);   %equation for fast training        训练算出每个样本对应的权值

        %更新模板的权值
		if frame == 1,  %first frame, train with a single image            第一帧，用单幅图像训练。
			model_alphaf = alphaf;                                         %第一帧中就直接用训练出的权值和模板
			model_xf = xf;
		else
			%subsequent frames, interpolate model                          后续帧，插值模型
			model_alphaf = (1 - interp_factor) * model_alphaf + interp_factor * alphaf;%后续帧中的更新使用本帧和前一帧中结果的加权
			model_xf = (1 - interp_factor) * model_xf + interp_factor * xf;
        end                           %model_xf 上一帧 ，  interp_factor * xf 这一帧的  

		%save position and timing
		positions(frame,:) = pos;                                          %保存每一帧中的目标位置
		time = time + toc();                                               %保存处理所耗的时间

		%visualization                                                     将每一帧的结果显示出来
		if show_visualization,
			box = [pos([2,1]) - target_sz([2,1])/2, target_sz([2,1])];    
			stop = update_visualization(frame, box);
			if stop, break, end  %user pressed Esc, stop early             用户按Esc，提前停止
			
			drawnow
% 			pause(0.05) 暂停 %uncomment to run slower取消这行注释，则运行较慢
		end
		
    end%  和第80行的for 组成一个end of for 循环

	if resize_image,                                                       %若之前将图像缩小了，则将位置的坐标换算回去
		positions = positions * 2;
	end
end

