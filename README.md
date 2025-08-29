# SimpleLogic
FPGA 4-bit counter FIFO logger via NI USB-6002
## Overview
This project demonstrates a complete FPGA-to-PC data acquisition system:

- **FPGA Design (Verilog)**: A 4-bit counter increments on a 1 Hz tick when triggered by a National Instruments (NI) device. Counter values are stored in a simple 16-depth FIFO. FIFO status flags (`full` and `empty`) are exposed to the NI device. LEDs indicate counter value and trigger status.

- **MATLAB Logger**: Uses NI-DAQ hardware to:
  - Send trigger signals to enable FPGA counting.
  - Pulse FIFO read (`fifo_rd`) signals to retrieve counter data.
  - Real-time plotting of counter values.
  - Log data to a file continuously, appending new sessions without overwriting previous data.

## Hardware Setup
- FPGA: DE10-Lite or compatible board.
- NI USB-6002 (or similar DAQ device with digital I/O).
- Connections:
  - FPGA FIFO data lines → NI digital input (4 bits).
  - FPGA FIFO status lines → NI digital input (`fifo_full`, `fifo_empty`).
  - NI digital outputs → FPGA `trigger_in` and `fifo_rd`.

## FPGA Design (Verilog)
- **SimpleLogic.v**
  - **Clocking**: Uses a PLL to convert 50 MHz board clock to 10 MHz, then divides to 1 Hz for counting.
  - **Counter**: 4-bit counter enabled by `trigger_in`.
  - **FIFO**: Depth of 16, synchronous single-clock implementation.
  - **LEDs**: Show counter value (`LEDR[3:0]`) and trigger status (`LEDR[9]`).
  - **FIFO Interface**: `fifo_data`, `fifo_full`, `fifo_empty`.

## MATLAB Logger
- **SimpleLogic_logger.m**
- Configures NI-DAQ digital channels for input and output.
- Controls FPGA trigger and reads FIFO data in real time.
- Plots counter values dynamically and logs to a text file.
- Adjustable parameters:
  - `deviceID`: NI device name.
  - `logFile`: Log file path.
  - `duration_minutes`: Total logging time.
  - `pulse_width_sec`: FIFO read pulse width.
  - `sample_delay_sec`: Delay between pulse and reading data.

## Usage
1. Program the FPGA with `SimpleLogic.v`.
2. Connect NI device according to hardware setup.
3. Run `SimpleLogic_logger.m` in MATLAB.
4. Observe real-time plot and verify logging in `fpga_log.txt`.

## Notes
- Ensure digital lines mapping in MATLAB matches FPGA pinout.
- FIFO read pulses are synchronized to prevent data loss.
- Real-time plotting is limited to recent 100 samples for performance.
