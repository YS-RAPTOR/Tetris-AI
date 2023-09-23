classdef actions
    enumeration
        rotate, drop, left, right, hold
    end
    
    methods
        function actionsList = GetActionsList(obj, endPosition, piece, hold)
            arguments
                obj actions
                endPosition (1, 3) {mustBeNumeric}
                piece pieces
                hold {mustBeNumericOrLogical}
            end
            
            x = piece.getStartX();
            x = x + piece.getRotationMovement(endPosition(3));
            x = endPosition(1) - x;
            
            if hold
                actionsList = [actions.hold];
            end
            
            if x >= 0
                actionsList = [actionsList, repmat(actions.rotate, 1, endPosition(3) - 1) ,repmat(actions.right, 1, x), actions.drop];
            else
                actionsList = [actionsList, repmat(actions.rotate, 1, endPosition(3) - 1) ,repmat(actions.left, 1, -x), actions.drop];
            end
        end
    end
end