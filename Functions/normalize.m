function [xn] = normalize(x_kk,fc,cc,kc,alpha_c)

%normalize
%
%[xn] = normalize(x_kk,fc,cc,kc,alpha_c)
%
%Computes the normalized coordinates xn given the pixel coordinates x_kk
%and the intrinsic camera parameters fc, cc and kc.
%
%INPUT: x_kk: Feature locations on the images
%       fc: Camera focal length
%       cc: Principal point coordinates
%       kc: Distortion coefficients
%       alpha_c: Skew coefficient
%
%OUTPUT: xn: Normalized feature locations on the image plane (a 2XN matrix)
%
%Important functions called within that program:
%
%comp_distortion_oulu: undistort pixel coordinates.

if nargin < 5,
   alpha_c = 0;
   if nargin < 4;
      kc = [0;0;0;0;0];
      if nargin < 3;
         cc = [0;0];
         if nargin < 2,
            fc = [1;1];
         end;
      end;
   end;
end;


% First: Subtract principal point, and divide by the focal length:
x_distort = [(x_kk(1,:) - cc(1))/fc(1);(x_kk(2,:) - cc(2))/fc(2)];

% Second: undo skew
x_distort(1,:) = x_distort(1,:) - alpha_c * x_distort(2,:);

% Third: Compensate for lens distortion:
distortion_model = @(x)(std_dist(x,kc) - x_distort);
if norm(kc) ~= 0,
    % HGM: I have trouble inverting the measurement model for points in
    % the corner of the images, not sure why.  2015-06-14
  	% xn = comp_distortion_oulu(x_distort,kc);
    opts = optimoptions('fsolve','MaxFunEvals',1e4, 'MaxIter', 1e3);
    xn = fsolve(distortion_model, x_distort, opts);
else
    xn = x_distort;
end

end

function xd = std_dist(x, kc)
r = sqrt(sum(x.^2, 1));
dx = [2*kc(3)*x(1,:).*x(2,:) + kc(4)*(r.^2 + 2*x(1,:).^2);
      kc(3)*(r.^2 + 2*x(2,:).^2) + 2*kc(4)*x(1,:).*x(2,:)];
xd = x + repmat((kc(1)*r.^2 + kc(2)*r.^4 + kc(5)*r.^6), 2, 1).*x + dx;
end