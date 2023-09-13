% フレームレートを指定
frameRate = 100;  % 例として30fpsを指定

% 動画ファイルの保存先とファイル名を指定
outputVideoFile = 'output_video.mp4';  % 出力動画ファイル名
outputVideoPath = 'D:\data\0912\source';  % 出力ディレクトリのパス

% 画像が格納されているディレクトリを指定
imageDir = 'D:\data\0912\source';  % 画像ディレクトリのパス
imageFileType = '.tif';  % 画像ファイルの拡張子

% ファイル名のパターンを指定
filePattern = '2k_0.12w_1024_10918_C001H001S0001*.tif';

% ファイル一覧を取得
imageFiles = dir(fullfile(imageDir, filePattern));
numFrames = numel(imageFiles);

% VideoWriterオブジェクトを作成
videoObj = VideoWriter(fullfile(outputVideoPath, outputVideoFile), 'MPEG-4');
videoObj.FrameRate = frameRate;

% ビデオファイルをオープン
open(videoObj);

% 進捗バーを初期化
h = waitbar(0, '処理中...');

% 画像から動画を作成
for frameIndex = 1:numFrames
    % 画像を読み込み
    img = imread(fullfile(imageDir, imageFiles(frameIndex).name));
    
    % 画像をグレースケールに変換
    grayImg = mat2gray(img);
    
    % 動画にフレームを書き込み
    writeVideo(videoObj, grayImg);
    
    % 進捗バーを更新
    progress = frameIndex / numFrames;
    waitbar(progress, h, sprintf('進捗: %.2f%%', progress * 100));
end

% 進捗バーを閉じる
close(h);

% ビデオファイルをクローズ
close(videoObj);

disp(['動画が保存されました: ' fullfile(outputVideoPath, outputVideoFile)]);