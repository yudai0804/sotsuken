// Data format
// boudrate = 9600
// byte size = 8
// start bit = 0
// parity = None
// stop bit = 1
// START(0) + B0 + B1 + B2 + B3 + B4 + B5 + B6 + B7 + STOP(1)

module uart_tx
#(
    // 27MHz
    parameter CLK_FREQ = 27_000_000,
    // 9600bps
    parameter BOUD_RATE = 9600
)(
    input clk,
    input rst_n,
    input start,
    input [7:0] data,
    output reg tx_pin,
    // 送信が終了したときもstart==1'd1であれば、次のデータを送信するのでfinishは0のまま
    output reg finish
);

localparam CYCLE = CLK_FREQ / BOUD_RATE;
reg [15:0] cycle;

localparam S_IDLE = 1'd0;
localparam S_RUNNING = 1'd1;

reg state;
reg [7:0] latch_data;
reg [3:0] clk_cnt;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        tx_pin <= 1'd1;
        finish <= 1'd1;
        cycle <= 16'd0;
        state <= S_IDLE;
        latch_data <= 8'd0;
        clk_cnt <= 4'd0;
    end
    else begin
        case (state)
            S_IDLE: begin
                if (start == 1'd1) begin
                    tx_pin <= 1'd0;
                    // start == 1'd1になった瞬間に出力するので、cycleは1にしておく
                    cycle <= 16'd1;
                    clk_cnt <= 4'd0;

                    finish <= 1'd0;
                    latch_data <= data;
                    state <= S_RUNNING;
                end
            end
            S_RUNNING: begin
                if (cycle == CYCLE - 1) begin
                    if (clk_cnt != 4'd9) begin
                        cycle <= 16'd0;
                        clk_cnt <= clk_cnt + 1'd1;
                    end
                    case (clk_cnt)
                        4'd0: tx_pin <= latch_data[0];
                        4'd1: tx_pin <= latch_data[1];
                        4'd2: tx_pin <= latch_data[2];
                        4'd3: tx_pin <= latch_data[3];
                        4'd4: tx_pin <= latch_data[4];
                        4'd5: tx_pin <= latch_data[5];
                        4'd6: tx_pin <= latch_data[6];
                        4'd7: tx_pin <= latch_data[7];
                        // stop bit
                        4'd8: tx_pin <= 1'd1;
                        // 終了
                        4'd9: begin
                            clk_cnt <= 4'd0;
                            if (start == 1'd1) begin
                                latch_data <= data;
                                // start bit
                                tx_pin <= 1'd0;
                                cycle <= 16'd1;
                            end
                            else begin
                                cycle <= 16'd0;
                                finish <= 1'd1;
                                state <= S_IDLE;
                            end
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