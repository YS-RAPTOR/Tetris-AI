clear;
close all;
clc;

warning('off', 'MATLAB:polyshape:MergeBrokenBoundary');
warning('off', 'MATLAB:polyshape:SelfIntersecting');
warning('off', 'MATLAB:polyshape:repairedBySimplify');
warning('off', 'MATLAB:polyshape:boolOperationFailed');
warning('off', 'MATLAB:polyshape:boundary3Points');


files = ["freetetris", "jstris", "tetris"];
files = "tetris"
for i = 1:numel(files)
    tetris = imread("SampleCaptures/" + files(i) + ".png");
    s = state(tetris);
    
    figure;
    imshow(tetris);
    hold on;
    for p = 1:numrows(s.probes)
        plot(s.probes(p,1), s.probes(p,2), 'r.', 'MarkerSize', 20);
    end
end