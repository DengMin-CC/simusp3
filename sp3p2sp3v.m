function [sp3v] = sp3p2sp3v(sp3p, NoEp, MaxSat)
omegae = 7.2921151467*1e-5;
dt = 0.001;
nlag = 10;
if NoEp < nlag
    warning('sp3p2sp3v: NoEp=%d < nlag=%d, cannot compute velocities.', NoEp, nlag);
    return;
end
sp3v.vecef  = NaN(NoEp,3,MaxSat);
sp3v.t = sp3p.t;
% Get sampling interval (seconds)
sp3int = (sp3p.t(2) - sp3p.t(1)) * 86400;
% ===== Pre-compute Lagrange weights for standard window =====
% Standard window: epochs [i-4, ..., i+5], interpolation at t(i)+dt
% Relative positions of window points w.r.t. interpolation point:
%   x_nodes(n) = (n-5)*sp3int - dt,  evaluate at x0 = 0
x_nodes = ((1:nlag)' - 5) * sp3int - dt;  % 10x1
w_std = ones(nlag, 1);
for n = 1:nlag
    for m = 1:nlag
        if m ~= n
            w_std(n) = w_std(n) * (0 - x_nodes(m)) / (x_nodes(n) - x_nodes(m));
        end
    end
end
% Pre-compute Earth rotation angles for standard window
% dif(n) = t(i)+dt - t(i-4+n-1) = (5-n)*sp3int + dt
dif_std = (4:-1:-5)' * sp3int + dt;  % 10x1
sinl_std = sin(omegae * dif_std);  % 10x1
cosl_std = cos(omegae * dif_std);  % 10x1
% Window index matrix: mid_idx(k,n) = k+n-1 for k=1:nmid, n=1:nlag
nmid = NoEp - nlag + 1;  % number of middle epochs
mid_idx = (1:nmid)' + (0:nlag-1);  % (NoEp-9) x 10
% ===== Process each satellite =====
for j = 1:MaxSat
    ya = sp3p.recef(:, 1, j);  % NoEp x 1 (mm)
    yb = sp3p.recef(:, 2, j);
    yc = sp3p.recef(:, 3, j);
    % --- Middle epochs: vectorized (i=5 to NoEp-5) ---
    ya_win = ya(mid_idx);  % (NoEp-9) x 10
    yb_win = yb(mid_idx);
    yc_win = yc(mid_idx);
    % Earth rotation correction: rotate x-y by omega*dif
    pa_win = ya_win .* cosl_std' + yb_win .* sinl_std';   % (NoEp-9) x 10
    pb_win = -ya_win .* sinl_std' + yb_win .* cosl_std';
    % Lagrange interpolation via matrix multiply (10x1 weights)
    ch_ya_mid = pa_win * w_std;  % (NoEp-9) x 1
    ch_yb_mid = pb_win * w_std;
    ch_yc_mid = yc_win * w_std;
    % Velocity = (interpolated - original) / dt
    sp3v.vecef(5:NoEp-5, 1, j) = (ch_ya_mid - ya(5:NoEp-5)) / dt;
    sp3v.vecef(5:NoEp-5, 2, j) = (ch_yb_mid - yb(5:NoEp-5)) / dt;
    sp3v.vecef(5:NoEp-5, 3, j) = (ch_yc_mid - yc(5:NoEp-5)) / dt;
    % --- Boundary epochs: per-epoch lag() (i=1:4 and i=NoEp-4:NoEp) ---
    for i = [1:4, NoEp-4:NoEp]
        if i < 5
            k = 1;
        else
            k = NoEp - 9;
        end
        l_x  = sp3p.t(k:k+9)*86400;
        l_ya = sp3p.recef(k:k+9,1,j);
        l_yb = sp3p.recef(k:k+9,2,j);
        l_yc = sp3p.recef(k:k+9,3,j);
        t    = sp3p.t(i)*86400+dt;
        pa   = NaN(1,10);
        pb   = NaN(1,10);
        for n = 1:10
            dif  = t-l_x(n);
            sinl = sin(omegae*dif);
            cosl = cos(omegae*dif);
            pa(n) = cosl*l_ya(n)+sinl*l_yb(n);
            pb(n) = -sinl*l_ya(n)+cosl*l_yb(n);
        end
        ch_ya = lag(l_x,pa,t);
        ch_yb = lag(l_x,pb,t);
        ch_yc = lag(l_x,l_yc,t);
        sp3v.vecef(i,1,j) = (ch_ya-ya(i))/dt;
        sp3v.vecef(i,2,j) = (ch_yb-yb(i))/dt;
        sp3v.vecef(i,3,j) = (ch_yc-yc(i))/dt;
    end
end
