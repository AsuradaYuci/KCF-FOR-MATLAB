
%  Main interface for Kernelized/Dual Correlation Filters (KCF/DCF).       内核/双相关滤波器（KCF / DCF）的主界面。
%  This function takes care of setting up parameters, loading video        该功能负责设置参数，加载视频信息和计算精度。
%  information and computing precisions. For the actual tracking code,     对于实际的跟踪代码，请查看TRACKER功能。
%  check out the TRACKER function.
%
%  RUN_TRACKER
%    Without any parameters, will ask you to choose a video, track using   如果没有任何参数，会要求您选择一个视频，
%    the Gaussian KCF on HOG, and show the results in an interactive       使用HOG上的高斯KCF进行跟踪，并以交互式图形显示结果。
%    figure. Press 'Esc' to stop the tracker early. You can navigate the   按'Esc'可以提前停止跟踪器。
%    video using the scrollbar at the bottom.                              您可以使用底部的滚动条浏览视频。
%
%  RUN_TRACKER VIDEO
%    Allows you to select a VIDEO by its name. 'all' will run all videos   允许您通过名称选择视频。'all'将运行所有视频并显示平均统计数据。
%    and show average statistics. 'choose' will select one interactively.  'choose'将以交互方式选择一个。
%
%  RUN_TRACKER VIDEO KERNEL
%    Choose a KERNEL. 'gaussian'/'polynomial' to run KCF, 'linear' for DCF.选择一个内核。'高斯'/'多项式'运行KCF，'线性'用于DCF。
%
%  RUN_TRACKER VIDEO KERNEL FEATURE
%    Choose a FEATURE type, either 'hog' or 'gray' (raw pixels).           选择一个特征类型，无论是'hog'还是'灰度'（原始像素）。
%
%  RUN_TRACKER(VIDEO, KERNEL, FEATURE, SHOW_VISUALIZATION, SHOW_PLOTS)
%    Decide whether to show the scrollable figure, and the precision plot. 决定是否显示可滚动的图形和精度图。
%
%  Useful combinations:                                                    有用的组合
%  >> run_tracker choose gaussian hog  %Kernelized Correlation Filter (KCF)
%  >> run_tracker choose linear hog    %Dual Correlation Filter (DCF)
%  >> run_tracker choose gaussian gray %Single-channel KCF (ECCV'12 paper)
%  >> run_tracker choose linear gray   %MOSSE filter (single channel)
%


function [precision, fps] = run_tracker(video, kernel_type, feature_type, show_visualization, show_plots)

	%path to the videos (you'll be able to choose one with the GUI).
	base_path = 'E:\tracker_release2\data\Benchmark';

	%default settings   默认设置
	if nargin < 1, video = 'choose'; end                                   %nargin->number of input arguments的缩写
	if nargin < 2, kernel_type = 'gaussian'; end                           %nargin函数：指出了输入参数个数
	if nargin < 3, feature_type = 'hog'; end
	if nargin < 4, show_visualization = ~strcmp(video, 'all'); end
	if nargin < 5, show_plots = ~strcmp(video, 'all'); end


	%parameters according to the paper. at this point we can override      根据论文参数。   
	%parameters based on the chosen kernel or feature type                 此时我们可以根据所选内核或特征类型覆盖参数
	kernel.type = kernel_type;
	
	features.gray = false;
	features.hog = false;
	
	padding = 1.5;  %extra area surrounding the target                     目标周围的额外区域（目标框向外扩展1.5倍）
	lambda = 1e-4;  %regularization                                        正则化参数
	output_sigma_factor = 0.1;  %spatial bandwidth (proportional to target)空间带宽（与目标成比例）
	
	switch feature_type
	case 'gray', %灰度特征                     
		interp_factor = 0.075;  %linear interpolation factor for adaptation 用于自适应的线性插值因子

		kernel.sigma = 0.2;  %gaussian kernel bandwidth                    高斯核带宽
		
		kernel.poly_a = 1;  %polynomial kernel additive term               多项式核加法项
		kernel.poly_b = 7;  %polynomial kernel exponent                    多项式核指数项
	
		features.gray = true;
		cell_size = 1;
		
	case 'hog',%hog特征
		interp_factor = 0.02;
		
		kernel.sigma = 0.5;
		
		kernel.poly_a = 1;
		kernel.poly_b = 9;
		
		features.hog = true;
		features.hog_orientations = 9;
		cell_size = 4;
		
	otherwise
		error('Unknown feature.')
	end


	assert(any(strcmp(kernel_type, {'linear', 'polynomial', 'gaussian'})), 'Unknown kernel.')
%strcmp，字符串比较函数，一样则返回1，不一样则返回0.  any判断元素是否为0元素，是非零元素返回1，否则返回0
%assert断言函数，在程序中确保某些条件成立
	switch video
	case 'choose',
		%ask the user for the video, then call self with that video name.   向用户询问视频，然后用该视频名称调用自己
		video = choose_video(base_path);
		if ~isempty(video),      %判断输入是否为非空
			[precision, fps] = run_tracker(video, kernel_type, ...
				feature_type, show_visualization, show_plots);
			
			if nargout == 0,  %don't output precision as an argument       不要输出精度作为参数
				clear precision
			end
		end
		
		
	case 'all',
		%all videos, call self with each video name.
		%所有的视频，每个视频名称自我调用
		%only keep valid directory names                                   只保留有效的目录名称
		dirs = dir(base_path);
		videos = {dirs.name};
		videos(strcmp('.', videos) | strcmp('..', videos) | ...
			strcmp('anno', videos) | ~[dirs.isdir]) = [];
		
		%the 'Jogging' sequence has 2 targets, create one entry for each.  “Jogging”序列有2个目标，为每个目标创建一个条目。
		%we could make this more general if multiple targets per video
		%becomes a common occurence.如果每个视频的多个目标成为常见现象，我们可以使这个更加通用。
		videos(strcmpi('Jogging', videos)) = [];
		videos(end+1:end+2) = {'Jogging.1', 'Jogging.2'};
		
		all_precisions = zeros(numel(videos),1);  %to compute averages     计算平均值
		all_fps = zeros(numel(videos),1);
		
		if ~exist('matlabpool', 'file'),%如果不存在'matlabpool'这个'file'，
			%no parallel toolbox, use a simple 'for' to iterate  没有平行的工具箱，用一个简单的'for'迭代
			for k = 1:numel(videos),
				[all_precisions(k), all_fps(k)] = run_tracker(videos{k}, ...
					kernel_type, feature_type, show_visualization, show_plots);
			end
		else
			%evaluate trackers for all videos in parallel     并行评估所有视频的跟踪器
			if matlabpool('size') == 0,
				matlabpool open;
			end
			parfor k = 1:numel(videos),%parfor并行计算
				[all_precisions(k), all_fps(k)] = run_tracker(videos{k}, ...
					kernel_type, feature_type, show_visualization, show_plots);
			end
		end
		
		%compute average precision at 20px, and FPS                        计算20px的平均精度和FPS
		mean_precision = mean(all_precisions);
		fps = mean(all_fps);
		fprintf('\nAverage precision (20px):% 1.3f, Average FPS:% 4.2f\n\n', mean_precision, fps)
		if nargout > 0,                                                    %nargout->指出了输出参数的个数
			precision = mean_precision;
		end
		
		
	case 'benchmark',
		%running in benchmark mode - this is meant to interface easily
		%with the benchmark's code.以基准模式运行 - 这意味着可以轻松地与基准测试代码进行交互。
		
		%get information (image file names, initial position, etc) from
		%the benchmark's workspace variables                               从基准工作区变量中获取信息（图像文件名称，初始位置等）
		seq = evalin('base', 'subS');                                      %evalin执行制定空间'base'中的命令'subS'
		target_sz = seq.init_rect(1,[4,3]);
		pos = seq.init_rect(1,[2,1]) + floor(target_sz/2);
		img_files = seq.s_frames;
		video_path = [];
		
		%call tracker function with all the relevant
		%parameters                                                        调用tracker函数与所有相关参数
		positions = tracker(video_path, img_files, pos, target_sz, ...
			padding, kernel, lambda, output_sigma_factor, interp_factor, ...
			cell_size, features, false);
		
		%return results to benchmark, in a workspace variable               将结果返回到基准测试，在工作区变量中
		rects = [positions(:,2) - target_sz(2)/2, positions(:,1) - target_sz(1)/2];
		rects(:,3) = target_sz(2);
		rects(:,4) = target_sz(1);
		res.type = 'rect';
		res.res = rects;
		assignin('base', 'res', res);%assignin用于在指定的工作区赋值，把数据从函数传递到MATLAB基本工作区（如本例，指定base）。
		
		
	otherwise
		%we were given the name of a single video to process.               我们获得了要处理的单个视频的名称。
	
		%get image file names, initial state, and ground truth for evaluation 获取图像文件名称，初始状态以及评估的ground truth
		[img_files, pos, target_sz, ground_truth, video_path] = load_video_info(base_path, video);
		
		
		%call tracker function with all the relevant parameters            调用tracker函数与所有相关参数
		[positions, time] = tracker(video_path, img_files, pos, target_sz, ...
			padding, kernel, lambda, output_sigma_factor, interp_factor, ...
			cell_size, features, show_visualization);
		
		
		%calculate and show precision plot, as well as frames-per-second   计算并显示精度图，以及每秒帧数
		precisions = precision_plot(positions, ground_truth, video, show_plots);
		fps = numel(img_files) / time;

		fprintf('%12s - Precision (20px):% 1.3f, FPS:% 4.2f\n', video, precisions(20), fps)

		if nargout > 0,
			%return precisions at a 20 pixels threshold                    以20像素阈值返回精度              
			precision = precisions(20);
		end

	end
end
