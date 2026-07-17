classdef NRAntennaElement < handle
    properties
        % No specific properties required
    end
    methods
        function varargout = pattern(obj, varargin)
            if nargout > 0
                % In case it gets called like pattern(nRAntennaElement, fc, 0, -90:90, 'CoordinateSystem', 'polar')
                % or pattern(nRAntennaElement, fc, -180:180, 0, 'CoordinateSystem', 'polar')
                varargout{1} = zeros(size(varargin{3}));
            end
        end
    end
end
