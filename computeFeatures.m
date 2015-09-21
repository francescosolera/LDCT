function [out] = computeFeatures(model, ambiguity, OF, det, detOF)

% init feature vector
out = ones(size(model.features, 1), 1);

% create OF for detection
%detOF.x = det(1);
%detOF.y = det(2);

%% THRESHOLD LEARNING
out(1) = 0.1;

if ~ambiguity
%% COMPUTE X SIMILARITY
    out(2) = 1 - abs(OF.x - det(1)) / (model.par.axis(2) - model.par.axis(1));
%% COMPUTE Y SIMILARITY
    out(3) = 1 - abs(OF.y - det(2)) / (model.par.axis(4) - model.par.axis(3));
end

if model.features(4) && ambiguity
    out(4) = exp(-abs(OF.x - det(1)).^2);%(model.par.axis(2) - model.par.axis(1));
end

if model.features(5) && ambiguity
    out(5) = exp(-abs(OF.y - det(2)).^2);%(model.par.axis(4) - model.par.axis(3));
end

if model.features(6) && ambiguity
    %out(6) = 1;
    out(6) = 1 - OF.computeDistanceFromHistory(det, model.par);
    %sum(abs(OF.presenceHistogram - detOF.presenceHistogram)) / 2;
end

if model.features(7) && ambiguity
    out(7) = 1 - OF.computeManifoldSmoothness(det);
end

end