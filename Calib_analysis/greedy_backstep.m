function greedy_backstep(varargin)
% This function runs a greedy backstepping analysis of a large
% camera calibration set of images.  The goal is to determine how a
% calibration's error grows as the number of images used is reduced.
% The approach is: Given a set of N calibration images, calibrate based
% on each of the N subsets of (N-1) images, leaving out a different
% image each time.  Find the calibration with the lowest error.  The
% image that was omitted is, in a sense, the "least useful" image of the
% N-set.  Remove it, and restart the process on the new (N-1) set,
% calibrating for each (N-2)-image subset.  In this way, we can find a
% "minimal calibration set" which represents the most useful images.
%
% GREEDY_BACKSTEP  Analyze subsets of a large calibration set.  The
%   calibration input file must have been generated via the CalTech
%   Camera Calibration Toolbox, as a number of its variable names are
%   used.
%    
%   greedy_backstep(calib_filename) reads the specified filename (often
%   Calib_Results.mat) and uses default values for all inputs, see below.
%
%   greedy_backstep(calib_filename, input_p) allows selection of the
%   following controlling parameters:
%     input_p.err_metric = 'norm_kc_error' (or 'max_ere')
%     input_p.stop_err = inf (or # > 0 for error-based termination)
%       (when all the calib errors are above this value, terminate)
%     input_p.min_images = 5 (or any number 1 <= # <= N)
%     input_p.parallel = 1 (or 0 if single-thread desired)
%     input_p.fisheye = 0 (0 uses standard model, 1 uses fisheye)
%     input_p.save_subset_calibrations = 0 (1 saves all intermed calibs
%       for later analysis)
%     input_p.save_filename = 'greedy_backstep' (filename into which to
%       save the err_mat matrix.  Also used as prefix for subset
%       calibration files if above flag is set)
    
narginchk(1,2);

calib_filename = varargin{1};
if nargin > 1
    input_p_in = varargin{2};
else
    input_p_in = struct();
end

default_p.err_metric = 'norm_kc_error';
default_p.stop_err = inf;
default_p.min_images = 5;
default_p.parallel = 1;
default_p.fisheye = 0;
default_p.save_subset_calibrations = 0;
default_p.save_filename = 'greedy_backstep';

input_p = populate_struct_with_defaults(input_p_in, default_p);
input_p.calib_filename = calib_filename;
active_images = [0 0 0]; % a dummy value, will be overwritten
load(calib_filename);

if input_p.parallel ~= 0
    mypool = parpool('local');
end

err_mat = NaN(length(active_images), length(active_images)-input_p.min_images);
min_err_val = 0;
while (min_err_val < input_p.stop_err) && (sum(active_images) > input_p.min_images)  
    % Calc all the leave-one-out subsets
    calib_err = NaN(sum(active_images), 1); % local err copy
    num_active = sum(active_images);
    ndx_act = find(active_images);

    % Run calibrations on all subsets
    if input_p.parallel ~= 0
        parfor omit_ctr = 1:num_active
            calib_err(omit_ctr) = subset_calib(input_p, active_images, ndx_act(omit_ctr));
        end
    else
        for omit_ctr = 1:num_active
            calib_err(omit_ctr) = subset_calib(input_p, active_images, ndx_act(omit_ctr));
        end
    end

    % Record errors in err_mat
    col_ndx = (length(active_images)-length(calib_err))+1;
    err_mat(find(active_images), col_ndx) = calib_err;
    
    % Sort the resulting errors
    [min_err_val, min_err_ndx] = min(err_mat(:, col_ndx));
    % Omit the image with the least effect
    active_images(min_err_ndx) = 0;
end

% Save the err_mat result
save(input_p.save_filename, 'err_mat');

if input_p.parallel ~= 0
    delete(mypool);
end

end % function greedy_backstep

function err_val = subset_calib(input_p, active_images_in, omit_ndx)
% Set up the subset calibration
load(input_p.calib_filename);
active_images = active_images_in; % Change active image set
active_images(omit_ndx) = 0; % Omit the desired image

% Run the calibration
if input_p.fisheye == 1
    go_calib_optim_fisheye_no_read;
else
    go_calib_optim;
end

% Compute the error
if strcmp(input_p.err_metric, 'max_ere')
    % HGM TODO
    % ctx = [f; cc; alpha_c; k]; % Compile the param vector
    % sigctx = [fc_error; cc_error; alpha_c_error; kc_error]; % param uncertainty
    % calib_error = calc_max_ere(ctx, sigctx); % Calc error
    err_val = omit_ndx; % temporary, fixme
elseif strcmp(input_p.err_metric, 'norm_kc_error')
    err_val = norm(kc_error);
end

if input_p.save_subset_calibrations == 1
    clear I_*;
    save([input_p.save_filename, '_', num2str(sum(active_images_in)-1), 'img_omit', ...
          num2str(omit_ndx)]); 
end
end % function subset_calib
