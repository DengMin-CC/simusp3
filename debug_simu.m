% debug_simu.m - Focused debug: trace orbit error for G01
clear; clc;

global NsatGPS NsatGLO NsatGAL NsatCMP NsatLEO
NsatGPS=32; NsatGLO=27; NsatGAL=52; NsatCMP=61; NsatLEO=150;
MaxSat = NsatGPS + NsatGLO + NsatGAL + NsatCMP + NsatLEO;

insp3 = 'whu23710_new.sp3';
outsp3 = 'Cwhu23710_new.sp3';
[sp3_in, NoEp, ~, sp3int] = readsp3(insp3);
[sp3_out, ~, ~, ~] = readsp3(outsp3);

fprintf('NoEp=%d, sp3int=%.1f\n', NoEp, sp3int);

% Check raw file values for G01
j = 1;
fprintf('\n--- G01 (j=%d) raw comparison ---\n', j);
fprintf('  Input  epoch 1: X=%.6f Y=%.6f Z=%.6f clk=%.12f\n', ...
    sp3_in.recef(1,1,j), sp3_in.recef(1,2,j), sp3_in.recef(1,3,j), sp3_in.recef(1,4,j));
fprintf('  Output epoch 1: X=%.6f Y=%.6f Z=%.6f clk=%.12f\n', ...
    sp3_out.recef(1,1,j), sp3_out.recef(1,2,j), sp3_out.recef(1,3,j), sp3_out.recef(1,4,j));
fprintf('  Diff   epoch 1: dX=%.6f dY=%.6f dZ=%.6f dClk=%.12f\n', ...
    sp3_out.recef(1,1,j)-sp3_in.recef(1,1,j), ...
    sp3_out.recef(1,2,j)-sp3_in.recef(1,2,j), ...
    sp3_out.recef(1,3,j)-sp3_in.recef(1,3,j), ...
    sp3_out.recef(1,4,j)-sp3_in.recef(1,4,j));

% Also check raw file text
fprintf('\n--- Raw G01 lines from input/output files ---\n');
fid = fopen(insp3, 'r');
count = 0;
while ~feof(fid)
    line = fgetl(fid);
    if ischar(line) && length(line) >= 4 && strcmp(line(1:2),'PG') && strcmp(line(3:4),'01')
        fprintf('  Input:  [%s]\n', line);
        count = count + 1;
        if count >= 2, break; end
    end
end
fclose(fid);

fid = fopen(outsp3, 'r');
count = 0;
while ~feof(fid)
    line = fgetl(fid);
    if ischar(line) && length(line) >= 4 && strcmp(line(1:2),'PG') && strcmp(line(3:4),'01')
        fprintf('  Output: [%s]\n', line);
        count = count + 1;
        if count >= 2, break; end
    end
end
fclose(fid);

% Now run the full error sim for G01 and check intermediate values
fprintf('\n--- Running error sim for G01 ---\n');
r_amp = 0.030; r_std = 0.010;
t_amp = 0.050; t_std = 0.010;
n_amp = 0.040; n_std = 0.010;
c_amp = 0.040; c_std = 0.006;

s = RandStream('mcg16807','Seed',10001); RandStream.setGlobalStream(s);
r_amp_v = r_amp + 0.003*randn;
s = RandStream('mcg16807','Seed',20001); RandStream.setGlobalStream(s);
r_phi = 2*pi*rand;
s = RandStream('mcg16807','Seed',30001); RandStream.setGlobalStream(s);
r_disp = 0.005*randn;

s = RandStream('mcg16807','Seed',10002); RandStream.setGlobalStream(s);
t_amp_v = t_amp + 0.003*randn;
s = RandStream('mcg16807','Seed',20002); RandStream.setGlobalStream(s);
t_phi = 2*pi*rand;
s = RandStream('mcg16807','Seed',30002); RandStream.setGlobalStream(s);
t_disp = 0.020*randn;

s = RandStream('mcg16807','Seed',10003); RandStream.setGlobalStream(s);
n_amp_v = n_amp + 0.003*randn;
s = RandStream('mcg16807','Seed',20003); RandStream.setGlobalStream(s);
n_phi = 2*pi*rand;
s = RandStream('mcg16807','Seed',30003); RandStream.setGlobalStream(s);
n_disp = 0.010*randn;

[w_r, w_ac2, T, sid] = selconf(1);
[r_e] = simuar2(NoEp, 1+MaxSat, sp3int, r_amp_v, T, r_phi, r_disp, r_std);
[t_e] = simuar2(NoEp, 1+2*MaxSat, sp3int, t_amp_v, T, t_phi, t_disp, t_std);
[n_e] = simuar2(NoEp, 1+3*MaxSat, sp3int, n_amp_v, T, n_phi, n_disp, n_std);
[c_e] = simuar2(NoEp, 1+4*MaxSat, sp3int, c_amp, T/2, r_phi, 0, c_std);

fprintf('  r_e: [%.6f, %.6f, ..., %.6f] RMS=%.6f\n', r_e(1), r_e(2), r_e(end), sqrt(mean(r_e.^2)));
fprintf('  t_e: [%.6f, %.6f, ..., %.6f] RMS=%.6f\n', t_e(1), t_e(2), t_e(end), sqrt(mean(t_e.^2)));
fprintf('  n_e: [%.6f, %.6f, ..., %.6f] RMS=%.6f\n', n_e(1), n_e(2), n_e(end), sqrt(mean(n_e.^2)));
fprintf('  c_e: [%.6f, %.6f, ..., %.6f] RMS=%.6f\n', c_e(1), c_e(2), c_e(end), sqrt(mean(c_e.^2)));

fprintf('\nDebug done.\n');
