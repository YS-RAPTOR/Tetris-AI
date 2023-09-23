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
    properties (SetAccess = immutable)
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
    end
end