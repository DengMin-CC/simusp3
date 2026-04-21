function writesp3(insp3, outsp3, sp3p)

global NsatGPS NsatGLO NsatGAL NsatCMP NsatLEO

% Read entire input file into memory (single pass, eliminates interleaved I/O)
fin = fopen(insp3, 'r');
if fin == -1
    errordlg('SP3 file can not be opened.','SP3 file error');
    error   ('SP3 file error');
end
all_lines = {};
while ~feof(fin)
    line = fgetl(fin);
    if ischar(line)
        all_lines{end+1} = line;
    end
end
fclose(fin);

% Parse header and build output in memory
out = {};
ts_str = '';
sp3int = 30;
NoSat = 0;
N = length(all_lines);
idx = 1;

% Phase 1: copy header lines
while idx <= N
    tline = all_lines{idx};
    if isempty(tline), idx = idx + 1; continue; end

    if tline(1) == '*'
        break;
    end

    out{end+1} = tline;

    if strcmp(tline(1),'#') && ~strcmp(tline(1:2),'##')
        date = sscanf(tline(4:31),'%f',[1,6]);
        if ~isempty(date) && length(date) == 6
            ts_str = datestr(date,'yyyy-mm-dd HH:MM:SS');
        end
    elseif strcmp(tline(1:2),'##')
        sp3int = sscanf(tline(25:38),'%f');
    elseif strcmp(tline(1),'+') && ~strcmp(tline(1:2),'++')
        temp = sscanf(tline(2:6),'%d');
        if ~isnan(temp), NoSat = temp; end
    end

    idx = idx + 1;
end

% Phase 2: process epoch data
while idx <= N
    tline = all_lines{idx};
    if isempty(tline), idx = idx + 1; continue; end

    if tline(1) == '*'
        ep = sscanf(tline(2:end),'%f',[1,6]);
        tc_str = datestr(ep,'yyyy-mm-dd HH:MM:SS');
        epno = round((etime(datevec(tc_str),datevec(ts_str))/sp3int) + 1);
        out{end+1} = tline;
        idx = idx + 1;

        for k = 1:NoSat
            if idx > N, break; end
            sl = all_lines{idx};
            idx = idx + 1;
            if isempty(sl), continue; end
            if sl(2) == 'G'
                sno = sscanf(sl(3:4),'%d');
                out{end+1} = sprintf('PG%02d%14.6f%14.6f%14.6f%14.6f',sno,...
                    sp3p.recefe(epno,1,sno)/1000,sp3p.recefe(epno,2,sno)/1000,...
                    sp3p.recefe(epno,3,sno)/1000,sp3p.recefe(epno,4,sno)*1e6);
            elseif sl(2) == 'R'
                sno = NsatGPS + sscanf(sl(3:4),'%d');
                out{end+1} = sprintf('PR%02d%14.6f%14.6f%14.6f%14.6f',sno-NsatGPS,...
                    sp3p.recefe(epno,1,sno)/1000,sp3p.recefe(epno,2,sno)/1000,...
                    sp3p.recefe(epno,3,sno)/1000,sp3p.recefe(epno,4,sno)*1e6);
            elseif sl(2) == 'E'
                sno = NsatGPS + NsatGLO + sscanf(sl(3:4),'%d');
                out{end+1} = sprintf('PE%02d%14.6f%14.6f%14.6f%14.6f',sno-NsatGPS-NsatGLO,...
                    sp3p.recefe(epno,1,sno)/1000,sp3p.recefe(epno,2,sno)/1000,...
                    sp3p.recefe(epno,3,sno)/1000,sp3p.recefe(epno,4,sno)*1e6);
            elseif sl(2) == 'C'
                sno = NsatGPS + NsatGLO + NsatGAL + sscanf(sl(3:4),'%d');
                out{end+1} = sprintf('PC%02d%14.6f%14.6f%14.6f%14.6f',sno-NsatGPS-NsatGLO-NsatGAL,...
                    sp3p.recefe(epno,1,sno)/1000,sp3p.recefe(epno,2,sno)/1000,...
                    sp3p.recefe(epno,3,sno)/1000,sp3p.recefe(epno,4,sno)*1e6);
            elseif sl(2) == 'J' || sl(2) == 'I' || sl(2) == 'S' || sl(2) == 'L'
                continue
            else
                sno = NsatGPS + NsatGLO + NsatGAL + NsatCMP + sscanf(sl(2:4),'%d') - 200;
                lno = sno - NsatGPS - NsatGLO - NsatGAL - NsatCMP + 200;
                out{end+1} = sprintf('P%03d%14.6f%14.6f%14.6f%14.6f',lno,...
                    sp3p.recefe(epno,1,sno)/1000,sp3p.recefe(epno,2,sno)/1000,...
                    sp3p.recefe(epno,3,sno)/1000,sp3p.recefe(epno,4,sno)*1e6);
            end
        end
        continue;
    end

    if length(tline) >= 3 && strcmp(tline(1:3),'EOF')
        out{end+1} = tline;
    end
    idx = idx + 1;
end

% Write all output at once (single I/O call)
fout = fopen(outsp3, 'w');
fwrite(fout, strjoin(out, sprintf('\r\n')));
fwrite(fout, sprintf('\r\n'));
fclose(fout);

end
