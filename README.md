# Radar Project - MATLAB Array Signal Processing

This project implements a phased array radar system using MATLAB for signal processing and data acquisition. The system consists of three main components:

## Files Overview

### AutoScan.m
The main program that provides a user interface with four options:
0. Plot existing data
1. Calibration
2. Single Scan and Plot
3. Continuous Auto-Scanning

Features:
- Handles data acquisition from PCI/MC/MX.31xx series boards
- Configures multichannel sampling (up to 8 channels)
- Automated data collection and processing
- Real-time visualization of radar data
- Support for continuous monitoring mode

### tools/calib.m
Calibration utility that:
- Removes DC offset from raw signals
- Performs Hilbert transform for complex signal reconstruction
- Calculates phase differences between channels
- Saves calibration data as 'cal.mat'

### tools/process.m
Core signal processing function that:
- Removes DC offset from input signals
- Applies Hilbert transform for signal reconstruction
- Calculates phase differences between channels
- Applies calibration corrections
- Implements digital beamforming
- Calculates direction of arrival (DoA)
- Generates beam pattern plots

## Technical Specifications
- Operating Frequency: 2.4 GHz
- Number of Antenna Elements: 7
- Array Spacing: λ/2
- Angular Scanning Range: -90° to +90°
- Angular Resolution: 0.1°
- Sampling Rate: 10 MHz
- Sample Size: 1024 points per channel

## Requirements
- MATLAB
- Compatible Data Acquisition Board:
  - MI.31xx (PCI)
  - MC.31xx (Compact PCI)
  - MX.31xx (PXI)
- Data Acquisition Toolbox

## Usage
1. Run `AutoScan.m`
2. Select from available options:
   - Option 0: Plot existing data from previous scans
   - Option 1: Perform system calibration
   - Option 2: Single scan with immediate plot
   - Option 3: Continuous scanning with real-time updates

## Project Structure
RadarProject/
├── MICX/
│   ├── AutoScan.m         # Main program interface
│   ├── micx_driver/       # PCI board drivers
│   │   └── ...            # Driver files
│   ├── tools/             # Signal processing utilities
│   │   ├── calib.m        # Calibration function
│   │   └── process.m         # Process function
│   └── data/              # Data storage
│       ├── calib.txt      # Calibration data
│       ├── cal.mat        # Calibration matrix
│       └── data.txt       # Scan measurement data