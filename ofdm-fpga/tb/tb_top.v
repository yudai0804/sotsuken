// topのテストベンチだけど、demodulationのテストベンチも兼ねてる

`timescale 1ns / 1ps

module testbench;
reg clk;
reg rst_n;

// reg rx_pin;
wire tx_pin;
wire [5:0] led;
wire adc_clk;
wire adc_din;
wire adc_dout;
wire adc_cs;
wire clk_pll;
wire rst_n_pll;

// `ifdef FAST_SIMULATION
// // 48MHz
// localparam CLK_FREQ = 48_000_000;
// localparam CLK_FREQ_MHZ = 48.0;
// // 1MHz
// localparam UART_BOUD_RATE = 1_000_000;
// // 12MHz
// localparam MCP3002_CLK_FREQ = 12_000_000;
// // 600kHz
// localparam ADC_SAMPLING_FREQ = 600_000;
// `else
// 24MHz
localparam CLK_FREQ = 24_000_000;
localparam CLK_FREQ_MHZ = 24.0;
// 9600bps
localparam UART_BOUD_RATE = 9600;
// 0.8MHz
localparam MCP3002_CLK_FREQ = 800_000;
// 48kHz
localparam ADC_SAMPLING_FREQ = 48_000;
// `endif
localparam ADC_SAMPLING_CYCLE = CLK_FREQ / ADC_SAMPLING_FREQ;

localparam UART_CYCLE = CLK_FREQ / UART_BOUD_RATE;
localparam UART_CYCLE_10 = UART_CYCLE * 10;
localparam MCP3002_CYCLE = CLK_FREQ / MCP3002_CLK_FREQ;

// tb
top
#(
    CLK_FREQ, 
    UART_BOUD_RATE, 
    MCP3002_CLK_FREQ, 
    ADC_SAMPLING_FREQ
)top_instance(
    clk,
    rst_n,
    1'd0,
    tx_pin,
    led,
    adc_clk,
    adc_din,
    adc_dout,
    adc_cs,
    clk_pll,
    rst_n_pll
);
// adc_doutの動作はPythonで自動生成
testbench_adc_dout testbench_adc_dout_instance(adc_cs, adc_clk, rst_n_pll, adc_dout);

// Generate clock
initial begin
    clk = 0;
end
always begin
    #(((1 / 27.0) / 2.0) * 1000) clk = ~clk;
end

initial begin
    // シミュレーションの開始
    $dumpfile("testbench.vcd"); // 波形出力ファイル
    $dumpvars(0, testbench);

    // 初期化
    #0 rst_n = 0;
    #0 rst_n = 1;
    `ifdef SINGLE_SIMULATION
    #(1 / CLK_FREQ_MHZ * 1000 * (ADC_SAMPLING_CYCLE * 1.75 * 1024)) $finish;
    `else
    #(1 / CLK_FREQ_MHZ * 1000 * (ADC_SAMPLING_CYCLE * 2.75 * 1024)) $finish;
    `endif
    // #(1 / CLK_FREQ_MHZ * 1000 * (ADC_SAMPLING_CYCLE * 10.75 * 1024)) $finish;
end

endmodule
