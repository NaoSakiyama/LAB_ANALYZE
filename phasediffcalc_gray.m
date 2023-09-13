% フォルダ内の画像ファイルのパスを取得
imageFolderPath = 'D:\data\0912\source'; % 画像フォルダのパスを指定
imageFiles = dir(fullfile(imageFolderPath, '*.tif')); % 拡張子に合わせて変更

% 画像ファイル名から下六桁の連番を取得
imageNumbers = zeros(1, length(imageFiles));
for i = 1:length(imageFiles)
    [~, fileName, ~] = fileparts(imageFiles(i).name);
    imageNumbers(i) = str2double(fileName(end-5:end));
end

% 基準画像のインデックスと差分計算範囲を指定
referenceImageIndex = 1; % 基準となる画像のインデックスを指定
startImageIndex = 2;     % 位相変化量の計算を始める画像のインデックスを指定
endImageIndex = 10918;       % 位相変化量の計算を終わる画像のインデックスを指定

% 基準画像を読み込む
referenceImage = imread(fullfile(imageFolderPath, imageFiles(referenceImageIndex).name));

% 保存先のディレクトリを作成
outputFolderPath = fullfile(fileparts(imageFolderPath), 'output_images_gray');
if ~exist(outputFolderPath, 'dir')
    mkdir(outputFolderPath);
end

% 進行状況表示
h = waitbar(0, 'Processing images...');

% 動画の設定
outputVideoPath = fullfile(fileparts(imageFolderPath), 'output_video_gray.mp4'); % 出力動画のパスを指定
outputVideo = VideoWriter(outputVideoPath, 'MPEG-4');
outputVideo.Quality = 100; % 品質を設定（通常は 0 から 100 の範囲で指定）
outputVideo.FrameRate = 100; % フレームレートを設定
open(outputVideo);

for i = startImageIndex:endImageIndex
    % 画像を読み込む
    currentImage = imread(fullfile(imageFolderPath, imageFiles(i).name));
    
    % 基準画像との差分を計算
    phaseDifference = double(currentImage) - double(referenceImage);

    % グレースケールに変換
    grayImage = mat2gray(phaseDifference, [-1, 1]);
    
    % 画像を保存
    outputImageFileName = sprintf('output_image_%06d.tif', imageNumbers(i));
    outputImagePath = fullfile(outputFolderPath, outputImageFileName);
    imwrite(im2uint8(grayImage), outputImagePath);
    
    % 動画にフレームを書き込む
    writeVideo(outputVideo, grayImage);
    
    % 進行状況を更新
    progress = (i - startImageIndex + 1) / (endImageIndex - startImageIndex + 1);
    waitbar(progress, h, sprintf('Processing images... %.2f%%', progress * 100));
end

% 進行状況を閉じる
close(h);

% 動画を閉じて保存
close(outputVideo);