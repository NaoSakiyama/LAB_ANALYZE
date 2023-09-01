close all

i=sqrt(-1);
tic;

%%%%%%%%%%%ここで設定します%%%%%%%%%%%
save_file = true;
SIZE = 1024;    %画像のサイズ
start_num = 4000;  %処理を開始する画像の番号
end_num = 4200; %処理を終了する画像の番号
Fs = 7200; %カメラのフレームレート(枚/s)
wsize1 = 1;  %切り抜きサイズの設定 0だと1x1 1だと3x3 2だと5x5...
folder1 = 'D:\data\0828\output_images_gray\';  %フォルダ指定
fname_prefix = 'output_image_'; %ファイル名の頭から後ろ6桁と拡張子を抜いたもの
seconds = (start_num:end_num).*(1/Fs); %時間

%%%経路ごとの切り抜き中心点と伝搬距離、出力ファイル名の決定%%%
%計算する経路のみコメントアウトを外して実行する。
for numPath = 2:2
  if numPath == 1
  elseif numPath == 2
     centerx = 534; %38  *128/96; %経路2
     centery = 507;
     d = 700;
     pathName = '2_'; 
  elseif numPath == 3
  else 
    display("error");
  end 

   %%%%%%%%%%%%設定はここまで%%%%%%%%%%%%
   phase1=zeros(start_num,end_num-start_num+1);
   phaseImg=zeros(SIZE,SIZE,end_num-start_num+1);

   phaseHolo = zeros(1,end_num-start_num+1);
   
  h = waitbar(0, 'Processing...');
  for v = 1:end_num - start_num + 1  % parfor 共有PCでのみ可能
   
   %%%%%ホログラム画像読み込み%%%%%
   fname1 = sprintf('%06d',v+start_num-1); %ファイル名最後の6桁と拡張子を作成
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
   phaseHolo(1,v) = Int_1(SIZEX/2,SIZEY/2);

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


   %%%%%逆伝播計算%%%%%
   sizex = SIZE;
   sizey = SIZE;
   dx=1e-4; % カメラの画素サイズ
   dy=1e-4;
   wa=532e-9; % レーザーの波長
   Recon = nearpropCONV(Int_1,sizex,sizey,dx,dy,0,0,wa,d);  % 逆伝搬計算(別ファイルの関数)
   Recon = Int_1;
    %figure(234)   %再構成波面
    %imshow(angle(Recon));
   
   %%%%%逆伝播計算後の画像から1点の位相を取り出す%%%%%
   phase1(1,v) = angle(Recon(SIZE/2,SIZE/2));
   
   % 進行状況の更新
   completion = v / (end_num - start_num + 1);
   waitbar(completion, h, sprintf('Processing... %d%%', round(completion * 100)));
  end

  phase1=unwrap(phase1);  %位相アンラップ(-πとπの間で飛ばないようにする)
  
  if save_file

    %%%%%測定した生データをcsvに出力%%%%%
    ws = wsize1*2+1;
    fname5 = strcat(folder1,pathName,sprintf('%dx%d_',ws,ws),'Time_rshift.csv');
    rphase=[seconds;phase1];
    csvwrite(fname5,rphase');
    figure(1121);
    title('PhaseShift(raw)');
    xlabel('Time [s]');
    ylabel('Phase');
    figure(1121);
    plot(seconds,phase1)
    title("Time-Phase(RAW)")
    savefig(strcat(sprintf("%d_%dx%d",numPath,ws,ws),"_rawdata"));

    %%%%%ノイズ除去のため、近くの点を取って平均化%%%%%
    phase2=zeros(start_num,end_num-start_num+1);
    phase3=zeros(start_num,end_num-start_num);
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
    fname3 = strcat(folder1,pathName,sprintf('%dx%d_',ws,ws),'Time_aphase.csv');
    aphase=[seconds;phase2];
    csvwrite(fname3,aphase');
    figure(1122);
    plot(seconds,phase2)
    title('Time-Phase(AVE.)');
    xlabel('Time [s]');
    ylabel('Phase');
    savefig(strcat(sprintf("%d_%dx%d",numPath,ws,ws),"_avedata"));

  
    %%%%%音声ファイル出力のためのノーマライズ%%%%%
    max1 = max(phase2(1,:));
    min1 = min(phase2(1,:)); 
    phase4 = 2.0*(phase2-min1)/(max1-min1) - 1.00;

    %%%%%音声ファイル出力%%%%%
    fname4 = strcat(folder1,pathName,sprintf('%dx%d_',ws,ws),'output.wav');
    audiowrite(fname4,phase4,Fs);

    %figure(4);  %音声データをプロット
    %plot(phase4,'r');
  end
end
toc;

close(h);  % プログレスバーを閉じる
disp('Processing complete.');

% スペクトル解析
num1 = start_num;
num2 = end_num;

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
savefig("spectral_raw");
fname6 = strcat(folder1,pathName,sprintf('%dx%d_',ws,ws),'Time_rfreq.csv');
rfreq=[f0_1;phase111];
csvwrite(fname6,rfreq');

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
savefig("spectral_ave");
fname7 = strcat(folder1,pathName,sprintf('%dx%d_',ws,ws),'Time_nfreq.csv');
nfreq=[f0_1;phase112];
csvwrite(fname7,nfreq');

% 経過の様子を表示
disp('Processing complete.');

% グラフのウィンドウを閉じるために待機
pause(2);
close(gcf);





