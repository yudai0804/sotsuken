module fft_twindle_factor_index
#(
    parameter N = 1024
)
(
    input [9:0] i,
    input is_1024,
    output [23:0] res
);

// localparam N4 = N / 4;
// localparam N4_2 = N4 * 2;
// localparam N4_3 = N4 * 3;
localparam N4 = 11'd256;
localparam N4_2 = 11'd512;
localparam N4_3 = 11'd768;

function [23:0] calc;
    // calc = {w_re_sign, i_re, w_im_sign, i_im};
    // fft1024ではN=4096の回転因子を使用するため4倍する
    input [9:0] i;
    input is_1024;
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
        ad_re = is_1024 ? _ad_re << 2 : _ad_re;
        ad_im = is_1024 ? _ad_im << 2 : _ad_im;
        sign_re = 1'd0;
        sign_im = 1'd1;
        calc = {sign_re, ad_re, sign_im, ad_im};
    end
    else if(N4 < i && i <= N4_2) begin
        // 第3象限
        _ad_re = i - N4;
        _ad_im = N4_2 - i;
        ad_re = is_1024 ? _ad_re << 2 : _ad_re;
        ad_im = is_1024 ? _ad_im << 2 : _ad_im;
        sign_re = 1'd1;
        sign_im = 1'd1;
        calc = {sign_re, ad_re, sign_im, ad_im};
    end
    else if(N4_2 < i && i <= N4_3) begin
        // 第2象限
        _ad_re = N4_3 - i;
        _ad_im = i - N4_2;
        ad_re = is_1024 ? _ad_re << 2 : _ad_re;
        ad_im = is_1024 ? _ad_im << 2 : _ad_im;
        sign_re = 1'd1;
        sign_im = 1'd0;
        calc = {sign_re, ad_re, sign_im, ad_im};
    end
    else begin
        // 第1象限
        _ad_re = i - N4_3;
        _ad_im = i & (N4 - i);
        ad_re = is_1024 ? _ad_re << 2 : _ad_re;
        ad_im = is_1024 ? _ad_im << 2 : _ad_im;
        sign_re = 1'd0;
        sign_im = 1'd0;
        calc = {sign_re, ad_re, sign_im, ad_im};
    end
endfunction

assign res = calc(i, is_1024);

endmodule