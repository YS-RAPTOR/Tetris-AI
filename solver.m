classdef solver
    properties
        cpuPool % The pool of workers to use for parallel processing
        canHold {mustBeNumericOrLogical} % 1 if the piece can be held
        debug {mustBeNumericOrLogical} % 1 if debug is enabled
        held pieces
    end
    
    methods
        function obj = solver(debug, canHold)
            if nargin < 1
                debug = false;
            end
            if nargin < 2
                canHold = false;
            end
            
            %obj.cpuPool = parpool('local', 10);
            obj.debug = debug;
            obj.canHold = canHold;
            obj.held = pieces.nop;
        end
        
        function delete(obj)
            delete(obj.cpuPool);
        end
        
        function [loc, hold] = solve(obj, currentState, currentPiece, nextPiece)
            arguments
                obj solver
                currentState state
                currentPiece pieces
                nextPiece pieces
            end
            % Go through all possible reachable positions for the piece
            % For now just dropping it in all possible locations. No fancy shit
            
            heightMap = uint8(zeros(1, 10));
            
            for row = 1:10
                for col = 1:20
                    if currentState.data(col, row) ==  1
                        heightMap(row) = 20 - col + 1;
                        break
                    end
                end
            end
            
            allPieces = currentPiece;
            lowestScore = Inf;
            
            if obj.canHold
                if(currentPiece ~= nextPiece && obj.held == pieces.nop)
                    allPieces = [allPieces, nextPiece];
                end
                if obj.held ~= pieces.nop && obj.held ~= nextPiece && obj.held ~= currentPiece
                    allPieces = [allPieces, obj.held];
                end
            end
            hold = false;
            pastFirstIter = false;
            for piece=allPieces
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
                
                weights = [0.6/maxHoles;0.3/maxHeight;0.1/maxRidges];
                
                weightedScores = scores*weights;
                
                % Gets the position with the best score
                [lowScore, idx] = min(weightedScores);
                
                if lowScore < lowestScore
                    lowestScore = lowScore;
                    loc = possiblePositions(idx, :);
                    if pastFirstIter
                        hold = true;
                    end
                end
                pastFirstIter = true;
            end
        end
        
        function possibleStates = getAllPossibleLocations(obj, heightMap, piece)
            arguments
                obj
                heightMap (1, 10) {mustBeNumeric}
                piece pieces
            end
            
            possibleStates = uint8(zeros(34, 3));
            subtractions = piece.getHeightMapSubtractions();
            i = 1;
            orientationIndex = 1;
            
            for orientation=piece.getOrientations()
                for location=1:10-size(orientation{1}, 2)+1
                    % location is x position of the piece
                    height = size(orientation{1}, 1);
                    bottom = max(heightMap(location:location+size(orientation{1}, 2)-1) - subtractions{orientationIndex});
                    
                    possibleStates(i, :) = uint8([location, bottom + height, orientationIndex]);
                    i = i+1;
                end
                orientationIndex = orientationIndex + 1;
            end
            
            possibleStates = possibleStates(1:i - 1, :);
            
            if obj.debug
                disp(possibleStates)
            end
        end
        
        function score = calculateScore(obj, location, piece, heightMap, stateToScore)
            arguments
                obj
                location (1, 3) {mustBeNumeric}
                piece pieces
                heightMap (1, 10) {mustBeNumeric}
                stateToScore state
            end
            
            % Prepare region to calculate number of holes
            pieceMat = piece.getOrientation(location(3));
            heightMapRegion = heightMap(location(1):location(1)+size(pieceMat, 2)-1);
            bottom = max(min(heightMapRegion), 1);
            region = stateToScore.data( 21 - location(2): 21 - bottom,location(1):location(1)+size(pieceMat, 2)-1);
            region = ~[region(1:size(pieceMat, 1), 1:size(pieceMat,2)) | pieceMat; region(size(pieceMat, 1) + 1:end, :)];
            % Calculate number of holes
            % A hole is define as a 1 that has a zero above it
            % Also calculate the heightMap of the region.
            noOfHoles = 0;
            regionHeightMap = zeros(1, size(region, 2));
            for x=1:size(region, 2)
                hasTop = false;
                for y=1:size(region, 1)
                    if region(y,x) == 0 && ~hasTop
                        hasTop = true;
                        regionHeightMap(x) = size(region, 1) - y + bottom;
                    end
                    
                    if region(y,x) == 1 && hasTop
                        noOfHoles = noOfHoles + 1;
                    end
                    
                end
            end
            
            % Find new diff of height map
            newHeightMap = [heightMap(1:location(1)-1), regionHeightMap, heightMap(location(1)+size(pieceMat, 2):end)];
            heightMapDiff = diff(newHeightMap);
            
            % Count the amount of height changes of at least greater than three blocks
            noOfRidges = sum(abs(heightMapDiff) >= 3);
            
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