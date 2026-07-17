function indCell = nrPRSIndices(carrier, prs, varargin)
    nSubcarriers = carrier.NSizeGrid * 12;
    numSymPerSlot = carrier.SymbolsPerSlot;
    
    indices = [];
    for l = prs.SymbolStart : prs.SymbolStart + prs.NumPRSSymbols - 1
        col = l + 1;
        % combOffset formula
        combOffset = mod(l - prs.SymbolStart, prs.CombSize) + prs.REOffset;
        
        % Subcarriers for this symbol
        % Note: MATLAB is 1-based, so subcarrier index starts at 1
        % We also have RBOffset (in RBs, each RB has 12 subcarriers)
        startSubcarrier = prs.RBOffset * 12 + combOffset + 1;
        subcarriers = startSubcarrier : prs.CombSize : nSubcarriers;
        
        % Linear indices in a grid of size [nSubcarriers, numSymPerSlot]
        linIdx = subcarriers + (col - 1) * nSubcarriers;
        indices = [indices; linIdx(:)];
    end
    
    indCell = {indices};
end
