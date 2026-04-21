% verify_simu.m - Verify error simulation results
% Compare input vs output SP3 to check error magnitudes

clear; clc;

global NsatGPS NsatGLO NsatGAL NsatCMP NsatLEO
NsatGPS = 32; NsatGLO = 27; NsatGAL = 52; NsatCMP = 61; NsatLEO = 150;
MaxSat = NsatGPS + NsatGLO + NsatGAL + NsatCMP + NsatLEO;

insp3  = 'whu23710_new.sp3';
outsp3 = 'Cwhu23710_new.sp3';

fprintf('===== Verifying %s vs %s =====\n\n', insp3, outsp3);

% Read both files (readsp3 puts positions into .recef, NOT .recefe)
[sp3_in, NoEp, ~, sp3int] = readsp3(insp3);
[sp3_out, ~, ~, ~]       = readsp3(outsp3);

fprintf('Epochs: %d, Interval: %.0fs\n\n', NoEp, sp3int);

clight = 2.99792458e8;

% Check which satellites exist in the input
n_active = 0;
for j = 1:MaxSat
    if ~isnan(sum(sp3_in.recef(1440,1:4,j)))
        n_active = n_active + 1;
    end
end
fprintf('Active satellites in input: %d\n\n', n_active);

% Results per satellite
fprintf('%-6s %-4s %10s %10s %10s %10s\n', 'Sys', 'PRN', 'dX_rms(m)', 'dY_rms(m)', 'dZ_rms(m)', 'dClk_rms(m)');

sys_count = [NsatGPS NsatGLO NsatGAL NsatCMP NsatLEO];
sys_names = {'GPS','GLO','GAL','BDS','LEO'};

for j = 1:MaxSat
    if isnan(sum(sp3_in.recef(1440,1:4,j)))
        continue;
    end

    % Position diff: output - input (both in meters from readsp3)
    dx = sp3_out.recef(:,1,j) - sp3_in.recef(:,1,j);
    dy = sp3_out.recef(:,2,j) - sp3_in.recef(:,2,j);
    dz = sp3_out.recef(:,3,j) - sp3_in.recef(:,3,j);

    % Clock diff: output - input (both in seconds from readsp3)
    dc_s = sp3_out.recef(:,4,j) - sp3_in.recef(:,4,j);
    dc_m = dc_s * clight;

    valid = ~isnan(dx);
    if sum(valid) == 0, continue; end

    dx_m = sqrt(mean(dx(valid).^2));
    dy_m = sqrt(mean(dy(valid).^2));
    dz_m = sqrt(mean(dz(valid).^2));
    dc_m_rms = sqrt(mean(dc_m(valid).^2));

    % Determine system
    if j <= NsatGPS
        sno = j; sname = 'GPS';
    elseif j <= NsatGPS+NsatGLO
        sno = j-NsatGPS; sname = 'GLO';
    elseif j <= NsatGPS+NsatGLO+NsatGAL
        sno = j-NsatGPS-NsatGLO; sname = 'GAL';
    elseif j <= NsatGPS+NsatGLO+NsatGAL+NsatCMP
        sno = j-NsatGPS-NsatGLO-NsatGAL; sname = 'BDS';
    else
        sno = j-NsatGPS-NsatGLO-NsatGAL-NsatCMP; sname = 'LEO';
    end

    fprintf('%-6s %4d %10.4f %10.4f %10.4f %10.4f\n', sname, sno, dx_m, dy_m, dz_m, dc_m_rms);
end

% Summary statistics by system
fprintf('\n===== Summary by system (RMS, meters) =====\n');
fprintf('%-6s %6s %10s %10s %10s %10s\n', 'Sys', 'Count', 'dX', 'dY', 'dZ', 'dClk');

for s = 1:5
    if s == 1, j_start = 1;
    else, j_start = sum(sys_count(1:s-1))+1;
    end
    j_end = sum(sys_count(1:s));

    all_dx = []; all_dy = []; all_dz = []; all_dc = [];
    n_valid = 0;
    for j = j_start:j_end
        if isnan(sum(sp3_in.recef(1440,1:4,j))), continue; end
        dx = sp3_out.recef(:,1,j) - sp3_in.recef(:,1,j);
        dy = sp3_out.recef(:,2,j) - sp3_in.recef(:,2,j);
        dz = sp3_out.recef(:,3,j) - sp3_in.recef(:,3,j);
        dc_s = sp3_out.recef(:,4,j) - sp3_in.recef(:,4,j);
        dc_m = dc_s * clight;
        valid = ~isnan(dx);
        if sum(valid) == 0, continue; end
        all_dx = [all_dx; dx(valid)];
        all_dy = [all_dy; dy(valid)];
        all_dz = [all_dz; dz(valid)];
        all_dc = [all_dc; dc_m(valid)];
        n_valid = n_valid + 1;
    end

    if isempty(all_dx), continue; end
    fprintf('%-6s %6d %10.4f %10.4f %10.4f %10.4f\n', sys_names{s}, n_valid, ...
        sqrt(mean(all_dx.^2)), sqrt(mean(all_dy.^2)), sqrt(mean(all_dz.^2)), sqrt(mean(all_dc.^2)));
end

% Spot checks
fprintf('\n===== Spot checks (first 5 epochs, satellite G01) =====\n');
j = 1;
if ~isnan(sum(sp3_in.recef(1440,1:4,j)))
    dx = sp3_out.recef(1:5,1,j) - sp3_in.recef(1:5,1,j);
    dy = sp3_out.recef(1:5,2,j) - sp3_in.recef(1:5,2,j);
    dz = sp3_out.recef(1:5,3,j) - sp3_in.recef(1:5,3,j);
    dc = (sp3_out.recef(1:5,4,j) - sp3_in.recef(1:5,4,j)) * clight;
    fprintf('G01 dX(m): ['); fprintf('%.4f ', dx); fprintf(']\n');
    fprintf('G01 dY(m): ['); fprintf('%.4f ', dy); fprintf(']\n');
    fprintf('G01 dZ(m): ['); fprintf('%.4f ', dz); fprintf(']\n');
    fprintf('G01 dClk(m): ['); fprintf('%.4f ', dc); fprintf(']\n');
end

fprintf('\n===== Spot checks (first 5 epochs, L201) =====\n');
j = NsatGPS+NsatGLO+NsatGAL+NsatCMP+1;
if j <= MaxSat && ~isnan(sum(sp3_in.recef(1440,1:4,j)))
    dx = sp3_out.recef(1:5,1,j) - sp3_in.recef(1:5,1,j);
    dy = sp3_out.recef(1:5,2,j) - sp3_in.recef(1:5,2,j);
    dz = sp3_out.recef(1:5,3,j) - sp3_in.recef(1:5,3,j);
    dc = (sp3_out.recef(1:5,4,j) - sp3_in.recef(1:5,4,j)) * clight;
    fprintf('L201 dX(m): ['); fprintf('%.4f ', dx); fprintf(']\n');
    fprintf('L201 dY(m): ['); fprintf('%.4f ', dy); fprintf(']\n');
    fprintf('L201 dZ(m): ['); fprintf('%.4f ', dz); fprintf(']\n');
    fprintf('L201 dClk(m): ['); fprintf('%.4f ', dc); fprintf(']\n');
else
    fprintf('L201 not active in file.\n');
end

fprintf('\n===== Verification complete =====\n');
