function latentVariables = correspondance(model, X, Y)

Dt = X.detections;
objectFiles = objectFile.filterOccludedObjects(X.objectFiles);

%% prepare the cost matrix
bigValue = Inf;
tresholdValue = 0.045; % orig 0.05

% costMatrix = [blockA, blockB; blockC, blockD];
fakeOF = objectFile.makeObjectFilesFromDetections([0 0 0 0], 1, -1, -1);
fakeOF = fakeOF{1};
blockA = zeros(length(objectFiles), size(Dt, 1));
my_w = [0; model.w(2:3); zeros(length(model.features) - 3, 1)]';
for i = 1 : size(blockA, 1)
    for j = 1 : size(blockA, 2)
        blockA(i, j) = ...
            my_w * ...
            (1 - computeFeatures(model, 0, objectFiles{i}, Dt(j, :), fakeOF));
    end
end

% augment cost matrix to avoid teleportation (par may need to be adj)
blockB = (bigValue * ones(size(blockA, 1)) .* (1 - eye(size(blockA, 1))));
blockC = (bigValue * ones(size(blockA, 2)) .* (1 - eye(size(blockA, 2))));
blockD = tresholdValue*ones(fliplr(size(blockA)));

augmentedCostMatrix = [...
    blockA, blockB;
    blockC, blockD];

augmentedCostMatrix(isnan(augmentedCostMatrix)) = tresholdValue;

%% run the hungarian
[assignments, ~] = assignmentoptimal_mex(augmentedCostMatrix);

% construct the association table
Y_classic = zeros(size(augmentedCostMatrix));
for i = 1 : length(assignments)
    if assignments(i) > 0 && i <= size(Y_classic, 1) && assignments(i) <= size(Y_classic, 2)
        Y_classic(i, assignments(i)) = 1;
    end
end

if isempty(Y)
    Y = Y_classic;
    Y_classic = [];
else
    Y_classic = Y_classic(1:size(blockA, 1), 1:size(blockA, 2));
end

latentVariables.associations = Y(1:size(blockA, 1), 1:size(blockA, 2));


%% decide which associations may be ambiguous and define relative groups
try
    latentVariables.influenceMap = influenceMap4(augmentedCostMatrix, latentVariables.associations, Y_classic);
catch
    latentVariables.influenceMap = influenceMap2(augmentedCostMatrix, latentVariables.associations, Y_classic);
end
latentVariables.focalSpots = focalSpots(...
    latentVariables.influenceMap, size(latentVariables.associations));

%% AMBIGUITY DETECTION!
% we classify something ambiguous if in its influence area we cannot
% reconstruct all the previous prediction!
% By doing so, we are implicitly considering ambiguous all the influence
% areas that have different #OF and #det. But we are adding cases were the
% same number of OF and det let this function miss unreproducible
% predictions.
for i = 1 : length(latentVariables.focalSpots)
    latentVariables.focalSpots{i}.isAmbiguous = false;
%    latentVariables.focalSpots{i}.isAmbiguous = true;
    
     submatrix = Y(latentVariables.focalSpots{i}.objectFiles, latentVariables.focalSpots{i}.detections);
     if sum(sum(submatrix)) < max(size(submatrix))
         latentVariables.focalSpots{i}.isAmbiguous = true;
     end
end


end