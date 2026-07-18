function info = nrOFDMInfo(carrier)
    scs = carrier.SubcarrierSpacing;
    nSize = carrier.NSizeGrid;
    nSubcarriers = nSize * 12;
    
    % Find smallest standard FFT size
    Nfft = 2^nextpow2(nSubcarriers);
    if Nfft < 128
        Nfft = 128;
    end
    
    SampleRate = Nfft * scs * 1000;
    
    % CP lengths for one slot (14 symbols)
    cp0_7 = round(Nfft * 160 / 2048);
    cp_other = round(Nfft * 144 / 2048);
    
    cpSlot = repmat(cp_other, 1, 14);
    cpSlot(1) = cp0_7;
    cpSlot(8) = cp0_7;
    
    % nrOFDMInfo returns CP and Symbol lengths for a SUBFRAME.
    % Number of slots in a subframe:
    slotsPerSubframe = scs / 15;
    
    % Repeat slot CP lengths for all slots in the subframe
    CyclicPrefixLengths = repmat(cpSlot, 1, slotsPerSubframe);
    
    info.Nfft = Nfft;
    info.CyclicPrefixLengths = CyclicPrefixLengths;
    info.SampleRate = SampleRate;
    info.SymbolLengths = repmat(Nfft, 1, 14 * slotsPerSubframe) + CyclicPrefixLengths;
end
