// prom_wは少し変なことをやっているので、ちゃんと動くかの確認用

`timescale 1ns / 1ps

module testbench;
reg clk;
reg rst_n;

wire [15:0] dout;
reg oce;
reg ce;
reg [10:0] ad;
reg [1:0] cnt;

// 27MHz
parameter CLK_FREQ = 27_000_000;
parameter CLK_FREQ_MHZ = 27.0;

// Generate clock
initial begin
    clk = 0;
end
always begin
    #(((1 / CLK_FREQ_MHZ) / 2.0) * 1000) clk = ~clk;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        oce <= 1'd1;
        ce <= 1'd1;
        ad <= 11'd0;
        cnt <= 2'd0;
    end
    else begin
        if (cnt == 2'd3) begin
            if (ad == 11'd1024)
                ad <= 11'd0;
            else
                ad <= ad + 1'd1;
        end
        else begin
            cnt <= cnt + 1'd1;
        end
    end
end

// リセットの論理が逆なので注意
Gowin_pROM_w sp(dout, clk, oce, ce, ~rst_n, ad);

// main
initial begin
    // シミュレーションの開始
    $dumpfile("testbench.vcd"); // 波形出力ファイル
    $dumpvars(0, testbench);

    // 初期化
    #0 rst_n = 0;
    #0 rst_n = 1;
    #0 ce = 1'd1;
    #0 ad = 11'd0;
    // 適当な時刻で終了
    #(1 /27.0 * 1000 * 1000 * 2) $finish;
end

endmodule