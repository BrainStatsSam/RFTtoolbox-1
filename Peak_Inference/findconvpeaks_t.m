function [peaklocs, peakvals] = findconvpeaks_t(lat_data, Kernel, peak_est_locs, mask, xvals_vecs, truncation )
% FINDTPEAKS( lat_data, Kprime, xvals_vecs, peak_est_locs, Kprime2, truncation, mask )
% calculates the locations of peaks in a convolution field using Newton Raphson.
%--------------------------------------------------------------------------
% ARGUMENTS
% lat_data      A D by nsubj matrix array giving the value of the lattice
%               field at every point.
% Kernel
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
% L = 100;
% nsubj = 50;
% lat_data = normrnd(0,1,L,nsubj);
% FWHM = 3;
% findconvpeaks_t(lat_data, FWHM)
% tcf = @(tval) tcfield( tval, lat_data, FWHM );
% plot(1:L, tcf(1:L))
%
% % 2D
% Dim = [3,3];
% nsubj = 20;
% mask = ones(Dim); mask(2,1) = 0;
% lat_data = normrnd(0,1,[Dim,nsubj]);
% findconvpeaks_t(lat_data, FWHM, 1, mask)
% xvals = 0.5:0.1:3.5;
% masked_field = @(x) mask_field( x, mask ).*tcfield( x, lat_data, FWHM );
% xvaluesatvoxels = xvals2voxels(xvals,2);
% surf(reshape(masked_field(xvaluesatvoxels),[length(xvals),length(xvals)]))
%--------------------------------------------------------------------------
% AUTHOR: Samuel Davenport
%--------------------------------------------------------------------------
Ldim = size(lat_data);
% nsubj = Ldim(end);
Ldim = Ldim(1:end-1);
D = length(Ldim);
% if Ldim(1) == 1 %May need this if you have problems in D = 1?
%     D = D - 1;
%     Ldim = Ldim(2:end-1);
%     if D > 1
%         lat_data = reshape(lat_data, Ldim);
%     end
% end
if nargin < 3
    peak_est_locs = 1; %I.e. just consider the maximum.
end
if nargin < 4
    if D == 1
        mask = ones(1,Ldim);
    else
        mask = ones(Ldim);
    end
end
if nargin < 6
    truncation = 0;
    %     truncation = 10*FWHM2sigma(Kernel);
end

if isnan(sum(lat_data(:)))
    error('Cant yet deal with nans')
end

%Setting up xvals_vecs
if nargin < 5
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

xvals_vecs_dims = zeros(1,D);
for d = 1:D
    xvals_vecs_dims(d) = length(xvals_vecs{d});
end
if ~isequal(xvals_vecs_dims, Ldim)
    error('The dimensions of xvals_vecs must match the dimensions of lat_data')
end

tcf = @(tval) tcfield( tval, lat_data, Kernel, truncation, xvals_vecs, mask );

if ~isequal(mask, ones(Ldim)) && ~isequal(mask, ones([1, Ldim]))
    masked_field = @(x) mask_field( x, mask, xvals_vecs ).*tcf(x);
else
    masked_field = tcf;
end

% At the moment this is just done on the initial lattice. Really need to
% change so that it's on the field evaluated on the lattice.

if isequal(size(peak_est_locs), [1,1]) && floor(peak_est_locs(1)) == peak_est_locs(1)
    top = peak_est_locs;
%     xvalues_at_voxels = xvals2voxels( xvals_vecs );
    teval_lat = smoothtstat(lat_data, Kernel);
%     if D < 3
%         teval_lat = tcf(xvalues_at_voxels);
%     else
%         smoothed_field = zeros([Ldim, nsubj]);
%         smoothing_store = zeros(Ldim);
%         for subj = 1:nsubj
%             spm_smooth(lat_data(:,:,:,subj), smoothing_store, Kernel);
%             smoothed_field(:,:,:,subj) = smoothing_store;
%         end
%         teval_lat = mvtstat(smoothed_field, Ldim);
%     end
    max_indices = lmindices(teval_lat, top, mask); %Note the transpose here! It's necessary for the input to other functions.
    if D == 1
        max_indices = max_indices';
    end
    top = size(max_indices,2);
    peak_est_locs = zeros(D, top);
    for I = 1:D
        peak_est_locs(I, :) = xvals_vecs{I}(max_indices(I,:));
    end
end
if D == 1 && isnan(peak_est_locs(1))
    peak_est_locs = peak_est_locs(2:end);
end

% [ peaklocs, peakvals ] = findlms( masked_field, peak_est_locs, 1.5 );

npeaks = size(peak_est_locs, 2);
peaklocs = zeros(D, npeaks);
peakvals = zeros(1, npeaks); 

A = [eye(D);-eye(D)];
% b = [Ldim(:)+0.5;ones(D,1)-0.5];
b = zeros(2*D,1);
for d = 1:D
    b(d) = xvals_vecs{d}(end);
end
for d = 1:D
    b(d+D) = -xvals_vecs{d}(1);
end
% b = [Ldim(:);ones(D,1)] %Need to discuss which boundary to use with Fabian!!!

options = optimoptions(@fmincon,'Display','off'); %Ensures that no output is displayed.
for peakI = 1:npeaks
    peaklocs(:, peakI) = fmincon(@(tval) -tcf(tval), peak_est_locs(:, peakI), A, b, [], [], [], [], [], options);
    peakvals(peakI) = tcf(peaklocs(:, peakI));
end

end

% for peakI = 1:npeaks
%     peak_locs(:, peakI) = fmincon(@(tval) -tcf(tval), peak_est_locs(:, peakI), A, b);
%     peak_vals(peakI) = tcf(peak_locs(:, peakI));
% end
