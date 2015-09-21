function [loss] = lossFunction(Yi, Y, H)

n_p = size(H.associations, 1);
n_d = size(H.associations, 2);
n_o = size(Yi, 1) - n_p - n_d;

Yi_ = Yi(1:n_p+n_o, 1:n_d);
Y_  = Y(1:n_p+n_o, 1:n_d);

loss = ((1 - Yi_(:))'*Y_(:) + (Yi_(:))'*(1 - Y_(:))) / sqrt(size(Y_, 1) * size(Y_, 2));

if isempty(loss)
    loss = 0;
end

end