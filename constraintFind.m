function [Y_hat] = constraintFind(model, X, Y)

% adapt to code
w = model.w;

% prepare the cost matrix
costMatrix = zeros(size(X));
for i = 1 : size(costMatrix, 1)
    for j = 1 : size(costMatrix, 2)
        costMatrix(i, j) = (1 - Y{i, j}) + w' * X{i, j};
    end
end

% run the hungarian
[assignments, ~] = munkres(-costMatrix);

% construct the most violated association table
Y_hat = zeros(size(Y));
for i = 1 : length(assignments)
    if assignments(i) > 0 && i <= size(Y_hat, 1) && assignments(i) <= size(Y_hat, 2)
        Y_hat(i, assignments(i)) = 1;
    end
end

end

