% batch_simusp3.m - Batch process multiple SP3 files with orbit/clock error simulation
% Behavior: V1 - all satellites (GNSS + LEO) get errors, clock period T/2
% Based on SimuSp3_16.m configuration
% Input:  whu{week}{day}_new.sp3  (from upstream csp3 project)
% Output: Cwhu{week}{day}_new.sp3
%
% Optimization: rotation matrix is precomputed once (EOP parameters are fixed),
% inner epoch loop is fully vectorized (eliminated ~752k ecef2eci/eci2ecef calls per file)

clear; clc;
delete('*.mat');
delete('*.asv');

global NsatGPS NsatGLO NsatGAL NsatCMP NsatLEO hleo
% Constants
mu      = 3.986004405e14;
omega_e = 7.29211514670698e-05;
Re      = 6378.137*1e3;
R2D     = 180/pi;
dt      = 1e-3;
clight  = 2.99792458*1e8;
% Satellite counts
NsatGPS = 32;
NsatGLO = 27;
NsatGAL = 52;
NsatCMP = 61;
NsatLEO = 150;
hleo    = 1100*1e3;
% Time parameters
leapsec = 18.0;
ut1_utc = 122353*1e-7;
tt_gps  = 32.184 + 19.0;
jdgps   = 2460292.5;
jdutc   = jdgps - leapsec/86400.0;
jdut1   = jdutc + ut1_utc/86400.0;
jdtt    = jdgps + tt_gps/86400.0;
ttt     = (jdtt - 2451545.0)/36525.0;
% ecef2eci parameters
lod     = -4047*1e-7;
xp      = 187693*1e-6;
yp      = 206272*1e-6;
eqeterms= 2;
ddpsi   = 0;
ddeps   = 0;
% Error parameters (2024-0306 adjusted, orbit error ~5cm)
r_amp_avg = 0.030; r_amp_std = 0.003; r_std = 0.010; r_disp_avg = 0; r_disp_std = 0.005;
t_amp_avg = 0.050; t_amp_std = 0.003; t_std = 0.010; t_disp_avg = 0; t_disp_std = 0.020;
n_amp_avg = 0.040; n_amp_std = 0.003; n_std = 0.010; n_disp_avg = 0; n_disp_std = 0.010;
c_amp_avg = 0.040; c_amp_std = 0.003; c_std = 0.006; c_disp_avg = 0; c_disp_std = 0.015;

MaxSat = NsatGPS + NsatGLO + NsatGAL + NsatCMP + NsatLEO;

% ===== Precompute rotation matrices ONCE (EOP is fixed for all epochs/files) =====
[prec_mat,~,~,~,~] = precess(ttt, '80');
[deltapsi,~,meaneps,omega_nut,nut_mat] = nutation(ttt,ddpsi,ddeps);
[st_mat,~] = sidereal(jdut1,deltapsi,meaneps,omega_nut,lod,eqeterms);
[pm_mat] = polarm(xp,yp,ttt,'80');

R  = prec_mat * nut_mat * st_mat * pm_mat;   % 3x3, ECEF -> ECI
R1 = prec_mat * nut_mat * st_mat;            % 3x3, PEF  -> ECI (without polar motion)
thetasa = 7.29211514670698e-05 * (1.0 - lod/86400.0);

fprintf('Rotation matrix R precomputed (same for all epochs and files).\n');

% Random seed initialization (once, same for all files)
s = RandStream('mcg16807','Seed',10001); RandStream.setGlobalStream(s);
r_amp = r_amp_avg + r_amp_std*randn(MaxSat,1);
s = RandStream('mcg16807','Seed',20001); RandStream.setGlobalStream(s);
r_phi = 2*pi*rand(MaxSat,1);
s = RandStream('mcg16807','Seed',30001); RandStream.setGlobalStream(s);
r_disp = r_disp_avg + r_disp_std*randn(MaxSat,1);

s = RandStream('mcg16807','Seed',10002); RandStream.setGlobalStream(s);
t_amp = t_amp_avg + t_amp_std*randn(MaxSat,1);
s = RandStream('mcg16807','Seed',20002); RandStream.setGlobalStream(s);
t_phi = 2*pi*rand(MaxSat,1);
s = RandStream('mcg16807','Seed',30002); RandStream.setGlobalStream(s);
t_disp = t_disp_avg + t_disp_std*randn(MaxSat,1);

s = RandStream('mcg16807','Seed',10003); RandStream.setGlobalStream(s);
n_amp = n_amp_avg + n_amp_std*randn(MaxSat,1);
s = RandStream('mcg16807','Seed',20003); RandStream.setGlobalStream(s);
n_phi = 2*pi*rand(MaxSat,1);
s = RandStream('mcg16807','Seed',30003); RandStream.setGlobalStream(s);
n_disp = n_disp_avg + n_disp_std*randn(MaxSat,1);

s = RandStream('mcg16807','Seed',10004); RandStream.setGlobalStream(s);
c_amp = c_amp_avg + c_amp_std*randn(MaxSat,1);
c_phi = r_phi;
s = RandStream('mcg16807','Seed',30004); RandStream.setGlobalStream(s);
c_disp = c_disp_avg + c_disp_std*randn(MaxSat,1);

% File list
file_list = {'whu23710_new.sp3', 'whu23711_new.sp3', 'whu23712_new.sp3', 'whu23713_new.sp3'};

for fidx = 1:length(file_list)
    insp3  = file_list{fidx};
    outsp3 = ['C' insp3];

    fprintf('\n===== Processing %s -> %s =====\n', insp3, outsp3);

    if ~exist(insp3, 'file')
        fprintf('WARNING: %s not found, skipping.\n', insp3);
        continue;
    end

    tic_read = tic;
    [sp3p, NoEp, MaxSat, sp3int] = readsp3(insp3);
    [sp3v] = sp3p2sp3v(sp3p, NoEp, MaxSat);
    fprintf('  Read + velocity: %.1f s\n', toc(tic_read));

    % Initialize ephe accumulation
    ephe_init = false;

    tic_sat = tic;
    for j = 1:MaxSat
        if isnan(sum(sp3p.recef(1440,1:4,j)))
            continue;
        end

        [w_r, w_ac2, T, sid] = selconf(j);

        [r_e] = simuar2(NoEp, j + MaxSat*1, sp3int, r_amp(j), T, r_phi(j), r_disp(j), r_std);
        [t_e] = simuar2(NoEp, j + MaxSat*2, sp3int, t_amp(j), T, t_phi(j), t_disp(j), t_std);
        [n_e] = simuar2(NoEp, j + MaxSat*3, sp3int, n_amp(j), T, n_phi(j), n_disp(j), n_std);
        if abs(c_disp(j) - r_disp(j)) > abs(c_disp(j))
            c_dispuse = 0 - c_disp(j);
        else
            c_dispuse = c_disp(j);
        end
        % V1: half orbital period for clock trend
        T_half = T/2;
        [c_e] = simuar2(NoEp, j + MaxSat*4, sp3int, c_amp(j), T_half, c_phi(j), c_dispuse, c_std);

        % V1: all satellites get errors (no j<173 filtering)

        % --- Statistics ---
        rms_r = sqrt(sum(r_e.^2)/NoEp);
        rms_t = sqrt(sum(t_e.^2)/NoEp);
        rms_n = sqrt(sum(n_e.^2)/NoEp);
        rms_c = sqrt(sum(c_e.^2)/NoEp);
        sisre = sqrt(sum((w_r*r_e - c_e).^2)/NoEp + w_ac2*(sum(t_e.^2)/NoEp + sum(n_e.^2)/NoEp));

        if ~ephe_init
            R_E = r_e; T_E = t_e; N_E = n_e; C_E = c_e;
            RMS_R = rms_r; RMS_T = rms_t; RMS_N = rms_n; RMS_C = rms_c;
            SISRE = sisre; W_R = w_r; W_AC2 = w_ac2; SID = sid;
            ephe_init = true;
        else
            R_E = [R_E r_e]; T_E = [T_E t_e]; N_E = [N_E n_e]; C_E = [C_E c_e];
            RMS_R = [RMS_R rms_r]; RMS_T = [RMS_T rms_t]; RMS_N = [RMS_N rms_n]; RMS_C = [RMS_C rms_c];
            SISRE = [SISRE sisre]; W_R = [W_R w_r]; W_AC2 = [W_AC2 w_ac2]; SID = [SID; sid];
        end

        % ===== Vectorized error application (no inner epoch loop) =====
        % Extract all epochs at once (NoEp x 3, in mm / mm/s)
        recef_mm = sp3p.recef(:,1:3,j);
        vecef_mm = sp3v.vecef(:,1:3,j);
        recef_km = recef_mm / 1000;
        vecef_km = vecef_mm / 1000;

        % ECEF -> ECI (matrix multiply, no per-epoch function call)
        reci_km = recef_km * R';               % NoEp x 3

        % Velocity with Earth rotation correction
        % cross([0,0,w], rpef) = [-w*y, w*x, 0]
        rpef_km = recef_km * pm_mat';
        cross_w = zeros(NoEp, 3);
        cross_w(:,1) = -thetasa * rpef_km(:,2);
        cross_w(:,2) =  thetasa * rpef_km(:,1);
        veci_km = (vecef_km * pm_mat' + cross_w) * R1';

        % Convert to mm for RTN
        reci_mm = reci_km * 1000;
        veci_mm = veci_km * 1000;

        % RTN basis vectors (vectorized over all epochs)
        r_norm = sqrt(sum(reci_mm.^2, 2));     % NoEp x 1
        g1 = reci_mm ./ r_norm;                % radial
        h  = cross(reci_mm, veci_mm);
        h_norm = sqrt(sum(h.^2, 2));
        g3 = h ./ h_norm;                      % normal
        g2 = cross(g3, g1);                    % tangential

        % Apply RTN errors: xyz = g1*r + g2*t + g3*n (broadcasting)
        % simuar2 returns column vector (NoEp x 1), use directly for broadcasting
        xyz = g1 .* r_e + g2 .* t_e + g3 .* n_e;

        % Add errors in ECI, then convert back to ECEF
        recie_km = (reci_mm + xyz) / 1000;
        recefe_km = recie_km * R;              % ECI -> ECEF (R' inverse)
        recefe_mm = recefe_km * 1000;

        % Store results
        sp3p.reci(:,1:3,j)  = reci_mm;
        sp3v.veci(:,1:3,j) = veci_mm;
        sp3p.recie(:,1:3,j) = reci_mm + xyz;
        sp3p.recefe(:,1:3,j) = recefe_mm;
        sp3p.recefe(:,4,j)   = sp3p.recef(:,4,j) + c_e(:) / clight;
    end
    fprintf('  Error simulation: %.1f s\n', toc(tic_sat));

    tic_write = tic;
    writesp3(insp3, outsp3, sp3p);
    fprintf('  Write SP3: %.1f s\n', toc(tic_write));

    % Save per-file results with tag
    tag = regexp(insp3, 'whu(\d+)_new\.sp3', 'tokens', 'once');
    if ~isempty(tag)
        save(sprintf('SP3_%s.mat', tag{1}), 'sp3p', 'sp3v');
        save(sprintf('ephe_%s.mat', tag{1}), 'R_E', 'T_E', 'N_E', 'C_E', 'RMS_R', 'RMS_T', 'RMS_N', 'RMS_C', 'SISRE', 'W_R', 'W_AC2', 'SID');
    end

    fprintf('===== %s done =====\n', outsp3);
end

fprintf('\n===== All files processed =====\n');
