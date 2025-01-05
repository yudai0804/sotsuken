// tb_uart_txはテストベンチのみ
// 期待した値かのテストは大変なのでやらない(とくにコーナーケース)

`timescale 1ns / 1ps

module testbench;
reg clk;
reg rst_n;

reg start;
reg [7:0] data;
wire finish;
wire tx_pin;

// 27MHz
parameter CLK_FREQ = 27_000_000;
parameter CLK_FREQ_MHZ = 27.0;

parameter BOUD_RATE = 115200;

localparam CYCLE = CLK_FREQ / BOUD_RATE;

uart_tx#(
    CLK_FREQ,
    BOUD_RATE
)uart_tx_instance(
    clk,
    rst_n,
    start,
    data,
    tx_pin,
    finish
);

    // task assert(input condition, input [1023:0] message);
    //     if (!condition) begin
    //         $display("ASSERTION FAILED at time %0t: %s", $time, message);
    //         $stop; // シミュレーション停止
    //     end
    // endtask

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
    #0 start = 1'd1;
    #0 data = 8'h41;
    // 最初は0.6クロックだけずらす
    // 0.5クロック目の立ち上がりで値が変化するので、少しだけ送らせて0.6
    // 本来は真ん中で読むべきだが、それでは簡単すぎてテストの意味がなくなってしまうので、最初に読む
    // 1回目
    // start bit
    // 最初にfinish = 0なのを確認
    #(1 /27.0 * 1000 * 0.6) assert(finish == 1'd0);
    #0 assert(tx_pin == 1'd0);
    // bit 0
    #(1 /27.0 * 1000 * CYCLE) assert(tx_pin == 1'd1);
    // bit 1
    #(1 /27.0 * 1000 * CYCLE) assert(tx_pin == 1'd0);
    // bit 2
    #(1 /27.0 * 1000 * CYCLE) assert(tx_pin == 1'd0);
    // bit 3
    #(1 /27.0 * 1000 * CYCLE) assert(tx_pin == 1'd0);
    // bit 4
    #(1 /27.0 * 1000 * CYCLE) assert(tx_pin == 1'd0);
    // bit 5
    #(1 /27.0 * 1000 * CYCLE) assert(tx_pin == 1'd0);
    // bit 6
    #(1 /27.0 * 1000 * CYCLE) assert(tx_pin == 1'd1);
    // bit 7
    #(1 /27.0 * 1000 * CYCLE) assert(tx_pin == 1'd0);
    // stop bit
    #(1 /27.0 * 1000 * CYCLE) assert(tx_pin == 1'd1);
    // 2回目
    // start bit
    // finish = 0なのを確認
    #(1 /27.0 * 1000 * CYCLE) assert(finish == 1'd0);
    #0 assert(tx_pin == 1'd0);
    // bit 0
    #(1 /27.0 * 1000 * CYCLE) assert(tx_pin == 1'd1);
    #0 start = 1'd0;
    // bit 1
    #(1 /27.0 * 1000 * CYCLE) assert(tx_pin == 1'd0);
    // bit 2
    #(1 /27.0 * 1000 * CYCLE) assert(tx_pin == 1'd0);
    // bit 3
    #(1 /27.0 * 1000 * CYCLE) assert(tx_pin == 1'd0);
    // bit 4
    #(1 /27.0 * 1000 * CYCLE) assert(tx_pin == 1'd0);
    // bit 5
    #(1 /27.0 * 1000 * CYCLE) assert(tx_pin == 1'd0);
    // bit 6
    #(1 /27.0 * 1000 * CYCLE) assert(tx_pin == 1'd1);
    // bit 7
    #(1 /27.0 * 1000 * CYCLE) assert(tx_pin == 1'd0);
    // stop bit
    #(1 /27.0 * 1000 * CYCLE) assert(tx_pin == 1'd1);
    // 最後にちゃんとfinish=1になっていることを確認
    #(1 /27.0 * 1000 * CYCLE) assert(finish == 1'd1);
    // 終了したらtx_pin=1であることも確認
    #0 assert(tx_pin == 1'd1);
    // 適当な時刻で終了
    #(1 /27.0 * 1000 * 2 * CYCLE) $finish;
end

endmodule