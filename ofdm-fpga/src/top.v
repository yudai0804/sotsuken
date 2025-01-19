module generate_rst_n_pll
#(
    parameter CLK_FREQ = 24_000_000
)(
    input clk_pll,
    input rst_n,
    output reg rst_n_pll
);

localparam CYCLE = CLK_FREQ / 1000;
reg [31:0] pll_cnt;

// 電源起動直後はPLLが不安定なので、最初の1msは待機のために、rst_n_pllを0にする

always @(posedge clk_pll or negedge rst_n) begin
    if (!rst_n) begin
        pll_cnt<= 32'd0;
    end
    else begin
        if (pll_cnt != CYCLE) begin
            pll_cnt <= pll_cnt + 1'd1;
        end
    end
end

always @(*) begin
    if (rst_n == 1'd1) begin
        rst_n_pll = (pll_cnt == CYCLE) ? 1'd1 : 1'd0;
    end
    else begin
        rst_n_pll = rst_n;
    end
end

endmodule

module mux_sp_fft(
    input oce_demod,
    input oce_fft,
    input oce_ofdm,
    input oce_tx_spe,
    output reg oce_o,
    input ce_demod,
    input ce_fft,
    input ce_ofdm,
    input ce_tx_spe,
    output reg ce_o,
    input wre_demod,
    input wre_fft,
    input wre_ofdm,
    input wre_tx_spe,
    output reg wre_o,
    input [10:0] ad_demod,
    input [10:0] ad_fft,
    input [10:0] ad_ofdm,
    input [10:0] ad_tx_spe,
    output reg [10:0] ad_o,
    input [31:0] din_demod,
    input [31:0] din_fft,
    input [31:0] din_ofdm,
    input [31:0] din_tx_spe,
    output reg [31:0] din_o,
    input [1:0] select
);
always @(*) begin
    case (select)
        2'd0: begin
            oce_o = oce_demod;
            ce_o = ce_demod;
            wre_o = wre_demod;
            ad_o = ad_demod;
            din_o = din_demod;
        end
        2'd1: begin
            oce_o = oce_fft;
            ce_o = ce_fft;
            wre_o = wre_fft;
            ad_o = ad_fft;
            din_o = din_fft;
        end
        2'd2: begin
            oce_o = oce_ofdm;
            ce_o = ce_ofdm;
            wre_o = wre_ofdm;
            ad_o = ad_ofdm;
            din_o = din_ofdm;
        end
        default: begin
            oce_o = oce_tx_spe;
            ce_o = ce_tx_spe;
            wre_o = wre_tx_spe;
            ad_o = ad_tx_spe;
            din_o = din_tx_spe;
        end
    endcase
end  
endmodule

module mux_sp_adc
(
    input oce_adc_adc,
    input oce_adc_other,
    output reg oce_adc,
    input ce_adc_adc,
    input ce_adc_other,
    output reg ce_adc,
    input wre_adc_adc,
    input wre_adc_other,
    output reg wre_adc,
    input [12:0] ad_adc_adc,
    input [12:0] ad_adc_other,
    output reg [12:0] ad_adc,
    input [9:0] din_adc_adc,
    input [9:0] din_adc_other,
    output reg [9:0] din_adc,
    input select_adc_ram
);

always @(*) begin
    if (select_adc_ram == 1'd0) begin
        oce_adc = oce_adc_adc;
        ce_adc = ce_adc_adc;
        wre_adc = wre_adc_adc;
        ad_adc = ad_adc_adc;
        din_adc = din_adc_adc;
    end
    else begin
        oce_adc = oce_adc_other;
        ce_adc = ce_adc_other;
        wre_adc = wre_adc_other;
        ad_adc = ad_adc_other;
        din_adc = din_adc_other;
    end
end
endmodule

module mux_uart_tx
(
    input start_res,
    input start_spe,
    output reg o_start,
    input [7:0] data_res,
    input [7:0] data_spe,
    output reg [7:0] o_data,
    input select_uart_tx
);

always @(*) begin
    if (select_uart_tx == 1'd0) begin
        o_start = start_res;
        o_data = data_res;
    end
    else begin
        o_start = start_spe;
        o_data = data_spe;
    end
end
endmodule

module top
#(
    parameter CLK_FREQ = 24_000_000,
    parameter UART_BOUD_RATE = 9600,
    parameter MCP3002_CLK_FREQ = 800_000,
    parameter ADC_SAMPLING_FREQ = 48_000
)(
    input clk,
    input rst_n,
    input rx_pin,
    output tx_pin,
    output [5:0] led,
    output adc_clk,
    output adc_din,
    input adc_dout,
    output adc_cs,
    // 出力を外部の回路に接続するなどはしないが、FPGAのsdcを設定するのに必要なので宣言
    output clk_pll,
    output rst_n_pll
);

// `timescale 1ns / 1ps
// module testbench;
// localparam CLK_FREQ = 24_000_000;
// localparam MCP3002_CLK_FREQ = 800_000;
// localparam UART_BOUD_RATE = 9600;
// localparam ADC_SAMPLING_FREQ = 48_000;
// reg clk;
// reg rst_n;
// reg rx_pin;
// wire tx_pin;
// wire [5:0] led;
// wire adc_clk;
// wire adc_din;
// reg adc_dout;
// wire adc_cs;
// wire clk_pll;
// wire rst_n_pll;

localparam UART_CYCLE = CLK_FREQ / UART_BOUD_RATE;
localparam UART_CYCLE_10 = UART_CYCLE * 10;
localparam MCP3002_CYCLE = CLK_FREQ / MCP3002_CLK_FREQ;

// ==========uart_tx==========
wire uart_tx_start;
wire [7:0] uart_tx_data;
wire uart_tx_finish;

// ==========mcp3002(adc)==========
wire adc_enable;
wire [9:0] adc_data;
wire adc_available;
wire adc_clear_available;

// ==========sp(prom)==========
// BSRAM fft0
wire [31:0] sp_fft0_dout;
wire sp_fft0_oce;
wire sp_fft0_ce;
wire sp_fft0_wre;
wire [10:0] sp_fft0_ad;
wire [31:0] sp_fft0_din;
// BSRAM fft1
wire [31:0] sp_fft1_dout;
wire sp_fft1_oce;
wire sp_fft1_ce;
wire sp_fft1_wre;
wire [10:0] sp_fft1_ad;
wire [31:0] sp_fft1_din;
// BSRAM(prom) w
wire [15:0] prom_w_dout;
wire prom_w_oce;
wire prom_w_ce;
wire [10:0] prom_w_ad;
// BSRAM adc
wire [9:0] sp_adc_dout;
wire sp_adc_oce;
wire sp_adc_ce;
wire sp_adc_wre;
wire [12:0] sp_adc_ad;
wire [9:0] sp_adc_din;

// ==========fft1024==========
wire fft1024_start;
wire fft1024_finish;
wire fft1024_clear;
wire fft1024_oce0;
wire fft1024_ce0;
wire fft1024_wre0;
wire [10:0] fft1024_ad0;
wire [31:0] fft1024_din0;
// BSRAM fft1
wire fft1024_oce1;
wire fft1024_ce1;
wire fft1024_wre1;
wire [10:0] fft1024_ad1;
wire [31:0] fft1024_din1;

// ==========ofdm==========
wire ofdm_start;
wire ofdm_finish;
wire ofdm_success;
wire ofdm_clear;
wire [95:0] ofdm_res;
wire ofdm_oce0;
wire ofdm_ce0;
// wre0はread onlyなので使わない
wire [10:0] ofdm_ad0;
// din0はread onlyなので使わない

// ==========demodulation==========
wire [1:0] select_fft_ram;

wire demod_oce0;
wire demod_ce0;
wire demod_wre0;
wire [10:0] demod_ad0;
wire [31:0] demod_din0;

wire demod_oce1;
wire demod_ce1;
wire demod_wre1;
wire [10:0] demod_ad1;
wire [31:0] demod_din1;

wire demod_oce0_tx_spe;
wire demod_ce0_tx_spe;
wire demod_wre0_tx_spe;
wire [10:0] demod_ad0_tx_spe;
wire [31:0] demod_din0_tx_spe;

wire select_adc_ram;

wire demod_oce_adc_adc;
wire demod_ce_adc_adc;
wire demod_wre_adc_adc;
wire [12:0] demod_ad_adc_adc;
wire [9:0] demod_din_adc_adc;

wire demod_oce_adc_other;
wire demod_ce_adc_other;
wire demod_wre_adc_other;
wire [12:0] demod_ad_adc_other;
wire [9:0] demod_din_adc_other;

wire select_uart_tx;

wire uart_tx_start_res;
wire [7:0] uart_tx_data_res;

wire uart_tx_start_spe;
wire [7:0] uart_tx_data_spe;

wire tx_res_enable;
wire tx_res_clear_enable;
wire is_tmp_mode;
wire ram_control_available;
wire ram_control_clear_available;
wire [12:0] signal_detect_index;
wire tx_spe_enable;

// その他
reg [5:0] led_reg;
assign led = ~led_reg;
reg [7:0] state;
reg [15:0] cycle;

wire [9:0] _adc_abs;
wire [9:0] adc_abs;
// adc_data - 10'h200
assign adc_abs = adc_data[9] ? adc_data - 10'h200 : 10'h200 - adc_data;

always @(*) begin
    // led_reg = (ram_control_available == 1'd0) ? adc_abs[8:3] : 6'd0;
    led_reg = adc_abs[8:3];
    // led_reg = adc_abs[5:0];
end

Gowin_rPLL gowin_rpll_instance
(
    clk_pll,
    clk
);

generate_rst_n_pll#
(
    CLK_FREQ
)generate_rst_n_pll_instance(
    clk_pll,
    rst_n,
    rst_n_pll
);

uart_tx#
(
    CLK_FREQ,
    UART_BOUD_RATE
)uart_tx_instance(
    clk_pll,
    rst_n_pll,
    uart_tx_start,
    uart_tx_data,
    tx_pin,
    uart_tx_finish
);

mcp3002#
(
    CLK_FREQ,
    MCP3002_CLK_FREQ
)mcp3002_instance(
    clk_pll,
    rst_n_pll,
    adc_clk,
    adc_din,
    adc_dout,
    adc_cs,
    adc_enable,
    adc_data,
    adc_available,
    adc_clear_available
);

Gowin_SP_fft0 gowin_sp_fft0_instance
(
    sp_fft0_dout,
    clk_pll,
    sp_fft0_oce,
    sp_fft0_ce,
    ~rst_n_pll,
    sp_fft0_wre,
    sp_fft0_ad,
    sp_fft0_din
);

Gowin_SP_fft1 gowin_sp_fft1_instance
(
    sp_fft1_dout,
    clk_pll,
    sp_fft1_oce,
    sp_fft1_ce,
    ~rst_n_pll,
    sp_fft1_wre,
    sp_fft1_ad,
    sp_fft1_din
);

Gowin_pROM_w gowin_prom_w_instance
(
    prom_w_dout,
    clk_pll,
    prom_w_oce,
    prom_w_ce,
    ~rst_n_pll,
    prom_w_ad
);

Gowin_SP_adc gowin_sp_adc_instance
(
    sp_adc_dout,
    clk_pll,
    sp_adc_oce,
    sp_adc_ce,
    ~rst_n_pll,
    sp_adc_wre,
    sp_adc_ad,
    sp_adc_din
);

fft1024 fft1024_instance
(
    clk_pll,
    rst_n_pll,
    fft1024_start,
    fft1024_finish,
    fft1024_clear,
    sp_fft0_dout,
    fft1024_oce0,
    fft1024_ce0,
    fft1024_wre0,
    fft1024_ad0,
    fft1024_din0,
    sp_fft1_dout,
    fft1024_oce1,
    fft1024_ce1,
    fft1024_wre1,
    fft1024_ad1,
    fft1024_din1,
    prom_w_dout,
    prom_w_oce,
    prom_w_ce,
    prom_w_ad
);

ofdm ofdm_instance
(
    clk_pll,
    rst_n_pll,
    ofdm_start,
    ofdm_finish,
    ofdm_success,
    ofdm_clear,
    ofdm_res,
    sp_fft0_dout,
    ofdm_oce0,
    ofdm_ce0,
    ofdm_ad0
);

demodulation_tx_res demodulation_tx_res_instance
(
    clk_pll,
    rst_n_pll,
    tx_res_enable,
    tx_res_clear_enable,
    uart_tx_start_res,
    uart_tx_data_res,
    uart_tx_finish,
    ofdm_res
);

demodulation_tx_spectrum demodulation_tx_spectrum_instance
(
    clk_pll,
    rst_n_pll,
    tx_spe_enable,
    uart_tx_start_spe,
    uart_tx_data_spe,
    uart_tx_finish,
    sp_fft0_dout,
    demod_oce0_tx_spe,
    demod_ce0_tx_spe,
    demod_wre0_tx_spe,
    demod_ad0_tx_spe,
    demod_din0_tx_spe
);

demodulation_read_adc#
(
    CLK_FREQ,
    MCP3002_CLK_FREQ,
    ADC_SAMPLING_FREQ
)demodulation_read_adc_instance(
    clk_pll,
    rst_n_pll,
    is_tmp_mode,
    ram_control_available,
    ram_control_clear_available,
    signal_detect_index,
    adc_enable,
    adc_data,
    adc_available,
    adc_clear_available,
    ofdm_success,
    sp_adc_dout,
    demod_oce_adc_adc,
    demod_ce_adc_adc,
    demod_wre_adc_adc,
    demod_ad_adc_adc,
    demod_din_adc_adc
);

demodulation_other demodulation_other_instance
(
    clk_pll,
    rst_n_pll,
    select_fft_ram,
    select_adc_ram,
    select_uart_tx,
    tx_res_enable,
    tx_res_clear_enable,
    is_tmp_mode,
    ram_control_available,
    ram_control_clear_available,
    signal_detect_index,
    tx_spe_enable,
    fft1024_start,
    fft1024_finish,
    fft1024_clear,
    ofdm_start,
    ofdm_finish,
    ofdm_success,
    ofdm_clear,
    sp_fft0_dout,
    demod_oce0,
    demod_ce0,
    demod_wre0,
    demod_ad0,
    demod_din0,
    sp_fft1_dout,
    demod_oce1,
    demod_ce1,
    demod_wre1,
    demod_ad1,
    demod_din1,
    sp_adc_dout,
    demod_oce_adc_other,
    demod_ce_adc_other,
    demod_wre_adc_other,
    demod_ad_adc_other,
    demod_din_adc_other
);

mux_sp_fft mux_sp_fft_instance0
(
    demod_oce0,
    fft1024_oce0,
    ofdm_oce0,
    demod_oce0_tx_spe,
    sp_fft0_oce,
    demod_ce0,
    fft1024_ce0,
    ofdm_ce0,
    demod_ce0_tx_spe,
    sp_fft0_ce,
    demod_wre0,
    fft1024_wre0,
    1'd0,
    demod_wre0_tx_spe,
    sp_fft0_wre,
    demod_ad0,
    fft1024_ad0,
    ofdm_ad0,
    demod_ad0_tx_spe,
    sp_fft0_ad,
    demod_din0,
    fft1024_din0,
    32'd0,
    demod_din0_tx_spe,
    sp_fft0_din,
    select_fft_ram
);

mux_sp_fft mux_sp_fft_instance1
(
    demod_oce1,
    fft1024_oce1,
    1'd0,
    1'd0,
    sp_fft1_oce,
    demod_ce1,
    fft1024_ce1,
    1'd0,
    1'd0,
    sp_fft1_ce,
    demod_wre1,
    fft1024_wre1,
    1'd0,
    1'd0,
    sp_fft1_wre,
    demod_ad1,
    fft1024_ad1,
    11'd0,
    11'd0,
    sp_fft1_ad,
    demod_din1,
    fft1024_din1,
    32'd0,
    32'd0,
    sp_fft1_din,
    select_fft_ram
);

mux_sp_adc mux_sp_adc_instance
(
    demod_oce_adc_adc,
    demod_oce_adc_other,
    sp_adc_oce,
    demod_ce_adc_adc,
    demod_ce_adc_other,
    sp_adc_ce,
    demod_wre_adc_adc,
    demod_wre_adc_other,
    sp_adc_wre,
    demod_ad_adc_adc,
    demod_ad_adc_other,
    sp_adc_ad,
    demod_din_adc_adc,
    demod_din_adc_other,
    sp_adc_din,
    select_adc_ram
);

mux_uart_tx mux_uart_tx_instance
(
    uart_tx_start_res,
    uart_tx_start_spe,
    uart_tx_start,
    uart_tx_data_res,
    uart_tx_data_spe,
    uart_tx_data,
    select_uart_tx
);

// mcp3002を使う
// always @(posedge clk or negedge rst_n) begin
//     if (!rst_n) begin
//         adc_enable <= 1'd0;
//         adc_clear_available <= 1'd0;
//         state <= 8'd0;
//         led_reg <= 6'd0;
//     end
//     else begin
//         case (state)
//             8'd0: begin
//                 adc_enable <= 1'd1;
//                 led_reg <= adc_data[9:4];
//             end
//         endcase
//     end
// end

// オウム返しをする
// always @(posedge clk or negedge rst_n) begin
//     if(!rst_n) begin
//         uart_tx_start <= 1'd0;
//         uart_tx_data <= 8'd0;

//         uart_rx_clear_available <= 1'd0;

//         state <= 8'd0;
//         cycle <= 16'd0;
//     end
//     else begin
//         case (state)
//             8'd0: begin
//                 if (uart_rx_available == 1'd1) begin
//                     uart_rx_clear_available <= 1'd1;
//                     uart_tx_data <= uart_rx_data;
//                     uart_tx_start <= 1'd1;
//                     state <= 8'd1;
//                 end
//             end
//             8'd1: begin
//                 uart_tx_start <= 1'd0;
//                 state <= 8'd0;
//             end
//         endcase
//     end
// end

// Helloを出力
// always @(posedge clk or negedge rst_n) begin
//     if (!rst_n) begin
//         uart_tx_start <= 1'd0;
//         uart_tx_data <= 8'd0;
//         state <= 8'd0;
//         cycle <= 16'd0;
//     end
//     else begin
//         uart_tx_start <= 1'd1;
//         if (cycle == UART_CYCLE_10 - 1) begin
//             cycle <= 16'd0;
//             state <= (state != 8'd6) ? state + 1'd1 : 8'd0;
//         end
//         else begin
//             cycle <= cycle + 1'd1;
//         end
//         case (state)
//             8'd0: tx_data <= "H";
//             8'd1: tx_data <= "e";
//             8'd2: tx_data <= "l";
//             8'd3: tx_data <= "l";
//             8'd4: tx_data <= "o";
//             8'd5: tx_data <= 8'h0d;
//             8'd6: tx_data <= "\n";
//         endcase
//     end
// end

// Generate clock
// initial begin
//     clk = 0;
// end
// always begin
//     #(((1 / 27.0) / 2.0) * 1000) clk = ~clk;
// end

// // main
// initial begin
//     // シミュレーションの開始
//     $dumpfile("testbench.vcd"); // 波形出力ファイル
//     $dumpvars(0, testbench);

//     // 初期化
//     #0 rst_n = 0;
//     #0 rst_n = 1;
//     // 適当な時刻で終了
//     #(1 / 27.0 * 1000 * 3000 * 27) $finish;
//     // #(1 / 27.0 * 1000 * 600 * 27) $finish;
// end

endmodule