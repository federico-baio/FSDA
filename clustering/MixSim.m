function [out]  = MixSim(k,v,varargin)
%MixSim generates k clusters in v dimensions with given overlap
%
%<a href="matlab: docsearch('MixSim')">Link to the help function</a>
%
%   MixSim(k,p) generates k groups in v dimensions. It is possible to
%   control the maximum and average overlapping.
%
%  Background: Given two generic clusters i and j = i ne j =1, ..., k,
%  indexed by \phi(x,\mu_i,\Sigma_i) and \phi(x,\mu_j,\Sigma_j) with
%  probabilities of occurrence \pi_i and \pi_j the misclassification
%  probability with respect to cluster i (which is called w_j|i) is defined as
%  Pr[ \pi_i \phi(x,\mu_i,\Sigma_i) < \pi_j \phi(x,\mu_j,\Sigma_j)].
%  The matrix containing the misclassification probabilities w_j|i is
%  called OmegaMap
%  The probability of overlapping between groups i and j is given by 
%            w_j|i + w_i|j          i,j=1,2, ..., k
%  The diagonal elements of OmegaMap are equal to 1.
%  The average overlap (which in the code is called below BarOmega) is
%  defined as the sum of the off diagonal elements of OmegaMap (matrix of
%  misclassification probabilities) divided by 0.5*k*(k-1)
%  The maximum overlap (which in the code is called MaxOmega) is defined as
%  max( w_j|i + w_i|j)  i \ne j=1,2, ..., k
%  The probability of overlapping w_j|i is nothing but the cdf of a linear
%  combination of non central chi^2 distributions with 1 degree of freedom
%  + a linear combination of N(0,1) evaluated in a
%  point c.  The coefficients of the linear combinations of non central
%  chi^2 and N(0,1) depend on the eigenvalues and eigenvectors of matrix
%  \Sigma_j|i = \Sigma^{0.5}_i \Sigma^{-1}_j \Sigma^{0.5}_i. 
%  Point c depends on the same eigenvalues and eigenvectors
%  of matrix \Sigma_j|i the mixing proportions \pi_i and \pi_j and the
%  determinants |\Sigma_i| and |\Sigma_j|
%  This probability is computed using routine ncx2mixtcdf
%
%  Required input arguments:
%
%            k: scalar, number of groups (components)
%            v: scalar, number of dimensions (variables).
%
%  Optional input arguments:
%
%    BarOmega : scalar, value of desired average overlap. The default value is ''
%    MaxOmega : scalar, value of desired maximum overlap. If BarOmega is empty
%               the default value of MaxOmega is 0.15
%               Remark: The overlap between two clusters i and j is defined
%               as the sum of the two misclassification probability w_{j|i}
%               and w_{i|j}
%         sph : scalar boolean which specifies covariance matrix structure
%               sph=false (default) ==> non-spherical,
%               sph=true            ==> spherical
%         hom : scalar boolean which specifies heterogeneous or homogeneous
%               clusters
%               hom=false (default) ==> heterogeneous,
%               hom=true            ==> homogeneous
%         ecc : scalar in the interval (0, 1] which defines maximum eccentricity.
%               For example, if ecc=0.9 (default value), we require for
%               each group that sqrt(1 - minL / maxL) <= 0.9 where minL and
%               maxL are respectively the min and max eigenvalue of the cov
%               matrix of a particular group
%  restrfactor: TODO      TODO
%       PiLow : value of the smallest mixing proportion (if 'PiLow' is not
%               reachable with respect to k, equal proportions are taken;
%               PiLow = 1.0 implies equal proportions by default). PiLow
%               must be a number in the interval (0 1]
%         int : mean vectors are simulated uniformly on a hypercube with
%               sides specified by int = (lower.bound, upper.bound).
%               The default value of int is [0 1]
%        resN : maximum number of mixture resimulations to find a
%               similation setting with prespecified level of overlapping.
%               The default value of resN is 100
%         tol : error bound for overlap computation default is 1e-06
%         lim : maximum number of integration terms default is 1e06.
%               REMARK: Optional parameters tol and lim will be used by
%               function ncx2mixtcdf.m which computes the cdf of a linear
%               combination of non central chi2 r.v.. This is the
%               probability of overlapping
%      R_seed : scalar > 0 for the seed to be used to generate random numbers
%               in a R instance. This is used to check consistency of the
%               results obtained with the R package MixSim.
%               This option requires the installation of the R-(D)COM Interface.
%               Default is 0, i.e. random numbers are generated by matlab.
%
%       Remark: The user should only give the input arguments that have to
%               change their default value. The name of the input arguments
%               needs to be followed by their value. The order of the input
%               arguments is of no importance.
%       Remark: If 'BarOmega' is not specified, the function generates a
%               mixture solely based on 'MaxOmega'; if 'MaxOmega' is not
%               specified, the function generates a mixture solely based on
%               'BarOmega'. If both BarOmega and MaxOmega are not specified
%               the function generates a mixture using MaxOmega=0.15.
%               If both BarOmega and MaxOmega are empty values as follows
%               out=MixSim(3,4,'MaxOmega','','BarOmega','')
%               the following message appears on the screen
%               Error: At least one overlap characteristic should be specified...
%
%  Output:
%
%  The output consists of a structure 'out' containing the following fields:
%
%            out.Pi  : vector of length k containing mixing proportions
%            out.Mu  : k-by-v matrix consisting of components' mean vectors
%                      Each row of this matrix is a centroid of a group
%             out.S  : v-by-v-by-k array containing covariances for the k
%                      groups
%       out.OmegaMap : matrix of misclassification probabilities (k-by-k);
%                      OmegaMap(i,j) = w_{j|i} is the probability that X
%                      coming from the i-th component (group) is classified
%                      to the j-th component.
%       out.BarOmega : scalar. Value of average overlap.
%       out.MaxOmega : scalar. Value of maximum overlap.
%         out.rcMax  : vector of length 2. It containes the row and column
%                      numbers for the pair of components producing maximum
%                      overlap 'MaxOmega'
%              fail  : scalar, flag value. 0 represents successful mixture
%                      generation, 1 represents failure.
%
% See also tkmeans, tclust, tclustreg, lga, rlga, ncx2mixtcdf
%
% References:
%
%   Maitra, R. and Melnykov, V. (2010) �Simulating data to study performance
%   of finite mixture modeling and clustering algorithms�, The Journal of
%   Computational and Graphical Statistics, 2:19, 354-376.
%
%   Melnykov, V., Chen, W.-C., and Maitra, R. (2012) �MixSim: An R Package
%   for Simulating Data to Study Performance of Clustering Algorithms�,
%   Journal of Statistical Software, 51:12, 1-25.
%
%   Davies, R. (1980) �The distribution of a linear combination of
%   chi-square random variables�, Applied Statistics, 29, 323-333.
%
%   Garcia-Escudero, L.A.; Gordaliza, A.; Matran, C. and Mayo-Iscar, A.
%   (2008), "A General Trimming Approach to Robust Cluster Analysis". Annals
%   of Statistics, Vol.36, 1324-1345. Technical Report available at
%   www.eio.uva.es/inves/grupos/representaciones/trTCLUST.pdf
%
%   Reference below documents the problem of the ill-conditioning of the
%   eigenvalue-eigenvector computation.
%
%  Numerische Mathematik, 19. August 1969, Volume 13, Issue 4, pp 293-304
%  Balancing a matrix for calculation of eigenvalues and eigenvectors
%  Dr. B. N. Parlett, Dr. C. Reinsch
%
% Parlett, B. N. and C. Reinsch, �Balancing a Matrix for Calculation of
% Eigenvalues and Eigenvectors,� Handbook for Auto. Comp., Vol. II, Linear
% Algebra, 1971,pp. 315-326.
%
% Copyright 2008-2014.
% Written by FSDA team
%
%
%<a href="matlab: docsearch('mixsim')">Link to the help function</a>
% Last modified 08-Dec-2013
%

% Examples:
%
%{
	% Generate 3 groups in 4 dimensions using maximum overlap equal to 0.15
    out=MixSim(3,4)
%}
%
%{
    % Generate 4 groups in 5 dimensions using average overlap of 0.05 and
    % maximum overlap equal to 0.15
    k=4;
    v=5;
    BarOmega=0.05;
    out=MixSim(4,5,'BarOmega',BarOmega, 'MaxOmega',0.15)

	% Check a posteriori the average overlap
    disp('Posterior average overlap')
    disp((sum(sum(out.OmegaMap))-k)/(0.5*k*(k-1)))
    
    % Check a posteriori the maximum overlap
    % Extract elements above the diagonal and sum them with the transpose
    % of the elements below the diagonal. The maximum of all these numbers
    % must be very close to the required maximum overlap
    cand=triu(out.OmegaMap,1)+(tril(out.OmegaMap,-1))'
    disp('Posterior average overlap')
    max(cand(:))
%}

%% User options

% Default
if nargin<2;
    error('k=number of components and v = number of dimensions must be specified');
end

if (v < 1)
    error('Wrong number of dimensions v')
end

if k<=1
    error('Wrong number of mixture components k')
end

Rseeddef = 0;
BarOmegadef = '';
MaxOmegadef = 0.15;
eccdef      = 0.9;
PiLowdef    = 0;
intdef      = [0 1];
resNdef     = 100;
toldef      = 1e-06;
limdef      = 1e06;

options=struct('R_seed', Rseeddef, 'BarOmega',BarOmegadef,'MaxOmega',MaxOmegadef,...
    'sph',false,'hom',false,'ecc',eccdef,'PiLow',PiLowdef,...
    'int',intdef,'resN',resNdef,'tol',toldef,'lim',limdef);

UserOptions=varargin(1:2:length(varargin));
if ~isempty(UserOptions)
    % Check if number of supplied options is valid
    if length(varargin) ~= 2*length(UserOptions)
        error('Error:: number of supplied options is invalid. Probably values for some parameters are missing.');
    end
    
    % Check if all the specified optional arguments were present in
    % structure options
    inpchk=isfield(options,UserOptions);
    WrongOptions=UserOptions(inpchk==0);
    if ~isempty(WrongOptions)
        disp(strcat('Non existent user option found->', char(WrongOptions{:})))
        error('Error:: in total %d non-existent user options found.', length(WrongOptions));
    end
end

if nargin > 2
    
    % If the user inside user options has only specified BarOmega but not
    % MaxOmega then MaxOmega is initialied with an empty value
    checkBarOmega = strcmp(UserOptions,'BarOmega');
    checkMaxOmega = strcmp(UserOptions,'MaxOmega');
    
    if sum(checkBarOmega) && ~sum(checkMaxOmega);
        options.MaxOmega='';
    end
    
    % Write in structure 'options' the options chosen by the user
    for i=1:2:length(varargin);
        options.(varargin{i})=varargin{i+1};
    end
    
end

% Default values for the optional parameters are set inside structure
% 'options'
int=options.int;

rcMax  = [0 0];
Lbound = int(1);
Ubound = int(2);

R_seed   = options.R_seed;
MaxOmega = options.MaxOmega;
BarOmega = options.BarOmega;
tol      = options.tol;
sph      = options.sph;
hom      = options.hom;
ecc      = options.ecc;
PiLow    = options.PiLow;
resN     = options.resN;
lim      = options.lim;

if R_seed > 0
    
    % Check if a connection exists
    global R_lInK_hANdle %#ok<TLEV>
    if isempty(R_lInK_hANdle)
        examp=which('Connect_Matlab_with_R_HELP.m');
        % examp1=strrep(examp,'\','\\');
        examp1=strrep(examp,filesep,[filesep filesep]);
        
        disp('To run MixSim independently from R, option R_seed must be 0');
        disp('To ensure replicability of R examples contained in file demoMixSim.R');
        disp('i.e. to use R random number generators, first run openR');
        disp(['See instructions in file <a href="matlab:opentoline(''',examp1,''',5)">Connect_Matlab_with_R_HELP.m</a>']);
        error('--------------------------');
    end
    
    setseed = ['set.seed(' num2str(R_seed) ', kind=''Mersenne-Twister'', normal.kind = ''Inversion'')'];
    [~] = evalR(setseed);
end

if ~islogical(sph)
    error('Wrong value of sph')
end

if ~islogical(hom)
    error('Wrong value of hom')
end

if ecc <= 0 || ecc > 1
    error('Wrong value of ecc')
end

if PiLow < 0 || PiLow > 1
    error('Wrong value of PiLow')
end

if int(1) >= int(2)
    error('Wrong interval int')
end

if resN < 1
    error('Wrong value of resN')
end

if (tol <= 0)
    error('Wrong value of eps')
end

if lim < 1
    error('Wrong value of lim')
end

% method =0 ==> just BarOmega has been specified
if isempty(MaxOmega) && ~isempty(BarOmega)
    method = 0;
    Omega = BarOmega;
end

% method =1 ==> just MaxOmega has been specified
if isempty(BarOmega) && ~isempty(MaxOmega)
    method = 1;
    Omega = MaxOmega;
end

% method =2 ==> both BarOmega and MaxOmega have been specified
if ~isempty(BarOmega) && ~isempty(MaxOmega)
    method = 2;
end

% method =-1 ==> both BarOmega and MaxOmega have not been specified
if isempty(BarOmega) && isempty(MaxOmega)
    method = -1;
end

if method == 0 || method == 1
    emax=ecc;
    Q = OmegaClust(Omega, method, v, k, PiLow, Lbound, Ubound, ...
        emax, tol, lim, resN, sph, hom);
    
elseif method == 2
    emax=ecc;
    
    % In this case both OmegaBar and OmegaMax have been specified
    Q = OmegaBarOmegaMax(v, k, PiLow, Lbound, Ubound, ...
        emax, tol, lim, resN, sph, BarOmega, MaxOmega);
    
elseif method~=-1
    error('Should never enter here')
else
    % isempty(BarOmega) && isempty(MaxOmega)
    error('At least one overlap characteristic should be specified')
end

out = Q;

%% Beginning of inner functions

    function  Q = OmegaClust(Omega, method, v, k, PiLow, Lbound, Ubound, emax, tol, lim, resN, sph, hom)
        % OmegaClust = procedure when average or maximum overlap is specified (not
        % both)
        %
        %  INPUT parameters
        %
        % Omega     : scalar containing requested overlap value
        % method    : scalar which specifies whether average or maximum
        %             overlap is requested. If method == 0 average overlap
        %             is requested else, max overlap is required
        % v         : scalar, dimensionality (number of variables)
        % k         : scalar, number of components (groups)
        % PiLow     : smallest mixing proportion allowed
        % Lbound    : lower bound for uniform hypercube at which mean vectors are
        %             simulated
        % Ubound    : upper bound for uniform hypercube at which mean vectors are
        %             simulated
        % emax      : maximum eccentricity
        % tol, lim  : parameters for ncx2mixtcdf.m which computes the probability
        %             of overlapping
        % resN      : scalar, number of resamplings allowed
        % sph       : scalar. If sph =1 spherical covariance matrices are
        %             generated, else covariance matrices with a
        %             prespecified maximum eccentricity are geenrated
        % hom       : scalar. If hom =1 equal covariance matrices are
        %             generated
        %
        %  OUTPUT parameters
        %
        %   A structure Q containing the following fields
        %           Pi   - vector of length k containing mixing proportions
        %           Mu   - matrix of size k-by-v contains mean vectors of
        %                  the k groups
        %           S    - array of size v-by-v-by-k containing covariance matrices
        %       OmegaMap - k-by-k matrix containing misclassification probabilities
        %       BarOmega - scalar, average overlap of the data which have been
        %                  generated
        %       MaxOmega - scalar, maximum overlap of the data which have been
        %                  generated
        %        rcMax   - vector of length 2 containing the pair of
        %                  components producing the highest overlap
        %           fail - flag indicating if the process failed (1). If everything went
        %                  well fail=0
        %
        fixcl=zeros(k,1);
        
        for isamp=1:resN
            
            fail=0;
            
            % Generate parameters
            % procedure genPi generates (mixture proportions) k numbers
            % whose sum is equal to 1 and the smallest value is not smaller
            % than PiLow
            Pigen=genPi(k,PiLow);
            % procedure genMu generates random centroids
            Mugen=genMu(v, k, Lbound, Ubound);
            
            % The last input parameter of genSigmaEcc and genSphSigma is a
            % boolean which specifies whether the matrices are equal (1) or
            % not (0)
            
            % Generate the covariance matrices
            if sph == 0
                % genSigmaEcc generates the covariance matrices with a
                % prespecified level of eccentricity
                Sgen=genSigmaEcc(v, k, emax, hom);
            else
                % genSphSigma generates spherical covariance matrices
                Sgen=genSphSigma(v, k, hom);
            end
            
            % prepare parameters (this line corresponds to row 774 of file
            % libOverlap.c)
            [li, di, const1]=ComputePars(v, k, Pigen, Mugen, Sgen);
            
            % check if desired overlap is reachable
            asympt = 1;
            c = 0.0;
            
            [OmegaMap, Balpha, Malpha, rcMax] = ...
                GetOmegaMap(c, v, k, li, di, const1, fixcl, tol, lim, asympt);
            
            if method == 0
                diff = Balpha - Omega;
            else
                diff = Malpha - Omega;
            end
            
            if (diff < -tol) % Prefixed overlapping is not reachable
                disp(['Warning: the desired overlap cannot be reached in simulation '  num2str(isamp)]);
                fail = 1;
            else
                lower=0;
                upper=4;
                % c is a constant which is used to scale the covariance
                % matrices of the groups in order to obtain a prespecified
                % level of average or maximum overlap
                c=0;
                while c==0
                    
                    [c,OmegaMap, Balpha, Malpha] = FindC(lower, upper, Omega, ...
                        method, v, k, li, di, const1, fixcl, tol, lim);
                    lower =upper;
                    upper=upper^2;
                    if upper>100000
                        disp(['Warning: the desired overlap cannot be reached in simulation '  num2str(isamp)]);
                        fail=1;
                        break
                    end
                end
            end
            
            if fail==0
                Sgen=c*Sgen;
                break  % this break enables to get out from the resampling loop
            end
        end
        
        if isamp == resN
            warning('off',['The desired overlap has not been reached in' num2str(resN) 'simulations']);
            warning('off','Increase the number of simulations allowed (option resN) or change the value of overlap');
            fail = 1;
        end
        
        Q = struct;
        Q.OmegaMap=OmegaMap;
        Q.BarOmega=Balpha;
        Q.MaxOmega=Malpha;
        Q.fail=fail;
        Q.Pi=Pigen;
        Q.Mu=Mugen;
        Q.S=Sgen;
        Q.rcMax=rcMax;
        
    end




    function Q=OmegaBarOmegaMax(p, k, PiLow, Lbound, Ubound, ...
            emax, tol, lim, resN, sph, BarOmega,MaxOmega)
        % OmegaBarOmegaMax = procedure when average and maximum overlaps are both specified
        % INPUT
        % p  - dimensionality
        % k  - number of components
        % PiLow - smallest mixing proportion allowed
        % Lbound - lower bound for uniform hypercube at which mean vectors at simulated
        % Ubound - upper bound for uniform hypercube at which mean vectors at simulated
        % emax - maximum eccentricity
        % tol, lim - parameters for qfc function
        % resN - number of resamplings allowed
        % sph - sperical covariance matrices
        % BarOmega - average overlap
        % MaxOmega - maximum overlap
        %  OUTPUT
        %   a structure Q containing the following fields
        % Pi - mixing proportions
        % Mu - mean vectors
        % S  - covariance matrices
        % OmegaMap - map of misclassification probabilities
        % BarOmega - average overlap
        % MaxOmega - maximum overlap
        % rcMax - contains the pair of components producing the highest overlap
        % fail - flag indicating if the process failed
        %  */
        Balpha=BarOmega;
        Malpha=MaxOmega;
        if Malpha<Balpha || Malpha>Balpha*k*(k-1)/2
            disp('Both conditions should hold:')
            disp('1. MaxOverlap > AverOverlap')
            disp('2.  MaxOverlap < AverOverlap * K (K - 1) / 2')
            error('incorrect values of average and maximum overlaps...');
            
        else
            
            
            li2=zeros(2, 2, p);
            di2=li2;
            const12=zeros(2);
            
            fix2=zeros(2,1);
            
            for isamp=1:resN
                
                % /* generate parameters */
                % procedure genPi generates (mixture proportions) k numbers whose sum
                % is equal to 1 and the smallest value is not smaller than PiLow
                Pigen=genPi(k,PiLow);
                % procedure genMu generates random centroids
                Mugen=genMu(p, k, Lbound, Ubound);
                
                % The last input parameter of genSigmaEcc and genSphSigma is a
                % boolean which specifies whether the matrices are equal
                % (1) or not (0)
                
                % Generate the covariance matrices
                if sph == 0
                    % genSigmaEcc generates the covariance matrices with a
                    % prespecified level of eccentricity
                    Sgen=genSigmaEcc(p, k, emax,0);
                else
                    % genSphSigma generates spherical covariance matrices
                    Sgen=genSphSigma(p, k, 0);
                end
                
                % /* prepare parameters */ row 953 of file libOverlap.c
                [li, di, const1]=ComputePars(p, k, Pigen, Mugen, Sgen);
                
                % /* check if maximum overlap is reachable */
                
                asympt = 1;
                c = 0.0;
                
                % fixcl = vector which specifies what are the clusters which
                % participate to the process of inflation
                fixcl=zeros(k,1);
                
                [OmegaMap, Balpha, Malpha, rcMax]=GetOmegaMap(c, p, k, li, di, const1, fixcl, tol, lim, asympt);
                
                
                diff = Malpha - MaxOmega;
                
                % Initialize fail
                fail=1;
                
                if diff >= -tol %  /* reachable */
                    
                    lower = 0.0;
                    upper = 2^10;
                    
                    while fail ~=0
                        
                        % /* find C for two currently largest clusters */
                        
                        for ii=1:2;
                            for jj=1:2
                                for l=1:p
                                    li2(ii,jj,l) = li(rcMax(ii),rcMax(jj),l);
                                    di2(ii,jj,l) = di(rcMax(ii),rcMax(jj),l);
                                end
                                const12(ii,jj) = const1(rcMax(ii),rcMax(jj));
                            end
                        end
                        
                        Malpha = MaxOmega;
                        
                        c=FindC(lower, upper, Malpha, 1, p, 2, li2, di2, const12, fix2, tol, lim);
                        
                        if c == 0 % /* abnormal termination */
                            disp(['Warning: the desired overlap cannot be reached in simulation '  num2str(isamp)]);
                            fail = 1;
                            break;
                        end
                        
                        asympt = 0;
                        % Map of misclassification probabilities
                        % Average overlap
                        % Maximum overlap
                        [OmegaMap, Balpha, Malpha, rcMax]=GetOmegaMap(c, p, k, li, di, const1, fixcl, tol, lim, asympt);
                        upper = c;
                        
                        diff = Balpha - (BarOmega);
                        if (diff < -tol) % /* BarOmega is not reachable */
                            disp(['Warning: the desired overlap cannot be reached in simulation '  num2str(isamp)]);
                            fail = 1;
                            break;
                        end
                        
                        diff = Malpha - MaxOmega;
                        if (diff < tol) %  /* MaxOmega has been reached */
                            fail = 0;
                            break;
                        end
                        
                    end
                    
                end
                
                if fail == 0
                    %  OmegaMax is reached and OmegaBar is reachable
                    % correct covariances by multiplier C
                    
                    
                    % cxS(p, K, S, c);
                    Sgen=c*Sgen;
                    
                    
                    [li,di,const1]=ComputePars(p,k,Pigen,Mugen,Sgen);
                    
                    fixcl(rcMax(1)) = 1;
                    fixcl(rcMax(2)) = 1;
                    upper = 1;
                    
                    Balpha = BarOmega;
                    method = 0;
                    % FindC(lower, upper, Balpha, method, p, K, li, di, const1, fix, pars, lim, &c, OmegaMap, &Balpha, &Malpha, rcMax);
                    
                    [c,OmegaMap, Balpha, Malpha,rcMax]=FindC(lower, upper, Balpha, method, p, k, li, di, const1, fixcl, tol, lim);
                    
                    
                    % correct covariances by multiplier c
                    for jj=1:k
                        if fixcl(jj) == 0
                            Sgen(:,:,jj) = c * Sgen(:,:,jj);
                        end
                    end
                    
                    
                    % Inside if  fail==0 OmegaMax is reached and OmegaBar is reachable */
                    break
                end
                
                
                
            end
            if isamp == resN
                warning('off',['The desired overlap has not been reached in' num2str(resN) 'simulations']);
                warning('off','Increase the number of simulations allowed (option resN) or change the value of overlap');
                
                fail = 1;
                
            end
            
            
            BarOmega = Balpha;
            MaxOmega = Malpha;
            Q=struct;
            Q.OmegaMap=OmegaMap;
            Q.BarOmega=BarOmega;
            Q.MaxOmega=MaxOmega;
            Q.fail=fail;
            Q.Pi=Pigen;
            Q.Mu=Mugen;
            Q.S=Sgen;
            Q.rcMax=rcMax;
            
        end
    end



    function Pigen=genPi(k,PiLow)
        % genPi generates mixing proportions
        %
        %  Required input arguments:
        % 		k       : scalar, number of components
        % 		PiLow   : scalar, smallest possible mixing proportion
        %
        %  Output:
        %
        % 		Pigen : vector of length k containing mixing proportions
        %
        %  For example Pigen=genPi(4,0.24)
        %  produces Pigen=
        %    0.2440
        %    0.2517
        %    0.2565
        %    0.2478
        %
        flag = 0;
        
        if PiLow >= 1 || PiLow <= 0
            if PiLow < 0 || PiLow >= 1
                disp('Warning: PiLow is out of range... generated equal mixing proportions...');
            end
            Pigen=zeros(k,1);
            Pigen=Pigen+1/k;
            
        else
            
            if R_seed
                Pigen = evalR(['rgamma(' num2str(k) ',1)']);
                Pigen = Pigen';
            else
                Pigen = randg(1,k,1);
            end
            
            s=sum(Pigen);
            
            for j=1:k
                Pigen(j) = PiLow + Pigen(j) / s * (1 - k * PiLow);
                if (Pigen(j) < PiLow)
                    flag = 1;
                    break
                end
            end
            if (flag == 1)
                warning('off','PiLow is too high... generated equal mixing proportions...');
                Pigen=zeros(k,1)+1/k;
            end
        end
    end



    function Mugen=genMu(p,k,Lbound, Ubound)
        % genMu generates matrix of means of size k-by-p
        % Parameters:
        % 		p - number of dimensions
        % 		k - number of components
        % 		Lbound - lower bound for the hypercube
        % 		Ubound - upper bound for the hypercube
        %   Output:
        % 		Mu - matrix of means of size k-by-p
        
        if R_seed
            % equivalent of 'rand(k,p)' in R is 'matrix(runif(k*p),k,p)'
            rn1s = ['matrix(runif(' num2str(k*p) '),' num2str(p) ',' num2str(k) ')'];
            rn1 = evalR(rn1s);
            rn1b = rn1';
            Mugen = Lbound + (Ubound-Lbound)*rn1b;
        else
            Mugen = Lbound + (Ubound-Lbound)*rand(k,p);
        end
    end


    function VC=genSigma(p)
        n = p + 1;
        
        mu=zeros(p,1);
        x=zeros(n,p);
        
        
        for ii=1:n
            for jj=1:p
                if R_seed
                    % randn(1) in R is rnorm(1)
                    x(ii,jj)= evalR('rnorm(1)');
                    mu(jj) = mu(jj) + x(ii,jj);
                else
                    x(ii,jj)= randn(1);
                    mu(jj) = mu(jj) + x(ii,jj);
                end
            end
        end
        
        mu=mu/n;
        
        VC=zeros(p);
        
        for ii=1:n
            for jj=1:p
                for kk=1:p
                    VC(jj,kk) = VC(jj,kk) + (x(ii,jj) - mu(jj)) * (x(ii,kk) - mu(kk));
                end
            end
        end
        
        VC=VC/(n-1);
    end




    function S=genSigmaEcc(p, k, emax, hom)
        % genSigmaEcc generates covariance matrix with prespecified eccentricity
        %
        %  Required input arguments:
        % 
        % 		p    - scalar, number of dimensions
        % 		k    - scalar, number of components
        % 		emax - scalar which defines maximum eccentricity
        %       hom  - scalar which specifies whether homogeneous (equal) or
        %              heterogeneous (different) covariance matrices must
        %              be generated. hom=1 implies homogeneous clusters
        %
        %  Output parameters
        %          S - array of size v-by-v-by-k containing the k
        %          variance-covariance matrices of the k groups
        %
        
        % S = 3d array which contains the covariance matriced of the groups
        S=zeros(p,p,k);
        
        if hom == 0
            
            for kk=1:k
                
                VC=genSigma(p);
                S(:,:,kk)=VC;
                
                [V,L] = eig(VC);
                Eig=diag(L);
                minL=min(Eig);
                maxL=max(Eig);
                
                % e = eccentricity
                e = sqrt(1 - minL / maxL);
                
                if (e > emax)
                    L=zeros(p);
                    
                    for ii=1:p
                        Eig(ii) = maxL * (1 - emax * emax * (maxL - Eig(ii)) / (maxL - minL));
                        L(ii,ii)=Eig(ii);
                    end
                    
                    R=V*L*V';
                    S(:,:,kk)=R;
                end
            end
        else % homogeneous clusters
            
            VC=genSigma(p);
            for kk=1:k;
                S(:,:,kk)=VC;
            end
            
            [V,L] = eig(VC);
            Eig=diag(L);
            minL=min(Eig);
            maxL=max(Eig);
            
            
            % e = eccentricity
            e = sqrt(1 - minL / maxL);
            
            % If some simulated dispersion matrics have e>emax specified by
            % ecc all eigenvalues will be scaled in order to have
            % enew=emax;
            if (e > emax)
                L=zeros(p);
                
                for ii=1:p
                    Eig(ii) = maxL * (1 - (emax^2) * (maxL - Eig(ii)) / (maxL - minL));
                    L(ii,ii)=Eig(ii);
                end
                
                R=V*L*(V');
                for kk=1:k;
                    S(:,:,kk)=R;
                end
            end
        end
    end



    function S=genSphSigma(p,k,hom)
        %Generates spherical covariance matrices
        %
        %  Required input arguments:
        %
        % 		p    - scalar, number of dimensions
        % 		k    - scalar, number of components
        %       hom  - scalar which specifies whether homogeneous (equal) or
        %              heterogeneous (different) covariance matrices must
        %              be generated. hom=1 implies homogeneous clusters
        %
        %  Output:
        %
        % 		S :  3D array of size p-by-p-by-k containing the k
        % 		variance-covariance matrices
        %
        S=zeros(p,p,k);
        
        % if hom ==1
        % S(:,:,j) = \sigma^2 I_p
        % else if hom =1
        % S(:,:,j) = \sigma^2_j I_p
        
        
        eyep=eye(p);
        if R_seed
            % rand(1) in R is runif(1)
            r = evalR('runif(1)');
        else
            r = rand(1);
        end
        
        for kkk=1:k
            if hom == 0
                if R_seed
                    % rand(1) in R is runif(1)
                    r = evalR('runif(1)');
                else
                    r = rand(1);
                end
            end
            LL=r*eyep;
            
            S(:,:,kkk)=LL;
        end
        
    end



    function  [c,OmegaMap2, BarOmega2, MaxOmega2,rcMax]=FindC(lower, upper, Omega, method, p, k, li, di, const1, fix, tol, lim)
        %find multiplier c on the interval [lower upper]
        %
        %  Required input arguments:
        %
        % lower : scalar - lower bound of the interval
        % upper : scalar - upper bound of the interval
        % Omega : k-by-k matrix containing input map of misclassification
        %         probabilities
        % method : scalar which specifies whether average (method=0) or maximum
        %          overlap is requested 
        %     p  : dimensionality
        %     k  : number of components
        % li, di, const1 : parameters needed for computing overlap,
        %          precalculated using routine ComputePars 
        %    fix : vector of length k containing zeros or ones
        %          if fix(j) =1 cluster j does not participate to inflation or
        %          deflation. If fix=zeros(k,1) all clusters participate in inflation/deflation
        %          This parameter is used just if heterogeneous clusters are used
        %         tol : scalar. Error bound for overlap computation default is 1e-06
        %         lim : maximum number of integration terms default is 1e06.
        %               REMARK: Optional parameters tol and lim will be used by
        %               function ncx2mixtcdf.m which computes the cdf of a linear
        %               combination of non central chi2 r.v.. This is the
        %               probability of overlapping
        %
        %  Output:
        %
        %        c    : scalar inflation parameter
        %               c is a constant which is used to scale the covariance
        %               matrices of the groups in order to obtain a
        %               prespecified level of average or maximum overlap
        %   OmegaMap2 : k-by-k matrix containing map of misclassification
        %               probabilities
        %   BarOmega2 : scalar. Average overlap 
        %   MaxOmega2 : scalar. Maximum overlap
        %      rcMax  : vector of length 2 containing the indexes assocaited
        %              to the pair of components producing the highest overlap
        %
        
        diff = Inf;
        stopIter = 1000;
        
        sch = 0;
        
        while abs(diff) > tol
            
            c = (lower + upper) / 2.0;
            
            asympt = 0;
            [OmegaMap2, BarOmega2, MaxOmega2,rcMax]=GetOmegaMap(c, p, k, li, di, const1, fix, tol, lim, asympt);
            
            % disp(OmegaMap2)
            
            if method == 0
                
                if BarOmega2 < Omega
                    % clusters are too far 
                    lower = c;
                else
                    upper = c;
                end
                
                diff = BarOmega2 - Omega;
                
            else
                
                if MaxOmega2 < Omega
                    % clusters are too far 
                    lower = c;
                else
                    upper = c;
                end
                
                diff = MaxOmega2 - Omega;
                
            end
            
            sch = sch + 1;
            
            if sch == stopIter
                c = 0.0;
                disp(['Warning: required overlap was not reached in routine findC after ' num2str(stopIter) ' iterations...'])
                break;
            end
            
        end
    end
end





