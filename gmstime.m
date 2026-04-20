% -----------------------------------------------------------------------------
%
%                           function gmst
%
%  inputs          description                    range / units
%    mjdut1      - modified julian date of ut1    days
%
%  outputs       :
%    gst         - greenwich sidereal time        0 to 2pi rad
%
% gst = gmstime(mjdut1);
% -----------------------------------------------------------------------------

function gst = gmstime(mjdut1)
        
        t0 = (floor(mjdut1) - 51544.5) / 36525.0;
        t  = (mjdut1        - 51544.5) / 36525.0;
        t2 = t * t ;
        t3 = t * t2;
        RetVal = 24110.54841 + 8640184.812866 * t0 + 0.093104 * t2 - 6.2e-6 * t3;
        RetVal = RetVal / 86400.0 + 1.002737909350795 * (mjdut1 - floor(mjdut1));
        RetVal = rem(RetVal, 1.0);
        
        if RetVal < 0.0
            RetVal = RetVal + 1.0;
        end
        
        gst = RetVal * 2.0 * pi;
        
end

