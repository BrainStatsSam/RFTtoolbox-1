function peak_locs = findtpeaks(lat_data, Kernel, xvals_vecs, peak_est_locs, mask)
% FINDTPEAKS( lat_data, Kprime, xvals_vecs, peak_est_locs, Kprime2, truncation, mask )
% calculates the locations of peaks in a convolution field using Newton Raphson.
%--------------------------------------------------------------------------
% ARGUMENTS
% lat_data      A D by nsubj matrix array giving the value of the lattice 
%               field at every point.
% Kprime        a function handle giving the derivative of the kernel. If
%               this is numeric the kernel is taken to be Gaussian with the 
%               value as the FWHM. I.e. if Kprime = 2, then within the 
%               function Kprime is set to be @(x) GkerMVderiv(x,2).
% xvals_vecs    a D-dimensional cell array whose entries are vectors giving the
%               xvalues at each each dimension along the lattice. It assumes
%               a regular, rectangular lattice (though within a given
%               dimension the voxels can be spaced irregularly).
%               I.e suppose that your initial lattice grid is a
%               4by5 2D grid with 4 voxels in the x direction and 5 in
%               the y direction. And that the x-values take the values:
%               [1,2,3,4] and the y-values take the values: [0,2,4,6,8].
%               Then you would take xvals_vecs = {[1,2,3,4], [0,2,4,6,8]}.
%               The default is to assume that the spacing between the
%               voxels is 1. If only one xval_vec direction is set the
%               others are taken to range up from 1 with increment given by
%               the set direction.
% peak_est_locs a D by npeaks matrix giving the initial estimates of the 
%               location of the peaks. If this is instead an integer: top  
%               then the top number of maxima are considered and initial 
%               locations are estimated from the underlying data. If this 
%               is not specified then it is set to 1, i.e. only considering
%               the maximum.
% Kprime2       the 2nd derivative of the kernel. If this is not set then
%               if the initial Kernel is Gaussian it is taken to be the 2nd
%               derivative of the corresponding Gaussian kernel. Otherwise
%               it is estimated from Kprime.
% truncation
% mask
%--------------------------------------------------------------------------
% OUTPUT
% peak_locs   the true locations of the top peaks in the convolution field.
%--------------------------------------------------------------------------
% EXAMPLES
% % 1D
% Y = [1,2,1];
% findtpeaks(Y, 3, 1:3, 1)
%
% % 2D
% Y = [1,1,1,1;1,2,2,1;1,2,2,1;1,1,1,1];
% find_peak_locs(Y, 3, 1:4, [2,2]')
%--------------------------------------------------------------------------
% AUTHOR: Samuel Davenport.
Ldim = size(lat_data);
Ldim = Ldim(1:end-1);
D = length(Ldim);
% if Ldim(1) == 1 %May need this if you have problems in D = 1?
%     D = D - 1;
%     Ldim = Ldim(2:end-1);
%     if D > 1
%         lat_data = reshape(lat_data, Ldim);
%     end
% end
if nargin < 5
   mask = ones(Ldim); 
end

if isnan(sum(lat_data(:)))
   error('Cant yet deal with nans') 
end

%Setting up xvals_vecs
if nargin < 4
    xvals_vecs = {1:Ldim(1)};  %The other dimensions are taken case of below.
end
if ~iscell(xvals_vecs)
    xvals_vecs = {xvals_vecs};
end
if length(xvals_vecs) < D
    increm = xvals_vecs{1}(2) - xvals_vecs{1}(1);
    for d = (length(xvals_vecs)+1):D
        xvals_vecs{d} = xvals_vecs{1}(1):increm:(xvals_vecs{1}(1)+increm*(Ldim(d)-1));
    end
end

% nsubj = size(lat_data, 1);
xvals_vecs_dims = zeros(1,D);
for d = 1:D
    xvals_vecs_dims(d) = length(xvals_vecs{d});
end
if ~isequal(xvals_vecs_dims, Ldim)
    error('The dimensions of xvals_vecs must match the dimensions of lat_data')
end

tcf = @(tval) tcfield( tval, lat_data, xvals_vecs, Kernel );
h = 0.0001;
if D == 1
    tcf_deriv = @(tval) (tcf(tval+h) - tcf(tval))/h;
    tcf_deriv2 = @(tval) (tcf_deriv(tval+h) - tcf_deriv(tval))/h;
elseif D == 2
    tcf_deriv = @(x) [(tcf(x+h*[1,0]') - tcf(x))/h, (tcf(x+h*[0,1]') - tcf(x))/h]';
    tcf_deriv2 = @(x) [(tcf_deriv(x+h*[1,0]') - tcf_deriv(x))/h, (tcf_deriv(x+h*[0,1]') - tcf_deriv(x))/h];
elseif D == 3
    tcf_deriv = @(x) [(tcf(x+h*[1,0,0]') - tcf(x))/h, (tcf(x+h*[0,1,0]') - tcf(x))/h, (tcf(x+h*[0,0,1]') - tcf(x))/h]';
    tcf_deriv2 = @(x) [(tcf_deriv(x+h*[1,0,0]') - tcf_deriv(x))/h, (tcf_deriv(x+h*[0,1,0]') - tcf_deriv(x))/h, (tcf_deriv(x+h*[0,0,1]') - tcf_deriv(x))/h];
end

if nargin < 4 
    peak_est_locs = 1; %I.e. just consider the maximum.
end

% At the moment this is just done on the initial lattice. Really need to
% change so that it's on the field evaluated on the lattice.

if isequal(size(peak_est_locs), [1,1])
    top = peak_est_locs;
    xvalues_at_voxels = xvals2voxels( xvals_vecs );
    teval_lat = tcf(xvalues_at_voxels);
    max_indices = lmindices(teval_lat, top, mask)'; %Note the transpose here! It's necessary for the input to other functions.
    if D == 1
        max_indices = max_indices';
    end
    top = length(max_indices);  
    peak_est_locs = zeros(D, top);
    for I = 1:D
        peak_est_locs(I, :) = xvals_vecs{I}(max_indices(I,:));
    end
end
if D == 1 && isnan(peak_est_locs(1))
    peak_est_locs = peak_est_locs(2:end) ;
end
npeaks = size(peak_est_locs, 2);

peak_locs = zeros(D, npeaks);
for peakI = 1:npeaks
    tol = min(abs(tcf_deriv(peak_est_locs(:,peakI)))/100000, 0.0001);
    notconverged = 1;
    while notconverged > 0 %This loop is to deal with situations where things don't converge on the first initialization.
        try
            peak_locs(:, peakI) = NewtonRaphson(tcf_deriv, peak_est_locs(:, peakI) + (notconverged-1)*0.1, tcf_deriv2, tol);
%             peak_locs(peakI) = NewtonRaphson(fderiv, peak_est_locs(peakI) + (notconverged-1)*0.1, fderiv2, tol);
            notconverged = 0;
        catch
            notconverged = notconverged + 1;
            if notconverged > 10
                error('notconverged has not converged')
            end
        end
    end
end

end