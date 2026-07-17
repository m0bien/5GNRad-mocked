classdef SteeringVector < handle
    properties
        SensorArray
        IncludeElementResponse = true
    end
    methods
        function obj = SteeringVector(varargin)
            for k = 1:2:nargin
                obj.(varargin{k}) = varargin{k+1};
            end
        end
        
        function varargout = subsref(obj, s)
            if strcmp(s(1).type, '()')
                [varargout{1:nargout}] = obj.evaluate(s(1).subs{:});
            else
                [varargout{1:nargout}] = builtin('subsref', obj, s);
            end
        end
        
        function A = evaluate(obj, fc, ang, wElem)
            lambda = 299792458 / fc;
            
            % ang: 2 x P matrix [az; el] in degrees
            az = ang(1, :);
            el = ang(2, :);
            
            % Unit vectors pointing towards directions
            ux = cosd(el) .* cosd(az);
            uy = cosd(el) .* sind(az);
            uz = sind(el);
            u = [ux; uy; uz]; % 3 x P
            
            if nargin < 4 || isempty(wElem)
                % Standard element-level steering vector
                pos = getElementPosition(obj.SensorArray);
                A = exp(1j * 2 * pi * (pos.' * u) / lambda);
            else
                % Subarray-level combined steering vector for ReplicatedSubarray
                % wElem is NelemSub x Nsub
                posSub = getElementPosition(obj.SensorArray.Subarray);
                NelemSub = size(posSub, 2);
                
                Mg = obj.SensorArray.GridSize(1);
                Ng = obj.SensorArray.GridSize(2);
                Nsub = Mg * Ng;
                
                if isscalar(obj.SensorArray.GridSpacing)
                    spV = obj.SensorArray.GridSpacing;
                    spH = obj.SensorArray.GridSpacing;
                else
                    spV = obj.SensorArray.GridSpacing(1);
                    spH = obj.SensorArray.GridSpacing(2);
                end
                
                % Compute offsets for each subarray
                offset = zeros(3, Nsub);
                for j = 1:Nsub
                    ng = floor((j-1)/Mg) + 1;
                    mg = mod(j-1, Mg) + 1;
                    shift_y = (ng - 1 - (Ng-1)/2) * spH;
                    shift_z = (mg - 1 - (Mg-1)/2) * spV;
                    offset(:, j) = [0; shift_y; shift_z];
                end
                
                P = size(ang, 2);
                A = zeros(Nsub, P);
                for p = 1:P
                    u_p = u(:, p);
                    phaseSub = exp(1j * 2 * pi * (posSub.' * u_p) / lambda);
                    phaseOffset = exp(1j * 2 * pi * (offset.' * u_p) / lambda);
                    A(:, p) = phaseOffset .* sum(wElem .* phaseSub, 1).';
                end
            end
        end
    end
end
