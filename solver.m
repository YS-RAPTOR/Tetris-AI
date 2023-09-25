classdef solver
    properties
        cpuPool % The pool of workers to use for parallel processing
        debug {mustBeNumericOrLogical} % 1 if debug is enabled
    end
    
    methods
        % Constructor for the class. Mainly used to turn on debugging
        function obj = solver(debug)
            if nargin < 1
                debug = false;
            end
            
            %obj.cpuPool = parpool('local', 10);
            obj.debug = debug;
        end
        
        % Deconstructor
        function delete(obj)
            % delete(obj.cpuPool);
        end
        
        % The main logic of solving the Tetris State. The main moethod this
        % AI uses is to brute force through all possible piece combinations
        % and score them according to some criteria. The orientations with
        % the best score will be the chosen end position.
        function [loc, hold] = solve(obj, currentState)
            arguments
                obj solver
                currentState state
            end
            
            % Converts the state into a 1D height map.
            heightMap = uint8(zeros(1, 10));
            
            % Iterate through the state to convert it into a 1D height map
            for row = 1:10
                for col = 1:20
                    if currentState.data(col, row) ==  1
                        heightMap(row) = 20 - col + 1;
                        break
                    end
                end
            end
            
            % Initializes the pieces that has to be considered.
            allPieces = currentState.piece;
            % The best score is the lowest score
            lowestScore = Inf;
            
            % Add the next piece to be evaluated if there is no piece held.
            % Do not add to be evaluated if the pieces are the same
            if(currentState.piece ~= currentState.nextPiece && currentState.heldPiece == pieces.nop)
                allPieces = [allPieces, currentState.nextPiece];
            end
            % If there is a piece held add it to be evaluated but similarly
            % if it is the same as the current piece do not evaluate.
            if currentState.heldPiece ~= pieces.nop && currentState.heldPiece ~= currentState.nextPiece && currentState.heldPiece ~= currentState.piece
                allPieces = [allPieces, currentState.heldPiece];
            end
            
            % If the lowest score is set at the second iteration it is
            % known that the hold button must be pressed. This is why these
            % variables are used.
            hold = false;
            pastFirstIter = false;
            
            % Evaluate all possible pieces
            for piece=allPieces
                % Get all locations for the pieces.
                possiblePositions = obj.getAllPossibleLocations(heightMap, piece);
                
                % For each position calculate correct score
                scores = zeros(size(possiblePositions, 1), 3);
                
                for i = 1:size(possiblePositions, 1)
                    scores(i, :) = obj.calculateScore(possiblePositions(i,:), piece, heightMap, currentState);
                end
                
                % Get the weighted sum of the scores
                maxHoles = max(scores(1, :));
                maxHeight = 20;
                maxRidges = 5;
                
                % Includes normalization and weighting
                weights = [0.6/maxHoles;0.3/maxHeight;0.1/maxRidges];
                
                % Gets the weighted scores
                weightedScores = scores*weights;
                
                % Gets the position with the best score
                [lowScore, idx] = min(weightedScores);
                
                % Set the lowest score
                if lowScore < lowestScore
                    % Sets the lowest score and end postion
                    lowestScore = lowScore;
                    loc = possiblePositions(idx, :);
                    % If the lowest score is set at second iteration then
                    % hold button must be pressed
                    if pastFirstIter
                        hold = true;
                    end
                end
                % Makes this true after first iteration.
                pastFirstIter = true;
            end
        end
        
        % Gets all possible end locations given a piece and height map.
        function possibleStates = getAllPossibleLocations(obj, heightMap, piece)
            arguments
                obj
                heightMap (1, 10) {mustBeNumeric}
                piece pieces
            end
            
            % There are a maximum of 34 possible locations.
            possibleStates = uint8(zeros(34, 3));

            % Precalculated in the pieces class
            subtractions = piece.getHeightMapSubtractions();
            i = 1;
            orientationIndex = 1;
            
            % Iterates through all orientations of the piece
            for orientation=piece.getOrientations()
                % Iterates through all x postions of the piece. 10 is the
                % board size and size(orientation{1}, 2) is its width.
                for location=1:10-size(orientation{1}, 2)+1
                    % location is x position of the piece

                    % height is found using the dimensions of the
                    % orientation
                    height = size(orientation{1}, 1);

                    % The lowest point that the piece can hit is found
                    % using the height map. This part:
                    % location:location+size(orientation{1}, 2)-1) gets the
                    % region of the height map that the piece can hit. The
                    % subtractions are there to make sure that if the
                    % bottom of the piece has a gap it is accounted for.
                    % Then you look for the max to avoind collisions with
                    % the state.
                    bottom = max(heightMap(location:location+size(orientation{1}, 2)-1) - subtractions{orientationIndex});
                    
                    % the end locations is a vector of [left X, top Y,
                    % orientation index]
                    possibleStates(i, :) = uint8([location, bottom + height, orientationIndex]);
                    i = i+1;
                end
                orientationIndex = orientationIndex + 1;
            end
            
            % Removes the traling zeros.
            possibleStates = possibleStates(1:i - 1, :);
            
            % If debug is enabled display all the possible states.
            if obj.debug
                disp(possibleStates)
            end
        end
        
        % Calculates the score of an end location fiven the state and
        % height map.
        function score = calculateScore(obj, location, piece, heightMap, stateToScore)
            arguments
                obj
                location (1, 3) {mustBeNumeric}
                piece pieces
                heightMap (1, 10) {mustBeNumeric}
                stateToScore state
            end
            
            % Prepare region to calculate number of holes
            % Gets the correct piece with correct orientation.
            pieceMat = piece.getOrientation(location(3));
            
            % Gets the height map region this piece can affect. This region
            % is only in the x direction
            heightMapRegion = heightMap(location(1):location(1)+size(pieceMat, 2)-1);

            % Gets the lowest point in the given height map region
            bottom = max(min(heightMapRegion), 1);

            % Using these information find the region that is affected by
            % the piece being place there. 21 - location(2): 21 -
            % bottom,location(1) is the region from the top of the piece to
            % the lowest trough in the region.
            % location(1):location(1)+size(pieceMat, 2)-1) is the same as
            % before where location(1) is the left most part of the piece
            % and the size(pieceMat, 2)-1) is its width.
            region = stateToScore.data( 21 - location(2): 21 - bottom,location(1):location(1)+size(pieceMat, 2)-1);
            
            % Superimpose the piece in this region and invert it.
            region = ~[region(1:size(pieceMat, 1), 1:size(pieceMat,2)) | pieceMat; region(size(pieceMat, 1) + 1:end, :)];
            % Calculate number of holes
            % A hole is define as a 1 that has a zero above it
            % Also calculate the new heightMap of the region.
            noOfHoles = 0;
            regionHeightMap = zeros(1, size(region, 2));
            % Iterates through the region left to right and top to bottom. 
            for x=1:size(region, 2)
                hasTop = false;
                for y=1:size(region, 1)
                    % This means there is a hole strucure at a particular
                    % place
                    if region(y,x) == 0 && ~hasTop
                        % Set that as its new height and indicate that
                        % there is a top
                        hasTop = true;
                        regionHeightMap(x) = size(region, 1) - y + bottom;
                    end
                    
                    % All holes encountered below a 0 is counted as a hole
                    if region(y,x) == 1 && hasTop
                        noOfHoles = noOfHoles + 1;
                    end
                    
                end
            end
            
            % Find the new height map and get the difference across it.
            newHeightMap = [heightMap(1:location(1)-1), regionHeightMap, heightMap(location(1)+size(pieceMat, 2):end)];
            heightMapDiff = diff(newHeightMap);
            

            % Count the amount of height changes of at least greater than three blocks
            % A ridge is defined as a climb or drop of greater than three.
            % This counts the number of ridges introduced by adding the
            % piece
            noOfRidges = sum(abs(heightMapDiff) >= 3);
            
            % returns the score criteria to do the weighted sum.
            score = [noOfHoles, location(2), noOfRidges];
            
            % Display region for debugging
            if obj.debug
                figure
                imshow(region, 'InitialMagnification', 'fit');
                str = sprintf('Holes: %d, Height: %d, Ridges: %d, x: %d, y: %d, orientation: %d' , score(1), score(2), score(3), location(1), location(2), location(3));
                title(str)
                disp(heightMap)
                disp(newHeightMap)
            end
        end
        
        
    end
end
