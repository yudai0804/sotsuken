//Copyright (C)2014-2025 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//Tool Version: V1.9.9.03  Education
//Created Time: 2025-01-18 22:58:31
create_clock -name clk -period 37.037 -waveform {0 18.518} [get_ports {clk}]
//create_clock -name clk_pll -period 41.667 -waveform {0 10.416} [get_ports {clk_pll}]
report_timing -setup -max_paths 200 -max_common_paths 1
