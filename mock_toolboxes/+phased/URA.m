classdef URA < handle
    properties
        Size = [2 2]
        ElementSpacing = [0.5 0.5]
        Element
    end
    methods
        function obj = URA(varargin)
            startIdx = 1;
            if nargin > 0 && isnumeric(varargin{1})
                obj.Size = varargin{1};
                startIdx = 2;
            end
            for k = startIdx:2:nargin
                obj.(varargin{k}) = varargin{k+1};
            end
        end
        function pos = getElementPosition(obj)
            M = obj.Size(1);
            N = obj.Size(2);
            if isscalar(obj.ElementSpacing)
                dV = obj.ElementSpacing;
                dH = obj.ElementSpacing;
            else
                dV = obj.ElementSpacing(1);
                dH = obj.ElementSpacing(2);
            end
            
            % URA is in YZ plane. Z increases along vertical (first dim of Size/M),
            % Y increases along horizontal (second dim of Size/N).
            y_vals = ((0:N-1) - (N-1)/2) * dH;
            z_vals = ((0:M-1) - (M-1)/2) * dV;
            
            [Z, Y] = meshgrid(z_vals, y_vals);
            Z = Z.';
            Y = Y.';
            
            pos = [zeros(1, M*N); Y(:).'; Z(:).'];
        end
    end
end
