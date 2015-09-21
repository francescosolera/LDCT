function [newObjectFiles] = impletion(Dt, id, objectFiles, associations, frame, videoPar)
newObjectFiles = objectFiles;

% retrieve not occluded objects and relative IDs
previousObjectFiles = objectFile.filterOccludedObjects(objectFiles);
previousIDs = objectFile.returnIDs(previousObjectFiles);

% retrieve occluded but not forgotten objects
occludedObjectFiles = objectFile.getOccludedObjects(objectFiles);
occludedIDs = objectFile.returnIDs(occludedObjectFiles);

% define final IDs and shape matrix
IDs_row = [previousIDs, occludedIDs];

n_obj = length(previousObjectFiles);

%% UPDATE PERSISTENT OBJECTS
blockA = associations(1:n_obj, :);
[r, c] = find(blockA==1);
for i = 1 : length(r)
    newObjectFiles = objectFile.updateLocation(newObjectFiles, ...
        IDs_row(r(i)), Dt(c(i), :), frame);
end

%% REVIVE OCCLUDED OBJECTS FROM NEW DETECTIONS
blockD = associations(n_obj+1:end, :);
[r, c] = find(blockD==1);
for i = 1 : length(r)
    newObjectFiles = objectFile.updateLocationFromDetection(newObjectFiles,...
        IDs_row(n_obj+r(i)), Dt(c(i), :), frame);
end

%% OCCLUDE UNASSOCIATED OBJECTS
% block C
idxs = sum(blockA, 2) == 0;
for i = 1 : length(idxs)
    if idxs(i)
        newObjectFiles = objectFile.occlude(newObjectFiles, IDs_row(i));
    end
end

%% CREATE OBJECTS FOR UNASSOCIATED DETECTIONS
idxs = sum(associations, 1) == 0;
cursor = length(newObjectFiles) + 1;
for i = 1 : length(idxs)
    if idxs(i)
        newObjectFiles(cursor) = ...
            objectFile.makeObjectFilesFromDetections(Dt(i, :), ...
            objectFile.giveMeANewValidID(newObjectFiles), id(i), frame);
        cursor = cursor + 1;
    end;
end

%%	FEATURES
% since correspondance used only filtered objects, in latentVariables we
% only have pointers to this array, not to the original one. So in order to
% be able to properly index objectFiles, we first have to get non occluded
% objects IDs and then, by indexing this array with latentVariables, get
% the index of a specific item in objectList by its ID
filteredObjectFiles = objectFile.filterOccludedObjects(newObjectFiles);
IDs = objectFile.returnIDs(filteredObjectFiles);

% update the features of the not-occluded objects in the scene
for j = 1 : length(filteredObjectFiles)
    idx = objectFile.returnIDXgivenAnID(newObjectFiles, IDs(j));
    % newObjectFiles{idx}.computePresenceHistogram(filteredObjectFiles);
    newObjectFiles{idx}.computeColorHistogram(videoPar);
end


%% smooth trajectories for non occluded objects
smoothPar = 5;
IDs_n = objectFile.returnIDs(newObjectFiles);
for j = 1 : length(newObjectFiles)
    idx = objectFile.returnIDXgivenAnID(newObjectFiles, IDs_n(j));
    newObjectFiles{idx}.smoothHistory(smoothPar);
end


%% CHECK WHETHER OCCLUDED OBJECTS NEED TO BE DELETED
global alltracks;

occludedLifeSpan = 10;
falsePointsLimit = 3; % percentage of true detection on trajectory

changed = true;
while changed
    changed = false;
    for i = 1 : length(newObjectFiles)
        if newObjectFiles{i}.isOccluded &&...
                newObjectFiles{i}.lastFrame + occludedLifeSpan < frame
            
            % keep the track only if it was "pure" enough - made from true
            % detections and not based mostly on predictions
            if (size(newObjectFiles{i}.history, 1) - newObjectFiles{i}.numberOfFP) > falsePointsLimit
                %newObjectFiles{i}.history = ...
                %     [newObjectFiles{i}.history; [newObjectFiles{i}.lastFrame+1 newObjectFiles{i}.x newObjectFiles{i}.y newObjectFiles{i}.BBw newObjectFiles{i}.BBh]];
                alltracks = [alltracks; newObjectFiles(i)];
            end
            newObjectFiles(i) = [];
            changed = true;
            break;
        end
    end
end

end