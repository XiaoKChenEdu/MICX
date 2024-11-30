addpath('./micx_driver')
addpath('./tools')

close all; clear; clc;

while true
    % Display menu and get user input
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
        case 1
            % Perform calib
            disp('Running calib.m');
            % ----- Initialize PCI boards ----- 
            [nErrorCode, nCount, nPCIVersion] = SpcInPCI;

            % ----- check for board type -----
            [nErrorCode, lBrdType] = SpcGetPa (0, 2000);

            % ----- split up 32-bit lBrdType in bus type (bit 16 - 31) and board type (bit 0 - 15) -----
            nBusType = bitshift (lBrdType, -16);   % lBrdType >> 16
            nBrdType = bitand   (lBrdType, 65535); % lBrdType & 0xffff

            switch nBusType

            case 0
                % ----- MI Boards : PCI Bus -----
                if (nBrdType < 12560) | (nBrdType > 12608)
                    error ('MI.31xx not found');
                end
                sBrdType = '   MI.%x\n';

            case 1
                % ----- MC Boards : Compact PCI Bus -----
                if (nBrdType < 12560) | (nBrdType > 12594)
                    error ('MC.31xx not found');
                end
                sBrdType = '   MC.%x\n';

            case 2
                % ----- MX Boards : PXI Bus -----
                if (nBrdType < 12560) | (nBrdType > 12594)
                    error ('MX.31xx not found');
                end
                sBrdType = '   MX.%x\n';

            otherwise
                fprintf ('No Board found');
            end

            % ----- get some board info -----
            [nErrorCode, lSN]         = SpcGetPa (0, 2030);
            [nErrorCode, lSamplerate] = SpcGetPa (0, 2100);
            [nErrorCode, lMemsize]    = SpcGetPa (0, 2110);
            fprintf ('\n\n');
            fprintf (sBrdType, nBrdType);
            fprintf ('   Serial No. :     %05.0f\n', lSN);
            fprintf ('   max samplerate : %.0f (%.0f MS/s)\n', lSamplerate, lSamplerate / 1000000);
            fprintf ('   max memsize :    %.0f (%.0f MSamples)\n', lMemsize, lMemsize / 2 / 1024 / 1024);

            switch nBrdType

            % ----- MI_MC_MX.3110, MI_MC_MX.3120, MI_MC_MX.3130, MI_MC_MX.3140 -----   
            case {  12560,         12576,         12592,         12608} 

                    nChannels = 2;
                    lChEnable = 3;

            % ----- MI_MC_MX.3111, MI_MC_MX.3121, MI_MC_MX.3131 -----
            case {  12561,         12577,         12593} 

                    nChannels =  4;
                    lChEnable = 15;

            % ----- MI_MC.3112, MI_MC.3122, MI_MC.3132 -----
            case {  12562,      12578,      12594}

                    nChannels =   8; 
                    lChEnable = 255;  

            otherwise
                    nChannels =  2;
                    lChEnable =  3;
            end

            % ----- memsize for recording -----
            lMemsize = 1024;

            % ----- setup board for recording -----
            for i= 0 : nChannels -1
            nErrorCode = SpcSetPa (0, 30010 + 100 * i, 1000);     % channel to +/- 1V 
            nErrorCode = SpcSetPa (0, 30030 + 100 * i, 1   );     % channel to 50 Ohm
            end

            nErrorCode = SpcSetPa (0, 11000,         lChEnable);     % enable channel for recording
            nErrorCode = SpcSetPa (0, 10000,          lMemsize);     % memsize for recording
            nErrorCode = SpcSetPa (0, 10100,        lMemsize/2);     % posttrigger for recording
            nErrorCode = SpcSetPa (0, 20030,                 1);     % enable internal PLL
            nErrorCode = SpcSetPa (0, 20100,                 0);     % internal clock used
            nErrorCode = SpcSetPa (0, 20000,          10000000);     % samplerate 10 MHz
            nErrorCode = SpcSetPa (0, 20110,                 0);     % no clock output
            nErrorCode = SpcSetPa (0, 40000,                 0);     % software trigger
            nErrorCode = SpcSetPa (0, 44000,                 0);     % pulsewidth not used
            nErrorCode = SpcSetPa (0, 40100,                 0);     % no trigger output
            nErrorCode = SpcSetPa (0, 0,                    10);     % start command

            % ----- check for error -----
            if nErrorCode ~= 0
            [nErrorCode, lLastError] = SpcGetPa (0, 999999);
            [nErrorCode, lLastReg]   = SpcGetPa (0, 999998);
            [nErrorCode, lLastValue] = SpcGetPa (0, 999997);
            fprintf ('\n');
            fprintf ('Error:     %.0f\n', lLastError);
            fprintf ('Register:  %.0f\n', lLastReg);
            fprintf ('Value:     %.0f\n', lLastValue);
            else

            % ----- wait for status ready -----
            lStatus    = 0;
            while lStatus ~= 20   
                [nErrorCode, lStatus] = SpcGetPa (0, 10);       % read status
            end

            % ----- set time array for display -----
            t = 0 : lMemsize - 1; 

            % ----- get data from board and display channels -----
            switch nChannels

                % ----- two channels recorded in one memory channel -----
                case 2
                    [nErrorCode, nTmpData] = SpcGetDa (0, 0, 0, 2*lMemsize, 16);

                    nData0(1:1:lMemsize) = nTmpData(1:2:2*lMemsize);
                    nData1(1:1:lMemsize) = nTmpData(2:2:2*lMemsize);

                    plot (t, nData0, t, nData1);

                % ----- four channels recorded in one memory channel -----
                case 4
                    [nErrorCode, nTmpData] = SpcGetDa (0, 0, 0, 4*lMemsize, 16);

                    nData0(1:1:lMemsize) = nTmpData(1:4:4*lMemsize);
                    nData1(1:1:lMemsize) = nTmpData(2:4:4*lMemsize);
                    nData2(1:1:lMemsize) = nTmpData(3:4:4*lMemsize);
                    nData3(1:1:lMemsize) = nTmpData(4:4:4*lMemsize);

                    plot (t, nData0, t, nData1, t, nData2, t, nData3);

                % ----- eight channels recorded in two memory channels -----
                case 8
                    [nErrorCode, nTmpData0] = SpcGetDa (0, 0, 0, 4*lMemsize, 16);
                    [nErrorCode, nTmpData1] = SpcGetDa (0, 1, 0, 4*lMemsize, 16);

                    nData0(1:1:lMemsize) = nTmpData0(1:4:4*lMemsize);
                    nData1(1:1:lMemsize) = nTmpData0(2:4:4*lMemsize);
                    nData2(1:1:lMemsize) = nTmpData0(3:4:4*lMemsize);
                    nData3(1:1:lMemsize) = nTmpData0(4:4:4*lMemsize);

                    nData4(1:1:lMemsize) = nTmpData1(1:4:4*lMemsize);
                    nData5(1:1:lMemsize) = nTmpData1(2:4:4*lMemsize);
                    nData6(1:1:lMemsize) = nTmpData1(3:4:4*lMemsize);
                    nData7(1:1:lMemsize) = nTmpData1(4:4:4*lMemsize);
                    outputData = [nData7' nData0' nData1' nData2' nData3' nData4' nData5' nData6'];
                    dlmwrite('./data/calib.txt', outputData, 'delimiter', ' ', 'precision', '%.6f')    
            end
            end
        case 2
            disp('Scan Once');
            % ----- Initialize PCI boards ----- 
            [nErrorCode, nCount, nPCIVersion] = SpcInPCI;

            % ----- check for board type -----
            [nErrorCode, lBrdType] = SpcGetPa (0, 2000);

            % ----- split up 32-bit lBrdType in bus type (bit 16 - 31) and board type (bit 0 - 15) -----
            nBusType = bitshift (lBrdType, -16);   % lBrdType >> 16
            nBrdType = bitand   (lBrdType, 65535); % lBrdType & 0xffff

            switch nBusType

            case 0
                % ----- MI Boards : PCI Bus -----
                if (nBrdType < 12560) | (nBrdType > 12608)
                    error ('MI.31xx not found');
                end
                sBrdType = '   MI.%x\n';

            case 1
                % ----- MC Boards : Compact PCI Bus -----
                if (nBrdType < 12560) | (nBrdType > 12594)
                    error ('MC.31xx not found');
                end
                sBrdType = '   MC.%x\n';

            case 2
                % ----- MX Boards : PXI Bus -----
                if (nBrdType < 12560) | (nBrdType > 12594)
                    error ('MX.31xx not found');
                end
                sBrdType = '   MX.%x\n';

            otherwise
                fprintf ('No Board found');
            end

            % ----- get some board info -----
            [nErrorCode, lSN]         = SpcGetPa (0, 2030);
            [nErrorCode, lSamplerate] = SpcGetPa (0, 2100);
            [nErrorCode, lMemsize]    = SpcGetPa (0, 2110);
            fprintf ('\n\n');
            fprintf (sBrdType, nBrdType);
            fprintf ('   Serial No. :     %05.0f\n', lSN);
            fprintf ('   max samplerate : %.0f (%.0f MS/s)\n', lSamplerate, lSamplerate / 1000000);
            fprintf ('   max memsize :    %.0f (%.0f MSamples)\n', lMemsize, lMemsize / 2 / 1024 / 1024);

            switch nBrdType

            % ----- MI_MC_MX.3110, MI_MC_MX.3120, MI_MC_MX.3130, MI_MC_MX.3140 -----   
            case {  12560,         12576,         12592,         12608} 

                    nChannels = 2;
                    lChEnable = 3;

            % ----- MI_MC_MX.3111, MI_MC_MX.3121, MI_MC_MX.3131 -----
            case {  12561,         12577,         12593} 

                    nChannels =  4;
                    lChEnable = 15;

            % ----- MI_MC.3112, MI_MC.3122, MI_MC.3132 -----
            case {  12562,      12578,      12594}

                    nChannels =   8; 
                    lChEnable = 255;  

            otherwise
                    nChannels =  2;
                    lChEnable =  3;
            end

            % ----- memsize for recording -----
            lMemsize = 1024;

            % ----- setup board for recording -----
            for i= 0 : nChannels -1
            nErrorCode = SpcSetPa (0, 30010 + 100 * i, 1000);     % channel to +/- 1V 
            nErrorCode = SpcSetPa (0, 30030 + 100 * i, 1   );     % channel to 50 Ohm
            end

            nErrorCode = SpcSetPa (0, 11000,         lChEnable);     % enable channel for recording
            nErrorCode = SpcSetPa (0, 10000,          lMemsize);     % memsize for recording
            nErrorCode = SpcSetPa (0, 10100,        lMemsize/2);     % posttrigger for recording
            nErrorCode = SpcSetPa (0, 20030,                 1);     % enable internal PLL
            nErrorCode = SpcSetPa (0, 20100,                 0);     % internal clock used
            nErrorCode = SpcSetPa (0, 20000,          10000000);     % samplerate 10 MHz
            nErrorCode = SpcSetPa (0, 20110,                 0);     % no clock output
            nErrorCode = SpcSetPa (0, 40000,                 0);     % software trigger
            nErrorCode = SpcSetPa (0, 44000,                 0);     % pulsewidth not used
            nErrorCode = SpcSetPa (0, 40100,                 0);     % no trigger output
            nErrorCode = SpcSetPa (0, 0,                    10);     % start command

            % ----- check for error -----
            if nErrorCode ~= 0
            [nErrorCode, lLastError] = SpcGetPa (0, 999999);
            [nErrorCode, lLastReg]   = SpcGetPa (0, 999998);
            [nErrorCode, lLastValue] = SpcGetPa (0, 999997);
            fprintf ('\n');
            fprintf ('Error:     %.0f\n', lLastError);
            fprintf ('Register:  %.0f\n', lLastReg);
            fprintf ('Value:     %.0f\n', lLastValue);
            else

            % ----- wait for status ready -----
            lStatus    = 0;
            while lStatus ~= 20   
                [nErrorCode, lStatus] = SpcGetPa (0, 10);       % read status
            end

            % ----- set time array for display -----
            t = 0 : lMemsize - 1; 

            % ----- get data from board and display channels -----
            switch nChannels

                % ----- two channels recorded in one memory channel -----
                case 2
                    [nErrorCode, nTmpData] = SpcGetDa (0, 0, 0, 2*lMemsize, 16);

                    nData0(1:1:lMemsize) = nTmpData(1:2:2*lMemsize);
                    nData1(1:1:lMemsize) = nTmpData(2:2:2*lMemsize);

                    plot (t, nData0, t, nData1);

                % ----- four channels recorded in one memory channel -----
                case 4
                    [nErrorCode, nTmpData] = SpcGetDa (0, 0, 0, 4*lMemsize, 16);

                    nData0(1:1:lMemsize) = nTmpData(1:4:4*lMemsize);
                    nData1(1:1:lMemsize) = nTmpData(2:4:4*lMemsize);
                    nData2(1:1:lMemsize) = nTmpData(3:4:4*lMemsize);
                    nData3(1:1:lMemsize) = nTmpData(4:4:4*lMemsize);

                    plot (t, nData0, t, nData1, t, nData2, t, nData3);

                % ----- eight channels recorded in two memory channels -----
                case 8
                    [nErrorCode, nTmpData0] = SpcGetDa (0, 0, 0, 4*lMemsize, 16);
                    [nErrorCode, nTmpData1] = SpcGetDa (0, 1, 0, 4*lMemsize, 16);

                    nData0(1:1:lMemsize) = nTmpData0(1:4:4*lMemsize);
                    nData1(1:1:lMemsize) = nTmpData0(2:4:4*lMemsize);
                    nData2(1:1:lMemsize) = nTmpData0(3:4:4*lMemsize);
                    nData3(1:1:lMemsize) = nTmpData0(4:4:4*lMemsize);

                    nData4(1:1:lMemsize) = nTmpData1(1:4:4*lMemsize);
                    nData5(1:1:lMemsize) = nTmpData1(2:4:4*lMemsize);
                    nData6(1:1:lMemsize) = nTmpData1(3:4:4*lMemsize);
                    nData7(1:1:lMemsize) = nTmpData1(4:4:4*lMemsize);
                    outputData = [nData7' nData0' nData1' nData2' nData3' nData4' nData5' nData6'];
                    dlmwrite('./data/data.txt', outputData, 'delimiter', ' ', 'precision', '%.6f')
                    processFile = './data/data.txt';
                    processData = load(processFile);
                    process(processData);
            end
            end
        case 3
            disp('AutoScan')
            while true
                % ----- Initialize PCI boards ----- 
                [nErrorCode, nCount, nPCIVersion] = SpcInPCI;

                % ----- check for board type -----
                [nErrorCode, lBrdType] = SpcGetPa (0, 2000);

                % ----- split up 32-bit lBrdType in bus type (bit 16 - 31) and board type (bit 0 - 15) -----
                nBusType = bitshift (lBrdType, -16);   % lBrdType >> 16
                nBrdType = bitand   (lBrdType, 65535); % lBrdType & 0xffff

                switch nBusType

                case 0
                    % ----- MI Boards : PCI Bus -----
                    if (nBrdType < 12560) | (nBrdType > 12608)
                        error ('MI.31xx not found');
                    end
                    sBrdType = '   MI.%x\n';

                case 1
                    % ----- MC Boards : Compact PCI Bus -----
                    if (nBrdType < 12560) | (nBrdType > 12594)
                        error ('MC.31xx not found');
                    end
                    sBrdType = '   MC.%x\n';

                case 2
                    % ----- MX Boards : PXI Bus -----
                    if (nBrdType < 12560) | (nBrdType > 12594)
                        error ('MX.31xx not found');
                    end
                    sBrdType = '   MX.%x\n';

                otherwise
                    fprintf ('No Board found');
                end

                % ----- get some board info -----
                [nErrorCode, lSN]         = SpcGetPa (0, 2030);
                [nErrorCode, lSamplerate] = SpcGetPa (0, 2100);
                [nErrorCode, lMemsize]    = SpcGetPa (0, 2110);
                fprintf ('\n\n');
                fprintf (sBrdType, nBrdType);
                fprintf ('   Serial No. :     %05.0f\n', lSN);
                fprintf ('   max samplerate : %.0f (%.0f MS/s)\n', lSamplerate, lSamplerate / 1000000);
                fprintf ('   max memsize :    %.0f (%.0f MSamples)\n', lMemsize, lMemsize / 2 / 1024 / 1024);

                switch nBrdType

                % ----- MI_MC_MX.3110, MI_MC_MX.3120, MI_MC_MX.3130, MI_MC_MX.3140 -----   
                case {  12560,         12576,         12592,         12608} 

                        nChannels = 2;
                        lChEnable = 3;

                % ----- MI_MC_MX.3111, MI_MC_MX.3121, MI_MC_MX.3131 -----
                case {  12561,         12577,         12593} 

                        nChannels =  4;
                        lChEnable = 15;

                % ----- MI_MC.3112, MI_MC.3122, MI_MC.3132 -----
                case {  12562,      12578,      12594}

                        nChannels =   8; 
                        lChEnable = 255;  

                otherwise
                        nChannels =  2;
                        lChEnable =  3;
                end

                % ----- memsize for recording -----
                lMemsize = 1024;

                % ----- setup board for recording -----
                for i= 0 : nChannels -1
                nErrorCode = SpcSetPa (0, 30010 + 100 * i, 1000);     % channel to +/- 1V 
                nErrorCode = SpcSetPa (0, 30030 + 100 * i, 1   );     % channel to 50 Ohm
                end

                nErrorCode = SpcSetPa (0, 11000,         lChEnable);     % enable channel for recording
                nErrorCode = SpcSetPa (0, 10000,          lMemsize);     % memsize for recording
                nErrorCode = SpcSetPa (0, 10100,        lMemsize/2);     % posttrigger for recording
                nErrorCode = SpcSetPa (0, 20030,                 1);     % enable internal PLL
                nErrorCode = SpcSetPa (0, 20100,                 0);     % internal clock used
                nErrorCode = SpcSetPa (0, 20000,          10000000);     % samplerate 10 MHz
                nErrorCode = SpcSetPa (0, 20110,                 0);     % no clock output
                nErrorCode = SpcSetPa (0, 40000,                 0);     % software trigger
                nErrorCode = SpcSetPa (0, 44000,                 0);     % pulsewidth not used
                nErrorCode = SpcSetPa (0, 40100,                 0);     % no trigger output
                nErrorCode = SpcSetPa (0, 0,                    10);     % start command

                % ----- check for error -----
                if nErrorCode ~= 0
                [nErrorCode, lLastError] = SpcGetPa (0, 999999);
                [nErrorCode, lLastReg]   = SpcGetPa (0, 999998);
                [nErrorCode, lLastValue] = SpcGetPa (0, 999997);
                fprintf ('\n');
                fprintf ('Error:     %.0f\n', lLastError);
                fprintf ('Register:  %.0f\n', lLastReg);
                fprintf ('Value:     %.0f\n', lLastValue);
                else

                % ----- wait for status ready -----
                lStatus    = 0;
                while lStatus ~= 20   
                    [nErrorCode, lStatus] = SpcGetPa (0, 10);       % read status
                end

                % ----- set time array for display -----
                t = 0 : lMemsize - 1; 

                % ----- get data from board and display channels -----
                switch nChannels

                    % ----- two channels recorded in one memory channel -----
                    case 2
                        [nErrorCode, nTmpData] = SpcGetDa (0, 0, 0, 2*lMemsize, 16);

                        nData0(1:1:lMemsize) = nTmpData(1:2:2*lMemsize);
                        nData1(1:1:lMemsize) = nTmpData(2:2:2*lMemsize);

                        plot (t, nData0, t, nData1);

                    % ----- four channels recorded in one memory channel -----
                    case 4
                        [nErrorCode, nTmpData] = SpcGetDa (0, 0, 0, 4*lMemsize, 16);

                        nData0(1:1:lMemsize) = nTmpData(1:4:4*lMemsize);
                        nData1(1:1:lMemsize) = nTmpData(2:4:4*lMemsize);
                        nData2(1:1:lMemsize) = nTmpData(3:4:4*lMemsize);
                        nData3(1:1:lMemsize) = nTmpData(4:4:4*lMemsize);

                        plot (t, nData0, t, nData1, t, nData2, t, nData3);

                    % ----- eight channels recorded in two memory channels -----
                    case 8
                        [nErrorCode, nTmpData0] = SpcGetDa (0, 0, 0, 4*lMemsize, 16);
                        [nErrorCode, nTmpData1] = SpcGetDa (0, 1, 0, 4*lMemsize, 16);

                        nData0(1:1:lMemsize) = nTmpData0(1:4:4*lMemsize);
                        nData1(1:1:lMemsize) = nTmpData0(2:4:4*lMemsize);
                        nData2(1:1:lMemsize) = nTmpData0(3:4:4*lMemsize);
                        nData3(1:1:lMemsize) = nTmpData0(4:4:4*lMemsize);

                        nData4(1:1:lMemsize) = nTmpData1(1:4:4*lMemsize);
                        nData5(1:1:lMemsize) = nTmpData1(2:4:4*lMemsize);
                        nData6(1:1:lMemsize) = nTmpData1(3:4:4*lMemsize);
                        nData7(1:1:lMemsize) = nTmpData1(4:4:4*lMemsize);
                        outputData = [nData7' nData0' nData1' nData2' nData3' nData4' nData5' nData6'];
                        dlmwrite('./data/data.txt', outputData, 'delimiter', ' ', 'precision', '%.6f')
                        processFile = './data/data.txt';
                        processData = load(processFile);
                        process(processData);
                end
                pause(2);
                close all;
                end
            end
        otherwise
            disp('Invalid choice. Please select 1, 2, or 3.');
    end
end