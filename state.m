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
        % Create state given the capture of the screen
        function obj = state(data)
            
            % Crop the data
            % 1600*2560 = [300, 1500, 500, 1800];
            obj.image = data;
            
            obj.absCrop = uint16([size(data, 1) *  state.crop(1), size(data, 1) * state.crop(2), size(data, 2) * state.crop(3), size(data, 2) * state.crop(4)]);
            data = obj.image(obj.absCrop(1):obj.absCrop(2), obj.absCrop(3):obj.absCrop(4), :);
            
            % Do Edge Detection on the images
            Iu = iconvolve(data, obj.kernel);
            Iv = iconvolve(data, obj.invkernel);
            
            data = sqrt(Iu.^2 + Iv.^2);
            
            % Convert the data to binary with high threshold
            data = rgb2gray(data) < 0.0001;
            
            % Get the shapes described by the data
            boundaries = bwboundaries(data);
            
            rectanglesOfInterest = polyshape.empty(0, 1);
            squaresOfInterest = polyshape.empty(0, 200);
            
            rectangleIndex = 0;
            squareIndex = 0;
            
            for k = 1:length(boundaries)
                if numel(boundaries) < 8
                    continue
                end
                
                shape = polyshape(boundaries{k}(:, 2), boundaries{k}(:, 1), "KeepCollinearPoints", false);
                
                if shape.NumRegions ~= 1
                    continue
                end
                
                miX = min(shape.Vertices(:, 1));
                maX = max(shape.Vertices(:, 1));
                miY = min(shape.Vertices(:, 2));
                maY = max(shape.Vertices(:, 2));
                
                width = maX - miX;
                height = maY - miY;
                
                if width < 25 || height < 25
                    continue;
                end
                
                if numrows(shape.Vertices) > 18
                    continue
                end
                
                aspectRatio = height/width;
                if aspectRatio > 1.75
                    rectangleIndex = rectangleIndex + 1;
                    rectanglesOfInterest(rectangleIndex) = shape;
                elseif aspectRatio > 0.9 && aspectRatio < 1.1 && shape.numsides < 10
                    squareIndex = squareIndex + 1;
                    squaresOfInterest(squareIndex) = shape;
                end
            end
            
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
            
            % Get the rectangle corners
            miX = min(rectanglesOfInterest.Vertices(:, 1)) + obj.absCrop(3);
            maX = max(rectanglesOfInterest.Vertices(:, 1)) + obj.absCrop(3);
            miY = min(rectanglesOfInterest.Vertices(:, 2)) + obj.absCrop(1);
            maY = max(rectanglesOfInterest.Vertices(:, 2)) + obj.absCrop(1);
            
            obj.squareSize = [(maX - miX) / 10 ,(maY - miY) / 20];
            obj.board = [miX, maX, miY, maY];
            
            i = 0;
            for y=miY+(obj.squareSize(2)/2):obj.squareSize(2):maY
                for x=miX+(obj.squareSize(1)/2):obj.squareSize(1):maX
                    i = i + 1;
                    obj.probes(i, :) = uint16([x y]);
                end
            end
            
            
            colors = obj.getColorsFromProbes(obj.probes);
            obj.backgroundColor = mode(colors);
            
            obj.heldRegion = [obj.absCrop(1),0.5*(obj.board(3) + obj.board(4)), obj.absCrop(3), obj.board(1)];
            obj.nextRegion = [obj.absCrop(1),0.5*(obj.board(3) + obj.board(4)), obj.board(2), obj.absCrop(4)];
            images = uint8(rgb2gray(obj.image) < 200)*255;
            images = {images(obj.heldRegion(1):obj.heldRegion(2), obj.heldRegion(3):obj.heldRegion(4), :), images(obj.nextRegion(1):obj.nextRegion(2), obj.nextRegion(3):obj.nextRegion(4), :)};
            texts = ["hold", "next"];
            boxes = {obj.heldRegion, obj.nextRegion};
            
            for i=1:numel(images)
                image = images{i};
                textRegions = detectTextCRAFT(image);
                
                % Perform OCR on the text regions using the ocr function
                results = ocr(image, textRegions, 'TextLayout', 'word', 'CharacterSet', 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789 ');
                box = locateText(results, texts(i),IgnoreCase=true);
                
                for j=1:numel(box)
                    if isempty(box{j})
                        continue
                    end
                    boxes{i} = [box{j}(2) + box{j}(4) + boxes{i}(1), box{j}(2) + box{j}(4) + 100 + boxes{i}(1), box{j}(1) + boxes{i}(3), box{j}(1) + box{j}(3) + boxes{i}(3)];
                end
            end
            
            obj.heldRegion = boxes{1};
            obj.nextRegion = boxes{2};
        end
        
        function probes = getProbes(obj, xs, ys)
            probes = zeros(numel(xs) * numel(ys), 2);
            i = 0;
            for y=ys
                for x=xs
                    i = i + 1;
                    probes(i, :) = obj.probes( (y - 1) * 10 + x, :);
                end
            end
            
        end
        
        function colors = getColorsFromProbes(obj, probes)
            colors = zeros(size(probes, 1), 3);
            for i = 1:size(probes, 1)
                x = probes(i, 1);
                y = probes(i, 2);
                
                % Get the RGB color at the specified coordinates
                colors(i, :) = squeeze(uint8(obj.image(y, x, :))); % Normalize to [0, 1]
            end
        end
        
        function obj = updateState(obj, img)
            obj.image = img;
            % Get State of the board
            colors = obj.getColorsFromProbes(obj.probes);
            
            % Convert the pieces to a state
            obj.data = zeros(20, 10);
            colMatrix = zeros(20, 10, 3);
            
            for i = 1:20
                for j = 1:10
                    if colors((i - 1) * 10 + j, :) == obj.backgroundColor
                        obj.data(i, j) = 0;
                        colMatrix(i, j, :) = [0 0 0];
                    else
                        obj.data(i, j) = 1;
                        colMatrix(i, j, :) = colors((i - 1) * 10 + j, :);
                    end
                end
            end
            
            % Check state for islands
            [labels , noOfIslands] = bwlabel(obj.data);
            islands = cell(noOfIslands, 1);
            
            % The highest island is the one that is closest to the bottom. The one closest to the bottom is the tetris state.
            island = 0;
            highest = 0;
            
            for i =1:20
                for j = 1:10
                    if labels(i, j) ~= 0
                        islands{labels(i, j)} = [islands{labels(i, j)}; i, j];
                        
                        if i > highest
                            highest = i;
                            island = labels(i, j);
                        end
                    end
                end
            end
            % The state is empty and the piece is the only thing on the board
            if noOfIslands == 2
                obj.data = labels == island;
                island = (2 - island) + 1;
                
                % Error check
            elseif noOfIslands ~= 1
                error("No state found");
            end
            
            colors = zeros(size(islands{island}, 1), 3);
            for i = 1:size(islands{island}, 1)
                x = islands{island}(i, 2);
                y = islands{island}(i, 1);
                
                colors(i, :) = squeeze(colMatrix(y, x, :));
            end
            
            
            possiblePieces = zeros(size(colors, 1), 0);
            for i = 1:size(colors, 1)
                possiblePieces(i) = pieces.getPieceFromColor(colors(i, :), obj.backgroundColor);
            end
            obj.piece = pieces.getPiece(mode(possiblePieces));
            
            
            % Get the held piece and next piece
            obj.heldPiece = obj.findMostLikelyPieceInRegion(double(obj.image(obj.heldRegion(1):obj.heldRegion(2), obj.heldRegion(3):obj.heldRegion(4), :)));
            obj.nextPiece = obj.findMostLikelyPieceInRegion(double(obj.image(obj.nextRegion(1):obj.nextRegion(2), obj.nextRegion(3):obj.nextRegion(4), :)));
            
        end
        
        function piece = findMostLikelyPieceInRegion(obj, img)
            imshow(img/255)
            
            distances = [1 255; 2 255; 3 255; 4 255; 5 255; 6 255; 7 255;];
            frequencies = [1 0; 2 0; 3 0; 4 0; 5 0; 6 0; 7 0;];
            
            for x=1:5:size(img, 2)
                foundPiece = false;
                for y=1:10:size(img, 1)
                    [possiblePiece, dist] = pieces.getPieceFromColor(squeeze(img(y, x, :))', obj.backgroundColor);
                    if dist > 75 || possiblePiece >= 8 || foundPiece
                        continue;
                    end
                    
                    foundPiece = true;
                    distances(possiblePiece, :) = [possiblePiece, min(distances(possiblePiece, 2), dist)];
                    frequencies(possiblePiece, :) = [possiblePiece, frequencies(possiblePiece, 2) + 1];
                end
            end
            
            sortedDistances = sortrows(distances, 2);
            sortedFrequencies = sortrows(frequencies, -2);
            maxFreq = sum(sortedFrequencies(:,2));
            
            

            if(sortedFrequencies(1, 2) - sortedFrequencies(2, 2) > 10)
                piece = pieces.getPiece(sortedFrequencies(1, 1));
                return
            end
            
            scores = zeros(1, 7);
            
            for i=1:7
                scores(sortedDistances(i, 1)) = scores(sortedDistances(i, 1)) + 0.4 * i;
                scores(sortedFrequencies(i, 1)) = scores(sortedFrequencies(i, 1)) + 0.6 * i;
            end

            [~, index] = min(scores);
            
            if isequal(frequencies(:, 2), zeros(7,1))
                piece = pieces.nop;
            else
                piece = pieces.getPiece(index);
            end
        end
        
    end
end
