function [sp3p,NoEp,MaxSat,sp3int] = readsp3(insp3)

global NsatGPS NsatGLO NsatGAL NsatCMP NsatLEO

[fid,errmsg] = fopen(insp3,'r');

if fid == -1
    errordlg('SP3 file can not be opened.','SP3 file error');
    error   ('SP3 file error: %s', errmsg);
end

MaxSat = NsatGPS + NsatGLO + NsatGAL + NsatCMP + NsatLEO;

while ~feof(fid)
    tline = fgetl(fid);
    if strcmp(tline(1),'#') && ~strcmp(tline(1:2),'##')
        
        date = sscanf(tline(4:31),'%f',[1,6]);
        ts_str = datestr(date,'yyyy-mm-dd HH:MM:SS');
        NoEp = sscanf(tline(32:39),'%f');
        NoEp = NoEp+1;
        sp3p.recef = NaN(NoEp,4,MaxSat);
        sp3p.reci = NaN(NoEp,3,MaxSat);
        sp3p.recefe = NaN(NoEp,4,MaxSat);
        sp3p.recie = NaN(NoEp,3,MaxSat);
        sp3p.t = NaN(NoEp,1);
    end
    if strcmp(tline(1:2),'##')
        sp3int = sscanf(tline(25:38),'%f');
    end
    if strcmp(tline(1),'+') && ~strcmp(tline(1:2),'++')
        temp = sscanf(tline(2:6),'%d');
        if ~isnan(temp)
            NoSat = temp;
        end
    end
    if strcmp(tline(1:2),'++') || strcmp(tline(1),'%') || strcmp(tline(1),'/')
        continue
    end
    % new epoch
    if strcmp(tline(1),'*')
        ep = sscanf(tline(2:end),'%f',[1,6]);
        tc_str=datestr(ep,'yyyy-mm-dd HH:MM:SS');
        epno = (etime(datevec(tc_str),datevec(ts_str))/sp3int) + 1;
        sp3p.t(epno) = datenum(datevec(tc_str));
        for k = 1:NoSat
            tline = fgetl(fid);
            if     strcmp(tline(2),'G')
                sno  = sscanf(tline(3:4),'%d');
            elseif strcmp(tline(2),'R')
                sno  = NsatGPS + sscanf(tline(3:4),'%d');
            elseif strcmp(tline(2),'E')
                sno  = NsatGPS + NsatGLO + sscanf(tline(3:4),'%d');
            elseif strcmp(tline(2),'C')
                sno  = NsatGPS + NsatGLO + NsatGAL + sscanf(tline(3:4),'%d');
            elseif strcmp(tline(2),'J') || strcmp(tline(2),'I') || strcmp(tline(2),'S') || strcmp(tline(2),'L')
                continue
            else
                sno  = NsatGPS + NsatGLO + NsatGAL + NsatCMP + sscanf(tline(2:4),'%d') - 200;
            end
            % writing part
            temp = sscanf(tline(5:end),'%f',[1,4]);
            sp3p.recef(epno,1:3,sno) = temp(1:3)*1000; %meter
            sp3p.recef(epno,  4,sno) = temp(4)*10^-6;  %second 
        end        
    end
end
fclose('all');

end
