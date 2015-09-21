function [out] = featureMap(model, Xi, Hi, Y)

X = buildMatrix(model, Xi, Hi, false, false, true);

out = sum([X{Y==1}], 2);

if isempty(out) && ~isempty(X)
    out = zeros(size(X{1,1}));
end

end