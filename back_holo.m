% オフアクシスホログラフィーによる干渉縞画像解析コード

% 1. 対象の画像フォルダを指定
image_folder = 'D:\data\0828\output_images_gray\output_image_';

% 2. 画像処理のパラメータ設定
start_num = 4000;          % 開始番号
end_num = 27000;          % 終了番号
Fs = 7200;                % フレームレート (枚/s)
SIZE = 1024;            % 画像サイズ% 切り抜いた干渉縞画像のフーリエ変換と輝点の切り抜き位置の指定
holo_fft = fftshift(fft2(holo_cropped));
figure;
imshow(log(abs(holo_fft)), []);
title('FFT of Cropped Interference Fringe Image');
fprintf('Click on the center of the bright spot in the FFT.\n');
center = round(ginput(1)); % ユーザが輝点の中心位置を指定
wsize = 20; % 切り抜くサイズ
holo_fft_cropped = holo_fft(center(2)-wsize:center(2)+wsize, center(1)-wsize:center(1)+wsize);
dx = 1e-4;              % カメラの画素サイズ (メートル)
lambda = 532e-9;        % レーザーの波長 (メートル)
d = 0.7;               % 逆伝搬距離 (メートル)
wsize = 1;             % フーリエ像の切り抜きサイズ

% 初期化
phase_data_raw = zeros(1, end_num - start_num + 1);
phase_data_unwrapped = zeros(1, end_num - start_num + 1);
intensity_freq_data = zeros(SIZE, end_num - start_num + 1);

% メインループ
for num = start_num:end_num
    fprintf('Processing image %d/%d...\n', num, end_num);
    
    % 画像読み込み
    image_filename = sprintf('%s%06d.tif', image_folder, num);
    holo_image = imread(image_filename);
    
    % 干渉縞画像の表示と切り抜き
    crop_height = round(rect(4));figure;
    imshow(Int_1, []);
    title('Interference Fringe Image');
    fprintf('Click on the upper-left and lower-right corners of the region to crop.\n');
    rect = getrect; % ユーザが切り抜く領域を指定
    crop_x = round(rect(1));
    crop_y = round(rect(2));
    crop_width = round(rect(3));
    holo_cropped = Int_1(crop_y:crop_y+crop_height-1, crop_x:crop_x+crop_width-1);

    % 切り抜いた干渉縞画像のフーリエ変換と輝点の切り抜き位置の指定
    holo_fft = fftshift(fft2(holo_cropped));
    figure;
    imshow(log(abs(holo_fft)), []);
    title('FFT of Cropped Interference Fringe Image');
    fprintf('Click on the center of the bright spot in the FFT.\n');
    center = round(ginput(1)); % ユーザが輝点の中心位置を指定
    wsize = 20; % 切り抜くサイズ
    holo_fft_cropped = holo_fft(center(2)-wsize:center(2)+wsize, center(1)-wsize:center(1)+wsize);

    % 干渉縞画像のFFT
    holo_fft = fftshift(fft2(holo_image));
    
    % フーリエ像の切り抜き
    center = [SIZE/2, SIZE/2];
    holo_fft_cropped = holo_fft(center(1)-wsize:center(1)+wsize, center(2)-wsize:center(2)+wsize);
    
    % 物体光の輝点の位置を抜き出し
    object_light = holo_fft_cropped(wsize+1, wsize+1);
    
    % 位相の計算
    phase = angle(object_light);
    phase_data_raw(num - start_num + 1) = phase;
    
    % 逆伝搬計算
    recon = ifft2(ifftshift(exp(1i * phase) * exp(1i * (k * d))));
    unwrapped_phase = unwrap(angle(recon(wsize+1, wsize+1)));
    phase_data_unwrapped(num - start_num + 1) = unwrapped_phase;
    
    % 周波数特性の計算
    intensity_freq_data(:, num - start_num + 1) = abs(holo_fft_cropped(:));
end

% データ出力
csvwrite('phase_data_raw.csv', phase_data_raw);
csvwrite('phase_data_unwrapped.csv', phase_data_unwrapped);
csvwrite('intensity_freq_data.csv', intensity_freq_data);

% プロットと保存
figure;
subplot(2, 1, 1);
plot(start_num:end_num, phase_data_raw);
title('Raw Phase Data');
xlabel('Image Number');
ylabel('Phase');
subplot(2, 1, 2);
plot(start_num:end_num, phase_data_unwrapped);
title('Unwrapped Phase Data');
xlabel('Image Number');
ylabel('Phase');
savefig('phase_plots.fig');

% 平均化した強度の周波数特性を計算
mean_intensity_freq_data = mean(intensity_freq_data, 2);

% 周波数特性データ出力
csvwrite('mean_intensity_freq_data.csv', mean_intensity_freq_data);

% プロットと保存
figure;
plot((1:SIZE)-SIZE/2, mean_intensity_freq_data);
title('Mean Intensity Frequency Data');
xlabel('Frequency Index');
ylabel('Intensity');
savefig('mean_intensity_freq_plot.fig');