// TODO: SRAMの中身(FFTの結果)をprintする機能をつける
//       その機能がないと、OFDMの特性の評価ができない
//       よくを言うとADCの結果もprintする機能がほしい

module demodulation_tx_res(
    input clk,
    input rst_n,
    // demodulation
    input tx_res_enable,
    output reg tx_res_clear_enable,
    // uart_tx
    output reg uart_tx_start,
    output reg [7:0] uart_tx_data,
    input uart_tx_finish,
    // ofdm
    input [95:0] ofdm_res
);

reg [1:0] state;
reg [3:0] index;

// OFDMが成功したときはUARTを送信
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        tx_res_clear_enable <= 1'd0;
        uart_tx_start <= 1'd0;
        index <= 4'd0;
        // 適当な初期値を設定(この初期値が使われることはない)
        state <= 2'd0;
    end
    else begin
        if (tx_res_enable == 1'd1) begin
            case (state)
                // STOPビットの時間も正確に連続で送信するのは面倒なので、
                // finishがちゃんと立ち上がったのを確認してから次のデータを送信するようにする。
                // なので、STOPビットが1サイクルだけ長い
                2'd0: begin
                    index <= 4'd1;
                    uart_tx_start <= 1'd1;
                    uart_tx_data <= ofdm_res[7:0];
                    state <= 2'd1;
                end
                2'd1: begin
                    if (uart_tx_finish == 1'd1) begin
                        uart_tx_start <= 1'd1;
                        case (index)
                            4'd1: uart_tx_data <= ofdm_res[15:8];
                            4'd2: uart_tx_data <= ofdm_res[23:16];
                            4'd3: uart_tx_data <= ofdm_res[31:24];
                            4'd4: uart_tx_data <= ofdm_res[39:32];
                            4'd5: uart_tx_data <= ofdm_res[47:40];
                            4'd6: uart_tx_data <= ofdm_res[55:48];
                            4'd7: uart_tx_data <= ofdm_res[63:56];
                            4'd8: uart_tx_data <= ofdm_res[71:64];
                            4'd9: uart_tx_data <= ofdm_res[79:72];
                            4'd10: uart_tx_data <= ofdm_res[87:80];
                            4'd11: uart_tx_data <= ofdm_res[95:88];
                        endcase
                        if (index == 4'd11) begin
                            state <= 2'd2;
                        end
                        else begin
                            index <= index + 1'd1;
                        end
                    end
                    else begin
                        uart_tx_start <= 1'd0;
                    end
                end
                2'd2: begin
                    uart_tx_start <= 1'd0;
                    if (uart_tx_finish == 1'd1) begin
                        tx_res_clear_enable <= 1'd1;
                    end
                end
            endcase
        end
        else begin
            // enable == 0のとき
            tx_res_clear_enable <= 1'd0;
            state <= 2'd0;
            index <= 4'd0;
        end
    end
end
endmodule

// TODO: 後で、tmpにも対応させる
module demodulation_read_adc
#(
    // 27MHz
    parameter CLK_FREQ = 27_000_000,
    // 0.9MHz
    parameter MCP3002_CLK_FREQ = 900_000,
    // 51.2kHz
    parameter ADC_SAMPLING_FREQ = 51_200
)(
    input clk,
    input rst_n,
    // demodulation
    input is_tmp_mode,
    output reg ram_control_available,
    input ram_control_clear_available,
    output reg [12:0] signal_detect_index,
    // mcp3002(adc)
    output reg adc_enable,
    input [9:0] adc_data,
    input adc_available,
    output reg adc_clear_available,
    // ofdm
    input ofdm_success,
    // BSRAM ADC
    input [9:0] dout_adc,
    output reg oce_adc,
    output reg ce_adc,
    output reg wre_adc,
    output reg [12:0] ad_adc,
    output reg [9:0] din_adc  
);

localparam N = 1024;

localparam ADC_SAMPLING_CYCLE = CLK_FREQ / ADC_SAMPLING_FREQ;
localparam ADC_CYCLE = CLK_FREQ / MCP3002_CLK_FREQ;
localparam ADC_CYCLE_16 = ADC_CYCLE * 16;
localparam ADC_THRESHOLD = 10'h008;
localparam INTEGRAL_THRESHOLD = 16'h0080;

reg [15:0] cycle;
reg [15:0] integral;
reg [12:0] index;
reg [12:0] cnt;
reg [29:0] tmp_buff;
reg [2:0] tmp_buff_index;

wire [9:0] _adc_abs;
wire [9:0] adc_abs;
// adc_data - 10'h200
assign _adc_abs = adc_data[9] ? adc_data - 10'h200 : 10'h200 - adc_data;
assign adc_abs = (_adc_abs >= ADC_THRESHOLD) ? _adc_abs : 10'h000;

// mod 8192を行う
function [12:0] calc_next_adc_index;
input [12:0] i;
calc_next_adc_index = (i == 13'd8191) ? 13'd0 : i + 13'd1;
endfunction

// ADCを読む
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        ram_control_available <= 1'd0;
        signal_detect_index <= 13'd0;
        adc_enable <= 1'd0;
        adc_clear_available <= 1'd0;
        oce_adc <= 1'd0;
        ce_adc <= 1'd0;
        wre_adc <= 1'd0;
        ad_adc <= 13'd0;
        din_adc <= 10'd0;
        cycle <= 16'd0;
        integral <= 16'd0;
        index <= 13'd0;
        cnt <= 13'd0;
    end
    else begin
        // TODO: oceとceは使うときだけ、出力するようにする(muxがあるので...)
        // 常にoceとceは出力しておく
        oce_adc <= 1'd1;
        ce_adc <= 1'd1;
        if (adc_clear_available == 1'd1) begin
            // adc_clear_available == 1のときは書き込んだ1サイクル後という意味
            adc_clear_available <= 1'd0;
            // 書き込んだ1サイクル後にwre_adc=0にする
            wre_adc <= 1'd0;
        end
        if (cycle != ADC_CYCLE_16 + 3 && ram_control_clear_available == 1'd1) begin
            ram_control_available <= 1'd0;
        end
        case (cycle)
            16'd0: begin
                // 開始
                cycle <= cycle + 1'd1;
                adc_enable <= 1'd1;
            end
            16'd1: begin
                // enableをoff
                cycle <= cycle + 1'd1;
                adc_enable <= 1'd0;
            end
            ADC_CYCLE_16 + 2: begin
                // ADCが完了し、availableに
                cycle <= cycle + 1'd1;
                adc_clear_available <= 1'd1;
                if (is_tmp_mode == 1'd0) begin
                    // TODO: tmpからの復帰の場合の処理も書く
                    // 流れ
                    // 今回取得したデータをtmpの末尾に書き込む
                    // この後のstateでtmpのデータを積分しながら書き込む
                    // TODO: 積分するときは、何シンボル目かというのも数えながらやる
                    // TODO: signal indexもそのときN足す

                    // ADC SRAMにデータを書き込む
                    wre_adc <= 1'd1;
                    ad_adc <= index;
                    din_adc <= adc_data;
                    index <= calc_next_adc_index(index);
                    // 現在のデータが信号が立ち上がってから何個目かを数える
                    if (cnt == 13'd0) begin
                        // 信号の立ち上がりが見つけられていない場合は積分する
                        // 積分した結果から信号の立ち上がりがあるかを確認する
                        if (integral + adc_abs >= INTEGRAL_THRESHOLD) begin
                            signal_detect_index <= index;
                            cnt <= cnt + 1'd1;
                        end
                        else begin
                            integral <= integral + adc_abs;
                        end
                    end
                    else begin
                        cnt <= cnt + 13'd1;
                    end
                end
                else begin
                    // TODO: tmpの実装をする
                    // バッファにデータを一時保存する
                end
            end
            ADC_CYCLE_16 + 3: begin
                cycle <= cycle + 1'd1;
                adc_clear_available <= 1'd0;
                // 書き込んだ1サイクル後にwre_adc=0にする
                wre_adc <= 1'd0;
                if (cnt == N - 1) begin
                    // N個分のデータが溜まっていた場合はavailableに
                    cnt <= 13'd0;
                    integral <= 16'd0;
                    ram_control_available <= 1'd1;
                end
            end
            ADC_SAMPLING_CYCLE - 1: begin
                cycle <= 16'd0;
            end
            default: begin
                cycle <= cycle + 1'd1;
            end
        endcase
    end
end
endmodule

module demodulation_other(
    input clk,
    input rst_n,
    // demodulation
    output reg [1:0] select_fft_ram,
    output reg select_adc_ram,
    output reg tx_res_enable,
    input tx_res_clear_enable,
    output reg is_tmp_mode,
    input ram_control_available,
    output reg ram_control_clear_available,
    input [12:0] signal_detect_index,
    // fft1024
    output reg fft1024_start,
    input fft1024_finish,
    output reg fft1024_clear,
    // ofdm
    output reg ofdm_start,
    input ofdm_finish,
    input ofdm_success,
    output reg ofdm_clear,
    // BSRAM fft0
    input [31:0] dout0,
    output reg oce0,
    output reg ce0,
    output reg wre0,
    output reg [10:0] ad0,
    output reg [31:0] din0,
    // BSRAM fft1
    input [31:0] dout1,
    output reg oce1,
    output reg ce1,
    output reg wre1,
    output reg [10:0] ad1,
    output reg [31:0] din1,
    // BSRAM ADC
    input [9:0] dout_adc,
    output reg oce_adc,
    output reg ce_adc,
    output reg wre_adc,
    output reg [12:0] ad_adc,
    output reg [9:0] din_adc
);

localparam N = 1024;
localparam N2 = N / 2;
localparam SHIFT_CNT = 10;

localparam S_READ_ADC = 8'h00;
localparam S_RAM_CONTROL = 8'h20;
localparam S_FFT = 8'h40;
localparam S_OFDM = 8'h60;
localparam S_TX_RES = 8'h80;

localparam SEL_FFT_RAM_DEMOD = 2'd0;
localparam SEL_FFT_RAM_FFT = 2'd1;
localparam SEL_FFT_RAM_OFDM = 2'd2;

localparam SEL_ADC_RAM_ADC = 1'd0;
localparam SEL_ADC_RAM_DEMOD = 1'd1;

reg [7:0] state;
reg [12:0] i;
reg [12:0] j;
reg [3:0] shift_cnt;
wire [13:0] _reverse_index;
wire [12:0] reverse_index;

// signal_detect_index - shift_cntが負の数になっても対応可能なようにN足しておく
assign _reverse_index = 14'd8192 + signal_detect_index - shift_cnt + {j[0], j[1], j[2], j[3], j[4], j[5], j[6], j[7], j[8], j[9]};
assign reverse_index = _reverse_index[12:0];

function [31:0] calc_adc_din;
input [9:0] adc_data;
reg [9:0] adc_abs;
reg [15:0] adc_abs16;
reg [15:0] signed_adc;
if (adc_data[9]) begin
    adc_abs = adc_data - 10'h200;
    // 6bitシフト(64で割る)
    adc_abs16 = {6'd0, adc_abs};
    signed_adc = adc_abs16;
    calc_adc_din = {signed_adc, 16'd0};
end
else begin
    adc_abs = 10'h200 - adc_data;
    // 6bitシフト(64で割る)
    adc_abs16 = {6'd0, adc_abs};
    signed_adc = ~adc_abs16 + 16'd1;
    calc_adc_din = {signed_adc, 16'd0};
end
endfunction

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        select_fft_ram <= SEL_FFT_RAM_DEMOD;
        select_adc_ram <= SEL_ADC_RAM_ADC;
        tx_res_enable <= 1'd0;
        is_tmp_mode <= 1'd0;
        ram_control_clear_available <= 1'd0;
        fft1024_start <= 1'd0;
        fft1024_clear <= 1'd0;
        ofdm_start <= 1'd0;
        ofdm_clear <= 1'd0;
        oce0 <= 1'd0;
        ce0 <= 1'd0;
        wre0 <= 1'd0;
        ad0 <= 11'd0;
        din0 <= 32'd0;
        oce1 <= 1'd0;
        ce1 <= 1'd0;
        wre1 <= 1'd0;
        ad1 <= 11'd0;
        din1 <= 32'd0;
        oce_adc <= 1'd0;
        ce_adc <= 1'd0;
        wre_adc <= 1'd0;
        ad_adc <= 13'd0;
        din_adc <= 10'd0;

        state <= S_READ_ADC;
        i <= 13'd0;
        j <= 13'd0;
        shift_cnt <= 4'd0;
    end
    else begin
        case (state)
            S_READ_ADC: begin
                if (ram_control_available == 1'd1) begin
                    state <= S_RAM_CONTROL;
                    ram_control_clear_available <= 1'd1;
                    is_tmp_mode <= 1'd1;
                    // TODO: 今はデバッグ中なので、is_tmp_modeはこれ以降1で固定
                    // デバッグが完了したら、他のステートのときは0にするようにする
                end
            end
            S_RAM_CONTROL: begin
                ram_control_clear_available <= 1'd0;
                // 初期化
                // メモリを選択
                select_fft_ram <= SEL_FFT_RAM_DEMOD;
                select_adc_ram <= SEL_ADC_RAM_DEMOD;
                i <= 13'd0;
                j <= 13'd0;
                state <= S_RAM_CONTROL + 8'd1;
            end
            S_RAM_CONTROL + 8'd1: begin
                // データ転送開始
                j <= j + 1'd1;
                oce0 <= 1'd1;
                ce0 <= 1'd1;
                wre0 <= 1'd0;
                oce1 <= 1'd1;
                ce1 <= 1'd1;
                wre1 <= 1'd0;
                oce_adc <= 1'd1;
                ce_adc <= 1'd1;
                wre_adc <= 1'd0;
                ad_adc <= reverse_index;
                state <= S_RAM_CONTROL + 8'd2;
            end
            S_RAM_CONTROL + 8'd2: begin
                j <= j + 1'd1;
                ad_adc <= reverse_index;
                state <= S_RAM_CONTROL + 8'd3;
            end
            S_RAM_CONTROL + 8'd3: begin
                // ADC->FFTにRAMのデータを転送
                ad_adc <= reverse_index;
                if (i == N - 1) begin
                    i <= 13'd0;
                    j <= 13'd0;
                    state <= S_RAM_CONTROL + 8'd4;
                end
                else begin
                    i <= i + 1'd1;
                    j <= j + 1'd1;
                end

                if (i > N2 - 1) begin
                    wre0 <= 1'd0;
                    wre1 <= 1'd1;
                    ad1 <= {2'd0, i[8:0]};
                    din1 <= calc_adc_din(dout_adc);
                end
                else begin
                    wre0 <= 1'd1;
                    wre1 <= 1'd0;
                    ad0 <= {2'd0, i[8:0]};
                    din0 <= calc_adc_din(dout_adc);
                end
            end
            S_RAM_CONTROL + 8'd4: begin
                // RAMが終了するまでの時間つぶし
                wre0 <= 1'd0;
                wre1 <= 1'd0;
                state <= S_RAM_CONTROL + 8'd5;
            end
            S_RAM_CONTROL + 8'd5: begin
                // RAMが終了するまでの時間つぶし
                state <= S_RAM_CONTROL + 8'd6;
            end
            S_RAM_CONTROL + 8'd6: begin
                select_fft_ram <= SEL_FFT_RAM_FFT;
                select_adc_ram <= SEL_ADC_RAM_ADC;
                state <= S_FFT;
            end
            S_FFT: begin
                fft1024_start <= 1'd1;
                state <= S_FFT + 8'd1;
            end
            S_FFT + 8'd1: begin
                fft1024_start <= 1'd0;
                if (fft1024_finish == 1'd1) begin
                    fft1024_clear <= 1'd1;
                    select_fft_ram <= SEL_FFT_RAM_OFDM;
                    state <= S_OFDM;
                end
            end
            S_OFDM: begin
                fft1024_clear <= 1'd0;
                ofdm_start <= 1'd1;
                state <= S_OFDM + 8'd1;
            end
            S_OFDM + 8'd1: begin
                ofdm_start <= 1'd0;
                if (ofdm_finish == 1'd1) begin
                    ofdm_clear <= 1'd1;
                    state <= S_OFDM + 8'd2;
                end
            end
            S_OFDM + 8'd2: begin
                ofdm_clear <= 1'd0;
                select_fft_ram <= SEL_FFT_RAM_DEMOD;
                if (ofdm_success == 1'd1) begin
                    state <= S_TX_RES;
                    tx_res_enable <= 1'd1;
                    shift_cnt <= 4'd0;
                end
                else begin
                    // シフトしてやり直し
                    if (shift_cnt != SHIFT_CNT - 1) begin
                        state <= S_RAM_CONTROL;
                        shift_cnt <= shift_cnt + 4'd1;
                    end
                    else begin
                        state <= S_READ_ADC;
                        shift_cnt <= 4'd0;
                    end
                end
            end
            S_TX_RES: begin
                if (tx_res_clear_enable == 1'd1) begin
                    state <= S_READ_ADC;
                end
            end
        endcase
    end
end
endmodule

module demodulation
#(
    // 27MHz
    parameter CLK_FREQ = 27_000_000,
    // 0.9MHz
    parameter MCP3002_CLK_FREQ = 900_000,
    // 51.2kHz
    parameter ADC_SAMPLING_FREQ = 51_200
)(
    input clk,
    input rst_n,
    output [1:0] select_fft_ram,
    // uart_tx
    output uart_tx_start,
    output [7:0] uart_tx_data,
    input uart_tx_finish,
    // mcp3002(adc)
    output adc_enable,
    input [9:0] adc_data,
    input adc_available,
    output adc_clear_available,
    // fft1024
    output fft1024_start,
    input fft1024_finish,
    output fft1024_clear,
    // ofdm
    output ofdm_start,
    input ofdm_finish,
    input ofdm_success,
    output ofdm_clear,
    input [95:0] ofdm_res,
    // BSRAM fft0
    input [31:0] dout0,
    output oce0,
    output ce0,
    output wre0,
    output [10:0] ad0,
    output [31:0] din0,
    // BSRAM fft1
    input [31:0] dout1,
    output oce1,
    output ce1,
    output wre1,
    output [10:0] ad1,
    output [31:0] din1,
    // BSRAM ADC
    input [9:0] dout_adc,
    output reg oce_adc,
    output reg ce_adc,
    output reg wre_adc,
    output reg [12:0] ad_adc,
    output reg [9:0] din_adc
);

localparam S_READ_ADC = 8'h00;
localparam S_RAM_CONTROL = 8'h20;
localparam S_FFT = 8'h40;
localparam S_OFDM = 8'h60;
localparam S_UART_TX = 8'h80;

wire oce_adc_adc;
wire ce_adc_adc;
wire wre_adc_adc;
wire [12:0] ad_adc_adc;
wire [9:0] din_adc_adc;
wire oce_adc_demod;
wire ce_adc_demod;
wire wre_adc_demod;
wire [12:0] ad_adc_demod;
wire [9:0] din_adc_demod;

wire select_adc_ram;
wire tx_res_enable;
wire tx_res_clear_enable;
wire is_tmp_mode;
wire ram_control_available;
wire ram_control_clear_available;
wire [12:0] signal_detect_index;

demodulation_read_adc
#(
    CLK_FREQ,
    MCP3002_CLK_FREQ,
    ADC_SAMPLING_FREQ
)demodulation_read_adc_instance(
    clk,
    rst_n,
    // demodulation
    is_tmp_mode,
    ram_control_available,
    ram_control_clear_available,
    signal_detect_index,
    // mcp3002(adc)
    adc_enable,
    adc_data,
    adc_available,
    adc_clear_available,
    // ofdm
    ofdm_success,
    // BSRAM ADC
    dout_adc,
    oce_adc_adc,
    ce_adc_adc,
    wre_adc_adc,
    ad_adc_adc,
    din_adc_adc
);

demodulation_other demodulation_other_instance(
    clk,
    rst_n,
    // demodulation
    select_fft_ram,
    select_adc_ram,
    tx_res_enable,
    tx_res_clear_enable,
    is_tmp_mode,
    ram_control_available,
    ram_control_clear_available,
    signal_detect_index,
    // fft1024
    fft1024_start,
    fft1024_finish,
    fft1024_clear,
    // ofdm
    ofdm_start,
    ofdm_finish,
    ofdm_success,
    ofdm_clear,
    // BSRAM fft0
    dout0,
    oce0,
    ce0,
    wre0,
    ad0,
    din0,
    // BSRAM fft1
    dout1,
    oce1,
    ce1,
    wre1,
    ad1,
    din1,
    // BSRAM ADC
    dout_adc,
    oce_adc_demod,
    ce_adc_demod,
    wre_adc_demod,
    ad_adc_demod,
    din_adc_demod
);

demodulation_tx_res demodulation_tx_res_instance(
    clk,
    rst_n,
    // demodulation
    tx_res_enable,
    tx_res_clear_enable,
    // uart_tx
    uart_tx_start,
    uart_tx_data,
    uart_tx_finish,
    // ofdm
    ofdm_res
);

// マルチプレクサ
always @(*) begin
    if (select_adc_ram == 1'd0) begin
        oce_adc = oce_adc_adc;
        ce_adc = ce_adc_adc;
        wre_adc = wre_adc_adc;
        ad_adc = ad_adc_adc;
        din_adc = din_adc_adc;
    end
    else begin
        oce_adc = oce_adc_demod;
        ce_adc = ce_adc_demod;
        wre_adc = wre_adc_demod;
        ad_adc = ad_adc_demod;
        din_adc = din_adc_demod;
    end
end
endmodule
