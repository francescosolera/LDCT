%% PARAMETERS
% video
videoPar.fileName = 'PETS09_S2.L1.avi';
videoPar.startingFrame  = 1;
videoPar.endingFrame    = 790;
videoPar.videoReader    = ['data_PETS09S2L1/', videoPar.fileName];
videoPar.xPixels        = 768;
videoPar.yPixels        = 576;
videoPar.subSampled     = 1;

% camera
videoPar.axis           = [-16 23 -15 18];
videoPar.camera         = [30, 30];
videoPar.pauseFor       = 0;
videoPar.XreverseView   = true;
videoPar.YreverseView   = false;
videoPar.XYexchange     = true;
videoPar.xFigure        = 800;
videoPar.yFigure        = 450;

% trajectories
videoPar.trajectoriesID = '';
videoPar.H = [0.0289940963053198,-0.0251947589444763,0.394494864353087;-0.00294838995768608,9.57081576204470e-05,0.304775997727424;2.42043079782752e-05,1.63318673453919e-05,0.00112102341066398];

% bounding boxes fixed size
videoPar.BBw = 30;
videoPar.BBh = 80;

% adj
if videoPar.XYexchange
    videoPar.axis = circshift(videoPar.axis, [0, 2]);
end