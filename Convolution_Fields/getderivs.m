function [fprime, fprime2] = getderivs( f, D, h)
% NEWFUN serves as a function template.
%--------------------------------------------------------------------------
% ARGUMENTS
%
%--------------------------------------------------------------------------
% OUTPUT
%
%--------------------------------------------------------------------------
% EXAMPLES
% [fprime, fprime2] = getderivs( @(x) x^2, 1)
% evalfprime = zeros(1,10);
% evalfprime2 = zeros(1,10);
% for x = 1:10
%   evalfprime(x) = fprime(x);
%   evalfprime2(x) = fprime2(x);
% end
% plot(1:10, evalfprime)
% hold on
% plot(1:10, evalfprime2)
%--------------------------------------------------------------------------
% AUTHOR: Samuel Davenport
if nargin < 2
    try
        f(1)
        D = 1;
    catch
        try
            f([1,1])
            D = 2;
        catch
            try
                f([1,1])
                D = 3;
            catch
                error('Need to have the function in the right form or input a dimension')
            end
        end
    end
end
if nargin < 3
    h = 10^(-4);
end

if D == 1
    fprime = @(x) (f(x+h) - f(x))/h;
    fprime2 = @(x) (fprime(x+h) - fprime(x))/h;
elseif D == 2
    fprime = @(x) [(f(x+h*[1,0]') - f(x))/h, (f(x+h*[0,1]') - f(x))/h];
    fprime2 = @(x) [(fprime(x+h*[1,0]') - fprime(x))/h, (fprime(x+h*[0,1]') - fprime(x))/h];
elseif D == 3
    fprime = @(x) [(f(x+h*[1,0,0]') - f(x))/h, (f(x+h*[0,1,0]') - f(x))/h, (f(x+h*[0,0,1]') - f(x))/h]';
    fprime2 = @(x) [(fprime(x+h*[1,0,0]') - fprime(x))/h, (fprime(x+h*[0,1,0]') - fprime(x))/h, (fprime(x+h*[0,0,1]') - fprime(x))/h];
end

end

