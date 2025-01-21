function [r, allrates] = irr(cf) 
%IRR   Internal rate of return.
%
%   R = IRR(CF)
%   [R, ALLRATES] = IRR(CF)
%
%   Inputs:
%         CF - A vector containing a stream of periodic cash flows. The
%            first entry in CF is the initial investment. If CF is a
%            matrix, each column of CF is treated as a separate cash-flow
%            stream.
%
%   Outputs:
%          R - An internal rate of return associated to CF. If CF is a
%            matrix, then R is a vector whose entry j is an internal rate
%            of return for column j in CF.
%
%   Optional Outputs:
%   ALLRATES - A vector containing all the internal rates of return
%            associated to CF. If CF is a matrix, then ALLRATES is also a
%            matrix, with the same number of columns as CF, and one fewer
%            row, and column j in ALLRATES contains all the rates of return
%            associated to column j in CF (including complex-valued rates).
%
%   Conventions:
%      * If one or multiple (warning if multiple) strictly positive rates
%        are found, R is set to the minimum
%      * If no strictly positive rates, but one or multiple (warning if
%        multiple) non-positive rates are found, R is set to the maximum
%      * If no real-valued rates are found, R is set to NaN (no warnings)
%
%   Examples:
%
%   1) A simple investment with a unique positive rate of return
%
%      Suppose an initial investment of $100,000 is made, and the following
%      cash flows represent the yearly income realized by the investment:
%  
%                  Year 1       $10,000 
%                  Year 2       $20,000 
%                  Year 3       $30,000 
%                  Year 4       $40,000 
%                  Year 5       $50,000 
% 
%      To calculate the internal rate of return on the investment, use
%
%              r = irr([-100000 10000 20000 30000 40000 50000])
%
%      which returns r = 12.01%. If the cash flow payments were monthly,
%      the resulting rate of return would be multiplied by 12 for the
%      annual rate of return.
%
%   2) Multiple rates of return
%
%      Consider now a project with the following cash flows:
%
%                     CF = [-1000 6000 -10900 5800].
%
%      Suppose the market rate is 10%.
%         We first call IRR with a single output argument:
%
%                             R = irr(CF).
%
%      It displays a warning ("Warning: Multiple rates of return") and
%      returns a 100% rate of return. The 100% rate on the project looks
%      very attractive. However, there was a warning. So call IRR again,
%      but this time with two output arguments:
%
%                        [R, ALLRATES] = irr(CF).
%
%      The rates of return (in ALLRATES) are -4.88%, 100%, and 204.88%.
%         Though some of these rates are lower and some higher than the
%      market rate, any of these rates can be used to get a consistent
%      recommendation on the project (see [2]), but we recommend to simply
%      switch to a present value analysis in these kinds of situations.
%         To check the present value of the project, use PVVAR:
%
%                          PV = pvvar(CF,0.10).
%
%      The second argument is the 10% market rate. The present value is
%      -196.0932, negative, so the project is not desirable.
%
%   It is good practice to always complement the use of IRR with a present
%   value analysis, using PVVAR, especially when there is a warning about
%   multiple rates of return. Some cash-flow streams have a unique positive
%   internal rate of return, as in Example (1). However, all cash-flow
%   streams have a multiplicity of rates of returns (some of which are
%   negative, or complex-valued; see the conventions above on when a
%   warning is thrown). Hazen [2] explains how any of these rates can be
%   used to get a recommendation on the project that is consistent with the
%   present value analysis (therefore, all rates of return are valid and
%   consistent). Yet, using the present value directly is a simpler way to
%   accomplish the same goal when the rates of return, as in Example (2),
%   do not have a straightforward interpretation.
%
%   See also MIRR, XIRR, PVVAR.
%
%   References:
%      [1] Brealey and Myers. Principles of Corporate Finance. Chapter 5.
%      [2] Hazen, G. A New Perspective on Multiple Internal Rates of
%          Return. The Engineering Economist, 2003, Vol. 48-1, pp. 31-51.
%

%       Copyright 1995-2006 The MathWorks, Inc.

if nargin < 1
   error(message('finance:irr:missingInputs'))
end

if ~isnumeric(cf)
   error(message('finance:irr:invalidInputArg'))
end

oneRateOut = true;
if (nargout == 2)
   oneRateOut = false;
end

[rowcf,colcf] = size(cf);
if rowcf == 1
   [rowcf,colcf] = size(cf');
   cf = cf(:);
end 

multrates = zeros(1,colcf);
r = zeros(1,colcf);
if nargout>1
   allrates = NaN(rowcf-1,colcf);
end

for loop = 1:colcf % loop over all cash-flow streams

   coeff = roots(fliplr(cf(:,loop)')); % Find roots of polynomial 
   rates = (1./coeff) - 1; % Compute corresponding rates

   % Preferred rates are real-valued and positive
   ind = find(rates > 0 & abs(imag(rates)) < 1e-6);
   nind = length(ind);
   if (nind==1)
      % One single positive rate
      r(loop) = real(rates(ind));
   elseif (nind > 1)
      % Multiple positive rates; flag stream id and return min rate
      multrates(loop) = 1;
      r(loop) = min(real(rates(ind)));
   else
      % Get indices of any other real rates, if any (must be <= 0)
      ind = find(abs(imag(rates)) < 1e-6);
      nind = length(ind);
      if (nind==1)
         % One non-positive rate
         r(loop) = real(rates(ind));
      elseif (nind > 1)
         % Multiple non-positive rates; flag stream id and return max rate
         multrates(loop) = 1;
         r(loop) = max(real(rates(ind)));
      else
         % No real rates; return NaN
         r(loop) = NaN;
      end
   end

   if nargout>1
      allrates(1:length(rates),loop) = rates(:);
   end

end % for loop

ind = find(multrates==1);
if (oneRateOut && ~isempty(ind))
   if (colcf==1)
      warning(message('finance:irr:multipleIRR'));
   else
     warning(message('finance:irr:multipleIRRVec', num2str( ind )));
   end
end
