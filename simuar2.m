function [sval] = simuar2(NoEp,sat,sp3int,amp,T,phi,disp,sig)

trend = zeros(NoEp,1);
for i = 1:NoEp
    t = (i-1)*sp3int;
    omega = 2*pi/T;
    trend(i) = amp*cos(omega*t + phi) + disp;
end

phi_1 = 0.6;
phi_2 = 0.25;
sig_e = sqrt(sig^2*((1-phi_2)^2-phi_1^2)*(1+phi_2)/(1-phi_2));

s = RandStream('mcg16807','Seed',sat);
RandStream.setGlobalStream(s);
e = sig_e*randn(NoEp,1);

noise = zeros(NoEp,1);
noise(1) = e(1);
noise(2) = e(2);
for i = 3:NoEp
    noise(i) = phi_1*noise(i-1) + phi_2*noise(i-2) + e(i);
end

sval = trend + noise;

end