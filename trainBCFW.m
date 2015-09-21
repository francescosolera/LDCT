function [out] = trainBCFW (model, Xi, Yi, Hi, callbacks)

% initialize variables
% // TODO // we'll evenually need to modify this
%w_i = zeros(length(model.w), model.timeWindow);
%l_i = zeros(1, model.timeWindow);
%l = 0;

w_i = zeros(length(model.w), 1);
try w_i = model.w_i; catch; end
l_i = zeros(1, 1);
try l_i = model.l_i; catch; end
%l = 0;

% pick a block at random
%i = ceil(rand*model.timeWindow);
i = size(w_i, 2);


% solve the oracle
%y_hat = callbacks.constraintFn(model, patterns{i}, labels{i});
[Y_hat, H_hat] = callbacks.constraintFn(model, Xi, Yi, Hi);

% find the new best value of the variable
%w_s = 1/model.lambda/model.timeWindow*(callbacks.featureFn(patterns{i}, labels{i}) - callbacks.featureFn(patterns{i}, num2cell(y_hat)));
w_s = 1/model.lambda*(callbacks.featureMapFn(model, Xi, Hi, Yi) - callbacks.featureMapFn(model, Xi, H_hat, Y_hat));
if isempty(w_s); w_s = zeros(length(model.w), 1); end

% also compute the loss at the new point
%l_s = 1/model.timeWindow*callbacks.lossFn(labels{i}, num2cell(y_hat));
l_s = callbacks.lossFn(Yi, Y_hat, H_hat);
if isempty(l_s); l_s = 0; end

% compute the step size
step_size = min(max((model.lambda*(w_i(:, i)-w_s)'*model.w - l_i(i) + l_s) / model.lambda / ...
    ((w_i(:, i)-w_s)'*(w_i(:, i)-w_s)+eps), 0), 1);
if isempty(step_size)
    step_size = 0;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% force to learn something!
if step_size == 0 && l_s > 0
    step_size = 0.01;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% evaluate w_i and l_i
model.w_i(:, end + 1)   = (1 - step_size) * w_i(:, i) + step_size * w_s;
model.l_i(end + 1)      = (1 - step_size) * l_i(i) + step_size * l_s;

% update w and l
model.w = model.w + model.w_i(:, end) - w_i(:, i);
%l = l + l_i_new - l_i(i);

% update w_i and l_i
%w_i(:, i) = w_i_new;
%l_i(i) = l_i_new;

out = model;

end

