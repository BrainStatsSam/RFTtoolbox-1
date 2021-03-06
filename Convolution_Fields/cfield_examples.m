%% Smoothing with increased resolution
nvox = 100; xvals = 1:nvox;
xvals_fine = 1:0.01:nvox;
FWHM = 3;
lat_data = normrnd(0,1,1,nvox);
cfield = inter_conv1D( lat_data, FWHM, 0.01);
plot(xvals_fine,cfield)
hold on
smooth_data = convfield( lat_data, FWHM, 0.01, 1);
plot(xvals_fine,smooth_data + 0.5)

%% Smoothing with the same resolution
lat_data = normrnd(0,1,1,nvox);
cfield = spm_conv(lat_data, FWHM);
plot(xvals,cfield)
hold on
smooth_data = convfield( lat_data', FWHM, 1, 1 );
plot(xvals, smooth_data)

%% Multiple subjects
nsubj = 3;
lat_data = normrnd(0,1,nvox,nsubj);
cfield = spm_conv(lat_data(:,1), FWHM);
plot(1:nvox,cfield)
hold on
smooth_data = convfield( lat_data, FWHM, 1, 1 );
plot(1:nvox,smooth_data(:,1))

%% 1D derivatives
lat_data = normrnd(0,1,nvox,1);
h = 0.01;
smoothedfield = convfield( lat_data, FWHM, h, 1);
deriv1 = convfield( lat_data, FWHM, h, 1, 1 );
deriv2 = diff(smoothedfield)/h;
plot(xvals_fine, deriv1 + 0.5)
hold on 
plot(xvals_fine(1:end-1), deriv2)

%% 2D
Dim = [50,50];
lat_data = normrnd(0,1,Dim)
cfield = spm_conv(lat_data, FWHM)
surf(cfield)
smooth_data = convfield( lat_data, FWHM, 0, 0, 1)
surf(smooth_data)

%% 2D derivatives
derivfield = convfield( lat_data, FWHM, 0, 1, 1)
surf(reshape(derivfield(1,:), Dim))
resAdd = 100;
smoothfield100 = convfield( lat_data, FWHM, resAdd, 0, 1);
derivfield100 = convfield( lat_data, FWHM, resAdd, 1, 1);
point = [500,500]
((smoothfield100(point(1), point(2) + 1) - smoothfield100(point(1),point(2)))/(1/(resAdd +1)))
((smoothfield100(point(1)+1, point(2)) - smoothfield100(point(1),point(2)))/(1/(resAdd +1)))
derivfield100(:,point(1), point(2))
% note that it's still not perfect because it's still a discrete
% approximation, but that's why we want to use derivfield in the first
% place!!
