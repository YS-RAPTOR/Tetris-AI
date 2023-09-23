classdef state
    properties (SetAccess = immutable)
        data (20, 10) {mustBeNumericOrLogical}
    end
    methods
        % Create state given the capture of the screen
        function obj = state(data)
            obj.data = data;
        end
    end
end