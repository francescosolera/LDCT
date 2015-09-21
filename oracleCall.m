function [Y_star, H_star] = oracleCall(model, Xi, Yi, Hi)

X = buildMatrix(model, Xi, Hi, true, true, false);
costMatrix = zeros(size(X));

if ~isempty([X{:}])
    costMatrix = reshape(model.w'*[X{:}], size(X, 1), size(X, 2));
end

loss_qt = 1 / sqrt(size(Yi, 1) * size(Yi, 2));

% add loss function terms
for r = 1 : size(costMatrix, 1)
    for c = 1 : size(costMatrix, 2)
        if Yi(r, c) == 0
            costMatrix(r, c) = costMatrix(r, c) + loss_qt;
        else
            costMatrix(r, c) = costMatrix(r, c) - loss_qt;
        end
    end
end

costMatrix = real(costMatrix);

[assignments] = assignmentoptimal_mex(-costMatrix + max(max(costMatrix)));

% construct the association table
Y_star = zeros(size(costMatrix));
for i = 1 : length(assignments)
    if assignments(i) > 0 && i <= size(Y_star, 1) && assignments(i) <= size(Y_star, 2)
        Y_star(i, assignments(i)) = 1;
    end
end

H_star = Hi;

end