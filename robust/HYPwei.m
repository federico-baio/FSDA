function w = HYPwei(u, cktuning)
%TBwei computes weight function psi(u)/u for hyperbolic tangent estimator
%
%<a href="matlab: docsearch('hypwei')">Link to the help function</a>
%
%
%
%  Required input arguments:
%
%    u :         n x 1 vector containing residuals or Mahalanobis distances
%                for the n units of the sample
%    cktuning :  vector of length 2 or of length 5 which specifies the value of the tuning
%                constant c (scalar greater than 0 which controls the
%                robustness/efficiency of the estimator)
%                and the prefixed value k (sup of the
%                change-of-variance sensitivity) and the values of
%                parameters A, B and d
%                cktuning(1) = c
%                cktuning(2) = k = supCVC(psi,x) x \in R
%                cktuning(3)=A;
%                cktuning(4)=B;
%                cktuning(5)=d;
%                Remark: if length(cktuning)==2 values of A, B and d will be
%                computed automatically
%
% Function HYPwei transforms vector u as follows
%
% HYPwei(u) = 	{ 1,			                               |u| <= d,
%               {
%		        { \sqrt(A * (k - 1)) * tanh(sqrt((k - 1) * B^2/A)*(c-|u|)/2) .* sign(u)/u
%		        { 	                 d <= |u| <  c,
%               {
%		        { 0,			                         |u| >= c.
%
%	It is necessary to have 0 < A < B < 2 *normcdf(c)-1- 2*c*normpdf(c) <1
%
%  Output:
%
%    w :         n x 1 vector contains the Tukey's biweight weights associated to the residuals or
%                Mahalanobis distances for the n units of the sample
%
%
% References:
%
%
% Frank R. Hampel, Peter J. Rousseeuw and Elvezio Ronchetti (1981),
% The Change-of-Variance Curve and Optimal Redescending M-Estimators,
% Journal of the American Statistical Association , Vol. 76, No. 375,
% pp. 643-648 (HRR)
%
% Copyright 2008-2011.
% Written by Marco Riani, Domenico Perrotta, Francesca Torti
%
%
%<a href="matlab: docsearch('hyppsi')">Link to the help page for this function</a>
% Last modified 15-Nov-2011
%
% Examples:
%
% Function HYPwei transforms vector u as follows

%
%
% Remark: Tukey's biweight  psi-function is almost linear around u = 0 in accordance with
% Winsor's principle that all distributions are normal in the middle.
% This means that  \psi (u)/u is approximately constant over the linear region of \psi,
% so the points in that region tend to get equal weight.
%
%
% References:
%
% ``Robust Statistics, Theory and Methods'' by Maronna, Martin and Yohai;
% Wiley 2006.
%
%
% Copyright 2008-2011.
% Written by Marco Riani, Domenico Perrotta, Francesca Torti
%
%
%<a href="matlab: docsearch('tbwei')">Link to the help page for this function</a>
% Last modified 15-Nov-2011
%
% Examples:

%{

    x=-6:0.01:6;
    ctuning=4;
    ktuning=4.5;
    weiHYP=HYPwei(x,[ctuning,ktuning]);
    plot(x,weiHYP)
    xlabel('x','Interpreter','Latex')
    ylabel('$W (x) =\psi(x)/x$','Interpreter','Latex')

%}


%% Beginning of code

c = cktuning(1);
k = cktuning(2);

if length(cktuning)>2
    
    A=cktuning(3);
    B=cktuning(4);
    d=cktuning(5);
    
    if ((A < 0) || (B < A) || (B>1)),
        error([' Illegal choice of parameters in hyperbolic tangent estimator: ' ...
            num2str(param) ]')
    else
    end
    
else
    % Find parameters A, B and d using routine HYPck
    [A,B,d]=HYPck(c,k);
    
    % For example if c=4 and k=5
    %     A = 0.857044;
    %     B = 0.911135;
    %     d =1.803134;
    % see Table 2 of HRR
end



w = zeros(size(u));
absu=abs(u);

%  u,		   |u| <=d
w(absu<=d) = 1;


%                d <= |u| < c,
% \sqrt(A * (k - 1)) * tanh(sqrt((k - 1) * B^2/A)*(c -|u|)/2) .* sign(u)
w(absu > d & absu <=c) = sqrt(A * (k - 1)) * tanh(sqrt((k - 1) * B^2/A)...
    *(c - absu(absu > d & absu <=c ))/2) .* sign(u(absu > d & absu <=c))./u(absu > d & absu <=c);

% 0,			              |u| >= c.

end