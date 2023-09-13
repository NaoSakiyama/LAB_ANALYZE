% 元の動画ファイルのパス
inputVideoPath = 'D:\data\0828\output_video_hot.mp4'; % 入力動画のパスを指定

% 速度倍率を設定
speedFactor = 2; % 速度倍率（例えば2なら元の速さの2倍）

% 元の動画を読み込む
inputVideo = VideoReader(inputVideoPath);

% 有効なファイル名を生成
validSpeedFactor = strrep(num2str(speedFactor), '.', '_'); % 速度倍率の小数点をアンダースコアに置換
outputVideoFileName = sprintf('output_video_%s.mp4', validSpeedFactor);

% 出力動画を作成する
outputVideoPath = fullfile(fileparts(inputVideoPath), outputVideoFileName); % 出力動画のパスを設定
outputVideo = VideoWriter(outputVideoPath, 'MPEG-4');
outputVideo.FrameRate = inputVideo.FrameRate * speedFactor; % 新しいフレームレートを設定
outputVideo.Quality = 100; % 品質を設定（通常は 0 から 100 の範囲で指定）
open(outputVideo);

% 進行状況表示
h = waitbar(0, 'Processing frames...');

while hasFrame(inputVideo)
    % フレームを読み込む
    frame = readFrame(inputVideo);
    
    % 一定間隔でフレームを保存することで再生速度を加速
    for i = 1:speedFactor
        if hasFrame(inputVideo)
            frame = readFrame(inputVideo); % フレームを読み込んでスキップ
            writeVideo(outputVideo, frame); % スキップしたフレームを保存
        end
    end
    
    % 進行状況を更新
    progress = inputVideo.CurrentTime / inputVideo.Duration;
    waitbar(progress, h, sprintf('Processing frames... %.2f%%', progress * 100));
end

% 進行状況を閉じる
close(h);

% 動画を閉じて保存
close(outputVideo);