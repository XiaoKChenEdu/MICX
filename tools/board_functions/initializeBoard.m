function [nChannels, lChEnable] = initializeBoard()
    addpath('./micx_driver')
    addpath('./tools')
    
    % ----- Initialize and check PCI boards -----
    [nErrorCode, nCount, nPCIVersion] = SpcInPCI;
    [nErrorCode, lBrdType] = SpcGetPa(0, 2000);
    
    % ----- split up 32-bit lBrdType -----
    nBusType = bitshift(lBrdType, -16);
    nBrdType = bitand(lBrdType, 65535);
    
    % Validate board type and get board info
    validateBoardType(nBusType, nBrdType);
    displayBoardInfo();
    
    % Set channels based on board type
    [nChannels, lChEnable] = getChannelConfig(nBrdType);
end