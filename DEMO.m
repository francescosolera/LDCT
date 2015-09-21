%% DEMO RUN FOR ICCV 2015 SUBMITTED WORK ON:
% Learning to Divide and Conquer for Online Multi-Target Tracking
clc; clear; close all;

%% README TO RUN
% This code is obfuscated and will be released upon acceptance to protect
% authorship. Through this realease we aim at showing that our method
% behaves as detailed in the paper, producing ambiguous influence zones
% only when miss or false detections occurs and invoking appearence or
% motion cues only under these ambiguous circumstances.
%
% Before running, you need to download the images and place them inside the
% data_PETS09S2L1/images folder and data_PETS09S2L2/images folder
% respectively:
%    PETS09-S2L1 -> http://tinyurl.com/oo3mxlg
%    PETS09-S2L1 -> http://tinyurl.com/lrjwduw

% INSTALL - first time only, then comment it
fprintf('Compiling C files...\n');
cd CCMatlab; mexall; cd ..;
mex assignmentoptimal.c -output assignmentoptimal_mex

%% PETS
trainingSequence    = 'data_PETS09S2L1';
testingSequence     = 'data_PETS09S2L1';
modelName           = 'pets.mat';
dotraining          = 1;
mymodel.w           = [5;1;1;1;1;1;1];      % INIT FOR TRAINING
showresults         = 1;

%% TRAINING
if dotraining
    fprintf('TRAINING\n');
    mymodel = mainLDCT(trainingSequence, 1, mymodel, showresults);
    save(modelName, 'mymodel');
end

%% TESTING
fprintf('TESTING\n');
load(modelName);
mainLDCT(testingSequence, 0, mymodel, showresults);