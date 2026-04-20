function [sval] = simugn(NoEp,sat,sp3int,amp,T,phi,disp,sig)

trend = zeros(NoEp,1);
for i = 1:NoEp
    t = (i-1)*sp3int;
    omega = 2*pi/T;
    trend(i) = amp*cos(omega*t + phi) + disp;
end

s = RandStream('mcg16807','Seed',sat);
RandStream.setDefaultStream(s);
noise = sig*randn(NoEp,1);

sval = trend + noise;

end