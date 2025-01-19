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

reg [2:0] state;
reg [3:0] index;

// OFDMが成功したときはUARTを送信
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        tx_res_clear_enable <= 1'd0;
        uart_tx_start <= 1'd0;
        uart_tx_data <= 8'd0;
        index <= 4'd0;
        // 適当な初期値を設定(この初期値が使われることはない)
        state <= 3'd0;
    end
    else begin
        if (tx_res_enable == 1'd1) begin
            case (state)
                // STOPビットの時間も正確に連続で送信するのは面倒なので、
                // finishがちゃんと立ち上がったのを確認してから次のデータを送信するようにする。
                // なので、STOPビットが1サイクルだけ長い
                3'd0: begin
                    index <= 4'd1;
                    uart_tx_start <= 1'd1;
                    uart_tx_data <= ofdm_res[7:0];
                    state <= 3'd1;
                    `ifdef DEMOD_SIMULATION
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
                    `endif
                end
                3'd1: begin
                    state <= 3'd2;
                end
                3'd2: begin
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
                            state <= 3'd4;
                        end
                        else begin
                            state <= 3'd3;
                            index <= index + 1'd1;
                        end
                    end
                    else begin
                        uart_tx_start <= 1'd0;
                    end
                end
                3'd3: begin
                    state <= 3'd2;
                end
                3'd4: begin
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
            state <= 3'd0;
            index <= 4'd0;
        end
    end
end
endmodule

// スペクトル表示する用のmodule
// 復調器には関係ないが、復調器の性能を評価するのに使用
module demodulation_tx_spectrum
(
    input clk,
    input rst_n,
    // demod
    input tx_spe_enable,
    // uart_tx
    output reg uart_tx_start,
    output reg [7:0] uart_tx_data,
    input uart_tx_finish,
    // BSRAM fft0
    input [31:0] dout0,
    output reg oce0,
    output reg ce0,
    output reg wre0,
    output reg [10:0] ad0,
    output reg [31:0] din0
);

localparam N = 1024;
localparam N2 = N / 2;

reg [10:0] i;
reg [7:0] state;
reg [15:0] tmp;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        i <= 11'd0;
        state <= 8'd0;
        uart_tx_start <= 1'd0;
        uart_tx_data <= 8'd0;
        oce0 <= 1'd0;
        ce0 <= 1'd0;
        wre0 <= 1'd0;
        ad0 <= 11'd0;
        din0 <= 32'd0;
    end
    else begin
        if (tx_spe_enable == 1'd1) begin
            case (state)
                8'd0: begin
                    oce0 <= 1'd1;
                    ce0 <= 1'd1;
                    wre0 <= 1'd0;
                    ad0 <= i;
                    din0 <= 32'd0;
                    state <= state + 1'd1;
                end
                8'd1: begin
                    state <= state + 1'd1;
                end
                8'd2: begin
                    tmp <= dout0[31:16];
                    oce0 <= 1'd0;
                    ce0 <= 1'd0;
                    state <= state + 1'd1;
                end
                8'd3: begin
                    uart_tx_start <= 1'd1;
                    uart_tx_data <= tmp[7:0];
                    state <= state + 1'd1;
                end
                8'd4: begin
                    uart_tx_start <= 1'd0;
                    state <= state + 1'd1;
                end
                8'd5: begin
                    if (uart_tx_finish == 1'd1) begin
                        uart_tx_start <= 1'd1;
                        uart_tx_data <= tmp[15:8];
                        state <= state + 1'd1;
                    end
                end
                8'd6: begin
                    uart_tx_start <= 1'd0;
                    state <= state + 1'd1;
                end
                8'd7: begin
                    if (uart_tx_finish == 1'd1) begin
                        if (i == N2 - 1)  begin
                            state <= 8'd255;
                        end
                        else begin
                            i <= i + 1'd1;
                            state <= 8'd0;
                        end
                    end
                end
            endcase
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
localparam ADC_THRESHOLD = 10'h040;
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
        tmp_buff <= 30'd0;
        tmp_buff_index <= 3'd0;
    end
    else begin
        if (adc_clear_available == 1'd1) begin
            // adc_clear_available == 1のときは書き込んだ1サイクル後という意味
            adc_clear_available <= 1'd0;
            // 書き込んだ1サイクル後にwre_adc=0にする
            wre_adc <= 1'd0;
        end
        // TODO: デバッグのためにコメントアウト
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
                    oce_adc <= 1'd1;
                    ce_adc <= 1'd1;
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
                // 書き込んだ1サイクル後にSRAMをOFFにする
                oce_adc <= 1'd0;
                ce_adc <= 1'd0;
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
    output reg select_uart_tx,
    output reg tx_res_enable,
    input tx_res_clear_enable,
    output reg is_tmp_mode,
    input ram_control_available,
    output reg ram_control_clear_available,
    input [12:0] signal_detect_index,
    output reg tx_spe_enable,
    input uart_mode,
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
localparam S_TX_SPE = 8'ha0;

localparam SEL_FFT_RAM_DEMOD = 2'd0;
localparam SEL_FFT_RAM_FFT = 2'd1;
localparam SEL_FFT_RAM_OFDM = 2'd2;
localparam SEL_FFT_RAM_TX_SPE = 2'd3;

localparam SEL_ADC_RAM_ADC = 1'd0;
localparam SEL_ADC_RAM_DEMOD = 1'd1;

localparam SEL_UART_TX_RES = 1'd0;
localparam SEL_UART_TX_SPE = 1'd1;

localparam UART_MODE_RES = 1'd0;
localparam UART_MODE_SPE= 1'd1;

reg [7:0] state;
reg [12:0] i;
reg [12:0] j;
reg [7:0] shift_cnt;
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
        select_uart_tx <= SEL_UART_TX_RES;
        tx_res_enable <= 1'd0;
        is_tmp_mode <= 1'd0;
        ram_control_clear_available <= 1'd0;
        tx_spe_enable <= 1'd0;
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
        shift_cnt <= 8'd0;
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
                if (ofdm_success == 1'd1) begin
                    if (uart_mode == UART_MODE_SPE) begin
                        select_fft_ram <= SEL_FFT_RAM_TX_SPE;
                        select_uart_tx <= SEL_UART_TX_SPE;
                        state <= S_TX_SPE;
                        tx_spe_enable <= 1'd1;
                    end
                    else begin
                        // uart_mode == UART_MODE_RES
                        select_fft_ram <= SEL_FFT_RAM_DEMOD;
                        select_uart_tx <= SEL_UART_TX_RES;
                        state <= S_TX_RES;
                        tx_res_enable <= 1'd1;
                        shift_cnt <= 8'd0;
                    end
                end
                else begin
                    select_fft_ram <= SEL_FFT_RAM_DEMOD;

                    // シフトしてやり直し
                    if (shift_cnt != SHIFT_CNT - 1) begin
                        state <= S_RAM_CONTROL;
                        shift_cnt <= shift_cnt + 1'd1;
                    end
                    else begin
                        state <= S_READ_ADC;
                        // デバッグのために失敗したときも出力するようにする
                        // state <= S_TX_RES;
                        // tx_res_enable <= 1'd1;
                        // shift_cnt <= 8'd0;
                    end
                end
            end
            S_TX_RES: begin
                if (tx_res_clear_enable == 1'd1) begin
                    state <= S_READ_ADC;
                end
            end
            S_TX_SPE: begin
                // このステートに入ったら抜ける必要はないので、何もしない
            end
        endcase
    end
end
endmodule