% Resets the workspace
clear;
close all;
clc;

% Removes some of the warnings
warning('off', 'MATLAB:polyshape:MergeBrokenBoundary');
warning('off', 'MATLAB:polyshape:SelfIntersecting');
warning('off', 'MATLAB:polyshape:repairedBySimplify');
warning('off', 'MATLAB:polyshape:boolOperationFailed');
warning('off', 'MATLAB:polyshape:boundary3Points');

% Imports java classes to control the keyboard and get the screenshot
import java.awt.Robot;
import java.awt.event.*;
import java.awt.Rectangle;
import java.awt.Toolkit;

% Define the controls that the two websites uses and some settings namely the pauseTime between states.
controls = containers.Map;
controls('rotate') = KeyEvent.VK_UP;
controls('drop') = KeyEvent.VK_SPACE;
controls('left') = KeyEvent.VK_LEFT;
controls('right') = KeyEvent.VK_RIGHT;
controls('hold') = KeyEvent.VK_C;
pauseTime = 0.4;


% Create robot
robot = Robot();
% Gets the screen szie
screenSize = Toolkit.getDefaultToolkit().getScreenSize();
w = screenSize.width;
h = screenSize.height;

% Creates a crop that tries to find the tetris board.
relCrop = uint16([state.crop(1) * h, state.crop(2) * h, state.crop(3) * w, state.crop(4) * w]);

% Creates a java ractangle to get the whole screen when screenshotting
screenRect = Rectangle(w, h);

% Create a Java frame (javax.swing.JFrame) and set its always-on-top property
frame = javax.swing.JFrame('Click on Me to Start');
frame.setAlwaysOnTop(true);

% Create a MATLAB figure and display an image
figure('Position',[0 h - 10, 10, 10]);

% Get the MATLAB figure as a Java object
figureHandle = gcf;
jFigure = get(handle(figureHandle), 'JavaFrame');
jAxis = handle(jFigure.getAxisComponent());

% Add the MATLAB figure's Java component to the Java frame
frame.getContentPane().add(jAxis);

% Sets the size of the java frame
frame.setSize(400, 300);

% Make the frame visible
frame.setVisible(true);

% Set the closing behavior for the frame
frame.setDefaultCloseOperation(javax.swing.JFrame.DISPOSE_ON_CLOSE);

% Captures a screen shot of your pc.
screenImage = robot.createScreenCapture(screenRect);
pixelsData = reshape(typecast(screenImage.getData.getDataStorage, 'uint8'), 4, w, h);
imgData = cat(3, ...
    transpose(reshape(pixelsData(3, :, :), w, h)), ...
    transpose(reshape(pixelsData(2, :, :), w, h)), ...
    transpose(reshape(pixelsData(1, :, :), w, h)));

% Displays the capture in the java frame
imshow(imgData(relCrop(1):relCrop(2), relCrop(3):relCrop(4), :), 'InitialMagnification', 10);
drawnow;

% Starts the AI when on the always on top figure. It will have the title
% click me. Make sure that the figure is at the top left corner and not
% interfearing with the tetris board.

% NOTE : In both of the websites make sure that these settings are set
% before starting the AI.

% In Jstris click on settings below the tetris board. Then click on the game settings tab. Then turn off Ghost. 
% Then click play and the survival. When the first piece appears on the
% screen click on the figure and immediately click on the window. The AI
% shoudl work now. The highest score achieved was 1500 before I shut it
% down.

% In Tetris.com click on the cogwheel and turn off Enable Mouse Control,
% Show Animations and Show Ghost Piece. Then click on the figure and then
% immediately click on resume. The AI isnt as reliable as jstris in this
% website. The maximum score however is 70,722. The scores between jstris
% and tetris.com are not comparable.


k = waitforbuttonpress;

disp("Starting Game...");

% Starts the game by taking a screenshot of the tetris board.
screenImage = robot.createScreenCapture(screenRect);
pixelsData = reshape(typecast(screenImage.getData.getDataStorage, 'uint8'), 4, w, h);
imgData = cat(3, ...
    transpose(reshape(pixelsData(3, :, :), w, h)), ...
    transpose(reshape(pixelsData(2, :, :), w, h)), ...
    transpose(reshape(pixelsData(1, :, :), w, h)));
frame.dispose();
close all;

% state(imgData) takes the screenshot and stores several regions of
% interest and probe locations to get the state of the board.
s = state(imgData);
% Initializes the solver that will be used.
sv = solver();
% Initializes the tries that the AI will take to refute errors. It tries 4
% times to get state before it reinstates the state
tries = 0;

% state loop
while true
    % Get a screenshot of the website
    screenImage = robot.createScreenCapture(screenRect);
    pixelsData = reshape(typecast(screenImage.getData.getDataStorage, 'uint8'), 4, w, h);
    imgData = cat(3, ...
        transpose(reshape(pixelsData(3, :, :), w, h)), ...
        transpose(reshape(pixelsData(2, :, :), w, h)), ...
        transpose(reshape(pixelsData(1, :, :), w, h)));
    
    % Tries 4 times before reinstaing state ROI.
    if tries == 4
        s = state(imgData);
        disp("Retrying State Generation...")
    end
    
    % Error handling for state.
    try
        s = s.updateState(imgData);
    catch exception
        try
            % Display the error message and other error details
            disp('An error occurred:');
            disp(exception.message); % Display the error message
            disp('Stack trace:');
            disp(exception.getStackTrace); % Display the stack trace
            s = state(imgData);
            s = s.updateState(imgData);
        catch exception
            % Display the error message and other error details
            disp('An error occurred:');
            disp(exception.message); % Display the error message
            disp('Stack trace:');
            disp(exception.getStackTrace); % Display the stack trace
            error("Something seems to have gone wrong. Either the game has ended or somehting broke. Please retry!")
        end
    end
    
    % Could not find valid state.
    if(s.piece == pieces.nop || s.nextPiece == pieces.nop)
        tries = tries + 1;
        continue;
    end
    
    % Resetting no of Tries since valid state was found.
    tries = 0;
    
    %fprintf('Piece: %s, Next: %s, Held: %s\n', s.piece, s.nextPiece, s.heldPiece);
    %disp(s.data);
    
    % the solve function given the state gives the best end position of the piece and tells
    % weather the hold button whould be pressed or not. The state is given
    [endPosition, hold] = sv.solve(s);

    % actions.GetActionsList gives a list of actions to do to get to a
    % given end position given the piece.
    if ~hold % If hold is not pressed the current piece is given to generate actionsList
        actionsList = actions.GetActionsList(endPosition, s.piece, hold);
    elseif s.heldPiece == pieces.nop % If the hold button is pressed and there is no held piece the nextPiece is used to generate actionsList
        actionsList = actions.GetActionsList(endPosition, s.nextPiece, hold);
    else % The hold button is pressed and there is a piece held. Use that piece to generate the actionsList.
        actionsList = actions.GetActionsList(endPosition, s.heldPiece, hold);
    end
    
    %disp(actionsList);
    
    % Given the actionsList perfrom these actions according to the controls
    % defined above.
    for i = 1:length(actionsList)
        pause(0.005)
        robot.keyPress(controls(char(actionsList(i))));
        pause(0.005);
        robot.keyRelease(controls(char(actionsList(i))));
    end
    
    % Pauses for the given amount to make sure that the animations finish.
    pause(pauseTime);
end