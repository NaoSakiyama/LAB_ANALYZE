close all

i=sqrt(-1);
tic;

%%%%%%%%%%%ここで設定します%%%%%%%%%%%
save_file = true;
SIZE = 1024;    %画像のサイズ
start_num = 4000;  %処理を開始する画像の番号
end_num = 5200; %処理を終了する画像の番号
% end_num = 1;
Fs = 7200; %カメラのフレームレート(枚/s)
wsize1 = 1;  %切り抜きサイズの設定 0だと1x1 1だと3x3 2だと5x5...
folder1 = 'D:\data\0828\source\';  %フォルダ指定
fname_prefix = '2k_0.17w_27000_512_C001H001S0001'; %ファイル名の頭から後ろ6桁と拡張子を抜いたもの
seconds = (start_num:end_num).*(1/Fs); %時間

%%%経路ごとの切り抜き中心点と伝搬距離、出力ファイル名の決定%%%
%計算する経路のみコメントアウトを外して実行する。
for numPath = 2:2
  if numPath == 1
    %経路1%
  %  centerx = SIZE-35+2;  %figure(2)での光る点。経路ごとに位置が異なる
  %  centery = SIZE-140+2;
  %  d = 588; %伝搬距離(mm)
  %  pathName = '1_';
  elseif numPath == 2
    %経路2%
     centerx = 534; %38  *128/96; %経路2
     centery = 507;
     d = 700;
     pathName = '2_'; 
  elseif numPath == 3
    %経路3%
   %  centerx = 137; %経路3
   %  centery = 96;
   %  d = 1075;
   %  pathName = '3_'; 
  else 
    display("error");
  end 
  %%%%%%%%%%%%設定はここまで%%%%%%%%%%%%
    phase1=zeros(1,end_num-start_num+1);
    phaseImg=zeros(SIZE,SIZE,end_num-start_num+1);

    phaseHolo = zeros(1,end_num-start_num+1);

  for v = 1:end_num - start_num + 1  % parfor 共有PCでのみ可能

    %%%%%進捗状況表示%%%%%
   if mod(v,1000) == 0
       display(v)
   end
   
   
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
   dx=0.02; % カメラの画素サイズ
   dy=0.02;
   wa=532e-6; % レーザーの波長
   Recon = nearpropCONV(Int_1,sizex,sizey,dx,dy,0,0,wa,d);  % 逆伝搬計算(別ファイルの関数)
   Recon = Int_1;
   %figure(234)   %再構成波面
   %imshow(angle(Recon));
   
   %%%%%逆伝播計算後の画像から1点の位相を取り出す%%%%%
   phase1(1,v) = angle(Recon(SIZE/2,SIZE/2));
%    phaseImg(:,:,v) = angle(Recon);
   %%%unwrapImg(:,:,v) = unwrap_phase(angle(Recon));
  end
%   phaseImgAll(:,:,:,numPath)=phaseImg;

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
    %phaseImg = phaseImg(21:320,21:320,:);
%    phaseImg_a = reshape(phaseImg,[SIZE,SIZE*(end_num-start_num+1)]);
%     csvwrite(strcat(folder1,pathName,sprintf('%dx%d_',ws,ws),'phaseImg.csv'),phaseImg_a);
    %%unwrapImg = reshape(unwrapImg,[SIZE,SIZE*(end_num-start_num+1)]);
    %%csvwrite(strcat(folder1,pathName,sprintf('%dx%d_',ws,ws),'unwrapped.csv'),unwrapImg);

    %%%%%ノイズ除去のため、近くの点を取って平均化%%%%%
    phase2=zeros(1,end_num-start_num+1);
    phase3=zeros(1,end_num-start_num);
    for v=1:end_num-start_num-10
       phase2(1,v)=phase1(1,v)-mean(phase1(1,v:v+10));
    end
    for v=end_num-start_num-9:end_num-start_num+1
       phase2(1,v)=phase1(1,v)-mean(phase1(1,v-10:v));
    end

    for v=1:end_num-start_num
        phase3(1,v) = phase2(1,v+1)-phase2(1,v);
    end

    %%%%%平均化したデータをcsvに出力%%%%%
    fname3 = strcat(folder1,pathName,sprintf('%dx%d_',ws,ws),'Time_Aphase.csv');
    aphase=[seconds;phase2];
    csvwrite(fname3,aphase');
    figure(1122);
    plot(seconds,phase2)
    title('Time-Phase(AVE.)');
    xlabel('Time [s]');
    ylabel('Phase');
    savefig(strcat(sprintf("%d_%dx%d",numPath,ws,ws),"_avedata"));

    %スペクトル解析
    %phase7 = highpass(phase2,1600,Fs);
    %phase7 = lowpass(phase2,1800,Fs);
    %figure(1123)
    %plot(phase7,'r')
    %savefig(strcat(sprintf("highpass_filtered_%d_%dx%d",numPath,ws,ws)));
  
    %%%%%音声ファイル出力のためのノーマライズ%%%%%
    max1 = max(phase2(1,:));
    min1 = min(phase2(1,:)); 
    phase4 = 2.0*(phase2-min1)/(max1-min1) - 1.00;

    %%%%%音声ファイル出力%%%%%
    fname4 = strcat(folder1,pathName,sprintf('%dx%d_',ws,ws),'output.wav');
    audiowrite(fname4,phase4,Fs);

%     figure(4);  %音声データをプロット
%     plot(phase4,'r');

%{
    figure(5)   %音声データのスペクトログラムをプロット
    specgram(phase4,256,Fs);
    colormap(jet);
    colorbar();
    savefig(strcat(num2str(numPath),"_specgram"));

    figure(6)
    plot(phaseHolo);
    title(num2str(start_num) + "～" + num2str(end_num) + " Hologram");
    savefig("Holo_plot");
%}
  end

  %{
phase11 = phase2(num1:num2);
phase111 = fftshift(abs(fft(phase11)));
n1 = num2-num1+1;
f0_1 = (-n1/2:n1/2-1).*(Fs/n1);
figure(11);
plot(f0_1,phase111);
xlabel('Frequency [Hz]');
ylabel('Spectral intensity []');
savefig(strcat(sprintf("%d_%dx%d",numPath,ws,ws),"_spectral"));
  %}
end
toc;

% スペクトル解析
num1 = 1;
num2 = end_num - start_num  + 1;

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
fname7 = strcat(folder1,pathName,sprintf('%dx%d_',ws,ws),'Time_Afreq.csv');
nfreq=[f0_1;phase112];
csvwrite(fname7,nfreq');

%干渉縞
%phase13 = phaseHolo(num1:num2);
%phase113 = fftshift(log(abs(fft(phase13))));
%n1 = num2-num1+1;
%f0_1 = (-n1/2:n1/2-1).*(Fs/n1);
%figure(13);
%plot(f0_1,phase113);
%title("fringes");
%xlabel('Frequency [Hz]');
%ylabel('Spectral intensity []');
%savefig("spectral_fringes");


%}
