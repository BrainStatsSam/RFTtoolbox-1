function [T, mu, sigma, d, Xcfields_at_tval] = tcfield( tval, lat_data, Kernel, truncation, xvals_vecs, mask )
% tcfield( tval, data, xvalues_at_voxels, Kernel ) calculates a 
% t-convolution field at the set of points specified by tval
%--------------------------------------------------------------------------
% ARGUMENTS
% tval      a D (number of dimensions) by nvalues matrix. Where each column
%           is a point at which to evaluate the t-convolution field.
% data      a Dim by nsubj array storing the individual lattice fields
%           (pre-smoothing) for each subject. Dim a vector giving the
%           dimensions of each lattice field.
% Kernel    the smoothing Kernel (as a function). If Kernel is a postive
%           number then an isotropic Gaussian kernel with dimension D and
%           FWHM = Kernel is used
% truncation    a window around the points at which to evaluate the kernel
%               setting this parameter allows for quicker computation of
%           the convolution field and has very litle effect on the values
%           of the field for kernels that have light tails such as the
%           Gaussian kernel. Default (which is recorded by setting
%           truncation = 0) is no truncation, using a Gaussian kernel 
%           (i.e. Kernel is entered as a number) and setting truncation = -1 results 
%           in a truncation of 4*FWHM2sigma(Kernel);
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
% mask      a D dimension 0/1 array that serves as a mask for the data. The 
%           default (if no mask is included) is not to mask the data, i.e. 
%           setting mask = ones(Dim);
%--------------------------------------------------------------------------
% OUTPUT
% T         the t-convolution field at the points given by tval
% mu        the mean estimate of the convolution fields at the points given by tval
% sigma     the standard deviation of the convolution fields at the points given by tval
% d         the cohensd-convolution field at the points given by tval
% Xcfields_at_tval     an nvalues by nsubj matrix where the ith column is 
%                  the convolution fields for the ith subject evaluated at 
%                  each of the tvalues
%--------------------------------------------------------------------------
% EXAMPLES
% % 1D t convolution field
% FWHM = 4; L = 100; nsubj = 40;
% lat_data = normrnd(0,1, L, nsubj);
% tcf = @(tval) tcfield( tval, lat_data, FWHM );
% plot(1:L, tcf(1:L))
% hold on
% plot(1:L, smoothtstat( data, FWHM));
%
% % 2D t convolution field. Note this is just illusratation, it is
% % inefficient to generate a whole 2D t field this way, much better to use
% % convfield. tcfield is to be used when you just want to calculate
% % several points in the field rather than on a regular grid
% nsubj = 20;
% Dim = [10,10];
% xvals_vecs = {1:Dim(1), 1:Dim(2)};
% xvaluesatvoxels = xvals2voxels(xvals_vecs);
% lat_field = normrnd(0,1,[Dim, nsubj]);
% field_at_voxels = reshape(tcfield( xvaluesatvoxels, lat_field, FWHM, -1 ), Dim);
% smoothfield = smoothtstat( lat_field, FWHM );
% surf(field_at_voxels)
% pause
% surf(smoothfield)
%--------------------------------------------------------------------------
% AUTHOR: Samuel Davenport
%--------------------------------------------------------------------------
if isnumeric(Kernel)
%     if Kernel < 1
%         warning('Are you sure the FWHM and increm have been written the right way around?')
%     end
%     FWHM = Kernel;
%     truncation = round(10*FWHM2sigma(FWHM));
    Kernel = @(x) GkerMV(x,Kernel);
end
if nargin < 4
    truncation = 0;
end

Ldim = size(lat_data);
D = length(Ldim) - 1;

if nargin < 5
    xvals_vecs = {1:Ldim(1)}; %The other dimensions are taken case of below.
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

if nargin < 6 %Default mask
    if D == 1
        mask = ones([1,Ldim(1:D)]);
    else
        mask = ones(Ldim(1:D));
    end
end

nsubj = size(lat_data,D+1);
nevals = size(tval,2);
Xcfields_at_tval = zeros(nevals, nsubj);

% if size(data,1) ~= length(xvalues_at_voxels)
%     error('The dimensions of data and xvalues_at_voxels do not match up')
% end

if D == 1
    for I = 1:nsubj
        Xcfields_at_tval(:, I) = applyconvfield(tval, lat_data(:,I)', Kernel, truncation, xvals_vecs, mask );
    end
elseif D == 2
    for I = 1:nsubj
        Xcfields_at_tval(:, I) = applyconvfield(tval, squeeze(lat_data(:,:,I)), Kernel, truncation, xvals_vecs, mask );
    end
elseif D == 3
    for I = 1:nsubj
        Xcfields_at_tval(:, I) = applyconvfield(tval, squeeze(lat_data(:,:,:,I)), Kernel, truncation, xvals_vecs, mask );
    end
else
    error('Not coded for D > 3')
end

[T,mu,sigma,d] = mvtstat(Xcfields_at_tval);

% if D == 1
%     T = T';
% end

T = T';

end


