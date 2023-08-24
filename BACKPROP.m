i = sqrt(-1)
tic;

%%%%%%%%%初期設定%%%%%%%%%

%条件%
save_file = true;
SIZE = 1024;
start_num = 1; 
end_num = 1;
Fs = 2000;
d = 85;
wsize = 1;

%保存場所%
folder = './source';
fname_prefix = '';
time = (start_num:end_num).*(1/Fs)

%%%%%%%%%中身の無い行列を作成%%%%%%%%%

phase1 = zeros(1,end_num-start_num+1);
phaseImg = zeros(SIZE, SIZE, end_num-start_num+1);
phaseHolo = zeros(1, end_num-start_num+1);

%%%%%%%%%進捗%%%%%%%%%

for v = 1:end_num - start_num + 1;
    if mod(v,1000) == 0;
        display(v);
    end;

%%%%%%%%%ホログラム画像読込%%%%%%%%%
%im2doubleを切り抜き前にするか後にするか%

fname1 = sprintf('%06d',v+start_num-1);
fname2 = strcat(folder1,strcat(fname_prefix,fname1));
Int_o = im2double(imread(fname2, 'tif'));
Int_c = imcrop(Int_o, []);
Int_r = imresize(Int_c,[1024 1024]);
figure(1);
imshow(Int_r,[]);

%%%%%%%%%干渉縞からグラフを出力%%%%%%%%%

SIZEX = SIZE
phaseHolo(1,v) = Int_r(SIZEX/2,SIZEX/2);

%%%%%%%%%ゼロパディング%%%%%%%%%

Int_pad = padarray(Int_r,[(SIZE-SIZEX)/2 (SIZE-SIZEX)/2]);

%%%%%%%%%物体光成分を抽出%%%%%%%%%

%フーリエ変換%
Int_fft = fft2(Int_pad);
Int_shift = fftshift(Int_fft);
figure(2);
imshow(log(abs(Int_shift)),[]);

%切り抜き%
f = zeros(SIZE)
f(centery-wsize1:centery+wsize1,centerx-wsize1:centerx+wsize1)=1;
Int_clip = Int_shift.*f;
Int_cshift = circshift(Int_1,[SIZEY/2+1-centery SIZEX/2+1-centerx]);
Int_1 = ifft2(ifftshift(Int_cshift));

%%%%%%%%%逆伝搬計算%%%%%%%%%

centerx = 512;
centery = 512;
dx = 1.00e-4;
wa = 532e-7;
Recon = nearpropCONV(Int_1,sizex,sizey,dx,dy,0,0,wa,d);
figure(3);
imshow(angle(Recon));

%%%%%%%%%1点の観察%%%%%%%%%
phase2(1,v) = angle(Recon(SIZE/2,SIZE/2));
phase3 = unwrap(phase2);








