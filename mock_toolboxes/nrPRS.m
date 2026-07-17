function symCell = nrPRS(carrier, prs, varargin)
    % Generates QPSK values for the PRS indices.
    
    indCell = nrPRSIndices(carrier, prs);
    numSymbols = numel(indCell{1});
    
    % Generate QPSK symbols using a deterministic random number generator
    % so that they are identical every time we call nrPRS for the same config.
    s = randstream_deterministic(prs.NPRSID, numSymbols);
    symbols = (2 * round(s(1:numSymbols)) - 1) + 1i * (2 * round(s(numSymbols+1:end)) - 1);
    symbols = symbols / sqrt(2);
    
    symCell = {symbols(:)};
end

function s = randstream_deterministic(seed, n)
    a = 1664525;
    c = 1013904223;
    m = 2^32;
    
    s = zeros(2 * n, 1);
    val = mod(seed, m);
    for k = 1 : 2 * n
        val = mod(a * val + c, m);
        s(k) = val / m;
    end
end
