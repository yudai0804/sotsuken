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

// TODO: uart_rxも書き直す
// TODO: cycleのノンブロッキング代入周りが怪しいので確認する

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
    output reg[7:0] rx_data,
    output reg rx_available,
    // 1のときrx_availableをクリアする
    input clear_rx_available
);
localparam CYCLE = CLK_FREQ / BOUD_RATE;
localparam CENTER_CYCLE = CYCLE / 2;
localparam S_IDLE = 2'd0;
localparam S_DATA = 2'd1;
localparam S_STOP1 = 2'd2;
localparam S_STOP2 = 2'd3;

// 27e6 / 115200 = 234
// より8bitあれば十分
reg [7:0] cycle;
reg [1:0] state;
reg [1:0] next_state;
reg [2:0] next_bit;
reg [2:0] bit;
reg [7:0] tmp_data;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        cycle <= 8'hff;
        state <= S_IDLE;
        next_state <= S_IDLE;
        bit <= 3'd0;
        next_bit <= 3'd0;
        rx_data <= 8'd0;
        tmp_data <= 8'd0;
        rx_available <= 1'd0;
    end
    else begin
        if (clear_rx_available == 1'd1)
            rx_available <= 1'd0;

        state <= next_state;
        bit <= next_bit;
        cycle <= cycle + 1'd1;

        case (state)
            S_IDLE: begin
                // detect start bit
                if (rx_pin == 1'd0) begin
                    if (cycle == CENTER_CYCLE - 2) begin
                        cycle <= 8'hff;
                        next_state <= S_DATA;
                    end
                end
                else
                    cycle <= 8'hff;
            end
            S_DATA: begin
                if (cycle == CYCLE - 2) begin
                    cycle <= 8'hff;
                    tmp_data[bit] <= rx_pin;
                    if (bit == 3'd7) begin
                        next_bit <= 3'd0;
                        next_state <= S_STOP1;
                    end
                    else
                        next_bit <= bit + 1'd1;
                end
            end
            // 信号を真ん中で読むために0.5サイクルずらしたので、S_STOPは1.5サイクル
            S_STOP1: begin
                if (cycle == CYCLE - 2) begin
                    cycle <= 8'hff;
                    next_state <= S_STOP2;
                end
            end
            // S_STOP2
            default: begin
                if (cycle == CENTER_CYCLE - 1) begin
                    cycle <= 8'hff;
                    next_state <= S_IDLE;
                    rx_data <= tmp_data; 
                    rx_available <= 1'd1;
                end
            end
        endcase
    end
end
endmodule
