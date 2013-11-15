function out=MMregcore(y,X,b0,auxscale,varargin)
%MMregcore computes MM regression estimators for a selected fixed scale.
% It does iterative reweighted least squares (IRWLS) steps from "initial
% beta" (b0) keeping the estimate of the scale (auxscale) fixed.
%
%<a href="matlab: docsearch('MMregcore')">Link to the help function</a>
%
%  Required input arguments:
%
%    y :        A vector with n elements that contains the response variable.
%    X :        Data matrix of explanatory variables (also called 'regressors')
%               of dimension (n x p). Rows of X represent observations, and
%               columns represent variables. 
%    b0:        Vector containing initial estimate of beta (generally an S
%               estimate with high breakdown point (eg .5)
% auxscale:     scalar containing estimate of the scale (generally an S
%               estimate with high breakdown point (eg .5)
%
%  Optional input arguments:
%
%   intercept : If 1, a model with constant term will be fitted (default),
%               if 0, no constant term will be included.
%       eff  :  scalar. Nominal efficiency. Default is set to 0.95.
%               Default efficiency is set to 0.95 (which
%               corresponds to c=4.68 in case of location efficiency or to
%               5.49 in case of shape efficiency)
%    effshape:  dummy scalar. If effshape=1 efficiency refers to shape
%               efficiency else (default) efficiency refers to location
%    refsteps:  scalar defining maximum number of (refining steps) 
%               literations in the MM loop (default value is 100)
%      reftol:  scalar controlling tolerance in the MM loop.
%               Default is 1e-7.
%     conflev:  Scalar between 0 and 1 containing the confidence level
%               used to declare units as outliers. Usually conflev = 0.95,
%               0.975, 0.99 (individual alpha) or 1-0.05/n, 1-0.025/n,
%               1-0.01/n (simultaneous alpha). Default value is 0.975.
%     rhofunc : String which specifies the rho function which must be used to
%               weight the residuals. Possible values are
%               'bisquare'
%               'optimal'
%               'hyperbolic'
%               'hampel'
%               'bisquare' uses Tukey's \rho and \psi functions.
%               See TBrho and TBpsi
%               'optimal' uses optimal \rho and \psi functions.
%               See OPTrho and OPTpsi
%               'hyperbolic' uses hyperbolic \rho and \psi functions.
%               See HYPrho and HYPpsi
%               'hampel' uses Hampel \rho and \psi functions.
%               See HArho and HApsi
%               The default is bisquare
% rhofuncparam: scalar or vector which contains the additional parameters
%               for the specified rho function.
%               For hyperbolic rho function it is possible to set up the
%               value of k = sup CVC (the default value of k is 4.5)
%               For Hampel rho function it is possible to define parameters
%               a, b and c (the default values are a=2, b=4, c=8)%      nocheck: Scalar. If nocheck is equal to 1 no check is performed on
%               matrix y and matrix X. Notice that y and X are left
%               unchanged. In other words the additional column of ones for
%               the intercept is not added. As default nocheck=0.
%       plots : Scalar or structure.
%               If plots = 1, generates a plot of scaled residuals against
%               index number. The confidence level used to draw the
%               confidence bands for the scaled residuals is given by the
%               input option conflev. If conflev is not specified a nominal
%               0.975 confidence interval will be used.
%       yxsave : scalar that is set to 1 to request that the response 
%                vector y and data matrix X are saved into the output
%                structure out. Default is 0, i.e. no saving is done.
%
%  Output:
%
%  The output is a structure 'out' containing the following fields:
%
%     out.beta  : p x 1 vector. Estimate of beta coefficients after 
%                 refsteps refining steps
%  out.residuals: n x 1 vector containing the estimates of the robust
%                 scaled residuals
%   out.outliers: A vector containing the list of the units declared as
%                 outliers using confidence level specified in input
%                 scalar conflev
%   out.conflev:  Confidence level that was used to declare outliers
%   out.weights:  n x 1 vector. Weights assigned to each observation
%     out.class:  'MM'
%     out.y    : response vector y. The field is present if option 
%                yxsave is set to 1.
%     out.X    : data matrix X. The field is present if option 
%                yxsave is set to 1.
%
%
% References:
%
% ``Robust Statistics, Theory and Methods'' by Maronna, Martin and Yohai;
% Wiley 2006.
%
% Acknowledgements
%
% This function follows the lines of MATLAB/R code developed during the
% years by many authors.
% For more details see http://www.econ.kuleuven.be/public/NDBAE06/programs/
% and the R library robustbase http://robustbase.r-forge.r-project.org/
% The core of these routines, e.g. the resampling approach, however, has
% been completely redesigned, with considerable increase of the
% computational performance.
%
% Copyright 2008-2011.
% Written by Marco Riani, Domenico Perrotta, Francesca Torti
%
%
%<a href="matlab: docsearch('mmregcore')">Link to the help page for this function</a>
% Last modified 15-Nov-2011
%
% Examples:
%
%{
    % Determine, e.g., an S estimate and extract the required arguments for the MM estimate.
    n=200;
    p=3;
    state1=123456;
    randn('state', state1);
    X=randn(n,p);
    y=randn(n,1);
    kk=10;
    ycont = y;
    ycont(1:kk)=ycont(1:kk)+7;
    [outS]=Sreg(ycont,X);
    outMM=MMregcore(ycont,X,outS.beta,outS.scale,'plots',1)
%}

%{
    % Determine, e.g., an S estimate and extract the required arguments for the MM estimate.
    % This time use a Tukey biweight for S estimation and HA rho function
    % for MM loop 
    n=200;
    p=3;
    state1=123456;
    randn('state', state1);
    X=randn(n,p);
    y=randn(n,1);
    kk=10;
    ycont = y;
    ycont(1:kk)=ycont(1:kk)+7;
    [outS]=Sreg(ycont,X);
    rhofunc='hampel';
    outMM1=MMregcore(ycont,X,outS.beta,outS.scale,'rhofunc',rhofunc,'plots',1)
%}

%% Beginning of code

nnargin = nargin;
vvarargin = varargin;
[y,X,n] = chkinputR(y,X,nnargin,vvarargin);

% default nominal efficiency
effdef = 0.95;
% by default the nominal efficiency refers to location efficiency
effshapedef = 0;
% default value of number of maximum refining iterations
refstepsdef = 50;
% default value of tolerance for the refining steps convergence
reftoldef = 1e-6;
% rho (psi) function which has to be used to weight the residuals
rhofuncdef='bisquare';

% store default values in the structure options
options=struct('refsteps',refstepsdef,'reftol',reftoldef,...
    'eff',effdef,'effshape',effshapedef,'conflev',0.975,...
    'rhofunc',rhofuncdef,'rhofuncparam','',...
    'plots',0,'nocheck',0,'yxsave',0);

% check user options and update structure options
UserOptions=varargin(1:2:length(varargin));
if ~isempty(UserOptions)
    % Check if number of supplied options is valid
    if length(varargin) ~= 2*length(UserOptions)
        error('Error:: number of supplied options is invalid. Probably values for some parameters are missing.');
    end
    % Check if user options are valid options
    chkoptions(options,UserOptions)
end

% Write in structure 'options' the options chosen by the user
if nargin > 2
    for i=1:2:length(varargin);
        options.(varargin{i})=varargin{i+1};
    end
end

eff     = options.eff;      % nominal efficiency
effshape= options.effshape; % nominal efficiency refers to shape or location
refsteps= options.refsteps; % maximum refining iterations
reftol  = options.reftol;   % tolerance for refining iterations covergence
rhofunc = options.rhofunc;    % String which specifies the function to use to weight the residuals

psifunc=struct;

if strcmp(rhofunc,'bisquare')
    
% TODO TODO TODO TODO TODO effshape is only implemented for TB 
    % Compute tuning constant associated to the requested nominal efficiency
    % c = consistency factor for a given value of efficiency
if effshape==1
    c=TBeff(eff,1,1);
else
    c=TBeff(eff,1);
end
    
    psifunc.c=c;
    psifunc.class='TB';
    
elseif strcmp(rhofunc,'optimal')
    
    
    % Compute tuning constant associated to the requested nominal efficiency
    % c2 = consistency factor for a given value of efficiency
    % Remark: given that in function OPTeff rho function is defined in the interval 0---2c/3, 2c/3---3c/3, >3c/3
    % it is necessary to divide the output of OPTeff by 3
    c=OPTeff(eff,1)/3;
    
    psifunc.c=c;
    psifunc.class='OPT';
    
elseif strcmp(rhofunc,'hyperbolic')
    
    if isempty(options.rhofuncparam)
        kdef=4.5;
    else
        kdef=options.rhofuncparam;
    end
    rhofuncparam=kdef;
    
    
    if kdef == 4 && eff==0.85;
        c2 =3.212800979614258;
        A2 =0.570183575755717;
        B2 =0.696172437281084;
        d2 =1.205900263786317;
    elseif kdef == 4.5 && eff==0.85;
        c2 =3.032387733459473;
        A2 =0.615717108822885;
        B2 = 0.723435958485131;
        d2 =1.321987605094910;
    elseif kdef == 5 && eff==0.85;
        c2 =2.911890029907227;
        A2 =0.650228046997054;
        B2 =0.743433840145084;
        d2 =1.419320821762087;
        
    elseif kdef == 4 && eff==0.95;
        c2 =4.331634521484375;
        A2 =0.754327484845243;
        B2 =0.846528826589308;
        d2 =1.480099129676819;
    elseif kdef == 4.5 && eff==0.95;
        c2 =3.866390228271484;
        A2 =0.791281464739131;
        B2 =0.867016329355630;
        d2 =1.610621500015260;
    elseif kdef == 5 && eff==0.95;
        c2 =3.629499435424805;
        A2 =0.818876452066880;
        B2 =0.882004888111327;
        d2 =1.723768949508668;
        
    else
        
        % Compute tuning constant associated to the requested nominal efficiency
        % c2 = consistency factor for a given value of efficiency
        [c2,A2,B2,d2]=HYPeff(eff,1,kdef);
    end
    
    
    psifunc.c=[c2,kdef,A2,B2,d2];
    psifunc.class='HYP';
    
    c=psifunc.c;
    
elseif strcmp(rhofunc,'hampel')
    
    if isempty(options.rhofuncparam)
        abc=[2,4,8];
    else
        abc=options.rhofuncparam;
    end
    rhofuncparam=abc;
    
    
    % Compute tuning constant associated to the requested nominal efficiency
    % c2 = consistency factor for a given value of efficiency
    c=HAeff(eff,1,abc);
    
    psifunc.c=[c,abc];
    psifunc.class='HA';
    
    c=psifunc.c;
    
else
    error('Specified rho function is not supported: possible values are ''bisquare'' , ''optimal'',  ''hyperbolic'', ''hampel''')
    
end


XXwei=strcat(psifunc.class,'wei');
hwei=str2func(XXwei);


epsf = eps;
iter=0;crit=Inf;b1=b0;
while (iter <= refsteps) && (crit > reftol)
    r1=(y-X*b1)/auxscale;
    tmp = find(abs(r1) <= epsf);
    n1 = size(tmp,1);
    if n1 ~= 0
        r1(tmp) = epsf;
    end
    
    % w is the weight vector \psi(x)/x Each observations receives a
    % weight. Units associated to outliers tend to have 0 weight
    
    % OLD INSTRUCTION
    % w=TBwei(r1,c);
    
    % Compute weights for prespecified rho function
    w=feval(hwei,r1,c);
    
    % Every column of matrix X and vector y is multiplied by the sqrt root of the n x 1
    % weight vector w, then weighted regression is performed
    w1=sqrt(w);
    Xw=bsxfun(@times,X,w1);
    Yw=y.*w1;
    % b2 = inv(X'W*X)*X'W*y where W=w*ones(1,k)
    b2=Xw\Yw;
    % disp([b2-b22])
    
    d=b2-b1;
    crit=max(abs(d));
    iter=iter+1;
    b1=b2;
end

out.class = 'MM';
out.beta = b2;
out.weights = w;
out.residuals = (y-X*out.beta)/auxscale;

% Store in output structure the outliers found with confidence level conflev
% which has been usedto declared the outliers
conflev = options.conflev;
seq = 1:n;
out.outliers = seq(abs(out.residuals) > sqrt(chi2inv(conflev,1)) );
out.conflev = conflev;

out.rhofunc=rhofunc;
% In case of Hampel or hyperbolic tangent estimator store the additional
% parameters which have been used
% For Hampel store a vector of length 3 containing parameters a, b and c
% For hyperbolic store the value of k= sup CVC
if exist('rhofuncparam','var')
    out.rhofuncparam=rhofuncparam;
end

% Store X (without the column of ones if there is an intercept)
if options.yxsave
    intcolumn = find(max(X,[],1)-min(X,[],1) == 0);
    if intcolumn==1;
        X(:,intcolumn)=[];
        % Store X (without the column of ones if there is an intercept)
        out.X=X;
    else
        out.X=X;
    end
    % Store response
    out.y=y;
end


% Plot of residual with outliers highlighted
if options.plots==1;
    laby='Robust MM residuals';
    resindexplot(out.residuals,'conflev',out.conflev,'laby',laby,'numlab',out.outliers);
end

end





