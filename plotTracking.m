function plotTracking(videoPar, folder, objectFiles, frame)
colors = 'ymcrgb';

hFig = figure(1);
%set(hFig, 'Position', [200 200 1.8*videoPar.xFigure videoPar.yFigure]);

video = [];
if true
    % get video frame
    try
        video = imread([folder, '/images/', sprintf('%06d.jpg', frame)]);
    catch
        try
            video = imread([folder, '/images/', sprintf('%06d.jpeg', frame)]);
        catch
            video = imread([folder, '/images/', sprintf('%06d.png', frame)]);
        end
    end
end

% show corresponding video
subplot(1, 2, 2);
cla;
imshow(video);
if ~isempty(videoPar.H)
    hold on;
    for i = 1 : length(objectFiles)
        
        % check for occluded or empty object files
        if objectFiles{i}.isOccluded || isempty(objectFiles{i}.history)
            continue
        end
        
        
        % check for unreliable tracklets
        if 0
            thresh = 5;
            if size(objectFiles{i}.history, 1) < thresh
                continue
            else
                dist = objectFiles{i}.history(end-thresh+1:end, [2 3 1]) - circshift(objectFiles{i}.history(end-thresh+1:end, [2 3 1]), +1);
                dist = dist(2:end, :);
                dist_frames = dist(:, 3);
                if sum(dist_frames == 1) < thresh/2, continue; end
            end
        end
        
        data = objectFiles{i}.history(objectFiles{i}.history(:, 1) <= frame, [2 3]);
        data = [data; [objectFiles{i}.x objectFiles{i}.y]];
        data = videoPar.H * [data, ones(size(data, 1), 1)]';
        
        data = round(data ./ (eps+repmat(data(3, :), 3, 1)));
        
        data = data';
        if isempty(data)
            continue;
        end
        
        % 2 <-> 1
        plot(data(max(1, end-60):end, 1), data(max(1, end-60):end, 2), 'Color', colors(mod(objectFiles{i}.id, 6)+1), 'LineWidth', 2);
        
        % cut for appearence features test
        w = int32(objectFiles{i}.BBw);%history(end, 4));
        h = int32(objectFiles{i}.BBh);%history(end, 5));
        
        rectangle('Position', [data(end, 1) - w/2, data(end, 2) - h, w, h], 'EdgeColor', colors(mod(objectFiles{i}.id, 6)+1));
        myimg = video(max(1, data(end, 2) - h) : min(480, data(end, 2)), max(1, data(end, 1) - w/2) : min(640, data(end, 1) + w/2), :);
        if ~isempty(myimg) && size(myimg, 1) == h+1 && size(myimg, 2) == w+1
            %imwrite(myimg, ['D:\lab\CVT\myVideoOutput\im' num2str(objectFiles{i}.id) '_' num2str(round(1000*rand)) '.jpg'], 'jpg');
        end
    end
    hold off;
    
    printMe = 0;
    
    if printMe
        hax = subplot(1, 2, 2);
        hfig = figure(10);
        hax_new = copyobj(hax, hfig);
        set(hax_new, 'Position', get(0, 'DefaultAxesPosition'));
        print(hfig, '-djpeg', ['D:\lab\CVT\myVideoOutput\imTR_' num2str(frame) '.jpg']);
    end
end

%hgexport(gcf, ['video/' num2str(frame) '.jpg'], hgexport('factorystyle'), 'Format', 'jpeg');

pause(0.01);%(videoPar.pauseFor);
end