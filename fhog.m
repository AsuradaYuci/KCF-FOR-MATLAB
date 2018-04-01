function H = fhog( I, binSize, nOrients, clip, crop )
% Efficiently compute Felzenszwalb's HOG (FHOG) features.                  有效计算Felzenszwalb的HOG（FHOG）特征。
%
% A fast implementation of the HOG variant used by Felzenszwalb et al.     Felzenszwalb等人在他们的工作中，对快速实现的HOG变体
% in their work on discriminatively trained deformable part models.        进行了可变形零件模型有区别的训练
%  http://www.cs.berkeley.edu/~rbg/latent/index.html
% Gives nearly identical results to features.cc in code release version 5  在代码发布版本5中获得与features.cc几乎相同的结果，
% but runs 4x faster (over 125 fps on VGA color images).                   但运行速度提高了4倍（在VGA彩色图像上超过125 fps）
%
% The computed HOG features are 3*nOrients+5 dimensional. There are        计算的HOG特征是3 * nOrients + 5维。
% 2*nOrients contrast sensitive orientation channels, nOrients contrast    有2 * nOrients对比敏感定位通道，
% insensitive orientation channels, 4 texture channels and 1 all zeros     nOrients对比不敏感定向通道，
% channel (used as a 'truncation' feature). Using the standard value of    4个纹理通道和1个全零通道（用作'截断'功能）。
% nOrients=9 gives a 32 dimensional feature vector at each cell. This      使用nOrients的标准值= 9，给出每个单元的32维特征向量。
% variant of HOG, refered to as FHOG, has been shown to achieve superior   HOG的这种变体，被称为FHOG，已被证明可以实现优于原始HOG特征的性能。
% performance to the original HOG features. For details please refer to    详情请参阅Felzenszwalb等人的工作。
% work by Felzenszwalb et al. (see link above).
%
% This function is essentially a wrapper for calls to gradientMag()        这个函数本质上是调用gradientMag（）和gradientHist（）的包装器。
% and gradientHist(). Specifically, it is equivalent to the following:     具体而言，它相当于以下内容：
%  [M,O] = gradientMag( I,0,0,0,1 ); softBin = -1; useHog = 2;             [M，O] = gradientMag（I，0,0,0,1）; softBin = -1;useHog = 2;
%  H = gradientHist(M,O,binSize,nOrients,softBin,useHog,clip);             H = gradientHist（M，O，binSize，nOrients，softBin，useHog，clip）; 
% See gradientHist() for more general usage.                               有关更多常规用法，请参阅gradientHist（）。
%
% This code requires SSE2 to compile and run (most modern Intel and AMD    此代码要求SSE2编译和运行（大多数现代英特尔和AMD处理器支持SSE2）。
% processors support SSE2). Please see: http://en.wikipedia.org/wiki/SSE2.
%
% USAGE
%  H = fhog( I, [binSize], [nOrients], [clip], [crop] )
%
% INPUTS
%  I        - [hxw] color or grayscale input image (must have type single) 彩色或灰度输入图像（必须有单一的类型）
%  binSize  - [8] spatial bin size                                         空间仓大小
%  nOrients - [9] number of orientation bins                               定向箱的数量
%  clip     - [.2] value at which to clip histogram bins                   用于剪辑直方图箱的值
%  crop     - [0] if true crop boundaries                                  如果是真，作边界
%
% OUTPUTS
%  H        - [h/binSize w/binSize nOrients*3+5] computed hog features     计算的hog特征
%
% EXAMPLE
%  I=imResample(single(imread('peppers.png'))/255,[480 640]);
%  tic, for i=1:100, H=fhog(I,8,9); end; disp(100/toc) % >125 fps
%  figure(1); im(I); V=hogDraw(H,25,1); figure(2); im(V)
%
% EXAMPLE
%  % comparison to features.cc (requires DPM code release version 5)
%  I=imResample(single(imread('peppers.png'))/255,[480 640]); Id=double(I);
%  tic, for i=1:100, H1=features(Id,8); end; disp(100/toc)
%  tic, for i=1:100, H2=fhog(I,8,9,.2,1); end; disp(100/toc)
%  figure(1); montage2(H1); figure(2); montage2(H2);
%  D=abs(H1-H2); mean(D(:))
%
% See also hog, hogDraw, gradientHist
%
% Piotr's Image&Video Toolbox      Version 3.23
% Copyright 2013 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Simplified BSD License [see external/bsd.txt]

%Note: modified to be more self-contained

if( nargin<2 ), binSize=8; end
if( nargin<3 ), nOrients=9; end
if( nargin<4 ), clip=.2; end
if( nargin<5 ), crop=0; end

softBin = -1; useHog = 2; b = binSize;

[M,O]=gradientMex('gradientMag',I,0,1);

H = gradientMex('gradientHist',M,O,binSize,nOrients,softBin,useHog,clip);

if( crop ), e=mod(size(I),b)<b/2; H=H(2:end-e(1),2:end-e(2),:); end

end
