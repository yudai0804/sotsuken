`timescale 1ns / 1ps

// tb_fft1024の実験用
module mux_sp_fft(
    input oce_i0,
    input oce_i1,
    output oce_o,
    input ce_i0,
    input ce_i1,
    output ce_o,
    input wre_i0,
    input wre_i1,
    output wre_o,
    input [10:0] ad_i0,
    input [10:0] ad_i1,
    output [10:0] ad_o,
    input [31:0] din_i0,
    input [31:0] din_i1,
    output [31:0] din_o,
    input s0
);
    assign oce_o = s0 ? oce_i1 : oce_i0;
    assign ce_o = s0 ? ce_i1 : ce_i0;
    assign wre_o = s0 ? wre_i1 : wre_i0;
    assign ad_o = s0 ? ad_i1 : ad_i0;
    assign din_o = s0 ? din_i1  :din_i0;
endmodule

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

// BSRAM fft0(fft1024)
wire fft1024_oce0;
wire fft1024_ce0;
wire fft1024_wre0;
wire [10:0] fft1024_ad0;
wire [31:0] fft1024_din0;
// BSRAM fft1(fft1024)
wire fft1024_oce1;
wire fft1024_ce1;
wire fft1024_wre1;
wire [10:0] fft1024_ad1;
wire [31:0] fft1024_din1;

// BSRAM fft0(disp)
reg disp_oce0;
reg disp_ce0;
reg disp_wre0;
reg [10:0] disp_ad0;
reg [31:0] disp_din0;
// BSRAM fft1(disp)
reg disp_oce1;
reg disp_ce1;
reg disp_wre1;
reg [10:0] disp_ad1;
reg [31:0] disp_din1;

// 27MHz
parameter CLK_FREQ = 27_000_000;
parameter CLK_FREQ_MHZ = 27.0;

reg s;

mux_sp_fft mux_sp_fft_instance0(
    disp_oce0,
    fft1024_oce0,
    oce0,
    disp_ce0,
    fft1024_ce0,
    ce0,
    disp_wre0,
    fft1024_wre0,
    wre0,
    disp_ad0,
    fft1024_ad0,
    ad0,
    disp_din0,
    fft1024_din0,
    din0,
    s
);

mux_sp_fft mux_sp_fft_instance1(
    disp_oce1,
    fft1024_oce1,
    oce1,
    disp_ce1,
    fft1024_ce1,
    ce1,
    disp_wre1,
    fft1024_wre1,
    wre1,
    disp_ad1,
    fft1024_ad1,
    ad1,
    disp_din1,
    fft1024_din1,
    din1,
    s
);

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
    fft1024_oce0,
    fft1024_ce0,
    fft1024_wre0,
    fft1024_ad0,
    fft1024_din0,
    dout1,
    fft1024_oce1,
    fft1024_ce1,
    fft1024_wre1,
    fft1024_ad1,
    fft1024_din1,
    dout_w,
    oce_w,
    ce_w,
    ad_w
);

// Generate clock
initial begin
    clk = 0;
end
always begin
    #(((1 / CLK_FREQ_MHZ) / 2.0) * 1000) clk = ~clk;
end

reg [3:0] state;
reg [10:0] addr_cnt;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        start <= 1'd0;
        state <= 4'd0;
        addr_cnt <= 11'd0;
        s <= 1'd1;
    end
    else begin
        case (state)
            4'd0: begin
                state <= 4'd1;
                start <= 1'd1;
                s <= 1'd1;
            end
            4'd1: begin
                if (finish == 1'd1) begin
                    start <= 1'd0;
                    state <= 4'd2;
                    s <= 1'd0;
                    disp_oce0 <= 1'd1;
                    disp_ce0 <= 1'd1;
                    disp_wre0 <= 1'd0;
                    disp_ad0 <= 11'd0;
                    disp_din0 <= 32'd0;
                    disp_oce1 <= 1'd1;
                    disp_ce1 <= 1'd1;
                    disp_wre1 <= 1'd0;
                    disp_ad1 <= 11'd0;
                    disp_din1 <= 32'd0;
                end
                else begin
                    start <= 1'd0;
                end
            end
            4'd2: begin
                state <= 4'd3;
                disp_ad0 <= addr_cnt + 1'd1;
                addr_cnt <= addr_cnt + 1'd1;
            end
            4'd3: begin
                $display("%d", dout0);
                disp_ad0 <= addr_cnt + 1'd1;
                if (addr_cnt == 11'd510) begin
                    state <= 4'd4;
                    addr_cnt <= 11'd0;
                end
                else begin
                    addr_cnt <= addr_cnt + 1'd1;
                end
            end
            4'd4: begin
                // print ad0=510
                $display("%d", dout0);
                state <= 4'd5;
            end
            4'd5: begin
                // print ad0=511
                $display("%d", dout0);
                disp_ad1 <= addr_cnt + 1'd1;
                addr_cnt <= addr_cnt + 1'd1;
                state <= 4'd6;
            end
            4'd6: begin
                $display("%d", dout1);
                disp_ad1 <= addr_cnt + 1'd1;
                if (addr_cnt == 11'd510) begin
                    state <= 4'd7;
                    addr_cnt <= 11'd0;
                end
                else begin
                    addr_cnt <= addr_cnt + 1'd1;
                end
            end
            4'd7: begin
                // print ad1=510
                $display("%d", dout1);
                state <= 4'd8;
            end
            4'd8: begin
                // print ad1=511
                $display("%d", dout1);
                state <= 4'd9;
            end
            default: begin
                // 何もしない
            end
        endcase
    end
end

// main
initial begin
    // シミュレーションの開始
    $dumpfile("testbench.vcd"); // 波形出力ファイル
    $dumpvars(0, testbench);

    // 初期化
    #0 rst_n = 0;
    #0 rst_n = 1;
    // 適当な時刻で終了
    #(1 /27.0 * 1000 * 600 * 27) $finish;
end

endmodule