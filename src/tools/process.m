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
    
    % Find the peak angle and magnitude
    [ ~, peak_idx] = max(mag);
    peak_angle = peak_idx/10 - 90;

    % Create radar-style plot
    figure('Position', [100 100 600 600]);
    set(gcf, 'Color', 'k');
    
    % Create polar plot with adjusted angles
    % h = polar(pi/2 - d_rad, mag, 'g-');
    % set(h, 'LineWidth', 2);
    polar(0, max(mag), '');  % without the line
    hold on
    
    % Plot the peak point
    peak_rad = peak_angle * pi/180;
    h_peak = polar(pi/2 - peak_rad, mag(peak_idx), 'ro');
    set(h_peak, 'MarkerSize', 10, 'MarkerFaceColor', 'r');
    
    % Customize the plot appearance
    ax = gca;
    set(ax, 'Color', 'k');
    set(ax, 'GridColor', [0.2 0.2 0.2]);
    
    % Adjust text labels for proper orientation
    t = findall(ax, 'Type', 'text');
    for i = 1:length(t)
        txt = get(t(i), 'String');
        pos = get(t(i), 'Position');
        val = str2num(txt);
        
        % Only modify if it's a number between 0 and 360 and near the rim
        if ~isempty(val) && val >= 0 && val <= 360 && norm(pos(1:2)) > max(mag)*1.2
            new_val = mod(-val + 90, 360);
            set(t(i), 'String', num2str(new_val));
        end
        set(t(i), 'Color', [0 0.8 0]);
    end
    
    grid on;
    
    % Add title with precise angle information
    title(sprintf('Target Detection at %.2f°', peak_angle), ...
        'Color', [0 0.8 0], 'FontSize', 12);
    
end
