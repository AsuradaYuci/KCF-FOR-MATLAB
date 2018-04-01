function [img_files, pos, target_sz, ground_truth, video_path] = load_video_info(base_path, video)
%LOAD_VIDEO_INFO
%   Loads all the relevant information for the video in the given path:    在给定路径中加载视频的所有相关信息：
%   the list of image files (cell array of strings), initial position      图像文件列表（字符串单元格数组），
%   (1x2), target size (1x2), the ground truth information for precision   初始位置（1x2），目标大小（1x2）， 精确的ground truth信息
%   calculations (Nx2, for N frames), and the path where the images are    计算（Nx2，N帧）以及图像所在的路径。
%   located. The ordering of coordinates and sizes is always [y, x].       坐标和大小的排序总是[y，x]。    
%
%   Joao F. Henriques, 2014
%   http://www.isr.uc.pt/~henriques/


	%see if there's a suffix, specifying one of multiple targets, for      查看是否有后缀，指定多个目标中的一个，
	%example the dot and number in 'Jogging.1' or 'Jogging.2'.             例如“Jogging.1”或“Jogging.2”中的点和数字。
	if numel(video) >= 2 && video(end-1) == '.' && ~isnan(str2double(video(end))),
		suffix = video(end-1:end);  %remember the suffix                   记住后缀
		video = video(1:end-2);  %remove it from the video name            从视频名称中删除它
	else
		suffix = '';
	end

	%full path to the video's files                                        视频文件的完整路径
	if base_path(end) ~= '/' && base_path(end) ~= '\',
		base_path(end+1) = '/';
	end
	video_path = [base_path video '/'];

	%try to load ground truth from text file (Benchmark's format)          尝试从文本文件加载ground truth（基准格式）
	filename = [video_path 'groundtruth_rect' suffix '.txt'];
	f = fopen(filename);
	assert(f ~= -1, ['No initial position or ground truth to load ("' filename '").'])
	
	%the format is [x, y, width, height]                                   格式是[x，y，宽度，高度]
	try
		ground_truth = textscan(f, '%f,%f,%f,%f', 'ReturnOnError',false);  
	catch  %ok, try different format (no commas)                           尝试不同的格式（无逗号）
		frewind(f);
		ground_truth = textscan(f, '%f %f %f %f');  
	end
	ground_truth = cat(2, ground_truth{:});
	fclose(f);
	
	%set initial position and size                                         设置初始位置和大小
	target_sz = [ground_truth(1,4), ground_truth(1,3)];
	pos = [ground_truth(1,2), ground_truth(1,1)] + floor(target_sz/2);
	
	if size(ground_truth,1) == 1,
		%we have ground truth for the first frame only (initial position)  我们只有第一帧的ground truth（初始位置）
		ground_truth = [];
	else
		%store positions instead of boxes                                  存储位置而不是框
		ground_truth = ground_truth(:,[2,1]) + ground_truth(:,[4,3]) / 2;
	end
	
	
	%from now on, work in the subfolder where all the images are           从现在起，在所有图像所在的子文件夹中工作
	video_path = [video_path 'img/'];
	
	%for these sequences, we must limit ourselves to a range of frames.    对于这些序列，我们必须将自己限制在一系列帧中。
	%for all others, we just load all png/jpg files in the folder.         对于所有其他的序列，我们只需加载文件夹中的所有png / jpg文件。
	frames = {'David', 300, 770;
			  'Football1', 1, 74;
			  'Freeman3', 1, 460;
			  'Freeman4', 1, 283};
	
	idx = find(strcmpi(video, frames(:,1)));
	
	if isempty(idx),
		%general case, just list all images                                一般情况下，只需列出所有图像
		img_files = dir([video_path '*.png']);
		if isempty(img_files),
			img_files = dir([video_path '*.jpg']);
			assert(~isempty(img_files), 'No image files to load.')
		end
		img_files = sort({img_files.name});
	else
		%list specified frames. try png first, then jpg.                   列出指定的帧。 先尝试PNG，然后JPG
		if exist(sprintf('%s%04i.png', video_path, frames{idx,2}), 'file'),
			img_files = num2str((frames{idx,2} : frames{idx,3})', '%04i.png');
			
		elseif exist(sprintf('%s%04i.jpg', video_path, frames{idx,2}), 'file'),
			img_files = num2str((frames{idx,2} : frames{idx,3})', '%04i.jpg');
			
		else
			error('No image files to load.')
		end
		
		img_files = cellstr(img_files);
	end
	
end

