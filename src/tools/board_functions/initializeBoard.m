function [nChannels, lChEnable] = initializeBoard()
    addpath('./micx_driver')
    addpath('./tools')
    
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
end