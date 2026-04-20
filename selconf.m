function [w_r,w_ac2,T,sid] = selconf(sno)

global NsatGPS NsatGLO NsatGAL NsatCMP NsatLEO hleo

% 常量
Re            = 6378.137*1e3;
T_gso         = 86164;
h_gso         = 35786*1e3;

% SISRE加权因子
w_r_gps       = 0.98;
w_r_glo       = 0.98;
w_r_gal       = 0.98;
w_r_bds_g_i   = 0.99;
w_r_bds_m     = 0.98;
w_ac2_gps     = 1/49.0;
w_ac2_glo     = 1/45.0;
w_ac2_gal     = 1/61.0;
w_ac2_bds_g_i = 1/126.0;
w_ac2_bds_m   = 1/54.0;
hleo_t        = [400 600 800 1000 1200 1400]*1e3;
w_r_leo_t     = [0.419 0.487 0.540 0.582 0.617 0.647];
w_ac2_leo_t   = [0.642 0.617 0.595 0.575 0.556 0.539];
w_r_leo       = spline(hleo_t,w_r_leo_t,hleo);
w_ac2_leo     = spline(hleo_t,w_ac2_leo_t,hleo);

if     sno <= NsatGPS
    k = sno;
    sid = sprintf('%c%02d','G',k);
    w_r = w_r_gps;
    w_ac2 = w_ac2_gps;
    h = 20180*1e3;
elseif sno <= NsatGPS + NsatGLO
    k = sno - NsatGPS;
    sid = sprintf('%c%02d','R',k);
    w_r = w_r_glo;
    w_ac2 = w_ac2_glo;
    h = 19100*1e3;
elseif sno <= NsatGPS + NsatGLO + NsatGAL
    k = sno - NsatGPS - NsatGLO;
    sid = sprintf('%c%02d','E',k);
    w_r = w_r_gal;
    w_ac2 = w_ac2_gal;
    h = 23220*1e3;
elseif sno <= NsatGPS + NsatGLO + NsatGAL + NsatCMP
    k = sno - NsatGPS - NsatGLO - NsatGAL;
    sid = sprintf('%c%02d','C',k);
    if k <= 10 || k == 13 || k == 16 || k == 31 || k == 38 || k == 39 || k == 40 || k == 56 || k >= 59
        w_r = w_r_bds_g_i;
        w_ac2 = w_ac2_bds_g_i;
        h = 35786*1e3;
    else
        w_r = w_r_bds_m;
        w_ac2 = w_ac2_bds_m;
        h = 21528*1e3;
    end
elseif sno <= NsatGPS + NsatGLO + NsatGAL + NsatCMP +NsatLEO
    k = sno - NsatGPS - NsatGLO - NsatGAL - NsatCMP + 200;
    sid = sprintf('%03d',k);
    w_r = w_r_leo;
    w_ac2 = w_ac2_leo;
    h = hleo;
end

T = T_gso*((Re + h)/(Re + h_gso))^(3/2);

end

