// 固定小数点のフォーマットはq1.15
module fft1024
(
    input clk,
    input rst_n,
    wire start,
    reg finish,
    // BSRAM fft0
    wire [31:0] dout0,
    reg oce0,
    reg ce0,
    reg wre0,
    reg [10:0] ad0,
    reg [31:0] din0,
    // BSRAM fft1
    wire [15:0] dout1,
    reg oce1,
    reg ce1,
    reg wre1,
    reg [11:0] ad1,
    reg [15:0] din1,
    // BSRAM(prom) w
    wire [15:0] dout_w,
    reg oce_w,
    reg ce_w,
    reg [10:0] ad_w,
    reg [15:0] din_w
);

localparam N = 1024;
localparam N2 = N / 2;
localparam N4 = N / 4;
localparam N_LOG = 10;
localparam N_PROM = 1025;
localparam N_PROM_LOG = 11;

reg [15:0] w_re;
reg [15:0] w_im;

// xの一次保管用。
// NOTE: 同じ変数を再利用しまくってるので、可読性ゴミなので注意
reg [15:0] x0_re;
reg [15:0] x0_im;
reg [15:0] x1_re;
reg [15:0] x1_im;

reg [N_LOG-1:0] step;
reg [N_LOG-1:0] half_step;
reg [N_LOG-1:0] index;
reg [N_LOG-1:0] i;
reg [N_LOG-1:0] j;
reg [N_LOG-1:0] k;
reg [N_PROM_LOG-1:0] i_re;
reg [N_PROM_LOG-1:0] i_im;
reg w_re_sign;
reg w_im_sign;
// x0とx2、x1とx3のインデックスは今回のSRAMの構成では同じ(N/2ずれているため)
reg [N_LOG-1:0] x_index;
reg [N_LOG-1:0] x_half_step_index;

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
    // xw_reとxw_imは絶対値
    reg [15:0] xw_re;
    reg [15:0] xw_im;
    case ({x1_re[15], w_re[15]})
        2'd0: xw_re = (x1_re * w_re >> 8)[15:0];
        2'd1: xw_re = (x1_re * (~w_re + 16'd1) >> 8)[15:0];
        2'd2: xw_re = ((~x1_re + 16'd1) * w_re >> 8)[15:0];
        2'd3: xw_re = ((~x1_re + 16'd1) * (~w_re + 16'd1) >> 8)[15:0];
    endcase
    case ({x1_im[15], w_im[15]})
        2'd0: xw_im = (x1_im * w_im >> 8)[15:0];
        2'd1: xw_im = (x1_im * (~w_im + 16'd1) >> 8)[15:0];
        2'd2: xw_im = ((~x1_im + 16'd1) * w_im >> 8)[15:0];
        2'd3: xw_im = ((~x1_im + 16'd1) * (~w_im + 16'd1) >> 8)[15:0];
    endcase
    // butterfly = {x0_re, x0_im, x1_re, x1_im};
    butterfly = {
        x0_re + ((x1_re[15] ^ w_re[15]) == 1'd1 ? ~xw_re + 16'd1 : xw_re),
        x0_im + ((x1_im[15] ^ w_im[15]) == 1'd1 ? ~xw_im + 16'd1 : xw_im),
        x0_re + ((x1_re[15] ^ w_re[15]) == 1'd0 ? ~xw_re + 16'd1 : xw_re),
        x0_im + ((x1_im[15] ^ w_im[15]) == 1'd0 ? ~xw_im + 16'd1 : xw_im),
    };
endfunction

function [23:0] calc_w;
    // calc_w = {w_re_sign, i_re, w_im_sign, i_im};
    input [N_LOG-1:0] i;
    if (N_LOG'd0 <= i && i <= N4) 
        // 第4象限
        calc_w = {1'd0, N4 - i, 1'd1, i};
    else if(N4 < i && i <= 2 * N4)
        // 第3象限
        calc_w = {1'd1, i - N4, 1'd1, N4 - i};
    else if(2 * N4 < i && i <= 3 * N4)
        // 第2象限
        calc_w = {1'd1, 3 * N4 - i, 1'd1, i - 2 * N4}; 
    else
        // 第1象限
        calc_w = {1'd0, i - 3 * N4, 1'd0, i & (N4 - i)};
endfunction

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        w_re <= 16'd0;
        w_im <= 16'd0;
        x0_re <= 16'd0;
        x0_im <= 16'd0;
        x1_re <= 16'd0;
        x1_im <= 16'd0;
        
        step <= N_LOG'd0;
        half_step <= N_LOG'd0;
        index <= N_LOG'd0;
        i <= N_LOG'd0;
        j <= N_LOG'd0;
        k <= N_LOG'd0;
        i_re <= N_PROM_LOG'd0;
        i_im <= N_PROM_LOG'd0;
        w_re_sign <= 1'd0;
        w_im_sign <= 1'd0;
        x_index <= N_LOG'd0;
        x_half_step_index <= N_LOG'd0;

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
                end
            end
            S_BUTTERFLY2_INIT: begin
                clk_cnt <= clk_cnt + 1'd1;
                case (clk_cnt)
                    2'd0: begin
                        ce_w <= 1'd1;
                        oce_w <= 1'd1;
                        ad_w <= N_PROM_LOG'd0;
                        // 他のSRAMもいつでも使用可能にしておく
                        ce0 <= 1'd1;
                        oce0 <= 1'd1;
                        wre0 <= 1'd0;
                        ad0 <= 11'd0;
                        ce0 <= 1'd1;
                        oce1 <= 1'd1;
                        wre1 <= 1'd0;
                        ad1 <= 11'd0;
                        i_re <= N_PROM_LOG'N4;
                        i_im <= N_PROM_LOG'd0;
                        w_re_sign <= 1'd0;
                        w_im_sign <= 1'd1;

                        finish <= 1'd0;
                    end
                    2'd1: begin
                        // fft1024ではN=4096の回転因子を使用するため4倍する
                        ad_w <= (i_re << 2)[N_PROM_LOG-1:0];
                    end
                    2'd2: begin
                        // fft1024ではN=4096の回転因子を使用するため4倍する
                        w_re <= (w_re_sign == 1'd1) ? ~dout_w + 1'd1 : dout_w;
                        ad_w <= (i_im << 2)[N_PROM_LOG-1:0];
                    end
                    2'd3: begin
                        w_im <= (w_im_sign == 1'd1) ? ~dout_w + 1'd1 : dout_w;
                        half_step <= N_LOG'd1;
                        step <= N_LOG'd2;
                        index <= N2;
                        i <= N_LOG'd0;
                        j <= N_LOG'd0;
                        k <= N_LOG'd0;
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
                            j <= N_LOG'd0;
                            i <= N_LOG'd0;
                            if (k == N2 - step) begin
                                k <= N_LOG'd0;
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
                        {w_re_sign, i_re, w_im_sign, i_im} <= calc_w(i);
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
                        ad0 <= {1'd0, x_half_index};
                        // x3
                        ad1 <= {1'd0, x_half_index};
                        ad_w <= (i_re << 2)[N_PROM_LOG-1:0];
                    end
                    2'd2: begin
                        // 代入
                        w_re <= (w_re_sign == 1'd1) ? ~dout_w + 1'd1 : dout_w;
                        // read
                        ad_w <= (i_im << 2)[N_PROM_LOG-1:0];
                        // write
                        wre0 <= 1'd1;
                        wre1 <= 1'd1;
                        // x0 = x0 + x1 * w
                        ad0 <= {1'd0, x_index};
                        {dout0, x0_re, x0_im} <= butterfly(x0_re, x0_im, dout0[31:16], dout0[15:0], w_re, w_im);
                        // x2 = x2 + x3 * w
                        ad1 <= {1'd0, x_index};
                        {dout1, x1_re, x1_im} <= butterfly(x1_re, x1_im, dout1[31:16], dout1[15:0], w_re, w_im);
                    end
                    2'd3: begin
                        // 代入
                        w_im <= (w_im_sign == 1'd1) ? ~dout_w + 1'd1 : dout_w;
                        // write
                        // x1 = x0 -  x1 * w
                        // x1を書き込み
                        ad0 <= {1'd0, x_half_step_index};
                        dout0 <= {x0_re, x0_im};
                        // x3 = x2 -  x3 * w
                        // x3を書き込み
                        ad1 <= {1'd0, x_half_step_index};
                        dout1 <= {x1_re, x1_im};

                        i <= i + index;
                        state <= next_state;
                    end
                endcase
            end
            S_BUTTERFLY1_INIT: begin
                clk_cnt <= clk_cnt + 1'd1;
                case (clk_cnt)
                    2'd0: begin
                        i_re <= N_PROM_LOG'N4;
                        i_im <= N_PROM_LOG'd0;
                        w_re_sign <= 1'd0;
                        w_im_sign <= 1'd1;
                    end
                    2'd1: begin
                        ad_w <= (i_re << 2)[N_PROM_LOG-1:0];
                    end
                    2'd2: begin
                        w_re <= (w_re_sign == 1'd1) ? ~dout_w + 1'd1 : dout_w;
                        ad_w <= (i_im << 2)[N_PROM_LOG-1:0];
                    end
                    2'd3: begin
                        w_im <= (w_im_sign == 1'd1) ? ~dout_w + 1'd1 : dout_w;

                        half_step <= step;
                        step <= step << 1;
                        index <= index >> 1;
                        i <= N_LOG'd0;
                        j <= N_LOG'd0;
                        k <= N_LOG'd0;
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
                            j <= N_LOG'd0;
                            i <= N_LOG'd0;
                            if (k == N - step) begin
                                k <= N_LOG'd0;
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
                        {w_re_sign, i_re, w_im_sign, i_im} <= calc_w(i);
                    end
                    2'd1: begin
                        // 代入
                        // x0
                        x0_re <= dout0[31:16];
                        x0_im <= dout0[15:0];
                        // read
                        // x1
                        ad0 <= {1'd0, x_half_step_index};
                        ad_w <= (i_re << 2)[N_PROM_LOG:0];
                    end
                    2'd2: begin
                        // 代入
                        w_re <= (w_re_sign == 1'd1) ? ~dout_w + 1'd1 : dout_w;
                        // read
                        ad_w <= (i_im << 2)[N_PROM_LOG-1:0];
                        // write
                        wre0 <= 1'd1;
                        // x0 = x0 + x1 * w
                        ad0 <= {1'd0, x_index};
                        {dout0, x0_re, x0_im} <= butterfly(x0_re, x0_im, dout0[31:16], dout0[15:0], w_re, w_im);
                    end
                    2'd3: begin
                        // 代入
                        w_im <= (w_im_sign == 1'd1) ? ~dout_w + 1'd1 : dout_w;
                        // write
                        // x1 = x0 -  x1 * w
                        ad0 <= {1'd0, x_half_step_index};
                        // x1
                        dout0 <= {x0_re, x0_im};
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