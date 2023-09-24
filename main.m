clear;
close all;
clc;

warning('off', 'MATLAB:polyshape:MergeBrokenBoundary');
warning('off', 'MATLAB:polyshape:SelfIntersecting');
warning('off', 'MATLAB:polyshape:repairedBySimplify');
warning('off', 'MATLAB:polyshape:boolOperationFailed');
warning('off', 'MATLAB:polyshape:boundary3Points');


files = ["jstris", "tetris"];
for i = 1:numel(files)
    tetris = imread("SampleCaptures/" + files(i) + ".png");
    s = state(tetris);
    
    figure;
    imshow(tetris);
    hold on;
    probes = s.probes;
    
    for p = 1:numrows(probes)
        plot(probes(p,1), probes(p,2), 'r.', 'MarkerSize', 20);
    end
end