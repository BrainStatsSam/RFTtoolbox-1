function sigma = FWHM2sigma( FWHM )
% NEWFUN serves as a function template.
%--------------------------------------------------------------------------
% ARGUMENTS
% 
%--------------------------------------------------------------------------
% OUTPUT
% 
%--------------------------------------------------------------------------
% EXAMPLES
% 
%--------------------------------------------------------------------------
% AUTHOR: Samuel Davenport.

sigma = FWHM/sqrt(8*log(2));
end

