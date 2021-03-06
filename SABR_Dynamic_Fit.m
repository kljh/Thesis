clear;


A = importdata('Data_BNPP.txt','\t',1);
B1=A.data(:,:);

r1 = 0.06;%%if edited, the data must be changed!
S01=17099.4;
matur1=4;
M1=100;
iterations=5;
Mplot=100;
beta=1;

B1(:,2)=B1(:,2)/S01;
S01=1;
B1(:,1)=B1(:,1)/252;
times1=unique(B1(:,1));
B1=B1(B1(:,1)<=times1(matur1),:);


P1=B1;
for i=1:size(B1,1)
    P1(i,3)=european_bs(S01,B1(i,2),r1,B1(i,3),B1(i,1),"call");
    %european_bs(S0,K,r,sigma0,T,putcall)
end


fun=@(var)SABRcal(var(1),var(2),var(3),beta,S01,B1,r1,var(4),var(5));
%SABRcal(alpha,rho,nu,beta,S0,B,r)
lb = [0,-1,0,0,0];
ub = [Inf,1,Inf,Inf,Inf];
x0=[0.3,-0.5,0.1,0.10,0.1];
% fun=@(var)SABRcal(var(1),var(2),var(3),var(4),S01,B1,r1);
% lb = [0,-1,0,0];
% ub = [Inf,1,Inf,1];
% x0=[0.5,0.5,0.5,0.5];

A = [];b = [];Aeq = [];beq = [];nonlcon=[];
%options = optimoptions('patternsearch','Display','off','MaxIter',10000,'UseParallel',true);
%vars=patternsearch(fun,x0,A,b,Aeq,beq,lb,ub,nonlcon,options);
options = optimoptions('simulannealbnd','Display','off');
vars=simulannealbnd(fun,x0,lb,ub,options);

%options = optimoptions('fmincon','Display','off','FinDiffRelStep',[0.01,0.01,0.01,0.01,0.01]);
%vars=fmincon(fun,x0,A,b,Aeq,beq,lb,ub,nonlcon,options);
disp(vars);
error=SABRcal(vars(1),vars(2),vars(3),beta,S01,B1,r1,vars(4),vars(5));
% error=SABRcal(vars(1),vars(2),vars(3),var(4),S01,B1,r1);
% beta=var(4);
disp(strcat("      error=",num2str(error)));

alpha=vars(1);
rho=vars(2);
nu=vars(3);
a=vars(4);
b=vars(5);


figure
for iter=1:matur1
    ax(iter) = subplot(2,ceil(matur1/2),iter);
    ti=times1(iter);
    
    C=B1(B1(:,1)==ti,2:3);
    
    
    SABRVol=@(K)sigmaSABR(alpha,rho,nu,beta,K,S01*exp(r1*ti),ti,a,b);
    
    scatter(ax(iter),C(:,1),C(:,2),'.');
    hold on;
    fplot(ax(iter),SABRVol,[min(C(:,1)) max(C(:,1))])
    hold on;
    title(ax(iter),times1(iter)*252)
end


function Error=SABRcal(alpha,rho,nu,beta,S0,B,r,a,b)
LS=0;
for i=1:size(B,1)
    LS=LS+(B(i,3)-sigmaSABR(alpha,rho,nu,beta,B(i,2),S0*exp(r*B(i,1)),B(i,1),a,b))^2;
end
Error=LS;
end



function sigma=sigmaSABR(alpha,rho,nu,beta,K,f,T,a,b)
w=alpha^(-1)*f^(1-beta);
n1=@(T)2*nu*rho/(T^2*(a+b)^2)*(exp(-(a+b)*T)-(1-(a+b)*T));
n22=@(T)3*nu^2*rho^2/(T^4*(a+b)^4)*(exp(-2*(a+b)*T)-8*exp(-(a+b)*T)+(7+2*(a+b)*T*(-3+(a+b)*T)));
v12=@(T)6*nu^2/(2*b*T)^3*(((2*b*T)^2/2-2*b*T+1)-exp(-2*b*T));
v22=@(T)6*nu^2/(2*b*T)^3*(2*(exp(-2*b*T)-1)+2*b*T*(exp(-2*b*T)+1));
%rhot=@(t)rho*exp(-a*t);
%nut=@(t)nu*exp(-b*t);

A1=@(T)(beta-1)/2+n1(T)*w/2;
A2=@(T)(1-beta)^2/12+(1-beta-n1(T)*w)/4+(4*v12(T)+3*(n22(T)-3*(n1(T))^2))*w^2/24;
B=@(T)1/w^2*((1-beta)^2/24+w*beta*n1(T)/4+(2*v22(T)-3*n22(T))*w^2/24);

sigma=1/w*(1+A1(T)*log(K./f)+A2(T)*(log(K./f)).^2+B(T)*T);
end


function Euro_final=Pricer(alpha,rho,nu,beta,K,f,r,T,L,M,iterations,PriceVol)
dt = T/L;
parfor iter=1:iterations
    F = f*ones(M,1);
    alp=alpha*ones(M,1);
    
    for k = 1:L
        Z1=randn(M,1);
        alp(:)=alp(:).*exp(nu*sqrt(dt)*Z1-nu^2*dt/2);
        v=alp.*(F.^(beta-1));
        F(:)=F(:).*exp(v.*(rho*Z1+sqrt(1-rho^2)*randn(M,1))*sqrt(dt)-v.^2*dt/2);
        
    end
    
    Y=zeros(M,1);
    for i=1:M
        Y(i) = max(F(i)-K,0);
    end
    
    
    if PriceVol=="price"
        Euro(iter)=exp(-r*T)*mean(Y(:));
    else
        euro=@(sigma)european_bs(f*exp(-r*T),K,r,sigma,T,"call")-exp(-r*T)*mean(Y(:));
        Euro(iter)=fzero(euro,0.25);
    end
    
end

Euro_final=mean(Euro);
end


function Plotter(alpha,rho,nu,beta,f,r,T,L,M,ax)
dt = T/L;
F = f*ones(M,L);
alp=alpha*ones(M,1);

for k = 1:L
    Z1=randn(M,1);
    alp(:)=alp(:).*exp(nu*sqrt(dt)*Z1-nu^2*dt/2);
    v=alp.*(F(:,k).^(beta-1));
    F(:,k+1)=F(:,k).*exp(v.*(rho*Z1+sqrt(1-rho)*randn(M,1))*sqrt(dt)-v.^2*dt/2);
end

for k = 1:(L+1)
    F(:,k)=F(:,k).*exp(-r*(T-dt*(k-1)));
end

plot(ax,0:dt*252:T*252,F(:,:)')
xlim([0 T*252])
ylim([0 2])

end

function euro=european_bs(S0,K,r,sigma0,T,putcall)
d1 = (log(S0/K) + (r + 0.5*sigma0^2)*T)/(sigma0*sqrt(T));
d2 = d1 - sigma0*sqrt(T);
N1 = normcdf(d1);
N2 = normcdf(d2);
if putcall=="call"
    euro = S0*N1 - K*exp(-r*T)*N2;
elseif putcall=="put"
    euro = S0*N1 - K*exp(-r*T)*N2 + K*exp(-r*T) - S0;
end
end