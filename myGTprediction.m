function [out] = myGTprediction(data)
out = [];

% data.objectFiles contains data on previous frame pedestrians
% data.detections + data.id contains current frame pedestrians info

% let's start by dividing the occluded objects by the still present ones
POF = objectFile.filterOccludedObjects(data.objectFiles);
OOF = objectFile.getOccludedObjects(data.objectFiles);

% get some number
n_POF = length(POF);
n_OOF = length(OOF);
n_DET = length(data.id);

out = zeros(n_POF + n_OOF + n_DET);

% BLOCK A
for i = 1 : n_POF
    for j = 1 : n_DET
        if POF{i}.realID == data.id(j)
            out(i, j) = 1;
            break;
        end
    end
end

% BLOCK C
for i = 1 : n_POF
    if sum(out(i, :)) == 0
        out(i, n_DET + n_OOF + i) = 1;
    end
end

% BLOCK D
for i = 1 : n_OOF
    for j = 1 : n_DET
        if OOF{i}.realID == data.id(j)
            out(n_POF + i, j) = 1;
            break;
        end
    end
end

% BLOCK E
for i = 1 : n_OOF
    if sum(out(n_POF + i, :)) == 0
        out(n_POF + i, n_DET + i) = 1;
    end
end

% BLOCK G
for j = 1 : n_DET
    if sum(out(:, j)) == 0
        out(n_POF + n_OOF + j, j) = 1;
    end
end

% BLOCK H
for j = 1 : n_OOF
    if sum(out(:, n_DET + j)) == 0
        for i = 1 : n_DET
            if sum(out(n_POF + n_OOF + i, :)) == 0
                out(n_POF + n_OOF + i, n_DET + j) = 1;
                break;
            end
        end
    end
end

% BLOCK I
for j = 1 : n_POF
    if sum(out(:, n_DET + n_OOF + j)) == 0
        for i = 1 : n_DET
            if sum(out(n_POF + n_OOF + i, :)) == 0
                out(n_POF + n_OOF + i, n_DET + n_OOF + j) = 1;
                break;
            end
        end
    end
end

% CHECK THE CONSTRUCTION OF BLOCKS E, H AND I

if ismember(0, sum(out, 2)) || ismember(2, sum(out, 2))
    disp 2;
end

if ismember(0, sum(out, 1)) || ismember(2, sum(out, 1))
    disp 1;
end

end