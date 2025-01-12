// MCP3002は電源電圧2.7V、クロック周波数1.2MHzのとき最大75kspsまでいける。
// 今回は電源電圧3.3V、クロック周波数0.9MHzで動かす。最大0.9M/16=56.25kspsまでいける。

module mcp3002
#(
    // 27MHz
    parameter CLK_FREQ = 27_000_000,
    // 0.9MHz
    parameter MCP3002_CLK_FREQ = 900_000
)(
    input clk,
    input rst_n,
    output reg adc_clk,
    output reg adc_din,
    input adc_dout,
    output reg adc_cs,
    input adc_enable,
    output reg [9:0] adc_data,
    output reg adc_available,
    input adc_clear_available
);

localparam START = 1'd1;
// 0: DIFFERENTIAL MODE
// 1: SINGLE ENDED MODE
localparam SGL_DIFF = 1'd1;
localparam ODD_SIGN = 1'd0;
// 0: LSB first
// 1: MSB first
localparam MSBF = 1'd1;

localparam S_IDLE = 1'd0;
localparam S_RUNNING = 1'd1;
// NOTE: 割り切れない値だと誤差が発生するので注意
localparam CYCLE = CLK_FREQ / MCP3002_CLK_FREQ;
localparam HALF_CYCLE = CYCLE / 2;
reg state;
reg [15:0] cycle;
reg [4:0] clk_cnt;
reg [9:0] tmp_data;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        adc_clk <= 1'd0;
        adc_din <= 1'd0;
        adc_cs <= 1'd1;
        adc_data <= 10'd0;
        adc_din <= 1'd0;
        adc_available <= 1'd1;
        state <= S_IDLE;
        cycle <= 16'd0;
        clk_cnt <= 5'd0;
        tmp_data <= 10'd0;
    end
    else begin
        if (adc_clear_available == 1'd1) begin
            adc_available <= 1'd0;
        end
        case (state)
            S_IDLE: begin
                if(adc_enable == 1'd1) begin
                    state <= S_RUNNING;
                    cycle <= 16'd0;
                    clk_cnt <= 5'd0;
                    adc_clk <= 1'd0;
                    adc_cs <= 1'd0;
                    adc_din <= START;
                    tmp_data <= 10'd0;
                end
                else begin
                    adc_clk <= 1'd0;
                    adc_din <= 1'd0;
                    adc_cs <= 1'd1;
                end
            end
            S_RUNNING: begin
                if (cycle == HALF_CYCLE - 1) begin
                    adc_clk <= ~adc_clk;
                    cycle <= 16'd0;

                    if (clk_cnt != 5'd31) begin
                        clk_cnt <= clk_cnt + 1'd1;
                        case (clk_cnt)
                            1: adc_din <= SGL_DIFF;
                            3: adc_din <= ODD_SIGN;
                            5: adc_din <= MSBF;
                            // null bit
                            7: adc_din <= 1'd0;
                            10: tmp_data[9] <= adc_dout;
                            12: tmp_data[8] <= adc_dout;
                            14: tmp_data[7] <= adc_dout;
                            16: tmp_data[6] <= adc_dout;
                            18: tmp_data[5] <= adc_dout;
                            20: tmp_data[4] <= adc_dout;
                            22: tmp_data[3] <= adc_dout;
                            24: tmp_data[2] <= adc_dout;
                            26: tmp_data[1] <= adc_dout;
                            28: tmp_data[0] <= adc_dout;
                            29: adc_cs <= 1'd1;
                        endcase
                    end
                    else begin
                        // 31
                        state <= S_IDLE;
                        clk_cnt <= 5'd0;
                        adc_data <= tmp_data;
                        adc_available <= 1'd1;
                    end
                end
                else begin
                    cycle <= cycle + 1'd1;
                end
            end
        endcase
    end
end
endmodule