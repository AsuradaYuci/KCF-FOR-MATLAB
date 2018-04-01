function x = get_features(im, features, cell_size, cos_window)
%GET_FEATURES
%   Extracts dense features from image.                                    从图像中提取密集的特征。
%
%   X = GET_FEATURES(IM, FEATURES, CELL_SIZE)
%   Extracts features specified in struct FEATURES, from image IM. The     从图像IM中提取struct FEATURES中指定的特征。
%   features should be densely sampled, in cells or intervals of CELL_SIZE.这些特征应该以CELL_SIZE的单元格或间隔进行密集采样。
%   The output has size [height in cells, width in cells, features].       输出具有大小[单元格高度，单元格宽度，特征]。
%
%   To specify HOG features, set field 'hog' to true, and                  要指定HOG特征，请将字段“hog”设置为true，
%   'hog_orientations' to the number of bins.                              并将“hog_orientations”设置为箱数量。
%
%   To experiment with other features simply add them to this function     要试验其他功能，只需将它们添加到此功能中，
%   and include any needed parameters in the FEATURES struct. To allow     并在FEATURES结构中包含所需的任何参数。
%   combinations of features, stack them with x = cat(3, x, new_feat).     要允许组合特征，请使用x = cat（3，x，new_feat）将它们堆叠起来。
%
%   Joao F. Henriques, 2014
%   http://www.isr.uc.pt/~henriques/


	if features.hog,
		%HOG features, from Piotr's Toolbox                                HOG功能，来自Piotr的工具箱
		x = double(fhog(single(im) / 255, cell_size, features.hog_orientations));
		x(:,:,end) = [];  %remove all-zeros channel ("truncation feature") 删除全零通道（“截断功能”）
	end
	
	if features.gray,
		%gray-level (scalar feature)                                       灰度（标量特征）
		x = double(im) / 255;
		
		x = x - mean(x(:));
	end
	
	%process with cosine window if needed                                  如果需要，用余弦窗口处理
	if ~isempty(cos_window),
		x = bsxfun(@times, x, cos_window);
	end
	
end
