data = load('./data/calib.txt');

% Remove the time column
data = data(:,2:8);
 
xData = length(data(:, 1));

% Remove DC values
for i = 1:7
    data(:,i) = data(:,i) - mean(data(:,1));
end

% Reconstruct signal with real and img part
data_rec = hilbert(data);

% Find phase difference
for i = 1:7
    corrCalib = xcorr(data_rec(:, 1), data_rec(:, i));  
    cal(i) = angle(corrCalib(length(data(:,1))));
end

save('cal.mat', 'cal');
