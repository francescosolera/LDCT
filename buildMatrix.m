function [costMatrix] = buildMatrix(model, data, latentVariables, cost, oracle, ~)

% put an hard threshold on the distance between object files and detections
m = 1;
threshold_on = true;
threshold_value = 1.5 * m;
numberOfIncreasingFrames = 2;

prebuilt_zeros = zeros(length(model.features)-1, 1);

% cost defines whether the matrix is the cost matrix for the hungarian or
% the feature matrix

previousOF = objectFile.filterOccludedObjects(data.objectFiles);
occludedOF = objectFile.getOccludedObjects(data.objectFiles);
det = data.detections;

ambiguousDet = sort(detections.returnAmbiguousDetections(det, latentVariables));

bigV = Inf;
if cost, bigV = Inf; end
if oracle, bigV = -Inf; end
bigV_vector = [bigV; prebuilt_zeros];
smaV = 1;

% X = [A, B, C; D, E, F; G, H, I];
% X = cell(length(previousOF) + length(occludedOF) + size(det, 1));

% let's fill the fixed parts
blockB = bigV * ones(length(previousOF), length(occludedOF));
if ~any(size(blockB)==0) %&& size(blockB, 2) == 1
    n_row = size(blockB, 1); n_col = size(blockB, 2);
    blockB = blockB(:); blockB = [blockB, repmat(prebuilt_zeros', size(blockB, 1), 1)]';
    blockB = mat2cell(blockB, length(model.features), ones(1, size(blockB, 2)));
    blockB = reshape(blockB, n_row, n_col);
else
    blockB = num2cell(blockB);
end

blockE = bigV * ones(length(occludedOF)) .* (1 - eye(length(occludedOF)));
blockE(isnan(blockE)) = smaV;
if ~any(size(blockE)==0) %&& size(blockE, 2) == 1
    n_row = size(blockE, 1); n_col = size(blockE, 2);
    blockE = blockE(:); blockE = [blockE, repmat(prebuilt_zeros', size(blockE, 1), 1)]';
    blockE = mat2cell(blockE, length(model.features), ones(1, size(blockE, 2)));
    blockE = reshape(blockE, n_row, n_col);
else    
    blockE = num2cell(blockE);
end

blockF = bigV * ones(length(occludedOF), length(previousOF));
if ~any(size(blockF)==0) %&& size(blockF, 2) == 1
    n_row = size(blockF, 1); n_col = size(blockF, 2);
    blockF = blockF(:); blockF = [blockF, repmat(prebuilt_zeros', size(blockF, 1), 1)]';
    blockF = mat2cell(blockF, length(model.features), ones(1, size(blockF, 2)));
    blockF = reshape(blockF, n_row, n_col);
else    
    blockF = num2cell(blockF);
end

blockH = smaV * ones(size(det, 1), length(occludedOF));
if ~any(size(blockH)==0) %&& size(blockH, 2) == 1
    n_row = size(blockH, 1); n_col = size(blockH, 2);
    blockH = blockH(:); blockH = [blockH, repmat(prebuilt_zeros', size(blockH, 1), 1)]';
    blockH = mat2cell(blockH, length(model.features), ones(1, size(blockH, 2)));
    blockH = reshape(blockH, n_row, n_col);
else    
    blockH = num2cell(blockH);
end

blockI = smaV * ones(size(det, 1), length(previousOF));
if ~any(size(blockI)==0) %&& size(blockI, 2) == 1
    n_row = size(blockI, 1); n_col = size(blockI, 2);
    blockI = blockI(:); blockI = [blockI, repmat(prebuilt_zeros', size(blockI, 1), 1)]';
    blockI = mat2cell(blockI, length(model.features), ones(1, size(blockI, 2)));
    blockI = reshape(blockI, n_row, n_col);
else    
    blockI = num2cell(blockI);
end

% to speed up things, instead of always calling areCompatible, we create a
% compatibilityList
compatibilityList = detections.downloadCompatibilityList(latentVariables);
compatibilityList = [compatibilityList; ...
    zeros(length(previousOF) - size(compatibilityList, 1), size(compatibilityList, 2))];

% now let's compute blocks A and D which depends on current scene and
% previous object files as well as on occluded ones. Recall that through
% latentVariables we know influence zones so we don't need to compute
% features for all the different cases
fakeOF = objectFile.makeObjectFilesFromDetections([0 0 0 0], 1, -1, -1);
fakeOF = fakeOF{1};
blockA = cell(length(previousOF), size(det, 1));
for r = 1 : length(previousOF)
    for c = 1 : size(det, 1)
        blockA{r, c} = bigV_vector;
        if compatibilityList(r, c)
            if ~threshold_on || (threshold_on && (norm([previousOF{r}.x previousOF{r}.y] - det(c, [1 2])) < threshold_value))
                ambiguity = ismembc(c, ambiguousDet);
                t = 1*cost +(-1)^(1+~cost) * computeFeatures(model, ambiguity, previousOF{r}, det(c, :), fakeOF);
                t((ambiguity & (model.levels ~= 2 | model.features == 0)) | (~ambiguity & (model.levels ~= 1 | model.features == 0))) = 0;
                blockA{r, c} = t;
            end
        end
    end
end

blockD = cell(length(occludedOF), size(det, 1));
for r = 1 : length(occludedOF)
    % preload to accelerate
    this_x = occludedOF{r}.x;
    this_y = occludedOF{r}.y;
    
    for c = 1 : size(det, 1)
        blockD{r, c} = bigV_vector;
        if ~threshold_on || (threshold_on && (norm([this_x this_y] - det(c, [1 2])) < threshold_value * min(numberOfIncreasingFrames, (data.frame-occludedOF{r}.lastFrame)/2)))
            ambiguity = ismembc(c, ambiguousDet);
            if ambiguity
                t = 1*cost +(-1)^(1+~cost) * computeFeatures(model, ambiguity, occludedOF{r}, det(c, :), fakeOF);
                t((ambiguity & (model.levels ~= 2 | model.features == 0)) | (~ambiguity & (model.levels ~= 1 | model.features == 0))) = 0;
                blockD{r, c} = t;
            end
        end
    end
end

% block C and block G need to be Inf-fixed where there is no sign of
% ambiguity that is - there must be no possibility of miassociating
% something which is not ambiguous.
blockC = bigV * ones(length(previousOF)) .* (1 - eye(length(previousOF)));
blockC(isnan(blockC)) = smaV;
if ~any(size(blockC)==0)
    n_row = size(blockC, 1); n_col = size(blockC, 2);
    blockC = blockC(:); blockC = [blockC, repmat(prebuilt_zeros', size(blockC, 1), 1)]';
    blockC = mat2cell(blockC, length(model.features), ones(1, size(blockC, 2)));
    blockC = reshape(blockC, n_row, n_col);
else    
    blockC = num2cell(blockC);
end
for r = 1 : length(previousOF)
    for c = 1 : size(det, 1)
        if compatibilityList(r, c)
            ambiguity = ismembc(c, ambiguousDet);
            if ~ambiguity
                blockC(r, :) = {bigV_vector};
            end
            break;
        end
    end
end

blockG = (bigV * ones(size(det, 1)) .* (1 - eye(size(det, 1))));
blockG(isnan(blockG)) = smaV;
if ~any(size(blockG)==0)
    n_row = size(blockG, 1); n_col = size(blockG, 2);
    blockG = blockG(:); blockG = [blockG, repmat(prebuilt_zeros', size(blockG, 1), 1)]';
    blockG = mat2cell(blockG, length(model.features), ones(1, size(blockG, 2)));
    blockG = reshape(blockG, n_row, n_col);
else    
    blockG = num2cell(blockG);
end
for c = 1 : size(det, 1)
    for r = 1 : length(previousOF)
        if compatibilityList(r, c)
            ambiguity = ismembc(c, ambiguousDet);
            if ~ambiguity
                blockG(:, c) = {bigV_vector};
            end
            break;
        end
    end
end

costMatrix = [...
    blockA, blockB, blockC;
    blockD, blockE, blockF;
    blockG, blockH, blockI];

end

