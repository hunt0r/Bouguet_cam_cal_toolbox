function max_ere = calc_max_ere(k, sigk, std_or_fisheye)
% inputs: k = parameter vector [fc; cc; alpha_c; kc] (mean)
%         sigk = parameter vector uncertainty (1 std deviation)
%         std_or_fisheye = 'std' or 'fisheye' to select model

% function parameters
n = 5e4;
nx = 1280; % image horizontal resolution 
ny = 720; % image vertical resolution
numx = 5; % number of testpoints in horizontal direction
numy = 5; % number of testpoints in vertical direction

% testgrid: specify where you'd like the points on the image in image
% coordinates, i.e. with (0,0) as the center of the top left pixel,
% (nx-1,0) as the center of the top right pixel, and (0,ny-1) in the
% center of the bottom left pixel.
%[tgx, tgy] = meshgrid(linspace(0, (nx-1), 5), linspace(0, (ny-1), 5));
[tgx, tgy] = meshgrid(linspace(0, (nx-1), numx), linspace(0, (ny-1), numy));
testgrid = [reshape(tgx, 1, []);
            reshape(tgy, 1, [])];
% Invert the mean camera model to specify XYZ coords of testgrid points
if strcmp(std_or_fisheye, 'std')
    XY = normalize(testgrid, k(1:2), k(3:4), k(6:10), k(5));
elseif strcmp(std_or_fisheye, 'fisheye')
    XY = normalize_pixel_fisheye(testgrid, k(1:2), k(3:4), k(6:9), k(5));
else
    error(['Invalid value for std_or_fisheye: ', std_or_fisheye])
end
XYZ = [      XY;
       ones(1, size(XY,2))]; % set Z=1 always

% gaussian distribution of parameter uncertainty
calSamples = randn(numel(k),n).*repmat(sigk,1,n) + repmat(k,1,n);

if strcmp(std_or_fisheye, 'std')
    [xy,~,~,~,~,~,~] = project_points2(XYZ, [0 0 0]', [0 0 0]', ...
                                   k(1:2), k(3:4), k(6:10), k(5));
else % fisheye
    [xy,~,~,~,~,~,~] = project_points_fisheye(XYZ, [0 0 0]', [0 0 0]', ...
                                   k(1:2), k(3:4), k(6:9), k(5));
end

% Map the XYZ points through every calSample    
xy_n = zeros(2, size(XYZ,2), size(calSamples, 2));
for cal = 1:size(calSamples, 2)
    k_n = calSamples(:, cal);
    if strcmp(std_or_fisheye, 'std')
        [xy_n(:,:,cal),~,~,~,~,~,~] = project_points2(XYZ, [0 0 0]', [0 0 0]', ...
                                   k_n(1:2), k_n(3:4), k_n(6:10), k_n(5));
    else %fisheye
        [xy_n(:,:,cal),~,~,~,~,~,~] = project_points_fisheye(XYZ, [0 0 0]', [0 0 0]', ...
                                   k_n(1:2), k_n(3:4), k_n(6:9), k_n(5));
    end
end
% figure
% scatter(xy(1,:), -xy(2,:), 'o')
% hold on
% plot([0 nx nx 0 0], -[0 0 ny ny 0], 'k:')
% axis image

% figure
% scatter(reshape(xy_n(1,:,:), 1, []), -reshape(xy_n(2,:,:), 1, []), '^');
% hold on
% plot([0 nx nx 0 0], -[0 0 ny ny 0], 'k:')
% axis image

% Compute the ERE
ere_mat = (1/n)*sum(abs(xy_n - repmat(xy, 1, 1, size(calSamples,2))),3);
max_ere = max(max(ere_mat));

end % function calc_max_ere