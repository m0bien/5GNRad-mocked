classdef nrCarrierConfig < handle
    properties
        SubcarrierSpacing = 15
        NSizeGrid = 52
        CyclicPrefix = 'Normal'
        NSlot = 0
        NCellID = 0
        NStartGrid = 0
    end
    properties (Dependent)
        SymbolsPerSlot
        SlotsPerSubframe
        SlotsPerFrame
    end
    methods
        function val = get.SymbolsPerSlot(obj)
            val = 14; % normal CP
        end
        function val = get.SlotsPerSubframe(obj)
            val = obj.SubcarrierSpacing / 15;
        end
        function val = get.SlotsPerFrame(obj)
            val = 10 * obj.SlotsPerSubframe;
        end
    end
end
