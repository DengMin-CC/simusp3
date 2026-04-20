function [sp3v] = sp3p2sp3v(sp3p,NoEp,MaxSat)

omegae = 7.2921151467*1e-5;

sp3v.vecef  = NaN(NoEp,3,MaxSat);
sp3v.t = NaN(NoEp,1);

dt = 0.001;
nlag = 10;   % number of Lagrange interpolation points

if NoEp < nlag
    warning('sp3p2sp3v: NoEp=%d < nlag=%d, cannot compute velocities.', NoEp, nlag);
    return;
end

for i = 1:NoEp
    for j = 1:MaxSat
        ya = sp3p.recef(i,1,j);
        yb = sp3p.recef(i,2,j);
        yc = sp3p.recef(i,3,j);
        if i < 5
            k = 1;
        elseif i > NoEp-5
            k = NoEp-9;
        else
            k = i-4;
        end
        l_x  = sp3p.t(k:k+9)*86400;
        l_ya = sp3p.recef((k:k+9),1,j);
        l_yb = sp3p.recef((k:k+9),2,j);
        l_yc = sp3p.recef((k:k+9),3,j);
        t    = sp3p.t(i)*86400+dt;
        
        pa   = NaN(1,10);
        pb   = NaN(1,10);
        pc   = NaN(1,10);
        % ���ǵ�����ת
        for n = 1:10
            dif  = t-l_x(n);
            sinl = sin(omegae*dif);
            cosl = cos(omegae*dif);
            pa(n) = cosl*l_ya(n)+sinl*l_yb(n);
            pb(n) = -sinl*l_ya(n)+cosl*l_yb(n);
            pc(n) = l_yc(n);
        end
        
        ch_ya = lag(l_x,pa,t);
        ch_yb = lag(l_x,pb,t);
        ch_yc = lag(l_x,pc,t);
        sp3v.vecef(i,1,j) = (ch_ya-ya)/dt;
        sp3v.vecef(i,2,j) = (ch_yb-yb)/dt;
        sp3v.vecef(i,3,j) = (ch_yc-yc)/dt;    
    end
    sp3v.t(i) = sp3p.t(i);
end

end
