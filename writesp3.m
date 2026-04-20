function writesp3(insp3,outsp3,sp3p)

global NsatGPS NsatGLO NsatGAL NsatCMP

[fin ,errmsgin ] = fopen(insp3,'r');
[fout,errmsgout] = fopen(outsp3,'w+');

if fin == -1 || fout == -1
    errordlg('SP3 file can not be opened.','SP3 file error');
    error   ('SP3 file error');
end

while ~feof(fin)
    tline = fgetl(fin);
    if strcmp(tline(1),'#') && ~strcmp(tline(1:2),'##')
        date = sscanf(tline(4:31),'%f',[1,6]);
        ts_str = datestr(date,'yyyy-mm-dd HH:MM:SS');
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
    if strcmp(tline(1),'#') || strcmp(tline(1),'+') ||strcmp(tline(1),'%') || strcmp(tline(1),'/')
        fprintf(fout,'%s\r\n',tline);
        continue
    end
    % new epoch
    if strcmp(tline(1),'*')
        ep = sscanf(tline(2:end),'%f',[1,6]);
        tc_str=datestr(ep,'yyyy-mm-dd HH:MM:SS');
        epno = (etime(datevec(tc_str),datevec(ts_str))/sp3int) + 1;
        fprintf(fout,'%s\r\n',tline);
        for k = 1:NoSat
            tline = fgetl(fin);
            if     strcmp(tline(2),'G')
                sno  = sscanf(tline(3:4),'%d');
                snostr = sprintf('%02d',sno);
                fprintf(fout,'%s%s%14.6f%14.6f%14.6f%14.6f\r\n','PG',snostr,...
                    sp3p.recefe(epno,1,sno)/1000.0,sp3p.recefe(epno,2,sno)/1000.0,sp3p.recefe(epno,3,sno)/1000.0,sp3p.recefe(epno,4,sno)*1e6);
            elseif strcmp(tline(2),'R')
                sno  = NsatGPS + sscanf(tline(3:4),'%d');
                snostr = sprintf('%02d',sno - NsatGPS);
                fprintf(fout,'%s%s%14.6f%14.6f%14.6f%14.6f\r\n','PR',snostr,...
                    sp3p.recefe(epno,1,sno)/1000.0,sp3p.recefe(epno,2,sno)/1000.0,sp3p.recefe(epno,3,sno)/1000.0,sp3p.recefe(epno,4,sno)*1e6);
            elseif strcmp(tline(2),'E')
                sno  = NsatGPS + NsatGLO + sscanf(tline(3:4),'%d');
                snostr = sprintf('%02d',sno - NsatGPS - NsatGLO);
                fprintf(fout,'%s%s%14.6f%14.6f%14.6f%14.6f\r\n','PE',snostr,...
                    sp3p.recefe(epno,1,sno)/1000.0,sp3p.recefe(epno,2,sno)/1000.0,sp3p.recefe(epno,3,sno)/1000.0,sp3p.recefe(epno,4,sno)*1e6);
            elseif strcmp(tline(2),'C')
                sno  = NsatGPS + NsatGLO + NsatGAL + sscanf(tline(3:4),'%d');
                snostr = sprintf('%02d',sno - NsatGPS - NsatGLO - NsatGAL);
                fprintf(fout,'%s%s%14.6f%14.6f%14.6f%14.6f\r\n','PC',snostr,...
                    sp3p.recefe(epno,1,sno)/1000.0,sp3p.recefe(epno,2,sno)/1000.0,sp3p.recefe(epno,3,sno)/1000.0,sp3p.recefe(epno,4,sno)*1e6);
            elseif strcmp(tline(2),'J') || strcmp(tline(2),'I') || strcmp(tline(2),'S') || strcmp(tline(2),'L')
                continue
            else
                sno  = NsatGPS + NsatGLO + NsatGAL + NsatCMP + sscanf(tline(2:4),'%d') - 200;
                fprintf(fout,'%s%s%02X%14.6f%14.6f%14.6f%14.6f\r\n','P','L',sno - NsatGPS - NsatGLO - NsatGAL - NsatCMP,...
                    sp3p.recefe(epno,1,sno)/1000.0,sp3p.recefe(epno,2,sno)/1000.0,sp3p.recefe(epno,3,sno)/1000.0,sp3p.recefe(epno,4,sno)*1e6);
            end
        end
    end
    if strcmp(tline(1:3),'EOF')
        fprintf(fout,'%s\r\n',tline);
        continue
    end
end
fclose('all');

end
