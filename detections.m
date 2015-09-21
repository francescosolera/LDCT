classdef detections < handle
    %DETECTIONS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        rawData
        cursor
        videoPar
    end
    
    methods
        function obj = detections(videoPar, folder)
            % load data
            obj.rawData = load([folder '/trajectories/trajectories' videoPar.trajectoriesID '.txt']);
            obj.rawData = obj.rawData(obj.rawData(:, 1) >= videoPar.startingFrame & obj.rawData(:, 1) <= videoPar.endingFrame, [1 2 3 5 9 10]);
            
            % filter redundant detections
            if 0
                rd = obj.rawData;
                %rd = rd(rd(:, end) < 300, :);
                %rd = rd(rd(:, end) > 60, :);
                rd_conv = rd(:, [3 4 5 6]);
                data = videoPar.H * [rd_conv(:, [1 2]), ones(size(rd_conv, 1), 1)]';
                data = round(data([1 2], :) ./ (eps+repmat(data(3, :), 2, 1)));
                rd_conv(:, [1 2]) = data';
                
                finaldata = zeros(0, size(rd, 2));
                frames = unique(rd(:, 1));
                for i = 1 : length(frames)
                    filteredData = zeros(0, 4);
                    thisdata_original = rd(rd(:, 1) == frames(i), :);
                    thisdata = rd_conv(rd(:, 1) == frames(i), :);
                    takeit = zeros(size(thisdata, 1), 1);
                    for j = 1 : size(thisdata, 1)
                        area_j = rectint(thisdata(j, :), thisdata(j, :));
                        found = 0;
                        for k = 1 : size(filteredData, 1)
                            intersect_jk = rectint(thisdata(j, :), filteredData(k, :));
                            area_k = rectint(filteredData(k, :), filteredData(k, :));
                            
                            if intersect_jk / (area_j+area_k-intersect_jk) > 0.3
                                found = 1;
                            end
                        end
                        if ~found
                            filteredData(end+1, :) = thisdata(j, :);
                            takeit(j) = 1;
                        end
                    end
                    finaldata = [finaldata; thisdata_original(takeit==1, :)];       
                end
                
                obj.rawData = finaldata;
            end
            
            
            % set curson at the beginning of data
            obj.cursor = videoPar.startingFrame;
            
            % save videoPar
            obj.videoPar = videoPar;
        end
        
        function [out, id, frameID] = getCurrentDetections(obj)
            % check whether we can go on serving data
            if obj.cursor > obj.videoPar.endingFrame
                error('No more data to serve...');
            end
            
            % prepare output
            id = obj.rawData(obj.rawData(:, 1) == obj.cursor, 2);
            out = obj.rawData(obj.rawData(:, 1) == obj.cursor, [3 4 5 6]);
            frameID = obj.cursor;
            
            % move pointer to next frame
            obj.cursor = obj.cursor + 1;
        end
        
        function [out] = isempty(obj)
            out = false;
            if obj.cursor > obj.videoPar.endingFrame
                out = true;
            end
        end
    end
    
    methods (Static)
        
        function [out] = downloadCompatibilityList(latentVariables)
            fs = latentVariables.focalSpots;
            q=[fs{:}];
            if isempty(q)
                out = [];
                return
            end
            of=[q.objectFiles];
            det=[q.detections];
            
            out = zeros(length(of), length(det));
            
            for i = 1 : length(fs)
                of = fs{i}.objectFiles;
                det=fs{i}.detections;
                out(of, det) = 1;
            end
        end
        
        function [out] = areCompatible(objIDX, detIDX, latentVariables)
            out = false;
            focalSpots = latentVariables.focalSpots;
            
            for i = 1 : length(focalSpots)
                if ismembc(objIDX, focalSpots{i}.objectFiles)
                    if ismembc(detIDX, focalSpots{i}.detections)
                        out = true;
                    end
                    break;
                elseif ismembc(detIDX, focalSpots{i}.detections)
                    break;
                end
            end
        end
        
        function [out] = returnAmbiguousDetections(det, latentVariables)
            amb = cellfun(@(x) x.isAmbiguous, latentVariables.focalSpots);
            amb = [latentVariables.focalSpots{amb}];
            try, out = [amb.detections]; catch out = []; end
        end
        
        function [out] = isAmbiguous(detIDX, ambiguousFS)
            
            out = false;
            for i = 1 : length(ambiguousFS)
                if ismembc(detIDX, ambiguousFS{i}.detections)
                    out = true;
                    break;
                end
            end
            
            %out = any(cellfun(@(x) ismembc(detIDX, x.detections), latentVariables.focalSpots(amb)));

            %out = any(cellfun(@(x) ismembc(detIDX, x.detections) && x.isAmbiguous, latentVariables.focalSpots));
            
        end
    end
    
end

