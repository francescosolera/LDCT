classdef objectFile < handle
    %OBJECTFILE An object file is a location pointer to higher level
    %properties of a target being tracked
    
    properties
        id                      % target identifier
        realID      = -1;       % real identifier, as written on traj.txt
        occluded    = false     % is target occluded?
        forgotten   = false     % is target forgotten?
        history     = []        % keep track of all previous positions
        assigned    = false     % for detections only
        lastFrame   = []        % last frame seen unoccluded
        scene       = []        % RGB last frame
        nextscene   = []        % RGB current frame
        numberOfFP  = 0         % number of false points added by the predictor
        
        % FEATURES
        x                       % x target location (meters)
        y                       % y target location (meters)
        BBw                     % BB width (pixels)
        BBh                     % BB height (pixels)
        presenceHistogram = zeros(1, 8);  % presence histogram
        RGBhistory  = {};
        RGBhistogram  = {};
    end
    
    methods
        function obj = objectFile(detection, id, realID, frame)
            obj.x = detection(1);
            obj.y = detection(2);
            obj.BBw = detection(3);
            obj.BBh = detection(4);
            %obj.history = [frame, obj.x, obj.y, obj.BBw, obj.BBh];
            %
            obj.id = id;
            obj.realID = realID;
            obj.lastFrame = frame;
        end
        
        function newObj = clone(obj)
            newObj = objectFile([0, 0, 0, 0], 0, 0, 0);
            % Construct a new object based on a deep copy of the current
            % object of this class by copying properties over.
            props = properties(obj);
            for i = 1:length(props)
                % Use Dynamic Expressions to copy the required property.
                % For more info on usage of Dynamic Expressions, refer to
                % the section "Creating Field Names Dynamically" in:
                % web([docroot '/techdoc/matlab_prog/br04bw6-38.html#br1v5a9-1'])
                newObj.(props{i}) = obj.(props{i});
            end
        end
        
        function out = isOccluded(obj)
            out = obj.occluded;
        end
        
        function out = isForgotten(obj)
            out = obj.forgotten;
        end
        
        function out = isAssigned(obj)
            out = obj.assigned;
        end
        
        function computePresenceHistogram(obj, objectFiles)
            % presenceHistogram is an 8 bin polar histogram
            % which divides 2pi space starting from 0° at north and by
            % moving in a clockwise manner. Every time an objct is
            % detetcted to fall in a specific region, than a counter is
            % incremented by 3 corresponding to that slice and the nearby
            % regions' counters by 1. The histogram is then normalized.
            obj.presenceHistogram = zeros(1, 8);
            
            for i = 1 : length(objectFiles)
                if obj.id == objectFiles{i}.id, continue; end
                
                x1 = obj.x;             y1 = obj.y;
                x2 = objectFiles{i}.x;  y2 = objectFiles{i}.y;
                
                A = x2-x1;
                O = y2-y1;
                H = sqrt(A^2 + O^2);
                
                code = 2^2*(O/H>0) + 2^1*(A/H>0) + 2^0*(abs(O/H)>abs(A/H));
                decoded = [6, 5, 3, 4, 7, 8, 2, 1];
                
                idx = decoded(code+1);
                idx_p = mod(idx-2, 8) + 1;
                idx_n = mod(idx, 8) + 1;
                
                obj.presenceHistogram(idx) = obj.presenceHistogram(idx) + 3;
                obj.presenceHistogram(idx_p) = obj.presenceHistogram(idx_p) + 1;
                obj.presenceHistogram(idx_n) = obj.presenceHistogram(idx_n) + 1;
            end
            
            % normalize it
            obj.presenceHistogram = obj.presenceHistogram ./ sum(obj.presenceHistogram);
            
            obj.presenceHistogram(isnan(obj.presenceHistogram)) = 0;
        end
        
        function smoothHistory(this, smoothPar)
            
            if size(this.history, 1) < smoothPar, return; end
            
            myData = this.history(end - smoothPar + 1: end, [2 3]);
            %myData(end - (smoothPar-1)/2 + 1, :) = mean(myData, 1);
            this.history(end - (smoothPar-1)/2, [2 3]) = mean(myData, 1);
            
        end
        
        function computeColorHistogram(this, videoPar)
            % set history limit
            history_limit = 30;
            
            % get current scene
            myscene = this.scene;
            if isempty(myscene)
                return
            end
            
            % homograph the coordinates
            data = videoPar.H * [this.x, this.y, 1]';
            data = round(data ./ (eps+repmat(data(3, :), 3, 1)));
            data = data';
            myx = data(1);
            myy = data(2);
            
            % try to crop bounding box corresponding to the object
            w = int32(this.BBw);         h = int32(this.BBh);
            thumb = myscene(max(1, myy - h) : min(myy, size(myscene, 1)), ...
                max(1, myx - w/2) : min(myx + w/2, size(myscene, 2)), :);
            
            % save thumb to history
            n = length(this.RGBhistory);
            if n >= history_limit
                n = 0;
                this.RGBhistory = circshift(this.RGBhistory, [1 1]);
            end
            
            this.RGBhistory{n+1} = thumb;
            
            % compute quantized histogram
            % [~, ~, freq_ly] = image_hist_RGB_3d(thumb, 20, 0.5, 0); % CAREFUL - VERY SLOW!
            freq_ly = imhist3(thumb, 60);

            % unroll it
            this.RGBhistogram{n+1} = freq_ly;
%             this.RGBhistogram{n+1} = [];
%             for i = 1 : size(freq_ly, 3)
%                 this.RGBhistogram{n+1} = [this.RGBhistogram{n+1};...
%                     reshape(freq_ly(:, :, i), size(freq_ly, 1) * size(freq_ly, 2), 1)];
%             end
            
            % normalize it
            this.RGBhistogram{n+1}=this.RGBhistogram{n+1}./sum(this.RGBhistogram{n+1});
        end
        
        function out = computeDistanceFromHistory(this, det, videoPar)
            % det is the detection for which we have to compute how distant
            % it is from this object's history
            
            % first of all we have to make an homography
            data = videoPar.H * [det(1), det(2), 1]';
            data = round(data ./ (eps+repmat(data(3, :), 3, 1)));
            data = data';
            myx = data(1);
            myy = data(2);
            
            % then we should extract the patch
            myscene = this.nextscene;
            w = int32(det(3));         h = int32(det(4));
            thumb = myscene(max(1, myy - h) : min(myy, size(myscene, 1)), ...
                max(1, myx - w/2) : min(myx + w/2, size(myscene, 2)), :);
            
            if isempty(thumb) || isempty(this.RGBhistory)
                out = 0.5; return;
            end
            
            % compute color histogram of thumb
            %[~, ~, freq_ly] = image_hist_RGB_3d(thumb, 20, 0.5, 0);
            freq_ly = imhist3(thumb, 60);
            
            % unroll it
            thumb_histogram = freq_ly;
%             thumb_histogram = [];
%             for i = 1 : size(freq_ly, 3)
%                 thumb_histogram = [thumb_histogram;...
%                     reshape(freq_ly(:, :, i), size(freq_ly, 1) * size(freq_ly, 2), 1)];
%             end
            
            % normalize it
            thumb_histogram = thumb_histogram ./ sum(thumb_histogram);
            
             % finally evaluate mean distance of det from history
            mean_distance = 0;
            for i = 1 : length(this.RGBhistogram)
                % mean_distance = mean_distance + norm(this.RGBhistogram{i} - thumb_histogram, 2);
                % mean_distance = mean_distance + histogram_intersection(this.RGBhistogram{i}', thumb_histogram');
                mean_distance = mean_distance + kullback_leibler_divergence(this.RGBhistogram{i}', thumb_histogram');
            end
            mean_distance = mean_distance / length(this.RGBhistogram);
            
            % PROBLEM: IF AN OBJECT HAS NO PAST, THE MEAN DISTANCE WILL END
            % UP BEING 0, WHICH IS NOT NECESSARILY TRUE...
            
            % do I have to divide by 2, as a single histogram sums up to 1?
            out = min(1, mean_distance/15); %min(1, (1 - exp(-mean_distance)));
        end
        
        function out = computeManifoldSmoothness(this, det)
            % we need to get of an idea of the curved level of det, with
            % respects to its potential neighborhood
            subindex    = @(A,r,c) A(r,c);
            %alpha       = @(val)        exp(val);
            %theta       = @(u, v)       acos(u'*v/(norm(u,2)*norm(v,2)));
            %theta_      = @(J_i, J_j)   min(theta(subindex(null(J_i), :, 1), subindex(null(J_j), :, 1)), pi-theta(subindex(null(J_i), :, 1), subindex(null(J_j), :, 1)));

            % parameters
            sigma_n = 1;
            sigma = 1;
            sigma_c = 0.5;
            worst_value = 0.8;
            
            % robustness
            if size(this.history, 1) < 3; out = worst_value; return; end
            
            myData = [this.history(max(1, end-30) : end, :); [-1 det(1) det(2) det(3) det(4)]];
            J = cell(1, size(myData, 1));
            for i = 1 : size(myData, 1)
                % *) consider just an eps-ball around point i
                m_eps = 1;    % meters
                X_i = zeros(2, size(myData, 1));
                this_idx = 1;
                this_myData = myData(i, [2 3]);
                for j = 1 : size(myData, 1)
                    if i ~= j && (myData(j, [2 3]) - this_myData)*(myData(j, [2 3]) - this_myData)' < m_eps
                        X_i(:, this_idx) = myData(j, [2 3])';
                        this_idx = this_idx + 1;
                    end
                end
                X_i = X_i(:, 1 : this_idx-1);
                
                % check for legality
                if size(X_i, 2) == 0, J{i} = []; continue; end
                    %out = worst_value; return; end
                
                X_i_tilde = X_i - repmat(myData(i, [2 3])', 1, size(X_i, 2));
                
                % *) construct S
                S = zeros(size(X_i_tilde, 2));
                for j = 1 : size(X_i_tilde, 2)
                    S(j, j) = 1 / (sigma_n^2 + sigma^2 * exp(norm(X_i_tilde(:, j), 2)));
                end
                               
                % *) extract the largest d eigenvectors
                T_i = X_i_tilde * (S * S') * X_i_tilde';
                [V, D] = eig(T_i);
                [~, idx] = max(max(D));
                
                J{i} = V(:, idx);
            end
            
            % check for legality
            if isempty(J{end}), out = worst_value; return; end
            
            % compute Ricci curvature (approx)
            R = 0;  n = 0;
            J_j = J{end}';
            sub_J_j = subindex(null(J_j), :, 1);
            for i = 1 : length(J) - 1
                if ~isempty(J{i}) && norm(myData(i, [2 3]) - myData(end, [2 3]), 2) < m_eps
                    J_i = J{i}';
                    sub_J_i = subindex(null(J_i), :, 1);
                    this_theta = acos(sub_J_i'*sub_J_j/(norm(sub_J_i,2)*norm(sub_J_j,2)));
                    R = R + exp(-(min(this_theta, pi-this_theta)) ...
                        / (1 + norm(myData(i, [2 3]) - myData(end, [2 3]), 2)) / sigma_c);
                    n = n + 1;
                end
            end
            
            % normalize
            out = 1 - R / n;
        end
    end
    
    
    
    methods (Static)
        function out = makeObjectFilesFromDetections(varargin)
            detections = varargin{1};
            
            nextID = 1;
            myRealID = varargin{2};
            frame = varargin{3};
            if nargin > 3
                nextID = varargin{2};
                myRealID = varargin{3};
                frame = varargin{4};
            end
            
            out = cell(1, size(detections, 1));
            for i = 1 : length(out)
                out{i} = objectFile(detections(i, :), nextID, myRealID(i), frame);
                nextID = nextID + 1;
            end
        end
        
        function out = filterOccludedObjects(objectFiles)
            out = cell(1, 0);
            idx = 1;
            for i = 1 : length(objectFiles)
                if ~objectFiles{i}.isOccluded
                    out{idx} = objectFiles{i};
                    idx = idx + 1;
                end
            end
        end
        
        function out = getOccludedObjects(objectFiles)
            out = cell(1, 0);
            idx = 1;
            for i = 1 : length(objectFiles)
                if objectFiles{i}.isOccluded && ~objectFiles{i}.isForgotten
                    out{idx} = objectFiles{i};
                    idx = idx + 1;
                end
            end
        end
        
        function out = returnIDXofNotAssociated(objectFiles)
            out = zeros(1, length(objectFiles));
            for i = 1 : length(objectFiles)
                if ~isAssigned(objectFiles{i})
                    out(i) = i;
                end
            end
            out(out==0) = [];
        end
        
        function out = giveMeANewValidID(objectFiles)
            if isempty(objectFiles), out = 1 + floor(1000*rand); return; end
            
            IDs = zeros(1, length(objectFiles));
            for i = 1 : length(objectFiles)
                IDs(i) = objectFiles{i}.id;
            end
            
            out = max(IDs) + 1 + floor(1000*rand);
        end
        
        function out = returnIDs(objectFiles)
            out = zeros(size(objectFiles));
            for i = 1 : length(objectFiles)
                out(i) = objectFiles{i}.id;
            end
        end
        
        function out = returnIDXgivenAnID(objectFiles, ID)
            out = -1;
            for i = 1 : length(objectFiles)
                if objectFiles{i}.id == ID
                    out = i;
                    return
                end
            end
        end
        
        function out = occlude(objectFiles, ID)
            for i = 1 : length(objectFiles)
                if objectFiles{i}.id == ID
                    objectFiles{i}.occluded = true;
                    objectFiles{i}.assigned = false;
                    break;
                end
            end
            
            out = objectFiles;
        end
        
        function out = updateLocation(objectFiles, ID_p, location, frame)
            for i = 1 : length(objectFiles)
                if objectFiles{i}.id == ID_p
                    objectFiles{i}.history = [objectFiles{i}.history; ...
                        [frame, objectFiles{i}.x, objectFiles{i}.y, objectFiles{i}.BBw, objectFiles{i}.BBh]];
                    objectFiles{i}.x = location(1);
                    objectFiles{i}.y = location(2);
                    objectFiles{i}.BBw = location(3);
                    objectFiles{i}.BBh = location(4);
                    objectFiles{i}.lastFrame = frame;
                    
                    break;
                end
            end
            
            out = objectFiles;
        end
        
        function out = updateLocationFromOccluded(objectFiles, ID_p, ID_o, frame)
            for i = 1 : length(objectFiles)
                if objectFiles{i}.id == ID_p, i_p = i; end
                if objectFiles{i}.id == ID_o, i_o = i; end
            end
            
            objectFiles{i_p}.history = [objectFiles{i_p}.history; ...
                [frame, objectFiles{i_p}.x, objectFiles{i_p}.y]];
            objectFiles{i_p}.x = objectFiles{i_o}.x;
            objectFiles{i_p}.y = objectFiles{i_o}.y;
            
            objectFiles(i_o) = [];
            
            out = objectFiles;
        end
        
        function out = updateLocationFromDetection(objectFiles, ID_o, location, frame)
            for i = 1 : length(objectFiles)
                if objectFiles{i}.id == ID_o, i_o = i; break; end
            end
            
            % take it away from the occluded state
            objectFiles{i_o}.occluded = false;
            objectFiles{i_o}.assigned = true;
            
            objectFiles{i_o}.history = [objectFiles{i_o}.history; ...
                [frame, objectFiles{i_o}.x, objectFiles{i_o}.y, objectFiles{i_o}.BBw, objectFiles{i_o}.BBh]];
            objectFiles{i_o}.x = location(1);
            objectFiles{i_o}.y = location(2);
            objectFiles{i_o}.BBw = location(3);
            objectFiles{i_o}.BBh = location(4);
            %
            objectFiles{i_o}.lastFrame = frame;
            
            out = objectFiles;
        end
        
    end
    
    
end