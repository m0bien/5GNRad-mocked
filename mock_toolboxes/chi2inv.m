function x = chi2inv(p, v)
    % CHI2INV Inverse chi-square cumulative distribution function (CDF).
    %   X = CHI2INV(P, V) returns the inverse CDF for the chi-square
    %   distribution with V degrees of freedom at the values in P.
    
    if p <= 0
        x = 0;
        return;
    elseif p >= 1
        x = Inf;
        return;
    end
    
    % Bisection search range
    x_low = 0;
    x_high = 1000; % Safe upper bound for small dof and standard p values
    
    % Bisection loop to solve gammainc(x/2, v/2) = p
    for iter = 1:50
        x_mid = (x_low + x_high) / 2;
        cdf = gammainc(x_mid / 2, v / 2);
        
        if cdf < p
            x_low = x_mid;
        else
            x_high = x_mid;
        end
    end
    
    x = (x_low + x_high) / 2;
end
