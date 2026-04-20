%
% ----------------------------------------------------------------------------
%
%                           function precess
%
%  this function calulates the transformation matrix that accounts for the effects
%    of preseccion. both the 1980 and 2000 theories are handled. note that the 
%    required parameters differ a little. 
%
%  author        : david vallado                  719-573-2600   25 jun 2002
%
%  revisions
%    vallado     - consolidate with iau 2000                     14 feb 2005
%
%  inputs          description                    range / units
%    ttt         - julian centuries of tt
%    opt         - method option                  '01', '02', '96', '80'
%
%  outputs       :
%    prec        - transformation matrix for mod - j2000 (80 only)
%    psia        - cannonical precession angle    rad    (00 only)
%    wa          - cannonical precession angle    rad    (00 only)
%    ea          - cannonical precession angle    rad    (00 only)
%    xa          - cannonical precession angle    rad    (00 only)
%
%  locals        :
%    ttt2        - ttt squared
%    ttt3        - ttt cubed
%    zeta        - precession angle               rad
%    z           - precession angle               rad
%    theta       - precession angle               rad
%    oblo        - obliquity value at j2000 epoch "%
%
%  coupling      :
%    none        -
%
%  references    :
%    vallado       2004, 214-216, 219-221
%
% [prec,psia,wa,ea,xa] = precess ( ttt, opt );
% ----------------------------------------------------------------------------

function [prec,psia,wa,ea,xa] = precess ( ttt, opt )
        
        convrt = pi / (180.0*3600.0);
        ttt2= ttt * ttt;
        ttt3= ttt2 * ttt;

        % ------------------- iau 77 precession angles --------------------
        if strcmp(opt,'80')
            psia =             5038.7784*ttt - 1.07259*ttt2 - 0.001147*ttt3; % "
            wa   = 84381.448                 + 0.05127*ttt2 - 0.007726*ttt3;
            ea   = 84381.448 -   46.8150*ttt - 0.00059*ttt2 + 0.001813*ttt3;
            xa   =               10.5526*ttt - 2.38064*ttt2 - 0.001125*ttt3;
            zeta =             2306.2181*ttt + 0.30188*ttt2 + 0.017998*ttt3; % "
            theta=             2004.3109*ttt - 0.42665*ttt2 - 0.041833*ttt3;
            z    =             2306.2181*ttt + 1.09468*ttt2 + 0.018203*ttt3;
          % ------------------ iau 00 precession angles -------------------
        else
            ttt4 = ttt2 * ttt2;
            ttt5 = ttt2 * ttt3;
            psia =             5038.47875*ttt - 1.07259*ttt2 - 0.001147*ttt3; % "
            wa   = 84381.448 -    0.02524*ttt + 0.05127*ttt2 - 0.007726*ttt3;
            ea   = 84381.448 -   46.84024*ttt - 0.00059*ttt2 + 0.001813*ttt3;
            xa   =               10.5526*ttt  - 2.38064*ttt2 - 0.001125*ttt3;
            zeta = 2.5976176 + 2306.0809506*ttt  + 0.3019015 *ttt2 + 0.0179663*ttt3 ...
                                - 0.0000327*ttt4 - 0.0000002*ttt5;  % "
            theta=             2004.1917476*ttt  - 0.4269353*ttt2 - 0.0418251*ttt3 ...
                                - 0.0000601*ttt4 - 0.0000001*ttt5;  % "
            z    = 2.5976176 + 2306.0803226*ttt  + 1.0947790*ttt2 + 0.0182273*ttt3 ...
                                + 0.0000470*ttt4 - 0.0000003*ttt5;  % "
        end

        % convert units to rad
        psia = psia  * convrt; % rad
        wa   = wa    * convrt;
        ea   = ea    * convrt;
        xa   = xa    * convrt;
        zeta = zeta  * convrt; 
        theta= theta * convrt;
        z    = z     * convrt;

        if strcmp(opt,'80')
            coszeta  = cos(zeta);
            sinzeta  = sin(zeta);
            costheta = cos(theta);
            sintheta = sin(theta);
            cosz     = cos(z);
            sinz     = sin(z);

            % ----------------- form matrix  mod to j2000 -----------------
            prec(1,1) =  coszeta * costheta * cosz - sinzeta * sinz;
            prec(1,2) =  coszeta * costheta * sinz + sinzeta * cosz;
            prec(1,3) =  coszeta * sintheta;
            prec(2,1) = -sinzeta * costheta * cosz - coszeta * sinz;
            prec(2,2) = -sinzeta * costheta * sinz + coszeta * cosz;
            prec(2,3) = -sinzeta * sintheta;
            prec(3,1) = -sintheta * cosz;
            prec(3,2) = -sintheta * sinz;
            prec(3,3) =  costheta;
        else
            prec = zeros(3);
        end
end

