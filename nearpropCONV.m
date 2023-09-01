function Recon=nearpropCONV(Comp1,sizex,sizey,dx,dy,shiftx,shifty,wa,d)

wa;
x1 = -sizex/2;
x2 = sizex/2-1;
y1 = -sizey/2;;
y2 = sizey/2-1;
M = sizex;
N = sizey;
%[m,n]=meshgrid(x1:x2,y1:y2);
%FresR=(exp(i*2*pi/wa*d)*exp(-i*pi*wa*d*((m/(M*dx)).^2+(n/(N*dy)).^2)));
[Fx,Fy]=meshgrid(x1:1:x2,y1:1:y2);

Dincline = exp(2.0*pi*i*(Fx*dx*dx*shiftx+Fy*dy*dy*shifty)/(wa*d));

%size(Dincline)
%figure(40);

Comp1 = Comp1.*Dincline;

Fcomp1 = fftshift(fft2(Comp1))/sqrt(sizex*sizey);

FresR=exp(-i*pi*wa*d*((Fx.^2)/((dx*sizex)^2)+(Fy.^2)/((dy*sizey)^2)));
  
Fcomp2 = Fcomp1.*FresR;
Recon = ifft2(fftshift(Fcomp2))*sqrt(sizex*sizey);
% k = 2*pi/wa;
% expTerm = exp(i*k*d)/(i*wa*d);
% Recon = expTerm * Recon;


%figure(count);
%imshow(abs(Recon),[]);
end