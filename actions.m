classdef actions
    enumeration
        rotate, drop, left, right, hold
    end
    
    methods
        function actionsList = GetActionsList(obj, endPosition, hold)
            arguments
                obj actions
                endPosition (1, 3) {mustBeNumeric}
                hold {mustBeNumericOrLogical}
            end
        end
        
    end
    
    
end