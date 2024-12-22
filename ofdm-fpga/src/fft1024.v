// 固定小数点のフォーマットはq1.15
module fft1024
(
    input clk,
    input rst_n,
    input start,
    output reg finish,
    // BSRAM fft0
    input wire [31:0] dout0,
    output reg oce0,
    output reg ce0,
    output reg wre0,
    output reg [10:0] ad0,
    output reg [31:0] din0,
    // BSRAM fft1
    input wire [31:0] dout1,
    output reg oce1,
    output reg ce1,
    output reg wre1,
    output reg [10:0] ad1,
    output reg [31:0] din1,
    // BSRAM(prom) w
    input wire [15:0] dout_w,
    output reg oce_w,
    output reg ce_w,
    output reg [10:0] ad_w,
    output reg [15:0] din_w
);

localparam N = 1024;
localparam N2 = N / 2;
localparam N4 = N / 4;
localparam N4_2 = N4 * 2;
localparam N4_3 = N4 * 3;
localparam N_PROM = 1025;

reg [15:0] w_re;
reg [15:0] w_im;

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
reg [10:0] prom_i_re;
reg [10:0] prom_i_im;
reg w_re_sign;
reg w_im_sign;
// x0とx2、x1とx3のインデックスは今回のSRAMの構成では同じ(N/2ずれているため)
reg [9:0] x_index;
reg [9:0] x_half_step_index;

localparam S_IDLE = 3'd0;
localparam S_BUTTERFLY2_INIT = 3'd1;
localparam S_BUTTERFLY2 = 3'd2;
localparam S_BUTTERFLY1_INIT = 3'd3;
localparam S_BUTTERFLY1 = 3'd4;

reg [2:0] state;
reg [2:0] next_state;
reg [1:0] clk_cnt;

function [63:0] butterfly;
    // butterfly = {x0_re, x0_im, x1_re, x1_im};
    // x0 = x0 + x1 * w
    // x1 = x0 - x1 * w
    input [15:0] x0_re;
    input [15:0] x0_im;
    input [15:0] x1_re;
    input [15:0] x1_im;
    input [15:0] w_re;
    input [15:0] w_im;
    // x1w_reとx1w_imは絶対値
    reg [15:0] x1w_re;
    reg [15:0] x1w_im;

    case ({x1_re[15], w_re[15], x1_im[15], w_im[15]})
        4'b0000: begin
            x1w_re = (x1_re * w_re) >> 16;
            x1w_im = (x1_im * w_im) >> 16;
            butterfly = {x0_re + x1w_re, x0_im + x1w_im, x0_re + ~x1w_re + 16'd1, x0_im + ~x1w_im + 16'd1};
        end
        4'b0001: begin
            x1w_re = (x1_re * w_re) >> 16;
            x1w_im = (x1_im * (~w_im + 16'd1)) >> 16;
            butterfly = {x0_re + x1w_re, x0_im + ~x1_im + 16'd1, x0_re + ~x1w_re + 16'd1, x0_im + x1w_im};
        end
        4'b0010: begin
            x1w_re = (x1_re * w_re) >> 16;
            x1w_im = ((~x1_im + 16'd1) * w_im) >> 16;
            butterfly = {x0_re + x1w_re, x0_im + ~x1_im + 16'd1, x0_re + ~x1w_re + 16'd1, x0_im + x1w_im};
        end
        4'b0011: begin
            x1w_re = (x1_re * w_re) >> 16;
            x1w_im = ((~x1_im + 16'd1) * (~w_im + 16'd1)) >> 16;
            butterfly = {x0_re + x1w_re, x0_im + x1w_im, x0_re + ~x1w_re + 16'd1, x0_im + ~x1w_im + 16'd1};
        end
        4'b0100: begin
            x1w_re = (x1_re * (~w_re + 16'd1)) >> 16;
            x1w_im = (x1_im * w_im) >> 16;
            butterfly = {x0_re + ~x1w_re + 16'd1, x0_im + x1w_im, x0_re + x1w_re, x0_im + ~x1w_im + 16'd1};
        end
        4'b0101: begin
            x1w_re = (x1_re * (~w_re + 16'd1)) >> 16;
            x1w_im = (x1_im * (~w_im + 16'd1)) >> 16;
            butterfly = {x0_re + ~x1w_re + 16'd1, x0_im + ~x1_im + 16'd1, x0_re + x1w_re, x0_im + x1w_im};
        end
        4'b0110: begin
            x1w_re = (x1_re * (~w_re + 16'd1)) >> 16;
            x1w_im = ((~x1_im + 16'd1) * w_im) >> 16;
            butterfly = {x0_re + ~x1w_re + 16'd1, x0_im + ~x1_im + 16'd1, x0_re + x1w_re, x0_im + x1w_im};
        end
        4'b0111: begin
            x1w_re = (x1_re * (~w_re + 16'd1)) >> 16;
            x1w_im = ((~x1_im + 16'd1) * (~w_im + 16'd1)) >> 16;
            butterfly = {x0_re + ~x1w_re + 16'd1, x0_im + x1w_im, x0_re + x1w_re, x0_im + ~x1w_im + 16'd1};
        end
        4'b1000: begin
            x1w_re = ((~x1_re + 16'd1) * w_re) >> 16;
            x1w_im = (x1_im * w_im) >> 16;
            butterfly = {x0_re + ~x1w_re + 16'd1, x0_im + x1w_im, x0_re + x1w_re, x0_im + ~x1w_im + 16'd1};
        end
        4'b1001: begin
            x1w_re = ((~x1_re + 16'd1) * w_re) >> 16;
            x1w_im = (x1_im * (~w_im + 16'd1)) >> 16;
            butterfly = {x0_re + ~x1w_re + 16'd1, x0_im + ~x1_im + 16'd1, x0_re + x1w_re, x0_im + x1w_im};
        end
        4'b1010: begin
            x1w_re = ((~x1_re + 16'd1) * w_re) >> 16;
            x1w_im = ((~x1_im + 16'd1) * w_im) >> 16;
            butterfly = {x0_re + ~x1w_re + 16'd1, x0_im + ~x1_im + 16'd1, x0_re + x1w_re, x0_im + x1w_im};
        end
        4'b1011: begin
            x1w_re = ((~x1_re + 16'd1) * w_re) >> 16;
            x1w_im = ((~x1_im + 16'd1) * (~w_im + 16'd1)) >> 16;
            butterfly = {x0_re + ~x1w_re + 16'd1, x0_im + x1w_im, x0_re + x1w_re, x0_im + ~x1w_im + 16'd1};
        end
        4'b1100: begin
            x1w_re = ((~x1_re + 16'd1) * (~w_re + 16'd1)) >> 16;
            x1w_im = (x1_im * w_im) >> 16;
            butterfly = {x0_re + x1w_re, x0_im + x1w_im, x0_re + ~x1w_re + 16'd1, x0_im + ~x1w_im + 16'd1};
        end
        4'b1101: begin
            x1w_re = ((~x1_re + 16'd1) * (~w_re + 16'd1)) >> 16;
            x1w_im = (x1_im * (~w_im + 16'd1)) >> 16;
            butterfly = {x0_re + x1w_re, x0_im + ~x1_im + 16'd1, x0_re + ~x1w_re + 16'd1, x0_im + x1w_im};
        end
        4'b1110: begin
            x1w_re = ((~x1_re + 16'd1) * (~w_re + 16'd1)) >> 16;
            x1w_im = ((~x1_im + 16'd1) * w_im) >> 16;
            butterfly = {x0_re + x1w_re, x0_im + ~x1_im + 16'd1, x0_re + ~x1w_re + 16'd1, x0_im + x1w_im};
        end
        4'b1111: begin
            x1w_re = ((~x1_re + 16'd1) * (~w_re + 16'd1)) >> 16;
            x1w_im = ((~x1_im + 16'd1) * (~w_im + 16'd1)) >> 16;
            butterfly = {x0_re + x1w_re, x0_im + x1w_im, x0_re + ~x1w_re + 16'd1, x0_im + ~x1w_im + 16'd1};
        end
    endcase
endfunction

function [23:0] calc_w;
    // calc_w = {w_re_sign, i_re, w_im_sign, i_im};
    input [9:0] i;
    if (0 <= i && i <= N4) 
        // 第4象限
        calc_w = {1'd0, N4 - i, 1'd1, i};
    else if(N4 < i && i <= 2 * N4)
        // 第3象限
        calc_w = {1'd1, i - N4, 1'd1, N4 - i};
    else if(N4_2 < i && i <= N4_3)
        // 第2象限
        calc_w = {1'd1, N4_3 - i, 1'd1, i - N4_2}; 
    else
        // 第1象限
        calc_w = {1'd0, i - N4_3, 1'd0, i & (N4 - i)};
endfunction

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        w_re <= 16'd0;
        w_im <= 16'd0;
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
        prom_i_re <= 11'd0;
        prom_i_im <= 11'd0;
        w_re_sign <= 1'd0;
        w_im_sign <= 1'd0;
        x_index <= 10'd0;
        x_half_step_index <= 10'd0;

        state <= S_IDLE;
        next_state <= S_IDLE;
        clk_cnt <= 2'd0;
        finish <= 1'd0;
    end
    else begin
        case (state)
            S_IDLE: begin
                if (start == 1'd1) begin
                    state <= S_BUTTERFLY2_INIT;
                    clk_cnt <= 2'd0;
                    finish <= 1'd0;
                end
            end
            S_BUTTERFLY2_INIT: begin
                clk_cnt <= clk_cnt + 1'd1;
                case (clk_cnt)
                    2'd0: begin
                        ce_w <= 1'd1;
                        oce_w <= 1'd1;
                        ad_w <= 11'd0;
                        // 他のSRAMもいつでも使用可能にしておく
                        ce0 <= 1'd1;
                        oce0 <= 1'd1;
                        wre0 <= 1'd0;
                        ad0 <= 11'd0;
                        ce0 <= 1'd1;
                        oce1 <= 1'd1;
                        wre1 <= 1'd0;
                        ad1 <= 11'd0;
                        prom_i_re <= N4;
                        prom_i_im <= 11'd0;
                        w_re_sign <= 1'd0;
                        w_im_sign <= 1'd1;
                    end
                    2'd1: begin
                        // fft1024ではN=4096の回転因子を使用するため4倍する
                        ad_w <= prom_i_re << 2;
                    end
                    2'd2: begin
                        // fft1024ではN=4096の回転因子を使用するため4倍する
                        w_re <= (w_re_sign == 1'd1) ? ~dout_w + 1'd1 : dout_w;
                        ad_w <= prom_i_im << 2;
                    end
                    2'd3: begin
                        w_im <= (w_im_sign == 1'd1) ? ~dout_w + 1'd1 : dout_w;
                        half_step <= 10'd1;
                        step <= 10'd2;
                        index <= N2;
                        i <= 10'd0;
                        j <= 10'd0;
                        k <= 10'd0;
                        state <= S_BUTTERFLY2;
                        next_state <= S_BUTTERFLY2;
                    end
                endcase
            end
            S_BUTTERFLY2: begin
                clk_cnt <= clk_cnt + 1'd1;
                case (clk_cnt)
                    2'd0: begin
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
                                next_state <= (step == N4) ? S_BUTTERFLY1_INIT : S_BUTTERFLY2;
                            end
                            else begin
                                k <= k + step;
                            end
                        end
                        else begin
                            j <= j + 1'd1;
                        end
                        
                        // read
                        wre0 <= 1'd0;
                        wre1 <= 1'd0;
                        // x0
                        ad0 <= {1'd0, k + j};
                        // x2
                        ad1 <= {1'd0, k + j};
                        // 回転因子のインデックスと符号を計算
                        {w_re_sign, prom_i_re, w_im_sign, prom_i_im} <= calc_w(i);
                    end
                    2'd1: begin
                        // 代入
                        // x0
                        x0_re <= dout0[31:16];
                        x0_im <= dout0[15:0];
                        // x2
                        x1_re <= dout1[31:16];
                        x1_im <= dout1[15:0];
                        // read
                        // x1
                        ad0 <= {1'd0, x_half_step_index};
                        // x3
                        ad1 <= {1'd0, x_half_step_index};
                        ad_w <= prom_i_re << 2;
                    end
                    2'd2: begin
                        // 代入
                        w_re <= (w_re_sign == 1'd1) ? ~dout_w + 1'd1 : dout_w;
                        // read
                        ad_w <= prom_i_im << 2;
                        // write
                        wre0 <= 1'd1;
                        wre1 <= 1'd1;
                        // x0 = x0 + x1 * w
                        ad0 <= {1'd0, x_index};
                        {din0, x0_re, x0_im} <= butterfly(x0_re, x0_im, dout0[31:16], dout0[15:0], w_re, w_im);
                        // x2 = x2 + x3 * w
                        ad1 <= {1'd0, x_index};
                        {din1, x1_re, x1_im} <= butterfly(x1_re, x1_im, dout1[31:16], dout1[15:0], w_re, w_im);
                    end
                    2'd3: begin
                        // 代入
                        w_im <= (w_im_sign == 1'd1) ? ~dout_w + 1'd1 : dout_w;
                        // write
                        // x1 = x0 -  x1 * w
                        // x1を書き込み
                        ad0 <= {1'd0, x_half_step_index};
                        din0 <= {x0_re, x0_im};
                        // x3 = x2 -  x3 * w
                        // x3を書き込み
                        ad1 <= {1'd0, x_half_step_index};
                        din1 <= {x1_re, x1_im};

                        i <= i + index;
                        state <= next_state;
                    end
                endcase
            end
            S_BUTTERFLY1_INIT: begin
                clk_cnt <= clk_cnt + 1'd1;
                case (clk_cnt)
                    2'd0: begin
                        prom_i_re <= N4;
                        prom_i_im <= 11'd0;
                        w_re_sign <= 1'd0;
                        w_im_sign <= 1'd1;
                        wre0 <= 1'd0;
                        wre1 <= 1'd0;
                    end
                    2'd1: begin
                        ad_w <= prom_i_re << 2;
                    end
                    2'd2: begin
                        w_re <= (w_re_sign == 1'd1) ? ~dout_w + 1'd1 : dout_w;
                        ad_w <= prom_i_im << 2;
                    end
                    2'd3: begin
                        w_im <= (w_im_sign == 1'd1) ? ~dout_w + 1'd1 : dout_w;

                        half_step <= step;
                        step <= step << 1;
                        index <= index >> 1;
                        i <= 10'd0;
                        j <= 10'd0;
                        k <= 10'd0;
                        state <= S_BUTTERFLY1;
                        next_state <= S_BUTTERFLY1;
                    end
                endcase
            end
            S_BUTTERFLY1: begin
                clk_cnt <= clk_cnt + 1'd1;
                case (clk_cnt)
                    2'd0: begin
                        // half stepずれたインデックスを計算
                        x_index <= k + j;
                        x_half_step_index <= j + k + half_step;
                        if (j == half_step - 1'd1) begin
                            j <= 10'd0;
                            i <= 10'd0;
                            if (k == N - step) begin
                                k <= 10'd0;
                                half_step <= step;
                                step <= step << 1;
                                index <= index >> 1;
                                next_state <= S_IDLE;
                            end
                            else begin
                                k <= k + step;
                            end
                        end
                        else begin
                            j <= j + 1'd1;
                        end

                        // read
                        wre0 <= 1'd0;
                        // x0
                        ad0 <= {1'd0, k + j};
                        // 回転因子のインデックスと符号を計算
                        {w_re_sign, prom_i_re, w_im_sign, prom_i_im} <= calc_w(i);
                    end
                    2'd1: begin
                        // 代入
                        // x0
                        x0_re <= dout0[31:16];
                        x0_im <= dout0[15:0];
                        // read
                        // x1
                        ad0 <= {1'd0, x_half_step_index};
                        ad_w <= prom_i_re << 2;
                    end
                    2'd2: begin
                        // 代入
                        w_re <= (w_re_sign == 1'd1) ? ~dout_w + 1'd1 : dout_w;
                        // read
                        ad_w <= prom_i_im << 2;
                        // write
                        wre0 <= 1'd1;
                        // x0 = x0 + x1 * w
                        ad0 <= {1'd0, x_index};
                        {din0, x0_re, x0_im} <= butterfly(x0_re, x0_im, dout0[31:16], dout0[15:0], w_re, w_im);
                    end
                    2'd3: begin
                        // 代入
                        w_im <= (w_im_sign == 1'd1) ? ~dout_w + 1'd1 : dout_w;
                        // write
                        // x1 = x0 -  x1 * w
                        ad0 <= {1'd0, x_half_step_index};
                        // x1
                        din0 <= {x0_re, x0_im};
                        i <= i + index;
                        state <= next_state;
                        finish <= (next_state == S_IDLE) ? 1'd1 : 1'd0;
                    end
                endcase
            end
        endcase
    end
end
endmodule