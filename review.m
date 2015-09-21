function [data, oldObjectFiles] = review(model, data, callbacks)
oldObjectFiles = [];

% guess latent variables
[latentVariables]   = callbacks.latentCompletion(model, data, []);

%% PREPARE INPUT AND OUTPUT DATA STRUCTURES
% retrieve not occluded objects and relative IDs (same of latentVariables)
previousObjectFiles = objectFile.filterOccludedObjects(data.objectFiles);
% retrieve occluded but not forgotten objects
occludedObjectFiles = objectFile.getOccludedObjects(data.objectFiles);
% create objectFiles for current detections
detectedObjectFiles = objectFile.makeObjectFilesFromDetections(data.detections, -1, -ones(length(data.detections), 1), -1);

% define final IDs and shape matrix
costMatrix = [];

X = buildMatrix(model, data, latentVariables, true, false, false);

if ~isempty([X{:}])
    costMatrix = reshape(model.w'*[X{:}], size(X, 1), size(X, 2));
end
costMatrix(costMatrix<0) = 0;
[assignments] = assignmentoptimal_mex(costMatrix);

% construct the association table
Y_hat = zeros(size(costMatrix));
for i = 1 : length(assignments)
    if assignments(i) > 0 && i <= size(Y_hat, 1) && assignments(i) <= size(Y_hat, 2)
        Y_hat(i, assignments(i)) = 1;
    end
end

if model.training
    Y_hat = myGTprediction(data);
end

% update prediction matrix
data.prediction = Y_hat;
croppedPrediction = data.prediction(...
    1:length(previousObjectFiles)+length(occludedObjectFiles),...
    1:length(detectedObjectFiles));

%% SUBSTITUTE PREDICTION WITH GT

%% -3- IMPLETION
try
    video = imread([model.folder '/images/' sprintf('%06d.jpg', data.frame)]);
    videonext = imread([model.folder '/images/' sprintf('%06d.jpg', data.frame+1)]);
catch
    try
        video = imread([model.folder '/images/' sprintf('%06d.jpeg', data.frame)]);
        videonext = imread([model.folder '/images/' sprintf('%06d.jpeg', data.frame+1)]);
    catch
        video = imread([model.folder '/images/' sprintf('%06d.png', data.frame)]);
        videonext = imread([model.folder '/images/' sprintf('%06d.png', data.frame+1)]);
    end
end

for i = 1 : size(data.objectFiles, 2)
    data.objectFiles{i}.scene = video;
    data.objectFiles{i}.nextscene = videonext;
end

[objectFiles] = impletion(data.detections, data.id, data.objectFiles, croppedPrediction, data.frame, model.par);

data.objectFiles = objectFiles;

if model.showResult
    plotTracking(model.par, model.folder, data.objectFiles, data.frame);
end

end