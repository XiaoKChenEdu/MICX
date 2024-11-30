function process(processdata)

% Remove the time column
data = processdata(:,2:8);

% Remove DC values
for i = 1:7
    data(:,i) = data(:,i) -  mean(data(:,1));
end

% Reconstruct signal with real and img part
data_rec = hilbert(data);

% Find phase difference of data
for i = 1:7
    corrCalib = xcorr(data_rec(:, 1), data_rec(:, i));  
    phase(i) = angle(corrCalib(length(data(:,1))));
end

% Original phase of data
w_org = exp(1j*phase);

load('./data/cal.mat');

% Phase after calibration
w_center = w_org.*conj(exp(1j*cal));

d_deg = linspace(-90,90,1801);
d_rad = d_deg*pi/180;
mag = zeros(1,length(d_rad));

c = 3*10^8;
fc=2.4e9;
lamda = c/fc;
d = lamda/2;
beta = 2*pi/lamda;
N_ant = 7;

% Scan
for i = 1:length(d_rad)
    mag(i) = abs(conj(w_center)*conj(exp(1j*beta*(0:N_ant-1)*d*sin(d_rad(i)))).');
end

mag_db = 20*log10(mag);

[~,x_deg] = max(mag);
fprintf('The Angle of arrival : %f\n', (x_deg/10)-90)

plot(d_deg,mag_db)
axis([-90 90 -50 30])
xlabel('\theta (Degree)')
ylabel('Magitude (db)')
grid on
end
