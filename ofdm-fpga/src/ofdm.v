module ofdm(
    input clk,
    input rst_n,
    input start,
    output reg finish,
    output reg success,
    input clear,
    output reg [95:0] res,
    // BSRAM fft0
    // read onlyなので、dinとwreは使わないので削除
    input [31:0] dout0,
    output reg oce0,
    output reg ce0,
    output reg [10:0] ad0
);
// サブキャリアの範囲は1000~6000Hz
// サブキャリア間隔は50Hz
// 1000Hz
localparam PILOT0 = 7'd20;
// 1050Hz
localparam PILOT1 = 7'd21;
// 2700Hz
localparam PILOT2 = 7'd54;
// 4350Hz
localparam PILOT3 = 7'd87;
// 6000Hz
localparam PILOT4 = 7'd120;

// 16384 = 0x4000 = 0.5
localparam PILOT_AMPLITUDE = 16'h4000;

localparam INDEX_BEGIN = 7'd20;

reg [15:0] pilot_diff;
reg [6:0] i;
reg [6:0] j;
reg [2:0] state;

wire [15:0] dout0_re;
wire [15:0] _sign_X;
wire sign_X;
assign dout0_re = dout0[31:16];
assign _sign_X = dout0_re - pilot_diff;
assign sign_X = _sign_X[15];

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        finish <= 1'd0;
        success <= 1'd0;
        res <= 96'd0;
        pilot_diff <= 16'd0;
        i <= INDEX_BEGIN;
        j <= 7'd0;
        state <= 3'd0;
    end
    else begin
        if (clear == 1'd1 && state != 3'd4) begin
            finish <= 1'd0;
            success <= 1'd0;
        end
        case (state)
            3'd0: begin
                if (start == 1'd1) begin
                    oce0 <= 1'd1;
                    ce0 <= 1'd1;
                    ad0 <= {4'd0, INDEX_BEGIN};
                    pilot_diff <= 16'd0;
                    i <= INDEX_BEGIN;
                    j <= 7'd0;
                    state <= 3'd1;
                end
            end
            3'd1: begin
                ad0 <= ad0 + 1'd1;
                state <= 3'd2;
            end
            3'd2: begin
                ad0 <= ad0 + 1'd1;
                i <= i + 1'd1;
                case (i)
                    PILOT0, PILOT1, PILOT2, PILOT3: begin
                        pilot_diff <= dout0_re - PILOT_AMPLITUDE;
                    end
                    PILOT4: begin
                        oce0 <= 1'd0;
                        ce0 <= 1'd0;
                        state <= 3'd3;
                    end
                    default: begin
                        // MSBから転送されてくるのでXORして対応
                        res[j ^ 7'h07] <= ~sign_X;
                        j <= j + 1'd1;
                    end
                endcase
            end
            3'd3: begin
                state <= 3'd4;
            end
            3'd4: begin
                state <= 3'd0;
                finish <= 1'd1;
                success <= (res[7:0] == 8'h55 && res [95:88] == 8'h55) ? 1'd1 : 1'd0;
            end
        endcase
    end
end
endmodule