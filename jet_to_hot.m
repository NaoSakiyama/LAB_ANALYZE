% Jetカラーマップで保存した動画ファイルのパス
jetVideoPath = 'D:\data\0828\output_video.mp4'; % 保存したJetカラーマップの動画ファイルのパスを指定

% Hotカラーマップで保存する動画ファイル名
hotVideoFileName = 'hot_video.mp4'; % Hotカラーマップで保存する動画ファイル名を指定

% Hotカラーマップを適用して動画を保存する
jetVideo = VideoReader(jetVideoPath);
hotVideoPath = fullfile(fileparts(jetVideoPath), hotVideoFileName); % Hotカラーマップで保存する動画のパスを設定
hotVideo = VideoWriter(hotVideoPath, 'MPEG-4');
hotVideo.FrameRate = jetVideo.FrameRate;
open(hotVideo);

totalFrames = floor(jetVideo.Duration * jetVideo.FrameRate);
h = waitbar(0, 'Processing frames...');

frameIndex = 0; % フレームのインデックスを初期化

while hasFrame(jetVideo)
    frameIndex = frameIndex + 1; % フレームのインデックスを更新
    jetFrame = readFrame(jetVideo);
    
    % JetカラーマップからHotカラーマップに変換
    grayFrame = rgb2gray(jetFrame); % Jetカラーマップのフレームをグレースケールに変換
    hotFrame = ind2rgb(im2uint8(mat2gray(grayFrame)), hot(256)); % Hotカラーマップを適用
    
    % Hotカラーマップで保存する動画にフレームを書き込む
    writeVideo(hotVideo, hotFrame);
    
    % 進行状況を更新
    progress = frameIndex / totalFrames;
    waitbar(progress, h, sprintf('Processing frames... %.2f%%', progress * 100));
end

close(h);
close(hotVideo);
