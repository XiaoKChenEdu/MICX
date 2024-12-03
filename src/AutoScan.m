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
    disp('4. AutoTrack (Testing)');
    choice = input('Enter your choice: ');
    
    switch choice
        case 0
            close all; clear; clc;
            processFile = './data/data.txt';
            processData = load(processFile);
            process(processData);
            
        case 1
            close all; clear; clc;
            [nChannels, lChEnable] = initializeBoard();
            setupBoardForRecording(nChannels, lChEnable);
            data = acquireData(nChannels);
            dlmwrite('./data/calib.txt', data, 'delimiter', ' ', 'precision', '%.6f');
            calib;
                
        case 2
            close all; clear; clc;
            [nChannels, lChEnable] = initializeBoard();
            setupBoardForRecording(nChannels, lChEnable);
            data = acquireData(nChannels);
            dlmwrite('./data/data.txt', data, 'delimiter', ' ', 'precision', '%.6f');
            processData = load('./data/data.txt');
            process(processData);
                
        case 3
            while true
                clear; clc;
                [nChannels, lChEnable] = initializeBoard();
                setupBoardForRecording(nChannels, lChEnable);
                data = acquireData(nChannels);
                dlmwrite('./data/data.txt', data, 'delimiter', ' ', 'precision', '%.6f');
                processData = load('./data/data.txt');
                process(processData);
                pause(0.5);
            end

        case 4
            while true
                clear; clc;
                [nChannels, lChEnable] = initializeBoard();
                setupBoardForRecording(nChannels, lChEnable);
                data = acquireData(nChannels);
                dlmwrite('./data/data.txt', data, 'delimiter', ' ', 'precision', '%.6f');
                processData = load('./data/data.txt');
                process_track(processData);
                pause(0.5);
            end

        otherwise
            disp('Invalid choice. Please select 0, 1, 2, 3 or 4.');
    end
end