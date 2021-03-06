clear;

T=1;
Smax=200;
N=4000;
M=1000;
S0=40;

K=40;
r=0.06;
sigma=0.2;
q=0;

dt=T/N;
dS=Smax/M;

a = 0.5*dt*((r-q)*(0:M)-sigma^2*(0:M).^2);
b = 1 + dt*(sigma^2*(0:M).^2 + r);
c = -0.5*dt*(sigma^2*(0:M).^2 + (r-q).*(0:M));

V=zeros(M+1,N+1);
V(:,N+1) = max(K-(0:dS:Smax)',0);
V(1,:) = K;

tri= diag(a(3:M),-1) + diag(b(2:M)) + diag(c(2:M-1),1);
triinv=inv(tri);
B=zeros(M-1,1);
for i = N:-1:1
    B(1)=-a(2)*V(1,i);
V(2:M,i) = triinv*(V(2:M,i+1)+B) ;
V(:,i)=max(K-[0:dS:Smax]',V(:,i));
end

V(S0/dS+1,1)