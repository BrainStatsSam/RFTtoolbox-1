function [L, geom] = LKCestim_GaussConv( Y, FWHM, D, resAdd, remove )
% LKCestim_GaussConv( Y, nu, D, resAdd, remove )
% estimates the Lipschitz Killing curvatures for a convolution process.
% It uses the fact that derivatives can be represented as convolutions
% with the derivative kernel.
% Currently, only 1D and 2D are tested and working. Moreover, the domain of
% the field is considered to be a box.
%
% Required additions:
%   - allow voxel dimensions to be different in different directions,
%   currently distance between voxels is assumed to be 1
%   - include mask
%   - add full 3D estimation
%
%--------------------------------------------------------------------------
% ARGUMENTS
%   Y       data array T_1 x ... x T_D x N. Last index enumerates the
%           samples
%   FWHM    array 1x1 or 1xD containing the FWHM for different directions
%           for smoothing with a Gaussian kernel, if numeric an isotropic
%           kernel is assumed
%   mask    boolean array T_1 x ... x T_D indicating which voxels belong to
%           to the region of interest. (not yet implemented!)
%   resAdd  integer denoting the amount of voxels padded between existing
%           voxels to increase resolution
%   remove  (only for theoretical simulations) integer of booundary voxels
%           to remove for estimation. It is used to remove boundary effects
%           in simulations. Default=0. Only touch, if you are simulating
%           theoretical processes.
%--------------------------------------------------------------------------
% OUTPUT
%   L       1xD array of estimated LKCs
%   geom    structure containing geometric quantities of the induced metric
%           of the random field.
%--------------------------------------------------------------------------
% EXAMPLES
% %2D
% rf   = noisegen( [35 35], 50, 6 );
% mask = ones([35 35);
% L = LKCestim_GaussConv( rf, 3, mask, 1 );
% 
% %3D
% thresh = 1;
% sims = randn(10,10,10)
% clusters = clusterloc(sims, thresh);
% sims > thresh
% clusters
%--------------------------------------------------------------------------
% AUTHORS: Fabian Telschow
%--------------------------------------------------------------------------
%------------ get parameters from the random field input ------------------
% Dimension of the input
sY     = size( Y );
% Dimension of the domain
domDim = sY( 1 : end-1 );
% dimension of the domain
D = length( domDim );
% number of samples
nsubj = sY( end );

% compute theoretical LKC on a square without boundary effects
theory = 1;

%------------ check input and set default values --------------------------
if nargin < 5
    remove = 0;
end

% Check mask input (this need to be coded carefully until know only boxes are )
mask = boolean(ones(domDim));


%------------ compute further constants and allocate variables ------------
% stepsize for inbetween voxel resolution increase
dx = 1/(resAdd+1);
% Dimensions for field with increased resolution
domDimhr = ( domDim - 1 ) * resAdd + domDim;
% number of points which needs to be removed from increased resolution
% image, since they don't belong into the estimation regime
remove2 = remove * ( 1 + resAdd);

% allocate vector for Lipschitz Killing curvature
L = NaN * ones( [ 1 length(domDim) ] );
% sturcture to output the different computed fields for debugging purposes
geom = struct();

%------------ estimate the LKCs -------------------------------------------
switch D
    case 1
        % increase the resolution of the raw data by introducing zeros
        Y2 = zeros( [ domDimhr, nsubj ] );
        Y2( 1:(resAdd + 1):end, : ) = Y;
        
        % grid for convolution kernel
        siz = ceil( 4*FWHM2sigma(FWHM) );
        x   = -siz:dx:siz;
        
        % convolution kernel and derivatives to be used with convn
        [ h, dxh ] = Gker( x, FWHM, 1 );     
        
        % get the convolutional field
        smY = convn( Y2', h, 'same' )';
     
        % get the derivative of the convolutional field
        smYx = convn( Y2', dxh, 'same' )';
        
        % get the estimates of the covariances
        VY    = var( smY,  0, D+1 );
        VdxY  = var( smYx, 0, D+1 );
        CYdxY = sum( ( smYx - mean(smYx, D+1) ) .* smY, D+1 ) / (nsubj-1);
                 
        % remove padded values in simulation of generated process to
        % avoid boundary effect
        VY    = VY( (remove2+1):(end-remove2) );
        VdxY  = VdxY( (remove2+1):(end-remove2) );
        CYdxY = CYdxY( (remove2+1):(end-remove2) );
                 
        % get the volume form
        vol_form = sqrt( ( VdxY.*VY - CYdxY.^2 ) ) ./ VY;
        
        % estimate of L1 by integrating volume form over the domain
        L(1) = sum( ( vol_form(1:end-1) + vol_form(2:end) ) ) * dx / 2;
        
        % Fill the output structure
        geom.vol_form = vol_form;
        geom.VY       = VY;
        geom.VdxY     = VdxY;
        geom.CYdxY    = CYdxY;

    case 2
        % increase the resolution of the raw data by introducing zeros
        Y2 = zeros( [ domDimhr, nsubj ] );
        Y2( 1:( resAdd + 1 ):end, 1:( resAdd + 1 ):end, : ) = Y;
        
        % grid for convolution kernel
        siz = ceil( 4*FWHM2sigma(FWHM) );
        [x,y] = meshgrid( -siz:dx:siz, -siz:dx:siz );
        xvals = [x(:), y(:)]';
        
        % convolution kernels to be used ith convn
        h   = reshape( GkerMV( xvals, FWHM ), size(x) );
        dh  = GkerMVderiv( xvals, FWHM );
        dxh = reshape( dh(1,:), size(x) );
        dyh = reshape( dh(2,:), size(x) );
        
        % get the convolutional field
        smY  = convn( Y2, h, 'same' );
        % get the derivative of the convolutional field
        smYx = convn( Y2, dxh, 'same' );
        smYy = convn( Y2, dyh, 'same' );
        
        % Get the estimates of the covariances
        VY   = var( smY,  0, D+1 );
        VdxY = var( smYx, 0, D+1 );
        VdyY = var( smYy, 0, D+1 );
        CdxYdyY = sum( ( smYy - mean( smYy, D+1 ) ) .* ...
                         smYx, D+1 ) / (nsubj-1);
        CYdxY = sum( ( smYx - mean( smYx, D+1 ) ) .* ...
                       smY, D+1 ) / (nsubj-1);
        CYdyY = sum( ( smYy - mean( smYy, D+1 ) ) .* ...
                       smY, D+1 ) / (nsubj-1);
                 
        % entries of riemanian metric
        g_xx = -CYdxY.^2 ./ VY.^2 + VdxY ./ VY;
        g_yy = -CYdyY.^2 ./ VY.^2 + VdyY ./ VY;
        g_xy = -CYdyY .* CYdxY ./ VY.^2 + CdxYdyY ./ VY;
        
        % cut it down to the valid part of the domain
        g_xx = max( g_xx( (remove2 + 1):(end-remove2), (remove2 + 1):(end-remove2) ), 0 );
        g_yy = max( g_yy( (remove2 + 1):(end-remove2), (remove2 + 1):(end-remove2) ), 0 );
        g_xy = g_xy( (remove2 + 1):(end-remove2), (remove2 + 1):(end-remove2) );
        
        % get the volume form, max intorduced for stability
        vol_form = sqrt( max( g_xx.*g_yy - g_xy.*g_xy, 0 ) );
        
        %%%% calculate the Lipschitz killing curvatures
        L(1) = sum(...
                    sqrt(g_xx(1,1:end-1)')     + sqrt(g_xx(1,2:end)') + ...
                    sqrt(g_yy(1:end-1,1))      + sqrt(g_yy(2:end,1) ) + ...
                    sqrt(g_xx(end-1,1:end-1)') + sqrt(g_xx(end-1,2:end)' )+ ...
                    sqrt(g_yy(1:end-1,end-1))  + sqrt(g_yy(2:end,end-1) )...
                   ) * dx / 2 / 2;
        
        % get meshgrid of domain and delaunay triangulation for integration
        % over the domain
        [ Xgrid, Ygrid ] = meshgrid( 1:dx:(sY(1)-2*remove), ...
                                     1:dx:(sY(2)-2*remove) );   
        DT = delaunayTriangulation( [ Xgrid(:), Ygrid(:) ] );
        
        L(2) = integrateTriangulation( DT, vol_form(:) );
        
        % Fill the output structure
        geom.vol_form = vol_form;
        geom.VY       = VY;
        geom.VdxY     = VdxY;
        geom.CYdxY    = CYdxY;
        
        geom.VdyY    = VdyY;
        geom.CYdyY   = CYdyY;
        geom.CYdxY   = CYdxY;
        geom.CdxYdyY = CdxYdyY;
        
        if theory == 1
            % initialize the vector reporting the true LKCs
            trueL = zeros([1 D]);

            % increase the resolution of the raw data by introducing zeros
            onesField = zeros( domDimhr );
            onesField( 1:( resAdd + 1 ):end, 1:( resAdd + 1 ):end ) = 1;

            VY      = convn( onesField, h.^2, 'same' );
            VdxY    = convn( onesField, dxh.^2, 'same' );
            VdyY    = convn( onesField, dyh.^2, 'same' );
            CYdyY   = convn( onesField, dyh.*h, 'same' );
            CYdxY   = convn( onesField, dxh.*h, 'same' );
            CdxYdyY = convn( onesField, dxh.*dyh, 'same' );

            % entries of riemanian metric
            g_xx = -CYdxY.^2 ./ VY.^2 + VdxY ./ VY;
            g_yy = -CYdyY.^2 ./ VY.^2 + VdyY ./ VY;
            g_xy = -CYdyY .* CYdxY ./ VY.^2 + CdxYdyY ./ VY;

            % cut it down to the valid part of the domain
            g_xx = max( g_xx( (remove2 + 1):(end-remove2), (remove2 + 1):(end-remove2) ), 0 );
            g_yy = max( g_yy( (remove2 + 1):(end-remove2), (remove2 + 1):(end-remove2) ), 0 );
            g_xy = g_xy( (remove2 + 1):(end-remove2), (remove2 + 1):(end-remove2) );

            % get the volume form, max intorduced for stability
            vol_form = sqrt( max( g_xx.*g_yy - g_xy.*g_xy, 0 ) );

            %%%% calculate the Lipschitz killing curvatures
            trueL(1) = sum(...
                        sqrt(g_xx(1,1:end-1)')     + sqrt(g_xx(1,2:end)') + ...
                        sqrt(g_yy(1:end-1,1))      + sqrt(g_yy(2:end,1) ) + ...
                        sqrt(g_xx(end-1,1:end-1)') + sqrt(g_xx(end-1,2:end)' )+ ...
                        sqrt(g_yy(1:end-1,end-1))  + sqrt(g_yy(2:end,end-1) )...
                       ) * dx / 2 / 2;

            % get meshgrid of domain and delaunay triangulation for integration
            % over the domain
            [ Xgrid, Ygrid ] = meshgrid( 1:dx:(sY(1)-2*remove), ...
                                         1:dx:(sY(2)-2*remove) );   
            DT = delaunayTriangulation( [ Xgrid(:), Ygrid(:) ] );

            trueL(2) = integrateTriangulation( DT, vol_form(:) );
            
            geom.trueL = trueL;
        end
        
    case 3
        % increase the resolution of the raw data by introducing zeros
        Y2 = zeros( [ domDimhr, nsubj ] );
        Y2( 1:( resAdd + 1 ):end, 1:( resAdd + 1 ):end,...
            1:( resAdd + 1 ):end, : ) = Y;
        
        % grid for convolution kernel
        siz = ceil( 4*FWHM2sigma(FWHM) );
        [x,y,z] = meshgrid( -siz:dx:siz, -siz:dx:siz, -siz:dx:siz );
        xvals = [x(:), y(:), z(:)]';
        
        % convolution kernels to be used ith convn
        h   = reshape( GkerMV( xvals, FWHM ), size(x) );
        dh  = GkerMVderiv( xvals, FWHM );
        dxh = reshape( dh(1,:), size(x) );
        dyh = reshape( dh(2,:), size(x) );
        dzh = reshape( dh(3,:), size(x) );
        
        % get the convolutional field
        smY  = convn( Y2, h, 'same' );
        % get the derivative of the convolutional field
        smYx = convn( Y2, dxh, 'same' );
        smYy = convn( Y2, dyh, 'same' );
        smYz = convn( Y2, dzh, 'same' );
        
        % Get the estimates of the covariances
        VY    = var( smY,  0, D+1 );
        VdxY = var( smYx, 0, D+1 );
        VdyY = var( smYy, 0, D+1 );
        VdzY = var( smYy, 0, D+1 );
        
        CdxYdyY = sum( ( smYy - mean( smYy, D+1 ) ) .* ...
                     ( smYx - mean( smYx, D+1 ) ), D+1 ) / (nsubj-1);
        CdxYdzY = sum( ( smYx - mean( smYx, D+1 ) ) .* ...
                     ( smYz - mean( smYz, D+1 ) ), D+1 ) / (nsubj-1);
        CdyYdzY = sum( ( smYy - mean( smYy, D+1 ) ) .* ...
                     ( smYz - mean( smYz, D+1 ) ), D+1 ) / (nsubj-1);

        CYdxY = sum( ( smYx - mean( smYx, D+1 ) ) .* ...
                     ( smY  - mean( smY,  D+1 ) ), D+1 ) / (nsubj-1);
        CYdyY = sum( ( smYy - mean( smYy, D+1 ) ) .* ...
                     ( smY  - mean( smY,  D+1 ) ), D+1 ) / (nsubj-1);
        CYdzY = sum( ( smYz - mean( smYz, D+1 ) ) .* ...
                     ( smY  - mean( smY,  D+1 ) ), D+1 ) / (nsubj-1);
                 
        % entries of riemanian metric
        g_xx = -CYdxY.^2 ./ VY.^2 + VdxY ./ VY;
        g_yy = -CYdyY.^2 ./ VY.^2 + VdyY ./ VY;
        g_zz = -CYdzY.^2 ./ VY.^2 + VdzY ./ VY;
        g_xy = -CYdyY .* CYdxY ./ VY.^2 + CdxYdyY ./ VY;
        g_xz = -CYdzY .* CYdxY ./ VY.^2 + CdxYdzY ./ VY;
        g_yz = -CYdzY .* CYdyY ./ VY.^2 + CdyYdzY ./ VY;
        
        % cut it down to the valid part of the domain
        g_xx = max( g_xx( (remove2 + 1):(end-remove2), (remove2 + 1):(end-remove2) ), 0 );
        g_yy = max( g_yy( (remove2 + 1):(end-remove2), (remove2 + 1):(end-remove2) ), 0 );
        g_zz = max( g_zz( (remove2 + 1):(end-remove2), (remove2 + 1):(end-remove2) ), 0 );
        g_xy = g_xy( (remove2 + 1):(end-remove2), (remove2 + 1):(end-remove2) );
        g_xz = g_xz( (remove2 + 1):(end-remove2), (remove2 + 1):(end-remove2) );
        g_yz = g_yz( (remove2 + 1):(end-remove2), (remove2 + 1):(end-remove2) );

        % get the volume form, max intorduced for stability
        vol_form = sqrt( max(   g_xx.*g_yy.*g_zz + g_xy.*g_yz.*g_xz + g_xz.*g_xy.*g_yz...
                              - g_xz.*g_yy.*g_xz - g_xy.*g_xy.*g_zz - g_xx.*g_yz.*g_yz, 0 ) );
                          
        if( theory == 1 )
            % get the convolutional field
            smY  = convn( ones(size(Y2)), h, 'same' );
            % get the derivative of the convolutional field
            smYx = convn( Y2, dxh, 'same' );
            smYy = convn( Y2, dyh, 'same' );
            smYz = convn( Y2, dzh, 'same' );

            % Get the estimates of the covariances
            VY    = var( smY,  0, D+1 );
            VdxY = var( smYx, 0, D+1 );
            VdyY = var( smYy, 0, D+1 );
            VdzY = var( smYy, 0, D+1 );

            CdxYdyY = sum( ( smYy - mean( smYy, D+1 ) ) .* ...
                         ( smYx - mean( smYx, D+1 ) ), D+1 ) / (nsubj-1);
            CdxYdzY = sum( ( smYx - mean( smYx, D+1 ) ) .* ...
                         ( smYz - mean( smYz, D+1 ) ), D+1 ) / (nsubj-1);
            CdyYdzY = sum( ( smYy - mean( smYy, D+1 ) ) .* ...
                         ( smYz - mean( smYz, D+1 ) ), D+1 ) / (nsubj-1);

            CYdxY = sum( ( smYx - mean( smYx, D+1 ) ) .* ...
                         ( smY  - mean( smY,  D+1 ) ), D+1 ) / (nsubj-1);
            CYdyY = sum( ( smYy - mean( smYy, D+1 ) ) .* ...
                         ( smY  - mean( smY,  D+1 ) ), D+1 ) / (nsubj-1);
            CYdzY = sum( ( smYz - mean( smYz, D+1 ) ) .* ...
                         ( smY  - mean( smY,  D+1 ) ), D+1 ) / (nsubj-1);

        end
end    
end