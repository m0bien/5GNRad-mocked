classdef ULA < handle
    properties
        NumElements = 4
        ElementSpacing = 0.5
        Element
        ArrayAxis = 'y'
    end
    methods
        function obj = ULA(varargin)
            startIdx = 1;
            if nargin > 0 && isnumeric(varargin{1})
                obj.NumElements = varargin{1};
                startIdx = 2;
            end
            for k = startIdx:2:nargin
                obj.(varargin{k}) = varargin{k+1};
            end
        end
        function pos = getElementPosition(obj)
            d = ((0:obj.NumElements-1) - (obj.NumElements-1)/2) * obj.ElementSpacing;
            pos = zeros(3, obj.NumElements);
            if strcmpi(obj.ArrayAxis, 'x')
                pos(1,:) = d;
            elseif strcmpi(obj.ArrayAxis, 'z')
                pos(3,:) = d;
            else % default 'y'
                pos(2,:) = d;
            end
        end
    end
end
