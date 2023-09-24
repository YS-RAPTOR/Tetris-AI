clear;
close all;
clc;

warning('off', 'MATLAB:polyshape:MergeBrokenBoundary');
warning('off', 'MATLAB:polyshape:SelfIntersecting');
warning('off', 'MATLAB:polyshape:repairedBySimplify');
warning('off', 'MATLAB:polyshape:boolOperationFailed');
warning('off', 'MATLAB:polyshape:boundary3Points');


files = ["tetris", "tetris1080", "jstris", "jstris1080"];
for file = 1:numel(files)
    tetris = imread("SampleCaptures/" + files(file) + ".png");
    
    s = state(tetris);
    tic;
    s = s.updateState(tetris);
    toc
end