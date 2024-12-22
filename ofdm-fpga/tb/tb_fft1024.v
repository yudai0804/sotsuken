// TODO: FFTのメモリの内容を全部吐き出すプログラムは後で書く。
//       まずは雰囲気だけでも動いていそうなことを確認するのが優先。
`timescale 1ns / 1ps

module testbench;
reg clk;
reg rst_n;

reg start;
wire finish;
// BSRAM fft0
wire [31:0] dout0;
wire oce0;
wire ce0;
wire wre0;
wire [10:0] ad0;
wire [31:0] din0;
// BSRAM fft1
wire [31:0] dout1;
wire oce1;
wire ce1;
wire wre1;
wire [10:0] ad1;
wire [31:0] din1;
// BSRAM(prom) w
wire [15:0] dout_w;
wire oce_w;
wire ce_w;
wire [10:0] ad_w;
wire [15:0] din_w;

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
        start <= 1'd0;
    end
    else begin
        // 開始がわかりやすいように1サイクル遅らせる
        if (start == 1'd0) begin
            start <= 1'd1;
        end
        else begin end
    end
end

// リセットの論理が逆なので注意
Gowin_SP_fft0 gowin_sp_fft0_instance(dout0, clk, oce0, ce0, ~rst_n, wre0, ad0, din0);
Gowin_SP_fft1 gowin_sp_fft1_instance(dout1, clk, oce1, ce1, ~rst_n, wre1, ad1, din1);
Gowin_pROM_w gowin_prom_w_instance(dout_w, clk, oce_w, ce_w, ~rst_n, ad_w);
fft1024 fft1024_instance(
    clk,
    rst_n,
    start,
    finish,
    dout0,
    oce0,
    ce0,
    wre0,
    ad0,
    din0,
    dout1,
    oce1,
    ce1,
    wre1,
    ad1,
    din1,
    dout_w,
    oce_w,
    ce_w,
    ad_w,
    din_w
);
// main
initial begin
    // シミュレーションの開始
    $dumpfile("testbench.vcd"); // 波形出力ファイル
    $dumpvars(0, testbench);

    // 初期化
    #0 rst_n = 0;
    #0 rst_n = 1;
    // 適当な時刻で終了
    #(1 /27.0 * 1000 * 1000 * 2) $finish;
end

endmodule