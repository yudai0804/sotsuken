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

// TODO: uart_txも書き直す
// TODO: cycleのノンブロッキング代入周りが怪しいので確認する

module uart_tx 
#(
    // 27MHz
    parameter CLK_FREQ = 27_000_000,
    // 115.2kbps
    parameter BOUD_RATE = 115200
)(
    input clk,
    input rst_n,
    output reg tx_pin,
    input tx_enable,
    input [7:0] tx_data,
    output reg tx_available
);
localparam CYCLE = CLK_FREQ / BOUD_RATE;
localparam S_IDLE = 2'd0;
localparam S_START = 2'd1;
localparam S_DATA = 2'd2;
localparam S_STOP = 2'd3;

// 27e6 / 115200 = 234
// より8bitあれば十分
reg [7:0] cycle;
reg [1:0] state;
reg [1:0] next_state;
reg [2:0] bit;
reg [2:0] next_bit;
reg [7:0] latch_data;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        cycle <= 8'hff;
        state <= S_IDLE;
        next_state <= S_IDLE;
        bit <= 3'd0;
        next_bit <= 3'd0;
        latch_data <= 8'd0;
        tx_pin <= 1'd1;
        tx_available <= 1'd1;
    end
    else begin
        if (tx_enable == 1'd1 && next_state == S_IDLE) begin
            latch_data <= tx_data;
            next_state <= S_START;
            cycle <= 8'd0;
            next_bit <= 3'd0;
            tx_available <= 1'd0;
        end
        else
            cycle <= cycle + 1'd1;
        
        state <= next_state;
        bit <= next_bit;
        
        case (state)
            S_IDLE: begin
                tx_pin <= 1'd1;
            end
            S_START: begin
                tx_pin <= 1'd0; 
                if (cycle == CYCLE - 2) begin
                    cycle <= 8'd0;
                    next_state <= S_DATA;
                end
            end
            S_DATA: begin
                tx_pin <= latch_data[bit];
                if (cycle == CYCLE - 2) begin
                    cycle <= 8'hff;
                    if (bit == 3'd7) begin
                        next_bit <= 3'd0;
                        next_state <= S_STOP;
                    end
                    else begin
                        next_bit <= bit + 1'd1;
                    end
                end
            end
            default: begin
                tx_pin <= 1'd1;
                if (cycle == CYCLE - 2) begin
                    cycle <= 8'hff;
                    next_state <= S_IDLE;
                    tx_available <= 1'd1;
                end
            end
        endcase
    end
end
endmodule
