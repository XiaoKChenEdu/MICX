function setupBoardForRecording(nChannels, lChEnable)
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
    nErrorCode = SpcSetPa (0, 0,                    10);     % start commandm,

end