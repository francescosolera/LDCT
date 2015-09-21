function [out] = influenceMap2(costMatrix, Y, Y_classic)
preAllocationMax = 2048;

costMatrix = costMatrix(1:size(Y, 1), 1:size(Y, 2));

if isempty(costMatrix), out = []; return; end
if isequal(size(costMatrix), [1 1]), out = 1; return; end

% retrieve most expansive association
maxcost     = max(costMatrix(Y==1));
if ~isempty(Y_classic), maxcost = max(costMatrix(Y_classic==1)); end
if isempty(maxcost), maxcost = 0; end

softcost    = 0.005;

% transform costMatrix in affinityMatrix
affinity = -costMatrix + maxcost + softcost;
affinity(Y==1) = 1;

% add unassociated OF/det
empty_rows = find(sum(Y,2) == 0);
empty_cols = find(sum(Y,1) == 0);

% build initial blocks
[r, c] = find(Y==1);
blocks = cell(1, preAllocationMax);
blocks_exists = ones(1, preAllocationMax);
blocks_affinities = zeros(1, preAllocationMax);
for i = 1 : length(r)
    blocks{i}.r = r(i);
    blocks{i}.c = c(i);
    blocks_affinities(i) = affinity(r(i), c(i));
end

for i = 1 : length(empty_rows)
    blocks{length(r)+i}.r = empty_rows(i);
    blocks{length(r)+i}.c = [];
    blocks_affinities(length(r)+i) = 0; %% ???
    blocks_exists(length(r)+i) = 1;
end
for i = 1 : length(empty_cols)
    blocks{length(r)+length(empty_rows)+i}.r = [];
    blocks{length(r)+length(empty_rows)+i}.c = empty_cols(i);
    blocks_affinities(length(r)+length(empty_rows)+i) = 0; %% ???
    blocks_exists(length(r)+length(empty_rows)+i) = 1;
end

% use index for preallocation purposes
currentIdx = length(r) + length(empty_rows) + length(empty_cols);

% initialize blocks pairwise affinities
comb = combnk(1:currentIdx, 2);
comb_exists = ones(1, size(comb, 1)); 
pairwise_aff = zeros(1, size(comb, 1));
for i = 1 : size(comb, 1)
    pairwise_aff(i) = sum(sum(affinity([blocks{comb(i, 1)}.r, blocks{comb(i, 2)}.r], [blocks{comb(i, 1)}.c, blocks{comb(i, 2)}.c])));
end

currentIdx = currentIdx + 1;
% main loop - blocks merging
changed = true;
while changed
    changed = false;
    
    % init max values
    best_gain = 0;          best_idx = 0;
    
    % evaluate all possible combination of blocks merging
    for i = 1 : size(comb, 1)
        % check if the comb is still valid
        if ~comb_exists(i), continue; end
        
        % compute previous score on this two clusters
        previous_score = blocks_affinities(comb(i, 1)) + blocks_affinities(comb(i, 2));
        
        % and compute the new potential score
        potential_score = pairwise_aff(i);
        
        % check if there is a gain
        gain = potential_score - previous_score;
        if gain > best_gain
            best_gain = gain;
            best_idx = i;
        end
    end
    
    % check if there has been a gain and make it stable
    if best_idx ~= 0
        % selected_blocks
        b1 = comb(best_idx, 1);
        b2 = comb(best_idx, 2);
        
        % new cluster
        new_cluster.r = [blocks{b1}.r; blocks{b2}.r];
        new_cluster.c = [blocks{b1}.c; blocks{b2}.c];
        
        % update blocks
        blocks_exists([b1, b2]) = 0;
        blocks_exists(currentIdx) = 1;
        blocks{currentIdx} = new_cluster;
        
        % update block affinities
        sum_affinities = blocks_affinities(b1) + blocks_affinities(b2);
        %blocks_affinities([b1, b2]) = [];
        blocks_affinities(currentIdx) = sum_affinities;
        currentIdx = currentIdx + 1;
        
        % update comb
        comb_exists(best_idx) = 0;
        for i = 1 : size(comb, 1)
            if ~comb_exists(i), continue; end
            done_smt = 0;
            if comb(i, 1) == b1 || comb(i, 1) == b2, comb(i, 1) = currentIdx-1; done_smt = 1;
            elseif comb(i, 2) == b1 || comb(i, 2) == b2, comb(i, 2) = currentIdx-1; done_smt = 1;
            end
            
            if done_smt
                pairwise_aff(i) = sum(sum(affinity([blocks{comb(i, 1)}.r; blocks{comb(i, 2)}.r], [blocks{comb(i, 1)}.c; blocks{comb(i, 2)}.c])));
            end
        end
        
        % check for autoreference in combs
        comb_exists(comb(:, 1) == b1 | comb(:, 1) == b2 | comb(:, 2) == b1 | comb(:, 2) == b2) = 0;
        
        % signal a change
        changed = true;
    end
end

blocks = blocks(1 : currentIdx - 1);
% move from blocks notation to Y notation
out = zeros(size(Y));
for i = 1 : length(blocks)
    if blocks_exists(i), out(blocks{i}.r, blocks{i}.c) = 1; end
end

disp *;

end