close all;
% 現在の日時を取得
currentDateTime = datestr(now, 'yyyymmdd_HHMMSS');

i = sqrt(-1);
tic;

%%%%%%%%%%% ここで設定します %%%%%%%%%%%
%長さ単位はmにそろえる%
save_file = true;
SIZE = 1024;    % 画像のサイズ
start_num = 4000;  % 処理を開始する画像の番号
end_num = 6800; % 処理を終了する画像の番号
Fs = 7200; % カメラのフレームレート(枚/s)
wsize1 = 1;  % 切り抜きサイズの設定 0だと1x1 1だと3x3 2だと5x5...
folder1 = 'D:\data\0828\source\';  % フォルダ指定
fname_prefix = '2k_0.17w_27000_512_C001H001S0001'; % ファイル名の頭から後ろ6桁と拡張子を抜いたもの
seconds = (start_num:end_num) * (1/Fs); % 時間
sizex = SIZE;
sizey = SIZE;

%%% 経路ごとの切り抜き中心点と伝搬距離、出力ファイル名の決定 %%%
% 計算する経路のみコメントアウトを外して実行する。
for numPath = 2:2
    switch numPath
        case 1
            % numPathが1の場合の処理
        case 2
            centerx = 534; % 38  *128/96; % 経路2
            centery = 507;
            d = 0.7;
            pathName = '2_';
            % numPathが2の場合の処理
        case 3
            % numPathが3の場合の処理
        otherwise
            error("Invalid numPath value");
    end

    %%%%%%%%%%%% 設定はここまで %%%%%%%%%%%%
    
    %バッチ処理
    batch_size =1200; % バッチのサイズ
    num_batches = ceil((end_num - start_num + 1) / batch_size);
    all_phase1 = cell(1, num_batches);
    total_processing_time = 0; % 合計処理時間の初期化
    % プログレスバーの作成
    %h = waitbar(0, 'Processing...', 'Name', 'Overall Progress');
    parfor batch = 1:num_batches
        batch_start = start_num + (batch - 1) * batch_size;
        batch_end = min(start_num + batch * batch_size - 1, end_num);
        % phase1_batch を一時的な変数にコピー
        tmp_phase1_batch = zeros(1, batch_end - batch_start + 1);
        %h_local = waitbar(0, sprintf('Batch %d/%d Processing...', batch, num_batches));
        %h = waitbar(0, sprintf('Processing batch %d/%d...', batch, num_batches));
        % 以下の部分を各 v ごとに並列処理
        %%%%%ホログラム画像読み込み%%%%%
        batch_start_time = tic;
        for v = batch_start:batch_end
           fname1 = sprintf('%06d',v); %ファイル名最後の6桁と拡張子を作成
           fname2 = strcat(folder1,strcat(fname_prefix,fname1));  %ファイル名作成
           Int_1 = im2double(imread(fname2,'tif')); %読み込み
           Int_1 = imadjust(Int_1);
           Int_1 = imcrop(Int_1,[91.5 158.5 83 81]);
           Int_1 = imresize(Int_1,[1024 1024]);
           %figure(1);
           %imshow(Int_1,[]);
        
           SIZEX = SIZE;
           SIZEY = SIZE;
        
           % ホログラム　干渉縞からグラフを出力
           %phaseHolo(1,v) = Int_1(SIZEX/2,SIZEY/2);
        
           % ｾﾞﾛﾊﾟﾃﾞｨﾝｸﾞ
           Int_1 = padarray(Int_1,[(SIZE-SIZEX)/2 (SIZE-SIZEY)/2],0,"both");
           
           %%%%%%読み込んだホログラムから物体光成分を抽出%%%%%%
           Int_1 = fft2(Int_1);
           Int_1 = fftshift(Int_1); 
           %figure(2);   %物体光
           %imshow(log(abs(Int_1)),[]);
        
           %切り抜き用窓の作成
           f=zeros(SIZE);
           SIZEX = SIZE;
           SIZEY = SIZE;
           f(centery-wsize1:centery+wsize1,centerx-wsize1:centerx+wsize1)=1;  %切り抜き用窓の作成
           Int_1 = Int_1.*f;  %切り抜き
           Int_1 = circshift(Int_1,[SIZEY/2+1-centery SIZEX/2+1-centerx]);  %切り抜き画像を中心に移動
           Int_1 = ifft2(ifftshift(Int_1));
           %Int_1 = fftshift(Int_1); %これで撮影面での物体光が取り出せた
           %imshow(log(abs(Int_1)),[]);
    
            % 逆伝播計算
            sizex = SIZE;
            sizey = SIZE;
            dx = 1e-4; % カメラの画素サイズ
            dy = 1e-4;
            wa = 532e-9; % レーザーの波長
            Recon = nearpropCONV(Int_1, sizex, sizey, dx, dy, 0, 0, wa, d);
            %Recon = Int_1;
            %figure(234)   %再構成波面
            %imshow(angle(Recon));
       
            % 逆伝播計算後の画像から1点の位相を取り出す
            tmp_phase1_batch(v-batch_start+1) = angle(Recon(SIZE/2, SIZE/2));
            % 進行状況を更新してプログレスバーを表示
            %completion = (v - batch_start + 1) / (batch_end - batch_start + 1);
            %waitbar(completion, h, sprintf('Processing batch %d/%d... %.2f%%', batch, num_batches, completion * 100));
        end

        tmp_phase1_batch = unwrap(tmp_phase1_batch);
        all_phase1{batch} = tmp_phase1_batch; % バッチごとの結果を保存
        %close(h_local);
    end
    phase1 = cat(2, all_phase1{:});
    phase1 = unwrap(phase1);  % 位相アンラップ(-πとπの間で飛ばないようにする)
    % グローバルプログレスバーの進捗を更新
    %global_completion = batch / num_batches;
    %waitbar(global_completion, h, sprintf('Overall Progress: %.2f%%', global_completion * 100));
end
%close(h);

if save_file
    %%%%%測定した生データをcsvに出力%%%%%
    % ファイル名に日時を結合して新しいファイル名を生成
    ws = wsize1*2+1;
    fname5 = strcat(folder1,pathName,sprintf('%dx%d_',ws,ws),'Time_rshift_B.csv');
    fname55 = strcat(fname5(1:end-4), '_', currentDateTime, '.csv');
    rphase=[seconds;phase1];
    csvwrite(fname55,rphase');
    figure(1121);
    title('PhaseShift(raw)');
    xlabel('Time [s]');
    ylabel('Phase');
    figure(1121);
    plot(seconds,phase1)
    title("Time-Phase(RAW)")
    savefig(strcat(sprintf("%d_%dx%d",numPath,ws,ws),"_rawdata_B"));

    %%%%%ノイズ除去のため、近くの点を取って平均化%%%%%
    phase2=zeros(1,end_num-start_num+1);
    phase3=zeros(1,end_num-start_num);
    for v=1:end_num-start_num-10
       phase2(1,v)=phase1(1,v)-mean(phase1(1,v:v+10));
    end
    for v=1:end_num-start_num-10
        if v <= 10
            phase2(1,v)=phase1(1,v)-mean(phase1(1,1:v+10));
        else
            phase2(1,v)=phase1(1,v)-mean(phase1(1,v-10:v+10));
        end
    end
    for v=1:end_num-start_num
        phase3(1,v) = phase2(1,v+1)-phase2(1,v);
    end

    %%%%%平均化したデータをcsvに出力%%%%%
    fname3 = strcat(folder1,pathName,sprintf('%dx%d_',ws,ws),'Time_Aphase_B.csv');
    fname33 = strcat(fname3(1:end-4), '_', currentDateTime, '.csv');
    aphase=[seconds;phase2];
    csvwrite(fname33,aphase');
    figure(1122);
    plot(seconds,phase2)
    title('Time-Phase(AVE.)');
    xlabel('Time [s]');
    ylabel('Phase');
    savefig(strcat(sprintf("%d_%dx%d",numPath,ws,ws),"_avedata_B"));

  
    %%%%%音声ファイル出力のためのノーマライズ%%%%%
    %max1 = max(phase2(1,:));
    %min1 = min(phase2(1,:)); 
    %phase4 = 2.0*(phase2-min1)/(max1-min1) - 1.00;

    %%%%%音声ファイル出力%%%%%
    %fname4 = strcat(folder1,pathName,sprintf('%dx%d_',ws,ws),'output.wav');
    %audiowrite(fname4,phase4,Fs);

    %figure(4);  %音声データをプロット
    %plot(phase4,'r');
end

% スペクトル解析
num1 = 1;
num2 = end_num - start_num + 1;

%生データ
phase11 = phase1(num1:num2);
phase111 = fftshift(log(abs(fft(phase11))));
n1 = num2-num1+1;
f0_1 = (-n1/2:n1/2-1).*(Fs/n1);
figure(11);
plot(f0_1,phase111);
title("raw data");
xlabel('Frequency [Hz]');
ylabel('Spectral intensity []');
savefig("spectral_raw_B");
fname6 = strcat(folder1,pathName,sprintf('%dx%d_',ws,ws),'Time_rfreq_B.csv');
fname66 = strcat(fname6(1:end-4), '_', currentDateTime, '.csv');
rfreq=[f0_1;phase111];
csvwrite(fname66,rfreq');

%平均化後
phase12 = phase2(num1:num2);
phase112 = fftshift(log(abs(fft(phase12))));
n1 = num2-num1+1;
f0_1 = (-n1/2:n1/2-1).*(Fs/n1);
figure(12);
plot(f0_1,phase112);
title("average data");
xlabel('Frequency [Hz]');
ylabel('Spectral intensity []');
savefig("spectral_ave_B");
fname7 = strcat(folder1,pathName,sprintf('%dx%d_',ws,ws),'Time_Afreq_B.csv');
fname77 = strcat(fname7(1:end-4), '_', currentDateTime, '.csv');
nfreq=[f0_1;phase112];
csvwrite(fname77,nfreq');

toc;