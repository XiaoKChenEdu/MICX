function setupBoardForRecording(nChannels, lChEnable)
    lMemsize = 1024;
    
    % Setup channels
    for i = 0:nChannels-1
        SpcSetPa(0, 30010 + 100 * i, 1000);  % channel to +/- 1V 
        SpcSetPa(0, 30030 + 100 * i, 1);     % channel to 50 Ohm
    end
    
    % Board configuration parameters
    configParams = [
        11000 lChEnable;    % enable channel for recording
        10000 lMemsize;     % memsize for recording
        10100 lMemsize/2;   % posttrigger for recording
        20030 1;            % enable internal PLL
        20100 0;            % internal clock used
        20000 10000000;     % samplerate 10 MHz
        20110 0;            % no clock output
        40000 0;            % software trigger
        44000 0;            % pulsewidth not used
        40100 0;            % no trigger output
        0     10            % start command
    ];
    
    % Apply configuration
    for i = 1:size(configParams, 1)
        SpcSetPa(0, configParams(i,1), configParams(i,2));
    end
end