clear
clc
delete('*.mat');
delete('*.asv');

global NsatGPS NsatGLO NsatGAL NsatCMP NsatLEO hleo
% 常量
mu      = 3.986004405e14;
omega_e = 7.29211514670698e-05;
Re      = 6378.137*1e3;
R2D     = 180/pi;
dt      = 1e-3;
clight  = 2.99792458*1e8;
% 卫星数
%2024 0306 只处理低轨卫星
NsatGPS = 32;
NsatGLO = 27;
NsatGAL = 52;
NsatCMP = 61;
NsatLEO = 150;
% 卫星高度
hleo    = 1100*1e3;
% 初始状态对应GPS时(gpst 2019.03.31 00:00:00)
leapsec = 18.0;
ut1_utc = 122353*1e-7;
tt_gps  = 32.184 + 19.0;
jdgps   = 2460292.5;
jdutc   = jdgps - leapsec/86400.0;
jdut1   = jdutc + ut1_utc/86400.0;
jdtt    = jdgps + tt_gps/86400.0;
ttt     = (jdtt - 2451545.0)/36525.0;
% ecef2eci其它参数
lod     = -4047*1e-7;
xp      = 187693*1e-6;
yp      = 206272*1e-6;
eqeterms= 2;
ddpsi   = 0;
ddeps   = 0;
aecef   = [0; 0; 0];
% SISRE, R, T, N误差设置
%2024 0306 为了满足实测数据FPPP仿真作了修改，使得轨道误差为5cm
r_amp_avg      = 0.030;
% r_amp_avg      = 0.070;
r_amp_std      = 0.003;
r_std          = 0.010;
r_disp_avg     = 0;
r_disp_std     = 0.005;

t_amp_avg      = 0.050;
% t_amp_avg      = 0.070;
t_amp_std      = 0.003;
t_std          = 0.010;
t_disp_avg     = 0;
t_disp_std     = 0.020;

n_amp_avg      = 0.040;
% n_amp_avg      = 0.070;
n_amp_std      = 0.003;
n_std          = 0.010;
n_disp_avg     = 0;
n_disp_std     = 0.010;

c_amp_avg      = 0.040;
% c_amp_avg      = 0.070;
c_amp_std      = 0.003;
c_std          = 0.006;
c_disp_avg     = 0;
c_disp_std     = 0.015;

insp3 = 'GLwhu22924.sp3';
outsp3 = 'CGLwhu22924.sp3';
[sp3p,NoEp,MaxSat,sp3int] = readsp3(insp3);
[sp3v] = sp3p2sp3v(sp3p,NoEp,MaxSat);

s = RandStream('mcg16807','Seed',10001);
RandStream.setGlobalStream(s);
r_amp = r_amp_avg + r_amp_std*randn(MaxSat,1);
s = RandStream('mcg16807','Seed',20001);
RandStream.setGlobalStream(s);
r_phi = 2*pi*rand(MaxSat,1);
s = RandStream('mcg16807','Seed',30001);
RandStream.setGlobalStream(s);
r_disp = r_disp_avg + r_disp_std*randn(MaxSat,1);

s = RandStream('mcg16807','Seed',10002);
RandStream.setGlobalStream(s);
t_amp = t_amp_avg + t_amp_std*randn(MaxSat,1);
s = RandStream('mcg16807','Seed',20002);
RandStream.setGlobalStream(s);
t_phi = 2*pi*rand(MaxSat,1);
s = RandStream('mcg16807','Seed',30002);
RandStream.setGlobalStream(s);
t_disp = t_disp_avg + t_disp_std*randn(MaxSat,1);

s = RandStream('mcg16807','Seed',10003);
RandStream.setGlobalStream(s);
n_amp = n_amp_avg + n_amp_std*randn(MaxSat,1);
s = RandStream('mcg16807','Seed',20003);
RandStream.setGlobalStream(s);
n_phi = 2*pi*rand(MaxSat,1);
s = RandStream('mcg16807','Seed',30003);
RandStream.setGlobalStream(s);
n_disp = n_disp_avg + n_disp_std*randn(MaxSat,1);

s = RandStream('mcg16807','Seed',10004);
RandStream.setGlobalStream(s);
c_amp = c_amp_avg + c_amp_std*randn(MaxSat,1);
c_phi = r_phi;
s = RandStream('mcg16807','Seed',30004);
RandStream.setGlobalStream(s);
c_disp = c_disp_avg + c_disp_std*randn(MaxSat,1);

for j = 1:MaxSat
    if isnan(sum(sp3p.recef(1440,1:4,j)))
        continue
    end
    j
%     if j>=10
%         break;
%     end
    % 仿真每颗卫星的SISRE和RTN误差
    [w_r,w_ac2,T,sid] = selconf(j);
    
    [r_e] = simuar2(NoEp,j + MaxSat*1,sp3int,r_amp(j),T,r_phi(j),r_disp(j),r_std);
    [t_e] = simuar2(NoEp,j + MaxSat*2,sp3int,t_amp(j),T,t_phi(j),t_disp(j),t_std);
    [n_e] = simuar2(NoEp,j + MaxSat*3,sp3int,n_amp(j),T,n_phi(j),n_disp(j),n_std);
    if abs(c_disp(j) - r_disp(j)) > abs(c_disp(j))
        c_dispuse = 0 - c_disp(j);
    else
        c_dispuse = c_disp(j);
    end
    %2024 0306 DM 为了仿真误差将1/2轨道周期
%     T=T/2;
    [c_e] = simuar2(NoEp,j + MaxSat*4,sp3int,c_amp(j),T,c_phi(j),c_dispuse,c_std);
    
    %2024 0516 DM 若只添加低轨的卫星钟差误差，可以打开
    if j<173
        for n_rtnc=1:length(r_e)
            r_e(n_rtnc)=0;
            t_e(n_rtnc)=0;
            n_e(n_rtnc)=0;
            c_e(n_rtnc)=0;
        end
    end
    rms_r = sqrt(sum(r_e.^2)/NoEp);
    rms_t = sqrt(sum(t_e.^2)/NoEp);
    rms_n = sqrt(sum(n_e.^2)/NoEp);
    rms_c = sqrt(sum(c_e.^2)/NoEp);
    sisre = sqrt(sum((w_r*r_e - c_e).^2)/NoEp + w_ac2*(sum(t_e.^2)/NoEp + sum(n_e.^2)/NoEp));
    
    if ~exist('ephe.mat','file')
        R_E   =   r_e;
        T_E   =   t_e;
        N_E   =   n_e;
        C_E   =   c_e;
        RMS_R = rms_r;
        RMS_T = rms_t;
        RMS_N = rms_n;
        RMS_C = rms_c;
        SISRE = sisre;
        W_R   =   w_r;
        W_AC2 = w_ac2;
        SID   =   sid;
    else
        load ephe.mat R_E T_E N_E C_E RMS_R RMS_T RMS_N RMS_C SISRE W_R W_AC2 SID;
        R_E   = [  R_E   r_e];
        T_E   = [  T_E   t_e];
        N_E   = [  N_E   n_e];
        C_E   = [  C_E   c_e];
        RMS_R = [RMS_R rms_r];
        RMS_T = [RMS_T rms_t];
        RMS_N = [RMS_N rms_n];
        RMS_C = [RMS_C rms_c];
        SISRE = [SISRE sisre];
        W_R   = [  W_R   w_r];
        W_AC2 = [W_AC2 w_ac2];
        SID   = [  SID;  sid];
    end
    save ephe.mat R_E T_E N_E C_E RMS_R RMS_T RMS_N RMS_C SISRE W_R W_AC2 SID;
    
    rtn = [r_e'; t_e'; n_e'];
    for i = 1:NoEp
        recef_t = sp3p.recef(i,1:3,j);
        recef = recef_t'/1000.0;
        vecef_t = sp3v.vecef(i,1:3,j);
        vecef = vecef_t'/1000.0;
        [reci,veci,aeci] = ecef2eci(recef,vecef,aecef,ttt,jdut1,lod,xp,yp,eqeterms,ddpsi,ddeps);
        reci_t = reci'*1000.0;
        sp3p.reci(i,1:3,j) = reci_t;
        veci_t = veci'*1000.0;
        sp3v.veci(i,1:3,j) = veci_t;
        g1 = reci_t/norm(reci_t,2);
        g3 = cross(reci_t,veci_t)/norm(cross(reci_t,veci_t),2);
        g2 = cross(g3,g1);
        G = [g1; g2; g3];
        xyz = G'*rtn(:,i);
        recie = (reci_t' + xyz)/1000.0;
        recie_t = recie'*1000.0;
        sp3p.recie(i,1:3,j) = recie_t;
        [recefe,vecefe,aecefe] = eci2ecef(recie,veci,aeci,ttt,jdut1,lod,xp,yp,eqeterms,ddpsi,ddeps);
        recefe_t = recefe'*1000.0;
        sp3p.recefe(i,1:3,j) = recefe_t;
        sp3p.recefe(i,4,j) = sp3p.recef(i,4,j) + c_e(i)/clight;
    end
end
% 输出包含误差的sp3文件
%%
writesp3(insp3,outsp3,sp3p);
save SP3.mat sp3p sp3v;
