module fft1024_twindle_factor_index
(
    input [9:0] i,
    output [23:0] res
);

// localparam N4 = N / 4;
// localparam N4_2 = N4 * 2;
// localparam N4_3 = N4 * 3;
localparam N = 11'd1024;
localparam N4 = 11'd256;
localparam N4_2 = 11'd512;
localparam N4_3 = 11'd768;

function [23:0] calc;
    // calc = {w_re_sign, i_re, w_im_sign, i_im};
    // fft1024ではN=4096の回転因子を使用するため4倍する
    input [9:0] i;
    reg [10:0] _ad_re;
    reg [10:0] _ad_im;
    reg [10:0] ad_re;
    reg [10:0] ad_im;
    reg sign_re;
    reg sign_im;

    if (0 <= i && i <= N4) begin
        // 第4象限
        _ad_re = N4 - i;
        _ad_im = i;
        ad_re = _ad_re << 2;
        ad_im = _ad_im << 2;
        sign_re = 1'd0;
        sign_im = 1'd1;
        calc = {sign_re, ad_re, sign_im, ad_im};
    end
    else if(N4 < i && i <= N4_2) begin
        // 第3象限
        _ad_re = i - N4;
        _ad_im = N4_2 - i;
        ad_re = _ad_re << 2;
        ad_im = _ad_im << 2;
        sign_re = 1'd1;
        sign_im = 1'd1;
        calc = {sign_re, ad_re, sign_im, ad_im};
    end
    else if(N4_2 < i && i <= N4_3) begin
        // 第2象限
        _ad_re = N4_3 - i;
        _ad_im = i - N4_2;
        ad_re = _ad_re << 2;
        ad_im = _ad_im << 2;
        sign_re = 1'd1;
        sign_im = 1'd0;
        calc = {sign_re, ad_re, sign_im, ad_im};
    end
    else begin
        // 第1象限
        _ad_re = i - N4_3;
        _ad_im = i & (N4 - i);
        ad_re = _ad_re << 2;
        ad_im = _ad_im << 2;
        sign_re = 1'd0;
        sign_im = 1'd0;
        calc = {sign_re, ad_re, sign_im, ad_im};
    end
endfunction

assign res = calc(i);

endmodule

module fft1024
(
    input clk,
    input rst_n,
    input start,
    output reg finish,
    input clear,
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
    // BSRAM(prom) w
    input [15:0] dout_w,
    output reg oce_w,
    output reg ce_w,
    output reg [10:0] ad_w
);

localparam N = 1024;
localparam N2 = N / 2;
localparam N4 = N / 4;
localparam N4_2 = N4 * 2;
localparam N4_3 = N4 * 3;

reg [15:0] w_re;

// xの一次保管用。
// NOTE: 同じ変数を再利用しまくってるので、可読性ゴミなので注意
reg [15:0] x0_re;
reg [15:0] x0_im;
reg [15:0] x1_re;
reg [15:0] x1_im;

reg [9:0] step;
reg [9:0] half_step;
reg [9:0] index;
reg [9:0] i;
reg [9:0] j;
reg [9:0] k;
reg [10:0] prom_i_im;
reg w_re_sign;
reg w_im_sign;
// x0とx2、x1とx3のインデックスは今回のSRAMの構成では同じ(N/2ずれているため)
reg [9:0] x_index;
reg [9:0] x_half_step_index;

localparam S_IDLE = 2'd0;
localparam S_BUTTERFLY2 = 2'd1;
localparam S_BUTTERFLY1 = 2'd2;
// S_FINISHがある理由はメモリの書き込みが終わるのを待つため。
localparam S_FINISH = 2'd3;

reg [1:0] state;
reg [1:0] next_state;
reg [2:0] clk_cnt;

wire [63:0] butterfly0_res;
wire [63:0] butterfly1_res;
wire [31:0] butterfly_dout0;

wire [23:0] fft_twindle_factor_index_res;

assign butterfly_dout0 = (state == S_BUTTERFLY1) ? dout1 : dout0;

fft1024_twindle_factor_index fft_twindle_factor_index_instance
(
    i,
    fft_twindle_factor_index_res
);


butterfly butterfly0
(
    x0_re,
    x0_im,
    // state == S_BUTTERFLY2のときはdout0
    // state == S_BUTTERFLY1のときはdout1
    // に接続する
    butterfly_dout0[31:16],
    butterfly_dout0[15:0],
    w_re,
    w_re_sign,
    dout_w,
    w_im_sign,
    butterfly0_res[63:48],
    butterfly0_res[47:32],
    butterfly0_res[31:16],
    butterfly0_res[15:0]
);

butterfly butterfly1
(
    x1_re,
    x1_im,
    dout1[31:16],
    dout1[15:0],
    w_re,
    w_re_sign,
    dout_w,
    w_im_sign,
    butterfly1_res[63:48],
    butterfly1_res[47:32],
    butterfly1_res[31:16],
    butterfly1_res[15:0]
);

// debug
`ifdef SIMULATOR
reg [15:0] debug_read_x0_re;
reg [15:0] debug_read_x0_im;
reg [15:0] debug_read_x1_re;
reg [15:0] debug_read_x1_im;
reg [15:0] debug_read_x2_re;
reg [15:0] debug_read_x2_im;
reg [15:0] debug_read_x3_re;
reg [15:0] debug_read_x3_im;
reg [15:0] debug_res_x0_re;
reg [15:0] debug_res_x0_im;
reg [15:0] debug_res_x1_re;
reg [15:0] debug_res_x1_im;
reg [15:0] debug_res_x2_re;
reg [15:0] debug_res_x2_im;
reg [15:0] debug_res_x3_re;
reg [15:0] debug_res_x3_im;
reg [15:0] debug_w_re;
reg [15:0] debug_w_im;
`endif

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        finish <= 1'd0;
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
        oce_w <= 1'd0;
        ce_w <= 1'd0;
        ad_w <= 11'd0;

        w_re <= 16'd0;
        x0_re <= 16'd0;
        x0_im <= 16'd0;
        x1_re <= 16'd0;
        x1_im <= 16'd0;
        step <= 10'd0;
        half_step <= 10'd0;
        index <= 10'd0;
        i <= 10'd0;
        j <= 10'd0;
        k <= 10'd0;
        prom_i_im <= 11'd0;
        w_re_sign <= 1'd0;
        w_im_sign <= 1'd0;
        x_index <= 10'd0;
        x_half_step_index <= 10'd0;
        state <= S_IDLE;
        next_state <= S_IDLE;
        clk_cnt <= 3'd0;
        `ifdef SIMULATOR
        debug_read_x0_re <= 16'd0;
        debug_read_x0_im <= 16'd0;
        debug_read_x1_re <= 16'd0;
        debug_read_x1_im <= 16'd0;
        debug_read_x2_re <= 16'd0;
        debug_read_x2_im <= 16'd0;
        debug_read_x3_re <= 16'd0;
        debug_read_x3_im <= 16'd0;
        debug_res_x0_re <= 16'd0;
        debug_res_x0_im <= 16'd0;
        debug_res_x1_re <= 16'd0;
        debug_res_x1_im <= 16'd0;
        debug_res_x2_re <= 16'd0;
        debug_res_x2_im <= 16'd0;
        debug_res_x3_re <= 16'd0;
        debug_res_x3_im <= 16'd0;
        debug_w_re <= 16'd0;
        debug_w_im <= 16'd0;
        `endif
    end
    else begin
        if (clear == 1'd1 && state != S_FINISH) begin
            finish <= 1'd0;
        end
        case (state)
            S_IDLE: begin
                if (start == 1'd1) begin
                    ce_w <= 1'd1;
                    oce_w <= 1'd1;
                    // 他のSRAMもいつでも使用可能にしておく
                    ce0 <= 1'd1;
                    oce0 <= 1'd1;
                    wre0 <= 1'd0;
                    ad0 <= 11'd0;
                    ce1 <= 1'd1;
                    oce1 <= 1'd1;
                    wre1 <= 1'd0;
                    ad1 <= 11'd0;

                    half_step <= 10'd1;
                    step <= 10'd2;
                    index <= N2;
                    i <= 10'd0;
                    j <= 10'd0;
                    k <= 10'd0;
                    state <= S_BUTTERFLY2;
                    next_state <= S_BUTTERFLY2;
                    clk_cnt <= 3'd0;

                    w_re_sign <= fft_twindle_factor_index_res[23];
                    ad_w <= fft_twindle_factor_index_res[22:12];
                    w_im_sign <= fft_twindle_factor_index_res[11];
                    prom_i_im <= fft_twindle_factor_index_res[10:0];
                end
            end
            // step <= N / 2のときは2つのバタフライ演算器を用いて計算
            S_BUTTERFLY2: begin
                case (clk_cnt)
                    3'd0: begin
                        x_index <= k + j;
                        x_half_step_index <= k + j + half_step;
                        if (j == half_step - 1'd1) begin
                            j <= 10'd0;
                            i <= 10'd0;
                            if (k == N2 - step) begin
                                k <= 10'd0;
                                half_step <= step;
                                step <= step << 1;
                                index <= index >> 1;
                                next_state <= (step == N2) ? S_BUTTERFLY1 : S_BUTTERFLY2;
                            end
                            else begin
                                k <= k + step;
                            end
                        end
                        else begin
                            j <= j + 1'd1;
                            i <= i + index;
                        end

                        // read
                        wre0 <= 1'd0;
                        wre1 <= 1'd0;
                        // x0
                        ad0 <= {1'd0, k + j};
                        // x2
                        ad1 <= {1'd0, k + j};
                        // 回転因子のインデックスと符号を計算
                        // {w_re_sign, ad_w, w_im_sign, prom_i_im} <= fft_twindle_factor_index_res;
                        w_re_sign <= fft_twindle_factor_index_res[23];
                        ad_w <= fft_twindle_factor_index_res[22:12];
                        w_im_sign <= fft_twindle_factor_index_res[11];
                        prom_i_im <= fft_twindle_factor_index_res[10:0];
                        clk_cnt <= 3'd1;
                    end
                    3'd1: begin
                        // read
                        // x1
                        ad0 <= {1'd0, x_half_step_index};
                        // x3
                        ad1 <= {1'd0, x_half_step_index};
                        // w_im
                        ad_w <= prom_i_im;
                        clk_cnt <= 3'd2;
                    end
                    3'd2: begin
                        // 代入
                        // x0
                        x0_re <= dout0[31:16];
                        x0_im <= dout0[15:0];
                        // x2
                        x1_re <= dout1[31:16];
                        x1_im <= dout1[15:0];
                        // w_re
                        w_re <= dout_w;
                        clk_cnt <= 3'd3;
                        `ifdef SIMULATOR
                        debug_read_x0_re <= dout0[31:16];
                        debug_read_x0_im <= dout0[15:0];
                        debug_read_x2_re <= dout1[31:16];
                        debug_read_x2_im <= dout1[15:0];
                        debug_w_re <= (w_re_sign == 1'd1) ? ~dout_w + 1'd1 : dout_w;
                        `endif
                    end
                    3'd3: begin
                        // バタフライ演算を行い、
                        // din0[31:16] = x0_re
                        // din0[15:0] = x0_im
                        // x0_re = x1_re
                        // x0_im = x1_im
                        // をノンブロッキング代入。butterfly2も同様。
                        din0 <= butterfly0_res[63:32];
                        x0_re <= butterfly0_res[31:16];
                        x0_im <= butterfly0_res[15:0];
                        din1 <= butterfly1_res[63:32];
                        x1_re <= butterfly1_res[31:16];
                        x1_im <= butterfly1_res[15:0];
                        // write
                        wre0 <= 1'd1;
                        wre1 <= 1'd1;
                        // x0 = x0 + x1 * w
                        ad0 <= {1'd0, x_index};

                        // x2 = x2 + x3 * w
                        ad1 <= {1'd0, x_index};

                        clk_cnt <= 3'd4;
                        `ifdef SIMULATOR
                        debug_read_x1_re <= dout0[31:16];
                        debug_read_x1_im <= dout0[15:0];
                        debug_read_x3_re <= dout1[31:16];
                        debug_read_x3_im <= dout1[15:0];
                        debug_w_im <= (w_im_sign == 1'd1) ? ~dout_w + 1'd1 : dout_w;
                        debug_res_x0_re <= butterfly0_res[63:48];
                        debug_res_x0_im <= butterfly0_res[47:32];
                        debug_res_x1_re <= butterfly0_res[31:16];
                        debug_res_x1_im <= butterfly0_res[15:0];
                        debug_res_x2_re <= butterfly1_res[63:48];
                        debug_res_x2_im <= butterfly1_res[47:32];
                        debug_res_x3_re <= butterfly1_res[31:16];
                        debug_res_x3_im <= butterfly1_res[15:0];
                        `endif
                    end
                    3'd4: begin
                        // write
                        // x1 = x0 -  x1 * w
                        // x1
                        ad0 <= {1'd0, x_half_step_index};
                        din0 <= {x0_re, x0_im};
                        // x3 = x2 -  x3 * w
                        // x3
                        ad1 <= {1'd0, x_half_step_index};
                        din1 <= {x1_re, x1_im};

                        state <= next_state;
                        if (next_state == S_BUTTERFLY1) begin
                            half_step <= N2;
                        end
                        clk_cnt <= 3'd0;
                    end
                endcase
            end
            // step == Nのときは1つのバタフライ演算器を用いて計算
            S_BUTTERFLY1: begin
                case (clk_cnt)
                    3'd0: begin
                        // half stepずれたインデックスを計算
                        x_index <= j;
                        x_half_step_index <= j + half_step;
                        if (j == half_step - 1'd1) begin
                            next_state <= S_FINISH;
                        end
                        else begin
                            j <= j + 1'd1;
                            // index=1'd1
                            i <= i + 1'd1;
                        end

                        // read
                        wre0 <= 1'd0;
                        wre1 <= 1'd0;
                        // x0
                        ad0 <= {1'd0, j};
                        // 回転因子のインデックスと符号を計算
                        // {w_re_sign, ad_w, w_im_sign, prom_i_im} <= fft_twindle_factor_index_res;
                        w_re_sign <= fft_twindle_factor_index_res[23];
                        ad_w <= fft_twindle_factor_index_res[22:12];
                        w_im_sign <= fft_twindle_factor_index_res[11];
                        prom_i_im <= fft_twindle_factor_index_res[10:0];
                        clk_cnt <= 3'd1;
                    end
                    3'd1: begin
                        // read
                        // x1
                        ad1 <= {1'd0, x_index};
                        // w_im
                        ad_w <= prom_i_im;
                        clk_cnt <= 3'd2;
                    end
                    3'd2: begin
                        // 代入
                        // x0
                        x0_re <= dout0[31:16];
                        x0_im <= dout0[15:0];
                        // w_re
                        w_re <= dout_w;
                        clk_cnt <= 3'd3;
                        `ifdef SIMULATOR
                        debug_read_x0_re <= dout0[31:16];
                        debug_read_x0_im <= dout0[15:0];
                        debug_w_re <= (w_re_sign == 1'd1) ? ~dout_w + 1'd1 : dout_w;
                        `endif
                    end
                    3'd3: begin
                        // この時点でバタフライ演算を行い
                        // din0[31:16] = x0_re
                        // din0[15:0] = x0_im
                        // x0_re = x1_re
                        // x0_im = x1_im
                        // を代入する
                        // state == S_BUTTERFLY1のとき、butterfly_dout0=dout1なので注意
                        din0 <= butterfly0_res[63:32];
                        x0_re <= butterfly0_res[31:16];
                        x0_im <= butterfly0_res[15:0];
                        // write
                        // x0 = x0 + x1 * w
                        wre0 <= 1'd1;
                        wre1 <= 1'd0;
                        ad0 <= {1'd0, x_index};
                        clk_cnt <= 3'd4;
                        `ifdef SIMULATOR
                        debug_read_x1_re <= dout1[31:16];
                        debug_read_x1_im <= dout1[15:0];
                        debug_w_im <= (w_im_sign == 1'd1) ? ~dout_w + 1'd1 : dout_w;
                        debug_res_x0_re <= butterfly0_res[63:48];
                        debug_res_x0_im <= butterfly0_res[47:32];
                        debug_res_x1_re <= butterfly0_res[31:16];
                        debug_res_x1_im <= butterfly0_res[15:0];
                        `endif
                    end
                    3'd4: begin
                        // write
                        // x1 = x0 -  x1 * w
                        // x1
                        wre0 <= 1'd0;
                        wre1 <= 1'd1;
                        ad1 <= {1'd0, x_index};
                        din1 <= {x0_re, x0_im};
                        state <= next_state;
                        clk_cnt <= 3'd0;
                    end
                endcase
            end
            // S_FINISHがある理由はメモリの書き込みが終わるのを待つため。
            S_FINISH: begin
                case (clk_cnt)
                    3'd0: begin
                        // 念の為、SRAM関連の変数は0にしておく
                        ce_w <= 1'd0;
                        oce_w <= 1'd0;
                        ad_w <= 11'd0;
                        ce0 <= 1'd0;
                        oce0 <= 1'd0;
                        wre0 <= 1'd0;
                        ad0 <= 11'd0;
                        ce1 <= 1'd0;
                        oce1 <= 1'd0;
                        wre1 <= 1'd0;
                        ad1 <= 11'd0;
                        clk_cnt <= 3'd1;
                        // twindle indexの関係で、iは0に戻しておく
                        i <= 10'd0;
                    end
                    3'd1: begin
                        finish <= 1'd1;
                        state <= S_IDLE;
                        next_state <= S_IDLE;
                    end
                endcase
            end
        endcase
    end
end
endmodule