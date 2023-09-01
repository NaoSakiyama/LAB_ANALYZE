% フォルダ内の画像ファイルのパスを取得
imageFolderPath = 'D:\data\0828\source'; % 画像フォルダのパスを指定
imageFiles = dir(fullfile(imageFolderPath, '*.tif')); % 拡張子に合わせて変更

% 画像ファイル名から下六桁の連番を取得
imageNumbers = zeros(1, length(imageFiles));
for i = 1:length(imageFiles)
    [~, fileName, ~] = fileparts(imageFiles(i).name);
    imageNumbers(i) = str2double(fileName(end-5:end));
end

% 画像ファイル名から下六桁の連番を取得
imageNumbers = zeros(1, length(imageFiles));
for i = 1:length(imageFiles)
    [~, fileName, ~] = fileparts(imageFiles(i).name);
    imageNumbers(i) = str2double(fileName(end-5:end));
end

% 基準画像のインデックスと差分計算範囲を指定
referenceImageIndex = 3000; % 基準となる画像のインデックスを指定
startImageIndex = 4000;     % 位相変化量を計算を始める画像のインデックスを指定
endImageIndex = 27000;       % 位相変化量を計算を終わる画像のインデックスを指定

% 基準画像を読み込む
referenceImage = imread(fullfile(imageFolderPath, imageFiles(referenceImageIndex).name));

% 位相変化量を計算して動画として保存
outputVideoPath = fullfile(fileparts(imageFolderPath), 'output_video_2.mp4'); % 出力動画のパスを指定
outputVideo = VideoWriter(outputVideoPath, 'MPEG-4');
outputVideo.Quality = 100; % 品質を設定（通常は 0 から 100 の範囲で指定）
outputVideo.FrameRate = 100; % フレームレートを設定
open(outputVideo);

% 進行状況表示
h = waitbar(0, 'Processing images...');

for i = startImageIndex:endImageIndex
    % 画像を読み込む
    currentImage = imread(fullfile(imageFolderPath, imageFiles(i).name));
    
    % 基準画像との差分を計算
    phaseDifference = double(currentImage) - double(referenceImage);

    % Hotカラーマップを適用
    hotImage = ind2rgb(im2uint8(mat2gray(phaseDifference, [-1, 1])), hot(256));
    
    % フレームを作成し、動画に書き込む
    frame = im2frame(hotImage);
    outputVideo.writeVideo(frame);

    % 進行状況を更新
    progress = (i - startImageIndex + 1) / (endImageIndex - startImageIndex + 1);
    waitbar(progress, h, sprintf('Processing images... %.2f%%', progress * 100));
end

% 進行状況を閉じる
close(h);

% 動画を閉じて保存
outputVideo.close();