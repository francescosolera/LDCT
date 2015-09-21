% load file
GT = dlmread('det.txt');
takeThisLine = rand(size(GT, 1), 1) > 0.2;
GT = GT(takeThisLine, :);

% need to write it from TL to BC
GT(:, 3) = GT(:, 3) + GT(:, 5) / 2;
GT(:, 4) = GT(:, 4) + GT(:, 6);

% and then from pixels to world coordinates
run('../loadPar.m');

data = GT(:, [3 4]);
data = videoPar.H \ [data, ones(size(data, 1), 1)]';
data = data ./ (eps+repmat(data(3, :), 3, 1));

GT(:, [3 4]) = data([1 2], :)';
dlmwrite('trajectories_deg.txt', GT, 'delimiter', ' ');