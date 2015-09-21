function [ out ] = manageDetections(det)
%MANAGEDETECTIONS transforms the detections prior to tracking

%% BE CAREFUL - MIND THE PARAMETERS
% they have been magically set!

myCase = 3;
% CASE 1 - surrounds tracking
% CASE 2 - mean pruning

% ------------------------------------------------------------------------
if myCase == 1
    n_det = size(det, 1);
    for i = 1 : n_det
        det = [det; ...
            det(i, :) - [0 0.2]; det(i, :) + [0 0.2]];
    end
    % ------------------------------------------------------------------------
elseif myCase == 2
    found_something_to_merge = true;
    while found_something_to_merge
        found_something_to_merge = false;
        
        n_det = size(det, 1);
        [X, Y] = meshgrid(1:n_det, 1:n_det);
        pairs = [X(:), Y(:)];
        
        for i = 1 : size(pairs, 1)
            if pairs(i, 1) ~= pairs(i, 2) && ...
                    norm(det(pairs(i, 1), :) - det(pairs(i, 2), :), 2) < 0.5
                det = [det; (det(pairs(i, 1), :) + det(pairs(i, 2), :)) / 2];
                det([pairs(i, 1), pairs(i, 2)], :) = [];
                
                found_something_to_merge = true;
                break;
            end
        end
        
    end
end

out = det;
