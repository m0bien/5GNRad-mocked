function info = nrOFDMInfo(carrier)
    scs = carrier.SubcarrierSpacing;
    nSize = carrier.NSizeGrid;
    nSubcarriers = nSize * 12;
    
    % Find smallest standard FFT size
    Nfft = 2^nextpow2(nSubcarriers);
    if Nfft < 128
        Nfft = 128; % minimum standard FFT size
    end
    
    SampleRate = Nfft * scs * 1000;
    
    % CP lengths for Normal CP
    cp0_7 = round(Nfft * 160 / 2048);
    cp_other = round(Nfft * 144 / 2048);
    
    CyclicPrefixLengths = repmat(cp_other, 1, 14);
    CyclicPrefixLengths(1) = cp0_7;
    CyclicPrefixLengths(8) = cp0_7;
    
    info.Nfft = Nfft;
    info.CyclicPrefixLengths = CyclicPrefixLengths;
    info.SampleRate = SampleRate;
    info.SymbolLengths = repmat(Nfft, 1, 14) + CyclicPrefixLengths;
end
