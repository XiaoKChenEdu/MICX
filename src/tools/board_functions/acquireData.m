function data = acquireData(nChannels)
    lMemsize = 1024;
    
    % Wait for ready status
    lStatus = 0;
    while lStatus ~= 20   
        [~, lStatus] = SpcGetPa(0, 10);
    end
    
    % Get data based on channel count
    switch nChannels
        case {2, 4}
            [~, nTmpData] = SpcGetDa(0, 0, 0, nChannels*lMemsize, 16);
            data = reshape(nTmpData, nChannels, [])';
        case 8
            [~, nTmpData0] = SpcGetDa(0, 0, 0, 4*lMemsize, 16);
            [~, nTmpData1] = SpcGetDa(0, 1, 0, 4*lMemsize, 16);
            data0 = reshape(nTmpData0, 4, [])';
            data1 = reshape(nTmpData1, 4, [])';
            data = [data1(:,4) data0 data1(:,1:3)];
    end
end