tic
clear;
American_call_LS=[];
for q=1:1
S0 = 1;
K = 1;
T = 2;
r = 0.06;
sigma = 0.4;
L = 50; % number of time intervals
dt = T/L;
M = 10000; % number of asset paths


Y = zeros(M,L);
S = S0*ones(M,L+1); % asset paths
for k = 2:L+1
S(:,k)=S(:,k-1).*exp((r-0.5*sigma^2)*dt+sigma*sqrt(dt)*randn(M,1));
end

plot(S(1:100,:)')

% Find payoff Y at expiry.
for i=1:M
Y(i,L) = max(S(i,L+1)-K,0);
end

d1 = (log(S0/K) + (r + 0.5*sigma^2)*T)/(sigma*sqrt(T));
d2 = d1 - sigma*sqrt(T);
N1 = normcdf(d1);
N2 = normcdf(d2);
European_call_BS = S0*N1 - K*exp(-r*T)*N2;

European_call_LS(q)=exp(-r*dt*L)*mean(Y(:,L));

% Find payoff Y at nodes for each time index.
for k = L+1:-1:3
j = 0;
for i=1:M
if S(i,k-1) > K % in-the-money condition
j = j+1;
S1(j) = S(i,k-1); % in-the-money asset price
Y1(j) = exp(-r*dt)*Y(i,k-1); % discounted cash flow
end
end
p = polyfit(S1,Y1,3);
%F = @(var,x)var(1)+var(2)*x+var(3)*x.*x;
%F = @(var,x)var(1)+var(2)*exp(-x/2)+var(3)*exp(-x/2).*(1-x)+var(4)*exp(-x/2).*(1-2*x+0.5*x.*x);
%data0 = [1 1 1 1];
%opts=optimset('Display','off');
%[var] = lsqcurvefit(F,data0,S1.',Y1.',[],[],opts);

for i = 1:M
if S(i,k-1)-K > polyval(p,S(i,k-1)) % early exercise condition
%if K - S(i,k-1) > F(var,S(i,k-1))
Y(i,k-2) = max(S(i,k-1)-K,0);
else
Y(i,k-2) = exp(-r*dt)*Y(i,k-1);
end
end
end
American_call_LS(q) = exp(-r*dt)*mean(Y(:,1));
clearvars -except American_call_LS European_call_LS European_call_BS
end
[mean(American_call_LS),std(American_call_LS)]
[mean(European_call_LS),std(European_call_LS)]
European_call_BS
toc