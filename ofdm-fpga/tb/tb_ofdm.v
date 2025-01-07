`timescale 1ns / 1ps

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

reg fft1024_start;
wire fft1024_finish;
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
// BSRAM fft0(ofdm)
wire ofdm_oce0;
wire ofdm_ce0;
// wre0はread onlyなので使わない
wire ofdm_wre0;
wire [10:0] ofdm_ad0;
// din0はread onlyなので使わない
wire [31:0] ofdm_din0;

reg s;

reg ofdm_start;
wire ofdm_finish;
wire ofdm_success;
wire [95:0] ofdm_res;

// 27MHz
parameter CLK_FREQ = 27_000_000;
parameter CLK_FREQ_MHZ = 27.0;

mux_sp_fft mux_sp_fft_instance0(
    ofdm_oce0,
    fft1024_oce0,
    oce0,
    ofdm_ce0,
    fft1024_ce0,
    ce0,
    ofdm_wre0,
    fft1024_wre0,
    wre0,
    ofdm_ad0,
    fft1024_ad0,
    ad0,
    ofdm_din0,
    fft1024_din0,
    din0,
    s
);

// リセットの論理が逆なので注意
Gowin_SP_fft0 gowin_sp_fft0_instance(dout0, clk, oce0, ce0, ~rst_n, wre0, ad0, din0);
Gowin_SP_fft1 gowin_sp_fft1_instance(dout1, clk, oce1, ce1, ~rst_n, wre1, ad1, din1);
Gowin_pROM_w gowin_prom_w_instance(dout_w, clk, oce_w, ce_w, ~rst_n, ad_w);

fft1024 fft1024_instance(
    clk,
    rst_n,
    fft1024_start,
    fft1024_finish,
    dout0,
    fft1024_oce0,
    fft1024_ce0,
    fft1024_wre0,
    fft1024_ad0,
    fft1024_din0,
    dout1,
    // fft1024_oce1,
    // fft1024_ce1,
    // fft1024_wre1,
    // fft1024_ad1,
    // fft1024_din1,
    oce1,
    ce1,
    wre1,
    ad1,
    din1,
    dout_w,
    oce_w,
    ce_w,
    ad_w
);

ofdm ofdm_instance(
    clk,
    rst_n,
    ofdm_start,
    ofdm_finish,
    ofdm_success,
    ofdm_res,
    dout0,
    ofdm_oce0,
    ofdm_ce0,
    ofdm_ad0
);

// Generate clock
initial begin
    clk = 0;
end
always begin
    #(((1 / CLK_FREQ_MHZ) / 2.0) * 1000) clk = ~clk;
end

reg [3:0] state;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        state <= 4'd0;
        fft1024_start <= 1'd0;
        s <= 1'd1;
        ofdm_start <= 1'd0;
    end
    else begin
        case (state)
            4'd0: begin
                state <= 4'd1;
                fft1024_start <= 1'd1;
                s <= 1'd1;
            end
            4'd1: begin
                fft1024_start <= 1'd0;
                if (fft1024_finish == 1'd1) begin
                    state <= 4'd2;
                    s <= 1'd0;
                    // 念の為、ofdm_start <= 1'd1にするのは次のステートで行う
                end
            end
            4'd2: begin
                state <= 4'd3;
                ofdm_start <= 1'd1;
            end
            4'd3: begin
                ofdm_start <= 1'd0;
                if (ofdm_finish == 1'd1) begin
                    if(ofdm_success == 1'd0) begin
                        $display("failed");
                        state <= 4'd15;
                    end
                    else begin
                        $display("%d", ofdm_res[7:0]);
                        $display("%d", ofdm_res[15:8]);
                        $display("%d", ofdm_res[23:16]);
                        $display("%d", ofdm_res[31:24]);
                        $display("%d", ofdm_res[39:32]);
                        $display("%d", ofdm_res[47:40]);
                        $display("%d", ofdm_res[55:48]);
                        $display("%d", ofdm_res[63:56]);
                        $display("%d", ofdm_res[71:64]);
                        $display("%d", ofdm_res[79:72]);
                        $display("%d", ofdm_res[87:80]);
                        $display("%d", ofdm_res[95:88]);
                        state <= 4'd15;
                    end
                end
            end
            default: begin
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
    #(1 / 27.0 * 1000 * 600 * 27) $finish;
end
endmodule