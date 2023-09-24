classdef state
    properties(Constant)
        kernel = kdgauss(0.25);
        invkernel = kdgauss(0.25)';
        crop = [0.18, 0.94, 0.19, 0.71];
        mid = [5:10:200, 6:10:200]
    end
    properties
        image
        probes (200, 2) {mustBeNumericOrLogical}
        data (20, 10)
        piece pieces
        nextPiece pieces
        heldPiece pieces
        backgroundColors {mustBeNumeric}
    end
    methods
        % Create state given the capture of the screen
        function obj = state(data)
            
            % Crop the data
            % 1600*2560 = [300, 1500, 500, 1800];
            obj.image = data;
            
            crop = uint16([size(data, 1) *  state.crop(1), size(data, 1) * state.crop(2), size(data, 2) * state.crop(3), size(data, 2) * state.crop(4)]);
            data = obj.image(crop(1):crop(2), crop(3):crop(4), :);
            
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
            
            %imshow(obj.image)
            %hold on
            
            for k = 1:length(boundaries)
                if numel(boundaries) < 8
                    continue
                end
                
                shape = polyshape(boundaries{k}(:, 2), boundaries{k}(:, 1), "KeepCollinearPoints", false);
                % TEMP
                % shape = polyshape(boundaries{k}(:, 2) + double(crop(3)), boundaries{k}(:, 1) + double(crop(1)), "KeepCollinearPoints", false);
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
                %plot(shape)
                
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
            for y=miY+(tetrisSquareY/2):tetrisSquareY:maY
                for x=miX+(tetrisSquareX/2):tetrisSquareX:maX
                    i = i + 1;
                    obj.probes(i, :) = uint16([x y]);
                end
            end
            
            
            colors = obj.getColorsFromProbes(obj.probes);
            
            obj.updateState();
            
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
            if nargin > 1
                obj.image = img;
            end
            
        end
        
        
    end
end
