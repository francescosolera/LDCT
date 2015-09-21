function model = mainCMTT(myfolder, istraining, model, showresults)
%function [model, alltracks_out] = mainCMTT(myfolder, istraining, model, showresults)

model.training = istraining;

if model.training
    mystring = '_deg';
else
    mystring = '_MOTchallenge';
end

pars.w = model.w;
pars.showResult = showresults;

addpath(genpath('./CCMatlab'));

global alltracks;
alltracks = [];

%% LOAD PARAMETERS, DATA and INITIALIZE TRACKER OBJECT FILES
folder = myfolder;
run([folder '/loadPar.m']);

% run
videoPar.trajectoriesID = mystring;

% load detections
data.allDetections = detections(videoPar, folder);

[mydata, id, ~] = data.allDetections.getCurrentDetections;
data.objectFiles = objectFile.makeObjectFilesFromDetections(mydata, id, data.allDetections.cursor - 1);
data.isempty = false;

%% FEATURES EMPLOYED IN THE TRACKING
% w(1)      - zero level feature: threshold
% w(2:3)    - first level features: displacements
% w(4:7)    - second level features: displacements, appearence, smoothness

model.w     = pars.w;
model.w_i   = zeros(length(model.w), 1);
model.l_i   = 0;

model.lambda        = 5;
model.par           = videoPar;
model.features      = [1 1 1 1 1 1 1]';
model.levels        = [0 1 1 2 2 2 2]';
model.showResult    = pars.showResult;
model.folder        = folder;

% other callbacks
callbacks.input             = @prepareInput;

% latent framework callbacks
callbacks.latentCompletion  = @correspondance;
callbacks.predict           = @review;
callbacks.train             = @trainBCFW;

% structural SVM callbacks
callbacks.constraintFn      = @oracleCall;
callbacks.featureMapFn      = @featureMap;
callbacks.lossFn            = @lossFunction;

%% INITIALIZE THE LEARNER
[data]                  = callbacks.input(data);

dataset{1}.objectFiles = {};
for i = 1 : length(data.objectFiles)
    dataset{1}.objectFiles{i} = data.objectFiles{i}.clone;
end

[data]                  = callbacks.predict(model, data, callbacks);

dataset{1}.frame        = data.frame;
dataset{1}.detections   = data.detections;
dataset{1}.id           = data.id;
dataset{1}.prediction   = data.prediction;
dataset{1}.w            = model.w;

%% MAIN LOOP
while ~data.isempty
    
    %% -1- LATENT COMPLETION
    % find the H that best explain X_i Y_i with current w_i
    Xi.objectFiles      = dataset{end}.objectFiles;
    Xi.detections       = dataset{end}.detections;
    Xi.frame            = dataset{end}.frame;
    Yi                  = dataset{end}.prediction;
    
    [latentVariables]   = callbacks.latentCompletion(model, Xi, Yi);
    
    %% -2- TRAINING
    % train the learner through the newly added example
    if model.training
        mymodel = callbacks.train(model, Xi, Yi, latentVariables, callbacks);
        w = mymodel.w; w_i = mymodel.w_i; l_i = mymodel.l_i;
        
        if 1 && sum(w<0) == 0 && all(~isnan(w)) && all(~isinf(w)) && all(isreal(w)), ...
                model.w = w; model.w_i = w_i; model.l_i = l_i; else disp '*'; end

        fprintf('w (%s): %s\n', num2str(data.frame), mat2str(round(model.w * 100)/100));
    else
        fprintf('%s\n', num2str(data.frame));
    end
    
    %% -3- PREDICT NEW EXAMPLE
    [data]	= callbacks.input(data);
    
    dataset{end+1}.objectFiles = {};
    for i = 1 : length(data.objectFiles)
        dataset{end}.objectFiles{i} = data.objectFiles{i}.clone;
    end
    
    dataset{end}.detections     = data.detections;
    dataset{end}.id             = data.id;
    dataset{end}.frame          = data.frame;
    dataset{end}.w              = model.w;
    
    [data] = callbacks.predict(model, data, callbacks);
    dataset{end}.prediction     = data.prediction;
    
    % add kalman detections
    numberofp = 5;
    predictDelay = 3;
    if 1
        occludedObjectFiles = objectFile.getOccludedObjects(data.objectFiles);
        occludedIDs = objectFile.returnIDs(occludedObjectFiles);
        for j = 1 : length(occludedObjectFiles)
            idx = objectFile.returnIDXgivenAnID(occludedObjectFiles, occludedIDs(j));
            
            if size(occludedObjectFiles{idx}.history, 1) > numberofp + predictDelay
                
                pos = occludedObjectFiles{idx}.history(end - numberofp + 1 - predictDelay: end - predictDelay, [2 3]);
                meanVel = pos - circshift(pos, +1);
                meanVel = mean(meanVel(2:end, :), 1);
                thisPos = [occludedObjectFiles{idx}.x, occludedObjectFiles{idx}.y] + 0.2 .* meanVel;
                
                all_idx = objectFile.returnIDXgivenAnID(data.objectFiles, occludedIDs(j));
                data.objectFiles{all_idx}.history(end+1, :) = [data.frame data.objectFiles{all_idx}.x data.objectFiles{all_idx}.y data.objectFiles{all_idx}.BBw data.objectFiles{all_idx}.BBh];
                data.objectFiles{all_idx}.x = thisPos(1);
                data.objectFiles{all_idx}.y = thisPos(2);
                data.objectFiles{all_idx}.numberOfFP = data.objectFiles{all_idx}.numberOfFP + 1;
            end
        end
    end
    
    % show influence zones
    if model.showResult, plot4debug(model, dataset{end-1}, latentVariables); end
end

end