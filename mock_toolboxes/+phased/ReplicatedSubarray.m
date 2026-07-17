classdef ReplicatedSubarray < handle
    properties
        Subarray
        Layout = 'Rectangular'
        GridSize = [1 1]
        GridSpacing = [0.5 0.5]
        SubarraySteering = 'None'
    end
    methods
        function obj = ReplicatedSubarray(varargin)
            for k = 1:2:nargin
                obj.(varargin{k}) = varargin{k+1};
            end
        end
        function pos = getElementPosition(obj)
            posSub = getElementPosition(obj.Subarray);
            Mg = obj.GridSize(1);
            Ng = obj.GridSize(2);
            
            if isscalar(obj.GridSpacing)
                spV = obj.GridSpacing;
                spH = obj.GridSpacing;
            else
                spV = obj.GridSpacing(1);
                spH = obj.GridSpacing(2);
            end
            
            pos = [];
            for ng = 1:Ng
                for mg = 1:Mg
                    shift_y = (ng - 1 - (Ng-1)/2) * spH;
                    shift_z = (mg - 1 - (Mg-1)/2) * spV;
                    pos = [pos, posSub + [0; shift_y; shift_z]];
                end
            end
        end
    end
end
