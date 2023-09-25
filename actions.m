classdef actions
    % The different actions supported.
    enumeration
        rotate, drop, left, right, hold
    end
    
    methods (Static)
        function actionsList = GetActionsList(endPosition, piece, hold)
            arguments
                endPosition (1, 3) {mustBeNumeric}
                piece pieces
                hold {mustBeNumericOrLogical}
            end
            
            % Gets the predefined start positions.
            x = piece.getStartX();
            % Looks at how rotation of the piiece will affect the start x
            % positions
            x = x + piece.getRotationMovement(endPosition(3));
            % Gets the delta between the endX position and startX posision.
            x = int8(endPosition(1)) - int8(x);
            
            % If the solver tells to hold, click on the hold button first
            % before doing anything
            if hold
                actionsList = [actions.hold];
            else
                actionsList = [];
            end
            
            % appends to the actionsList the rotations that it has to do, then the
            % x movements and finally the drop command. This AI can only
            % work with dropping pieces and cannot do more complicated
            % manuevers.
            if x >= 0 % If the delta is greater than or equal to zero moving right
                actionsList = [actionsList, repmat(actions.rotate, 1, endPosition(3) - 1) ,repmat(actions.right, 1, x), actions.drop];
            else % moving left
                actionsList = [actionsList, repmat(actions.rotate, 1, endPosition(3) - 1) ,repmat(actions.left, 1, -x), actions.drop];
            end
        end
    end
end