figure;
clight = 2.99792458*1e8;
m2cm = 1e2;
m2ns = 1/clight*1e9;

subplot(5,1,1);
h1 = bar(RMS_R*m2cm,'r');
val = mean(RMS_R*m2cm);
str = sprintf('%s%4.1f%s','平均RMS: ',val,'cm');
l1 = legend(h1,str);
set(l1,'FontSize',8);
axis([1 267 0 10]);
set(gca,'XTick',[1 31 52 76 119 267]);
set(gca,'YTick',[0:2:10]);
ylabel('(a)径向/cm','FontSize',9);
set(gca,'xticklabel','');
grid on;

subplot(5,1,2);
h2 = bar(RMS_T*m2cm,'g');
val = mean(RMS_T*m2cm);
str = sprintf('%s%4.1f%s','平均RMS: ',val,'cm');
l2 = legend(h2,str);
set(l2,'FontSize',8);
axis([1 267 0 10]);
set(gca,'XTick',[1 31 52 76 119 267]);
set(gca,'YTick',[0:2:10]);
ylabel('(b)切向/cm','FontSize',9);
set(gca,'xticklabel','');
grid on;

subplot(5,1,3);
h3 = bar(RMS_N*m2cm,'b');
val = mean(RMS_N*m2cm);
str = sprintf('%s%4.1f%s','平均RMS: ',val,'cm');
l3 = legend(h3,str);
set(l3,'FontSize',8);
axis([1 267 0 10]);
set(gca,'XTick',[1 31 52 76 119 267]);
set(gca,'YTick',[0:2:10]);
ylabel('(c)法向/cm','FontSize',9);
set(gca,'xticklabel','');
grid on;

subplot(5,1,4);
h4 = bar(RMS_C*m2ns,'c');
val = mean(RMS_C*m2ns);
str = sprintf('%s%4.2f%s','平均RMS: ',val,'ns');
l4 = legend(h4,str);
set(l4,'FontSize',8);
axis([1 267 0 0.3]);
set(gca,'XTick',[1 31 52 76 119 267]);
set(gca,'YTick',[0:0.1:0.3]);
ylabel('(d)钟差/ns','FontSize',9);
set(gca,'xticklabel','');
grid on;

subplot(5,1,5);
h5 = bar(SISRE*m2cm,'m');
val_gnss = mean(SISRE(1:118)*m2cm);
val_leo = mean(SISRE(119:267)*m2cm);
str = sprintf('%s%4.1f%s%4.1f%s','均值: ',val_gnss,'cm(GNSS); ',val_leo,'cm(LEO)');
l5 = legend(h5,str);
set(l5,'FontSize',8);
axis([1 267 0 10]);
set(gca,'XTick',[1 31 52 76 119 267]);
set(gca,'YTick',[0:2:10]);
ylabel('(e)SISRE/cm','FontSize',9);
set(gca,'xticklabel',{'G01','R01','E01','C01','L001','L149'});
grid on;

figure(2);
x = 1:1:2900;
subplot(4,1,1);
h1 = plot(x,R_E(:,90)*m2cm,'b',x,R_E(:,119)*m2cm,'r');
l1 = legend(h1,'C19','L001');
set(l1,'FontSize',8,'Orientation','horizontal');
axis([11 2891 -10 10]);
set(gca,'XTick',[11:480:2891]);
set(gca,'YTick',[-10:5:10]);
ylabel('(a)径向/cm','FontSize',9);
set(gca,'xticklabel','');
grid on;

subplot(4,1,2);
plot(x,T_E(:,90)*m2cm,'b',x,T_E(:,119)*m2cm,'r');
axis([11 2891 -10 10]);
set(gca,'XTick',[11:480:2891]);
set(gca,'YTick',[-10:5:10]);
ylabel('(b)切向/cm','FontSize',9);
set(gca,'xticklabel','');
grid on;

subplot(4,1,3);
plot(x,N_E(:,90)*m2cm,'b',x,N_E(:,119)*m2cm,'r');
axis([11 2891 -10 10]);
set(gca,'XTick',[11:480:2891]);
set(gca,'YTick',[-10:5:10]);
ylabel('(c)法向/cm','FontSize',9);
set(gca,'xticklabel','');
grid on;

subplot(4,1,4);
plot(x,C_E(:,90)*m2ns,'b',x,C_E(:,119)*m2ns,'r');
axis([11 2891 -0.3 0.3]);
set(gca,'XTick',[11:480:2891]);
set(gca,'YTick',[-0.3:0.15:0.3]);
ylabel('(d)钟差/ns','FontSize',9);
set(gca,'xticklabel',{'0h','4h','8h','12h','16h','20h','24h'});
grid on;








