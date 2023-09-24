classdef pieces
    enumeration
        I,
        O,
        T,
        S,
        Z,
        J,
        L,
        nop
    end
    properties (Constant)
        possibleOrientations  = {
            {uint8([1, 1, 1, 1]), uint8([1; 1; 1; 1])};
            {uint8([1, 1; 1, 1])};
            {uint8([0, 1, 0; 1, 1, 1]), uint8([1, 0; 1, 1; 1, 0]), uint8([1, 1, 1; 0, 1, 0]), uint8([0, 1; 1, 1; 0, 1])};
            {uint8([0, 1, 1; 1, 1, 0]), uint8([1, 0; 1, 1; 0, 1])};
            {uint8([1, 1, 0; 0, 1, 1]), uint8([0, 1; 1, 1; 1, 0])};
            {uint8([1, 0, 0; 1, 1, 1]), uint8([1, 1; 1, 0; 1, 0]), uint8([1, 1, 1; 0, 0, 1]), uint8([0, 1; 0, 1; 1, 1])};
            {uint8([0, 0, 1; 1, 1, 1]), uint8([1, 0; 1, 0; 1, 1]), uint8([1, 1, 1; 1, 0, 0]), uint8([1, 1; 0, 1; 0, 1])};
            };
        
        heightMapSubtractions = {
            {uint8([0, 0, 0, 0]), uint8(0)};
            {uint8([0, 0])};
            {uint8([0,0,0]), uint8([0, 1]), uint8([1, 0, 1]), uint8([1, 0])};
            {uint8([0, 0, 1]), uint8([1, 0])};
            {uint8([1, 0, 0]), uint8([0, 1])};
            {uint8([0, 0, 0]), uint8([0, 2]), uint8([1, 1, 0]), uint8([0, 0])};
            {uint8([0, 0, 0]), uint8([0, 0]), uint8([0, 1, 1]), uint8([2, 0])};
            };
        
        startX = uint8([4, 5, 4, 4, 4, 4, 4])
        
        rotationMovement = {
            {uint(0), uint(2)};
            {uint(0)};
            {uint(0), uint(1), uint(0), uint(0)};
            {uint(0), uint(1)};
            {uint(0), uint(1)};
            {uint(0), uint(1), uint(0), uint(0)};
            {uint(0), uint(1), uint(0), uint(0)};
            };
        
        pieceColors = {
            [49, 199, 239];
            [247, 211, 8];
            [173, 77, 156];
            [66, 182, 66];
            [239, 32, 41];
            [90, 101, 173];
            [239, 121, 33];
            };
    end
    
    methods
        function orientations = getOrientations(obj)
            switch obj
                case pieces.I
                    orientations = obj.possibleOrientations{1};
                case pieces.O
                    orientations = obj.possibleOrientations{2};
                case pieces.T
                    orientations = obj.possibleOrientations{3};
                case pieces.S
                    orientations = obj.possibleOrientations{4};
                case pieces.Z
                    orientations = obj.possibleOrientations{5};
                case pieces.J
                    orientations = obj.possibleOrientations{6};
                case pieces.L
                    orientations = obj.possibleOrientations{7};
                case pieces.nop
                    error('nop has no orientations');
            end
        end
        
        function orientation = getOrientation(obj, orientationIndex)
            switch obj
                case pieces.I
                    orientation = obj.possibleOrientations{1}{orientationIndex};
                case pieces.O
                    orientation = obj.possibleOrientations{2}{orientationIndex};
                case pieces.T
                    orientation = obj.possibleOrientations{3}{orientationIndex};
                case pieces.S
                    orientation = obj.possibleOrientations{4}{orientationIndex};
                case pieces.Z
                    orientation = obj.possibleOrientations{5}{orientationIndex};
                case pieces.J
                    orientation = obj.possibleOrientations{6}{orientationIndex};
                case pieces.L
                    orientation = obj.possibleOrientations{7}{orientationIndex};
                case pieces.nop
                    error('nop has no orientations');
            end
        end
        
        function subtractions = getHeightMapSubtractions(obj)
            switch obj
                case pieces.I
                    subtractions = obj.heightMapSubtractions{1};
                case pieces.O
                    subtractions = obj.heightMapSubtractions{2};
                case pieces.T
                    subtractions = obj.heightMapSubtractions{3};
                case pieces.S
                    subtractions = obj.heightMapSubtractions{4};
                case pieces.Z
                    subtractions = obj.heightMapSubtractions{5};
                case pieces.J
                    subtractions = obj.heightMapSubtractions{6};
                case pieces.L
                    subtractions = obj.heightMapSubtractions{7};
                case pieces.nop
                    error('nop has no height map subtractions');
            end
        end
        function x = getStartX(obj)
            switch obj
                case pieces.I
                    x = obj.startX(1);
                case pieces.O
                    x = obj.startX(2);
                case pieces.T
                    x = obj.startX(3);
                case pieces.S
                    x = obj.startX(4);
                case pieces.Z
                    x = obj.startX(5);
                case pieces.J
                    x = obj.startX(6);
                case pieces.L
                    x = obj.startX(7);
                case pieces.nop
                    error('nop has no start x');
            end
        end
        
        function x = getRotationMovement(obj, orientationIndex)
            switch obj
                case pieces.I
                    x = obj.rotationMovement{1}{orientationIndex};
                case pieces.O
                    x = obj.rotationMovement{2}{orientationIndex};
                case pieces.T
                    x = obj.rotationMovement{3}{orientationIndex};
                case pieces.S
                    x = obj.rotationMovement{4}{orientationIndex};
                case pieces.Z
                    x = obj.rotationMovement{5}{orientationIndex};
                case pieces.J
                    x = obj.rotationMovement{6}{orientationIndex};
                case pieces.L
                    x = obj.rotationMovement{7}{orientationIndex};
                case pieces.nop
                    error('nop has no rotation movement');
            end
        end
        
        
    end
    
    methods (Static)
        function [pieceIndex, dist] = getPieceFromColor(color, backgroundColor)

            if max(color) - min(color) < 10
                dist = 255;
                pieceIndex = 8;
                return;
            end

            % Check distance to all colors including background color
            distances = zeros(1, 9);
            for i = 1:7
                distances(i) = sqrt(sum((color - pieces.pieceColors{i}).^2));
            end
            distances(8) = sqrt(sum((color - backgroundColor).^2));
            distances(9) = sqrt(sum((color - [255, 255, 255]).^2));
            [dist, pieceIndex] = min(distances);
        end
        
        function piece = getPiece(index)
            switch index
                case 1
                    piece = pieces.I;
                case 2
                    piece = pieces.O;
                case 3
                    piece = pieces.T;
                case 4
                    piece = pieces.S;
                case 5
                    piece = pieces.Z;
                case 6
                    piece = pieces.J;
                case 7
                    piece = pieces.L;
                otherwise
                    piece = pieces.nop;
            end
        end
    end
end