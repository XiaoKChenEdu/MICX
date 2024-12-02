addpath('./micx_driver')
addpath('./tools')
addpath('./tools/board_functions')
close all; clear; clc;

% Main loop
while true
    disp('Select an option:');
    disp('0. Plot');
    disp('1. Perform calib.m');
    disp('2. Scan once and Plot');
    disp('3. AutoScan and Plot');
    choice = input('Enter your choice: ');
    
    switch choice
        case 0
            processFile = './data/data.txt';
            processData = load(processFile);
            process(processData);
            
        case {1, 2, 3}
            [nChannels, lChEnable] = initializeBoard();
            setupBoardForRecording(nChannels, lChEnable);
            
            if choice == 1
                data = acquireData(nChannels);
                dlmwrite('./data/calib.txt', data, 'delimiter', ' ', 'precision', '%.6f');
                
            elseif choice == 2
                data = acquireData(nChannels);
                dlmwrite('./data/data.txt', data, 'delimiter', ' ', 'precision', '%.6f');
                processData = load('./data/data.txt');
                process(processData);
                
            else % choice == 3
                while true
                    data = acquireData(nChannels);
                    dlmwrite('./data/data.txt', data, 'delimiter', ' ', 'precision', '%.6f');
                    processData = load('./data/data.txt');
                    process(processData);
                    pause(2);
                    close all;
                end
            end
            
        otherwise
            disp('Invalid choice. Please select 0, 1, 2, or 3.');
    end
end