classdef state
    properties(Constant)
        kernel = kdgauss(0.25);
        invkernel = kdgauss(0.25)';
        crop = [0.18, 0.94, 0.19, 0.71];
    end
    
    properties (SetAccess = private)
        absCrop (1, 4) {mustBeNumeric}
        board (1, 4) {mustBeNumeric}
        backgroundColor (1, 3) {mustBeNumeric}
        probes (200, 2) {mustBeNumericOrLogical}
        data (20, 10)
        piece pieces
        nextPiece pieces
        heldPiece pieces
        heldRegion (1, 4) {mustBeNumeric}
        nextRegion (1, 4) {mustBeNumeric}
        squareSize (1, 2) {mustBeNumeric}
    end
    
    properties
        image
    end
    methods
        % Create state given the capture of the screen. This function is
        % extremely costly so is done only ones. This means that if the
        % screen changes (scroll the website) the AI will break.
        function obj = state(data)
            
            % Crop the data using relative values. To make it resistant to
            % different resolutions. Havent tested with 1920*1080.
            % 1600*2560 = [300, 1500, 500, 1800];
            obj.image = data;
            
            % Initialize the crop region
            obj.absCrop = uint16([size(data, 1) *  state.crop(1), size(data, 1) * state.crop(2), size(data, 2) * state.crop(3), size(data, 2) * state.crop(4)]);
            
            % crops the image
            data = obj.image(obj.absCrop(1):obj.absCrop(2), obj.absCrop(3):obj.absCrop(4), :);
            
            % Do Edge Detection on the images
            Iu = iconvolve(data, obj.kernel);
            Iv = iconvolve(data, obj.invkernel);
            
            data = sqrt(Iu.^2 + Iv.^2);
            
            % Convert the data to binary with low threshold
            data = rgb2gray(data) < 0.0001;
            
            % Get the shapes described by the data by lokking four
            % boundaries in the data.
            boundaries = bwboundaries(data);
            
            % Initializes data to be filled out by iterating through the
            % shapes
            rectanglesOfInterest = polyshape.empty(0, 1);
            squaresOfInterest = polyshape.empty(0, 200);
            
            rectangleIndex = 0;
            squareIndex = 0;
            
            % Iterate through all the boundaries
            for k = 1:length(boundaries)
                % Check if the shape has at least 8 vertices
                if numel(boundaries) < 8
                    continue
                end
                
                % Convert to polygon
                shape = polyshape(boundaries{k}(:, 2), boundaries{k}(:, 1), "KeepCollinearPoints", false);
                
                % If the number of regions is not 1 probably has zero
                % regions or is not a square/rectabgle
                if shape.NumRegions ~= 1
                    continue
                end
                
                % Find the 4 extremities of the shape
                miX = min(shape.Vertices(:, 1));
                maX = max(shape.Vertices(:, 1));
                miY = min(shape.Vertices(:, 2));
                maY = max(shape.Vertices(:, 2));
                
                % Find the width and height of the shape
                width = maX - miX;
                height = maY - miY;
                
                % Has to be a minimum width
                if width < 25 || height < 25
                    continue;
                end
                
                % If it has too many vertices this means it is probably not
                % a square or rectangle
                if numrows(shape.Vertices) > 18
                    continue
                end
                
                % Checks the aspect ration
                % The tetris board is taller than it is wider so possible
                % rectangles that can be the tetris board is chosen

                % Squares are also saved since they can be used to
                % construct the tetris board region.
                aspectRatio = height/width;
                if aspectRatio > 1.75
                    rectangleIndex = rectangleIndex + 1;
                    rectanglesOfInterest(rectangleIndex) = shape;
                elseif aspectRatio > 0.9 && aspectRatio < 1.1 && shape.numsides < 10
                    squareIndex = squareIndex + 1;
                    squaresOfInterest(squareIndex) = shape;
                end
            end
            
            % If there are rectangles of interest choose the rectangle with
            % the highest area as the tetris board.

            % If there are no rectangles construct the tetris board
            % rectangle using the smaller squares.
            if rectangleIndex > 1
                area = 0;
                rectangle = polyshape.empty(0, 1);
                for j = 1:rectangleIndex
                    if (area < rectanglesOfInterest(j).area)
                        area = rectanglesOfInterest(j).area;
                        rectangle = rectanglesOfInterest(j);
                    end
                end
                rectanglesOfInterest = rectangle;
            elseif rectangleIndex == 0
                % find the  rectangle described by the smaller squares
                left = 5000;
                right = 0;
                top = 5000;
                bottom = 0;
                % Constructing the rectangle of interest using the smaller
                % squares within the tetris board.
                for j = 1:squareIndex
                    if (left > min(squaresOfInterest(j).Vertices(:, 1)))
                        left = min(squaresOfInterest(j).Vertices(:, 1));
                    end
                    if (right < max(squaresOfInterest(j).Vertices(:, 1)))
                        right = max(squaresOfInterest(j).Vertices(:, 1));
                    end
                    if (top > min(squaresOfInterest(j).Vertices(:, 2)))
                        top = min(squaresOfInterest(j).Vertices(:, 2));
                    end
                    if (bottom < max(squaresOfInterest(j).Vertices(:, 2)))
                        bottom = max(squaresOfInterest(j).Vertices(:, 2));
                    end
                end
                rectanglesOfInterest = polyshape([left, right, right, left], [top, top, bottom, bottom]);
            end
            
            % Get the rectangle corners in reference to the full image.
            miX = min(rectanglesOfInterest.Vertices(:, 1)) + obj.absCrop(3);
            maX = max(rectanglesOfInterest.Vertices(:, 1)) + obj.absCrop(3);
            miY = min(rectanglesOfInterest.Vertices(:, 2)) + obj.absCrop(1);
            maY = max(rectanglesOfInterest.Vertices(:, 2)) + obj.absCrop(1);
            
            % Find the size of a tetris square.
            obj.squareSize = [(maX - miX) / 10 ,(maY - miY) / 20];
            % Save the board location in reference to the full image.
            obj.board = [miX, maX, miY, maY];
            
            % Constructs probes to figure out the state of the tetris
            % board.
            i = 0;
            for y=miY+(obj.squareSize(2)/2):obj.squareSize(2):maY
                for x=miX+(obj.squareSize(1)/2):obj.squareSize(1):maX
                    i = i + 1;
                    obj.probes(i, :) = uint16([x y]);
                end
            end
            
            % Get the background color of the tetris board. Get the colors
            % of the different probe locations and find the modal color.
            colors = obj.getColorsFromProbes(obj.probes);
            obj.backgroundColor = mode(colors);
            
            % Held region is defined as the top 50% of the tetris board and the very left of the crop to the left of the tetris board. 
            % So relative to the tetris board the held piece should be in
            % its top left.

            obj.heldRegion = [obj.absCrop(1),0.5*(obj.board(3) + obj.board(4)), obj.absCrop(3), obj.board(1)];

            % Next region is defined as the top 50% of the tetris board and the very right of the tetris board to the right of crop. 
            % So relative to the tetris board the next piece should be in
            % its top right.

            obj.nextRegion = [obj.absCrop(1),0.5*(obj.board(3) + obj.board(4)), obj.board(2), obj.absCrop(4)];

            % Binarize image for ocr
            images = uint8(rgb2gray(obj.image) < 200)*255;

            % get the held region and next region in a cell. Get the text
            % you are searching for in a cell and the regions in a cell.
            images = {images(obj.heldRegion(1):obj.heldRegion(2), obj.heldRegion(3):obj.heldRegion(4), :), images(obj.nextRegion(1):obj.nextRegion(2), obj.nextRegion(3):obj.nextRegion(4), :)};
            texts = ["hold", "next"];
            boxes = {obj.heldRegion, obj.nextRegion};
            
            % Iterate through the above values
            for i=1:numel(images)
                image = images{i};
                % Get the regions of interest for the text using
                % detectTextCRAFT.
                textRegions = detectTextCRAFT(image);
                
                % Perform OCR on the text regions using the ocr function
                results = ocr(image, textRegions, 'TextLayout', 'word', 'CharacterSet', 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789 ');
                % locate the specific text being searched for and ignore
                % case.
                box = locateText(results, texts(i),IgnoreCase=true);
                
                % iterate through the results from the search.
                for j=1:numel(box)
                    % if it is empty skip. This means the workd could not
                    % be located in this bounding box/
                    if isempty(box{j})
                        continue
                    end
                    % When detected create the new bounding with the x
                    % region being the width of the text and the y region
                    % being the bottom of the text and 100 pixels down.
                    boxes{i} = [box{j}(2) + box{j}(4) + boxes{i}(1), box{j}(2) + box{j}(4) + 100 + boxes{i}(1), box{j}(1) + boxes{i}(3), box{j}(1) + box{j}(3) + boxes{i}(3)];
                end
            end
            
            % Set the new heldRegion and nextRegion after doing ocr.
            obj.heldRegion = boxes{1};
            obj.nextRegion = boxes{2};
        end
        % Given 2D points in an array find the corresponding color of
        % those points in the image.
        function colors = getColorsFromProbes(obj, probes)
            
            colors = zeros(size(probes, 1), 3);
            for i = 1:size(probes, 1)
                x = probes(i, 1);
                y = probes(i, 2);
                
                % Get the RGB color at the specified coordinates
                colors(i, :) = squeeze(uint8(obj.image(y, x, :)));
            end
        end
        % Runs every iteration of the main loop. Is much more efficient due
        % to precalculation of regions of interest in the state() method.
        function obj = updateState(obj, img)
            
            obj.image = img;
            % Get the colors from the precalculated probes
            colors = obj.getColorsFromProbes(obj.probes);
            
            % Convert the colors to a state
            % Add a connector at the bottom to make sure that state is
            % labeled properly.
            tempData = [zeros(20, 10); ones(1, 10)];
            colMatrix = zeros(20, 10, 3);
            
            % Iterate through the probe results
            for i = 1:20
                for j = 1:10
                    % If the color detected by the probe is white, black or
                    % the background color that position in the state is
                    % empty. The color matrix is filled with black in that
                    % position.

                    % If it is not any of those colors the state has a
                    % block at that location. The color matrix is set to
                    % the color detected by the probe.
                    if isequal(colors((i - 1) * 10 + j, :), obj.backgroundColor) || isequal(colors((i - 1) * 10 + j, :), [0, 0, 0]) || isequal(colors((i - 1) * 10 + j, :), [255, 255, 255])
                        tempData(i, j) = 0;
                        colMatrix(i, j, :) = [0 0 0];
                    else
                        tempData(i, j) = 1;
                        colMatrix(i, j, :) = colors((i - 1) * 10 + j, :);
                    end
                end
            end
            
            % Check state for islands. Islands are defined as 1s surrounded
            % by 0s.
            [labels , noOfIslands] = bwlabel(tempData);
            islands = cell(noOfIslands, 1);
            
            % The highest island is the one that is closest to the bottom. The one closest to the bottom is the tetris state.
            island = labels(21, 1);
            
            % iterates through the labels and creates a cell array of
            % coordinates for each island. 
            for i =1:20
                for j = 1:10
                    if labels(i, j) ~= 0
                        islands{labels(i, j)} = [islands{labels(i, j)}; i, j];
                    end
                end
            end

            % The state is detected properely with no issues.
            if noOfIslands == 2
                % removes the island that is the piece.
                obj.data = labels(1:20, :) == island;
                % gets the label for the piece island
                island = (2 - island) + 1;
            elseif noOfIslands ~= 1
                % There is an error
                error("No state found");
            end
            
            if noOfIslands ~= 1
                % go thorugh the piece island and set a vector of colors
                % for detecting its piece.
                colors = zeros(size(islands{island}, 1), 3);
                for i = 1:size(islands{island}, 1)
                    x = islands{island}(i, 2);
                    y = islands{island}(i, 1);
                    
                    colors(i, :) = squeeze(colMatrix(y, x, :));
                end
            else
                % the state and the piece is connected. Assume the piece is
                % between 5:6 x and 1:3 y.
                i = 0;
                % Check for colors in that region.
                colors = zeros(6, 1, 3);
                for x = 5:6
                    for y = 1:3
                        % If there is something in the position save its
                        % color for detecting the piece and zero it out to
                        % create the state.
                        if labels(y, x)
                            i = i + 1;
                            colors(i, :) = squeeze(colMatrix(y, x, :));
                            labels(y, x) = 0;
                        end
                    end
                end
                % Creates the state and piece colors.
                obj.data = labels(1:20, :);
                colors = colors(1:i, :, :);
            end
                        
            % Finds the possible piece by using the utlity function that
            % converts a given color to a piece.
            possiblePieces = zeros(size(colors, 1), 0);
            for i = 1:size(colors, 1)
                possiblePieces(i) = pieces.getPieceFromColor(colors(i, :), obj.backgroundColor);
            end
            % The modal piece is used and set to be the current piece
            obj.piece = pieces.getPiece(mode(possiblePieces));
            
            
            % Get the held piece and next piece. The image is cropped
            % according to the correct region.
            obj.heldPiece = obj.findMostLikelyPieceInRegion(double(obj.image(obj.heldRegion(1):obj.heldRegion(2), obj.heldRegion(3):obj.heldRegion(4), :)));
            obj.nextPiece = obj.findMostLikelyPieceInRegion(double(obj.image(obj.nextRegion(1):obj.nextRegion(2), obj.nextRegion(3):obj.nextRegion(4), :)));
            
        end
        
        function piece = findMostLikelyPieceInRegion(obj, img)
            % Sets up tables from pice index to distances and frequencies.
            % Lower distance is better, Higher frequency is better.
            distances = [1 255; 2 255; 3 255; 4 255; 5 255; 6 255; 7 255;];
            frequencies = [1 0; 2 0; 3 0; 4 0; 5 0; 6 0; 7 0;];
            
            % Probe the x axis of the image every 5 pixels. Iterates from
            % left to right and top to bottom.
            for x=1:5:size(img, 2)
                foundPiece = false;
                % Probes image every 10 pixels.
                for y=1:10:size(img, 1)
                    % Gets the distance and possible piece shown by
                    % distance in using the utility function in pieces.
                    [possiblePiece, dist] = pieces.getPieceFromColor(squeeze(img(y, x, :))', obj.backgroundColor);
                    % If the distance is greater than 75 or
                    % possiblePicesIndex >= 8 (nop) do not save this piece
                    if dist > 75 || possiblePiece >= 8
                        % After finding a piece if the code reaches here
                        % that means further probing downwards is useless.
                        if foundPiece
                            break
                        end
                        continue;
                    end
                    % If the code hits here a piece is found and found
                    % piece is set to true.
                    foundPiece = true;
                    % find the distance and increment the frequency of the
                    % piece. Set distance as the minimum distance.
                    distances(possiblePiece, :) = [possiblePiece, min(distances(possiblePiece, 2), dist)];
                    frequencies(possiblePiece, :) = [possiblePiece, frequencies(possiblePiece, 2) + 1];
                end
            end
            
            % Sort the tables
            sortedDistances = sortrows(distances, 2);
            sortedFrequencies = sortrows(frequencies, -2);        
            
            % If the difference between the first place and second place for frequency is
            % too great you can ignore distance.
            if(sortedFrequencies(1, 2) - sortedFrequencies(2, 2) > 10)
                piece = pieces.getPiece(sortedFrequencies(1, 1));
                return
            end
            
            scores = zeros(1, 7);
            
            % Calculates the scores. First place gets you 1 point and
            % second place gets you two points ..etc.. The lower the points
            % the better. The points recieved by distance and frequncy are
            % weighted to the favor of the distance.
            for i=1:7
                scores(sortedDistances(i, 1)) = scores(sortedDistances(i, 1)) + 0.4 * i;
                scores(sortedFrequencies(i, 1)) = scores(sortedFrequencies(i, 1)) + 0.6 * i;
            end
            
            % Find the minimum score
            [~, index] = min(scores);
            
            % If the frequencies are zeros that means that there was no
            % piece detected, otherwise set the piece according to the
            % score.
            if isequal(frequencies(:, 2), zeros(7,1))
                piece = pieces.nop;
            else
                piece = pieces.getPiece(index);
            end
        end
        
    end
end