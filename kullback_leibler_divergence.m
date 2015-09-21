function d=kullback_leibler_divergence(XI,XJ)
  
  
  m=size(XJ,1); % number of samples of p
  p=size(XI,2); % dimension of samples
  
  assert(p == size(XJ,2)); % equal dimensions
  assert(size(XI,1) == 1); % pdist requires XI to be a single sample
  
  d=zeros(m,1); % initialize output array
  
  XI_idxs = XI(XI ~= 0);
  
  for i=1:m
      d(i) = XI_idxs * log(XI_idxs / (XJ(i) + eps))';
%     for j=1:p
% 			if XI(j) ~= 0
%                 % XJ is the model! makes it possible to determine each "likelihood" that XI was drawn from each of the models in XJ
% 				d(i,1) = d(i,1) + (XI(j) * log(XI(j) / (XJ(i)+eps)));
% 			end
%     end
  end