classdef state
    properties(Constant)
        kernel = kdgauss(0.5);
        invkernel = kdgauss(0.5)';
        crop = [0.18, 0.94, 0.19, 0.71];
    end
    properties
        probes (200, 2) {mustBeNumericOrLogical}
        data (20, 10)
        piece pieces
        nextPiece pieces
        heldPiece pieces
    end
    methods
        % Create state given the capture of the screen
        function obj = state(data)
            
            % Crop the data
            % 1600*2560 = [300, 1500, 500, 1800];
            
            crop = [size(tetris, 1) *  state.crop(1), size(tetris, 1) * state.crop(2), size(tetris, 2) * state.crop(3), size(tetris, 2) * state.crop(4)];
            data = data(crop(1):crop(2), crop(3):crop(4), :);
            
            % Do Edge Detection on the images
            Iu = iconvolve(data, obj.kernel);
            Iv = iconvolve(data, obj.invkernel);
            
            data = sqrt(Iu.^2 + Iv.^2);
            
            % Convert the data to binary with high threshold
            data = rgb2gray(data) < 0.001;
            
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
            miX = min(rectanglesOfInterest.Vertices(:, 1)) + crop(3);
            maX = max(rectanglesOfInterest.Vertices(:, 1)) + crop(3);
            miY = min(rectanglesOfInterest.Vertices(:, 2)) + crop(1);
            maY = max(rectanglesOfInterest.Vertices(:, 2)) + crop(1);
            
            tetrisSquareX = (maX - miX) / 10;
            tetrisSquareY = (maY - miY) / 20;
            i = 0;
            for x=miX+(tetrisSquareX/2):tetrisSquareX:maX
                for y=miY+(tetrisSquareY/2):tetrisSquareY:maY
                    i = i + 1;
                    obj.probes(i, :) = uint16([x y]);
                end
            end
        end
        
    end
end
