`ifdef SIMULATOR
`timescale 1ns / 1ps

module testbench;
reg clk;
reg rst_n;

reg rx_pin;
wire tx_pin;
wire [5:0] led;
wire adc_clk;
wire adc_din;
reg adc_dout;
wire adc_cs;

`else

module top(
    input clk,
    input rst_n,
    input rx_pin,
    output tx_pin,
    output [5:0] led
    // output adc_clk,
    // output adc_din,
    // input adc_dout,
    // output adc_cs
);
`endif

// 27MHz
localparam CLK_FREQ = 27_000_000;
localparam CLK_FREQ_MHZ = 27.0;
// 9600bps
localparam UART_BOUD_RATE = 9600;
// 0.9MHz
localparam MCP3002_CLK_FREQ = 900_000;

localparam UART_CYCLE = CLK_FREQ / UART_BOUD_RATE;
localparam UART_CYCLE_10 = UART_CYCLE * 10;
localparam MCP3002_CYCLE = CLK_FREQ / MCP3002_CLK_FREQ;

reg [7:0] state;
reg [15:0] cycle;

reg uart_tx_start;
reg [7:0] uart_tx_data;
wire uart_tx_finish;

wire [7:0] uart_rx_data;
wire uart_rx_available;
reg uart_rx_clear_available;

uart_tx#
(
    CLK_FREQ,
    UART_BOUD_RATE
)uart_tx_instance(
    clk,
    rst_n,
    uart_tx_start,
    uart_tx_data,
    tx_pin,
    uart_tx_finish
);

uart_rx#
(
    CLK_FREQ,
    UART_BOUD_RATE
)uart_rx_instance(
    clk,
    rst_n,
    rx_pin,
    uart_rx_data,
    uart_rx_available,
    uart_rx_clear_available
);
/*
led#
(
    .CLK_FREQ(CLK_FREQ)
)led_instance(
    .clk(clk),
    .rst_n(rst_n),
    .led(led)
);
*/

// オウム返しをする
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        uart_tx_start <= 1'd0;
        uart_tx_data <= 8'd0;

        uart_rx_clear_available <= 1'd0;

        state <= 8'd0;
        cycle <= 16'd0;
    end
    else begin
        case (state)
            8'd0: begin
                if (uart_rx_available == 1'd1) begin
                    uart_rx_clear_available <= 1'd1;
                    uart_tx_data <= uart_rx_data;
                    uart_tx_start <= 1'd1;
                    state <= 8'd1;
                end
            end
            8'd1: begin
                uart_tx_start <= 1'd0;
                state <= 8'd0;
            end
        endcase
    end
end

// /*

// Helloを出力
/*
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        uart_tx_start <= 1'd0;
        uart_tx_data <= 8'd0;
        state <= 8'd0;
        cycle <= 16'd0;
    end
    else begin
        uart_tx_start <= 1'd1;
        if (cycle == UART_CYCLE_10 - 1) begin
            cycle <= 16'd0;
            state <= (state != 8'd6) ? state + 1'd1 : 8'd0;
        end
        else begin
            cycle <= cycle + 1'd1;
        end
        case (state)
            8'd0: tx_data <= "H";
            8'd1: tx_data <= "e";
            8'd2: tx_data <= "l";
            8'd3: tx_data <= "l";
            8'd4: tx_data <= "o";
            8'd5: tx_data <= 8'h0d;
            8'd6: tx_data <= "\n";
        endcase
    end
end
*/

// */

`ifdef SIMULATOR
// Generate clock
initial begin
    clk = 0;
end
always begin
    #(((1 / CLK_FREQ_MHZ) / 2.0) * 1000) clk = ~clk;
end

initial begin
    // シミュレーションの開始
    $dumpfile("testbench.vcd"); // 波形出力ファイル
    $dumpvars(0, testbench);

    // 初期化
    #0 rst_n = 0;
    #0 rst_n = 1;
    // 適当な時間で終了
    #(1 / 27.0 * 1000 * UART_CYCLE_10 * 2) $finish;
end
`endif
endmodule