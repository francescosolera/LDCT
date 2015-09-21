function plot4debug(model, data, latentVariables)

videoPar = model.par;
objectFiles = data.objectFiles;
Dt = data.detections;
frame = data.frame;

previousOF = objectFile.filterOccludedObjects(data.objectFiles);

colors = 'ymcgb';
letters = 'abcdefghijklmnopqrstuvwxyz';

hFig = figure(1);

hs = subplot(1, 2, 1);
cla(hs);

% plot latent variables
hold on;

% plot bridview trajectories
for i = 1 : length(objectFiles)
    data = [objectFiles{i}.x, objectFiles{i}.y];
    
    if ~objectFiles{i}.isOccluded
        if ~isempty(objectFiles{i}.history)
            data = [objectFiles{i}.history(objectFiles{i}.history(:, 1) < frame, [2 3]); data];
        end
        
        thiscolor = [0.70 0.7 0.7];
        %thiscolor = colors(mod(objectFiles{i}.id, 5)+1);
        
        if videoPar.XYexchange
            plot(data(:, 2), data(:, 1), 'Color', thiscolor, 'LineWidth', 3);
        else
            plot(data(:, 1), data(:, 2), 'Color', thiscolor, 'LineWidth', 3);
        end
    else
        if videoPar.XYexchange
            plot(data(2), data(1), 'ok', 'LineWidth', 3);
        else
            plot(data(1), data(2), 'ok', 'LineWidth', 3);
        end
    end
    
    hold on;
end

for i = 1 : length(latentVariables.focalSpots)
    data = [];
    for j = 1 : length(latentVariables.focalSpots{i}.objectFiles)
        ids = latentVariables.focalSpots{i}.objectFiles(j);
        if ids <= length(previousOF)
            %idx = objectFile.returnIDXgivenAnID(previousOF, ids);
            data = [data; previousOF{ids}.x, previousOF{ids}.y];
        end
    end
    for j = 1 : length(latentVariables.focalSpots{i}.detections)
        idx = latentVariables.focalSpots{i}.detections(j);
        data = [data; Dt(idx, [1 2])];
    end
    
    % augment with circles
    data_ = [];
    q = 0 : 0.1 : 2;
    for j = 1 : size(data, 1)
        data_ = [data_; [data(j, 1) + 0.5*cos(q*pi)]', [data(j, 2) + 0.5*sin(q*pi)]'];
    end
    
    if ~isempty(data_)
        k = convhull(data_(:, 1), data_(:, 2));
        if latentVariables.focalSpots{i}.isAmbiguous
            c = 'r';
        else
            c = 'g';
        end
        
        if videoPar.XYexchange
            patch(data_(k, 2), data_(k, 1), c, 'FaceAlpha', 0.2);
        else
            patch(data_(k, 1), data_(k, 2), c, 'FaceAlpha', 0.2);
        end
    end
end

for i = 1 : size(Dt, 1)
    if videoPar.XYexchange
        plot(Dt(i, 2), Dt(i, 1), 'or', 'LineWidth', 3);
        %text(Dt(i, 2)+0.2, Dt(i, 1)+0.01, letters(mod(i, 26)+1), 'FontSize', 10);
    else
        plot(Dt(i, 1), Dt(i, 2), 'or', 'LineWidth', 3);
        %text(Dt(i, 1)+0.01, Dt(i, 2)+0.2, letters(mod(i, 26)+1), 'FontSize', 10);
    end
end

if model.training
    title(['Online training at frame ', num2str(frame)]);
else
    title(['Tracking at frame ', num2str(frame)]);
end

%set(hFig, 'Position', [1650 100 videoPar.xFigure*2/3 videoPar.yFigure*3/2]);
axis(videoPar.axis);
if videoPar.YreverseView, set(gca,'YDir','reverse'); end
if videoPar.XreverseView, set(gca,'XDir','reverse'); end
try rotate(hs, [0 0 1], videoPar.rotate); catch; end

hold off;
%print(hFig, '-djpeg', ['images_of_tracked_people/imDB_' num2str(frame) '.jpg']);

%pause(0.5);

end