`timescale 1ns / 1ps

module testbench;
reg clk;
reg rst_n;

wire adc_clk;
wire din;
reg dout;
wire cs;
reg enable;
wire [9:0] data;
wire available;
reg clear_available;

// 27MHz
parameter CLK_FREQ = 27_000_000;
parameter CLK_FREQ_MHZ = 27.0;
// 0.9MHz
parameter MCP3002_CLK_FREQ = 900_000;

localparam CYCLE = CLK_FREQ / MCP3002_CLK_FREQ;
localparam HALF_CYCLE = CYCLE / 2;

mcp3002#(
    CLK_FREQ,
    MCP3002_CLK_FREQ
)mcp3002_instance(
    clk,
    rst_n,
    adc_clk,
    din,
    dout,
    cs,
    enable,
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

    // SPI test
    #0 dout = 0;
    #0 enable = 1'd1;
    // 送信している間なので、適当に待機
    // 9
    #(1 / 27.0 * 1000 * CYCLE * 5) dout = 1;
    // 8
    #(1 / 27.0 * 1000 * CYCLE) dout = 0;
    // 7
    #(1 / 27.0 * 1000 * CYCLE) dout = 1;
    // 6
    #(1 / 27.0 * 1000 * CYCLE) dout = 0;
    // 5
    #(1 / 27.0 * 1000 * CYCLE) dout = 1;
    // 4
    #(1 / 27.0 * 1000 * CYCLE) dout = 0;
    // 3
    #(1 / 27.0 * 1000 * CYCLE) dout = 1;
    // 2
    #(1 / 27.0 * 1000 * CYCLE) dout = 0;
    // 1
    #(1 / 27.0 * 1000 * CYCLE) dout = 1;
    // 0
    #(1 / 27.0 * 1000 * CYCLE) dout = 0;
    // 最後は1サイクル待機
    #(1 / 27.0 * 1000 * CYCLE) dout = 0;
    // availableなのを確認
    #(1 / 27.0 * 1000 * CYCLE) assert(available == 1'd1);
    // dataがただし以下確認
    #0 assert(data == 10'h2AA);
    // clearしたらちゃんとavailable=0になるか確認
    #0 clear_available = 1'd1;
    #(1 / 27.0 * 1000) assert(available == 1'd0);
    // finish
    #(1 / 27.0 * 1000 * CYCLE) $finish;
end

endmodule