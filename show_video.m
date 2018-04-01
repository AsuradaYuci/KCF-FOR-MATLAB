function update_visualization_func = show_video(img_files, video_path, resize_image)
%SHOW_VIDEO
%   Visualizes a tracker in an interactive figure, given a cell array of
%   image file names, their path, and whether to resize the images to
%   half size or not.在交互式图形中显示跟踪器，给定图像文件名称的单元阵列，路径以及是否将图像大小调整为一半。
%
%   This function returns an UPDATE_VISUALIZATION function handle, that    该函数返回一个UPDATE_VISUALIZATION函数句柄，
%   can be called with a frame number and a bounding box [x, y, width,     一旦计算出新帧的结果，
%   height], as soon as the results for a new frame have been calculated.  该句柄就可以用帧号和边界框[x，y，width，height]调用。
%   This way, your results are shown in real-time, but they are also       这样，您的结果即时显示，
%   remembered so you can navigate and inspect the video afterwards.       并且它们也会被记住，以便以后可以导航并检查视频。
%   Press 'Esc' to send a stop signal (returned by UPDATE_VISUALIZATION).  按'Esc'发送一个停止信号（由UPDATE_VISUALIZATION返回）。
%
%   Joao F. Henriques, 2014
%   http://www.isr.uc.pt/~henriques/


	%store one instance per frame                                          每帧存储一个实例
	num_frames = numel(img_files);                                         %numel：返回图像中的像素个数
	boxes = cell(num_frames,1);                                            %cell：创建一个num_frames*1的cell矩阵

	%create window                                                         创建窗口
	[fig_h, axes_h, unused, scroll] = videofig(num_frames, @redraw, [], [], @on_key_press);  %#ok, unused outputs
	set(fig_h, 'Number','off', 'Name', ['Tracker - ' video_path])          %set：设置图像属性
	axis off;        %axis：设置坐标轴
	
	%image and rectangle handles start empty, they are initialized later   图像和矩形handle开始为空，它们在稍后被初始化
	im_h = [];
	rect_h = [];
	
	update_visualization_func = @update_visualization;                     %@：是用于定义函数句柄的操作符。
	stop_tracker = false;                                                  %函数句柄既是一种变量，可以用于传参和赋值；也是可以当做函数名一样使用。
	

	function stop = update_visualization(frame, box)
		%store the tracker instance for one frame, and show it. returns    将跟踪器实例存储一帧，并显示它。
		%true if processing should stop (user pressed 'Esc').              如果处理停止（用户按'Esc'），则返回true。
		boxes{frame} = box;                                                %存储帧
		scroll(frame);                                                     %显示帧
		stop = stop_tracker;
	end

	function redraw(frame)
		%render main image                                                 渲染主图像
		im = imread([video_path img_files{frame}]);                        %imread：用于读取图片文件中的数据
		if size(im,3) > 1,                                                 %3表示为RGB，如果图像为彩色图，则将其转换为灰度图
			im = rgb2gray(im);
		end
		if resize_image,                                                   %调整图像大小
			im = imresize(im, 0.5);
		end
		
		if isempty(im_h),  %create image                                   如果没有图像输入，则创建图像
			im_h = imshow(im, 'Border','tight', 'InitialMag',200, 'Parent',axes_h);
		else  %just update it                                              如果有图像输入则更新它
			set(im_h, 'CData', im)
		end
		
		%render target bounding box for this frame                         为此帧渲染目标边界框
		if isempty(rect_h),  %create it for the first time                 如果没有矩形边界框，则第一次创建它
			rect_h = rectangle('Position',[0,0,1,1], 'EdgeColor','g', 'Parent',axes_h);
            %rectangle:绘制矩形图形，边框颜色，
		end
		if ~isempty(boxes{frame}),                                         %如果存储的帧不为0（boxes{frame}应该是个坐标）
			set(rect_h, 'Visible', 'on', 'Position', boxes{frame});
		else
			set(rect_h, 'Visible', 'off');
		end
	end

	function on_key_press(key)
		if strcmp(key, 'escape'),  %stop on 'Esc'
			stop_tracker = true;
		end
	end

end

