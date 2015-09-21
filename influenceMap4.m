function [out] = influenceMap4(costMatrix, Y, Y_classic)

costMatrix = costMatrix(1:size(Y, 1), 1:size(Y, 2));

if isempty(costMatrix), out = []; return; end
if isequal(size(costMatrix), [1 1]), out = 1; return; end

% retrieve most expansive association
maxcost     = max(costMatrix(Y==1));
if ~isempty(Y_classic), maxcost = max(costMatrix(Y_classic==1)); end
if isempty(maxcost), maxcost = 0; end

softcost    = 0.05;

% transform costMatrix in affinityMatrix
affinity = -costMatrix + maxcost + softcost;
affinity(Y==1) = 1;

SC_costMatrix = [0*diag(ones(size(affinity, 1), 1)), affinity; affinity', 0*diag(ones(size(affinity, 2), 1))];

% a_expand - it works but it's slow
% AL_ICM - fast but creates only small zones
C = a_expand(sparse(SC_costMatrix));



C_OF = C(1:size(affinity, 1), :);
C_DET = C(size(affinity, 1)+1:end, :);

clusters = unique(C);

out = zeros(size(Y));
for i = 1 : length(clusters)
   out(C_OF == clusters(i), C_DET == clusters(i)) = 1;
end

end



