function [out] = focalSpots(influenceMap, dimensions)

out = {};
    
if dimensions(1) == 0 || dimensions(2) == 0
    return
end

map = influenceMap(1:dimensions(1), 1:dimensions(2));

% squeeze columns
detections_cols=cell(1, size(map, 2));
for i = 1 : size(map, 2)
    detections_cols{i} = i;
end

for i = 1 : size(map, 2)
    if sum(map(:, i)) == 0
        detections_cols{i} = [];
        continue;
    end
    for j = i + 1 : size(map, 2)
        if isequal(map(:, i), map(:, j))
            map(:, j) = zeros(size(map(:, j)));
            detections_cols{i} = [detections_cols{i}, j];
            detections_cols{j} = [];
        end
    end
end

idx = sum(map, 1)==0;
detections_cols(idx) = [];
map(:, idx) = [];

% squeeze rows
detections_rows=cell(1, size(map, 1));
for i = 1 : size(map, 1)
    detections_rows{i} = i;
end

for i = 1 : size(map, 1)
    if sum(map(i, :)) == 0
        detections_rows{i} = [];
        continue;
    end
    for j = i + 1 : size(map, 1)
        if isequal(map(i, :), map(j, :))
            map(j, :) = zeros(size(map(j, :)));
            detections_rows{i} = [detections_rows{i}, j];
            detections_rows{j} = [];
        end
    end
end

idx = sum(map, 2)==0;
detections_rows(idx) = [];
map(idx, :) = [];

influenceGroups = cell(1, length(detections_rows));
for i = 1 : length(detections_rows)
    influenceGroups{i}.objectFiles = detections_rows{i};
    influenceGroups{i}.detections = detections_cols{find(map(i, :)==1)};
end

% we want to add the influence groups where we have at least a detection
% but no object
lonedet = find(sum(influenceMap, 1)==0);

for i = 1 : length(lonedet)
    influenceGroups{end+1}.objectFiles = [];
    influenceGroups{end}.detections = lonedet(i);
end

out = influenceGroups;
end