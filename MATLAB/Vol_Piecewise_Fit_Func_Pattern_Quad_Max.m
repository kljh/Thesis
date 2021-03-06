clear;

S01=167.65;
r1 = 0.06;

A = importdata('AAPL.txt','\t',1);
B1=A.data(:,:);

times1=unique(B1(:,1));
matur1=4;
a1=zeros(matur1,1);
b1=zeros(matur1,1);
c1=ones(matur1,1);
sigmamax1=0.8;

M1 = 5000; % number of asset paths
iterations1=100;




B1=B1(B1(:,1)<=28,:);

%a1(1)=0.1963;b1(1)=17.9684;c1(1)=182.9531;
for iter=1:matur1
tic
T1 = times1(iter)/252;
D1=252;
L1 = T1*D1*2;

fun = @(var)Localvol(var(1),var(2),var(3),iter,S01,r1,T1,D1,M1,L1,B1,a1,b1,c1,sigmamax1,iterations1);

A = [];b = [];Aeq = [];beq = [];nonlcon=[];
lb = [0.15,0.00001,175];
ub = [0.25,0.001,200];
x0=[0.2-0.005*iter, 0.0001/(iter), 170+5*iter];

options = optimoptions('patternsearch','Display','off','MaxIter',10000,'UseParallel',true);
%options = optimset('MaxFunEvals',100000,'MaxIter',100000,'Display','off');
vars=patternsearch(fun,x0,A,b,Aeq,beq,lb,ub,nonlcon,options);
disp(vars);
a1(iter)=vars(1);
b1(iter)=vars(2);
c1(iter)=vars(3);

format shortg;
c = clock;
disp(strcat(num2str(toc),strcat("   ",strcat(num2str(c(4)),strcat(":",num2str(c(5)))))))
fprintf('_______________________________________\n\n\n')
end


sigma0=0.2;
iterations2=10;
figure

for iter=1:matur1
ax(iter) = subplot(2,matur1/2,iter);
ti=times1(iter);
C=B1(B1(:,1)==ti,2:3);

T1 = times1(iter)/252;
D1=252;
L1 = T1*D1*2;

for i=1:size(C,1)
Euro(i)=Pricer(a1,b1,c1,sigmamax1,S01,r1,T1,D1,M1,L1,B1,C(i,1),iterations2);
end

for i=1:size(C,1)
Euro_Const(i)=Pricer_Const(sigma0,S01,r1,T1,M1,L1,C(i,1),iterations2);
end


scatter(ax(iter),C(:,1),C(:,2));
hold on;
scatter(ax(iter),C(:,1),Euro(:));
hold on;
scatter(ax(iter),C(:,1),Euro_Const(:));
title(ax(iter),times1(iter)) 
clear Euro Euro_Const
end

beep


%{
for i=1:size(C,1)
euro=@(sigma)european_bs(S01,C(i,1),r1,sigma,ti/252,'call')-C(i,2);
C(i,2)=fzero(euro,0.5);
end
scatter(C(:,1),C(:,2));
hold on;
F = @(var,x)var(1)+var(2)*((x-var(3))/var(3)).^2;
data0 = [vars(1) vars(2) vars(3)];
opts=optimset('Display','off');
[var] = lsqcurvefit(F,data0,C(:,1),C(:,2),[0.1 0.1 165],[0.35 100 200],opts);
vol=@(x)var(1)+var(2)*((x-var(3))/var(3)).^2;
fplot(vol, [150 185]);
hold on;
vol2=@(x)vars(1)+vars(2)*((x-vars(3))/vars(3)).^2;
fplot(vol2, [150 185]);
%}


function Error_final=Localvol(at,bt,ct,matur,S0,r,T,D,M,L,B,a,b,c,sigmamax,iterations)

dt = T/L;
Error=zeros(iterations,1);
times=unique(B(:,1));

a(matur)=at;
b(matur)=bt;
c(matur)=ct;

for iter=1:iterations
S = S0*ones(M,1); % asset paths
sigma=a(1)*ones(M,1);

for k = 2:L+1
S(:)=S(:)+S(:)*r*dt+sqrt(dt)*sigma(:).*S(:).*randn(M,1);

for i=1:size(times,1)
if dt*D*(k-1)<=times(i)
   %sigma=arrayfun(@(x) min(a(i)+b(i)*min(x,0)^2,sigmamax),(S(:,k)-c(i))/c(i));
   sigma=arrayfun(@(x) min(a(i)+b(i)*(min(x-c(i),0))^2,sigmamax),(S(:)));
   %sigma=arrayfun(@(x) a(i)+b(i)*x^2,(S(:,k)-c(i))/c(i));
   break;
end
end
end
   
   C=B(B(:,1)==T*D,2:3);
   Y=zeros(M,size(C,1));
   for j=1:size(C,1)
       for i=1:M
           Y(i,j) = max(S(i)-C(j,1),0);
       end
   end
   Error(iter)=abs(sum(exp(-r*T)*mean(Y)-C(:,2)'));
   clear Y;

end
Error_final=mean(Error);
end




function Euro_final=Pricer(a,b,c,sigmamax,S0,r,T,D,M,L,B,K,iterations)
dt = T/L;
times=unique(B(:,1));

for iter=1:iterations
S = S0*ones(M,1); % asset paths
sigma=a(1)*ones(M,1);

for k = 2:L+1
S(:)=S(:)+S(:)*r*dt+sqrt(dt)*sigma(:).*S(:).*randn(M,1);

for i=1:size(times,1)
if dt*D*(k-1)<=times(i)
   %sigma=arrayfun(@(x) min(a(i)+b(i)*min(x,0)^2,sigmamax),(S(:,k)-c(i))/c(i));
   sigma=arrayfun(@(x) min(a(i)+b(i)*(min(x-c(i),0))^2,sigmamax),(S(:)));
   %sigma=arrayfun(@(x) a(i)+b(i)*x^2,(S(:,k)-c(i))/c(i));
   break;
end
end

end

for i=1:M
Y(i) = max(S(i)-K,0);
end

Euro_Vol(iter)=exp(-r*T)*mean(Y(:));
end

Euro_final=mean(Euro_Vol);
end


function Euro_final_Const=Pricer_Const(sigma,S0,r,T,M,L,K,iterations)
dt = T/L;

for iter=1:iterations
S = S0*ones(M,L+1); % asset paths

for k = 2:L+1
S(:,k)=S(:,k-1)+S(:,k-1)*r*dt+sqrt(dt)*sigma.*S(:,k-1).*randn(M,1);

end

for i=1:M
Y(i) = max(S(i,L+1)-K,0);
end

Euro_Vol(iter)=exp(-r*dt*L)*mean(Y(:));
end

Euro_final_Const=mean(Euro_Vol);
end


function euro=european_bs(S0,K,r,sigma0,T,putcall)
d1 = (log(S0/K) + (r + 0.5*sigma0^2)*T)/(sigma0*sqrt(T));
d2 = d1 - sigma0*sqrt(T);
N1 = normcdf(d1);
N2 = normcdf(d2);
if putcall=='call'
    euro = S0*N1 - K*exp(-r*T)*N2;
elseif putcall=='put'
    euro = S0*N1 - K*exp(-r*T)*N2 + K*exp(-r*T) - S0;
end
end