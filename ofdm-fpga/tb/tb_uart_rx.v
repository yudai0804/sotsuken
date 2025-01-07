`timescale 1ns / 1ps

module testbench;
reg clk;
reg rst_n;

reg rx_pin;
wire [7:0] data;
wire available;
reg clear_available;

// 27MHz
parameter CLK_FREQ = 27_000_000;
parameter CLK_FREQ_MHZ = 27.0;

parameter BOUD_RATE = 9600;

localparam CYCLE = CLK_FREQ / BOUD_RATE;
localparam HALF_CYCLE = CYCLE / 2;

uart_rx#(
    CLK_FREQ,
    BOUD_RATE
)uart_rx_instance(
    clk,
    rst_n,
    rx_pin,
    data,
    available,
    clear_available
);

// assert
task assert(input condition);
if (!condition) begin
    $display("ASSERTION FAILED: time %0t", $time);
end
endtask

// Generate clock
initial begin
    clk = 0;
end
always begin
    #(((1 / CLK_FREQ_MHZ) / 2.0) * 1000) clk = ~clk;
end

// main
initial begin
    // シミュレーションの開始
    $dumpfile("testbench.vcd"); // 波形出力ファイル
    $dumpvars(0, testbench);

    // 初期化
    #0 rst_n = 0;
    #0 rst_n = 1;
    #0 rx_pin = 1'd0;
    // 0
    #(1 / 27.0 * 1000 * CYCLE) rx_pin = 1'd1;
    // 1
    #(1 / 27.0 * 1000 * CYCLE) rx_pin = 1'd0;
    // 2
    #(1 / 27.0 * 1000 * CYCLE) rx_pin = 1'd0;
    // 3
    #(1 / 27.0 * 1000 * CYCLE) rx_pin = 1'd0;
    // 4
    #(1 / 27.0 * 1000 * CYCLE) rx_pin = 1'd0;
    // 5
    #(1 / 27.0 * 1000 * CYCLE) rx_pin = 1'd0;
    // 6
    #(1 / 27.0 * 1000 * CYCLE) rx_pin = 1'd1;
    // 7
    #(1 / 27.0 * 1000 * CYCLE) rx_pin = 1'd0;
    // stop
    #(1 / 27.0 * 1000 * CYCLE) rx_pin = 1'd1;
    // availableなのを確認
    #(1 / 27.0 * 1000 * (CYCLE + 1)) assert(available == 1'd1);
    // dataがただし以下確認
    #0 assert(data == 8'h41);
    // clearしたらちゃんとavailable=0になるか確認
    #0 clear_available = 1'd1;
    #(1 / 27.0 * 1000) assert(available == 1'd0);

    // 適当な時刻で終了
    #(1 / 27.0 * 1000 * CYCLE) $finish;
end

endmodule