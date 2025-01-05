// Data format
// boudrate = 115200
// byte size = 8
// start bit = 0
// parity = None
// stop bit = 1
// START(0) + B0 + B1 + B2 + B3 + B4 + B5 + B6 + B7 + STOP(1)

// クロック周波数27MHzのとき、
// 1 - floor(27e6 / 115200) / (27e6 / 115200) = 0.001600
// よりボーレートの誤差は0.16%

module uart_rx
#(
    // 27MHz
    parameter CLK_FREQ = 27_000_000,
    // 115.2kbps
    parameter BOUD_RATE = 115200
)(
    input clk,
    input rst_n,
    input rx_pin,
    output reg [7:0] data,
    output reg available,
    // 1のときrx_availableをクリアする
    input clear_available
);

localparam CYCLE = CLK_FREQ / BOUD_RATE;
localparam HALF_CYCLE = CYCLE / 2;
localparam S_IDLE = 1'd0;
localparam S_RUNNING = 1'd1;
// 27e6 / 115200 = 234
// より8bitあれば十分
// NOTE: 115200より遅くしたら、オーバーフローする可能性があるので注意
reg [7:0] cycle;
reg [7:0] tmp_data;
reg state;
reg [4:0] clk_cnt;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        data <= 8'd0;
        available <= 1'd0;
        cycle <= 8'd0;
        tmp_data <= 8'd0;
        state <= S_IDLE;
        clk_cnt <= 5'd0;
    end
    else begin
        if (clear_available == 1'd1 && (state == S_RUNNING && clk_cnt == 5'd17) == 1'd0) begin
            available <= 1'd0;
        end
        case (state)
            S_IDLE: begin
                if (rx_pin == 1'd0) begin
                    if (cycle == HALF_CYCLE - 1) begin
                        // start bit検出
                        cycle <= 8'd0;
                        state <= S_RUNNING;
                        clk_cnt <= 5'd0;
                    end
                    else begin
                        cycle <= cycle + 1'd1;
                    end
                end
                else begin
                    cycle <= 8'd0;
                end
            end
            S_RUNNING: begin
                if (cycle == HALF_CYCLE - 1) begin
                    cycle <= 8'd0;
                    if (clk_cnt != 5'd18) begin
                        clk_cnt <= clk_cnt + 1'd1;
                    end
                    case (clk_cnt)
                        5'd1: tmp_data[0] <= rx_pin;
                        5'd3: tmp_data[1] <= rx_pin;
                        5'd5: tmp_data[2] <= rx_pin;
                        5'd7: tmp_data[3] <= rx_pin;
                        5'd9: tmp_data[4] <= rx_pin;
                        5'd11: tmp_data[5] <= rx_pin;
                        5'd13: tmp_data[6] <= rx_pin;
                        5'd15: tmp_data[7] <= rx_pin;
                        // stop bit終了
                        5'd18: begin
                            clk_cnt <= 5'd0;
                            data <= tmp_data;
                            available <= 1'd1;
                            state <= S_IDLE;
                        end
                    endcase
                end
                else begin
                    cycle <= cycle + 1'd1;
                end
            end
        endcase
    end
end
endmodule