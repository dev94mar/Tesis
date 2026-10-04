clear; clc
aqui = fileparts(mfilename('fullpath'));
addpath(fullfile(aqui, '..', 'inestable', 'PII_inestable'));
m=0.141; a=7.17184; b=1.6163e-6; c1=8.563; g=981; Fs=20; vth=0.02; T=1e-3;
S = load(fullfile(aqui, '..', 'inestable', 'PII_inestable', 'PII_lic.mat'));
Cpii = zpk(S.C); z = Cpii.Z{1}; p = Cpii.P{1}; k = Cpii.K;
bajos = [-4.875 -1.861];
i_bajos = arrayfun(@(zb) find(abs(z - zb) == min(abs(z - zb)), 1), bajos);
i_alto = setdiff(1:numel(z), i_bajos);
p_red = p(abs(p)>1e-9);
kK=1.0; al=2.2; be=1.05;
zz=z; zz(i_bajos)=z(i_bajos)*al; zz(i_alto)=z(i_alto)*be;
pp=p; pp(abs(p)>1e-9)=p_red*be;
Cz=zpk(zz,pp,k*kK);
disp(Cz)
[Ad,Bd,Cd,Dd] = ssdata(c2d(ss(Cz), T, 'zoh'));
n=size(Ad,1); ueq = m*g*b*(a+2)^4;
x0c = [Ad-eye(n); Cd] \ [zeros(n,1); ueq];
y0=[-2;0]; u=ueq; uzm=u; N=35000; yp=zeros(N,1); yv=yp; up=yp;
for kk=1:N
  [~,y]=ode45(@(t,y) maglev_karnopp(t,y,u), [0 T], y0); y0=y(end,:)';
  Fe=u/(b*max(a-y0(1),1e-6)^4)-m*g;
  if abs(y0(2))<vth && abs(Fe)<=Fs, y0(2)=0; end
  mov=y0(2)~=0; if mov, uzm=u; end
  e = -2 - ((kk-1)*T>=5) - y0(1);
  x0c = Ad*x0c + Bd*e;
  u = min(max(Cd*x0c+Dd*e,0),3.5);
  if mov && u<=uzm+0.025 && u>=uzm-0.02, u=uzm; end
  yp(kk)=y0(1); yv(kk)=y0(2); up(kk)=u;
end
tl=25001:35000; at=yv(tl)==0; ep=sum(at(2:end)&~at(1:end-1));
fprintf('y_final=%.6f error_final=%.6f ciclo=%.6f atasc=%.4f n_episodios=%d sat=%.4f\n', ...
  yp(end), -3-yp(end), max(yp(tl))-min(yp(tl)), sum(at)*T/max(ep,1), ep, sum(up>=3.5-1e-4)/N);
